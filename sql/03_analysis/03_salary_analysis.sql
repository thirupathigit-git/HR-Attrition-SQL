-- ============================================================
-- FILE: 03_analysis/03_salary_analysis.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Salary band vs attrition correlation analysis
--              using NTILE, PERCENT_RANK, and salary band joins
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- QUERY 1: Attrition rate by defined salary band
-- ------------------------------------------------------------
SELECT
    sb.band_label,
    sb.band_description,
    CONCAT('₹', FORMAT(sb.monthly_min,0), ' – ₹', FORMAT(sb.monthly_max,0)) AS income_range,
    COUNT(fe.employee_id)                                     AS headcount,
    SUM(fe.attrition_flag)                                    AS attritions,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2)      AS attrition_rate_pct,
    ROUND(AVG(fe.monthly_income), 2)                         AS avg_income_in_band,
    ROUND(AVG(fe.job_satisfaction), 2)                       AS avg_job_satisfaction
FROM fact_employee fe
JOIN dim_salary_band sb ON fe.salary_band_id = sb.salary_band_id
GROUP BY sb.salary_band_id, sb.band_label, sb.band_description, sb.monthly_min, sb.monthly_max
ORDER BY sb.monthly_min;


-- ------------------------------------------------------------
-- QUERY 2: Income NTILE quartiles vs attrition
--          Divides employees into 4 equal income groups
-- ------------------------------------------------------------
WITH income_quartiles AS (
    SELECT
        employee_id,
        monthly_income,
        attrition_flag,
        NTILE(4) OVER (ORDER BY monthly_income) AS income_quartile
    FROM fact_employee
)
SELECT
    income_quartile,
    CASE income_quartile
        WHEN 1 THEN 'Q1 — Lowest 25%'
        WHEN 2 THEN 'Q2 — Lower-mid 25%'
        WHEN 3 THEN 'Q3 — Upper-mid 25%'
        WHEN 4 THEN 'Q4 — Highest 25%'
    END                                              AS quartile_label,
    COUNT(*)                                          AS headcount,
    MIN(monthly_income)                              AS min_income,
    MAX(monthly_income)                              AS max_income,
    ROUND(AVG(monthly_income), 2)                   AS avg_income,
    SUM(attrition_flag)                              AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM income_quartiles
GROUP BY income_quartile
ORDER BY income_quartile;


-- ------------------------------------------------------------
-- QUERY 3: Salary hike percentage vs attrition
--          Did employees who got smaller raises leave more?
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN percent_salary_hike < 12 THEN 'Low raise   (< 12%)'
        WHEN percent_salary_hike < 17 THEN 'Avg raise   (12–16%)'
        WHEN percent_salary_hike < 22 THEN 'Good raise  (17–21%)'
        ELSE                               'High raise  (22%+)'
    END                                               AS raise_bracket,
    COUNT(*)                                           AS headcount,
    SUM(attrition_flag)                                AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)  AS attrition_rate_pct,
    ROUND(AVG(percent_salary_hike), 1)                AS avg_hike_pct
FROM fact_employee
GROUP BY raise_bracket
ORDER BY attrition_rate_pct DESC;


-- ------------------------------------------------------------
-- QUERY 4: Stock option level vs attrition
-- ------------------------------------------------------------
SELECT
    stock_option_level,
    CASE stock_option_level
        WHEN 0 THEN 'No stock options'
        WHEN 1 THEN 'Level 1'
        WHEN 2 THEN 'Level 2'
        WHEN 3 THEN 'Level 3'
    END                                               AS stock_label,
    COUNT(*)                                           AS headcount,
    SUM(attrition_flag)                                AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)  AS attrition_rate_pct
FROM fact_employee
GROUP BY stock_option_level
ORDER BY stock_option_level;


-- ------------------------------------------------------------
-- QUERY 5: PERCENT_RANK of each attrited employee's income
--          within their department — were low earners more likely to leave?
-- ------------------------------------------------------------
WITH income_ranked AS (
    SELECT
        fe.emp_number,
        dd.dept_name,
        fe.monthly_income,
        fe.attrition_flag,
        ROUND(PERCENT_RANK() OVER (
            PARTITION BY fe.dept_id
            ORDER BY fe.monthly_income
        ) * 100, 1)                             AS income_pct_rank_in_dept
    FROM fact_employee fe
    JOIN dim_department dd ON fe.dept_id = dd.dept_id
)
SELECT
    dept_name,
    CASE
        WHEN income_pct_rank_in_dept <= 25  THEN 'Bottom 25% earners'
        WHEN income_pct_rank_in_dept <= 50  THEN '25–50% earners'
        WHEN income_pct_rank_in_dept <= 75  THEN '50–75% earners'
        ELSE                                     'Top 25% earners'
    END                                          AS income_tier_in_dept,
    COUNT(*)                                      AS headcount,
    SUM(attrition_flag)                           AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM income_ranked
GROUP BY dept_name, income_tier_in_dept
ORDER BY dept_name, attrition_rate_pct DESC;
