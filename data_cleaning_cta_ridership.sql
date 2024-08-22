/*
	CTA Ridership Compared to weather (Data Cleaning)
*/

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


# New working tables

SELECT *
FROM weather_station_data
;

SELECT *
FROM cta_daily_boarding
;

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


# CTA daily boarding table -  Identifying duplicates, NULLs, blanks, and negative values

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


SELECT *
FROM cta_daily_boarding
WHERE service_date = '2011-10-01'
# 10/2/11-10/31/11 and 7/1/14-7/31/14
;


 -- Creating a new working table with row_numbers, for removing duplicates
CREATE TABLE cta_daily_boarding_v2 AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY service_date ORDER BY service_date) AS row_cnt
FROM cta_daily_boarding
)
;

SELECT *
FROM cta_daily_boarding_v2
;

 -- Checking one of the duplicate dates
SELECT *
FROM cta_daily_boarding_v2
WHERE service_date = '2011-10-01'
# 10/2/11-10/31/11 and 7/1/14-7/31/14
;

DELETE FROM cta_daily_boarding_v2
WHERE row_cnt > 1
;


/*
		Cleaning weather station data, as well as normalizing (aggregating) to conform to ridership data
        This will involve collecting average temperature, wind speed, precipitation, etc,. for each day, as that is the interval used for the ridership data
*/

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


SELECT *
FROM weather_station_data
;

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
; 							/*This looks like bad data, I could match it to the '0' values in the same timeframe, 
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



# Aggregating for use in analysis

SELECT *
FROM weather_station_data
;

SELECT *
FROM weather_station_data
ORDER BY station_name, measurement_timestamp
;

SELECT
	station_name,
    DATE(measurement_timestamp) AS measurement_date,
    precipitation_type
FROM weather_station_data
WHERE precipitation_type IS NOT NULL
ORDER BY station_name, measurement_date
;

SELECT
	precipitation_type,
	COUNT(*)
FROM weather_station_data
GROUP BY precipitation_type
;

SELECT *
FROM weather_station_data
WHERE precipitation_type = 'Solid precipitation, e.g. snow'
ORDER BY station_name, measurement_timestamp
;

-- Looking to find the precipitation type that occurred the most on each day

SELECT *
FROM weather_station_data
;


SELECT
	DATE(measurement_timestamp) AS measurement_date,
    precipitation_type,
    COUNT(precipitation_type) AS prec_type_cnt
FROM weather_station_data
GROUP BY measurement_date, precipitation_type
ORDER BY measurement_date, precipitation_type
;


WITH precip_counts AS (
SELECT
	DATE(measurement_timestamp) AS measurement_date,
    precipitation_type,
    COUNT(precipitation_type) AS prec_type_cnt
FROM weather_station_data
GROUP BY measurement_date, precipitation_type
ORDER BY measurement_date, precipitation_type
), rankings AS (
SELECT
	measurement_date,
    precipitation_type,
    DENSE_RANK() OVER(PARTITION BY measurement_date ORDER BY prec_type_cnt DESC) AS ranking
FROM precip_counts
)
SELECT *
FROM rankings
WHERE ranking = 1
;



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







