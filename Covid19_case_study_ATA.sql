select * 
from PortfolioProject .. CovidDeaths
where continent is not null
order by 3,4

--select * 
--from PortfolioProject .. CovidVaccination
--order by 3,4

-- Select data that we are going to be using

Select location,date,total_cases,new_cases,total_deaths,population
from PortfolioProject..CovidDeaths
where continent is not null and population is not null
order by 1,2

-- Looking at total cases vs. total deaths
-- Shows likelihood of dying if you contract covid in your country

Select location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercent
from PortfolioProject..CovidDeaths
where location = 'India'
order by 1,2

-- Looking at total cases vs population
-- Shows what percentage of population got covid

Select location,date,population,total_cases, (total_cases/population)*100 as CasesPercent
from PortfolioProject..CovidDeaths
where continent is not null and population is not null
--where location = 'India'
order by 1,2

-- Countries with highest infection rate

Select Location,population,MAX(total_cases) as HighestInfectedCountry, Max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location = 'India'
Group by Location,population
order by PercentPopulationInfected desc

-- Countries with the highest death count

Select Location,max(cast(total_deaths as int)) as TotalDeathCount 
from PortfolioProject..CovidDeaths
--where location = 'India'
where continent is not null
Group by Location
order by TotalDeathCount desc

-- Lets break things by continent

Select continent,max(cast(total_deaths as int)) as TotalDeathCount 
from PortfolioProject..CovidDeaths
--where location = 'India'
where continent is not null
Group by continent
order by TotalDeathCount desc
-- but we are not getting the accurate ones, so:

Select Location,max(cast(total_deaths as int)) as TotalDeathCount 
from PortfolioProject..CovidDeaths
--where location = 'India'
where continent is null
Group by Location
order by TotalDeathCount desc

-- Showing continents with highest death count per population
Select Location,max(cast(total_deaths as int)) as TotalDeathCount 
from PortfolioProject..CovidDeaths
--where location = 'India'
where continent is not null
Group by Location
order by TotalDeathCount desc

-- Global numbers

Select sum(new_cases) as total_cases, sum(cast (new_deaths as int)) as total_deaths,
sum(cast (new_deaths as int))/ sum(new_cases) * 100 
as DeathPercentage 
from PortfolioProject..CovidDeaths
--where location = 'India'
where continent is not null
--Group by date
order by 1,2

select * from
PortfolioProject..CovidVaccinations

alter table PortfolioProject..CovidVaccinations
drop column F26

-- Lets join them

-- Looking at total population vs vaccination

select * 
from PortfolioProject..CovidDeaths dea
join PortfolioProject .. CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
--sum(cast(vac.new_vaccinations as int)) over(partition by dea.location)
-- in place of cast you can also use:
sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated 
-- ,(RollingPeopleVaccinated/dea.population)* 100  we get error here as :  Invalid column name 'RollingPeopleVaccinated'
-- so now we are creating temp
from PortfolioProject..CovidDeaths dea
join PortfolioProject .. CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.population is not null and dea.continent is not null
order by 1,2,3

-- use cte (Common Table Expression)

with PopvsVac (Continent, Location, Date, Population,New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject .. CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.population is not null and dea.continent is not null
--order by 1,2,3
)
select * ,(RollingPeopleVaccinated/Population) * 100 as PercentPeopleVaccinatedperPopulation
from PopvsVac 
order by 1,2,3

-- Temp table

Create table #PercentPeopleVaccinated
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime, 
Population numeric, 
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)
insert into #PercentPeopleVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject .. CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.population is not null and dea.continent is not null
--order by 1,2,3

select * ,(RollingPeopleVaccinated/Population) * 100 as PercentPeopleVaccinatedperPopulation
from #PercentPeopleVaccinated
order by 1,2,3

-- if you make any alterations in the above code then just use this below query

/*drop table if exists #PercentPeopleVaccinated
Create table #PercentPeopleVaccinated
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime, 
Population numeric, 
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)
insert into #PercentPeopleVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject .. CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
-- where dea.population is not null and dea.continent is not null
--order by 1,2,3

select * ,(RollingPeopleVaccinated/Population) * 100 as PercentPeopleVaccinatedperPopulation
from #PercentPeopleVaccinated
order by 1,2,3 */


-- creating views to use for later visualizations

Create View PercentPeopleVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject .. CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.population is not null and dea.continent is not null
--order by 1,2,3

select * from PercentPeopleVaccinated



