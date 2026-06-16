-- ============================================================
-- FILE: 02_data_prep/etl_pipeline.sql
-- PROJECT: HR Employee Attrition Analysis
-- AUTHOR: Maram Thirupathi
-- DESCRIPTION: Full ETL pipeline — raw CSV → staging → fact table
--
-- PIPELINE STAGES:
--   Stage 1 → Create staging table (raw, no constraints)
--   Stage 2 → Load raw CSV into staging
--   Stage 3 → Clean & validate staging data
--   Stage 4 → Transform & load into normalized fact/dim tables
--   Stage 5 → Post-load validation summary
--
-- Run order:
--   01_schema/create_tables.sql         (first)
--   02_data_prep/insert_lookup_data.sql (second)
--   02_data_prep/etl_pipeline.sql       (third)  ← this file
--   02_data_prep/data_validation.sql    (fourth)
-- ============================================================

USE hr_attrition_db;

-- ============================================================
-- STAGE 1: STAGING TABLE
-- Raw shape matching the IBM HR CSV exactly.
-- All columns VARCHAR — no constraints — so any CSV loads cleanly.
-- We fix data quality issues in Stage 3 before promoting to fact table.
-- ============================================================

DROP TABLE IF EXISTS staging_employee;

CREATE TABLE staging_employee (
    row_id                      INT AUTO_INCREMENT PRIMARY KEY,

    -- IBM HR CSV columns (all raw VARCHAR)
    Age                         VARCHAR(10),
    Attrition                   VARCHAR(10),   -- "Yes" / "No"
    BusinessTravel              VARCHAR(30),
    DailyRate                   VARCHAR(10),
    Department                  VARCHAR(60),
    DistanceFromHome            VARCHAR(10),
    Education                   VARCHAR(10),   -- 1-5 scale
    EducationField              VARCHAR(40),
    EmployeeCount               VARCHAR(10),
    EmployeeNumber              VARCHAR(20),
    EnvironmentSatisfaction     VARCHAR(10),
    Gender                      VARCHAR(10),
    HourlyRate                  VARCHAR(10),
    JobInvolvement              VARCHAR(10),
    JobLevel                    VARCHAR(10),
    JobRole                     VARCHAR(60),
    JobSatisfaction             VARCHAR(10),
    MaritalStatus               VARCHAR(15),
    MonthlyIncome               VARCHAR(10),
    MonthlyRate                 VARCHAR(10),
    NumCompaniesWorked          VARCHAR(10),
    Over18                      VARCHAR(5),
    OverTime                    VARCHAR(5),    -- "Yes" / "No"
    PercentSalaryHike           VARCHAR(10),
    PerformanceRating           VARCHAR(10),
    RelationshipSatisfaction    VARCHAR(10),
    StandardHours               VARCHAR(10),
    StockOptionLevel            VARCHAR(10),
    TotalWorkingYears           VARCHAR(10),
    TrainingTimesLastYear       VARCHAR(10),
    WorkLifeBalance             VARCHAR(10),
    YearsAtCompany              VARCHAR(10),
    YearsInCurrentRole          VARCHAR(10),
    YearsSinceLastPromotion     VARCHAR(10),
    YearsWithCurrManager        VARCHAR(10),

    -- ETL audit columns
    load_timestamp              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    load_status                 VARCHAR(20) DEFAULT 'PENDING',  -- PENDING / CLEAN / REJECTED
    rejection_reason            VARCHAR(200) DEFAULT NULL
);


-- ============================================================
-- STAGE 2: LOAD RAW CSV
--
-- Option A: MySQL LOAD DATA INFILE (fastest — requires FILE privilege)
-- Option B: MySQL Workbench Table Data Import Wizard (GUI, no privilege needed)
-- Option C: mysqlimport command-line tool
--
-- Using Option A below. Update the file path to match your system.
-- Windows:  'C:/datasets/WA_Fn-UseC_-HR-Employee-Attrition.csv'
-- Linux/Mac: '/home/user/datasets/WA_Fn-UseC_-HR-Employee-Attrition.csv'
-- ============================================================

