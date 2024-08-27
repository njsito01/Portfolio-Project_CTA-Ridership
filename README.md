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

<details>
	<summary><sub>Expand</sub></summary>
    
```SQL

# Joining the data
SELECT *
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

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

I first checked the date range covered by joining the two sets of data, and it covers 9 years of data, which should suffice to analyze trends and patterns.
The results of this query are shown here:

|First Date|Last Date|
|:---:|:---:|
|2015-04-25|2024-04-30|


> [!NOTE]
> The timeframe covers the COVID-19 pandemic.
> The years of 2020, 2021, and 2022 will be filtered out of many of the following queries.
> If the pandemic was included, the patterns and trends that the questions above look to answer would be severely impacted by factors outside of the scope of this analysis.


Next, I looked to Identify some of the extremes, as a whole, as well as throughout each month.

<details>
	<summary><sub>Expand</sub></summary>
    
```SQL
# Lowest, Highest, and Average temperatures

# Lowest, Highest, and Average temperatures

SELECT
	MAX(air_temp) AS max_temp,
    MIN(air_temp) AS min_temp,
    ROUND(AVG(air_temp), 1) AS avg_temp
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;

SELECT
	CONCAT(YEAR(service_date),'-',MONTH(service_date)) AS each_month,
	MAX(air_temp) AS max_temp,
    MIN(air_temp) AS min_temp,
    ROUND(AVG(air_temp), 1) AS avg_temp
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
GROUP BY each_month
ORDER BY each_month
;


```

</details>

The overall maximum, minimum, and average temperatures:

|max_temp|min_temp|avg_temp|
|:---:|:---:|:---:|
|89.1|-14.6|52.7|

A selection from the monthly figures:

|each_month|max_temp|min_temp|avg_temp|
|:---:|:---:|:---:|:---:|
|2015-4|44.6|43|43.8|
|2015-5|73.6|46|64.1|
|2015-6|79.1|48.2|64.7|
|2015-7|81.6|58|71.7|
|2015-8|82.4|61.6|72.2|
|2015-9|84.9|58.2|70.3|
|2015-10|67.2|43.6|56.4|
|2015-11|66.3|23.6|48.6|
|2015-12|59.4|24.8|41.1|
|2016-1|45|3.5|28|



Next, I looked to explore total ridership for both bus and rail, by month, to identify any seasonal patterns or trends

<details>
	<summary><sub>Expand</sub></summary>
    
```SQL
# Total ridership by month

SELECT
	CONCAT(YEAR(service_date),'-',MONTH(service_date)) AS each_month,
    SUM(bus) AS bus_ridership,
    SUM(rail_boardings) AS rail_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
GROUP BY each_month
ORDER BY each_month
LIMIT 10
;

```
</details>

Here's a selection of the results:
|each_month|bus_ridership|rail_ridership|
|:---:|:---:|:---:|
|2015-4|1419971|1253060|
|2015-5|4488475|3894277|
|2015-6|23206111|21125032|
|2015-7|22901148|21926763|
|2015-8|22218096|20802215|
|2015-9|23886543|21625824|
|2015-10|25047871|22663990|
|2015-11|21655511|19470592|
|2015-12|21343364|18501324|
|2016-1|20751116|18164698|


My next step was to take a rough look for any correlation between the various weather factors and ridership. I did this by identifying approximate "bands" within which would fall a "low", "medium", or "high" measurement of each respective weather factor, then calculating the count of records and total ridership for each mode that fell within each "band".

#### Temperature

<details>
	<summary><sub>Expand temperature query</sub></summary>

```SQL
-- Temperature
SELECT
	MAX(air_temp) AS max_temp,
    MIN(air_temp) AS min_temp,
    ROUND(AVG(air_temp), 1) AS avg_temp,
    ROUND(AVG(air_temp) * 0.9, 1) AS middle_band_low,
    ROUND(AVG(air_temp) * 1.1, 1) AS middle_band_high
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

