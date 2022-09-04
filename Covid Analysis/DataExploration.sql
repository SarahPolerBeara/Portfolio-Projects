--DROP table IF EXISTS CovidDeaths;

CREATE TABLE IF NOT EXISTS CovidDeaths (
iso_code VARCHAR(20),
continent VARCHAR (50),
"location" VARCHAR (50),
"date" TIMESTAMP, 
population BIGINT,
total_cases	INT,
new_cases INT,
new_cases_smoothed	DECIMAL,
total_deaths INT,
new_deaths INT,
new_deaths_smoothed DECIMAL,
total_cases_per_million	DECIMAL,
new_cases_per_million DECIMAL,
new_cases_smoothed_per_million DECIMAL,
total_deaths_per_million DECIMAL,
new_deaths_per_million DECIMAL,
new_deaths_smoothed_per_million	DECIMAL,
reproduction_rate DECIMAL,
icu_patients INT,
icu_patients_per_million DECIMAL,
hosp_patients INT,
hosp_patients_per_million DECIMAL,
weekly_icu_admissions DECIMAL,
weekly_icu_admissions_per_million DECIMAL,
weekly_hosp_admissions DECIMAL,
weekly_hosp_admissions_per_million DECIMAL
);


COPY CovidDeaths
FROM '/Applications/PostgreSQL 13/CovidDeaths.csv' 
DELIMITER ',' 
CSV HEADER;

--Select Data to Use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Look at total cases vs total deaths in America

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths::numeric/total_cases::numeric)*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE location ILIKE '%states%'
ORDER BY 1,2;

--Look at total cases vs population in countries at the end of the data collection period
--And find countries with highest case percentage rates

SELECT location, date, COALESCE(total_cases,0), COALESCE(population,0), COALESCE(ROUND((total_cases::numeric/population::numeric)*100,2),0) AS CasePercentage
FROM CovidDeaths
WHERE date = (SELECT MAX(date)
				FROM CovidDeaths)
AND continent IS NOT NULL
ORDER BY CasePercentage DESC;

--Find countries with highest death rates at end of period

SELECT location, date, ROUND(COALESCE((total_deaths::numeric/total_cases::numeric)*100,0),2) AS "DeathRate(%)"
FROM CovidDeaths
WHERE date = (SELECT MAX(date)
				FROM CovidDeaths)
AND continent IS NOT NULL
ORDER BY "DeathRate(%)" DESC;

--Find continents with highest death count

SELECT location, MAX(total_deaths::numeric) AS TotalDeaths
FROM CovidDeaths
WHERE continent IS NULL
AND location NOT ILIKE '%world%'
GROUP BY location
ORDER BY TotalDeaths DESC;

--Global Numbers

SELECT date, SUM(new_cases) AS DailyCases, SUM(new_deaths) AS DailyDeaths, ROUND((SUM(new_deaths::numeric)/SUM(new_cases::numeric))*100,2) AS DailyDeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;


--DROP TABLE IF EXISTS CovidVaccinations;

CREATE TABLE IF NOT EXISTS CovidVaccinations(
iso_code VARCHAR (20),
continent VARCHAR (50),	
"location" VARCHAR (50),	
"date" TIMESTAMP,	
new_tests DECIMAL,
total_tests INT,
total_tests_per_thousand DECIMAL,
new_tests_per_thousand DECIMAL,
new_tests_smoothed DECIMAL,
new_tests_smoothed_per_thousand DECIMAL,
positive_rate DECIMAL,
tests_per_case DECIMAL,
tests_units VARCHAR (50),
total_vaccinations DECIMAL,
people_vaccinated DECIMAL,
people_fully_vaccinated INT,
new_vaccinations INT,
new_vaccinations_smoothed DECIMAL,
total_vaccinations_per_hundred DECIMAL, 
people_vaccinated_per_hundred DECIMAL,
people_fully_vaccinated_per_hundred DECIMAL,
new_vaccinations_smoothed_per_million DECIMAL,
stringency_index DECIMAL,
population_density DECIMAL,
median_age DECIMAL,
aged_65_older DECIMAL,
aged_70_older DECIMAL,
gdp_per_capita DECIMAL,
extreme_poverty DECIMAL,
cardiovasc_death_rate DECIMAL,
diabetes_prevalence DECIMAL,
female_smokers DECIMAL,
male_smokers DECIMAL,
handwashing_facilities DECIMAL,
hospital_beds_per_thousand DECIMAL,
life_expectancy DECIMAL,
human_development_index DECIMAL);

COPY CovidVaccinations
FROM '/Applications/PostgreSQL 13/CovidVaccinations.csv' 
DELIMITER ',' 
CSV HEADER;

--looking at total population versus vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, va.new_vaccinations,
SUM(va.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Total_Vax
FROM CovidDeaths dea
JOIN CovidVaccinations va
ON dea.location=va.location
AND dea.Date=va.Date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--CTE 
WITH PopsVac (continent, date, location, population, new_vacciantions, Rolling_Total_Vax)
AS (SELECT dea.continent, dea.location, dea.date, dea.population, va.new_vaccinations,
SUM(va.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Total_Vax
FROM CovidDeaths dea
JOIN CovidVaccinations va
ON dea.location=va.location
AND dea.Date=va.Date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
   )

SELECT *, ROUND((Rolling_Total_Vax::numeric/population)*100,2) AS Rolling_percent_Vax
FROM PopsVac;

--Same manipulation/querying but using a Temp Table

DROP TABLE IF EXISTS PercentPopVaxxed2;

CREATE TEMP TABLE PercentPopVaxxed2 AS
SELECT dea.continent, dea.location, dea.date, dea.population, va.new_vaccinations,
SUM(va.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Total_Vax
FROM CovidDeaths dea
JOIN CovidVaccinations va
ON dea.location=va.location
AND dea.Date=va.Date
WHERE dea.continent IS NOT NULL;
--ORDER BY 2,3
	
   
   
SELECT *, ROUND((Rolling_Total_Vax::numeric/population)*100,2) AS Rolling_percent_Vax
FROM PercentPopVaxxed2;


--Creating view to store data for later visualizations

DROP VIEW IF EXISTS PercentPopVaxxed;

CREATE VIEW PercentPopVaxxed AS
SELECT dea.continent, dea.location, dea.date, dea.population, va.new_vaccinations,
SUM(va.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Total_Vax
FROM CovidDeaths dea
JOIN CovidVaccinations va
ON dea.location=va.location
AND dea.Date=va.Date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;
;
 