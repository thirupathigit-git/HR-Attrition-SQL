-- ============================================================
-- FILE: 03_analysis/05_overtime_analysis.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Overtime impact on attrition — one of the
--              strongest predictors in the IBM HR dataset
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- QUERY 1: Overtime vs no overtime — headline comparison
-- ------------------------------------------------------------
SELECT
    CASE overtime_flag WHEN 1 THEN 'Works Overtime' ELSE 'No Overtime' END AS overtime_status,
    COUNT(*)                                          AS headcount,
    SUM(attrition_flag)                               AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct,
    ROUND(AVG(work_life_balance), 2)                 AS avg_wlb_score,
    ROUND(AVG(job_satisfaction), 2)                  AS avg_job_satisfaction,
    ROUND(AVG(monthly_income), 2)                    AS avg_income
FROM fact_employee
GROUP BY overtime_flag;


-- ------------------------------------------------------------
-- QUERY 2: Overtime + Department combined analysis
-- ------------------------------------------------------------
SELECT
    dd.dept_name,
    CASE fe.overtime_flag WHEN 1 THEN 'Overtime' ELSE 'No Overtime' END AS ot_status,
    COUNT(*)                                          AS headcount,
    SUM(fe.attrition_flag)                            AS attritions,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM fact_employee fe
JOIN dim_department dd ON fe.dept_id = dd.dept_id
GROUP BY dd.dept_name, fe.overtime_flag
ORDER BY dd.dept_name, fe.overtime_flag DESC;


-- ------------------------------------------------------------
-- QUERY 3: Overtime + Salary band interaction
--          Do low earners who work overtime leave most?
-- ------------------------------------------------------------
SELECT
    sb.band_label,
    CASE fe.overtime_flag WHEN 1 THEN 'Overtime' ELSE 'No Overtime' END AS ot_status,
    COUNT(*)                                          AS headcount,
    SUM(fe.attrition_flag)                            AS attritions,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct,
    ROUND(AVG(fe.work_life_balance), 2)              AS avg_wlb
FROM fact_employee fe
JOIN dim_salary_band sb ON fe.salary_band_id = sb.salary_band_id
GROUP BY sb.band_label, fe.overtime_flag
ORDER BY sb.band_label, fe.overtime_flag DESC;


-- ------------------------------------------------------------
-- QUERY 4: Overtime + Work-life balance score segmentation
-- ------------------------------------------------------------
SELECT
    CASE fe.overtime_flag WHEN 1 THEN 'Overtime' ELSE 'No Overtime' END AS ot_status,
    CASE fe.work_life_balance
        WHEN 1 THEN '1 – Poor'
        WHEN 2 THEN '2 – Fair'
        WHEN 3 THEN '3 – Good'
        WHEN 4 THEN '4 – Excellent'
    END                                               AS wlb_score,
    COUNT(*)                                           AS headcount,
    SUM(fe.attrition_flag)                             AS attritions,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM fact_employee fe
GROUP BY fe.overtime_flag, fe.work_life_balance
ORDER BY fe.overtime_flag DESC, fe.work_life_balance;


-- ------------------------------------------------------------
-- QUERY 5: Overtime multiplier effect
--          How many times more likely to leave if on overtime?
-- ------------------------------------------------------------
WITH rates AS (
    SELECT
        SUM(CASE WHEN overtime_flag = 1 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN overtime_flag = 1 THEN 1 ELSE 0 END), 0)  AS ot_rate,
        SUM(CASE WHEN overtime_flag = 0 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN overtime_flag = 0 THEN 1 ELSE 0 END), 0)  AS no_ot_rate
    FROM fact_employee
)
SELECT
    ROUND(ot_rate, 2)                         AS overtime_attrition_rate_pct,
    ROUND(no_ot_rate, 2)                      AS no_overtime_attrition_rate_pct,
    ROUND(ot_rate / NULLIF(no_ot_rate, 0), 2) AS attrition_multiplier,
    CONCAT(ROUND(ot_rate / NULLIF(no_ot_rate, 0), 1), 'x more likely to leave')
                                              AS interpretation
FROM rates;
