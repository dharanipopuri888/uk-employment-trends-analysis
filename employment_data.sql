/*  Metadata
------------------------------------------------------------
PROJECT: Workplace Employment Data Analysis (2009–2019)
TOOL: MySQL Workbench
AUTHOR: Dharani Kishori Popuri 
DATE CREATED: 2025
DATA SOURCE: London Datastore (ONS Workplace Employment)

DESCRIPTION:
This SQL script performs:
  • Data structure creation
  • Data cleaning & standardization
  • NULL and missing value handling
  • Data validation (consistency checks)
  • Duplicate detection & removal
  • Authority classification (Nation, Region, Local Authority)
  • Descriptive statistical analysis
  • Sector-wise and year-wise analysis
  • Creation of analytics-ready views for Python & Power BI

TABLE DETAILS:
  - Table Name: employment_data
  - Rows: Employment statistics by Local Authority (2009–2019)
  - Columns:
        Year, Local_Authority_County, Code,
        Public_FT_employees, Public_PT_employees, Public_Tot_employees, Public_Tot_employment,
        Private_FT_employees, Private_PT_employees, Private_Tot_employees, Private_Tot_employment,
        Total_FT_Employees, Total_PT_Employees, Total_Tot_employees, Total_Employment,
		Authority_Type, Validation_Status

NOTES:
  • Data was pre-cleaned in Excel for initial formatting issues.
  • SQL performs deeper validation and transformation.
  • Final clean dataset is exported into a VIEW for BI tools.
------------------------------------------------------------
*/


CREATE TABLE employment_data (
    Year INT,
    Local_Authority_County VARCHAR(100),
    Code VARCHAR(20),
    Public_FT_employees INT,
    Public_PT_employees INT,
    Public_Tot_employees INT,
    Public_Tot_employment INT,
    Private_FT_employees INT,
    Private_PT_employees INT,
    Private_Tot_employees INT,
    Private_Tot_employment INT,
    Total_FT_Employees INT,
    Total_PT_Employees INT,
    Total_Tot_employees INT,
    Total_Employment INT
);

-- Validating Post-Import Integrity
SELECT * FROM employment_data;

-- Disabling safe mode
SET SQL_SAFE_UPDATES = 0;

-- filtering metadata rows like column descriptions and empty columns
DELETE FROM employment_data
WHERE Year IS NULL OR Year NOT BETWEEN 1900 AND 2100;

-- Remove Empty or Irrelevant Rows
DELETE FROM employment_data
WHERE Local_Authority_County IS NULL
  AND Code IS NULL
  AND Year IS NULL;
  
-- Trim Whitespace from Text Columns
UPDATE employment_data
SET Local_Authority_County = TRIM(Local_Authority_County),
    Code = TRIM(Code);
    
-- Handle Missing Numeric Values
UPDATE employment_data
SET  Public_FT_employees = COALESCE(Public_FT_employees, 0),
    Public_PT_employees = COALESCE(Public_PT_employees, 0),
    Public_Tot_employees = COALESCE(Public_Tot_employees, 0),
    Public_Tot_employment = COALESCE(Public_Tot_employment, 0),
    Private_FT_employees = COALESCE(Private_FT_employees, 0),
    Private_PT_employees = COALESCE(Private_PT_employees, 0),
    Private_Tot_employees = COALESCE(Private_Tot_employees, 0),
    Private_Tot_employment = COALESCE(Private_Tot_employment, 0),
    Total_FT_Employees = COALESCE(Total_FT_Employees, 0),
    Total_PT_Employees = COALESCE(Total_PT_Employees, 0) ,
    Total_Tot_employees = COALESCE(Total_Tot_employees, 0),
    Total_Employment = COALESCE(Total_Employment, 0);
  
-- validating rows (380 rows effected)
SELECT *
FROM employment_data
WHERE Total_FT_Employees != Public_FT_employees + Private_FT_employees
   OR Total_PT_Employees != Public_PT_employees + Private_PT_employees
   OR Total_Tot_employees != Total_FT_Employees + Total_PT_Employees
   OR Total_Tot_employees != Public_Tot_employees + Private_Tot_employees ;
   
-- ading validation status 
ALTER TABLE employment_data ADD Validation_Status VARCHAR(20);

