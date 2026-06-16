-- ============================================================
-- FILE: 03_analysis/01_attrition_overview.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Top-level KPIs — overall attrition rate,
--              headcount summary, and company-wide health score
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- QUERY 1: Company-wide attrition KPI summary
-- ------------------------------------------------------------
SELECT
    COUNT(*)                                                AS total_employees,
    SUM(attrition_flag)                                     AS total_attritions,
    SUM(CASE WHEN attrition_flag = 0 THEN 1 ELSE 0 END)    AS active_employees,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)       AS attrition_rate_pct,
    ROUND(AVG(monthly_income), 2)                          AS avg_monthly_income,
    ROUND(AVG(years_at_company), 1)                        AS avg_tenure_years,
    ROUND(AVG(age), 1)                                     AS avg_age
FROM fact_employee;


-- ------------------------------------------------------------
-- QUERY 2: Attrition by gender with rate comparison
-- ------------------------------------------------------------
SELECT
    gender,
    COUNT(*)                                          AS headcount,
    SUM(attrition_flag)                               AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct,
    ROUND(AVG(monthly_income), 2)                    AS avg_income
FROM fact_employee
GROUP BY gender
ORDER BY attrition_rate_pct DESC;


-- ------------------------------------------------------------
-- QUERY 3: Attrition by marital status
-- ------------------------------------------------------------
SELECT
    marital_status,
    COUNT(*)                                          AS headcount,
    SUM(attrition_flag)                               AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY marital_status
ORDER BY attrition_rate_pct DESC;


-- ------------------------------------------------------------
-- QUERY 4: Attrition by business travel frequency
-- ------------------------------------------------------------
SELECT
    business_travel,
    COUNT(*)                                          AS headcount,
    SUM(attrition_flag)                               AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct,
    ROUND(AVG(job_satisfaction), 2)                  AS avg_job_satisfaction
FROM fact_employee
GROUP BY business_travel
ORDER BY attrition_rate_pct DESC;


-- ------------------------------------------------------------
-- QUERY 5: Monthly income distribution of leavers vs stayers
--          Using CASE WHEN for income brackets
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN monthly_income < 3000  THEN 'Under 3K'
        WHEN monthly_income < 6000  THEN '3K – 6K'
        WHEN monthly_income < 10000 THEN '6K – 10K'
        WHEN monthly_income < 15000 THEN '10K – 15K'
        ELSE 'Above 15K'
    END                                               AS income_bracket,
    COUNT(*)                                          AS headcount,
    SUM(attrition_flag)                               AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY income_bracket
ORDER BY
    CASE income_bracket
        WHEN 'Under 3K'   THEN 1
        WHEN '3K – 6K'    THEN 2
        WHEN '6K – 10K'   THEN 3
        WHEN '10K – 15K'  THEN 4
        ELSE 5
    END;
