-- ============================================================
-- FILE: 04_stored_procedures/sp_high_risk_employees.sql
-- PROJECT: HR Employee Attrition Analysis
-- AUTHOR: Maram Thirupathi
-- DESCRIPTION: Returns active employees above a risk score threshold
--              for HR intervention prioritization.
--
-- RISK SCORE METHODOLOGY (max 100 points)
-- Weights are derived from attrition rate differentials in this dataset:
--
--   Factor                 Points  Justification (from dataset analysis)
--   ---------------------  ------  ----------------------------------------
--   Overtime = Yes           +25   Overtime employees: 30.5% vs 9.8% non-OT = 3.1x
--   Salary Band 1            +20   Band 1: ~29% attrition vs 16.1% avg
--   Salary Band 2            +12   Band 2: ~19% attrition
--   Salary Band 3            +5    Band 3: ~12% attrition
--   Age 18–25                +15   Highest attrition age cohort (early-career)
--   Age 26–32                +10   Second-highest attrition age cohort
--   Age 33–40                +5    Moderate risk
--   Tenure 0–2 yrs           +15   32.6% vs 9.4% for 3+ yrs = 3.5x multiplier
--   Tenure 3–5 yrs           +8    Still elevated vs senior employees
--   Tenure 6–10 yrs          +3    Moderate risk
--   Job Satisfaction = 1     +10   Very dissatisfied — highest predictor
--   Job Satisfaction = 2     +6    Dissatisfied
--   Job Satisfaction = 3     +2    Neutral
--   Marital Status = Single  +5    Single employees leave more (mobility)
--   Travel Frequently        +5    Highest travel burden
--   Travel Rarely            +2    Some travel burden
--   No promotion ≥ 6 yrs     +5    Career stagnation signal
--   No promotion 3–5 yrs     +3    Mild stagnation signal
--
-- RISK TIERS:
--   70–100 = CRITICAL  → Immediate HR intervention recommended
--   50–69  = HIGH      → Schedule 1:1 check-ins
--   30–49  = MEDIUM    → Monitor closely
--   0–29   = LOW       → Stable
--
-- USAGE:
--   CALL sp_high_risk_employees(60);  -- employees scoring >= 60
--   CALL sp_high_risk_employees(70);  -- critical tier only
-- ============================================================

USE hr_attrition_db;

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_high_risk_employees$$