-- Updating validating status (148 rows effected)
UPDATE employment_data
SET Validation_Status = 
  CASE
    WHEN ABS(Public_Tot_employees - (Public_FT_employees + Public_PT_employees)) > 0
      OR ABS(Private_Tot_employees - (Private_FT_employees + Private_PT_employees)) > 0
      OR ABS(Total_Tot_employees - (Total_FT_Employees + Total_PT_Employees)) > 0
      OR ABS(Total_Tot_employees - (Public_Tot_employees + Private_Tot_employees)) > 0
    THEN 'Invalid'
    ELSE 'Valid'
  END;
   
   
-- checking for negative values
SELECT *
FROM employment_data
WHERE Public_FT_employees < 0
    OR Public_PT_employees < 0
    OR Public_Tot_employees < 0
    OR Public_Tot_employment < 0
    OR Private_FT_employees < 0
    OR Private_PT_employees < 0
    OR Private_Tot_employees < 0
    OR Private_Tot_employment < 0
    OR Total_FT_Employees < 0
    OR Total_PT_Employees < 0
    OR Total_Tot_employees < 0
    OR Total_Employment < 0 ;
    
-- Detect Duplicate Rows by Year + Code
SELECT Year, Code, COUNT(*) AS count
FROM employment_data
GROUP BY Year, Code
HAVING COUNT(*) > 1;

-- adding authority type to the table
ALTER TABLE employment_data
ADD Authority_Type VARCHAR(50);

-- categorizing the local authoruty
UPDATE employment_data
SET Authority_Type = 
  CASE
    WHEN Local_Authority_County IN ('Great Britain') THEN 'Aggregate'
    WHEN Local_Authority_County IN ('England', 'Scotland', 'Wales') THEN 'Nation'
    WHEN Local_Authority_County IN ('London', 'South East', 'North West', 'East Midlands', 'West Midlands', 'East', 'South West', 'North East', 'Yorkshire and The Humber') THEN 'Region'
    WHEN Local_Authority_County LIKE '%London%' OR Code LIKE 'E09%' THEN 'Local Authority'
    ELSE 'Unclassified'
  END;

-- Aggregate total employment by Authority Type and Year
SELECT Authority_Type, Year,
  SUM(Public_Tot_employees) AS Total_Public_Employees,
  SUM(Private_Tot_employees) AS Total_Private_Employees,
  SUM(Total_Tot_employees) AS Total_Employees,
  SUM(Total_Employment) AS Total_Employment
FROM employment_data
GROUP BY Authority_Type, Year
ORDER BY Year, Authority_Type;

-- Sum by Authority Type (gives totals by category e.g., "Region", "Nation", "Local Authority")
SELECT Authority_Type,
       SUM(Total_Employment) AS Total_Employment
FROM employment_data
GROUP BY Authority_Type
ORDER BY Total_Employment DESC;

-- Year-over-Year Employment Growth
SELECT Authority_Type, Year,
       SUM(Total_Employment) AS Total_Employment,
       LAG(SUM(Total_Employment)) OVER (PARTITION BY Authority_Type ORDER BY Year) AS Prev_Year_Employment,
       ROUND((SUM(Total_Employment) - LAG(SUM(Total_Employment)) OVER (PARTITION BY Authority_Type ORDER BY Year)) * 100.0 / NULLIF(LAG(SUM(Total_Employment)) OVER (PARTITION BY Authority_Type ORDER BY Year), 0), 2) AS YoY_Growth_Percent
FROM employment_data
GROUP BY Authority_Type, Year
ORDER BY Authority_Type, Year;

-- Top 5 regions
Select Year, Local_Authority_County, SUM(Total_Employment) AS Total_Employment
FROM employment_data
WHERE Authority_Type = 'Local Authority'
GROUP BY Local_Authority_County, Year
ORDER BY Total_Employment DESC
LIMIT 5;

-- Least 5 employment Local authorities
Select Year, Local_Authority_County, SUM(Total_Employment) AS Total_Employment
FROM employment_data
WHERE Authority_Type = 'Local Authority'
GROUP BY Local_Authority_County, Year
ORDER BY Total_Employment ASC
LIMIT 5;

