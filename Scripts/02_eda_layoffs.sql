--EXPLORATORY DATA ANALYSIS (EDA)
--Purpose: Extracting insights on layoff trends, top companies and monthly accumulation.

-- Initial preview of the cleaned data
SELECT *
FROM layoffs_staging2
GO

-- Checking the maximum number of people laid off in a single event
SELECT MAX(total_laid_off)
FROM layoffs_staging2
GO

-- Looking at Percentage to see how big these layoffs were relative to the company size
SELECT MAX(percentage_laid_off) AS max_percentage,
	   MIN(percentage_laid_off) AS min_percentage
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GO

-- Finding companies that laid off 100% of their staff (percentage_laid_off = 1)
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
GO

-- Examining 100% layoff companies by funding (funds_raised_millions)
-- Insight: Many well-funded startups still failed completely.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC
GO

-- TOP 5 COMPANIES WITH THE LARGEST SINGLE LAYOFF EVENT
SELECT TOP(5) company, total_laid_off
FROM layoffs_staging2 
ORDER BY total_laid_off DESC
GO

-- TOP 10 COMPANIES WITH THE MOST TOTAL LAYOFFS (Aggregated)
SELECT TOP(10) company, SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off_sum DESC
GO

-- TOTAL LAYOFFS BY LOCATION
SELECT TOP(10) location, SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
GROUP BY location
ORDER BY total_laid_off_sum DESC
GO

-- TOTAL LAYOFFS BY COUNTRY
-- Insight: Identifying the regions most affected by the economic downturn.
SELECT TOP(10) country, SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off_sum DESC
GO

-- TOTAL LAYOFFS BY YEAR
SELECT YEAR(date) AS yearS, SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY YEAR(date) DESC
GO

-- TOTAL LAYOFFS BY INDUSTRY
SELECT TOP(10) industry, SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off_sum DESC
GO

-- TOTAL LAYOFFS BY COMPANY STAGE (Series A, B, Post-IPO, etc.)
SELECT TOP(10) stage, SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off_sum DESC
GO

-- ADVANCED ANALYSIS: TOP 3 COMPANIES PER YEAR
-- Using CTEs and DENSE_RANK to identify the leading companies in layoffs annually.
WITH Company_Year AS
(
	SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off_sum
	FROM layoffs_staging2
	GROUP BY company, YEAR(date)
),
Company_Year_Rank AS 
(
	SELECT company, years, total_laid_off_sum,
			DENSE_RANK() OVER (
							PARTITION BY years 
							ORDER BY total_laid_off_sum DESC) AS ranking
	FROM Company_Year
)
SELECT company, years, total_laid_off_sum, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off_sum DESC
GO

-- ROLLING TOTAL ANALYSIS
-- Tracking the accumulation of layoffs month-over-month.

-- Previewing layoffs by Month (YYYY-MM)
SELECT FORMAT([date], 'yyyy-MM') AS [month], 
       SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
WHERE [date] IS NOT NULL
GROUP BY FORMAT([date], 'yyyy-MM')
ORDER BY 1;
GO

-- CALCULATING ROLLING TOTAL OF LAYOFFS PER MONTH
-- Casting FORMAT result to VARCHAR(10) to avoid memory size limits
WITH date_cte AS
(
	SELECT CAST(FORMAT([date], 'yyyy-MM') AS VARCHAR(10)) AS [month], 
		   SUM(total_laid_off) AS total_laid_off_sum
	FROM layoffs_staging2
	WHERE [date] IS NOT NULL
	GROUP BY FORMAT([date], 'yyyy-MM')
)
SELECT [month], SUM(total_laid_off_sum) OVER (ORDER BY [month] ASC) AS rolling_total_layoffs
FROM date_cte
ORDER BY [month] ASC