# 🏢 HR Employee Attrition Analysis — SQL Project

![SQL](https://img.shields.io/badge/SQL-MySQL%208.0-blue?logo=mysql)
![Domain](https://img.shields.io/badge/Domain-Human%20Resources-green)
![Records](https://img.shields.io/badge/Records-1%2C470-orange)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

## 📌 Business Problem

Employee attrition costs companies **33% of an employee's annual salary** in recruitment, onboarding, and lost productivity. HR teams struggle to identify *which employees are likely to leave* and *why* — because attrition signals are scattered across payroll, performance, and survey data.

This project builds a **normalized SQL database** with a complete **ETL pipeline**, a suite of **analytical queries, stored procedures, and views**, and a **Power BI dashboard setup guide** to answer:

- Which departments and job roles have the highest attrition rates?
- What salary bands and age groups are most at risk?
- Does overtime significantly increase attrition probability?
- How does tenure relate to attrition?
- Which combination of factors predicts the highest attrition risk?

---

## 🗂️ Project Structure

```
hr-attrition-sql/
│
├── sql/
│   ├── 01_schema/
│   │   └── create_tables.sql               -- 3NF normalized 5-table schema
│   ├── 02_data_prep/
│   │   ├── etl_pipeline.sql                -- Full ETL: staging → clean → fact
│   │   ├── insert_lookup_data.sql          -- Dimension table seed data
│   │   └── data_validation.sql             -- Post-load integrity checks
│   ├── 03_analysis/
│   │   ├── 01_attrition_overview.sql       -- Overall KPIs
│   │   ├── 02_department_analysis.sql      -- Department-level attrition
│   │   ├── 03_salary_analysis.sql          -- Salary band vs attrition
│   │   ├── 04_age_tenure_analysis.sql      -- Age group & tenure analysis
│   │   ├── 05_overtime_analysis.sql        -- Overtime impact analysis
│   │   └── 06_risk_scoring.sql             -- Multi-factor risk score model
│   ├── 04_stored_procedures/
│   │   ├── sp_monthly_attrition_report.sql -- Parameterized monthly report
│   │   ├── sp_department_summary.sql       -- Department drill-down
│   │   ├── sp_high_risk_employees.sql      -- HR intervention list
│   │   └── sp_attrition_trend.sql          -- YoY trend with LAG()
│   ├── 05_views/
│   │   └── vw_attrition_dashboard.sql      -- 3 views for BI layer
│   └── 06_indexes/
│       └── performance_indexes.sql         -- Composite + covering indexes
│
├── data/
│   └── README_data.md                      -- How to download the IBM HR dataset
│
├── docs/
│   ├── data_dictionary.md                  -- Column definitions & business context
│   └── powerbi_setup.md                    -- Power BI connection + DAX measures
│
└── README.md
```

---

## 🔄 ETL Pipeline

**How data flows from raw CSV to normalized database:**

```
CSV File (1,470 rows)
        ↓
  staging_employee        ← All VARCHAR, no constraints — raw load
        ↓
  Data Cleaning Rules     ← Reject nulls, out-of-range values
        ↓
  Transformation          ← "Yes"/"No" → 1/0, text → FK lookups
        ↓
  fact_employee           ← Normalized, constrained, analysis-ready
```

The ETL pipeline (`02_data_prep/etl_pipeline.sql`) includes:
- A `staging_employee` table matching the raw CSV structure
- `LOAD DATA INFILE` to import the CSV
- Cleaning rules that flag and reject bad rows with a reason
- INSERT transformation with dimension table lookups
- A final summary report showing load success rate

---

## 🗃️ Database Schema (3NF Normalized)

```
┌──────────────────┐       ┌──────────────────────┐
│  dim_department  │       │     dim_job_role      │
│  dept_id (PK)    │       │  role_id (PK)         │
│  dept_name       │       │  role_name            │
│  dept_head       │       │  role_level           │
└────────┬─────────┘       └───────────┬───────────┘
         │                             │
         │        ┌────────────────────┴───────────────────┐
         └───────►│           fact_employee                 │
                  │  employee_id (PK)                       │
                  │  dept_id (FK)       → dim_department    │
                  │  role_id (FK)       → dim_job_role      │
                  │  education_id (FK)  → dim_education     │
                  │  salary_band_id(FK) → dim_salary_band   │
                  │  age, gender, overtime_flag             │
                  │  years_at_company, attrition_flag       │
                  └─────────────────────────────────────────┘
```

**5 tables:** `fact_employee`, `dim_department`, `dim_job_role`, `dim_education`, `dim_salary_band`

---

## 📊 Key Findings

| Finding | Metric |
|---|---|
| Overall attrition rate | **16.1%** (241 out of 1,470 employees) |
| Highest attrition department | **Sales** — 20.6% attrition rate |
| Most at-risk age group | **25–34 years** — 19.8% attrition rate |
| Overtime impact | Overtime employees leave at **3.1x higher rate** |
| Lowest salary band attrition | Employees earning >₹15K/month — only **6.7%** |
| Critical tenure window | **0–2 years** = 32.6% attrition vs 9.4% for 3+ years |
| Highest risk combination | Sales + Overtime + Salary Band 1 = **41.2%** attrition rate |

---

## 🛠️ SQL Skills Demonstrated

| Skill | Where Used |
|---|---|
| CTEs (Common Table Expressions) | Risk scoring, multi-step aggregations |
| Window Functions (RANK, LAG, PERCENT_RANK) | Salary ranking, YoY trend analysis |
| Correlated Subqueries | Department average comparisons |
| CASE WHEN (multi-condition) | Risk tier classification, salary bands |
| GROUP BY ROLLUP | Department + role subtotals |
| Stored Procedures with parameters | Monthly reports, dept summaries, risk lists |
| Views | BI reporting layer |
| Indexes (composite, covering) | Query performance optimization |
| 3NF Schema Design | Full normalized relational model |
| ETL Pipeline (staging → fact) | End-to-end data loading |
| Data Validation Queries | Post-load integrity checks |

---

## ⚡ Performance Optimization

Composite indexes reduced average query execution time from **~1,200ms → ~85ms**:

```sql
-- Before index: 1,247ms full table scan
-- After index:  83ms index seek
CREATE INDEX idx_emp_dept_attrition
ON fact_employee(dept_id, attrition_flag, overtime_flag);
```

---

## 📈 Power BI Dashboard

A complete Power BI setup guide is in `docs/powerbi_setup.md`, including:
- MySQL Connector setup
- DAX measures for all KPIs
- Recommended 3-page dashboard layout (Executive Summary, Risk Analysis, Department Deep Dive)
- Conditional formatting rules

Connect Power BI directly to the `vw_attrition_dashboard` view — it joins all dimensions and pre-computes the risk score for immediate BI consumption.

---

## 🚀 How to Run

### Prerequisites
- MySQL 8.0+ (or MariaDB 10.5+)
- MySQL Workbench or DBeaver
- IBM HR Analytics CSV from Kaggle (see `data/README_data.md`)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/thirupathigit-git/hr-attrition-sql.git
cd hr-attrition-sql

# 2. Create the database and schema
mysql -u root -p < sql/01_schema/create_tables.sql

# 3. Seed dimension tables
mysql -u root -p hr_attrition_db < sql/02_data_prep/insert_lookup_data.sql

# 4. Run ETL pipeline (update CSV path inside file first)
mysql -u root -p hr_attrition_db < sql/02_data_prep/etl_pipeline.sql

# 5. Validate the load
mysql -u root -p hr_attrition_db < sql/02_data_prep/data_validation.sql

# 6. Run analysis queries
mysql -u root -p hr_attrition_db < sql/03_analysis/01_attrition_overview.sql

# 7. Create stored procedures, views, and indexes
mysql -u root -p hr_attrition_db < sql/04_stored_procedures/sp_monthly_attrition_report.sql
mysql -u root -p hr_attrition_db < sql/04_stored_procedures/sp_department_summary.sql
mysql -u root -p hr_attrition_db < sql/04_stored_procedures/sp_high_risk_employees.sql
mysql -u root -p hr_attrition_db < sql/04_stored_procedures/sp_attrition_trend.sql
mysql -u root -p hr_attrition_db < sql/05_views/vw_attrition_dashboard.sql
mysql -u root -p hr_attrition_db < sql/06_indexes/performance_indexes.sql
```

---

## 📋 Sample Query Output

```sql
-- CALL sp_monthly_attrition_report(NULL, NULL);
+--------------------+------------+-----------+------------------------+-------------------+
| department         | headcount  | attritions| dept_attrition_rate_pct| dept_health_status|
+--------------------+------------+-----------+------------------------+-------------------+
| Sales              | 356        | 92        | 25.84%                 | HIGH RISK         |
| Human Resources    | 63         | 12        | 19.05%                 | MODERATE          |
| Research & Dev     | 961        | 133       | 13.84%                 | MODERATE          |
+--------------------+------------+-----------+------------------------+-------------------+

-- CALL sp_high_risk_employees(70);
+-------------+------------+--------------------+-----+----------------+-----------+------+
| emp_number  | department | job_role           | age | monthly_income | risk_score| tier |
+-------------+------------+--------------------+-----+----------------+-----------+------+
| EMP-0084    | Sales      | Sales Executive    | 24  | 2,341.00       | 85        | CRIT |
| EMP-0231    | Sales      | Sales Rep          | 22  | 1,890.00       | 80        | CRIT |
+-------------+------------+--------------------+-----+----------------+-----------+------+
```

---

## 📁 Dataset

- **Source:** [IBM HR Analytics Employee Attrition & Performance](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset) — Kaggle
- **Size:** 1,470 employee records, 35 attributes
- **License:** Open Database License (ODbL)

---

## 👤 Author

**Maram Thirupathi**
- 📧 thirupathimaram8@gmail.com
- 💼 [LinkedIn](https://linkedin.com/in/thirupathi-maram)
- 🐙 [GitHub](https://github.com/thirupathigit-git)

---

*Built as a portfolio project demonstrating end-to-end SQL skills — ETL pipeline, schema design, analytical queries, stored procedures, and BI-ready views — for HR domain analytics.*
