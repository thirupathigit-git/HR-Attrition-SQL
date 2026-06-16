# Power BI Setup Guide — HR Attrition Dashboard

This guide connects Power BI Desktop to the `hr_attrition_db` MySQL database and replicates all key findings as interactive visuals.

---

## Prerequisites

- Power BI Desktop (free download from microsoft.com/power-bi)
- MySQL Connector/NET or ODBC driver installed
- MySQL 8.0 running locally with `hr_attrition_db` loaded

---

## Step 1: Connect Power BI to MySQL

1. Open Power BI Desktop → **Get Data** → **MySQL database**
2. Server: `localhost` | Database: `hr_attrition_db`
3. Select these tables/views:
   - `vw_attrition_dashboard` ← primary data source
   - `vw_salary_risk_bands`
   - `vw_department_health`
4. Click **Load**

> **Tip:** Use views, not raw tables. The views already join all dimensions and compute the risk score — this keeps Power BI DAX simpler.

---

## Step 2: Data Model

No relationships needed — `vw_attrition_dashboard` is a flat denormalized view designed for BI consumption. Power BI treats it as a single table.

If you load multiple views, set these relationships:
- `vw_attrition_dashboard[department]` → `vw_department_health[dept_name]`
- `vw_attrition_dashboard[salary_band]` → `vw_salary_risk_bands[band_label]`

---

## Step 3: DAX Measures

Create these measures in Power BI (Home → New Measure):

### Core KPIs

```dax
-- Overall Attrition Rate
Attrition Rate =
DIVIDE(
    COUNTROWS(FILTER('vw_attrition_dashboard', 'vw_attrition_dashboard'[attrition_flag] = 1)),
    COUNTROWS('vw_attrition_dashboard'),
    0
)

-- Total Attritions
Total Attritions =
COUNTROWS(FILTER('vw_attrition_dashboard', 'vw_attrition_dashboard'[attrition_flag] = 1))

-- Active Headcount
Active Headcount =
COUNTROWS(FILTER('vw_attrition_dashboard', 'vw_attrition_dashboard'[attrition_flag] = 0))

-- Average Monthly Income
Avg Monthly Income =
AVERAGE('vw_attrition_dashboard'[monthly_income])

-- Average Tenure
Avg Tenure (Years) =
AVERAGE('vw_attrition_dashboard'[years_at_company])
```

### Risk Analysis Measures

```dax
-- Overtime Attrition Rate
Overtime Attrition Rate =
DIVIDE(
    COUNTROWS(
        FILTER('vw_attrition_dashboard',
            'vw_attrition_dashboard'[attrition_flag] = 1
            && 'vw_attrition_dashboard'[overtime] = "Yes"
        )
    ),
    COUNTROWS(FILTER('vw_attrition_dashboard', 'vw_attrition_dashboard'[overtime] = "Yes")),
    0
)

-- Non-Overtime Attrition Rate
Non-Overtime Attrition Rate =
DIVIDE(
    COUNTROWS(
        FILTER('vw_attrition_dashboard',
            'vw_attrition_dashboard'[attrition_flag] = 1
            && 'vw_attrition_dashboard'[overtime] = "No"
        )
    ),
    COUNTROWS(FILTER('vw_attrition_dashboard', 'vw_attrition_dashboard'[overtime] = "No")),
    0
)

-- Overtime Risk Multiplier (shows 3.1x in a card)
Overtime Risk Multiplier =
DIVIDE([Overtime Attrition Rate], [Non-Overtime Attrition Rate], 0)

-- High Risk Employee Count (score >= 60)
High Risk Count =
COUNTROWS(
    FILTER('vw_attrition_dashboard',
        'vw_attrition_dashboard'[attrition_risk_score] >= 60
        && 'vw_attrition_dashboard'[attrition_flag] = 0
    )
)

-- Critical Risk Count (score >= 70)
Critical Risk Count =
COUNTROWS(
    FILTER('vw_attrition_dashboard',
        'vw_attrition_dashboard'[attrition_risk_score] >= 70
        && 'vw_attrition_dashboard'[attrition_flag] = 0
    )
)
```

### Attrition Rate by Segment (for tooltips)

```dax
-- Attrition Rate % (formatted string for card visual)
Attrition Rate % =
FORMAT([Attrition Rate], "0.0%")

-- Department vs Company Variance
Dept vs Company Variance =
[Attrition Rate] - CALCULATE([Attrition Rate], ALL('vw_attrition_dashboard'[department]))
```

---

## Step 4: Recommended Dashboard Layout (3 Pages)

### Page 1 — Executive Summary
| Visual | Type | Fields |
|---|---|---|
| Attrition Rate | KPI Card | `Attrition Rate %` |
| Total Attritions | Card | `Total Attritions` |
| Active Headcount | Card | `Active Headcount` |
| Avg Tenure | Card | `Avg Tenure (Years)` |
| Attrition by Department | Bar Chart | department, `Attrition Rate` |
| Attrition by Age Group | Column Chart | age_group, `Attrition Rate` |
| Attrition by Salary Band | Bar Chart | salary_band, `Attrition Rate` |

### Page 2 — Risk Analysis
| Visual | Type | Fields |
|---|---|---|
| Overtime Risk Multiplier | KPI Card | `Overtime Risk Multiplier` |
| Overtime vs Non-OT Rate | Clustered Bar | overtime, `Attrition Rate` |
| Risk Score Distribution | Histogram | attrition_risk_score (bins) |
| High Risk by Department | Bar | department, `High Risk Count` |
| Critical Risk Employees | Table | emp_number, department, job_role, attrition_risk_score |
| Tenure vs Attrition | Scatter | years_at_company, `Attrition Rate` |

### Page 3 — Department Deep Dive
| Visual | Type | Fields |
|---|---|---|
| Department Slicer | Slicer | department |
| Dept Attrition Rate | Gauge | `Attrition Rate` (target: 10%) |
| Role-Level Attrition | Bar | job_role, `Attrition Rate` |
| Avg Satisfaction Score | Card | Average of job_satisfaction |
| Satisfaction vs Attrition | Scatter | job_satisfaction, `Attrition Rate` |
| WLB Score vs Attrition | Scatter | work_life_balance, `Attrition Rate` |

---

## Step 5: Formatting Tips

- Set theme colors: Red `#C0392B` (high attrition), Amber `#E67E22` (medium), Green `#27AE60` (low)
- Add conditional formatting on attrition rate columns: red if > 20%, amber if 12–20%, green if < 12%
- Use `attrition_risk_score` for a color gradient on the employee table

---

## Key Findings to Highlight on Dashboard

| Finding | Value | Visual Suggestion |
|---|---|---|
| Overall attrition rate | 16.1% | KPI card with target line at 10% |
| Overtime multiplier | 3.1x higher | Callout card |
| Highest risk department | Sales — 20.6% | Bar chart highlight |
| Critical tenure window | 0–2 years = 32.6% | Line chart |
| Highest risk combo | Sales + Overtime + Band 1 = 41.2% | Tooltip on scatter |