LOAD DATA INFILE '/path/to/WA_Fn-UseC_-HR-Employee-Attrition.csv'
INTO TABLE staging_employee
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS   -- skip header row
(
    Age, Attrition, BusinessTravel, DailyRate, Department,
    DistanceFromHome, Education, EducationField, EmployeeCount,
    EmployeeNumber, EnvironmentSatisfaction, Gender, HourlyRate,
    JobInvolvement, JobLevel, JobRole, JobSatisfaction, MaritalStatus,
    MonthlyIncome, MonthlyRate, NumCompaniesWorked, Over18, OverTime,
    PercentSalaryHike, PerformanceRating, RelationshipSatisfaction,
    StandardHours, StockOptionLevel, TotalWorkingYears,
    TrainingTimesLastYear, WorkLifeBalance, YearsAtCompany,
    YearsInCurrentRole, YearsSinceLastPromotion, YearsWithCurrManager
);

-- Confirm raw row count after load (should be 1,470)
SELECT CONCAT('Staging loaded: ', COUNT(*), ' rows') AS load_status
FROM staging_employee;


-- ============================================================
-- STAGE 3: CLEAN & VALIDATE STAGING DATA
--
-- Rule 1: Mark rows with missing mandatory fields as REJECTED
-- Rule 2: Mark rows with out-of-range values as REJECTED
-- Rule 3: Mark remaining rows as CLEAN
-- ============================================================

-- Rule 1: Reject rows with NULL or empty mandatory fields
UPDATE staging_employee
SET
    load_status      = 'REJECTED',
    rejection_reason = 'Missing mandatory field'
WHERE
    TRIM(COALESCE(EmployeeNumber, '')) = ''
    OR TRIM(COALESCE(Age,            '')) = ''
    OR TRIM(COALESCE(Department,     '')) = ''
    OR TRIM(COALESCE(MonthlyIncome,  '')) = ''
    OR TRIM(COALESCE(Attrition,      '')) = ''
    OR TRIM(COALESCE(OverTime,       '')) = '';

-- Rule 2: Reject rows with out-of-range numeric values
UPDATE staging_employee
SET
    load_status      = 'REJECTED',
    rejection_reason = 'Out-of-range value'
WHERE
    load_status != 'REJECTED'
    AND (
        CAST(Age AS UNSIGNED)                  NOT BETWEEN 18 AND 70
        OR CAST(Education AS UNSIGNED)         NOT BETWEEN 1  AND 5
        OR CAST(JobSatisfaction AS UNSIGNED)   NOT BETWEEN 1  AND 4
        OR CAST(PerformanceRating AS UNSIGNED) NOT BETWEEN 1  AND 4
        OR CAST(MonthlyIncome AS DECIMAL(10,2)) < 1000
    );

-- Rule 3: Mark surviving rows as CLEAN
UPDATE staging_employee
SET load_status = 'CLEAN'
WHERE load_status = 'PENDING';

-- Rejection summary report
SELECT
    load_status,
    COUNT(*)         AS row_count,
    rejection_reason
FROM staging_employee
GROUP BY load_status, rejection_reason
ORDER BY load_status;


-- ============================================================
-- STAGE 4: TRANSFORM & LOAD INTO NORMALIZED TABLES
--
-- Maps staging columns → fact_employee using dim table lookups.
-- Only CLEAN rows are promoted.
--
-- Key transformations applied:
--   "Yes"/"No"    → 1/0    (attrition_flag, overtime_flag)
--   MonthlyIncome → salary_band_id  (range lookup via dim_salary_band)
--   Education 1-5 → education_id    (lookup via dim_education)
--   Department    → dept_id         (lookup via dim_department)
--   JobRole       → role_id         (lookup via dim_job_role)
-- ============================================================

