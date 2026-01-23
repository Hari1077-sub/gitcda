CREATE SCHEMA cwc_analysis;
USE cwc_analysis;
CREATE TABLE AVERAGE_RUN_RATE_PER_TOURNAMENT(
Tournament_ID VARCHAR(50) PRIMARY KEY,
Average_Run_Rate FLOAT
);
INSERT INTO  AVERAGE_RUN_RATE_PER_TOURNAMENT
SELECT 
   Tournament_ID,round(avg((((1st_innings_score / Overs_1st) + (2nd_innings_score / Overs_2nd)) / 2)),2) AS ARR_per_tournament
FROM
  cwc_analysis.Wcwc_2022 Group by Tournament_ID;
CREATE TABLE Win_bias(
Tournament_ID VARCHAR(10) PRIMARY KEY,
Matches_Won_by_Chasing INT,
Matches_Won_by_Defending INT
);
INSERT INTO Win_bias
SELECT 
    Tournament_ID,
    (SELECT 
            COUNT(Match_Won_by)
        FROM
            cwc_analysis.cwc_2019
        WHERE
            Match_Won_by = 'Chasing') as Matches_Won_by_Chasing,
    (SELECT 
            COUNT(Match_Won_by)
        FROM
           cwc_analysis.cwc_2019
        WHERE
            Match_Won_by = 'Defending') as Matches_Won_by_Defending
FROM
    cwc_analysis.cwc_2019
group by 
	Tournament_ID;
CREATE TABLE  TOSS_ROLE_IN_WINNING(
Tournament_ID VARCHAR(10) PRIMARY KEY,
no_of_teams_won_toss_and_match INT
);
INSERT INTO TOSS_ROLE_IN_WINNING
SELECT 
    Tournament_ID,
    (SELECT 
            COUNT(Winner)
        FROM
            cwc_analysis.cwc_2023
        WHERE
            Winner = Toss_Won_By) AS no_of_teams_won_toss_and_match
FROM
    cwc_analysis.cwc_2023
GROUP BY Tournament_ID;
CREATE TABLE bowling_intensity(
Tournament_ID VARCHAR(10) PRIMARY KEY,
Bowling_Index enum('Lethal','Average','Poor')
);
INSERT INTO bowling_intensity
SELECT 
    Tournament_ID,
    CASE
        WHEN (SUM(1st_innings_wicket + 2nd_innings_wicket) / COUNT(Match_ID)) >= 14
             AND AVG((1st_innings_score / NULLIF(Overs_1st, 0) + 2nd_innings_score / NULLIF(Overs_2nd, 0)) / 2.0) <= 4.8
       THEN 'Lethal'
        
        WHEN (SUM(1st_innings_wicket + 2nd_innings_wicket)  / COUNT(Match_ID)) >= 12
             AND AVG((1st_innings_score / NULLIF(Overs_1st, 0) + 2nd_innings_score / NULLIF(Overs_2nd, 0)) / 2.0) <= 5.8
		THEN 'Average'
        
        ELSE 'Poor'
    END AS Bowling_Index
FROM 
    wcwc_2022
GROUP BY 
    Tournament_ID;
CREATE OR REPLACE VIEW ANALYSED AS
SELECT 
    t1.Tournament_ID,
    t1.Average_Run_Rate,
    t2.Bowling_Index,
    t3.no_of_teams_won_toss_and_match,
    t4.Matches_Won_by_Chasing,
    t4.Matches_Won_by_Defending
FROM cwc_analysis.average_run_rate_per_tournament AS t1
JOIN cwc_analysis.bowling_intensity AS t2 
    ON t1.Tournament_ID = t2.Tournament_ID
JOIN cwc_analysis.toss_role_in_winning AS t3 
    ON t1.Tournament_ID = t3.Tournament_ID
JOIN cwc_analysis.win_bias AS t4 
    ON t1.Tournament_ID = t4.Tournament_ID
GROUP BY 
    t1.Tournament_ID, 
    t2.Bowling_Index, 
    t3.no_of_teams_won_toss_and_match, 
    t4.Matches_Won_by_Chasing, 
    t4.Matches_Won_by_Defending;