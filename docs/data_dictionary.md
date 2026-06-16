# Data Dictionary — HR Employee Attrition Analysis

## Source Dataset
**IBM HR Analytics Employee Attrition & Performance**
- Source: [Kaggle](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset)
- Original rows: 1,470 employees, 35 attributes
- Project rows: ~15,000 (expanded using stratified sampling)
- License: Open Database License (ODbL)

---

## Table: `fact_employee`

| Column | Type | Description | Source Column |
|---|---|---|---|
| `employee_id` | INT (PK) | Auto-generated surrogate key | — |
| `emp_number` | VARCHAR | Original employee identifier | EmployeeNumber |
| `dept_id` | TINYINT (FK) | Reference to dim_department | Department |
| `role_id` | TINYINT (FK) | Reference to dim_job_role | JobRole |
| `education_id` | TINYINT (FK) | Reference to dim_education | Education |
| `salary_band_id` | TINYINT (FK) | Reference to dim_salary_band | MonthlyIncome (derived) |
| `age` | TINYINT | Employee age in years | Age |
| `gender` | ENUM | Male / Female | Gender |
| `marital_status` | ENUM | Single / Married / Divorced | MaritalStatus |
| `distance_from_home_km` | SMALLINT | Distance in km | DistanceFromHome |
| `monthly_income` | DECIMAL | Monthly salary in ₹ / $ | MonthlyIncome |
| `percent_salary_hike` | TINYINT | Last salary hike % | PercentSalaryHike |
| `stock_option_level` | TINYINT | 0=none, 1-3=increasing | StockOptionLevel |
| `total_working_years` | TINYINT | Career total experience | TotalWorkingYears |
| `years_at_company` | TINYINT | Tenure at current company | YearsAtCompany |
| `years_in_current_role` | TINYINT | Tenure in current role | YearsInCurrentRole |
| `years_since_promotion` | TINYINT | Years since last promotion | YearsSinceLastPromotion |
| `years_with_curr_mgr` | TINYINT | Years under current manager | YearsWithCurrManager |
| `num_companies_worked` | TINYINT | Total employers in career | NumCompaniesWorked |
| `overtime_flag` | TINYINT(1) | 1=Works OT, 0=Does not | OverTime |
| `business_travel` | ENUM | Travel frequency | BusinessTravel |
| `training_times_lastyear` | TINYINT | # training sessions attended | TrainingTimesLastYear |
| `job_satisfaction` | TINYINT | 1=Low, 4=Very High | JobSatisfaction |
| `environment_satisfaction` | TINYINT | 1=Low, 4=Very High | EnvironmentSatisfaction |
| `work_life_balance` | TINYINT | 1=Bad, 4=Best | WorkLifeBalance |
| `relationship_satisfaction` | TINYINT | 1=Low, 4=Very High | RelationshipSatisfaction |
| `job_involvement` | TINYINT | 1=Low, 4=Very High | JobInvolvement |
| `performance_rating` | TINYINT | 1=Low, 4=Outstanding | PerformanceRating |
| `attrition_flag` | TINYINT(1) | **Target: 1=Left, 0=Stayed** | Attrition |

---

## Table: `dim_department`

| Column | Description |
|---|---|
| `dept_id` | PK |
| `dept_name` | Human Resources / Research & Development / Sales |

---

## Table: `dim_salary_band`

| Band | Monthly Range | Description |
|---|---|---|
| Band 1 | ₹1,009 – ₹4,999 | Entry-level compensation |
| Band 2 | ₹5,000 – ₹9,999 | Mid-level compensation |
| Band 3 | ₹10,000 – ₹14,999 | Senior-level compensation |
| Band 4 | ₹15,000 – ₹19,999 | Leadership compensation |

---

## Satisfaction Scale (all 1–4 fields)

| Score | Label |
|---|---|
| 1 | Low / Bad / Poor |
| 2 | Medium / Fair |
| 3 | High / Good |
| 4 | Very High / Best / Outstanding |
