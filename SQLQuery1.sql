select * from ProjectPortfolio.dbo.CovidDeaths$;

select * from ProjectPortfolio.dbo.CovidVaccinations$;

--Sorting the table according to the 3rd and 4th column
select * from ProjectPortfolio.dbo.CovidDeaths$
order by 3,4;

select * from ProjectPortfolio.dbo.CovidVaccinations$
order by 3,4;

--select data that we are going to be using
select Location, date, total_cases, new_cases, total_deaths, population 
from ProjectPortfolio.dbo.CovidDeaths$
order by 1,2;

--Top 100 entries of the both tables
SELECT TOP 100 * FROM ProjectPortfolio.dbo.CovidDeaths$;
select top 100 * from CovidVaccinations$;

--Continentwise populations and covid deaths and covid cases registered
select continent, sum(CAST(total_cases AS BIGINT)) as TotalCases, sum(CAST(total_deaths AS BIGINT)) as TotalDeaths ,
MAX(CAST(population AS BIGINT)) AS Population  
from ProjectPortfolio.dbo.CovidDeaths$
where continent is not null
group by continent
order by 1 asc;

--
select top 5 * from CovidDeaths$;
select top 5 * from CovidVaccinations$;

-- Missing values or weird data
select count(*) as MissingDeaths
from CovidDeaths$
where total_deaths is null or total_deaths = 0;

--Missing values or weird data
select count(*) as missingVaccinations
from CovidVaccinations$
where new_vaccinations is null or new_vaccinations = 0;

--Total cases vs deaths (Mortality rate)

select location, sum(cast(total_cases as bigint)) as TotalCases,
sum(cast(total_deaths as bigint)) as TotalDeaths,
Round(sum(cast(total_deaths as Float))/sum(cast(total_cases as float))*100, 2) as DeathPercentage
from CovidDeaths$
where continent is not null
group by location
order by DeathPercentage Desc;


-- Total cases vs population (Infection rate)

select location,  population, max(total_cases) as TotalCases,
round(max(total_cases)/population * 100, 2) as PercentPopulationInfected
from CovidDeaths$
where continent is not null
group by location, population
order by PercentPopulationInfected Desc;

--Highest death count by continent

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc;

-- Shows cumulative vaccinations over time for the United States

select location, date,
sum(cast(new_vaccinations as BigInt)) over (partition by location order by date) as CumulativeVaccinations
from CovidVaccinations$
where location = 'United States'
order by date;

--Rolling 7 days average of new cases

select location, date, 
avg(new_cases) over (partition by location order by date rows between 6 preceding and current row) as Rolling7DayAvgCases
from CovidDeaths$
where continent is not null
order by location, date;

-- Join both datasets

select d.location, d.date, d.total_cases, d.total_deaths, v.new_vaccinations
from CovidDeaths$ d join CovidVaccinations$ v
on d.location = v.location and d.date = v.date
where d.continent is not null
order by d.location, d.date;

--Countries with highest vaccination coverage

select v.location,
max(cast(v.people_fully_vaccinated as int)) as FullyVaccinated,
max(cast(v.people_fully_vaccinated as int)) * 100.0 / max(d.population) as PercentPopulationVaccinated
from CovidVaccinations$ v
join CovidDeaths$ d
on v.location = d.location and v.date = d.date
where d.continent is not null
group by v.location
order by PercentPopulationVaccinated desc;

--Monthwise cases trend top 100

select top 100 location,  
format(date, 'yyyy-mm') as month,
sum(cast(new_cases as bigint)) as TotalCasesInMonth
from CovidDeaths$
where continent is not null
group by location, Format(date, 'yyyy-mm')
order by location, month;

--Countries with highest death rate per population

select location, round(max(total_deaths) * 100 / max(population),2) as DeathRatePerPopulation
from CovidDeaths$
where continent is not null
group by location
order by DeathRatePerPopulation desc;

--Day with the highest new cases globally

select top 1 date,
sum(new_cases) as TotalNewCases
from CovidDeaths$
where continent is  not null
group by date
order by TotalNewCases desc;

--Continent with highest vaccination progress

select d.continent,
max(cast(v.people_fully_vaccinated as bigint)) as TotalVaccinated,
round(max(cast(v.people_fully_vaccinated as Float)) * 100 / max(d.population), 2) as VaccinationRate
from CovidDeaths$ d join CovidVaccinations$ v
on d.location = v.location and d.date = v.date
where d.continent is not null
group by d.continent
order by VaccinationRate desc;

