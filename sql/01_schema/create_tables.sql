-- ============================================================
-- FILE: 01_schema/create_tables.sql
-- PROJECT: HR Employee Attrition Analysis
-- AUTHOR: Maram Thirupathi
-- DESCRIPTION: Creates normalized 3NF schema with 5 tables
--              for HR attrition analysis
-- ============================================================

CREATE DATABASE IF NOT EXISTS hr_attrition_db;
USE hr_attrition_db;

-- ------------------------------------------------------------
-- DIMENSION TABLE 1: Department
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_department (
    dept_id       TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    dept_name     VARCHAR(50)       NOT NULL,
    dept_head     VARCHAR(100)          NULL,
    created_at    TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_department PRIMARY KEY (dept_id),
    CONSTRAINT uq_dept_name  UNIQUE      (dept_name)
);

-- ------------------------------------------------------------
-- DIMENSION TABLE 2: Job Role
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_job_role (
    role_id       TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    role_name     VARCHAR(60)       NOT NULL,
    role_level    ENUM('Entry','Mid','Senior','Lead','Manager','Director') NOT NULL DEFAULT 'Entry',
    CONSTRAINT pk_job_role  PRIMARY KEY (role_id),
    CONSTRAINT uq_role_name UNIQUE      (role_name)
);

-- ------------------------------------------------------------
-- DIMENSION TABLE 3: Education Level
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_education (
    education_id    TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    education_code  TINYINT          NOT NULL,   -- original 1-5 scale
    education_label VARCHAR(40)      NOT NULL,   -- Below College / College / Bachelor / Master / Doctor
    CONSTRAINT pk_education PRIMARY KEY (education_id)
);

-- ------------------------------------------------------------
-- DIMENSION TABLE 4: Salary Band
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_salary_band (
    salary_band_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    band_label       VARCHAR(20)      NOT NULL,   -- Band 1 / Band 2 / Band 3 / Band 4
    monthly_min      DECIMAL(10,2)    NOT NULL,
    monthly_max      DECIMAL(10,2)    NOT NULL,
    band_description VARCHAR(60)      NOT NULL,
    CONSTRAINT pk_salary_band  PRIMARY KEY (salary_band_id),
    CONSTRAINT chk_salary_range CHECK (monthly_min < monthly_max)
);

-- ------------------------------------------------------------
-- FACT TABLE: Employee (core records)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fact_employee (
    employee_id           INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    emp_number            VARCHAR(20)     NOT NULL,  -- original EmployeeNumber
    dept_id               TINYINT UNSIGNED NOT NULL,
    role_id               TINYINT UNSIGNED NOT NULL,
    education_id          TINYINT UNSIGNED NOT NULL,
    salary_band_id        TINYINT UNSIGNED NOT NULL,

    -- Demographics
    age                   TINYINT UNSIGNED NOT NULL,
    gender                ENUM('Male','Female') NOT NULL,
    marital_status        ENUM('Single','Married','Divorced') NOT NULL,
    distance_from_home_km SMALLINT UNSIGNED NOT NULL,

    -- Compensation
    monthly_income        DECIMAL(10,2)   NOT NULL,
    percent_salary_hike   TINYINT UNSIGNED NOT NULL,
    stock_option_level    TINYINT UNSIGNED NOT NULL DEFAULT 0,

    -- Work history
    total_working_years   TINYINT UNSIGNED NOT NULL,
    years_at_company      TINYINT UNSIGNED NOT NULL,
    years_in_current_role TINYINT UNSIGNED NOT NULL,
    years_since_promotion TINYINT UNSIGNED NOT NULL,
    years_with_curr_mgr   TINYINT UNSIGNED NOT NULL,
    num_companies_worked  TINYINT UNSIGNED NOT NULL,

    -- Work conditions
    overtime_flag         TINYINT(1)      NOT NULL DEFAULT 0,  -- 1=Yes, 0=No
    business_travel       ENUM('Non-Travel','Travel_Rarely','Travel_Frequently') NOT NULL,
    training_times_lastyear TINYINT UNSIGNED NOT NULL,

    -- Satisfaction scores (1-4 scale)
    job_satisfaction      TINYINT UNSIGNED NOT NULL,
    environment_satisfaction TINYINT UNSIGNED NOT NULL,
    work_life_balance     TINYINT UNSIGNED NOT NULL,
    relationship_satisfaction TINYINT UNSIGNED NOT NULL,
    job_involvement       TINYINT UNSIGNED NOT NULL,
    performance_rating    TINYINT UNSIGNED NOT NULL,

    -- Target variable
    attrition_flag        TINYINT(1)      NOT NULL DEFAULT 0,  -- 1=Left, 0=Stayed

    -- Audit
    record_created_at     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_employee     PRIMARY KEY (employee_id),
    CONSTRAINT uq_emp_number   UNIQUE      (emp_number),
    CONSTRAINT fk_emp_dept     FOREIGN KEY (dept_id)         REFERENCES dim_department(dept_id),
    CONSTRAINT fk_emp_role     FOREIGN KEY (role_id)         REFERENCES dim_job_role(role_id),
    CONSTRAINT fk_emp_edu      FOREIGN KEY (education_id)    REFERENCES dim_education(education_id),
    CONSTRAINT fk_emp_salary   FOREIGN KEY (salary_band_id)  REFERENCES dim_salary_band(salary_band_id),

    CONSTRAINT chk_age                CHECK (age BETWEEN 18 AND 70),
    CONSTRAINT chk_job_satisfaction   CHECK (job_satisfaction BETWEEN 1 AND 4),
    CONSTRAINT chk_env_satisfaction   CHECK (environment_satisfaction BETWEEN 1 AND 4),
    CONSTRAINT chk_wlb                CHECK (work_life_balance BETWEEN 1 AND 4),
    CONSTRAINT chk_perf               CHECK (performance_rating BETWEEN 1 AND 4)
);
