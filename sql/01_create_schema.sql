-- NYC Motor Vehicle Collision Analysis | MySQL schema
-- Run on a new database before importing the source CSV.
-- If a table already exists, this script does NOT overwrite its contents.

CREATE DATABASE IF NOT EXISTS nyc_crashes;
USE nyc_crashes;

-- These names and types reflect the schema from the completed coursework.
-- Date and coordinate fields were initially imported as text; conversions
-- are applied at query time in 02_exploratory_queries.sql.
CREATE TABLE IF NOT EXISTS crashes (
    crash_date VARCHAR(20),
    crash_time VARCHAR(20),
    borough VARCHAR(50),
    zip_code VARCHAR(20),
    latitude VARCHAR(30),
    longitude VARCHAR(30),
    location VARCHAR(100),
    on_street_name VARCHAR(255),
    cross_street_name VARCHAR(255),
    off_street_name VARCHAR(255),
    persons_injured INT,
    persons_killed INT,
    pedestrians_injured INT,
    pedestrians_killed INT,
    cyclists_injured INT,
    cyclists_killed INT,
    motorists_injured INT,
    motorists_killed INT,
    contributing_factor_vehicle_1 VARCHAR(255),
    contributing_factor_vehicle_2 VARCHAR(255),
    contributing_factor_vehicle_3 VARCHAR(255),
    contributing_factor_vehicle_4 VARCHAR(255),
    contributing_factor_vehicle_5 VARCHAR(255),
    collision_id BIGINT,
    vehicle_type_code_1 VARCHAR(255),
    vehicle_type_code_2 VARCHAR(255),
    vehicle_type_code_3 VARCHAR(255),
    vehicle_type_code_4 VARCHAR(255),
    vehicle_type_code_5 VARCHAR(255)
);

-- These commands verify the table exists and display the schema.
SHOW TABLES;
DESCRIBE crashes;
