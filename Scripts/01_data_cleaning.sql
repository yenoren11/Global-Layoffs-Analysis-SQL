--DATA CLEANING

-- STEP 0: DATA PREPARATION (STAGING)
-- Purpose: To create a copy for manipulation, keeping the original data (Raw data) safe.

SELECT *
INTO layoffs_staging
FROM layoffs
GO

-- STEP 1: REMOVE DUPLICATE DATA
-- How to do it: Use ROW_NUMBER() to mark identical rows

-- Preview data
SELECT * 
FROM layoffs_staging
GO

-- Check for duplicates using ROW_NUMBER()
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, industry, total_laid_off, percentage_laid_off, [date]
		ORDER BY (SELECT NULL)
	) AS row_num
FROM layoffs_staging
GO

-- Preliminary check for duplicate records using CTE across all relevant columns
WITH duplicate_cte AS
(
	SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY company, location, 
					industry, total_laid_off, 
					percentage_laid_off, [date],
					stage, country, funds_raised_millions
		ORDER BY (SELECT NULL)
	) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
GO

-- Remove duplicates using CTE
WITH delete_cte AS
(
	SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY company, location, 
					industry, total_laid_off, 
					percentage_laid_off, [date],
					stage, country, funds_raised_millions
		ORDER BY (SELECT NULL)
	) AS row_num
	FROM layoffs_staging
) 
DELETE
FROM delete_cte
WHERE row_num > 1
GO

-- Create a second staging table (layoffs_staging2) to better manage data with row identifiers
CREATE TABLE [dbo].[layoffs_staging2](
	[company] [nvarchar](MAX),
	[location] [nvarchar](MAX),
	[industry] [nvarchar](MAX),
	[total_laid_off] [nvarchar](MAX),
	[percentage_laid_off] [nvarchar](MAX),
	[date] [nvarchar](MAX),
	[stage] [nvarchar](MAX),
	[country] [nvarchar](MAX),
	[funds_raised_millions] [nvarchar](MAX),
	row_num INT
)
GO

-- Insert data into the new staging table with calculated row numbers
INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY company, location, 
					industry, total_laid_off, 
					percentage_laid_off, [date],
					stage, country, funds_raised_millions
	ORDER BY (SELECT NULL)
	) AS row_num
FROM layoffs_staging
GO

-- Delete final duplicates where row_num > 1
DELETE
FROM layoffs_staging2
WHERE row_num > 1
GO

SELECT * FROM layoffs_staging2
GO

-- STEP 2: STANDARDIZE THE DATA
-- Purpose: Fixing inconsistent naming, trimming whitespace, and correcting data types.

-- 2.1. Remove extra whitespace from company names
SELECT company, TRIM(company)
FROM layoffs_staging2
GO

-- 2.2. Standardize 'Industry' column
-- Find null or empty industry values
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry
GO

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''
ORDER BY industry
GO

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%'
GO

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'airbnb%'
GO

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry =''
GO

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''
ORDER BY industry
GO

-- Populate missing industry values using data from other rows with the same company name (Self-Join)
UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
GO

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''
ORDER BY industry
GO

-- Standardize variations of 'Crypto' into one single category
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry
GO

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency')
GO

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry
GO

SELECT *
FROM layoffs_staging2
GO

-- 2.3. Clean 'Country' column
-- Remove trailing periods (e.g., 'United States.')
SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY country
GO

UPDATE layoffs_staging2
SET country = LEFT(country, LEN(country) - 1)
WHERE country LIKE '%.';
GO

SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY country
GO

-- 2.4. Fix 'Date' column format
-- Convert string dates into proper SQL DATE format
SELECT *
FROM layoffs_staging2
GO

SELECT *
FROM layoffs_staging2
WHERE TRY_CONVERT(DATE, [date], 101) IS NULL 
AND [date] IS NOT NULL
GO

UPDATE layoffs_staging2
SET [date] = NULL
WHERE [date] = 'NULL'
GO

UPDATE layoffs_staging2
SET [date] = CONVERT(DATE, [date], 101)
GO

ALTER TABLE layoffs_staging2
ALTER COLUMN [date] DATE
GO

SELECT *
FROM layoffs_staging2
GO

-- STEP 3: HANDLE NULL OR BLANK VALUES
-- Purpose: Convert text 'NULL' strings to actual SQL NULL values for calculations.

SELECT *
FROM layoffs_staging2
GO

UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE ISNUMERIC(total_laid_off) = 0
GO

ALTER TABLE layoffs_staging2
ALTER COLUMN total_laid_off INT


UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE ISNUMERIC(percentage_laid_off) = 0
GO

ALTER TABLE layoffs_staging2
ALTER COLUMN percentage_laid_off FLOAT

UPDATE layoffs_staging2
SET funds_raised_millions = NULL
WHERE ISNUMERIC(funds_raised_millions) = 0
GO

ALTER TABLE layoffs_staging2
ALTER COLUMN funds_raised_millions FLOAT

SELECT *
FROM layoffs_staging2
GO

-- STEP 4: REMOVE UNNECESSARY DATA
-- Purpose: Delete rows that lack critical analysis data and drop helper columns.

-- Delete rows where both laid off columns are null (no usable data for layoff analysis)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
GO

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL

SELECT * 
FROM layoffs_staging2
GO

-- Drop the helper column row_num
ALTER TABLE layoffs_staging2
DROP COLUMN row_num
GO

-- FINAL CHECK OF CLEANED DATA
SELECT * 
FROM layoffs_staging2
GO