-- ============================================================
-- FILE: 06_indexes/performance_indexes.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Composite and covering indexes for query
--              performance optimization on fact_employee
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- INDEX 1: Primary attrition filter — most queries filter on
--          attrition_flag first, then by department
-- ------------------------------------------------------------
CREATE INDEX idx_attrition_dept
ON fact_employee(attrition_flag, dept_id);

-- ------------------------------------------------------------
-- INDEX 2: Overtime + attrition — used in overtime impact queries
-- ------------------------------------------------------------
CREATE INDEX idx_overtime_attrition
ON fact_employee(overtime_flag, attrition_flag, dept_id);

-- ------------------------------------------------------------
-- INDEX 3: Salary band filtering — used in compensation analysis
-- ------------------------------------------------------------
CREATE INDEX idx_salary_band_attrition
ON fact_employee(salary_band_id, attrition_flag);

-- ------------------------------------------------------------
-- INDEX 4: Age + tenure — used in demographic analysis queries
-- ------------------------------------------------------------
CREATE INDEX idx_age_tenure
ON fact_employee(age, years_at_company, attrition_flag);

-- ------------------------------------------------------------
-- INDEX 5: Covering index for the dashboard view query
--          Includes all columns needed to avoid table lookups
-- ------------------------------------------------------------
CREATE INDEX idx_cover_dashboard
ON fact_employee(
    dept_id, role_id, attrition_flag, overtime_flag,
    monthly_income, age, years_at_company, job_satisfaction
);

-- ------------------------------------------------------------
-- VERIFY: Check index usage with EXPLAIN
-- ------------------------------------------------------------
EXPLAIN
SELECT dept_id, COUNT(*), SUM(attrition_flag)
FROM fact_employee
WHERE attrition_flag = 1
GROUP BY dept_id;
