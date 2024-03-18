USE Portfolio; 

-- Formatting date from string to Date
SELECT STR_TO_DATE(date, '%d/%m/%Y') as formattedate
FROM covid ;

UPDATE Covid 
SET date = STR_TO_DATE(date, '%d/%m/%Y');



-- Infection Rates Worldwide 

SELECT 
	continent, 
	location, 
	MAX(total_cases) TotalCases,
	MAX((total_cases/population)*100) AS InfectionRates
FROM 
	covid c 
WHERE 
	continent <> ''
GROUP BY 	
	continent, location;
 


-- Contienetal Average HDI Vs infection rates 


SELECT location, MAX(total_cases) AS cases, population, MAX((total_cases/population)*100) AS Infectionrates, human_development_index AS HDI
FROM covid c 
WHERE continent = '' AND location  IN
(SELECT continent FROM covid where continent  <> '')
GROUP BY location, population, HDI;

# no info on contienental HDI, hence need to calculate it from available data
-- found some inconsistnces from the above data, calculated the average Continental infection rates and HDI 

WITH tab (continent, location, total_cases, population,HDI, country_cases, country_pop) AS (
    SELECT 
        continent,
        location, 
        total_cases, 
        population,
   		human_development_index as HDI,
        MAX(total_cases) OVER (PARTITION BY location) AS country_cases,  
        MAX(population) OVER (PARTITION BY location) AS country_pop
    FROM 
        covid c 
    WHERE 
        continent <> ''
    GROUP BY 
        continent, 
        location, 
        total_cases, 
        population,
        human_development_index 
)

SELECT 
    continent,
    (SUM(country_cases) / SUM(country_pop)) * 100 AS infection_rates, ROUND(AVG(HDI),3) as HDI
FROM 
    tab
GROUP BY 
    continent;



-- HDI on death and infection rates -- Total test per thousand -- found some descrepancies in the original data, calculated from scratch 
-- removed territories and countires not recongniesed by united nations by joining into another table with tthe relevant information. 
SELECT 
	c.location, MAX(human_development_index) AS HDI, 
	MAX((total_cases/population)*100) AS Infectionrates, 
	MAX(total_cases) AS InfecttionCount,
	MAX(total_tests/ population)* 1000 AS TestPer1000
FROM 
	covid c 
JOIN 
	all_countries ac 
ON 
	c.location = ac.location 
GROUP BY 
	c.location
ORDER BY 
	HDI DESC;


-- Top 5 countries with HDI,infection rates and testing availibilty 
WITH TMS (location,HDI) AS(
	SELECT 
		location,
		human_development_index AS HDI
	FROM 
		covid c 
	GROUP BY 
		location, human_development_index 
	ORDER BY 
		human_development_index DESC
	LIMIT 5
)

SELECT DISTINCT 
	c.date,
	TMS.*,
	MAX((c.total_cases/c.population)*100) AS Infectionrates, 
	MAX(c.total_tests/ c.population)* 1000 AS TestPer1000
FROM 
	covid c 
JOIN 
	TMS
ON 
	c.location = TMS.location
GROUP BY 
	c.`date`, TMS.location, TMS.HDI;



-- Country infection rates vs poverty rates

SELECT 	
	c.location, 
	c.extreme_poverty, 
	MAX((total_cases/population)*100) AS Infectionrates
FROM 
	covid c 
JOIN 
	all_countries ac 
ON 
	c.location = ac.location 
GROUP BY 
	c.location, 
	c.extreme_poverty
ORDER BY 
	3 DESC;


-- Creating views, stores data for later use(e.g. visualisations)

CREATE View InfVsPov as
SELECT 	
	c.location, 
	c.extreme_poverty, 
	MAX((total_cases/population)*100) AS Infectionrates
FROM 
	covid c 
JOIN 
	all_countries ac 
ON 
	c.location = ac.location 
GROUP BY 
	c.location, 
	c.extreme_poverty
ORDER BY 
	3 DESC;