SELECT
	'Bus Ridership' AS mode_label,
    SUM(CASE WHEN air_temp > 59 THEN 1 ELSE NULL END) AS high_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp > 59 THEN bus ELSE NULL END), 1) AS higher_temp_bus_ridership,
    SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN 1 ELSE NULL END) AS middle_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN bus ELSE NULL END), 1) AS middle_temp_bus_ridership,
    SUM(CASE WHEN air_temp < 48 THEN 1 ELSE NULL END) AS low_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp < 48 THEN bus ELSE NULL END), 1) AS lower_temp_bus_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN air_temp > 59 THEN 1 ELSE NULL END) AS above_avg_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp > 59 THEN rail_boardings ELSE NULL END), 1) AS higher_temp_rail_ridership,
    SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN 1 ELSE NULL END) AS middle_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN rail_boardings ELSE NULL END), 1) AS middle_temp_rail_ridership,
    SUM(CASE WHEN air_temp < 48 THEN 1 ELSE NULL END) AS below_avg_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp < 48 THEN rail_boardings ELSE NULL END), 1) AS lower_temp_rail_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;
```
</details>

Results:

|mode_label|high_temp_cnt|higher_temp_ridership|middle_temp_cnt|middle_temp_ridership|low_temp_cnt|lower_temp_ridership|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Bus Ridership	|867	|568869301	|303	|200867238	|896	|535899978|
|Rail Ridership	|867	|526709790	|303	|175830530	|896	|456893385|

#### Humidity:

<details>
	<summary><sub>Expand humidity query</sub></summary>

```SQL

-- Humidity
SELECT
	MAX(humidity) AS max_humidity,
    MIN(humidity) AS min_humidity,
    ROUND(AVG(humidity), 1) AS avg_humidity,
    ROUND(AVG(humidity)* 0.9, 1)  AS middle_band_low,
    ROUND(AVG(humidity) * 1.1, 1) AS middle_band_high
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

SELECT
	'Bus Ridership' AS mode_label,
    SUM(CASE WHEN humidity > 75 THEN 1 ELSE NULL END) AS high_hum_cnt,
    ROUND(SUM(CASE WHEN humidity > 75 THEN bus ELSE NULL END), 1) AS higher_hum_ridership,
    SUM(CASE WHEN humidity BETWEEN 61 AND 75 THEN 1 ELSE NULL END) AS middle_hum_cnt,
    ROUND(SUM(CASE WHEN humidity BETWEEN 61 AND 75 THEN bus ELSE NULL END), 1) AS middle_hum_ridership,
    SUM(CASE WHEN humidity < 61 THEN 1 ELSE NULL END) AS low_hum_cnt,
    ROUND(SUM(CASE WHEN humidity < 61 THEN bus ELSE NULL END), 1) AS lower_hum_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN humidity > 75 THEN 1 ELSE NULL END) AS above_avg_hum_cnt,
    ROUND(SUM(CASE WHEN humidity > 75 THEN rail_boardings ELSE NULL END), 1) AS higher_hum_ridership,
    SUM(CASE WHEN humidity BETWEEN 61 AND 75 THEN 1 ELSE NULL END) AS middle_hum_cnt,
    ROUND(SUM(CASE WHEN humidity BETWEEN 61 AND 75 THEN rail_boardings ELSE NULL END), 1) AS middle_hum_ridership,
    SUM(CASE WHEN humidity < 61 THEN 1 ELSE NULL END) AS below_avg_hum_cnt,
    ROUND(SUM(CASE WHEN humidity < 61 THEN rail_boardings ELSE NULL END), 1) AS lower_hum_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;

```

</details>

Results:

|mode_label	|high_hum_cnt	|higher_hum_ridership	|middle_hum_cnt	|middle_hum_ridership	|low_hum_cnt	|lower_hum_ridership|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Bus Ridership	|699	|448212113	|826	|521804099	|541	|335620305|
|Rail Ridership	|699	|404101125	|826	|463463004	|541	|291869576|


#### Rain Intensity:

<details>
	<summary><sub>Expand rain intensity query</sub></summary>

```SQL
-- Rain Intensity

SELECT
	MAX(rain_intensity) AS max_rain_intensity,
    MIN(rain_intensity) AS min_rain_intensity,
    ROUND(AVG(rain_intensity), 1) AS avg_rain_intensity,
    ROUND(AVG(rain_intensity)* 0.9, 1)  AS middle_band_low,
    ROUND(AVG(rain_intensity) * 1.1, 1) AS middle_band_high
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

