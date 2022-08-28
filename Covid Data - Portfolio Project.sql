USE Portpholio
SELECT *
FROM CovidDeaths
order by 3,4

--USE Portpholio
--SELECT *
--FROM CovidVaccination
--order by 3,4


--Select the data that we are going to be using


SELECT Location,Date,total_cases,new_cases,total_deaths,population
FROM Portpholio..CovidDeaths
ORDER BY 1,2

-- Looking for Total Cases VS Total Deaths

--This shows the likelyhood if you contracted with covid

SELECT Location,Date,total_cases,new_cases,total_deaths,(total_deaths/total_cases)*100 as Precentage
FROM Portpholio..CovidDeaths
WHERE Location  LIKE '%LANKA%' AND total_cases IS NOT NULL
ORDER BY 1,2

SELECT Location,Date, MAX((total_deaths/total_cases)*100) as DeathPrecentage
FROM Portpholio..CovidDeaths
GROUP BY Location,Date
HAVING MAX((total_deaths/total_cases)*100) > 50
ORDER BY 1,2

--Looking total cases with population

-- Precentage got inflected covid by population

SELECT Location,Date,population,total_cases,new_cases,(total_cases/population)*100 as CasePrecentage
FROM Portpholio..CovidDeaths
WHERE Location  LIKE '%LANKA%' 
ORDER BY 1,2

-- What counties has highest inflected rate compare to the Population

SELECT top 100 Location,population,MAX (total_cases) as MaxTotalCases,MAX((total_cases/population)*100) AS MaxCasePrecentage
FROM Portpholio..CovidDeaths
GROUP BY Location,population
--HAVING MAX((total_cases/population)*100) > 20 
--AND MAX((total_cases/population)*100) <40
ORDER BY MaxCasePrecentage DESC



SELECT top 100 Location,population,MAX (total_cases) as MaxTotalCases,MAX((total_cases/population)*100) AS MaxCasePrecentage
FROM Portpholio..CovidDeaths
where Location Like '%lanka%'
GROUP BY Location,population


-- Countries with highest death count per population

SELECT top 100 Location,population,MAX (total_deaths) as MaxTotalDeaths,MAX((total_deaths/population)*100) AS MaxDeathPrecentage
FROM Portpholio..CovidDeaths
GROUP BY Location,population
ORDER BY MaxDeathPrecentage DESC

-- Countries with highest death count 
SELECT Location, MAX (CAST(total_deaths AS INT)) as MaxTotalDeaths
FROM Portpholio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY MaxTotalDeaths DESC

-- Countries with highest death count per population (No deaths countries to be excluded)
SELECT Location, MAX (CAST(total_deaths AS INT)) as MaxTotalDeaths
FROM Portpholio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent, Location
HAVING MAX (CAST(total_deaths AS INT)) IS NOT NULL 
ORDER BY MaxTotalDeaths DESC



-- Continent  with highest death count (But This wrong)
SELECT continent, MAX (CAST(total_deaths AS INT)) as MaxTotalDeaths
FROM Portpholio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY MaxTotalDeaths DESC

-- Continent  with highest death count (Corrected one)

SELECT location, MAX (CAST(total_deaths AS INT)) as MaxTotalDeaths
FROM Portpholio..CovidDeaths
WHERE continent IS NULL 
GROUP BY location
ORDER BY MaxTotalDeaths DESC


-- Countries of each Continent  with highest death count ??/??/?  I Cant do it
SELECT continent, MAX (CAST(total_deaths AS INT)) as MaxTotalDeaths
FROM Portpholio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY MaxTotalDeaths DESC

-- Lets braek thing in to dates
SELECT date, SUM(new_cases) AS TotalNewCases, SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths, 
(SUM(CAST(new_deaths AS INT)))/SUM(new_cases)* 100 AS DailyDeathTOCases
FROM Portpholio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY date 


--Lets join both tables

SELECT *
FROM Portpholio..CovidDeaths DEA
JOIN Portpholio..CovidVaccination  VAC
ON DEA.location =  VAC.location
AND DEA.date =  VAC.date

-- Total population VS vaccination

SELECT DEA.continent,DEA.date, DEA.location,DEA.population, VAC.new_vaccinations
FROM Portpholio..CovidDeaths DEA
JOIN Portpholio..CovidVaccination  VAC
ON DEA.location =  VAC.location
AND DEA.date =  VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 1,2,3

-- partirion in to dates

SELECT DEA.continent, DEA.location, DEA.date,DEA.population, VAC.new_vaccinations,SUM(CAST(VAC.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date) AS Total_Vac_Day
FROM Portpholio..CovidDeaths DEA
JOIN Portpholio..CovidVaccination  VAC
ON	DEA.location =  VAC.location
	AND DEA.date =  VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3

--find Total-Vac-Day - Precentage

SELECT DEA.continent, DEA.location, DEA.date,DEA.population, VAC.new_vaccinations,SUM(CAST(VAC.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date) AS Total_Vac_Day, (SUM(CAST(VAC.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date)/DEA.population)*100
FROM Portpholio..CovidDeaths DEA
JOIN Portpholio..CovidVaccination  VAC
ON	DEA.location =  VAC.location
	AND DEA.date =  VAC.date
WHERE DEA.continent IS NOT NULL 
ORDER BY 2,3

--Use CTE in order to find Total-Vac-Day - Precentage

WITH  PopVSVaccn (continent, Location, date,population,new_vaccinations,Total_Vac_Day )
AS
(
SELECT DEA.continent, DEA.location, DEA.date,DEA.population, VAC.new_vaccinations,SUM(CAST(VAC.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date) AS Total_Vac_Day 
--(Total_Vac_Day / DEA.population)*100
FROM Portpholio..CovidDeaths DEA
JOIN Portpholio..CovidVaccination  VAC
ON	DEA.location =  VAC.location
	AND DEA.date =  VAC.date
WHERE DEA.continent IS NOT NULL 
--ORDER BY 2,3
)

SELECT *,(Total_Vac_Day/population)*100 AS VaccinPcentge
FROM PopVSVaccn


-- Time for work with TEMP TABLES

DROP TABLE IF EXISTS #Precentage_of_Vaccinatd
CREATE TABLE #Precentage_of_Vaccinatd
(
continent NVARCHAR(225),
location NVARCHAR(225),
date	DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
Total_Vac_Day NUMERIC)

INSERT INTO #Precentage_of_Vaccinatd
SELECT DEA.continent, DEA.location, DEA.date,DEA.population, VAC.new_vaccinations,SUM(CAST(VAC.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date) AS Total_Vac_Day 
--(Total_Vac_Day / DEA.population)*100
FROM Portpholio..CovidDeaths DEA
JOIN Portpholio..CovidVaccination  VAC
ON	DEA.location =  VAC.location
	AND DEA.date =  VAC.date
WHERE DEA.continent IS NOT NULL 
--ORDER BY 2,3

SELECT *,(Total_Vac_Day/population)*100 AS VaccinPcentge
FROM #Precentage_of_Vaccinatd

-- Creating VIEW data for later visualizations

Create View Precentage_of_Vaccinatd AS
SELECT DEA.continent, DEA.location, DEA.date,DEA.population, VAC.new_vaccinations,SUM(CAST(VAC.new_vaccinations AS BIGINT)) 
OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date) AS Total_Vac_Day 
--(Total_Vac_Day / DEA.population)*100
FROM Portpholio..CovidDeaths DEA
JOIN Portpholio..CovidVaccination  VAC
ON	DEA.location =  VAC.location
	AND DEA.date =  VAC.date
WHERE DEA.continent IS NOT NULL 
--ORDER BY 2,3

