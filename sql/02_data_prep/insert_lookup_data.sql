-- ============================================================
-- FILE: 02_data_prep/insert_lookup_data.sql
-- PROJECT: HR Employee Attrition Analysis
-- DESCRIPTION: Populates all 4 dimension tables with reference data
-- ============================================================

USE hr_attrition_db;

-- ------------------------------------------------------------
-- Departments (from IBM HR dataset)
-- ------------------------------------------------------------
INSERT INTO dim_department (dept_name) VALUES
    ('Human Resources'),
    ('Research & Development'),
    ('Sales');

-- ------------------------------------------------------------
-- Job Roles
-- ------------------------------------------------------------
INSERT INTO dim_job_role (role_name, role_level) VALUES
    ('Healthcare Representative', 'Mid'),
    ('Human Resources',           'Entry'),
    ('Laboratory Technician',     'Entry'),
    ('Manager',                   'Manager'),
    ('Manufacturing Director',    'Director'),
    ('Research Director',         'Director'),
    ('Research Scientist',        'Mid'),
    ('Sales Executive',           'Mid'),
    ('Sales Representative',      'Entry');

-- ------------------------------------------------------------
-- Education Levels
-- ------------------------------------------------------------
INSERT INTO dim_education (education_code, education_label) VALUES
    (1, 'Below College'),
    (2, 'College'),
    (3, 'Bachelor'),
    (4, 'Master'),
    (5, 'Doctor');

-- ------------------------------------------------------------
-- Salary Bands (based on IBM HR income distribution)
-- ------------------------------------------------------------
INSERT INTO dim_salary_band (band_label, monthly_min, monthly_max, band_description) VALUES
    ('Band 1',  1009.00,  4999.00, 'Entry-level compensation'),
    ('Band 2',  5000.00,  9999.00, 'Mid-level compensation'),
    ('Band 3', 10000.00, 14999.00, 'Senior-level compensation'),
    ('Band 4', 15000.00, 19999.00, 'Leadership compensation');