SELECT
	'Bus Ridership' AS mode_label,
    SUM(CASE WHEN rain_intensity > 0.2 THEN 1 ELSE NULL END) AS high_rain_intensity_cnt,
    ROUND(SUM(CASE WHEN rain_intensity > 0.2 THEN bus ELSE NULL END), 1) AS higher_rain_intensity_ridership,
    SUM(CASE WHEN rain_intensity BETWEEN 0.1 AND 0.2 THEN 1 ELSE NULL END) AS middle_rain_intensity_cnt,
    ROUND(SUM(CASE WHEN rain_intensity BETWEEN 0.1 AND 0.2 THEN bus ELSE NULL END), 1) AS middle_rain_intensity_ridership,
    SUM(CASE WHEN rain_intensity < 0.1 THEN 1 ELSE NULL END) AS low_rain_intensity_cnt,
    ROUND(SUM(CASE WHEN rain_intensity < 0.1 THEN bus ELSE NULL END), 1) AS lower_rain_intensity_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN rain_intensity > 0.2 THEN 1 ELSE NULL END) AS above_avg_rain_intensity_cnt,
    ROUND(SUM(CASE WHEN rain_intensity > 0.2 THEN rail_boardings ELSE NULL END), 1) AS higher_rain_intensity_ridership,
    SUM(CASE WHEN rain_intensity BETWEEN 0.1 AND 0.2 THEN 1 ELSE NULL END) AS middle_rain_intensity_cnt,
    ROUND(SUM(CASE WHEN rain_intensity BETWEEN 0.1 AND 0.2 THEN rail_boardings ELSE NULL END), 1) AS middle_rain_intensity_ridership,
    SUM(CASE WHEN rain_intensity < 0.1 THEN 1 ELSE NULL END) AS below_avg_rain_intensity_cnt,
    ROUND(SUM(CASE WHEN rain_intensity < 0.1 THEN rail_boardings ELSE NULL END), 1) AS lower_rain_intensity_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;

```

</details>

Results:

|mode_label |high_rain_intensity_cnt |higher_rain_intensity_ridership |middle_rain_intensity_cnt |middle_rain_intensity_ridership |low_rain_intensity_cnt |lower_rain_intensity_ridership|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Bus Ridership	|313	|194484769	|210	|128971131	|1543	|982180617|
|Rail Ridership	|313	|177131034	|210	|114211487	|1543	|868091184|


#### Total rain:

<details>
	<summary><sub>Expand total rain query</sub></summary>

```SQL
-- Total Rain

SELECT
	MAX(total_rain) AS max_total_rain,
    MIN(total_rain) AS min_total_rain,
    ROUND(AVG(total_rain), 1) AS avg_total_rain,
    ROUND(AVG(total_rain)* 0.9, 1)  AS middle_band_low,
    ROUND(AVG(total_rain) * 1.1, 1) AS middle_band_high
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

SELECT
	'Bus Ridership' AS mode_label,
    SUM(CASE WHEN total_rain > 153 THEN 1 ELSE NULL END) AS high_total_rain_cnt,
    ROUND(SUM(CASE WHEN total_rain > 153 THEN bus ELSE NULL END), 1) AS higher_total_rain_ridership,
    SUM(CASE WHEN total_rain BETWEEN 125 AND 153 THEN 1 ELSE NULL END) AS middle_total_rain_cnt,
    ROUND(SUM(CASE WHEN total_rain BETWEEN 125 AND 153 THEN bus ELSE NULL END), 1) AS middle_total_rain_ridership,
    SUM(CASE WHEN total_rain < 125 THEN 1 ELSE NULL END) AS low_total_rain_cnt,
    ROUND(SUM(CASE WHEN total_rain < 125 THEN bus ELSE NULL END), 1) AS lower_total_rain_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN total_rain > 153 THEN 1 ELSE NULL END) AS above_avg_total_rain_cnt,
    ROUND(SUM(CASE WHEN total_rain > 153 THEN rail_boardings ELSE NULL END), 1) AS higher_total_rain_ridership,
    SUM(CASE WHEN total_rain BETWEEN 125 AND 153 THEN 1 ELSE NULL END) AS middle_total_rain_cnt,
    ROUND(SUM(CASE WHEN total_rain BETWEEN 125 AND 153 THEN rail_boardings ELSE NULL END), 1) AS middle_total_rain_ridership,
    SUM(CASE WHEN total_rain < 125 THEN 1 ELSE NULL END) AS below_avg_total_rain_cnt,
    ROUND(SUM(CASE WHEN total_rain < 125 THEN rail_boardings ELSE NULL END), 1) AS lower_total_rain_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;

