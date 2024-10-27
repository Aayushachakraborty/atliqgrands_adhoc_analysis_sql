CREATE DATABASE IF NOT EXISTS hotel_management;
USE hotel_management;

DROP TABLE IF EXISTS fact_bookings;

CREATE TABLE fact_bookings (
     booking_id VARCHAR(255) PRIMARY KEY,
    property_id INT,
    booking_date DATE,
    check_in_date DATE,
    checkout_date DATE,
    no_guests INT,
    room_category VARCHAR(100),
    booking_platform VARCHAR(100),
    ratings_given FLOAT NULL,
    booking_status VARCHAR(50),
    revenue_generated DECIMAL(10, 2),
    revenue_realized DECIMAL(10, 2)
);


select * from fact_bookings;
 
SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/fact_bookings.csv'
INTO TABLE fact_bookings
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

-- TEMPORARY
DROP TABLE IF EXISTS temp_bookings;

CREATE TABLE temp_bookings (
    booking_id VARCHAR(255),
    property_id INT,
    booking_date VARCHAR(10),  -- Keep as VARCHAR for date strings
    check_in_date VARCHAR(10),
    checkout_date VARCHAR(10),
    no_guests INT,
    room_category VARCHAR(100),
    booking_platform VARCHAR(100),
    ratings_given VARCHAR(10),  -- Keep as VARCHAR to handle empty strings
    booking_status VARCHAR(50),
    revenue_generated DECIMAL(10, 2),
    revenue_realized DECIMAL(10, 2)
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/fact_bookings.csv'
INTO TABLE temp_bookings
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

INSERT INTO fact_bookings (booking_id, property_id, booking_date, check_in_date, checkout_date, no_guests, room_category, booking_platform, ratings_given, booking_status, revenue_generated, revenue_realized)
SELECT 
    booking_id,
    property_id,
    STR_TO_DATE(booking_date, '%d-%m-%Y') AS booking_date,
    STR_TO_DATE(check_in_date, '%d-%m-%Y') AS check_in_date,
    STR_TO_DATE(checkout_date, '%d-%m-%Y') AS checkout_date,
    no_guests,
    room_category,
    booking_platform,
    NULLIF(ratings_given, '') AS ratings_given,
    booking_status,
    revenue_generated,
    revenue_realized
FROM temp_bookings;

DROP TABLE IF EXISTS temp_bookings;

show tables;

SELECT COUNT(*) FROM fact_bookings;

SELECT * FROM fact_bookings LIMIT 10;
CREATE TABLE fact_aggregated_bookings (
    property_id INT,
    check_in_date DATE,
    room_category VARCHAR(100),
    successful_bookings INT,
    capacity INT
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/fact_aggregated_bookings.csv'
INTO TABLE fact_aggregated_bookings
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(property_id, @check_in_date, room_category, successful_bookings, capacity)
SET check_in_date = STR_TO_DATE(@check_in_date, '%d-%b-%y');

SELECT COUNT(*) FROM fact_aggregated_bookings;
SELECT * FROM fact_aggregated_bookings LIMIT 10;

CREATE TABLE properties (
    property_id INT PRIMARY KEY,
    property_name VARCHAR(100),
    category VARCHAR(50),
    city VARCHAR(50)
);
INSERT INTO properties (property_id, property_name, category, city)
VALUES
(16558, 'Atliq Grands', 'Luxury', 'Delhi'),
(16559, 'Atliq Exotica', 'Luxury', 'Mumbai'),
(16560, 'Atliq City', 'Business', 'Delhi'),
(16561, 'Atliq Blu', 'Luxury', 'Delhi'),
(16562, 'Atliq Bay', 'Luxury', 'Delhi'),
(16563, 'Atliq Palace', 'Business', 'Delhi'),
(17558, 'Atliq Grands', 'Luxury', 'Mumbai'),
(17559, 'Atliq Exotica', 'Luxury', 'Mumbai'),
(17560, 'Atliq City', 'Business', 'Mumbai'),
(17561, 'Atliq Blu', 'Luxury', 'Mumbai'),
(17562, 'Atliq Bay', 'Luxury', 'Mumbai'),
(17563, 'Atliq Palace', 'Business', 'Mumbai'),
(18558, 'Atliq Grands', 'Luxury', 'Hyderabad'),
(18559, 'Atliq Exotica', 'Luxury', 'Hyderabad'),
(18560, 'Atliq City', 'Business', 'Hyderabad'),
(18561, 'Atliq Blu', 'Luxury', 'Hyderabad'),
(18562, 'Atliq Bay', 'Luxury', 'Hyderabad'),
(18563, 'Atliq Palace', 'Business', 'Hyderabad'),
(19558, 'Atliq Grands', 'Luxury', 'Bangalore'),
(19559, 'Atliq Exotica', 'Luxury', 'Bangalore'),
(19560, 'Atliq City', 'Business', 'Bangalore'),
(19561, 'Atliq Blu', 'Luxury', 'Bangalore'),
(19562, 'Atliq Bay', 'Luxury', 'Bangalore'),
(19563, 'Atliq Palace', 'Business', 'Bangalore'),
(17564, 'Atliq Seasons', 'Business', 'Mumbai');

SELECT 
    fb.booking_id,
    fb.property_id,
    p.property_name,
    p.category AS property_category,
    p.city,
    fb.booking_date,
    fb.check_in_date,
    fb.checkout_date,
    fb.no_guests,
    fb.room_category,
    fb.booking_platform,
    fb.ratings_given,
    fb.booking_status,
    fb.revenue_generated,
    fb.revenue_realized,
    fab.successful_bookings,
    fab.capacity
FROM 
    fact_bookings fb
JOIN 
    fact_aggregated_bookings fab 
    ON fb.property_id = fab.property_id AND fb.check_in_date = fab.check_in_date AND fb.room_category = fab.room_category
JOIN 
    properties p 
    ON fb.property_id = p.property_id;
-- Calculate Total Revenue for Each Property
SELECT 
    p.property_name,
    SUM(fb.revenue_realized) AS total_revenue
FROM 
    fact_bookings fb
JOIN 
    properties p ON fb.property_id = p.property_id
GROUP BY 
    p.property_name
ORDER BY 
    total_revenue DESC;
    -- Calculate Occupancy Percentage by Property
SELECT
    p.property_name,
    (SUM(fab.successful_bookings) / SUM(fab.capacity)) * 100 AS occupancy_percentage
FROM
    fact_aggregated_bookings fab
JOIN
    properties p ON fab.property_id = p.property_id
GROUP BY
    p.property_name
ORDER BY
    occupancy_percentage DESC;
-- Calculate the Average Rating per Property
SELECT 
    p.property_name,
    AVG(fb.ratings_given) AS average_rating
FROM 
    fact_bookings fb
JOIN 
    properties p ON fb.property_id = p.property_id
WHERE 
    fb.ratings_given IS NOT NULL
GROUP BY 
    p.property_name
ORDER BY 
    average_rating DESC;
-- Revenue and Occupancy Split by City and Property
SELECT
    p.city,
    p.property_name,
    SUM(fb.revenue_realized) AS total_revenue,
    (SUM(fab.successful_bookings) / SUM(fab.capacity)) * 100 AS occupancy_percentage
FROM
    fact_bookings fb
JOIN
    fact_aggregated_bookings fab ON fb.property_id = fab.property_id AND fb.check_in_date = fab.check_in_date AND fb.room_category = fab.room_category
JOIN
    properties p ON fb.property_id = p.property_id
GROUP BY
    p.city, p.property_name
ORDER BY
    total_revenue DESC;
-- Trend in Weekly Revenue
SELECT
    YEAR(fb.check_in_date) AS year,
    WEEK(fb.check_in_date) AS week_number,
    SUM(fb.revenue_realized) AS weekly_revenue
FROM
    fact_bookings fb
GROUP BY
    year, week_number
ORDER BY
    year, week_number;
-- Occupancy by Day Type (Weekend vs Weekday)
SELECT
    p.property_name,
    CASE 
        WHEN DAYOFWEEK(fab.check_in_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    (SUM(fab.successful_bookings) / SUM(fab.capacity)) * 100 AS occupancy_percentage
FROM
    fact_aggregated_bookings fab
JOIN
    properties p ON fab.property_id = p.property_id
GROUP BY
    p.property_name, day_type
ORDER BY
    p.property_name, day_type;
-- Booking % by Platform
SELECT
    fb.booking_platform,
    COUNT(fb.booking_id) AS total_bookings,
    (COUNT(fb.booking_id) / (SELECT COUNT(*) FROM fact_bookings)) * 100 AS booking_percentage
FROM
    fact_bookings fb
GROUP BY
    fb.booking_platform
ORDER BY
    total_bookings DESC;