INSERT INTO fact_employee (
    emp_number,
    dept_id,
    role_id,
    education_id,
    salary_band_id,
    age,
    gender,
    marital_status,
    distance_from_home_km,
    monthly_income,
    percent_salary_hike,
    stock_option_level,
    total_working_years,
    years_at_company,
    years_in_current_role,
    years_since_promotion,
    years_with_curr_mgr,
    num_companies_worked,
    overtime_flag,
    business_travel,
    training_times_lastyear,
    job_satisfaction,
    environment_satisfaction,
    work_life_balance,
    relationship_satisfaction,
    job_involvement,
    performance_rating,
    attrition_flag
)
SELECT
    TRIM(s.EmployeeNumber),

    -- Dimension FK lookups (text → surrogate key)
    dd.dept_id,
    jr.role_id,
    de.education_id,
    sb.salary_band_id,

    -- Demographics
    CAST(s.Age               AS UNSIGNED),
    TRIM(s.Gender),
    TRIM(s.MaritalStatus),
    CAST(s.DistanceFromHome  AS UNSIGNED),

    -- Compensation
    CAST(s.MonthlyIncome     AS DECIMAL(10,2)),
    CAST(s.PercentSalaryHike AS UNSIGNED),
    CAST(s.StockOptionLevel  AS UNSIGNED),

    -- Work history
    CAST(s.TotalWorkingYears        AS UNSIGNED),
    CAST(s.YearsAtCompany           AS UNSIGNED),
    CAST(s.YearsInCurrentRole       AS UNSIGNED),
    CAST(s.YearsSinceLastPromotion  AS UNSIGNED),
    CAST(s.YearsWithCurrManager     AS UNSIGNED),
    CAST(s.NumCompaniesWorked       AS UNSIGNED),

    -- Work conditions (text → boolean 0/1)
    CASE TRIM(s.OverTime)       WHEN 'Yes' THEN 1 ELSE 0 END,
    TRIM(s.BusinessTravel),
    CAST(s.TrainingTimesLastYear AS UNSIGNED),

    -- Satisfaction scores
    CAST(s.JobSatisfaction          AS UNSIGNED),
    CAST(s.EnvironmentSatisfaction  AS UNSIGNED),
    CAST(s.WorkLifeBalance          AS UNSIGNED),
    CAST(s.RelationshipSatisfaction AS UNSIGNED),
    CAST(s.JobInvolvement           AS UNSIGNED),
    CAST(s.PerformanceRating        AS UNSIGNED),

    -- Target variable (text → boolean 0/1)
    CASE TRIM(s.Attrition) WHEN 'Yes' THEN 1 ELSE 0 END

FROM staging_employee s
JOIN dim_department  dd ON dd.dept_name      = TRIM(s.Department)
JOIN dim_job_role    jr ON jr.role_name      = TRIM(s.JobRole)
JOIN dim_education   de ON de.education_code = CAST(s.Education AS UNSIGNED)
JOIN dim_salary_band sb
    ON CAST(s.MonthlyIncome AS DECIMAL(10,2))
       BETWEEN sb.monthly_min AND sb.monthly_max
WHERE s.load_status = 'CLEAN';

SELECT CONCAT('fact_employee loaded: ', COUNT(*), ' rows') AS final_status
FROM fact_employee;


-- ============================================================
-- STAGE 5: ETL SUMMARY REPORT
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM staging_employee)                                AS total_raw_rows,
    (SELECT COUNT(*) FROM staging_employee WHERE load_status = 'CLEAN')    AS clean_rows,
    (SELECT COUNT(*) FROM staging_employee WHERE load_status = 'REJECTED') AS rejected_rows,
    (SELECT COUNT(*) FROM fact_employee)                                   AS loaded_to_fact,
    ROUND(
        (SELECT COUNT(*) FROM fact_employee) * 100.0
        / NULLIF((SELECT COUNT(*) FROM staging_employee), 0), 2
    )                                                                      AS load_success_rate_pct;