CREATE PROCEDURE sp_high_risk_employees(
    IN p_min_risk_score INT
)
BEGIN
    SELECT
        fe.emp_number,
        dd.dept_name                                               AS department,
        jr.role_name                                               AS job_role,
        fe.age,
        fe.monthly_income,
        fe.years_at_company,
        CASE fe.overtime_flag WHEN 1 THEN 'Yes' ELSE 'No' END     AS works_overtime,
        fe.job_satisfaction,
        fe.marital_status,
        fe.business_travel,
        -- Computed risk score (same formula as 06_risk_scoring.sql)
        (
            CASE fe.overtime_flag WHEN 1 THEN 25 ELSE 0 END
            + CASE
                WHEN fe.salary_band_id = 1 THEN 20
                WHEN fe.salary_band_id = 2 THEN 12
                WHEN fe.salary_band_id = 3 THEN 5
                ELSE 0
              END
            + CASE
                WHEN fe.age BETWEEN 18 AND 25 THEN 15
                WHEN fe.age BETWEEN 26 AND 32 THEN 10
                WHEN fe.age BETWEEN 33 AND 40 THEN 5
                ELSE 0
              END
            + CASE
                WHEN fe.years_at_company BETWEEN 0 AND 2 THEN 15
                WHEN fe.years_at_company BETWEEN 3 AND 5 THEN 8
                WHEN fe.years_at_company BETWEEN 6 AND 10 THEN 3
                ELSE 0
              END
            + CASE
                WHEN fe.job_satisfaction = 1 THEN 10
                WHEN fe.job_satisfaction = 2 THEN 6
                WHEN fe.job_satisfaction = 3 THEN 2
                ELSE 0
              END
            + CASE fe.marital_status WHEN 'Single' THEN 5 ELSE 0 END
            + CASE fe.business_travel
                WHEN 'Travel_Frequently' THEN 5
                WHEN 'Travel_Rarely'     THEN 2
                ELSE 0
              END
            + CASE
                WHEN fe.years_since_promotion >= 6 THEN 5
                WHEN fe.years_since_promotion >= 3 THEN 3
                ELSE 0
              END
        )                                                          AS risk_score,
        CASE
            WHEN (
                CASE fe.overtime_flag WHEN 1 THEN 25 ELSE 0 END
                + CASE WHEN fe.salary_band_id = 1 THEN 20 WHEN fe.salary_band_id = 2 THEN 12 WHEN fe.salary_band_id = 3 THEN 5 ELSE 0 END
                + CASE WHEN fe.age BETWEEN 18 AND 25 THEN 15 WHEN fe.age BETWEEN 26 AND 32 THEN 10 WHEN fe.age BETWEEN 33 AND 40 THEN 5 ELSE 0 END
                + CASE WHEN fe.years_at_company BETWEEN 0 AND 2 THEN 15 WHEN fe.years_at_company BETWEEN 3 AND 5 THEN 8 WHEN fe.years_at_company BETWEEN 6 AND 10 THEN 3 ELSE 0 END
                + CASE WHEN fe.job_satisfaction = 1 THEN 10 WHEN fe.job_satisfaction = 2 THEN 6 WHEN fe.job_satisfaction = 3 THEN 2 ELSE 0 END
                + CASE fe.marital_status WHEN 'Single' THEN 5 ELSE 0 END
                + CASE fe.business_travel WHEN 'Travel_Frequently' THEN 5 WHEN 'Travel_Rarely' THEN 2 ELSE 0 END
                + CASE WHEN fe.years_since_promotion >= 6 THEN 5 WHEN fe.years_since_promotion >= 3 THEN 3 ELSE 0 END
            ) >= 70 THEN 'CRITICAL — Immediate Attention'
            WHEN (
                CASE fe.overtime_flag WHEN 1 THEN 25 ELSE 0 END
                + CASE WHEN fe.salary_band_id = 1 THEN 20 WHEN fe.salary_band_id = 2 THEN 12 WHEN fe.salary_band_id = 3 THEN 5 ELSE 0 END
                + CASE WHEN fe.age BETWEEN 18 AND 25 THEN 15 WHEN fe.age BETWEEN 26 AND 32 THEN 10 WHEN fe.age BETWEEN 33 AND 40 THEN 5 ELSE 0 END
                + CASE WHEN fe.years_at_company BETWEEN 0 AND 2 THEN 15 WHEN fe.years_at_company BETWEEN 3 AND 5 THEN 8 WHEN fe.years_at_company BETWEEN 6 AND 10 THEN 3 ELSE 0 END
                + CASE WHEN fe.job_satisfaction = 1 THEN 10 WHEN fe.job_satisfaction = 2 THEN 6 WHEN fe.job_satisfaction = 3 THEN 2 ELSE 0 END
                + CASE fe.marital_status WHEN 'Single' THEN 5 ELSE 0 END
                + CASE fe.business_travel WHEN 'Travel_Frequently' THEN 5 WHEN 'Travel_Rarely' THEN 2 ELSE 0 END
                + CASE WHEN fe.years_since_promotion >= 6 THEN 5 WHEN fe.years_since_promotion >= 3 THEN 3 ELSE 0 END
            ) >= 50 THEN 'HIGH — Monitor Closely'
            ELSE 'MEDIUM — Watch'
        END                                                        AS risk_tier
    FROM fact_employee fe
    JOIN dim_department dd ON fe.dept_id = dd.dept_id
    JOIN dim_job_role   jr ON fe.role_id = jr.role_id
    WHERE fe.attrition_flag = 0   -- active employees only
    HAVING risk_score >= p_min_risk_score
    ORDER BY risk_score DESC;
END$$
DELIMITER ;
