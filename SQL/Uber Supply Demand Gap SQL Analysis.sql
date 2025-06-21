-- Uber Supply Demand Gap SQL Analysis 
-- 1. Overall demand versus supply
-- Question: How many ride requests were successfully served during the study period?
SELECT  
    COUNT(*) AS Total_requests,
    SUM(Status = 'Trip Completed') AS completed,
    ROUND(SUM(Status = 'Trip Completed') / COUNT(*), 2) AS completion_rate
FROM uber_requests;

-- 2. Completion rate by pickup location
-- Question: Does the success rate differ between the City and the Airport?
SELECT
    Pickup_point,
    SUM(Status = 'Trip Completed') AS Completed,
    ROUND(SUM(Status = 'Trip Completed') / COUNT(*), 2) AS Completion_Rate
FROM uber_requests
GROUP BY Pickup_point;

-- 3. Hour-by-hour supply gap
-- Question: At what hours does unmet demand spike?
SELECT
    Request_hour,
    ROUND(SUM(Gap_Flag = 'Demand Unfulfilled') / COUNT(*), 2) AS Gap_Ratio
FROM uber_requests
GROUP BY Request_hour
ORDER BY Gap_Ratio DESC;

-- 4. Time-of-day slot Performance
-- Question: Which time of day slot has suffered most?
SELECT
    Time_of_day_slot,
    ROUND(SUM(Status = 'Trip Completed') / COUNT(*), 2) AS Completion_Rate
FROM uber_requests
GROUP BY Time_of_day_slot
ORDER BY Completion_Rate DESC;

-- 5. Why requests fail (root-cause by location)
-- Question: When trips fail, is it driver cancellation or no cars?
SELECT
    Pickup_point,
    SUM(Status = 'Cancelled') AS Cancelled,
    SUM(Status = 'No Cars Available') AS No_Cars,
    ROUND(SUM(Status = 'Cancelled')
          / SUM(Status IN ('Cancelled','No Cars Available')), 2) AS Cancel_Share
FROM uber_requests
WHERE Status IN ('Cancelled','No Cars Available')
GROUP BY Pickup_point;

-- 6. Peak demand hour for each location
-- Question: When does each pickup point experience its single busiest hour?
SELECT
    Pickup_point,
    Request_hour,
    Request_Count
FROM (
    SELECT
        Pickup_point,
        Request_hour,
        COUNT(*) AS Request_Count,
        ROW_NUMBER() OVER (PARTITION BY Pickup_point ORDER BY COUNT(*) DESC) AS rn
    FROM uber_requests
    GROUP BY Pickup_point, Request_hour
) AS ranked
WHERE rn = 1;

-- 7. Average trip duration by pickup & slot
-- Question: Does traffic or anything else make some trips inherently longer?
SELECT
    Pickup_point,
    Time_of_day_slot,
    ROUND(AVG(Trip_duration_minutes), 1) AS Avg_Minutes
FROM uber_requests
WHERE Status = 'Trip Completed'
GROUP BY Pickup_point, Time_of_day_slot
ORDER BY Avg_Minutes DESC;

-- 8.  High-Performing drivers
-- Question: Who completes the most trips?
SELECT
    Driver_id,
    COUNT(*) AS Trips_Completed
FROM uber_requests
WHERE Status = 'Trip Completed'
GROUP BY Driver_id
ORDER BY Trips_Completed DESC
LIMIT 5;

-- 9.  Driver cancellation prevalence
-- Question: What proportion of active drivers cancel at least once?
WITH all_drivers AS (
    SELECT DISTINCT Driver_id
    FROM uber_requests
    WHERE Driver_id IS NOT NULL
),
cancellers AS (
    SELECT DISTINCT Driver_id
    FROM uber_requests
    WHERE Status = 'Cancelled'
)
SELECT
    ROUND((SELECT COUNT(*) FROM cancellers) / (SELECT COUNT(*) FROM all_drivers), 2) AS pct_cancelled;

-- 10. Weekday performance swing
-- Question: Do some weekdays perform better than others?
SELECT
    Weekday,
    COUNT(*) AS Total_Requests,
    SUM(Status = 'Trip Completed') AS Completed,
    ROUND(SUM(Status = 'Trip Completed') / COUNT(*), 2) AS Completion_Rate
FROM uber_requests
GROUP BY Weekday
ORDER BY FIELD(Weekday,
               'Monday','Tuesday','Wednesday',
               'Thursday','Friday','Saturday','Sunday');

-- 11. “Driver assigned” status check
-- Question: Do “No Cars Available” events ever happen after a driver is assigned?
SELECT
    Driver_status,
    Status,
    COUNT(*) AS Count
FROM uber_requests
GROUP BY Driver_status, Status;

-- 12. Hourly city vs airport gap comparison
-- Question: During which hours is the ride demand unfulfilled most often, and how does this differ between City and Airport pickups?
SELECT
    Request_hour,
    Pickup_point,
    ROUND(SUM(Gap_Flag = 'Demand Unfulfilled') / COUNT(*), 2) AS Gap_Ratio
FROM uber_requests
GROUP BY Request_hour, Pickup_point
ORDER BY Gap_Ratio DESC
LIMIT 10;









