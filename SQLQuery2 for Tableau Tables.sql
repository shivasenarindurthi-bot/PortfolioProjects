/*
Queries used for Tableau Project
*/

/* 1. Global Death Percentage */

SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject1.dbo.CovidDeaths$
WHERE continent IS NOT NULL 
ORDER BY 1, 2;


/* 2. Locations without continent data (e.g., cruise ships, world totals) */

SELECT 
    location, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject1.dbo.CovidDeaths$
WHERE continent IS NULL 
  AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;


/* 3. Infection rate by country */

SELECT 
    location, 
    population, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject1.dbo.CovidDeaths$
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


/* 4. Infection rate by country and date */

SELECT 
    location, 
    population, 
    date, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject1.dbo.CovidDeaths$
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC;


/* 5. Daily totals by location */

SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    total_deaths
FROM PortfolioProject1.dbo.CovidDeaths$
WHERE continent IS NOT NULL 
ORDER BY 1, 2;


/* 6. Vaccination progress per location */

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        d.continent, 
        d.location, 
        d.date, 
        d.population, 
        v.new_vaccinations,
        SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
    FROM PortfolioProject1.dbo.CovidDeaths$ d
    JOIN PortfolioProject1.dbo.CovidVaccinations$ v
        ON d.location = v.location
        AND d.date = v.date
    WHERE d.continent IS NOT NULL
)
SELECT 
    *, 
    (RollingPeopleVaccinated / population) * 100 AS PercentPeopleVaccinated
FROM PopvsVac;


/* 7. Highest infection rate by date */

SELECT 
    location, 
    population, 
    date, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject1.dbo.CovidDeaths$
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC;


/* 8. Rolling people vaccinated (extra KPI reference) */

SELECT 
    d.continent, 
    d.location, 
    d.date, 
    d.population,
    MAX(v.total_vaccinations) AS RollingPeopleVaccinated
FROM PortfolioProject1.dbo.CovidDeaths$ d
JOIN PortfolioProject1.dbo.CovidVaccinations$ v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL 
GROUP BY d.continent, d.location, d.date, d.population
ORDER BY 1, 2, 3;
