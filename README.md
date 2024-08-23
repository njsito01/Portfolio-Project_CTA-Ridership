# Portfolio Project - CTA Ridership
Analyzing the effects of weather on ridership for various modes of public transit


## Introduction

1. How is ridership for different modes of public transit affected by different weather conditions?
   - Precipitation, temperature, humidity, solar radiation
3. Do people utilize different modes depending on those weather conditions?
4. Are there seasonal trends for different modes? (Does bus usage increase in the summer? Etc.)

## Preparation & Data Cleaning


### Data and Tools

You can find the datasets I used here for [CTA Ridership](https://data.cityofchicago.org/Transportation/CTA-Ridership-Daily-Boarding-Totals/6iiy-9s97/about_data)
and here for [weather](https://data.cityofchicago.org/Parks-Recreation/Beach-Weather-Stations-Automated-Sensors/k7hf-8y75/about_data)

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


## Analysis


## Visualization

Please find the produced dashboard [here](https://public.tableau.com/views/PortfolioProject-CTARidershipforDifferentWeatherFactors/CTARidershipDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)


## Conclusions
