/****** 
Portfolio
Data from https://ourworldindata.org/covid-deaths
******/

--Select Data that we will use 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


--Convert total cases and total deaths to Int
--ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_cases int 
--ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_deaths int 

--Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, ISNULL(total_deaths, 0) total_deaths, CAST(ISNULL(total_deaths, 0) AS FLOAT)/total_cases*100 DeathPercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL AND location = 'Russia' AND total_cases IS NOT NULL
ORDER BY 1, 2

--Shows what percentage of population got Covid
SELECT location, date, total_cases, population, total_cases/population*100 PercentPopulationInfected
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL /*AND location = 'Russia'*/ AND total_cases IS NOT NULL
ORDER BY 1, 2


--Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 HighestPercentPopulationInfected
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


--Showing Contries with Highest Death Count per Population
SELECT location, population, MAX(total_deaths) as TotalDeathsCount, MAX(total_deaths/population)*100 PercentPopulationDeaths
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


------------LET'S BREAK THINGS DOWN BY CONTINENTS
SELECT location, MAX(population) Population, MAX(total_deaths) as TotalDeathsCount, MAX(total_deaths/population)*100 PercentPopulationDeaths
FROM dbo.CovidDeaths
WHERE continent IS NULL AND total_cases IS NOT NULL
	AND location NOT LIKE '%income%'
	AND location NOT IN ('World', 'European Union')
GROUP BY location
ORDER BY 4 DESC


--Showing continetns with the highest death count per population
SELECT continent, SUM(population) Population, SUM(TotalDeathsCount) TotalDeathsCount
FROM (
	SELECT location, continent, MAX(population) population, MAX(ISNULL(total_deaths, 0)) as TotalDeathsCount
	FROM dbo.CovidDeaths
	WHERE continent IS NOT NULL AND total_cases IS NOT NULL
	GROUP BY location, continent
	) countries
GROUP BY continent
ORDER BY 1


------- WOLRD NUMBERS ----------
SELECT /*date,*/ SUM(ISNULL(new_cases, 0)) TotalCases, SUM(ISNULL(new_deaths, 0)) TotalDeaths
	, ISNULL(SUM(ISNULL(new_deaths, 0))/NULLIF(SUM(new_cases), 0), 0)*100 DeathPercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL --AND total_cases IS NOT NULL
--GROUP BY date
ORDER BY 1


---------- VACCINATIONS --------

-- Looking at Total Population vs Vaccinations

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
	, ISNULL(SUM(CAST(vacs.new_vaccinations as bigint)) OVER(PARTITION BY deaths.location 
				ORDER BY deaths.location, deaths.date ROWS UNBOUNDED PRECEDING), 0) RunningTotalVaccinations
FROM dbo.CovidDeaths deaths
JOIN dbo.CovidVaccinations vacs 
	ON deaths.location = vacs.location
		AND deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL
	AND deaths.date BETWEEN '2021-01-01' AND '2022-12-31'
	AND deaths.continent = 'Europe'
ORDER BY 1, 2, 3


-- USE CTE

WITH PopVacs AS 
(
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
		, ISNULL(SUM(CAST(vacs.new_vaccinations as bigint)) OVER(PARTITION BY deaths.location 
					ORDER BY deaths.location, deaths.date ROWS UNBOUNDED PRECEDING), 0) RunningTotalVaccinations
	FROM dbo.CovidDeaths deaths
	JOIN dbo.CovidVaccinations vacs 
		ON deaths.location = vacs.location
			AND deaths.date = vacs.date
	WHERE deaths.continent IS NOT NULL
		AND deaths.date BETWEEN '2021-01-01' AND '2022-12-31'
		AND deaths.continent = 'Europe'
)

SELECT *, RunningTotalVaccinations/population*100 PercentPopulationVaccinated
FROM PopVacs
ORDER BY 2, 3


--USE Temp table 

IF OBJECT_ID('tempdb..#PopsVacs') IS NOT NULL DROP TABLE #PopsVacs
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
	, ISNULL(SUM(CAST(vacs.new_vaccinations as bigint)) OVER(PARTITION BY deaths.location 
				ORDER BY deaths.location, deaths.date ROWS UNBOUNDED PRECEDING), 0) RunningTotalVaccinations
INTO #PopsVacs
FROM dbo.CovidDeaths deaths
JOIN dbo.CovidVaccinations vacs 
	ON deaths.location = vacs.location
		AND deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL
	--AND deaths.date BETWEEN '2021-01-01' AND '2022-12-31'
	AND deaths.continent = 'Europe'

SELECT continent, location, population, SUM(ISNULL(CONVERT(int, new_vaccinations), 0)) TotalVacs
	, MAX(RunningTotalVaccinations/population*100) MaxPercentPopulationVaccinated
FROM #PopsVacs
GROUP BY continent, location, population
ORDER BY 2


-- Creating VIEW for visualization

CREATE VIEW dbo.PopulationVaccinated AS 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations
	, ISNULL(SUM(CAST(vacs.new_vaccinations as bigint)) OVER(PARTITION BY deaths.location 
				ORDER BY deaths.location, deaths.date ROWS UNBOUNDED PRECEDING), 0) RunningTotalVaccinations
FROM dbo.CovidDeaths deaths
JOIN dbo.CovidVaccinations vacs 
	ON deaths.location = vacs.location
		AND deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL

