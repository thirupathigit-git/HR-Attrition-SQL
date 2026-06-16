-- ============================================================
-- FILE: 03_analysis/04_age_tenure_analysis.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Age group and tenure (years at company) analysis
--              using LAG(), age brackets, and tenure windows
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- QUERY 1: Attrition by age group (5-year brackets)
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN age BETWEEN 18 AND 24 THEN '18–24'
        WHEN age BETWEEN 25 AND 34 THEN '25–34'
        WHEN age BETWEEN 35 AND 44 THEN '35–44'
        WHEN age BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END                                               AS age_group,
    COUNT(*)                                           AS headcount,
    SUM(attrition_flag)                                AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)  AS attrition_rate_pct,
    ROUND(AVG(monthly_income), 2)                     AS avg_income,
    ROUND(AVG(job_satisfaction), 2)                   AS avg_satisfaction
FROM fact_employee
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN '18–24' THEN 1 WHEN '25–34' THEN 2
        WHEN '35–44' THEN 3 WHEN '45–54' THEN 4
        ELSE 5
    END;


-- ------------------------------------------------------------
-- QUERY 2: Tenure (years at company) vs attrition
--          The "critical window" analysis
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN years_at_company BETWEEN 0  AND 2  THEN '0–2 yrs  (New hire)'
        WHEN years_at_company BETWEEN 3  AND 5  THEN '3–5 yrs  (Early career)'
        WHEN years_at_company BETWEEN 6  AND 10 THEN '6–10 yrs (Mid career)'
        WHEN years_at_company BETWEEN 11 AND 20 THEN '11–20 yrs (Senior)'
        ELSE '20+ yrs (Veteran)'
    END                                               AS tenure_band,
    COUNT(*)                                           AS headcount,
    SUM(attrition_flag)                                AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)  AS attrition_rate_pct,
    ROUND(AVG(years_since_promotion), 1)              AS avg_yrs_since_promotion
FROM fact_employee
GROUP BY tenure_band
ORDER BY
    CASE tenure_band
        WHEN '0–2 yrs  (New hire)'     THEN 1
        WHEN '3–5 yrs  (Early career)' THEN 2
        WHEN '6–10 yrs (Mid career)'   THEN 3
        WHEN '11–20 yrs (Senior)'      THEN 4
        ELSE 5
    END;


-- ------------------------------------------------------------
-- QUERY 3: Years since last promotion vs attrition
--          Long gaps without promotion correlate with attrition
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN years_since_promotion = 0 THEN 'Recently promoted'
        WHEN years_since_promotion BETWEEN 1 AND 2 THEN '1–2 yrs ago'
        WHEN years_since_promotion BETWEEN 3 AND 5 THEN '3–5 yrs ago'
        ELSE '6+ yrs ago (Stalled)'
    END                                               AS promotion_gap,
    COUNT(*)                                           AS headcount,
    SUM(attrition_flag)                                AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)  AS attrition_rate_pct
FROM fact_employee
GROUP BY promotion_gap
ORDER BY attrition_rate_pct DESC;


-- ------------------------------------------------------------
-- QUERY 4: Number of companies worked (job-hopping pattern)
--          using ROW_NUMBER() and LAG() to show trend
-- ------------------------------------------------------------
WITH hopping_stats AS (
    SELECT
        num_companies_worked,
        COUNT(*)                                               AS headcount,
        SUM(attrition_flag)                                    AS attritions,
        ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)      AS attrition_rate
    FROM fact_employee
    GROUP BY num_companies_worked
),
with_lag AS (
    SELECT
        num_companies_worked,
        headcount,
        attritions,
        attrition_rate,
        LAG(attrition_rate) OVER (ORDER BY num_companies_worked) AS prev_rate,
        ROW_NUMBER() OVER (ORDER BY num_companies_worked)        AS rn
    FROM hopping_stats
)
SELECT
    num_companies_worked,
    headcount,
    attritions,
    attrition_rate,
    prev_rate                                                   AS prev_company_count_rate,
    ROUND(attrition_rate - COALESCE(prev_rate, attrition_rate), 2) AS rate_change_vs_prev
FROM with_lag
ORDER BY num_companies_worked;


-- ------------------------------------------------------------
-- QUERY 5: Age + Tenure combined risk matrix (cross-tab)
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN age < 30 THEN 'Under 30'
        WHEN age < 40 THEN '30–39'
        ELSE '40+'
    END                                               AS age_group,
    CASE
        WHEN years_at_company <= 2 THEN '0–2 yrs'
        WHEN years_at_company <= 5 THEN '3–5 yrs'
        ELSE '6+ yrs'
    END                                               AS tenure_group,
    COUNT(*)                                           AS headcount,
    SUM(attrition_flag)                                AS attritions,
    ROUND(SUM(attrition_flag) * 100.0 / COUNT(*), 2)  AS attrition_rate_pct
FROM fact_employee
GROUP BY age_group, tenure_group
ORDER BY attrition_rate_pct DESC;
