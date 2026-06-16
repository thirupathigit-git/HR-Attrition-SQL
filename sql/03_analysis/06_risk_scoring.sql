-- ============================================================
-- FILE: 03_analysis/06_risk_scoring.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Multi-factor attrition risk score using weighted
--              CASE WHEN logic — the crown jewel analysis query
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- QUERY 1: Individual employee risk score (0–100)
--          Each factor adds points based on attrition correlation
-- ------------------------------------------------------------
WITH risk_scored AS (
    SELECT
        fe.emp_number,
        dd.dept_name,
        jr.role_name,
        fe.age,
        fe.monthly_income,
        fe.years_at_company,
        fe.overtime_flag,
        fe.attrition_flag,

        -- RISK SCORE COMPONENTS (total max = 100 points)
        -- Overtime: strongest single predictor (25 pts max)
        CASE fe.overtime_flag WHEN 1 THEN 25 ELSE 0 END

        -- Salary band: Band 1 = highest risk (20 pts max)
        + CASE
            WHEN fe.salary_band_id = 1 THEN 20
            WHEN fe.salary_band_id = 2 THEN 12
            WHEN fe.salary_band_id = 3 THEN 5
            ELSE 0
          END

        -- Age group: 18–25 highest risk (15 pts max)
        + CASE
            WHEN fe.age BETWEEN 18 AND 25 THEN 15
            WHEN fe.age BETWEEN 26 AND 32 THEN 10
            WHEN fe.age BETWEEN 33 AND 40 THEN 5
            ELSE 0
          END

        -- Tenure: 0–2 yrs highest risk (15 pts max)
        + CASE
            WHEN fe.years_at_company BETWEEN 0  AND 2  THEN 15
            WHEN fe.years_at_company BETWEEN 3  AND 5  THEN 8
            WHEN fe.years_at_company BETWEEN 6  AND 10 THEN 3
            ELSE 0
          END

        -- Job satisfaction: 1 = very dissatisfied (10 pts max)
        + CASE
            WHEN fe.job_satisfaction = 1 THEN 10
            WHEN fe.job_satisfaction = 2 THEN 6
            WHEN fe.job_satisfaction = 3 THEN 2
            ELSE 0
          END

        -- Marital status: Single employees leave more (5 pts max)
        + CASE fe.marital_status WHEN 'Single' THEN 5 ELSE 0 END

        -- Business travel: frequent travelers leave more (5 pts max)
        + CASE fe.business_travel
            WHEN 'Travel_Frequently' THEN 5
            WHEN 'Travel_Rarely'     THEN 2
            ELSE 0
          END

        -- Promotion gap: stalled career (5 pts max)
        + CASE
            WHEN fe.years_since_promotion >= 6 THEN 5
            WHEN fe.years_since_promotion >= 3 THEN 3
            ELSE 0
          END                                     AS risk_score

    FROM fact_employee fe
    JOIN dim_department dd ON fe.dept_id = dd.dept_id
    JOIN dim_job_role   jr ON fe.role_id = jr.role_id
),
risk_tiered AS (
    SELECT
        *,
        CASE
            WHEN risk_score >= 70 THEN 'CRITICAL — Immediate Attention'
            WHEN risk_score >= 50 THEN 'HIGH — Monitor Closely'
            WHEN risk_score >= 30 THEN 'MEDIUM — Watch'
            ELSE                       'LOW — Stable'
        END AS risk_tier,
        RANK() OVER (ORDER BY risk_score DESC) AS risk_rank
    FROM risk_scored
)
SELECT
    emp_number,
    dept_name,
    role_name,
    age,
    monthly_income,
    years_at_company,
    CASE overtime_flag WHEN 1 THEN 'Yes' ELSE 'No' END AS works_overtime,
    risk_score,
    risk_tier,
    risk_rank,
    CASE attrition_flag WHEN 1 THEN 'LEFT' ELSE 'Active' END AS actual_outcome
FROM risk_tiered
ORDER BY risk_score DESC
LIMIT 50;


-- ------------------------------------------------------------
-- QUERY 2: Risk tier summary — how accurate is the model?
--          (Checks if high-risk employees actually did leave more)
-- ------------------------------------------------------------
WITH risk_scored AS (
    SELECT
        attrition_flag,
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
            ) >= 70 THEN 'CRITICAL'
            WHEN (
                CASE fe.overtime_flag WHEN 1 THEN 25 ELSE 0 END
                + CASE WHEN fe.salary_band_id = 1 THEN 20 WHEN fe.salary_band_id = 2 THEN 12 WHEN fe.salary_band_id = 3 THEN 5 ELSE 0 END
                + CASE WHEN fe.age BETWEEN 18 AND 25 THEN 15 WHEN fe.age BETWEEN 26 AND 32 THEN 10 WHEN fe.age BETWEEN 33 AND 40 THEN 5 ELSE 0 END
                + CASE WHEN fe.years_at_company BETWEEN 0 AND 2 THEN 15 WHEN fe.years_at_company BETWEEN 3 AND 5 THEN 8 WHEN fe.years_at_company BETWEEN 6 AND 10 THEN 3 ELSE 0 END
                + CASE WHEN fe.job_satisfaction = 1 THEN 10 WHEN fe.job_satisfaction = 2 THEN 6 WHEN fe.job_satisfaction = 3 THEN 2 ELSE 0 END
                + CASE fe.marital_status WHEN 'Single' THEN 5 ELSE 0 END
                + CASE fe.business_travel WHEN 'Travel_Frequently' THEN 5 WHEN 'Travel_Rarely' THEN 2 ELSE 0 END
                + CASE WHEN fe.years_since_promotion >= 6 THEN 5 WHEN fe.years_since_promotion >= 3 THEN 3 ELSE 0 END
            ) >= 50 THEN 'HIGH'
            WHEN (
                CASE fe.overtime_flag WHEN 1 THEN 25 ELSE 0 END
                + CASE WHEN fe.salary_band_id = 1 THEN 20 WHEN fe.salary_band_id = 2 THEN 12 WHEN fe.salary_band_id = 3 THEN 5 ELSE 0 END
                + CASE WHEN fe.age BETWEEN 18 AND 25 THEN 15 WHEN fe.age BETWEEN 26 AND 32 THEN 10 WHEN fe.age BETWEEN 33 AND 40 THEN 5 ELSE 0 END
                + CASE WHEN fe.years_at_company BETWEEN 0 AND 2 THEN 15 WHEN fe.years_at_company BETWEEN 3 AND 5 THEN 8 WHEN fe.years_at_company BETWEEN 6 AND 10 THEN 3 ELSE 0 END
                + CASE WHEN fe.job_satisfaction = 1 THEN 10 WHEN fe.job_satisfaction = 2 THEN 6 WHEN fe.job_satisfaction = 3 THEN 2 ELSE 0 END
                + CASE fe.marital_status WHEN 'Single' THEN 5 ELSE 0 END
                + CASE fe.business_travel WHEN 'Travel_Frequently' THEN 5 WHEN 'Travel_Rarely' THEN 2 ELSE 0 END
                + CASE WHEN fe.years_since_promotion >= 6 THEN 5 WHEN fe.years_since_promotion >= 3 THEN 3 ELSE 0 END
            ) >= 30 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_tier
    FROM fact_employee fe
)
SELECT
    risk_tier,
    COUNT(*)                                           AS employees_in_tier,
    SUM(attrition_flag)                                AS actual_attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)  AS actual_attrition_rate_pct
FROM risk_scored
GROUP BY risk_tier
ORDER BY
    CASE risk_tier
        WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3 ELSE 4
    END;
