-- ============================================================
-- FILE: 04_stored_procedures/sp_attrition_trend.sql
-- PROJECT: HR Employee Attrition Analysis
-- AUTHOR: Maram Thirupathi
-- DESCRIPTION: Year-over-year attrition trend using window functions.
--              Uses LAG() to compare each year against the previous
--              and classifies direction as WORSENING / IMPROVING / STABLE.
--
-- USAGE:
--   CALL sp_attrition_trend();
-- ============================================================

USE hr_attrition_db;

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_attrition_trend$$

CREATE PROCEDURE sp_attrition_trend()
BEGIN
    WITH yearly AS (
        SELECT
            YEAR(record_created_at)                                AS yr,
            COUNT(*)                                               AS headcount,
            SUM(attrition_flag)                                    AS attritions,
            ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)      AS attrition_rate
        FROM fact_employee
        GROUP BY YEAR(record_created_at)
    )
    SELECT
        yr                                                         AS year,
        headcount,
        attritions,
        attrition_rate                                             AS attrition_rate_pct,
        LAG(attrition_rate) OVER (ORDER BY yr)                    AS prev_year_rate,
        ROUND(
            attrition_rate - LAG(attrition_rate) OVER (ORDER BY yr), 2
        )                                                          AS yoy_change_pct,
        CASE
            WHEN attrition_rate > LAG(attrition_rate) OVER (ORDER BY yr) THEN 'WORSENING ↑'
            WHEN attrition_rate < LAG(attrition_rate) OVER (ORDER BY yr) THEN 'IMPROVING ↓'
            ELSE 'STABLE →'
        END                                                        AS trend_direction
    FROM yearly
    ORDER BY yr;
END$$
DELIMITER ;
