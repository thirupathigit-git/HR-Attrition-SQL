-- ============================================================
-- FILE: 05_views/vw_attrition_dashboard.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: 3 reusable views for Power BI / reporting layer
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- VIEW 1: Main dashboard view — joins all dimensions
--         Used as the single source for BI tools (Power BI etc.)
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_attrition_dashboard;

CREATE VIEW vw_attrition_dashboard AS
SELECT
    fe.employee_id,
    fe.emp_number,
    dd.dept_name                                               AS department,
    jr.role_name                                               AS job_role,
    jr.role_level,
    ed.education_label,
    sb.band_label                                              AS salary_band,
    sb.band_description                                        AS salary_band_desc,
    fe.age,
    CASE
        WHEN fe.age BETWEEN 18 AND 24 THEN '18–24'
        WHEN fe.age BETWEEN 25 AND 34 THEN '25–34'
        WHEN fe.age BETWEEN 35 AND 44 THEN '35–44'
        WHEN fe.age BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END                                                        AS age_group,
    fe.gender,
    fe.marital_status,
    fe.monthly_income,
    fe.percent_salary_hike,
    fe.stock_option_level,
    fe.years_at_company,
    fe.years_in_current_role,
    fe.years_since_promotion,
    fe.total_working_years,
    fe.num_companies_worked,
    CASE fe.overtime_flag WHEN 1 THEN 'Yes' ELSE 'No' END     AS overtime,
    fe.business_travel,
    fe.job_satisfaction,
    fe.environment_satisfaction,
    fe.work_life_balance,
    fe.relationship_satisfaction,
    fe.performance_rating,
    fe.attrition_flag,
    CASE fe.attrition_flag WHEN 1 THEN 'Left' ELSE 'Active'
    END                                                        AS attrition_status,
    -- Pre-computed risk score for BI consumption
    (
        CASE fe.overtime_flag WHEN 1 THEN 25 ELSE 0 END
        + CASE WHEN fe.salary_band_id = 1 THEN 20 WHEN fe.salary_band_id = 2 THEN 12 WHEN fe.salary_band_id = 3 THEN 5 ELSE 0 END
        + CASE WHEN fe.age BETWEEN 18 AND 25 THEN 15 WHEN fe.age BETWEEN 26 AND 32 THEN 10 WHEN fe.age BETWEEN 33 AND 40 THEN 5 ELSE 0 END
        + CASE WHEN fe.years_at_company <= 2 THEN 15 WHEN fe.years_at_company <= 5 THEN 8 WHEN fe.years_at_company <= 10 THEN 3 ELSE 0 END
        + CASE WHEN fe.job_satisfaction = 1 THEN 10 WHEN fe.job_satisfaction = 2 THEN 6 WHEN fe.job_satisfaction = 3 THEN 2 ELSE 0 END
        + CASE fe.marital_status WHEN 'Single' THEN 5 ELSE 0 END
        + CASE fe.business_travel WHEN 'Travel_Frequently' THEN 5 WHEN 'Travel_Rarely' THEN 2 ELSE 0 END
        + CASE WHEN fe.years_since_promotion >= 6 THEN 5 WHEN fe.years_since_promotion >= 3 THEN 3 ELSE 0 END
    )                                                          AS attrition_risk_score
FROM fact_employee fe
JOIN dim_department dd ON fe.dept_id       = dd.dept_id
JOIN dim_job_role   jr ON fe.role_id       = jr.role_id
JOIN dim_education  ed ON fe.education_id  = ed.education_id
JOIN dim_salary_band sb ON fe.salary_band_id = sb.salary_band_id;


-- ------------------------------------------------------------
-- VIEW 2: Salary risk bands — aggregated for BI charts
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_salary_risk_bands;

CREATE VIEW vw_salary_risk_bands AS
SELECT
    sb.band_label,
    sb.band_description,
    CONCAT('₹', FORMAT(sb.monthly_min,0), '–₹', FORMAT(sb.monthly_max,0)) AS income_range,
    COUNT(fe.employee_id)                                     AS headcount,
    SUM(fe.attrition_flag)                                    AS attritions,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2)      AS attrition_rate_pct,
    ROUND(AVG(fe.monthly_income), 2)                         AS avg_income,
    ROUND(AVG(fe.job_satisfaction), 2)                       AS avg_satisfaction
FROM fact_employee fe
JOIN dim_salary_band sb ON fe.salary_band_id = sb.salary_band_id
GROUP BY sb.salary_band_id, sb.band_label, sb.band_description, sb.monthly_min, sb.monthly_max;


-- ------------------------------------------------------------
-- VIEW 3: Department health scorecard
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_department_health;

CREATE VIEW vw_department_health AS
WITH company_rate AS (
    SELECT ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2) AS co_rate
    FROM fact_employee
)
SELECT
    dd.dept_name,
    COUNT(fe.employee_id)                                     AS headcount,
    SUM(fe.attrition_flag)                                    AS attritions,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2)      AS dept_attrition_rate,
    cr.co_rate                                                AS company_attrition_rate,
    ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*) - cr.co_rate, 2)  AS variance,
    ROUND(AVG(fe.job_satisfaction), 2)                       AS avg_job_satisfaction,
    ROUND(AVG(fe.work_life_balance), 2)                      AS avg_wlb_score,
    ROUND(AVG(fe.monthly_income), 2)                         AS avg_income,
    ROUND(AVG(fe.years_at_company), 1)                       AS avg_tenure,
    CASE
        WHEN SUM(fe.attrition_flag) * 100.0 / COUNT(*) >= 20 THEN 'Critical'
        WHEN SUM(fe.attrition_flag) * 100.0 / COUNT(*) >= 15 THEN 'At Risk'
        WHEN SUM(fe.attrition_flag) * 100.0 / COUNT(*) >= 10 THEN 'Monitor'
        ELSE 'Healthy'
    END                                                       AS health_status
FROM fact_employee fe
JOIN dim_department dd ON fe.dept_id = dd.dept_id
CROSS JOIN company_rate cr
GROUP BY dd.dept_name, cr.co_rate;
