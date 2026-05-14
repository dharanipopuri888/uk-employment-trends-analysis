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

Built on the SQL-exported dataset (`sql_employment_data.csv`), the Python stage adds:

- **Exploratory Data Analysis (EDA)** — `.describe()`, null checks, distribution plots
- **Year-over-year growth** — Computed `yoy_growth_percent` via `.pct_change()` grouped by authority
- **Sector share trends** — Line charts showing public vs private sector share per year
- **Top/bottom authority comparisons** — Bar charts of highest/lowest employment boroughs
- **Correlation analysis** — Heatmaps of employment metrics
- **Time-series trends** — Total employment trajectory across 2009–2019 for nations and regions

**Output:** `python_employment_data.csv` (enriched with `yoy_growth_percent`, `prev_year_employment`, `Public/Private_sector_share`)

---

## 📊 Stage 4 — Power BI Dashboard

**Tool:** Power BI Desktop  
**File:** [`powerbi/Employment_Trends_Dashboard.pbix`](powerbi/Employment_Trends_Dashboard.pbix)

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