--Case fatality rate over time

select location, date,
(sum(cast(total_deaths as bigint))/ nullif(sum(total_cases),0)) * 100 as CaseFatalityRate
from CovidDeaths$
where continent is not null
group by location, date
order by location, date;

--Rolling case fatality rate(CFR)

select location, date,
round(sum(cast(total_deaths as bigint))*1.0/ nullif(sum(cast(total_cases as bigint)), 0) * 100, 2) as CaseFatalityRate,
round(avg(sum(cast(total_deaths as bigint))*1.0 /nullif(sum(cast(total_cases as bigint)), 0)* 100)
over (partition by location order by date rows between 6 preceding and current row), 2) as Rolling7DayCFR
from CovidDeaths$
where continent is not null
group by location, date
order by location, date;

--Top 5 countries every month by infection rate

WITH MonthlyCases AS (
SELECT location, FORMAT(date, 'yyyy-MM') AS Month,
SUM(CAST(new_cases AS BIGINT)) AS TotalCases
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, FORMAT(date, 'yyyy-MM')
),
RankedCases AS (
SELECT Month, location, TotalCases,
RANK() OVER (PARTITION BY Month ORDER BY TotalCases DESC) AS RankByCases
FROM MonthlyCases
)
SELECT Month, location, TotalCases, RankByCases
FROM RankedCases
WHERE TotalCases > 0 AND RankByCases <= 5
ORDER BY Month, RankByCases;


--Correlation Analysis (Vaccinations vs Death Raates)

with VaccVsDeaths as (
select d.location, 
sum(cast(d.total_deaths as bigint)) as TotalDeaths,
sum(cast(v.people_fully_vaccinated as bigint)) as TotalVaccinated,
max(d.population) as Population
from CovidDeaths$ d join CovidVaccinations$ v
on d.location = v.location and d.date = v.date
where d.continent is not null
group by d.location
)
select location, TotalDeaths, TotalVaccinated,
Round((TotalVaccinated * 100) / nullif(population, 0), 2) as VaccinationRate,
Round((TotalDeaths * 100) / nullif(Population, 0), 2) as DeathRate
from VaccVsDeaths
order by VaccinationRate desc;

--find days with unusually high spikes vs 7 day average 

with CasesWithAvg as (
select location, date, new_cases,
avg(new_cases) over (partition by location order by date rows between 6 preceding and current row) as RollingAvg
from CovidDeaths$
where continent is not null
)
select location, date, new_cases, RollingAvg,
case when new_cases > RollingAvg * 2 then 'Spike' else 'Normal' end as CaseStatus
from CasesWithAvg
order by location, date;


--Create materialized views

CREATE VIEW CovidKeyMetrics as 
select d.location, d.date, d.total_cases, d.total_deaths, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (Partition by d.location order by d.date) as CumulativeVaccinations
from CovidDeaths$ d join CovidVaccinations$ v
on d.location = v.location and d.date = v.date
where d.continent is not null;

SELECT * FROM CovidKeyMetrics;

--Key Performance Indicators for Infection rate, Death rate, Vaccination rate, Monthly growth

select d.location,
max(total_cases) as TotalCases,
max(total_deaths) as TotalDeaths,
max(total_cases)*100 / max(population) as InfectionRate,
max(total_deaths)*100 / max(population) as DeathRate,
max(v.people_fully_vaccinated) *100 / max(population) as VaccinationRate
From CovidDeaths$ d
join CovidVaccinations$ v
on d.location = v.location and d.date = v.date
where d.continent is not null
group by d.location
order by InfectionRate desc;

--% change in cases day over day

select location, date, new_cases,
lag(new_cases) over (partition by location order by date) as PrevDayCases,
round(((new_cases - lag(new_cases) over (partition by location order by date)) * 100/
nullif(lag(new_cases) over (partition by location order by  date), 0)), 2) as DailyGrowthRate
from CovidDeaths$
where continent is not null
order by location, date;


--Automate reporting with stored procedure

create procedure CovidSummary @Country Nvarchar(100)
as
begin
select d.location, d.date, d.total_cases, d.total_deaths, v.new_vaccinations
from CovidDeaths$ d join CovidVaccinations$ v
on d.location = v.location and d.date = v.date
where d.location = @Country
order by date;
end;


exec CovidSummary 'India';

exec CovidSummary 'United states';