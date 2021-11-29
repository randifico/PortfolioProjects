--SELECT  location, date, total_cases, new_cases, total_deaths, population 
FROM Public."CovidDeaths"
ORDER BY 1,2

--Looking at total cases vs total deaths
SELECT  location, date, total_cases, total_deaths
FROM Public."CovidDeaths"
ORDER BY 1,2

--Trend of weekly hospital cases per million
SELECT date, total_cases, new_cases, weekly_hosp_admissions_per_million
FROM Public."CovidDeaths"
WHERE location ILIKE '%States' AND weekly_hosp_admissions_per_million IS NOT NULL6
ORDER BY date DESC

--Likelihood of dying in your country
SELECT  location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage
FROM Public."CovidDeaths"
WHERE location ILIKE '%states%'
ORDER BY 1,2 DESC

--SELECT  location, date, total_cases, new_cases, total_deaths, population 
FROM Public."CovidDeaths"
ORDER BY 1,2

--Looking at total cases vs total deaths
SELECT  location, date, total_cases, total_deaths
FROM Public."CovidDeaths"
ORDER BY 1,2

--Trend of weekly hospital cases per million
SELECT date, total_cases, new_cases, weekly_hosp_admissions_per_million
FROM Public."CovidDeaths"
WHERE location ILIKE '%States' AND weekly_hosp_admissions_per_million IS NOT NULL
ORDER BY date DESC

--Likelihood of dying if you contract COVID in the US
SELECT  location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage
FROM Public."CovidDeaths"
WHERE location ILIKE '%states%'
ORDER BY 1,2 DESC

--Looking at the total cases vs the population

--Shows what percentage of the population got covid
SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,6) AS popPercent
FROM Public."CovidDeaths"
WHERE location ILIKE '%states'
ORDER BY 1,2 DESC

-- Looking at countries with highest deaths
SELECT location, 
	MAX(cast(total_deaths AS INT)) AS highestDeathCount 
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY highestDeathCount DESC

-- QUERIES REGARDING CONTINENTS

--Showing the continents with the highest deathcount
SELECT continent, 
	MAX(cast(total_deaths AS INT)) AS deathCount 
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY deathCount DESC

--Global infection, death rate, and likelihood of death from COVID diagnosis
SELECT SUM(new_cases) AS sumNewCases, 
	SUM(new_deaths) AS sumNewDeaths, 
	SUM(new_deaths)::FLOAT/NULLIF(SUM(new_cases), 0)::FLOAT *100 AS percentDeaths 
FROM Public."CovidDeaths"
ORDER BY 1 DESC

--GlOBAL NUMBERS

--Total population of countries vs vaccinations
SELECT dea.continent, 
	dea.location, 
	MAX(dea.date) AS new_date, 
	dea.population, 
	vac.new_vaccinations
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3 DESC

--Total population of countries vs running total of daily vaccinations
SELECT dea.continent, 
	dea.location, 
	MAX(dea.date) AS new_date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3 DESC

--USING CTE, rolling percentage of total population vaccinated by country
With popVsVac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
AS
(
SELECT dea.continent, 
	dea.location, 
	MAX(dea.date) AS new_date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3 DESC
)
SELECT *, (rollingPeopleVaccinated/population)*100
FROM popVsVac

--Total population of USA vs running total of daily vaccinations
SELECT dea.continent, 
	dea.location, 
	MAX(dea.date) AS new_date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location ILIKE '%states%'
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3 DESC

-- Looking at daily percent death rates globally
SELECT 
	date, 
	SUM(new_cases) AS sumNewCases, 
	SUM(new_deaths) AS sumNewDeaths, 
	SUM(new_deaths)::FLOAT/NULLIF(SUM(new_cases), 0)::FLOAT *100 AS percentDeaths 
FROM Public."CovidDeaths"
  --WHERE location ILIKE '%states%'
GROUP BY date
ORDER BY 1 DESC

--SELECT * FROM Public."CovidDeaths" LIMIT 1

--Number of deaths by continent
SELECT continent, MAX(total_deaths) AS totalDeathCount
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 1

--Looking at death percentage by continent
SELECT continent, SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths,
	SUM(new_deaths)/SUM(total_deaths)*100 AS deathPercentage
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY continent

--Looking at the countries with highest deaths rates compared to population
SELECT location, population, 
	MAX(total_deaths) AS highestDeathCount, 
	MAX(total_deaths/population)*100 AS percentPopulationDead
FROM Public."CovidDeaths"
GROUP BY location, Population
ORDER BY percentPopulationDead DESC

--Vaccination info
SELECT * 
FROM Public."CovidVaccinations"
ORDER BY 3, 4

-- Creating view to store data for later visualizations

Create View percentPopulationVaccinated AS 
SELECT dea.continent, 
	dea.location, 
	MAX(dea.date) AS new_date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
ORDER BY 2,3 DESC


SELECT continent, MAX(total_deaths) AS totalDeathCount
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 1








--Vaccination info
/*
SELECT * 
FROM Public."CovidVaccinations"
ORDER BY 3, 4
*/






