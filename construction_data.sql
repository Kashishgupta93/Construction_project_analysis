-- Total project count (how many projects?)
SELECT count(project_id) FROM construction_data;

-- Which types of construction projects does the company have more of?
SELECT project_type,count(project_id) as tot_count
From construction_data GROUP BY project_type order by tot_count DESC;
-- Make project_type column consistent(metro,Metro to Metro)
UPDATE construction_data
SET project_type = INITCAP(project_type);
-- all project_type
SELECT DISTINCT(project_type) from construction_data;

-- How many projects are there in each region?
SELECT region,count(project_id) as tot_project
FROM construction_data GROUP BY region order by tot_project DESC;

-- What is the project status distribution?
SELECT project_status ,count(*) as tot_count FROM construction_data
GROUP BY project_status order by tot_count DESC;

-- What is the total planned cost vs actual cost?
SELECT
    SUM(planned_cost_inr) AS Total_Planned_Cost,
    SUM(actual_cost_inr) AS Total_Actual_Cost,
    SUM(actual_cost_inr) - SUM(planned_cost_inr) AS Total_Cost_Overrun
FROM construction_data;

-- Which projects_type have the highest cost overruns?
SELECT project_type,sum(cost_overrun) as highest_costoverrun
from construction_data GROUP BY project_type order by highest_costoverrun DESC;

-- Which projects have the highest cost overruns?
SELECT project_name,actual_cost_inr,planned_cost_inr,cost_overrun
FROM construction_data Order by cost_overrun DESC;

-- Which project types have the highest average cost overrun?
SELECT project_type,AVG(cost_overrun) as avg_cost
FROM construction_data GROUP BY project_type ORDER BY avg_cost DESC;

-- Which contractors have the highest cost overruns?
SELECT contractor,SUM(cost_overrun) as high_cost
FROM construction_data GROUP BY contractor ORDER BY high_cost DESC;

-- Which project are delayed?
SELECT project_name,project_type,contractor,project_status
From construction_data where project_status='Delayed';

-- Which are the top 10 most delayed projects?
SELECT
    project_id,
    project_name,
    project_type,
    delay_days
FROM construction_data
ORDER BY delay_days DESC
LIMIT 10;

-- Which project types have the highest average delay?
SELECT
    project_type,
    ROUND(AVG(delay_days),2) AS Avg_Delay_Days
FROM construction_data
GROUP BY project_type
ORDER BY Avg_Delay_Days DESC;

-- Which locations have the highest average delay?
SELECT location,ROUND(AVG(delay_days),2) AS avg_delay FROM construction_data
GROUP BY location ORDER BY avg_delay DESC;

-- Which contractors have the highest average delay?
SELECT contractor,ROUND(AVG(delay_days),2) AS avg_delay FROM construction_data
GROUP BY contractor ORDER BY avg_delay DESC;


-- Which project types have the lowest average progress?
SELECT
    project_type,
    ROUND(AVG(actual_progress_pct),2) AS Avg_Actual_Progress
FROM construction_data
GROUP BY project_type
ORDER BY Avg_Actual_Progress;

-- Which contractors handle the most projects?
SELECT contractor,COUNT(project_id) as project_count
FROM construction_data GROUP BY contractor ORDER BY project_count DESC;

-- Which projects have the most quality issues?
SELECT project_name,project_id,contractor ,quality_issues,quality_rating
FROM construction_data ORDER BY quality_rating DESC LIMIT 10;

-- Which project types have the most quality issues?
SELECT project_type,SUM(quality_issues) as high_issue
FROM construction_data
GROUP BY project_type ORDER BY high_issue DESC;

-- Which projects have the most safety incidents?
SELECT
    project_id,
    project_name,
    safety_incidents,
    safety_score
FROM construction_data
ORDER BY safety_incidents DESC;

-- Which project types have the highest safety risk?
SELECT
    project_type,
    ROUND(SUM(safety_incidents),2) AS Avg_Safety_Incidents,
    ROUND(AVG(safety_score),2) AS Avg_Safety_Score
FROM construction_data
GROUP BY project_type
ORDER BY Avg_Safety_Incidents DESC;

-- ADD new costoverrun percentage column
ALTER TABLE construction_data
ADD COLUMN cost_overrun_pct NUMERIC(10,2);

-- Add value in it
UPDATE construction_data
SET cost_overrun_pct=((actual_cost_inr-planned_cost_inr)
                      /NULLIF(planned_cost_inr,0))*100;

-- Projects costing more than the average project cost
SELECT
    project_id,
    project_name,
    actual_cost_inr
FROM construction_data
WHERE actual_cost_inr >
      (SELECT AVG(actual_cost_inr)
       FROM construction_data);

-- Rank projects by cost overrun
SELECT
    project_id,
    project_name,
    project_type,
    cost_overrun_pct,
    RANK() OVER (
        ORDER BY cost_overrun_pct DESC
    ) AS Cost_Overrun_Rank
FROM construction_data;

-- Rank projects within each project type
SELECT
    project_id,
    project_name,
    project_type,
    cost_overrun_pct,
    RANK() OVER (
        PARTITION BY project_type
        ORDER BY cost_overrun_pct DESC
    ) AS Type_Rank
FROM construction_data;

-- Contractor Ranking
WITH ContractorPerformance AS (
    SELECT
        contractor,
        ROUND(AVG(cost_overrun_pct),2) AS Avg_Overrun,
        ROUND(AVG(delay_days),2) AS Avg_Delay
    FROM construction_data
    GROUP BY contractor
)

SELECT
    *,
    RANK() OVER (
        ORDER BY Avg_Overrun
    ) AS Contractor_Rank
FROM ContractorPerformance;