-- year wise top 3 regions
WITH region_totals AS (
 SELECT Year, Local_Authority_County, SUM(Total_Employment) AS Total_Employment
FROM employment_data
WHERE Authority_Type = 'Local Authority'
GROUP BY Year, Local_Authority_County
),
ranked_regions AS (
  SELECT Year, Local_Authority_County, Total_Employment,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Total_Employment DESC) AS rank_in_year
  FROM region_totals
)
SELECT Year, Local_Authority_County, Total_Employment
FROM ranked_regions
WHERE rank_in_year <= 3
ORDER BY Year, rank_in_year;

-- year wise Bottom 3 regions
WITH region_totals AS (
 SELECT Year, Local_Authority_County, SUM(Total_Employment) AS Total_Employment
FROM employment_data
WHERE Authority_Type = 'Local Authority'
GROUP BY Year, Local_Authority_County
),
ranked_regions AS (
  SELECT Year, Local_Authority_County, Total_Employment,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Total_Employment ASC) AS rank_in_year
  FROM region_totals
)
SELECT Year, Local_Authority_County, Total_Employment
FROM ranked_regions
WHERE rank_in_year <= 3
ORDER BY Year, rank_in_year;
 
-- overal public and private employment percentage
SELECT ROUND(SUM(Public_Tot_employment) * 100.0 / SUM(Total_Employment), 2) AS Public_Sector_Percent, 
	ROUND(SUM(Private_Tot_employment) * 100.0 / SUM(Total_Employment), 2) AS Private_Sector_Percent 
FROM employment_data;

-- year-wise percentage of public and private employment
SELECT Year, 
	ROUND(SUM(Public_Tot_employment) * 100.0 / SUM(Total_Employment), 2) AS Public_Sector_Percent,
	ROUND(SUM(Private_Tot_employment) * 100.0 / SUM(Total_Employment), 2) AS Private_Sector_Percent 
    FROM employment_data
    GROUP BY Year 
    ORDER BY Year;

-- authority wise percentage of public and private employment
SELECT Authority_Type, 
	ROUND(SUM(Public_Tot_employment) * 100.0 / SUM(Total_Employment), 2) AS Public_Sector_Percent, 
    ROUND(SUM(Private_Tot_employment) * 100.0 / SUM(Total_Employment), 2) AS Private_Sector_Percent 
    FROM employment_data 
    GROUP BY Authority_Type 
    ORDER BY Public_Sector_Percent DESC;

-- exploratory statistical analysis 
SELECT COUNT(*) AS row_count, 
MIN(Total_Employment) AS min_employment, 
MAX(Total_Employment) AS max_employment, 
AVG(Total_Employment) AS avg_employment, 
SUM(Total_Employment) AS total_employment_sum 
FROM employment_data;

SELECT Year, 
	COUNT(*) AS records, 
    SUM(Total_Employment) AS total_emp, 
    AVG(Total_Employment) AS avg_emp 
    FROM employment_data 
    GROUP BY Year 
    ORDER BY Year;
    
-- stats as per authority type 
SELECT Authority_Type, COUNT(*) AS records, 
SUM(Total_Employment) AS total_employment, 
ROUND(AVG(Total_Employment), 2) AS avg_employment, 
MIN(Total_Employment) AS min_employment, 
MAX(Total_Employment) AS max_employment 
FROM employment_data 
GROUP BY Authority_Type 
ORDER BY total_employment DESC;

CREATE OR REPLACE VIEW view_employment_full_export AS 
SELECT Year, Local_Authority_County, Code, Authority_Type, 
-- Public sector metrics 
Public_FT_employees, 
Public_PT_employees, 
Public_Tot_employees, 
Public_Tot_employment,
-- Private sector metrics
Private_FT_employees,
Private_PT_employees,
Private_Tot_employees,
Private_Tot_employment,

-- Combined totals
Total_FT_Employees,
Total_PT_Employees,
Total_Tot_employees,
Total_Employment,

Validation_Status,

-- Public & Private sector percentages
CASE 
    WHEN Total_Employment > 0 THEN 
         ROUND(Public_Tot_employees * 100.0 / Total_Employment, 2)
    ELSE NULL
END AS Public_Sector_Percent,

CASE 
    WHEN Total_Employment > 0 THEN 
         ROUND(Private_Tot_employees * 100.0 / Total_Employment, 2)
    ELSE NULL
END AS Private_Sector_Percent
FROM employment_data;



