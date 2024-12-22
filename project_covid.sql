SELECT *
FROM "CovidDeaths"
WHERE
	continent IS NOT NULL
ORDER BY 3,4 


-- SELECT *
-- FROM "CovidVaccination"
-- ORDER BY 3,4 ;



-- Select Data that we are going to be using 

SELECT 
	Location, date, total_cases, new_cases, total_deaths, population
FROM
	"CovidDeaths"
ORDER BY
	1, 2


-- Looking at Total Cases vs Total Deaths
--  Shows likelihoodgood of dying by location 

SELECT 
	Location, date, total_cases, total_deaths , (total_deaths/total_cases)*100 AS DeathRate
FROM 
	"CovidDeaths"
WHERE
	location like '%States%'
ORDER BY
	1, 2




-- Shows what percentage of population got covid

SELECT 
	Location, date,  population, total_cases,(total_cases/population)*100 AS case_rate
FROM 
	"CovidDeaths"
WHERE
	location like '%States%'
ORDER BY
	1, 2



-- Looking at Counturies with Highest Infection Rate comprated to Population
-- Null 값 제외하기 위해 WHERE 절 추가 

SELECT 
	Location, population, MAX(total_cases) as Highest_infection_count, MAX(total_cases/population)*100 AS percent_population_infected 
FROM 
	"CovidDeaths"
WHERE
	total_cases IS NOT NULL
	AND population IS NOT NULL 
GROUP BY
	Location, Population
ORDER BY
	 percent_population_infected DESC


-- Showing Contries with Highest Death Count Per Poplation
SELECT 
	Location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM
	"CovidDeaths"
WHERE 
	 continent IS NOT NULL
	 AND total_deaths IS NOT NULL
GROUP BY
	Location
HAVING
	 MAX(total_deaths) IS NOT NULL
ORDER BY
	 Total_Death_Count DESC 



--  LET'S BREAK THING DOWN BY CONTINENT 

-- Showing continents with the highest death count per population

SELECT 
	location, 
	continent, 
	MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM
	"CovidDeaths"
WHERE 
	continent IS NOT NULL
GROUP BY						-- SELECT 절에서 사용중인 컬럼을 포함시켜야 함
	location, continent
HAVING
	MAX(cast(total_deaths as int)) IS NOT NULL
ORDER BY
	 Total_Death_Count DESC 



-- GLOBAL NUMBERS
SELECT 
	date, 
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths, 
	(SUM(new_deaths)/SUM(new_cases))*100 as Death_rate
FROM
	"CovidDeaths"
WHERE
	continent IS NOT NULL
GROUP BY
	date
ORDER BY
	1, 2


--  Looking at Total Population vs Vaccinations

SELECT 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	dea.new_vaccinations,
	SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location) 
	AS RollingPeopleVaccinated,
FROM
	"CovidDeaths" dea
JOIN
	"CovidVaccination" vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
ORDER BY
	2, 3


-- USE CTE

WITH Pop_vs_Vac (Continent, location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS 
(SELECT 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated
FROM
	"CovidDeaths" dea
JOIN
	"CovidVaccination" vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
)
SELECT * 
FROM 
	Pop_vs_Vac 



WITH Pop_vs_Vac (Continent, location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS 
(SELECT 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated
FROM
	"CovidDeaths" dea
JOIN
	"CovidVaccination" vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
)
SELECT *, 
	(RollingPeopleVaccinated/Population) * 100
FROM 
	Pop_vs_Vac


-- TEMP TABLE
-- Drop the temporary table if it exists
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create a new temporary table
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    Continent varchar(255),
    Location varchar(255),
    Date timestamp,  -- Use timestamp instead of datetime
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date::timestamp,
    dea.population::numeric,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
    AS RollingPeopleVaccinated
FROM
    "CovidDeaths" dea
JOIN
    "CovidVaccination" vac
    ON dea.location = vac.location 
    AND dea.date::timestamp = vac.date::timestamp 
WHERE
    dea.continent IS NOT NULL;

-- Select the data from the temporary table
SELECT *
FROM PercentPopulationVaccinated;
