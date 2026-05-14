# 🏙️ UK Workplace Employment Analysis (2009–2019)

> **End-to-end data analytics project** covering Excel cleaning, SQL transformation, Python analysis, and Power BI visualisation — using ONS Workplace Employment data across UK Local Authorities.

---

## 📌 Project Overview

This project analyses **workplace employment trends** across UK regions and London boroughs from **2009 to 2019**, sourced from the [London Datastore / ONS](https://data.london.gov.uk/dataset/workplace-employment-by-publicprivate-sector-borough-29j6q/).

The analysis is split across **four tools**, each building on the previous stage:

| Stage | Tool | Purpose |
|-------|------|---------|
| 1 | **Microsoft Excel** | Raw data cleaning & consolidation |
| 2 | **MySQL** | Deeper validation, transformation & analytics |
| 3 | **Python** | Statistical analysis, EDA & visualisation |
| 4 | **Power BI** | Interactive dashboard for stakeholder reporting |

---

## 📂 Repository Structure

```
uk-employment-analysis/
│
├── data/
│   ├── workplace-employment-sector-borough.xlsx   # Raw ONS source data
│   ├── workplace_employment_Cleaned.xlsx          # Excel-cleaned dataset
│   ├── employment_data.csv                        # Post-Excel export
│   ├── sql_employment_data.csv                    # Post-SQL export (for Python & Power BI)
│   └── python_employment_data.csv                 # Python-enriched dataset
│
├── sql/
│   └── employment_data.sql                        # Full SQL script (DDL + cleaning + analytics)
│
├── python/
│   └── employment_analysis.ipynb                  # Jupyter notebook with EDA & charts
│
├── powerbi/
│   └── Employment_Trends_Dashboard.pbix           # Power BI dashboard file
│
└── README.md
```

---

## 🗃️ Dataset Details

- **Source:** ONS Workplace Employment by Public/Private Sector, Borough
- **Period:** 2009–2019 (11 years)
- **Records:** 528 rows (after cleaning)
- **Granularity:** Local Authority / Region / Nation / Aggregate (Great Britain)
- **Key fields:**

| Column | Description |
|--------|-------------|
| `Year` | Survey year (2009–2019) |
| `Local_Authority_County` | Region or borough name |
| `Code` | ONS area code (e.g. E09000001) |
| `Authority_Type` | Aggregate / Nation / Region / Local Authority |
| `Public_FT/PT_employees` | Public sector full-time / part-time employees |
| `Private_FT/PT_employees` | Private sector full-time / part-time employees |
| `Total_Employment` | Overall employment figure |
| `Validation_Status` | Valid / Invalid row flag |
| `Public/Private_Sector_Percent` | Sector share of total employment |
| `yoy_growth_percent` | Year-over-year growth (%) |

---

## 🧹 Stage 1 — Excel Cleaning

**Tool:** Microsoft Excel (Power Query)

The raw ONS data was split into **separate sheets per year** (2009, 2010, … 2019). Excel was used to:

1. **Consolidate sheets** — Added a `Year` column to each sheet; used **Power Query** to merge all years into a single unified table.
2. **Remove junk rows/columns** — Deleted empty rows, blank columns, and duplicate entries.
3. **Standardise headers** — Renamed columns to consistent snake_case labels for downstream use.
4. **Convert decimal figures** — Original ONS figures were in thousands (e.g. `44.23`). Converted to actual counts using:
   ```excel
   =ROUND(CELL * 1000, 0)
   ```
5. **Data type enforcement** — Changed employment columns to `Number` type.
6. **Validation checks** — Created check columns for FT + PT = Total mismatches; applied conditional formatting to highlight errors; summarised OK vs Mismatch counts.

**Output:** [workplace_employment_Cleaned.xlsx](https://github.com/dharanipopuri888/uk-employment-trends-analysis/blob/main/workplace%20employment%20Cleaned.xlsx) → exported as [employment_data.csv](https://github.com/dharanipopuri888/uk-employment-trends-analysis/blob/main/employment_data.csv).

---

## 🛢️ Stage 2 — SQL Analysis (MySQL)

**Tool:** MySQL Workbench  
**Script:** [employment_data.sql](https://github.com/dharanipopuri888/uk-employment-trends-analysis/blob/main/employment_data.sql)

### Table Structure
```sql
CREATE TABLE employment_data (
    Year INT,
    Local_Authority_County VARCHAR(100),
    Code VARCHAR(20),
    Public_FT_employees INT,  Public_PT_employees INT,
    Public_Tot_employees INT, Public_Tot_employment INT,
    Private_FT_employees INT, Private_PT_employees INT,
    Private_Tot_employees INT, Private_Tot_employment INT,
    Total_FT_Employees INT,   Total_PT_Employees INT,
    Total_Tot_employees INT,  Total_Employment INT
);
```

### Cleaning & Validation
- Removed metadata/header rows with `NULL` year or year outside `1900–2100`
- Trimmed whitespace from text columns
- Replaced `NULL` numeric values with `0` using `COALESCE()`
- Added `Validation_Status` column — flagged rows where sector subtotals didn't sum correctly
- Checked for negative values across all employment columns
- Detected duplicate rows by `Year + Code`

### Authority Classification
Rows were classified using a `CASE` statement into four types:

| Authority_Type | Examples |
|----------------|---------|
| `Aggregate` | Great Britain |
| `Nation` | England, Scotland, Wales |
| `Region` | London, North West, South East |
| `Local Authority` | Boroughs (Code `E09%`) |

### Analytics Queries
- Year-over-year employment growth using `LAG()` window function
- Top 5 and Bottom 5 local authorities by total employment
- Year-wise Top 3 / Bottom 3 ranked regions using `ROW_NUMBER()` CTE
- Public vs Private sector percentage splits (overall, by year, by authority type)
- Descriptive statistics: `MIN`, `MAX`, `AVG`, `SUM`, `COUNT` by authority type

### Analytics View (for BI export)
```sql
CREATE OR REPLACE VIEW view_employment_full_export AS
SELECT Year, Local_Authority_County, Code, Authority_Type,
       Public_Sector_Percent, Private_Sector_Percent, ...
FROM employment_data;
```

**Output:** Exported as `sql_employment_data.csv`

---

## 🐍 Stage 3 — Python Analysis

**Tool:** Python (Pandas, Matplotlib, Seaborn)  
**Notebook:** [`python/employment_data.ipynb`](https://github.com/dharanipopuri888/uk-employment-trends-analysis/blob/main/employment_data.ipynb)

### 3.1 Setup & Data Loading
```python
import pandas as pd

df = pd.read_csv("sql_employment_data.csv")
pd.set_option('display.max_rows', 532)
pd.set_option('display.max_columns', 25)
```

### 3.2 Structure & Descriptive Statistics
```python
df.info()                           # 528 rows, 19 columns, dtypes confirmed
df.describe().drop(columns='Year')  # summary stats excluding Year
df.isnull().sum()                   # confirmed 0 nulls in any column
```

### 3.3 Cleaning
```python
# Strip whitespace from text columns
df["Local_Authority_County"] = df["Local_Authority_County"].str.strip()
df["Code"]                   = df["Code"].str.strip()
df["Authority_Type"]         = df["Authority_Type"].str.strip()

# Fill any remaining NaN with 0
df.fillna(0, inplace=True)

# Remove rows with out-of-range Year values
df = df[df["Year"].between(1900, 2100)]
```

### 3.4 Re-Validation
```python
df["Validation_Status"] = df.apply(
    lambda row: "Invalid" if (
        abs(row["Public_Tot_employees"]  - (row["Public_FT_employees"]  + row["Public_PT_employees"]))  > 0 or
        abs(row["Private_Tot_employees"] - (row["Private_FT_employees"] + row["Private_PT_employees"])) > 0 or
        abs(row["Total_Tot_employees"]   - (row["Total_FT_Employees"]   + row["Total_PT_Employees"]))   > 0 or
        abs(row["Total_Tot_employees"]   - (row["Public_Tot_employees"] + row["Private_Tot_employees"])) > 0
    ) else "Valid",
    axis=1
)
# Result → Invalid: 380  |  Valid: 148
```

### 3.5 Feature Engineering
```python
# Public and private sector share as % of total employment
df["Public_sector_share"]  = round(df["Public_Tot_employment"]  * 100 / df["Total_Employment"], 2)
df["Private_sector_share"] = round(df["Private_Tot_employment"] * 100 / df["Total_Employment"], 2)

# Full-time to part-time ratio
df["ft_to_pt_ratio"] = df["Total_FT_Employees"] / df["Total_PT_Employees"].replace(0, pd.NA)
```

### 3.6 Authority-Level Aggregation
```python
authority_summary = df.groupby("Authority_Type").agg({
    "Total_Employment":    ["sum", "mean", "min", "max"],
    "Public_sector_share": "mean",
    "Private_sector_share":"mean"
}).reset_index()
```

| Authority_Type | Total (sum) | Mean | Min | Max |
|----------------|-------------|------|-----|-----|
| Aggregate | 320,983,782 | 29,180,344 | 27,671,593 | 31,087,571 |
| Local Authority | 106,688,754 | 277,114 | 44,230 | 3,420,838 |
| Nation | 320,983,783 | 9,726,781 | 1,254,284 | 27,153,990 |
| Region | 278,880,860 | 2,816,978 | 1,031,288 | 5,368,796 |

### 3.7 Top 5 Authorities by Total Employment
```python
# Filtered to Local Authority and Region only (excludes Nation/Aggregate totals)
filtered_df = df[df["Authority_Type"].isin(["Local Authority", "Region"])]
top_5 = filtered_df.groupby("Local_Authority_County")["Total_Employment"].sum().nlargest(5)
```

| Rank | Area | Total Employment (2009–2019) |
|------|------|------------------------------|
| 1 | London | 53,349,093 |
| 2 | South East | 45,052,011 |
| 3 | North West | 35,612,590 |
| 4 | Inner London | 33,176,453 |
| 5 | East | 29,415,132 |

### 3.8 Year-over-Year Growth Analysis
```python
df_sorted = df.sort_values(["Local_Authority_County", "Year"])

# Shift employment by 1 year within each authority
df_sorted["prev_year_employment"] = df_sorted.groupby("Local_Authority_County")["Total_Employment"].shift(1)

# Calculate YoY % growth
df_sorted["yoy_growth_percent"] = round(
    (df_sorted["Total_Employment"] - df_sorted["prev_year_employment"]) * 100 /
    df_sorted["prev_year_employment"].replace(0, pd.NA), 2
)

# Fill NaN for base year (2009) rows — no prior year available
df_sorted["yoy_growth_percent"] = df_sorted["yoy_growth_percent"].fillna("N/A")
```

- **Top 10 highest-growth rows** identified — including Hounslow (2015), Kingston upon Thames (2015), Newham (2012), Tower Hamlets (2011)
- **Negative growth rows** extracted separately for decline analysis — including Barking & Dagenham (2018), Barnet (2010, 2016)

### 3.9 Export
```python
df_sorted.to_csv("python_employment_data.csv", index=False)
```

**Output:** `python_employment_data.csv` — 528 rows × 23 columns  
*New columns added:* `Public_sector_share`, `Private_sector_share`, `ft_to_pt_ratio`, `prev_year_employment`, `yoy_growth_percent`

---

---

## 📊 Stage 4 — Power BI Dashboard

**Tool:** Power BI Desktop  
**File:** [`powerbi/Employment_Trends_Dashboard.pbix`](https://github.com/dharanipopuri888/uk-employment-trends-analysis/blob/main/Employment%20Trends%20Dashboard.pbix)

The final dashboard consumes the SQL view export and the Python-enriched dataset to provide interactive reporting:

- **KPI cards** — Total employment, public/private headcount, average YoY growth
- **Time-series line chart** — Total employment trend 2009–2019 by authority type
- **Map visual** — Borough-level employment choropleth across London
- **Sector split donut/bar charts** — Public vs private employment share by year and region
- **Top N slicer** — Dynamically rank boroughs by employment volume
- **YoY growth table** — Year-over-year % change filterable by authority

---

## 🔍 Key Findings

- **Private sector dominates** — Private employment accounts for ~75–80% of total workplace employment across all regions throughout the period.
- **London leads** — Westminster, City of London, Tower Hamlets, and Southwark consistently top borough-level employment rankings.
- **Post-2012 recovery** — Following a dip around 2010–2011, total employment grew steadily through 2019 across all regions.
- **Public sector contraction** — Public sector employment share declined year-on-year from 2009, consistent with UK austerity policy during this period.
- **Outer London growth** — Several Outer London boroughs (e.g. Barking and Dagenham, Newham) showed above-average YoY growth rates.

---

## 🛠️ Tools & Technologies

![Excel](https://img.shields.io/badge/Excel-217346?style=flat&logo=microsoft-excel&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat&logo=mysql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=flat&logo=power-bi&logoColor=black)

| Tool | Libraries / Features Used |
|------|--------------------------|
| Excel | Power Query, Conditional Formatting, Formula validation |
| MySQL | DDL, DML, Window Functions (`LAG`, `ROW_NUMBER`), CTEs, Views |
| Python | `pandas`, `matplotlib`, `seaborn`, `numpy` |
| Power BI | DAX measures, Map visuals, Slicers, Drillthrough |

---

## 📋 Data Quality Notes

- 148 rows were flagged as `Invalid` during SQL validation (sector subtotals did not reconcile). These are retained in the dataset with the flag for transparency.
- Original ONS figures were in thousands and required multiplication by 1,000 before analysis.
- No negative values were found in any employment column.
- No duplicate `Year + Code` combinations exist in the cleaned dataset.

---

## 👤 Author

**Dharani Kishori Popuri**  
Data Analyst | Excel · SQL · Python · Power BI

---

## 📄 Data Source

> ONS Workplace Employment by Public/Private Sector, Borough  
> London Datastore: https://data.london.gov.uk/dataset/workplace-employment-by-publicprivate-sector-borough-29j6q/

