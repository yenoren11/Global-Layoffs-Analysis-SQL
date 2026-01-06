# Data Cleaning in SQL - Global Layoffs Dataset

## 📌 Project Overview
This project focuses on a comprehensive Data Cleaning process for a global layoffs dataset using SQL Server. The primary goal is to transform messy, raw data into a structured, consistent, and clean format, making it ready for Exploratory Data Analysis (EDA) and visualization.

## 🛠 Tools & Technologies
- **Language:** SQL
- **Tool:** Microsoft SQL Server Management Studio (SSMS)
- **Dataset Source:** [Kaggle - Layoffs 2022 Dataset](https://www.kaggle.com/datasets/swaptr/layoffs-2022)

## 📋 Data Cleaning Steps

### Step 0: Data Preparation (Staging)
Created a staging table `layoffs_staging` from the raw data. This ensures the original dataset remains untouched and provides a safe environment for manipulation.

### Step 1: Remove Duplicate Records
Identified identical rows using the `ROW_NUMBER()` function over a `PARTITION` of all columns within a Common Table Expression (CTE).
- Isolated records where `row_num > 1`.
- Performed a permanent deletion of these duplicates to maintain data integrity.

### Step 2: Standardize the Data
- **Trimming:** Removed unnecessary whitespace from company names using the `TRIM()` function.
- **Industry Harmonization:** Standardized variations of industry names (e.g., merging 'Crypto Currency' and 'CryptoCurrency' into a single 'Crypto' category).
- **Populating Missing Values:** Used a `Self-Join` logic to fill in missing `industry` values by matching them with existing data from the same company.
- **Geographic Cleanup:** Fixed country naming inconsistencies (e.g., removing trailing periods in 'United States.').
- **Date Conversion:** Converted the `date` column from string format to a proper `DATE` data type for time-series analysis.

### Step 3: Handle NULL or Blank Values
- Replaced literal `'NULL'` strings with actual SQL system `NULL` values.
- Analyzed and cleaned numeric columns like `total_laid_off`, `percentage_laid_off`, and `funds_raised_millions` to ensure they are ready for calculation.

### Step 4: Final Cleanup & Removal
- Removed entries that were missing both `total_laid_off` and `percentage_laid_off`, as they provided no actionable insights for layoff analysis.
- Dropped the auxiliary `row_num` column used during the deduplication phase.

## 🔍 Exploratory Data Analysis (EDA)
After cleaning the data, I conducted an exploratory analysis to uncover trends, patterns, and outliers in global layoffs. Key insights explored include:

- **Top Layoffs:** Identified companies with the largest single-day layoffs and highest total layoffs over the years.
- **Geographic & Industry Trends:** Analyzed which locations (cities/countries) and industries (e.g., Retail, Consumer, Transportation) were hit hardest.
- **Funding Impact:** Explored the relationship between a company's funding stage and their layoff percentage.
- **Time-Series Analysis:**
    - **Yearly Trends:** Compared total layoffs across different years.
    - **Rolling Total:** Calculated the monthly rolling total of layoffs to visualize the progression over time.
    - **Top 3 Companies per Year:** Used `DENSE_RANK()` and `CTEs` to identify the top 3 companies with the most layoffs for each specific year.