```

</details>

Results:

|mode_label |high_total_rain_cnt |higher_total_rain_ridership| middle_total_rain_cnt| middle_total_rain_ridership| low_total_rain_cnt|lower_total_rain_ridership|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Bus Ridership	|640	|426674087	|49	|31171929	|1377	|847790501|
|Rail Ridership	|640	|397044693	|49	|28461491	|1377	|733927521|


#### Wind speed:

<details>
	<summary><sub>Expand wind speed query</sub></summary>

```SQL
-- Wind Speed

SELECT
	MAX(wind_speed) AS max_wind_speed,
    MIN(wind_speed) AS min_wind_speed,
    ROUND(AVG(wind_speed), 1) AS avg_wind_speed,
    ROUND(AVG(wind_speed)* 0.9, 1)  AS middle_band_low,
    ROUND(AVG(wind_speed) * 1.1, 1) AS middle_band_high
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

SELECT
	'Bus Ridership' AS mode_label,
    SUM(CASE WHEN wind_speed > 3.2 THEN 1 ELSE NULL END) AS high_wind_speed_cnt,
    ROUND(SUM(CASE WHEN wind_speed > 3.2 THEN bus ELSE NULL END), 1) AS higher_wind_speed_ridership,
    SUM(CASE WHEN wind_speed BETWEEN 2.7 AND 3.2 THEN 1 ELSE NULL END) AS middle_wind_speed_cnt,
    ROUND(SUM(CASE WHEN wind_speed BETWEEN 2.7 AND 3.2 THEN bus ELSE NULL END), 1) AS middle_wind_speed_ridership,
    SUM(CASE WHEN wind_speed < 2.7 THEN 1 ELSE NULL END) AS low_wind_speed_cnt,
    ROUND(SUM(CASE WHEN wind_speed < 2.7 THEN bus ELSE NULL END), 1) AS lower_wind_speed_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN wind_speed > 3.2 THEN 1 ELSE NULL END) AS above_avg_wind_speed_cnt,
    ROUND(SUM(CASE WHEN wind_speed > 3.2 THEN rail_boardings ELSE NULL END), 1) AS higher_wind_speed_ridership,
    SUM(CASE WHEN wind_speed BETWEEN 2.7 AND 3.2 THEN 1 ELSE NULL END) AS middle_wind_speed_cnt,
    ROUND(SUM(CASE WHEN wind_speed BETWEEN 2.7 AND 3.2 THEN rail_boardings ELSE NULL END), 1) AS middle_wind_speed_ridership,
    SUM(CASE WHEN wind_speed < 2.7 THEN 1 ELSE NULL END) AS below_avg_wind_speed_cnt,
    ROUND(SUM(CASE WHEN wind_speed < 2.7 THEN rail_boardings ELSE NULL END), 1) AS lower_wind_speed_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;

```

</details>

Results:

|mode_label|high_wind_speed_cnt|higher_wind_speed_ridership|middle_twind_speed_cnt|middle_wind_speed_ridership|low_wind_speed_cnt|lower_wind_speed_ridership|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Bus Ridership	|637	|423434601	|463	|276064499	|966	|606137417|
|Rail Ridership	|637	|379566419	|463	|236114046	|966	|543753240|


#### Barometric pressure:

<details>
	<summary><sub>Expand barometric pressure query</sub></summary>

```SQL

-- Barometric Pressure

