# Select data for exploration

SELECT country, date, population, total_cases, new_cases, total_deaths
FROM Project_Covid.covid_death
ORDER BY country, date desc;

# Total Cases VS Total Deaths
# Indicate likelyhood of dying if contacted Covid in Singapore

SELECT country, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS death_percent
FROM Project_Covid.covid_death
WHERE country = 'Singapore'
HAVING death_percent IS NOT NULL
ORDER BY date;

# Total Cases VS Population
# Indicate percentage of Singapore population infected with Covid

SELECT country, date, population, total_cases, (total_cases/population)*100 AS population_infected_percent
FROM Project_Covid.covid_death
WHERE country = 'Singapore'
ORDER BY date;

# Country with highest infection rate compare to population between Indonesia, Malaysia and Singapore

SELECT country, population, MAX(total_cases) AS highest_infected_count, MAX((total_cases/population))*100 AS population_infected_percent
FROM Project_Covid.covid_death
GROUP BY country, population
ORDER BY population_infected_percent DESC;

# Country with highest death rate compare to population between Indonesia, Malaysia and Singapore

SELECT country, population, MAX(total_deaths) AS highest_death_count, MAX((total_deaths/population))*100 AS population_death_percent
FROM Project_Covid.covid_death
GROUP BY country, population
ORDER BY population_death_percent DESC;

# Total infection rate compare to population for Indonesia, Malaysia and Singapore by date

SELECT date, IMS_population, IMS_infected_count, (IMS_infected_count/IMS_population)*100 AS IMS_infected_percent
FROM 
	(SELECT date, SUM(DISTINCT(population)) AS IMS_population, SUM(total_cases) AS IMS_infected_count
	FROM Project_Covid.covid_death
    GROUP BY date
    ) AS IMS_pop_inf
ORDER BY date DESC;

# Total death rate compare to population for Indonesia, Malaysia and Singapore by date

SELECT date, IMS_population, IMS_death_count, (IMS_death_count/IMS_population)*100 AS IMS_death_percent
FROM 
	(SELECT date, SUM(DISTINCT(population)) AS IMS_population, SUM(total_deaths) AS IMS_death_count
	FROM Project_Covid.covid_death
    GROUP BY date
    ) AS IMS_pop_dea
ORDER BY date DESC;

# Total Population VS Vaccination
# Indicate percent of population that has received at least one Covid vaccination by date

SELECT dea.country, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.country ORDER BY dea.date) AS rolling_vaccination
FROM Project_Covid.covid_death AS dea
JOIN Project_Covid.covid_vaccination AS vac
	ON dea.iso_code = vac.iso_code AND dea.date = vac.date;
    
# CTE to perform calculation on PARTITION BY from "Total Population VS Vaccination" query

WITH cte_PopvsVac (country, date, population, new_vaccinations, rolling_vaccination) AS
(SELECT dea.country, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.country ORDER BY dea.date) AS rolling_vaccination
FROM Project_Covid.covid_death AS dea
JOIN Project_Covid.covid_vaccination AS vac
	ON dea.iso_code = vac.iso_code AND dea.date = vac.date
)
SELECT country, date, (rolling_vaccination/population)*100 AS rolling_vaccination_percent
FROM cte_PopvsVac
ORDER BY country, date DESC;

# Temp table to perform calculation on PARTITION BY from "Total Population VS Vaccination" query

DROP TEMPORARY TABLE IF EXISTS temp_PopvsVac;

USE Project_Covid;

CREATE TEMPORARY TABLE temp_PopvsVac(
country VARCHAR(45),
date DATE,
population INT,
new_vaccinations INT,
rolling_vaccination DECIMAL);

INSERT INTO temp_PopvsVac
SELECT dea.country, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.country ORDER BY dea.date) AS rolling_vaccination
FROM Project_Covid.covid_death AS dea
JOIN Project_Covid.covid_vaccination AS vac
	ON dea.iso_code = vac.iso_code AND dea.date = vac.date;
    
SELECT country, date, (rolling_vaccination/population)*100 AS rolling_vaccination_percent
FROM Project_Covid.temp_PopvsVac
ORDER BY country, date DESC;

# View for data visualisations

CREATE VIEW view_PopvsVac AS
SELECT dea.country, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER(PARTITION BY dea.country ORDER BY dea.date) AS rolling_vaccination
FROM Project_Covid.covid_death AS dea
JOIN Project_Covid.covid_vaccination AS vac
	ON dea.iso_code = vac.iso_code AND dea.date = vac.date;

SELECT country, date, (rolling_vaccination/population)*100 AS rolling_vaccination_percent
FROM Project_Covid.view_PopvsVac
ORDER BY country, date DESC;