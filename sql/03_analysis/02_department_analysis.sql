-- ============================================================
-- FILE: 03_analysis/02_department_analysis.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Department-level attrition analysis using CTEs,
--              window functions, GROUP BY ROLLUP, and correlated subqueries
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- QUERY 1: Department + Job Role breakdown using GROUP BY ROLLUP
--          Produces subtotals per department and a grand total
-- ------------------------------------------------------------
SELECT
    COALESCE(dd.dept_name, 'ALL DEPARTMENTS')     AS department,
    COALESCE(jr.role_name, 'ALL ROLES')           AS job_role,
    COUNT(*)                                       AS headcount,
    SUM(fe.attrition_flag)                         AS attritions,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM fact_employee fe
JOIN dim_department dd ON fe.dept_id  = dd.dept_id
JOIN dim_job_role   jr ON fe.role_id  = jr.role_id
GROUP BY ROLLUP(dd.dept_name, jr.role_name)
ORDER BY department, job_role;


-- ------------------------------------------------------------
-- QUERY 2: Department attrition ranked with RANK() window function
--          Includes company average for comparison
-- ------------------------------------------------------------
WITH dept_attrition AS (
    SELECT
        dd.dept_name,
        COUNT(*)                                                   AS headcount,
        SUM(fe.attrition_flag)                                     AS attritions,
        ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2)       AS dept_attrition_rate
    FROM fact_employee fe
    JOIN dim_department dd ON fe.dept_id = dd.dept_id
    GROUP BY dd.dept_name
),
company_avg AS (
    SELECT ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS company_rate
    FROM fact_employee
)
SELECT
    da.dept_name,
    da.headcount,
    da.attritions,
    da.dept_attrition_rate,
    ca.company_rate                                          AS company_avg_rate,
    ROUND(da.dept_attrition_rate - ca.company_rate, 2)      AS variance_from_avg,
    CASE
        WHEN da.dept_attrition_rate > ca.company_rate THEN 'ABOVE AVG ⚠'
        WHEN da.dept_attrition_rate < ca.company_rate THEN 'BELOW AVG ✓'
        ELSE 'AT AVG'
    END                                                     AS performance_flag,
    RANK() OVER (ORDER BY da.dept_attrition_rate DESC)      AS attrition_rank
FROM dept_attrition da
CROSS JOIN company_avg ca
ORDER BY da.dept_attrition_rate DESC;


-- ------------------------------------------------------------
-- QUERY 3: Top 5 highest-attrition job roles (any department)
--          using DENSE_RANK() to handle ties
-- ------------------------------------------------------------
WITH role_stats AS (
    SELECT
        jr.role_name,
        dd.dept_name,
        COUNT(*)                                               AS headcount,
        SUM(fe.attrition_flag)                                 AS attritions,
        ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2)   AS attrition_rate
    FROM fact_employee fe
    JOIN dim_job_role   jr ON fe.role_id  = jr.role_id
    JOIN dim_department dd ON fe.dept_id  = dd.dept_id
    GROUP BY jr.role_name, dd.dept_name
    HAVING COUNT(*) >= 10   -- exclude roles with very small samples
)
SELECT
    role_name,
    dept_name,
    headcount,
    attritions,
    attrition_rate,
    DENSE_RANK() OVER (ORDER BY attrition_rate DESC) AS risk_rank
FROM role_stats
ORDER BY risk_rank
LIMIT 10;


-- ------------------------------------------------------------
-- QUERY 4: Correlated subquery — employees whose income is below
--          their department average (a common attrition driver)
-- ------------------------------------------------------------
SELECT
    fe.emp_number,
    dd.dept_name,
    jr.role_name,
    fe.monthly_income,
    ROUND(
        (SELECT AVG(fe2.monthly_income)
         FROM fact_employee fe2
         WHERE fe2.dept_id = fe.dept_id), 2
    )                                          AS dept_avg_income,
    ROUND(
        fe.monthly_income -
        (SELECT AVG(fe2.monthly_income)
         FROM fact_employee fe2
         WHERE fe2.dept_id = fe.dept_id), 2
    )                                          AS income_vs_dept_avg,
    fe.attrition_flag
FROM fact_employee fe
JOIN dim_department dd ON fe.dept_id = dd.dept_id
JOIN dim_job_role   jr ON fe.role_id = jr.role_id
WHERE fe.monthly_income < (
    SELECT AVG(fe3.monthly_income)
    FROM fact_employee fe3
    WHERE fe3.dept_id = fe.dept_id
)
ORDER BY income_vs_dept_avg ASC
LIMIT 50;


-- ------------------------------------------------------------
-- QUERY 5: Running total of attritions per department
--          using SUM() as window function
-- ------------------------------------------------------------
WITH monthly_data AS (
    SELECT
        dd.dept_name,
        YEAR(fe.record_created_at)                     AS yr,
        MONTH(fe.record_created_at)                    AS mo,
        SUM(fe.attrition_flag)                         AS monthly_attritions
    FROM fact_employee fe
    JOIN dim_department dd ON fe.dept_id = dd.dept_id
    GROUP BY dd.dept_name, YEAR(fe.record_created_at), MONTH(fe.record_created_at)
)
SELECT
    dept_name,
    yr,
    mo,
    monthly_attritions,
    SUM(monthly_attritions) OVER (
        PARTITION BY dept_name
        ORDER BY yr, mo
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                        AS running_total_attritions
FROM monthly_data
ORDER BY dept_name, yr, mo;
