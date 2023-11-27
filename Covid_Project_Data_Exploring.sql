--select * from CovidProject.dbo.covidDeath
--order by location, date

--select * from CovidProject.dbo.covidVaccinations
--order by location, date


----Total cases vs total deaths
----Shows the likelihood of dying if you infected by covid 

--select location, date, total_cases, total_deaths, convert(float, total_deaths)/convert(float, total_cases)*100 as DeathPercentage
--from CovidProject.dbo.covidDeath
--where location like '%kingdom%'
--order by location, date

----Total cases vs population
----Show percentage of population infected by Covid

--select location, date, total_cases, population, convert(float, total_cases)/convert(float, population)*100 as InfectedPercentage
--from CovidProject.dbo.covidDeath
--where location like '%kingdom%'
--order by location, date

----Create a new table to show countries with the highest infection rate compared to their population

--drop table if exists CovidProject.dbo.highestInfectionRateByCountries
--select location, population, max(cast(total_cases as int)) as HighestInfectedCount, max(convert(float, total_cases)/convert(float, population)*100) as HighestInfectedPercentage
--into CovidProject.dbo.highestInfectionRateByCountries
--from CovidProject.dbo.covidDeath
--where continent is not null
--group by location, population
--order by HighestInfectedPercentage desc

----show the table created above

--select * from CovidProject.dbo.highestInfectionRateByCountries
--order by HighestInfectedPercentage desc

----Create a new table to show countries with the highest death count and death rate compared to their population

--drop table if exists CovidProject.dbo.highestDeathByCountries
--select location, population, max(cast(total_deaths as int)) as HighestDeathCount, max(convert(float, total_deaths)/convert(float, population)*100) as HighestDeathPercentage
--into CovidProject.dbo.highestDeathByCountries
--from CovidProject.dbo.covidDeath
--where continent is not null
--group by location, population
--order by HighestDeathCount desc

----Show table created above

--select * from CovidProject.dbo.highestDeathByCountries
--order by HighestDeathCount desc

----Global cases and deaths by date

--select date, sum(new_cases) as totalCasesOfTheDay, sum(cast(new_deaths as int)) as totalDeathOfTheDay, 
--case 
--when sum(cast(new_deaths as int)) = 0 then null
--when sum(new_cases) = 0 then null
--else sum(cast(new_deaths as int))/sum(new_cases)*100 
--end as deathPercentageOfTheDay
--from CovidProject.dbo.covidDeath
--where continent is not null
--group by date
--order by date



----Create stored procedure for Vaccinations by Countries

drop procedure if exists vaccinationsByCountries
go
create procedure vaccinationsByCountries @locationName varchar(50) as
begin

----Create temp table to store the results

	drop table if exists #filteredVaccinationsByCountries 
	create table #filteredVaccinationsByCountries 
	(
	continent nvarchar(255),
	location nvarchar(255),
	date date,
	Population int,
	newVaccinations int,
	rollingTotalVaccinations int,
	vaccinationsPercentage float
	);

----Use CTE to process calculation, altering data and join tables

	with DE_VAC as
	(
	Select de.continent, de.location, de.date, de.population, 
		isnull(vac.new_vaccinations,0) as newVaccinations,
		sum(cast(isnull(vac.new_vaccinations,0) as float)) over(partition by de.location order by de.location, de.date) as rollingTotalVaccinations 
	from CovidProject.dbo.covidDeath as DE
		inner join CovidProject.dbo.covidVaccinations as VAC
		on de.location=vac.location 
		and de.date=vac.date
	)

----insert data into temp table

	insert into #filteredVaccinationsByCountries 
	Select continent, location, date, population, newVaccinations, rollingTotalVaccinations,
		(rollingTotalVaccinations/population)*100 as vaccinationsPercentage
	from DE_VAC
	where continent is not null and location like '%'+ @locationName+'%'

----Display the results from the temp table

select * from #filteredVaccinationsByCountries 

end
go
----Execute stored procedure
----In the parameter field, enter the name of the location to show results for specific countries or leave it as '' to show all locations

exec vaccinationsByCountries @locationName = 'bani'





