
/*
	CTA Ridership Compared to weather (Exploratory Data Analysis)
    
    Questions:
	1. How is ridership for different modes of transit affected by different weather conditions?
		- Wind speed, solar radiation, temperature, humidity
	2. Do people utilize different modes depending on the amount of precipitation? What about for hot vs. cold temperatures?
	3. Are there seasonal trends for different modes? (ie.: Does bus usage increase in the summer? Etc.)
*/

# Working tables

SELECT *
FROM weather_station_data
;

SELECT *
FROM cta_daily_boarding_v2
;


# Join
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

/*
	 Running simple checks for correlation between riderships and different weather factors
	- Not utilizing data from 2020-2022 as COVID ridership will adversely affect the ability to identify general rider patterns
	- There does appear to be some potential correlation between ridership and different weather factors,
		but visualizations will make it more apparent
*/


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
    ROUND(SUM(CASE WHEN air_temp > 59 THEN bus ELSE NULL END), 1) AS higher_temp_ridership,
    SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN 1 ELSE NULL END) AS middle_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN bus ELSE NULL END), 1) AS middle_temp_ridership,
    SUM(CASE WHEN air_temp < 48 THEN 1 ELSE NULL END) AS low_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp < 48 THEN bus ELSE NULL END), 1) AS lower_temp_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
UNION
SELECT
	'Rail Ridership' AS mode_label,
    SUM(CASE WHEN air_temp > 59 THEN 1 ELSE NULL END) AS above_avg_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp > 59 THEN rail_boardings ELSE NULL END), 1) AS higher_temp_ridership,
    SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN 1 ELSE NULL END) AS middle_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp BETWEEN 48 AND 59 THEN rail_boardings ELSE NULL END), 1) AS middle_temp_ridership,
    SUM(CASE WHEN air_temp < 48 THEN 1 ELSE NULL END) AS below_avg_temp_cnt,
    ROUND(SUM(CASE WHEN air_temp < 48 THEN rail_boardings ELSE NULL END), 1) AS lower_temp_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
;


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


/*
	Looking at monthly and seasonal trends in ridership by mode
		-spring runs from March 1 to May 31;
		-summer runs from June 1 to August 31;
		-fall (autumn) runs from September 1 to November 30; and.
		-winter runs from December 1 to February 28 (February 29 in a leap year).
*/


SELECT *
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
;

SELECT
    MONTH(service_date) AS observation_month,
    ROUND(AVG(bus), 1) AS avg_bus_ridership,
    ROUND(AVG(rail_boardings), 1) AS avg_rail_ridership,
    ROUND(AVG(total_rides), 1) AS avg_total_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
GROUP BY observation_month
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
    ROUND(AVG(total_rides), 1) AS avg_total_ridership
FROM cta_daily_boarding_v2 AS cta
JOIN daily_weather_avgs AS dwa
	ON cta.service_date = dwa.measurement_date
WHERE YEAR(service_date) NOT IN ('2020','2021','2022')
GROUP BY season
;




