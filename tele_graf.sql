CREATE OR REPLACE FORCE EDITIONABLE VIEW "SCOTT"."TELE_GRAF" ("END_TIME", "T_USERIO", "T_CONCURRENCY", "T_SYSTEMIO", "T_COMMIT", "T_NETWORK", "T_APPLICATION", "T_CONFIGURATION", "T_ADMINISTRATIVE", "P_USERIO", "P_CONCURRENCY", "P_SYSTEMIO", "P_COMMIT", "P_NETWORK", "P_APPLICATION", "P_CONFIGURATION", "P_ADMINISTRATIVE") AS 
  SELECT
      MAX(end_time) as end_time,
      SUM(DECODE(wait_class_id, 1740759767, ROUND(time_waited, 1), 0)) as T_UserIO,
      SUM(DECODE(wait_class_id, 3875070507, ROUND(time_waited, 1), 0)) as T_Concurrency,
      SUM(DECODE(wait_class_id, 4108307767, ROUND(time_waited, 1), 0)) as T_SystemIO,
      SUM(DECODE(wait_class_id, 3386400367, ROUND(time_waited, 1), 0)) as T_Commit,
      SUM(DECODE(wait_class_id, 2000153315, ROUND(time_waited, 1), 0)) as T_Network,
      SUM(DECODE(wait_class_id, 4217450380, ROUND(time_waited, 1), 0)) as T_Application,
      SUM(DECODE(wait_class_id, 3290255840, ROUND(time_waited, 1), 0)) as T_Configuration,
      SUM(DECODE(wait_class_id, 4166625743, ROUND(time_waited, 1), 0)) as T_Administrative,
      
      SUM(DECODE(wait_class_id, 1740759767, ROUND(dbtime_in_wait, 1), 0)) as P_UserIO,
SUM(DECODE(wait_class_id, 3875070507, ROUND(dbtime_in_wait, 1), 0)) as P_Concurrency,
SUM(DECODE(wait_class_id, 4108307767, ROUND(dbtime_in_wait, 1), 0)) as P_SystemIO,
SUM(DECODE(wait_class_id, 3386400367, ROUND(dbtime_in_wait, 1), 0)) as P_Commit,
SUM(DECODE(wait_class_id, 2000153315, ROUND(dbtime_in_wait, 1), 0)) as P_Network,
SUM(DECODE(wait_class_id, 4217450380, ROUND(dbtime_in_wait, 1), 0)) as P_Application,
SUM(DECODE(wait_class_id, 3290255840, ROUND(dbtime_in_wait, 1), 0)) as P_Configuration,
SUM(DECODE(wait_class_id, 4166625743, ROUND(dbtime_in_wait, 1), 0)) as P_Administrative
    FROM
      v$waitclassmetric
    WHERE
      wait_class_id != 2723168908
    GROUP BY 
      end_time;