SELECT
	MAX(barometric_pressure) AS max_bp,
    MIN(barometric_pressure) AS min_bp,
    ROUND(AVG(barometric_pressure), 1) AS avg_bp,
    ROUND(AVG(barometric_pressure)* 0.9, 1)  AS middle_band_low,
    ROUND(AVG(barometric_pressure) * 1.1, 1) AS middle_band_high
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
; -- 'Middle band' calculations extend past min and max values

SELECT
	'Bus Ridership' AS mode_label,
    SUM(CASE WHEN barometric_pressure > 1000 THEN 1 ELSE NULL END) AS high_bp_cnt,
    ROUND(SUM(CASE WHEN barometric_pressure > 1000 THEN bus ELSE NULL END), 1) AS higher_bp_ridership,
    SUM(CASE WHEN barometric_pressure BETWEEN 990 AND 1000 THEN 1 ELSE NULL END) AS middle_bp_cnt,
    ROUND(SUM(CASE WHEN barometric_pressure BETWEEN 990 AND 1000 THEN bus ELSE NULL END), 1) AS middle_bp_ridership,
    SUM(CASE WHEN barometric_pressure < 990 THEN 1 ELSE NULL END) AS low_bp_cnt,
    ROUND(SUM(CASE WHEN barometric_pressure < 990 THEN bus ELSE NULL END), 1) AS lower_bp_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN barometric_pressure > 1000 THEN 1 ELSE NULL END) AS above_avg_bp_cnt,
    ROUND(SUM(CASE WHEN barometric_pressure > 1000 THEN rail_boardings ELSE NULL END), 1) AS higher_bp_ridership,
    SUM(CASE WHEN barometric_pressure BETWEEN 990 AND 1000 THEN 1 ELSE NULL END) AS middle_bp_cnt,
    ROUND(SUM(CASE WHEN barometric_pressure BETWEEN 990 AND 1000 THEN rail_boardings ELSE NULL END), 1) AS middle_bp_ridership,
    SUM(CASE WHEN barometric_pressure < 990 THEN 1 ELSE NULL END) AS below_avg_bp_cnt,
    ROUND(SUM(CASE WHEN barometric_pressure < 990 THEN rail_boardings ELSE NULL END), 1) AS lower_bp_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;

```

</details>

Results:

|mode_label|high_bp_cnt|higher_bp_ridership|middle_bp_cnt|middle_bp_ridership|low_bp_cnt|lower_bp_ridership|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Bus Ridership	|355	|215773932	|1205	|765821460	|506	|324041125|
|Rail Ridership	|355	|188189889	|1205	|685212567	|506	|286031249|


#### Solar radiation:

<details>
	<summary><sub>Expand solar radiation query</sub></summary>

```SQL
-- Solar Radiation

SELECT
	MAX(solar_radiation) AS max_solar,
    MIN(solar_radiation) AS min_solar,
    ROUND(AVG(solar_radiation), 1) AS avg_solar,
    ROUND(AVG(solar_radiation)* 0.9, 1)  AS middle_band_low,
    ROUND(AVG(solar_radiation) * 1.1, 1) AS middle_band_high
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
; 

SELECT
	'Bus Ridership' AS mode_label,
    SUM(CASE WHEN solar_radiation > 117 THEN 1 ELSE NULL END) AS high_solar_cnt,
    ROUND(SUM(CASE WHEN solar_radiation > 117 THEN bus ELSE NULL END), 1) AS higher_solar_ridership,
    SUM(CASE WHEN solar_radiation BETWEEN 95 AND 117 THEN 1 ELSE NULL END) AS middle_solar_cnt,
    ROUND(SUM(CASE WHEN solar_radiation BETWEEN 95 AND 117 THEN bus ELSE NULL END), 1) AS middle_solar_ridership,
    SUM(CASE WHEN solar_radiation < 95 THEN 1 ELSE NULL END) AS low_solar_cnt,
    ROUND(SUM(CASE WHEN solar_radiation < 95 THEN bus ELSE NULL END), 1) AS lower_solar_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN solar_radiation > 117 THEN 1 ELSE NULL END) AS above_avg_solar_cnt,
    ROUND(SUM(CASE WHEN solar_radiation > 117 THEN rail_boardings ELSE NULL END), 1) AS higher_solar_ridership,
    SUM(CASE WHEN solar_radiation BETWEEN 95 AND 117 THEN 1 ELSE NULL END) AS middle_solar_cnt,
    ROUND(SUM(CASE WHEN solar_radiation BETWEEN 95 AND 117 THEN rail_boardings ELSE NULL END), 1) AS middle_solar_ridership,
    SUM(CASE WHEN solar_radiation < 95 THEN 1 ELSE NULL END) AS below_avg_solar_cnt,
    ROUND(SUM(CASE WHEN solar_radiation < 95 THEN rail_boardings ELSE NULL END), 1) AS lower_solar_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;
