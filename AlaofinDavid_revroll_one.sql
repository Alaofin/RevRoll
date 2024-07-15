/*
Question #1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the total value of parts installed by the installer.

Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in increasing order.

Expected column names: name, bonus
*/

-- q1 solution:

SELECT
    i.name AS name,
    ROUND(
        SUM(p.price * o.quantity * 0.1)) AS bonus
FROM
    installers i
JOIN
    installs ins ON i.installer_id = ins.installer_id
JOIN
    orders o ON ins.order_id = o.order_id
JOIN
    parts p ON o.part_id = p.part_id
GROUP BY i.name
ORDER BY bonus;


/*
Question #2: 
RevRoll encourages healthy competition. The company holds a “Install Derby” where installers face off to see who can change a part the fastest in a tournament style contest.

Derby points are awarded as follows:

- An installer receives three points if they win a match (i.e., Took less time to install the part).
- An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
- An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. Return the result table ordered by `num_points` in decreasing order. 
In case of a tie, order the records by `installer_id` in increasing order.

Expected column names: `installer_id`, `name`, `num_points`

*/

-- q2 solution:
WITH DerbyResults AS (
    SELECT
        installer_one_id AS installer_id,
        SUM(CASE WHEN installer_one_time < installer_two_time THEN 3
                   WHEN installer_one_time = installer_two_time THEN 1
                   ELSE 0 END) AS num_points
    FROM
        install_derby
    GROUP BY
        installer_one_id

    UNION ALL

    SELECT
        installer_two_id AS installer_id,
        SUM(CASE WHEN installer_two_time < installer_one_time THEN 3
                   WHEN installer_two_time = installer_one_time THEN 1
                   ELSE 0 END) AS num_points
    FROM
        install_derby
    GROUP BY
        installer_two_id
)

SELECT
    i.installer_id,
    i.name,
    COALESCE(SUM(dr.num_points), 0) AS num_points
FROM
    installers i
LEFT JOIN
    DerbyResults dr ON i.installer_id = dr.installer_id
GROUP BY
    i.installer_id, i.name
ORDER BY
    num_points DESC, i.installer_id;


/*
Question #3:

Write a query to find the fastest install time with its corresponding `derby_id` for each installer. 
In case of a tie, you should find the install with the smallest `derby_id`.

Return the result table ordered by `installer_id` in ascending order.

Expected column names: `derby_id`, `installer_id`, `install_time`
*/

-- q3 solution:

WITH FastestInstall AS (
    SELECT
        derby_id,
        installer_one_id AS installer_id,
        installer_one_time AS install_time
    FROM
        install_derby

    UNION ALL

    SELECT
        derby_id,
        installer_two_id AS installer_id,
        installer_two_time AS install_time
    FROM
        install_derby
)

SELECT
     Min(derby_id) As derby_id,
    installer_id,
    MIN(install_time) AS install_time
FROM
    FastestInstall
GROUP BY
    installer_id
ORDER BY
    installer_id ;


/*
Question #4: 
Write a solution to calculate the total parts spending by customers paying for installs on each Friday of every week in November 2023. 
If there are no purchases on the Friday of a particular week, the parts total should be set to `0`.

Return the result table ordered by week of month in ascending order.

Expected column names: `november_fridays`, `parts_total`
*/

-- q4 solution:

WITH NovemberFridays AS (
    SELECT 
        DISTINCT EXTRACT(WEEK FROM install_date) AS week_of_month,
        EXTRACT(DAY FROM install_date) AS day_of_week
    FROM installs
    WHERE EXTRACT(MONTH FROM install_date) = 11
    AND EXTRACT(YEAR FROM install_date) = 2023
    AND EXTRACT(DAY FROM install_date) BETWEEN 1 AND 30
    AND EXTRACT(DOW FROM install_date) = 5 -- Friday
)

SELECT
    TO_CHAR(i.install_date, 'YYYY-MM-DD') AS november_friday,
    COALESCE(SUM(p.price * o.quantity), 0) AS parts_total
FROM NovemberFridays nf
LEFT JOIN installs i ON EXTRACT(WEEK FROM i.install_date) = nf.week_of_month AND EXTRACT(DOW FROM i.install_date) = 5
LEFT JOIN orders o ON i.order_id = o.order_id
LEFT JOIN parts p ON o.part_id = p.part_id
GROUP BY i.install_date
ORDER BY i.install_date;

