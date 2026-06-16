-- ============================================================
-- FILE: 04_stored_procedures/sp_department_summary.sql
-- PROJECT: HR Employee Attrition Analysis
-- AUTHOR: Maram Thirupathi
-- DESCRIPTION: Drill-down report for a specific department.
--              Returns role-level attrition, satisfaction,
--              income, and tenure breakdown.
--
-- USAGE:
--   CALL sp_department_summary('Sales');
--   CALL sp_department_summary('Research & Development');
--   CALL sp_department_summary('Human Resources');
-- ============================================================

USE hr_attrition_db;

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_department_summary$$

CREATE PROCEDURE sp_department_summary(
    IN p_dept_name VARCHAR(50)
)
BEGIN
    DECLARE v_dept_id TINYINT UNSIGNED;

    -- Lookup department ID
    SELECT dept_id INTO v_dept_id
    FROM dim_department
    WHERE dept_name = p_dept_name
    LIMIT 1;

    -- Guard: department not found
    IF v_dept_id IS NULL THEN
        SELECT CONCAT('Department not found: "', p_dept_name,
               '". Valid values: Human Resources, Research & Development, Sales')
               AS error_message;
    ELSE
        -- Role-level breakdown within department
        SELECT
            jr.role_name,
            jr.role_level,
            COUNT(*)                                               AS headcount,
            SUM(fe.attrition_flag)                                 AS attritions,
            ROUND(SUM(fe.attrition_flag) * 100.0 / COUNT(*), 2)   AS attrition_rate_pct,
            ROUND(AVG(fe.monthly_income), 2)                      AS avg_income,
            ROUND(AVG(fe.job_satisfaction), 2)                    AS avg_job_satisfaction,
            ROUND(AVG(fe.work_life_balance), 2)                   AS avg_wlb_score,
            ROUND(AVG(fe.years_at_company), 1)                    AS avg_tenure_yrs,
            SUM(CASE fe.overtime_flag WHEN 1 THEN 1 ELSE 0 END)   AS overtime_headcount,
            ROUND(
                SUM(CASE fe.overtime_flag WHEN 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
            )                                                      AS overtime_pct
        FROM fact_employee fe
        JOIN dim_job_role jr ON fe.role_id = jr.role_id
        WHERE fe.dept_id = v_dept_id
        GROUP BY jr.role_name, jr.role_level
        ORDER BY attrition_rate_pct DESC;
    END IF;
END$$
DELIMITER ;
