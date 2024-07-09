SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4;

--SELECT *
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4;

-- Select the Data that we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases vs. Total Deaths

SELECT location, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percent_deaths
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases vs. Total Deaths (Filtering by a particular location)
--SHows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percent_deaths
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT AND location LIKE '%Lanka'
ORDER BY 1,2;

--Looking at Total Cases vs Population (Shows what percentage of population has got COVID)

SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_cases
FROM PortfolioProject.dbo.coviddeaths
WHERE location LIKE '%Lanka'
ORDER BY 1,2;

-- Looking at the Countries that have the highest infection rates compared to the population
-- United states is within the top 10 for highest infection rates based on population. 
SELECT location, population, MAX (total_cases) AS max_infection_count, MAX((total_cases/population))*100 AS percent_cases
FROM PortfolioProject.dbo.coviddeaths
GROUP BY location, population
ORDER BY 4 DESC;

-- Countries with the highest deaths (You have to change the data type in the total_death column, or else the max values are incorrect)

SELECT location, MAX(CAST(total_deaths AS int)) AS Max_deaths
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT 

-- Continents with the highest death counts per population (This selects out the individual country that had the highest death count in that continent) 
-- For example, in North America, United States had the highest death count. Hence, the query picks up only that particular entry.

SELECT continent, MAX(CAST(total_deaths AS int)) AS Max_deaths
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

--If you want to get the highest value of death for each continent, you can do it the following ways

-- OPTION 1
SELECT location, MAX(CAST(total_deaths AS int)) AS Max_deaths
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC;

-- OPTION 2
WITH t1 AS
(SELECT continent, location, MAX(CAST(total_deaths AS int)) AS max_death
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent, location)

SELECT t1.continent, SUM(t1.max_death) total_deaths_in_continent
FROM t1
GROUP BY t1.continent;

--Global Numbers

--Global total cases and deaths (daily values)
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS deathpercentage
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Global total cases and deaths (Overall) - [Option 1 not using subqueries - See below for Option 2 with subqueries]

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS deathpercentage
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Global total cases and deaths [Option 2 using subqueries]
WITH t1 AS
(SELECT location, MAX(CAST(total_deaths AS int)) AS max_deaths, MAX(CAST(total_cases AS int)) AS max_total_cases
FROM PortfolioProject.dbo.coviddeaths
WHERE continent IS NOT NULL
GROUP By location)
SELECT SUM(t1.max_deaths) AS global_death_count, SUM(t1.max_total_cases) AS global_case_count, CAST((SUM(t1.max_deaths)*1.0/SUM(t1.max_total_cases))*100 AS decimal (20,2)) AS death_percent_global
FROM t1;

-- Joining Covid Deaths and Covid vaccinations tables

SELECT *
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date;

--Looking at total population vs vaccination (new_vaccinations column represents new vaccinations per day)

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

-- Calculating the running total by month for each location

SELECT  d.continent, 
		d.location, 
		d.date, 
		d.population, 
		v.new_vaccinations, 
		SUM(Cast(v.new_vaccinations AS bigint)) OVER
		(PARTITION BY d.location, year(d.date), month(d.date) ORDER BY d.date) AS running_total_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

-- Calculating the running total for each location by year

SELECT  d.continent, 
		d.location, 
		d.date, 
		d.population, 
		v.new_vaccinations, 
		SUM(Cast(v.new_vaccinations AS bigint)) OVER
		(PARTITION BY d.location, year(d.date) ORDER BY d.date) AS running_total_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

-- Calculating the percentage of population vaccinated for each location by year [Option 1]

WITH T1 AS
(SELECT d.continent, 
		d.location, 
		d.date,
		d.population, 
		v.new_vaccinations, 
		SUM(Cast(v.new_vaccinations AS bigint)) OVER
		(PARTITION BY d.location,CAST(YEAR(d.date) AS VARCHAR(4)) + '-01-01' ORDER BY d.date) AS running_total_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL)

SELECT t1.continent,
	   t1.location,
	   t1.date,
	   t1.population,
	   t1.new_vaccinations,
	   t1.running_total_vaccinations,
	   (t1.running_total_vaccinations/t1.population)*100 AS percentage_vaccinated
FROM t1;

-- Alternate Method of Calculating the above [Option 2]

WITH t1 (continent, location, date, population, new_vaccinations, running_total_vaccinations) AS
(SELECT  d.continent, 
		d.location, 
		d.date, 
		d.population, 
		v.new_vaccinations, 
		SUM(Cast(v.new_vaccinations AS bigint)) OVER
		(PARTITION BY d.location ORDER BY d.location, d.date) AS running_total_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL)

SELECT *,(t1.running_total_vaccinations/t1.population)*100 AS percentage_vaccinated
FROM t1


-- By the end of April 2021, percentage of population vaccinated, by location

WITH t1 AS
(SELECT d.continent, 
		d.location, 
		d.date,
		d.population, 
		v.new_vaccinations, 
		SUM(Cast(v.new_vaccinations AS bigint)) OVER
		(PARTITION BY d.location,CAST(YEAR(d.date) AS VARCHAR(4)) + '-01-01' ORDER BY d.date) AS running_total_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL),

t2 AS

(SELECT t1.continent,
	   t1.location,
	   t1.population,
	   MAX(t1.running_total_vaccinations) AS total_vaccinated
FROM t1
GROUP BY t1.continent, t1.location, t1.population)

SELECT t2.continent,
       t2.location,
	   t2.population,
	   t2.total_vaccinated,
	   (t2.total_vaccinated/t2.population)*100 AS percentage_vaccinated
FROM t2
ORDER BY 5 DESC;

-- TEMP TABLE
-- [Incase you want to change any conditions/filters after creating the table, you have to drop the existing table and rerun the CREATE TABLE]
-- DROP TABLE IF EXISTS percent_population_vaccinated

DROP TABLE IF EXISTS percent_population_vaccinated
CREATE TABLE percent_population_vaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
running_total_vaccinations numeric
)

INSERT INTO percent_population_vaccinated
SELECT  d.continent, 
		d.location, 
		d.date, 
		d.population, 
		v.new_vaccinations, 
		SUM(Cast(v.new_vaccinations AS bigint)) OVER
		(PARTITION BY d.location ORDER BY d.location, d.date) AS running_total_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3

SELECT *,(running_total_vaccinations/population)*100 AS percentage_vaccinated
FROM percent_population_vaccinated;

-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW percent_population_vaccinated3 AS
SELECT  d.continent, 
		d.location, 
		d.date, 
		d.population, 
		v.new_vaccinations, 
		SUM(Cast(v.new_vaccinations AS bigint)) OVER
		(PARTITION BY d.location ORDER BY d.location, d.date) AS running_total_vaccinations
FROM PortfolioProject.dbo.coviddeaths d
JOIN PortfolioProject.dbo.covidvaccinations v
     ON d.location=v.location
	 AND d.date=v.date
WHERE d.continent IS NOT NULL;

SELECT * 
FROM percent_population_vaccinated3


