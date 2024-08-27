# Portfolio Project - CTA Ridership
Analyzing the effects of weather on ridership for various modes of public transit


## Introduction

1. How is ridership for different modes of public transit affected by different weather conditions?
   - Precipitation, temperature, humidity, solar radiation
3. Do people utilize different modes depending on those weather conditions?
4. Are there seasonal trends for different modes? (Does bus usage increase in the summer? Etc.)

## Preparation & Data Cleaning


### Data and Tools

The following datasets were used in this analysis:

[CTA - Ridership - Daily Boarding Totals](https://data.cityofchicago.org/Transportation/CTA-Ridership-Daily-Boarding-Totals/6iiy-9s97/about_data)
and
[Beach Weather Stations - Automated Sensors](https://data.cityofchicago.org/Parks-Recreation/Beach-Weather-Stations-Automated-Sensors/k7hf-8y75/about_data)

 
The following tools were used on this analysis:
- SQL: The language of the code written
- MySQL Workbench: The environment I interacted with and queried the database from
- MySQL Server: The database where the dataset was stored
- Tableau Public: The BI tool used to create the final visualizations and dashboard


### Process

My first step to cleaning the data was to ensure that I did not make any changes to the original data.  To do this, I created two new tables, and named them to both avoid confusion, as well as to be easier to reference.

<details>
  <summary><sub>Expand for the code used to create new "working tables"</sub></summary>

```SQL
# Original Data
SELECT * 
FROM `beach_weather_stations_-_automated_sensors_20240813`
;

SELECT *
FROM `cta_-_ridership_-_daily_boarding_totals_20240813`
;

# Creating working files to leave original data intact

CREATE TABLE weather_station_data AS (
	SELECT * 
	FROM `beach_weather_stations_-_automated_sensors_20240813`
)
;

CREATE TABLE cta_daily_boarding AS (
	SELECT *
	FROM `cta_-_ridership_-_daily_boarding_totals_20240813`
)
;
```
</details>
 

After creating the "working tables", I started with the table documenting CTA ridership. I identified any fields with the wrong data types, and updated them to appropriate types:

<details>
	
   <summary><sub>Expand for the code used to correct data types</sub></summary>
   
  
```SQL
# CTA daily boarding table - Updating data types
SELECT *
FROM cta_daily_boarding
;

SELECT service_date, STR_TO_DATE(service_date, '%m/%d/%Y')
FROM cta_daily_boarding
;

UPDATE cta_daily_boarding
SET service_date = STR_TO_DATE(service_date, '%m/%d/%Y')
;

ALTER TABLE cta_daily_boarding
MODIFY COLUMN service_date DATE
;

```
</details>

Then, it was time to identify any NULL, blank, negative, or duplicate values

<details>
	<summary><sub>Expand to see this SQL code</summary>

```SQL
SELECT *
FROM cta_daily_boarding
WHERE bus IS NULL
	OR bus = ''
    OR bus < 0
;

SELECT *
FROM cta_daily_boarding
WHERE rail_boardings IS NULL
	OR rail_boardings = ''
    OR rail_boardings < 0
;

SELECT *
FROM cta_daily_boarding
WHERE total_rides IS NULL
	OR total_rides = ''
    OR total_rides < 0
;

SELECT *
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY service_date ORDER BY service_date) AS row_cnt
	FROM cta_daily_boarding
    ) as row_nums
WHERE row_cnt > 1
;
```
</details>

After identifying some duplicate rows, I created a new "working table" and removed those rows:

<details>
	<summary><sub>Expand</sub></summary>


```SQL
 -- Creating a new working table with row_numbers, for removing duplicates
CREATE TABLE cta_daily_boarding_v2 AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY service_date ORDER BY service_date) AS row_cnt
FROM cta_daily_boarding
)
;

DELETE FROM cta_daily_boarding_v2
WHERE row_cnt > 1
;
```

</details>


Next, I moved on to the weather data table, and the first step was to rename the columns to a more usable format

<details>
	
  <summary><sub>Expand to see the code used to update column names</sub></summary>


```SQL
# Updating column names
SELECT *
FROM weather_station_data
;

ALTER TABLE weather_station_data
RENAME COLUMN `Station Name` TO station_name;

ALTER TABLE weather_station_data
RENAME COLUMN `Measurement Timestamp` TO measurement_timestamp;

ALTER TABLE weather_station_data
RENAME COLUMN `Air Temperature` TO air_temperature;

ALTER TABLE weather_station_data
RENAME COLUMN `Wet Bulb Temperature` TO wet_bulb_temperature;

ALTER TABLE weather_station_data
RENAME COLUMN `Humidity` TO humidity;

ALTER TABLE weather_station_data
RENAME COLUMN `Rain Intensity` TO rain_intensity;

ALTER TABLE weather_station_data
RENAME COLUMN `Interval Rain` TO interval_rain;

ALTER TABLE weather_station_data
RENAME COLUMN `Total Rain` TO total_rain;

ALTER TABLE weather_station_data
RENAME COLUMN `Precipitation Type` TO precipitation_type;

ALTER TABLE weather_station_data
RENAME COLUMN `Wind Direction` TO wind_direction;

ALTER TABLE weather_station_data
RENAME COLUMN `Wind Speed` TO wind_speed;

ALTER TABLE weather_station_data
RENAME COLUMN `Maximum Wind Speed` TO max_wind_speed;

ALTER TABLE weather_station_data
RENAME COLUMN `Barometric Pressure` TO barometric_pressure;

ALTER TABLE weather_station_data
RENAME COLUMN `Solar Radiation` TO solar_radiation;

ALTER TABLE weather_station_data
RENAME COLUMN `Heading` TO heading;

ALTER TABLE weather_station_data
RENAME COLUMN `Battery Life` TO battery_life;

ALTER TABLE weather_station_data
RENAME COLUMN `Measurement Timestamp Label` TO measurement_timestamp_label;

ALTER TABLE weather_station_data
RENAME COLUMN `Measurement ID` TO measurement_id;
```

</details>

I then proceeded to identify any NULLs or blanks, and replaced the blanks with NULLs as I went:

<details>
	<summary><sub>Expand</sub></summary>

 ```SQL
# Identifying NULLs, blanks, etc.

SELECT *
FROM weather_station_data WHERE wet_bulb_temperature IS NULL
;

UPDATE weather_station_data
SET wet_bulb_temperature = NULL
WHERE wet_bulb_temperature = ''
;

SELECT *
FROM weather_station_data WHERE humidity =''
;

SELECT *
FROM weather_station_data WHERE rain_intensity =''
;

UPDATE weather_station_data
SET rain_intensity = NULL
WHERE rain_intensity = ''
;

SELECT *
FROM weather_station_data WHERE interval_rain IS NULL
;

SELECT *
FROM weather_station_data WHERE total_rain = ''
;

UPDATE weather_station_data
SET total_rain = NULL
WHERE total_rain = ''
;

SELECT *
FROM weather_station_data WHERE precipitation_type = ''
;

UPDATE weather_station_data
SET precipitation_type = NULL
WHERE precipitation_type = ''
;

SELECT *
FROM weather_station_data WHERE wind_direction IS NULL
;

SELECT *
FROM weather_station_data WHERE wind_speed = ''
;

SELECT *
FROM weather_station_data WHERE heading = ''
;

UPDATE weather_station_data
SET heading = NULL
WHERE heading = ''
;
```
 
</details>

My next step was to normalize the data. I did this by updating dates to the correct format, converting Celcius to Fahrenheit, and updating column data types:

<details>
	<summary><sub>Expand</sub></summary>

```SQL
# Normalizing data

SELECT * , STR_TO_DATE(measurement_timestamp, '%m/%d/%Y %r')
FROM weather_station_data
ORDER BY station_name, measurement_timestamp
;

UPDATE weather_station_data
SET measurement_timestamp = STR_TO_DATE(measurement_timestamp, '%m/%d/%Y %r')
;

SELECT *, DATE(measurement_timestamp) AS measurement_date
FROM weather_station_data
ORDER BY station_name, measurement_timestamp
;

-- Converting from C to F
SELECT 
	air_temperature,
    ROUND((air_temperature * 9/5) + 32, 1) AS air_temp_f
FROM weather_station_data
;

SELECT 
	wet_bulb_temperature,
    ROUND((wet_bulb_temperature * 9/5) + 32, 1) AS bulb_temp_f
FROM weather_station_data
;

UPDATE weather_station_data
SET air_temperature = ROUND((air_temperature * 9/5) + 32, 1)
;

UPDATE weather_station_data
SET wet_bulb_temperature = ROUND((wet_bulb_temperature * 9/5) + 32, 1)
;


# Updating data types

ALTER TABLE weather_station_data
MODIFY COLUMN measurement_timestamp DATETIME
;

ALTER TABLE weather_station_data
MODIFY COLUMN wet_bulb_temperature DOUBLE
;

ALTER TABLE weather_station_data
MODIFY COLUMN wet_bulb_temperature DOUBLE
;

SELECT DISTINCT rain_intensity
FROM weather_station_data
;

ALTER TABLE weather_station_data
MODIFY COLUMN rain_intensity DOUBLE
;

SELECT DISTINCT total_rain
FROM weather_station_data
;

ALTER TABLE weather_station_data
MODIFY COLUMN total_rain DOUBLE
;

SELECT DISTINCT heading
FROM weather_station_data
;

SELECT *
FROM weather_station_data
WHERE heading =''
;

ALTER TABLE weather_station_data
MODIFY COLUMN heading INT
;

```
</details>

Part of that process was to convert the different precipitation codes into their descriptions, as well as remove incorrect values:

<details>
	<summary><sub>Expand</sub></summary>

```SQL
/*
Precipitation Type
0 = No precipitation 
60 = Liquid precipitation, e.g. rain - Ice, hail and sleet are transmitted as rain (60). 
70 = Solid precipitation, e.g. snow 
40 = unspecified precipitation
*/

SELECT DISTINCT precipitation_type
FROM weather_station_data
; -- Results contained '5', which is not listed in the dataset description

SELECT * 
FROM weather_station_data
WHERE precipitation_type = '5'
;

SELECT *
FROM weather_station_data
WHERE station_name = 'Oak Street Weather Station'
	AND measurement_timestamp LIKE '2017-10-03%'
; 			/*This looks like bad data, I could match it to the '0' values in the same timeframe, 
			but some other values are also showing '5', when they likely shouldn't. I'll remove this row 
			from the data, so the other invalid values don't affect the analysis, either */
                            
DELETE FROM weather_station_data
WHERE precipitation_type = '5'
;

UPDATE weather_station_data
SET precipitation_type = 'No precipitation'
WHERE precipitation_type = '0'
;

UPDATE weather_station_data
SET precipitation_type = 'Liquid precipitation, e.g. rain - Ice, hail and sleet are transmitted as rain (60)'
WHERE precipitation_type = '60'
;

UPDATE weather_station_data
SET precipitation_type = 'Solid precipitation, e.g. snow'
WHERE precipitation_type = '70'
;

UPDATE weather_station_data
SET precipitation_type = 'unspecified precipitation'
WHERE precipitation_type = '40'
;

```
</details>

From there, it was a matter of generating the tables that would be used for analysis.  The *cta_daily_boarding_v2* table was already cleaned, but the data is tracked daily, whereas the weather data was tracked hourly. In order to compare the two appropriately, I found the average weather figures for each day, and created a view I could use in the analysis:

<details>
	<summary><sub>Expand</sub></summary>

```SQL
-- The aggregation - Looking to find general weather condition by the day
CREATE VIEW daily_weather_avgs AS
SELECT 
    DATE(measurement_timestamp) AS measurement_date,
    ROUND(AVG(air_temperature), 1) AS air_temp,
    ROUND(AVG(wet_bulb_temperature), 1) AS wet_bulb_temp,
    ROUND(AVG(humidity), 1) AS humidity,
    ROUND(AVG(rain_intensity), 1) AS rain_intensity,
    ROUND(AVG(interval_rain), 1) AS interval_rain,
    ROUND(AVG(total_rain), 1) AS total_rain,
    ROUND(AVG(wind_direction), 1) AS wind_direction,
    ROUND(AVG(wind_speed), 1) AS wind_speed,
    ROUND(AVG(max_wind_speed), 1) AS max_wind_speed,
    ROUND(AVG(barometric_pressure), 1) AS barometric_pressure,
    ROUND(AVG(solar_radiation), 1) AS solar_radiation,
    ROUND(AVG(heading), 1) AS heading
FROM weather_station_data
GROUP BY measurement_date
ORDER BY measurement_date
;

```
</details>



## Analysis

### Questions

The goal of this analysis is to answer three questions:

1. How is ridership for different modes of public transit affected by different weather conditions?
   - Precipitation, temperature, humidity, solar radiation
3. Do people utilize different modes depending on those weather conditions?
4. Are there seasonal trends for different modes? (Does bus usage increase in the summer? Etc.)

### Approach

The first step was to gain familiarity with the dataset, by joining the two sources of data, then performing a few exploratory queries. 

I first checked the date range covered by joining the two sets of data, and it covers 9 years of data, which should suffice to analyze trends and patterns.  

<details>
	<summary><sub>Expand</sub></summary>
    
```SQL
# Date range

SELECT 
	MIN(service_date) AS first_date,
    MAX(service_date) AS last_date
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;
```
</details>

The results of this query are shown here:

|First Date|Last Date|
|---|---|
|2015-04-25|2024-04-30|


> [!NOTE]
> The timeframe includes the COVID-19 pandemic.
> The years of 2020, 2021, and 2022 will be filtered out of many queries in this analysis.
> If the pandemic was included, the patterns and trends that the questions above look to answer would be severely impacted by factors outside of the scope of this analysis.


<details>
	<summary><sub>Expand</sub></summary>
    
```SQL

```

</details>

<details>
	<summary><sub>Expand</sub></summary>
    
```SQL

# Joining the data
SELECT *
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

# Lowest, Highest, and Average temperatures

SELECT
MAX(air_temp) AS max_temp,
    MIN(air_temp) AS min_temp,
    ROUND(AVG(air_temp), 1) AS avg_temp
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

SELECT
	CONCAT(YEAR(service_date),'-',MONTH(service_date)) AS each_month,
	MAX(air_temp) AS max_temp,
    MIN(air_temp) AS min_temp,
    ROUND(AVG(air_temp), 1) AS avg_temp
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
GROUP BY each_month
ORDER BY each_month
;

```
</details>



## Visualization

Please find the produced dashboard [here](https://public.tableau.com/views/PortfolioProject-CTARidershipforDifferentWeatherFactors/CTARidershipDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)


## Conclusions