```

</details>

Results:

|mode_label|high_solar_cnt|higher_solar_ridership|middle_solar_cnt|middle_solar_ridership|low_solar_cnt|lower_solar_ridership|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Bus Ridership	|803	|502187599	|188	|127534501	|1075	|675914417|
|Rail Ridership	|803	|448369919	|188	|115191799	|1075	|595871987|


### Seasonal Trends

Coming back to the monthly ridership totals, I wanted to clarify by season, checking both total number of trips made by each mode, as well as the average for each season:

<details>
	<summary><sub>Expand</sub></summary>

```SQL
SELECT
    MONTH(service_date) AS observation_month,
    SUM(bus) AS total_bus_ridership,
    SUM(rail_boardings) AS total_rail_ridership,
    SUM(total_rides) AS total_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
GROUP BY observation_month
ORDER BY observation_month
;

SELECT
    CASE
		WHEN MONTH(service_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(service_date) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(service_date) IN (9, 10, 11) THEN 'Autumn'
        WHEN MONTH(service_date) IN (12, 1, 2) THEN 'Winter'
	END AS season,
    SUM(bus) AS total_bus_ridership,
    SUM(rail_boardings) AS total_rail_ridership,
    SUM(total_rides) AS total_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
GROUP BY season
;


SELECT
    CASE
		WHEN MONTH(service_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(service_date) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(service_date) IN (9, 10, 11) THEN 'Autumn'
        WHEN MONTH(service_date) IN (12, 1, 2) THEN 'Winter'
	END AS season,
    ROUND(AVG(bus), 1) AS avg_bus_ridership,
    ROUND(AVG(rail_boardings), 1) AS avg_rail_ridership,
    ROUND(AVG(total_rides), 1) AS avg_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
GROUP BY season
;
```
 
</details>

Total by month:

|observation_month	|total_bus_ridership	|total_rail_ridership	|total_ridership|
|:---:|:---:|:---:|:---:|
|1	|101553375	|86214121	|187767496|
|2	|104189894	|85794873	|189984767|
|3	|114426276	|96126349	|210552625|
|4	|111997146	|96185201	|208182347|
|5	|98567904	|86864390	|185432294|
|6	|118913077	|111175686	|230088763|
|7	|115714401	|110425690	|226140091|
|8	|119227303	|112921675	|232148978|
|9	|124215218	|112152641	|236367859|
|10	|108531844	|98572901	|207104745|
|11	|96999053	|86219611	|183218664|
|12	|91301026	|76780567	|168081593|



Total by season:

|season	|total_bus_ridership	|total_rail_ridership	|total_ridership|
|:---:|:---:|:---:|:---:|
|Spring	|324991326	|279175940	|604167266|
|Summer	|353854781	|334523051	|688377832|
|Autumn	|329746115	|296945153	|626691268|
|Winter	|297044295	|248789561	|545833856|


Average by season:

|season	|avg_bus_ridership	|avg_rail_ridership	|avg_ridership|
|:---:|:---:|:---:|:---:|
|Spring	|626187.5	|537911.3	|1164098.8|
|Summer	|641041.3	|606020.0	|1247061.3|
|Autumn	|681293.6	|613523.0	|1294816.7|
|Winter	|581300.0	|486868.0	|1068168.0|




## Visualization

Please find the produced dashboard [here](https://public.tableau.com/views/PortfolioProject-CTARidershipforDifferentWeatherFactors/CTARidershipDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)


## Conclusions
