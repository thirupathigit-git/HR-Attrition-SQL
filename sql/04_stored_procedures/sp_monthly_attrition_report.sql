-- ============================================================
-- FILE: 04_stored_procedures/sp_monthly_attrition_report.sql
-- PROJECT: HR Employee Attrition Analysis
-- AUTHOR: Maram Thirupathi
-- DESCRIPTION: Parameterized report for any date range.
--              Returns 3 result sets: company summary,
--              department breakdown, and top 3 attrition drivers.
--
-- USAGE:
--   CALL sp_monthly_attrition_report('2024-01-01', '2024-12-31');
--   CALL sp_monthly_attrition_report(NULL, NULL);  -- full dataset
-- ============================================================

USE hr_attrition_db;

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_monthly_attrition_report$$

CREATE PROCEDURE sp_monthly_attrition_report(
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    -- Default to full dataset if no dates passed
    IF p_start_date IS NULL THEN SET p_start_date = '1900-01-01'; END IF;
    IF p_end_date   IS NULL THEN SET p_end_date   = CURDATE();    END IF;

    -- Result Set 1: Company-level summary
    SELECT
        'COMPANY SUMMARY'                                          AS report_section,
        COUNT(*)                                                   AS total_employees,
        SUM(attrition_flag)                                        AS total_attritions,
        ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)          AS overall_attrition_rate_pct,
        ROUND(AVG(monthly_income), 2)                             AS avg_monthly_income,
        ROUND(AVG(years_at_company), 1)                           AS avg_tenure_yrs
    FROM fact_employee
    WHERE record_created_at BETWEEN p_start_date AND p_end_date;

    -- Result Set 2: Department breakdown with health status
    SELECT
        dd.dept_name                                               AS department,
        COUNT(*)                                                   AS headcount,
        SUM(fe.attrition_flag)                                     AS attritions,
        ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2)       AS dept_attrition_rate_pct,
        ROUND(AVG(fe.monthly_income), 2)                          AS avg_dept_income,
        CASE
            WHEN SUM(fe.attrition_flag) * 100.0 / COUNT(*) > 20 THEN 'HIGH RISK'
            WHEN SUM(fe.attrition_flag) * 100.0 / COUNT(*) > 12 THEN 'MODERATE'
            ELSE 'HEALTHY'
        END                                                        AS dept_health_status
    FROM fact_employee fe
    JOIN dim_department dd ON fe.dept_id = dd.dept_id
    WHERE fe.record_created_at BETWEEN p_start_date AND p_end_date
    GROUP BY dd.dept_name
    ORDER BY dept_attrition_rate_pct DESC;

    -- Result Set 3: Top 3 attrition drivers (dataset-validated)
    SELECT
        'Overtime (3.1x higher attrition rate)'                   AS attrition_driver,
        ROUND(
            SUM(CASE WHEN overtime_flag = 1 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN overtime_flag = 1 THEN 1 ELSE 0 END), 0), 2
        )                                                          AS high_risk_group_pct,
        ROUND(
            SUM(CASE WHEN overtime_flag = 0 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN overtime_flag = 0 THEN 1 ELSE 0 END), 0), 2
        )                                                          AS baseline_group_pct
    FROM fact_employee
    WHERE record_created_at BETWEEN p_start_date AND p_end_date

    UNION ALL

    SELECT
        'Salary Band 1 — lowest earners (highest attrition)',
        ROUND(
            SUM(CASE WHEN salary_band_id = 1 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN salary_band_id = 1 THEN 1 ELSE 0 END), 0), 2
        ),
        ROUND(
            SUM(CASE WHEN salary_band_id > 1 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN salary_band_id > 1 THEN 1 ELSE 0 END), 0), 2
        )
    FROM fact_employee
    WHERE record_created_at BETWEEN p_start_date AND p_end_date

    UNION ALL

    SELECT
        '0–2 year tenure — new hires at highest risk (3.5x rate)',
        ROUND(
            SUM(CASE WHEN years_at_company <= 2 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN years_at_company <= 2 THEN 1 ELSE 0 END), 0), 2
        ),
        ROUND(
            SUM(CASE WHEN years_at_company > 2 THEN attrition_flag ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN years_at_company > 2 THEN 1 ELSE 0 END), 0), 2
        )
    FROM fact_employee
    WHERE record_created_at BETWEEN p_start_date AND p_end_date;

END$$
DELIMITER ;
