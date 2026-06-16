-- ============================================================
-- FILE: 02_data_prep/data_validation.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Post-load integrity and quality checks.
--              All queries should return 0 rows if data is clean.
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- CHECK 1: Orphaned FK references (should return 0 rows)
-- ------------------------------------------------------------
SELECT 'Orphaned dept_id' AS check_name, COUNT(*) AS violation_count
FROM fact_employee fe
LEFT JOIN dim_department dd ON fe.dept_id = dd.dept_id
WHERE dd.dept_id IS NULL

UNION ALL

SELECT 'Orphaned role_id', COUNT(*)
FROM fact_employee fe
LEFT JOIN dim_job_role jr ON fe.role_id = jr.role_id
WHERE jr.role_id IS NULL

UNION ALL

SELECT 'Orphaned salary_band_id', COUNT(*)
FROM fact_employee fe
LEFT JOIN dim_salary_band sb ON fe.salary_band_id = sb.salary_band_id
WHERE sb.salary_band_id IS NULL;

-- ------------------------------------------------------------
-- CHECK 2: Salary vs salary_band_id consistency
-- ------------------------------------------------------------
SELECT
    'Salary band mismatch' AS check_name,
    COUNT(*)               AS violation_count
FROM fact_employee fe
JOIN dim_salary_band sb ON fe.salary_band_id = sb.salary_band_id
WHERE fe.monthly_income NOT BETWEEN sb.monthly_min AND sb.monthly_max;

-- ------------------------------------------------------------
-- CHECK 3: Business logic — years_at_company cannot exceed total_working_years
-- ------------------------------------------------------------
SELECT
    'Years at company > total working years' AS check_name,
    COUNT(*)                                 AS violation_count
FROM fact_employee
WHERE years_at_company > total_working_years;

-- ------------------------------------------------------------
-- CHECK 4: Duplicate employee numbers
-- ------------------------------------------------------------
SELECT
    'Duplicate emp_number' AS check_name,
    COUNT(*)               AS violation_count
FROM (
    SELECT emp_number
    FROM fact_employee
    GROUP BY emp_number
    HAVING COUNT(*) > 1
) dup;

-- ------------------------------------------------------------
-- CHECK 5: NULL counts on mandatory columns
-- ------------------------------------------------------------
SELECT
    SUM(CASE WHEN monthly_income IS NULL THEN 1 ELSE 0 END)  AS null_income,
    SUM(CASE WHEN age            IS NULL THEN 1 ELSE 0 END)  AS null_age,
    SUM(CASE WHEN attrition_flag IS NULL THEN 1 ELSE 0 END)  AS null_attrition,
    SUM(CASE WHEN dept_id        IS NULL THEN 1 ELSE 0 END)  AS null_dept
FROM fact_employee;

-- ------------------------------------------------------------
-- CHECK 6: Row count summary (confirm expected load)
-- ------------------------------------------------------------
SELECT
    'fact_employee'  AS table_name, COUNT(*) AS row_count FROM fact_employee
UNION ALL
SELECT 'dim_department',  COUNT(*) FROM dim_department
UNION ALL
SELECT 'dim_job_role',    COUNT(*) FROM dim_job_role
UNION ALL
SELECT 'dim_education',   COUNT(*) FROM dim_education
UNION ALL
SELECT 'dim_salary_band', COUNT(*) FROM dim_salary_band;
