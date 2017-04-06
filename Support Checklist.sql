/***************************************************************************************************************************************

THE SQL IN BIB_FIRSTLINE_SUPPORT_CHECKLIST_SCRIPTS IS USED TO MONITOR THE BIB SOLUTION. 

SQL RESULTS SHOULD BE PASTED INTO THE CORRESPONDING EXCEL WORKBOOK SHEET NUMBER IN BIB_FIRSTLINE_SUPPORT_CHECKLIST_V3.8.xlsx

DEVELOPER:        WORK PIECE:                                        LAST MODIFIED:
DEAN LAMBRECHTS - BIB_FIRSTLINE_SUPPORT_CHECKLIST_SCRIPTS_V3.8.sql - 11/07/2014

FOR ANY CHANGES OR QUESTIONS REGARDING THESE SCRIPTS - PLEASE E-MAIL: SUPPORT@PBT.CO.ZA

NOTE: 
THERE MAY BE ERRORS IN THESE SCRIPTS WHEN EXECUTED FOR THE 1ST TIME IN YOUR OPCO. IF THAT HAPPENS, PLEASE LOG WITH 2ND LINE SUPPORT.

***************************************************************************************************************************************/



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--1)
--PROCESS DATES:
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT BUSINESS_AREA, TO_CHAR(TO_DATE(PROCESS_DATE,'yyyymmdd'),'YYYYMMDD') PROCESS_DATE, CASE WHEN DAYS_BEHIND = 0 THEN 'UP TO DATE' ELSE DAYS_BEHIND||' '||'DAY/S BEHIND' END STATUS
FROM
(
SELECT TASK BUSINESS_AREA, MAX_KEY PROCESS_DATE, TRUNC(SYSDATE-1)-TO_DATE(MAX_KEY,'yyyy/mm/dd') DAYS_BEHIND
FROM DW_TASKS 
WHERE TASK LIKE 'STD_DEP%PROCE%'
AND TASK <> 'STD_DEP_EDW_PROCESS_MONTH'
ORDER BY CASE 
WHEN TASK = 'STD_DEP_EDW_PROCESS_DATE' THEN 1
END, 2 DESC
) AA
;

--PD_OVERVIEW:
--YOU FIRST NEED TO CREATE THE VIEW IN YOUR OPCO.
--SQL FOR THE VIEW CAN BE FOUND IN LOCATION:

SELECT *
FROM BIB_SUPP.V_PD_OVERVIEW
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--2)
--ARE THERE ANY FAILED RUNS?
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--2)
--Failed Runs aggregated
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
A.RUN_STATUS,A.TASK,A.ROWS_LOADED,
TO_CHAR(START_DATE,'YYYYMMDD HH24:MI:SS') START_DATE,
TO_CHAR(END_DATE,'YYYYMMDD HH24:MI:SS') END_DATE,
A.DW_BATCH_ID,A.DW_TASK_ID,DW_RUN_ID, ROWS_ERROR,DIY_PARAMETER, 
B.TASK_BUSINESS_AREA, TASK_TECHNICAL_AREA, TASK_TARGET_TYPE
FROM DW_RT_RUNS A
JOIN DW_TASKS B
ON A.DW_TASK_ID = B.DW_TASK_ID
WHERE
 RUN_STATUS  IN ('FAILED')
ORDER BY START_DATE DESC,B.TASK_BUSINESS_AREA
;
select task, 'Has ' || no_failed ||' Failed runs in rt runs ' Alert_text from (select  task, run_status,count(*) no_failed from BIB_META.dw_rt_runs where run_status = 'FAILED'  group by task,run_status
having count(*)>0
order by COUNT(*) desc);

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--3)
--INTERPRETATION: IF THERE ARE MANY RUNS FOR ONE TASK (MORE THAN 5) OR THEY ARE ON VERY OLD DATA (MORE THAN 2 DAYS PRIOR TO EDW_PROCESS_DATE) THEN THIS IS A RED-FLAG.
--IF THIS IS NOT EMPTY, THEN INSERT RESULTS INTO SHEET 3.
--(YOU CAN LIST THE DETAILS OF SPECIFIC TASKS USING RUNNINGRUNS.SQL - FOR YOUR OWN FURTHER INVESTIGATIONS.)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT *
from
(
SELECT 
DW_TASK_ID,IS_RUNNABLE,TASK,COUNT(*) QUEUE_SIZE,MIN(SRC_DTK),MAX(SRC_DTK),MIN(DW_RUN_ID),MIN(MY_DTK) , MAX(MY_DTK) ,MAX(DW_RUN_ID) FROM (
SELECT 
X.IS_RUNNABLE,
C.DW_DATE_KEY SRC_DTK,COALESCE(TO_CHAR(B.DW_DATE_KEY) ,A.DIY_PARAMETER,'_') MY_DTK,A.RUN_STATUS,X.TASK,ROWS_LOADED,
TRUNC((NVL(END_DATE,SYSDATE)-START_DATE)*24*60*60,2) MINS,START_DATE,END_DATE,A.DW_BATCH_ID,A.DW_TASK_ID,DW_RUN_ID, ROWS_ERROR,DIY_PARAMETER
FROM DW_RT_RUNS A JOIN DW_TASKS X ON A.DW_TASK_ID=X.DW_TASK_ID
LEFT OUTER JOIN DW_RT_BATCHES B ON A.DW_BATCH_ID=B.DW_BATCH_ID
LEFT OUTER JOIN DW_RT_BATCHES C ON B.DW_COPIED_BATCH_ID=C.DW_BATCH_ID
WHERE  RUN_STATUS  IN ('FAILED','RUNABLE','RUNNING','PENDING','WAITING')
)
GROUP BY DW_TASK_ID,IS_RUNNABLE,TASK
ORDER BY 4 DESC
)
WHERE QUEUE_SIZE > 5
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--4)
--ANY LONGRUNNING TASKS?
--IF THERE ARE ANY, INSERT RESULTS INTO SHEET 4.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS') CURR_DT,
A.RUN_STATUS,TASK, ROWS_LOADED,
TO_CHAR(START_DATE,'YYYYMMDD HH24:MI:SS') START_DATE,
TO_CHAR(END_DATE,'YYYYMMDD HH24:MI:SS') END_DATE,
A.DW_BATCH_ID,A.DW_TASK_ID,DW_RUN_ID, ROWS_ERROR,DIY_PARAMETER
FROM DW_RT_RUNS A 
WHERE 
 RUN_STATUS  IN ('RUNNING')
 AND START_DATE < SYSDATE-0.1
ORDER BY START_DATE DESC
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--5)
--ANY DISABLED JOBS? ANY BIB_CTL,BIB_META LONG RUNNING JOBS.
--IF ANY, ESCALATE IMMEDIATELY!
--INSERT RESULTS INTO SHEET 5. 
--DO NOT DROP ANY FW_PARTITION_MAINT% JOBS IF IT STILL HAS A SID!
--DO NOT DROP THE SAME LONG RUNNING JOB EVERYDAY, IF THE SAME JOB IS RUNNING LONG EVERYDAY, IT NEEDS TO BE ESCALATED!
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT      null SID,
            RUN_TIME,
            OWNER,
            JOB_NAME,
            B.TASK,
            A.DW_TASK_ID,
            STATE
FROM 
(
SELECT OWNER,
CASE WHEN STATE='RUNNING' THEN (CURRENT_TIMESTAMP-LAST_START_DATE) ELSE NULL END RUN_TIME,
            JOB_NAME,
            SUBSTR(JOB_NAME, INSTR(JOB_NAME,'#',1,1)+1, INSTR(JOB_NAME,'#',1,2)-1-INSTR(JOB_NAME,'#',1,1)) DW_TASK_ID,
            STATE
FROM SYS.DBA_SCHEDULER_JOBS A
WHERE OWNER IN ('BIB_CTL','BIB_META')
    AND STATE = 'DISABLED'
) A
LEFT OUTER JOIN BIB_META.DW_TASKS B
    ON A.DW_TASK_ID = TO_CHAR(B.DW_TASK_ID)
union all
SELECT 
            bb.session_id SID,
            a.RUN_TIME,
            a.OWNER,
            a.JOB_NAME,
            B.TASK,
            A.DW_TASK_ID,
            a.STATE
FROM 
(
SELECT OWNER,
CASE WHEN STATE='RUNNING' THEN (CURRENT_TIMESTAMP-LAST_START_DATE) ELSE NULL END RUN_TIME,
            JOB_NAME,
            SUBSTR(JOB_NAME, INSTR(JOB_NAME,'#',1,1)+1, INSTR(JOB_NAME,'#',1,2)-1-INSTR(JOB_NAME,'#',1,1)) DW_TASK_ID,
            STATE
FROM SYS.DBA_SCHEDULER_JOBS A
WHERE OWNER IN ('BIB_CTL','BIB_META')
    AND STATE = 'RUNNING'
    AND LAST_START_DATE < CURRENT_TIMESTAMP-0.1 --YOU CAN REMOVE THIS LINE IF YOU WANT TO SEE ALL RUNNING JOBS.
) A
LEFT OUTER JOIN BIB_META.DW_TASKS B
    ON A.DW_TASK_ID = TO_CHAR(B.DW_TASK_ID)
left outer join dba_scheduler_running_jobs bb
on bb.job_name = a.job_name
ORDER BY 6 DESC, 1 DESC
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--6)
--ARE THERE ANY BATCHES WITH AN AUDITFAILED STATUS? 
--ARE THERE ANY BATCHES WITH AN AUDITING STATUS? THIS MEANS THAT IT HAS BEEN AUDITING FOR 2HOURS OR LONGER. NOT GOOD!
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
T.TASK,
B.TABLE_NAME, 
MIN(DW_DATE_KEY),
MAX(DW_DATE_KEY),
LOAD_STATUS,
COUNT(*) CNT_AUDFAILED
FROM DW_RT_BATCHES B 
JOIN DW_TASKS T 
ON (T.DW_TASK_ID=B.DW_TASK_ID) 
WHERE B.SUPER_BATCH_IND<>'Y' 
AND LOAD_STATUS = 'AUDITFAILED'
GROUP BY T.TASK, B.TABLE_NAME, B.LOAD_STATUS
UNION ALL
SELECT 
T.TASK,
B.TABLE_NAME, 
MIN(DW_DATE_KEY),
MAX(DW_DATE_KEY),
LOAD_STATUS,
COUNT(*) CNT_AUDFAILED
FROM DW_RT_BATCHES B 
JOIN DW_TASKS T 
ON (T.DW_TASK_ID=B.DW_TASK_ID) 
WHERE B.SUPER_BATCH_IND<>'Y' 
AND LOAD_STATUS IN ('AUDITING','PULL_AUDIT')
AND TRUNC(AUDIT_START_DATE) > SYSDATE - 0.1
GROUP BY T.TASK, B.TABLE_NAME, B.LOAD_STATUS
ORDER BY 6 DESC
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--7)
--IS THE SUBSCRIBER SNAP 'WAITING' FOR MORE THAN 6 HOURS?
--INSERT RESULTS INTO SHEET 7.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
* FROM (
SELECT 
COALESCE(TO_CHAR(B.DW_DATE_KEY) ,A.DIY_PARAMETER,'_') MY_DTK,A.RUN_STATUS,TASK,ROWS_LOADED,
/*TRUNC((NVL(END_DATE,SYSDATE)-START_DATE)*24*60*60,2) MINS,*/START_DATE,END_DATE,CASE WHEN RUN_STATUS IN ('WAITING','RUNABLE') THEN ROUND((SYSDATE - START_DATE)*24*60,0) END MINS_WAITING,
CASE WHEN RUN_STATUS IN ('RUNABLE','WAITING') THEN ROUND((SYSDATE - START_DATE)*24*60/60,0) END HOURS_WAITING,A.DW_BATCH_ID,A.DW_TASK_ID,DW_RUN_ID, ROWS_ERROR,DIY_PARAMETER
--A.* 
FROM DW_RT_RUNS A 
LEFT OUTER JOIN DW_RT_BATCHES B ON A.DW_BATCH_ID=B.DW_BATCH_ID
LEFT OUTER JOIN DW_RT_BATCHES C ON B.DW_COPIED_BATCH_ID=C.DW_BATCH_ID
WHERE 
1=1 
AND (TASK LIKE '%SUBS_GSM_SNAPD' ESCAPE '\' 
 OR TASK IN ('STD_WAIT_SUBS_SNAPD','STD_C2C_FCT_SUBS_SNAPD'))
AND TASK NOT LIKE '%RULE%' 
ORDER BY CASE WHEN RUN_STATUS='RUNNING' THEN 1 WHEN RUN_STATUS IN ('FAILED','WAITING','PENDING') THEN 2 WHEN RUN_STATUS='RUNABLE' THEN 3 ELSE 4 END, START_DATE 
DESC
)
WHERE ROWNUM < 7
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--8)
--SHOWS BY AUDITED TABLE HOW UP TO DATE A TABLE IS.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM
(
SELECT
B.TABLE_NAME,
TASK,
B.DW_TASK_ID,
MAX(DW_DATE_KEY) MAX_DATE_KEY,
SUM(RECORD_COUNT) TOTAL_RWS_LOADED
FROM DW_RT_BATCHES B
LEFT OUTER JOIN DW_TASKS T
ON B.DW_TASK_ID = T.DW_TASK_ID
WHERE DW_DATE_KEY IS NOT NULL
AND B.TABLE_NAME IS NOT NULL
AND B.TABLE_NAME NOT LIKE '$%'
GROUP BY 
B.TABLE_NAME, 
TASK, 
B.DW_TASK_ID
ORDER BY 4
)
WHERE MAX_DATE_KEY < (SELECT MAX_KEY FROM DW_TASKS WHERE TASK = 'STD_DEP_EDW_PROCESS_DATE')
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--9)
--TASKS THAT HAVE NOT RUN IN THE LAST 3 DAYS.
--WHENEVER STD_TG% OR TG_% TASKS APPEAR IN THE LIST BELOW, ESCLALATE IMMEDIATELY!!!
--FOR ALL THE OTHER TASKS APPEARING BESIDES ABOVE MENTIONED, THE NECESSARY INVESTIGATION WILL HAVE TO BE APPLIED.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
TASK,
IS_RUNNABLE,
DW_TASK_ID,
RUN_STATUS,
LAST_RUN_DATE
FROM 
(
SELECT
R.TASK,
IS_RUNNABLE,
R.DW_TASK_ID,
RUN_STATUS,
MAX(TO_CHAR(END_DATE,'YYYYMMDD')) LAST_RUN_DATE
FROM DW_RT_RUNS R
LEFT OUTER JOIN DW_TASKS T
ON R.DW_TASK_ID = T.DW_TASK_ID
WHERE RUN_STATUS IN ('CLOSED','SUCCESS','FAILED')
AND IS_RUNNABLE = 'Yes'
AND R.TASK NOT LIKE '%WAIT%'
GROUP BY R.TASK, IS_RUNNABLE, R.DW_TASK_Id, RUN_STATUS
ORDER BY 1
)
WHERE LAST_RUN_DATE < TO_CHAR(SYSDATE-3,'YYYYMMDD') 
UNION ALL
SELECT 
TASK,
IS_RUNNABLE,
DW_TASK_ID,
RUN_STATUS,
LAST_RUN_DATE
FROM 
(
SELECT
R.TASK,
IS_RUNNABLE,
R.DW_TASK_ID,
MAX(TO_CHAR(END_DATE,'YYYYMMDD')) LAST_RUN_DATE,
RUN_STATUS
FROM DW_RT_RUNS R
LEFT OUTER JOIN DW_TASKS T
ON R.DW_TASK_ID = T.DW_TASK_ID
WHERE RUN_STATUS IN ('CLOSED','SUCCESS','FAILED')
AND IS_RUNNABLE = 'No'
AND R.TASK LIKE '%TG%'
GROUP BY R.TASK, IS_RUNNABLE, R.DW_TASK_ID, RUN_STATUS
ORDER BY 4
)
WHERE LAST_RUN_DATE < TO_CHAR(SYSDATE-3,'YYYYMMDD') 
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--10)
--CHECK WHETHER INTERGRATION HAS BEEN LOADED FOR THE EDW PROCESS DATE.
--INSERT RESULTS INTO SHEET 12. 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
DISTINCT NVL(B.DATE_KEY,MAX(A.DATE_KEY))DATE_KEY,
A.OBJECT_NAME,
B.PROCESSING_STATUS
FROM I_CONTROL@BIBSRC_LINK A,
 (SELECT 
  OBJECT_NAME, 
  DATE_KEY,
  PROCESSING_STATUS
  FROM I_CONTROL@BIBSRC_LINK
  WHERE DATE_KEY = (SELECT DISTINCT MAX_KEY FROM DW_TASKS WHERE TASK = 'STD_DEP_EDW_PROCESS_DATE')
 )B
WHERE A.OBJECT_NAME = B.OBJECT_NAME  (+)
--AND A.DATE_KEY=B.DATE_KEY
GROUP BY A.OBJECT_NAME,
B.PROCESSING_STATUS,
B.DATE_KEY
ORDER BY 1,2
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--11)
--ARE THERE ANY JOBS WITH JOB_STATUS = SCHEDULED, BUT NOT BEING RUN? 
--NB!!! THIS SHOULD RETURN EMPTY. IF ANY, TRY BELOW FIX, ELSE ESCALATE!
--FIX: DISABLE THE JOB IN THE SCHEDULER, SET THE JOB BACK TO SCHEDULED, AND IT SHOULD DISAPPEAR FROM THE CHECK.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
--,A.*
JOB_NAME 
FROM DW_SCHEDULED_JOBS A 
WHERE JOB_STATUS='SCHEDULED'
MINUS
SELECT 
--,B.*
JOB_NAME 
FROM DBA_SCHEDULER_JOBS B 
WHERE OWNER='BIB_META' 
  AND STATE IN ('SCHEDULED','RUNNING')
  ;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--12)
--SCHEDULER JOBS FAILING.
--NB!!! THIS SHOULD RETURN EMPTY. IF ANY, INVESTIGATE AND ESCALATE.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select
a.log_date,
a.owner,
a.job_name, 
a.status, 
substr(b.additional_info,1, 100) error_msg
from dba_scheduler_job_log  a
  join  sys.SCHEDULER$_JOB_RUN_DETAILS  b
  on a.log_id = b.log_id
where 1=1
    and trunc(a.LOG_DATE)=trunc(sysdate)
    and a.status <> 'SUCCEEDED' 
    and a.owner = 'BIB_META' 
order by a.LOG_DATE desc
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--13)
--BAD ROWS FOR FILE LOADERS IN LAST 7 DAYS.
--THIS MIGHT RETURN SOMETHING, IF IT DOES THE BAD_RWS_PERC, LOGERR_RWS_PERC SHOULD BE REALLY LOW.
--LOOK AT THE TOTAL ROWS LOADED VS BAD_ROWS/LOG_ERR_RWS. NO NEED TO RAISE ALARMS IF THERE IS 1 BAD_ROW /LOG_ERR_RWS OUT OF 10000. 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select 
  t.task,
  t.source_system,
  min_regdt,
  max_regdt,
  f.total_rws,
  f.rws_loaded,
  f.bad_rws,
  round(f.bad_rws/f.total_rws*100,0)||'%' bad_rws_perc,
  f.log_err_rws,
  round(f.log_err_rws/f.total_rws*100,0)||'%' logerr_rws_perc
from dw_tasks t,
(
    select /*+ NO_INDEX(dw_rt_files) */
      dw_task_id,
      count(*) files, 
      sum(row_count) total_rws, 
      sum(base_row_count) rws_loaded, 
      sum(bad_row_count) bad_rws, 
      sum(log_errors_row_count) log_err_rws,
      min(register_datetime) min_regdt, 
      max(register_datetime) max_regdt
    from dw_rt_files
    where dw_rt_files.register_datetime > sysdate -7
    group by 
      dw_task_id
) f
where t.dw_task_id = f.dw_task_id
  and t.task_type = 'FILE'
  and (bad_rws > 0 or log_err_rws > 0)
order by 
t.task
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--14)
--ARE THERE ANY BATCHES WAITING TO BE SUPER BATCHED DATED MANY DAYS AGO?
--THIS SHOULD RETURN EMPTY.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select 
task,
table_name,
min(dw_date_Key),
max(dw_date_Key),
min(CREATE_DATETIME),
max(CREATE_DATETIME),
count(*) cnt_batches
from 
(
select b.task,
              a.* 
from dw_rt_batches a 
join dw_tasks b 
    on (a.dw_task_id=b.dw_task_id)
where a.record_count > 0 
    and a.super_batch_ind <> 'Y' 
    and nvl(a.dw_super_batch_id, -1) = -1     
    and b.super_batch_ind = 'Y' 
    order by 1
)
where CREATE_DATETIME < sysdate-1
group by 
task,
table_name
order by 7 desc
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--15)
--SUBSCRIBER SNAP PROFILE CHECKING. 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select * 
FROM
(
select   
task, 
rows_loaded, 
a.dw_batch_id, 
trunc((nvl(end_date,sysdate)-start_date)*24*60,1) mins, 
(trunc(end_date)) - trunc(to_date(diy_parameter,'YYYYMMDD')) days_BEHIND, 
end_date, 
diy_parameter 
from dw_rt_runs a  
left outer join (select dw_task_id t_id,task_business_area from dw_tasks ) t on a.dw_task_id=t.t_id 
where  
1=1  
and (task like 'STD_C2E_FCT_SUBS_GSM_SNAPD' escape '\'  )  
or (task like 'STD_C2E_FCT_SUBSCRIBER_SNAPD' escape '\'  ) 
AND RUN_STATUS IN ('CLOSED')
ORDER BY START_DATE DESC
)
WHERE ROWNUM <=32
order by 7 desc;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--16)
--CHECKING WHETHER FILE LOADERS ARE UP TO DATE. 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select b.table_name target_table_name, b.dw_task_id, task, max_date_in_table, case when days_behind > 0 then days_behind ||' '||'DAY/S BEHIND' else 'UP TO DATE' end status
from
(
select  table_name, dw_task_id, max_date_in_table, (trunc(sysdate) - to_date(max_date_in_table,'YYYYMMDD')) days_behind
FROM (
select table_name, dw_task_id, max(to_char(dw_max_date_key)) max_date_in_table
from bib_meta.dw_rt_batches
WHERE TABLE_NAME LIKE 'STG_CDR.%'
group by table_name, dw_task_id
UNION ALL
select table_name, dw_task_id, max(to_char(load_start_date,'YYYYMMDD')) max_date_in_table
from bib_meta.dw_rt_batches 
where table_name like '%SGSN%' 
OR TABLE_NAME LIKE '%MSC%' 
group by table_name, dw_task_id
) a
) B
LEFT OUTER JOIN DW_TASKS T 
on t.dw_task_id = b.dw_task_id
WHERE MAX_DATE_IN_TABLE IS NOT NULL
order by 4
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--18)
--ARE THERE ERROR TABLES OUT OF TREND, OR ANY ERRORS REGARDS TO COLUMN WIDTHS?
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--The below will generate about +-20 statements. Execute them and paste results in sheet 17. 
--Not all of them WILL return, you might find that only about 5 statements will return results.

 SELECT 'SELECT '''||OWNER||'.'||TABLE_NAME||''' TABLE_NAME, ORA_ERR_MESG$, DATE_KEY,  COUNT(*) FROM '||OWNER||'.'||TABLE_NAME||' WHERE TO_CHAR(DATE_KEY) BETWEEN TO_CHAR(TRUNC(SYSDATE),''YYYYMMDD'')-7 AND TO_CHAR(TRUNC(SYSDATE),''YYYYMMDD'') GROUP BY ORA_ERR_MESG$, DATE_KEY ORDER BY DATE_KEY;'
              FROM ALL_TABLES
              WHERE TABLE_NAME LIKE 'ER_%'
                AND OWNER = 'BIB_CDR'
                ;

				

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--19)
--CRITICAL!
--CHECK FOR AUDITED BATCHES THAT ARE EMPTY. THIS MUST RETURN EMPTY BEFORE ADVANCING THE STD_DEP_EDW_PROCESS_DATE.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				
select rr.rows_loaded, rr.task run_task,b.task, a.record_count,a.load_status, a.*  
from dw_rt_batches a join dw_tasks b on a.dw_task_id=b.dw_task_id
join dw_rt_runs rr on rr.dw_batch_id=a.dw_batch_id
where b.task like 'TG_CDR%'
and rr.rows_loaded > 0
and a.dw_super_batch_id is null
and a.super_batch_ind <> 'Y'
and a.record_count = 0 
and a.load_status in ('AUDITED','LOADED','AUDITING') 
and a.create_datetime > sysdate -14
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--20)
--CRITICAL!
--THIS MUST RETURN EMPTY. IF NOT, ESCALATE IMMEDIATELY!
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select *
from
(
select * from (
select b.dw_task_id,task,count(distinct dw_batch_id) Provisioned_batches, sum( un_created) Un_created
from
(select a.*
from dw_tasks a 
left outer join dw_tasks b 
on a.pattern_task=b.task
left outer join dw_task_exec_steps c 
on coalesce(b.task,a.task)=c.task
left outer join dw_table_metadata d
on c.target_table_name like '%'||d.table_name 
where a.task like '%%%%'
and (
    (  a.parameter_type ='BATCH' and a.copy_batch_ind='Y') 
    or (a.parameter_type='LOAD' and a.task_type='FILE')
)
and a.is_runnable='Yes'
and a.pattern_task <> 'Pattern task'
and c.template_name like '%PARTSWAP%'
and d.partitioning_key='Batch') b
left outer join (select dw_task_id,dw_batch_id,case when record_count=-2 then 1 else 0 end un_created from dw_rt_batches where load_status='PROVISIONED') a
on a.dw_task_id=b.dw_task_id
group by b.dw_task_id,task
)
order by case when provisioned_batches=0 then 1 else 100 end, un_created desc, provisioned_batches
)
where (provisioned_batches < 20 or UN_CREATED > 0)
;	


				
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--21)
--ARE THERE ANY FILES NOT ARCHIVED IN LAST 30 DAYS?
--PLEASE TAKE NOTE - THE BIGGER DW_RT_FILES THE LONGER THE QUERY WILL RUN. AVG RUN TIME 3-4 MINUTES.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM
(
SELECT /*+parallel (8) FULL(B) FULL(A)*/ 
       B.TASK, 
       PROCESSING_STATUS, 
       TO_CHAR(TRUNC(REGISTER_DATETIME),'YYYYMMDD') REG_DATE, 
       COUNT(*) CNT
FROM DW_RT_FILES A
JOIN DW_TASKS B
    ON A.DW_TASK_ID = B.DW_TASK_ID
where b.parameter_type = 'LOAD'
  AND (
        PROCESSING_STATUS NOT IN ('ARCHIVED','DUP_MOVED') 
        AND REGISTER_DATETIME < SYSDATE-3
      )
GROUP BY 
        B.TASK, 
        PROCESSING_STATUS, 
        TO_CHAR(TRUNC(REGISTER_DATETIME),'YYYYMMDD')
ORDER BY 3
)
WHERE REG_DATE > SYSDATE-30
;


				
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--22)
--THIS SHOULD RETURN EMPTY.
--ARE THERE ANY UNUSABLE/INVALID INDEXES.
--FIX: USE THE DW_BIB_UTL PACKAGE TO REBUILD THEM.
--PLEASE NOTE: IF THE REBUILD RUNS FOR MORE THAN 30MINUTES - CANCEL AND LOG WITH 2ND LINE SUPPORT.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--INVALID INDEXED PARTITIONS:
select 
A.INDEX_OWNER,
A.INDEX_NAME,
B.TABLE_NAME,
--A.PARTITION_NAME,
--A.TABLESPACE_NAME,
A.STATUS,
COUNT(*) COUNTS,
'INVALID INDEXED PARTITION' TYPE
FROM DBA_IND_PARTITIONS A 
JOIN ALL_INDEXES B 
ON A.INDEX_OWNER=B.OWNER 
AND A.INDEX_NAME =B.INDEX_NAME
WHERE 1=1
AND A.INDEX_OWNER IN ('STG_GEN','BIB_CDR','BIB') 
AND A.STATUS = 'UNUSABLE'
GROUP BY
A.INDEX_OWNER,
A.INDEX_NAME,
'INVALID INDEXED PARTITION',
--A.PARTITION_NAME,
--A.TABLESPACE_NAME,
A.STATUS,
B.TABLE_NAME
UNION ALL
--INVALID INDEXED SUBPARTITIONS:i
select 
A.INDEX_OWNER,
A.INDEX_NAME,
B.TABLE_NAME,
--A.PARTITION_NAME,
--A.TABLESPACE_NAME,
A.STATUS,
COUNT(*) COUNTS,
'INVALID INDEXED SUBPARTITION' TYPE
FROM DBA_IND_SUBPARTITIONS A 
JOIN ALL_INDEXES B 
ON A.INDEX_OWNER=B.OWNER AND A.INDEX_NAME =B.INDEX_NAME
WHERE 1=1
AND A.INDEX_OWNER IN ('STG_GEN','BIB_CDR','BIB') 
AND A.STATUS = 'UNUSABLE'
GROUP BY 
A.INDEX_OWNER,
A.INDEX_NAME,
'INVALID INDEXED SUBPARTITION',
--A.PARTITION_NAME,
--A.TABLESPACE_NAME,
A.STATUS,
B.TABLE_NAME
UNION ALL
--INVALID INDEXES:
select 
owner, 
index_name, 
A.TABLE_NAME,
--NULL,
--TABLESPACE_NAME,
status,
COUNT(*) COUNTS,
status||' INDEX' TYPE
FROM ALL_INDEXES A
where OWNER IN ('STG_GEN','BIB_CDR','BIB') 
and status in ('INVALID','UNUSABLE')
GROUP BY
owner, 
index_name, 
A.TABLE_NAME,
status||' INDEX',
--NULL,
--TABLESPACE_NAME,
status
ORDER BY 5 DESC
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--23)
--TABLESPACE GROWTH AND DATAFILE SIZE CHECKING
--INSERT RESULTS INTO SHEET 13. 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM
(
SELECT B.TABLESPACE_NAME,
         BIGFILE,
         TBS_SIZE SIZEMB,
         A.FREE_SPACE FREEMB,
         ROUND(TBS_SIZE/1024,2) SIZEGB,
         ROUND(A.FREE_SPACE/1024,2) FREEGB,
         CASE WHEN ROUND(SUM(A.FREE_SPACE/B.TBS_SIZE)*100,2) <=10
                THEN CASE WHEN BIGFILE='NO' THEN 'ALERT!!! ADD A DATAFILE!!!'
                        ELSE 'ENOUGH SPACE AVAILABLE IN TS'
                                END
                                ELSE 'ENOUGH SPACE AVAILABLE IN TS'
                END MESSAGE,
                ROUND(SUM(A.FREE_SPACE/B.TBS_SIZE)*100,2) perc_free
FROM (
          SELECT TABLESPACE_NAME,
                   ROUND(SUM(BYTES)/1024/1024, 0) AS FREE_SPACE
          FROM SYS.DBA_FREE_SPACE
          GROUP BY TABLESPACE_NAME
       ) A,
       (
          SELECT TABLESPACE_NAME,
                   ROUND(SUM(BYTES)/1024/1024, 0) AS TBS_SIZE
          FROM SYS.DBA_DATA_FILES
          GROUP BY TABLESPACE_NAME
       ) B,
       (SELECT TABLESPACE_NAME,BIGFILE FROM DBA_TABLESPACES ) c
WHERE A.TABLESPACE_NAME(+)=B.TABLESPACE_NAME
AND  A.TABLESPACE_NAME=C.TABLESPACE_NAME
AND A.TABLESPACE_NAME NOT IN ('SYSTEM','SYSAUX') 
AND A.TABLESPACE_NAME NOT LIKE 'UNDO%'
and BIGFILE = 'NO'
GROUP BY B.TABLESPACE_NAME,
              TBS_SIZE,
              FREE_SPACE,BIGFILE
ORDER BY 7,1
)
WHERE MESSAGE = 'ALERT!!! ADD A DATAFILE!!!'
ORDER BY 8
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--24)
--CHECKING AVAILABLE DISK SPACE ON ORACLE DB.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT TOTAL_MB/1024 AS TOTAL_IN_GB, 
ROUND(TOTAL_MB/1024/1024,2) AS TOTAL_IN_TB, 
ROUND(FREE_MB/1024,0) AS AVAILABLE_GB, 
--ROUND(FREE_MB/1024/1024,3) AS AVAILABLE_TB,
ROUND((FREE_MB/1024)/(TOTAL_MB/1024)*100,0)||'%' PERC_AVAILABLE, 
100 - ROUND((FREE_MB/1024)/(TOTAL_MB/1024)*100,0) PERC_used,NAME 
FROM V$ASM_DISKGROUP
;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--25
--ONLY IF OPCO USES INFORMATICA FOR S2S_LOADS.
--ARE THERE ANY FAILED INFORMATIA WORKFLOWS?
--INSERT RESULTS INTO SHEET 16.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT *
FROM
(
SELECT 'ITC' SOURCE_SYSTEM_CD, 
                    BATCH_ID, 
                    START_TIME BATCH_START, 
                    PROCESS_STATUS, 
                    MIN_DATE_TS, 
                    MAX_DATE_TS, 
                    CASE 
                            WHEN PROCESS_STATUS = 'S2S_F' AND TRUNC(MAX_DATE_TS) <> TRUNC(SYSDATE-1) THEN 'WORKFLOW FAILED ON '||TO_CHAR(TRUNC(START_TIME),'YYYYMMDD')||' AND NOT UP TO DATE!'
                            WHEN PROCESS_STATUS = 'S2S_F' AND TRUNC(MAX_DATE_TS) = TRUNC(SYSDATE-1) THEN 'WORKFLOW FAILED BUT UP TO DATE!'
                            WHEN TRUNC(MAX_DATE_TS) >= TRUNC(SYSDATE) THEN 'UP TO DATE' 
                            WHEN TRUNC(MAX_DATE_TS) = TRUNC(SYSDATE-1) THEN 'UP TO DATE'
                            WHEN TRUNC(MAX_DATE_TS) <> TRUNC(SYSDATE-1) THEN 'WORKFLOW NOT UP TO DATE!'
                            
                    END SOURCE_STATUS
FROM bib_aux.batch_ctl WHERE batch_id = (SELECT MAX(batch_id) FROM stg_gen.ablt_pm_rated_cdrs)
UNION ALL
SELECT 
bc.SOURCE_SYSTEM_CD, bc.BATCH_ID, bc.START_TIME BATCH_START, bc.PROCESS_STATUS, bc.MIN_DATE_TS, bc.MAX_DATE_TS,
                   CASE 
                            WHEN PROCESS_STATUS = 'S2S_F' AND TRUNC(MAX_DATE_TS) <> TRUNC(SYSDATE-1) THEN 'WORKFLOW FAILED ON '||TO_CHAR(TRUNC(bc.START_TIME),'YYYYMMDD')||' AND NOT UP TO DATE!'
                            WHEN PROCESS_STATUS = 'S2S_F' THEN 'WORKFLOW FAILED ON '||TO_CHAR(TRUNC(bc.START_TIME),'YYYYMMDD')||'!'
                            WHEN TRUNC(MAX_DATE_TS) >= TRUNC(SYSDATE) THEN 'UP TO DATE' 
                            WHEN TRUNC(MAX_DATE_TS) = TRUNC(SYSDATE-1) THEN 'UP TO DATE'
                            WHEN TRUNC(MAX_DATE_TS) <> TRUNC(SYSDATE-1) THEN 'WORKFLOW NOT UP TO DATE!'
                            
                    END SOURCE_STATUS
FROM BIB_AUX.BATCH_CTL bc
WHERE bc.BATCH_ID IN 
(
    SELECT BATCH_ID FROM 
(
        SELECT SOURCE_SYSTEM_CD, MAX(BATCH_ID) BATCH_ID
        FROM BIB_AUX.BATCH_CTL 
        WHERE process_status NOT IN ('S2S_P','S2S_PR','S2M_P','S2M_PR')
        AND batch_id != NVL((SELECT MAX(batch_id) FROM stg_gen.ablt_pm_rated_cdrs),0)
        GROUP BY SOURCE_SYSTEM_CD
)
)
)
ORDER BY
CASE
WHEN SOURCE_STATUS LIKE 'WORKFLOW FAILED ON%' THEN 1
WHEN SOURCE_STATUS = 'WORKFLOW NOT UP TO DATE' THEN 2
WHEN PROCESS_STATUS <> 'S2S_C' THEN 3

END
;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--26)
--ARE THERE PARAMETERS IN JOB_CTL NOT UP TO DATE OR INCORRECT?
--CRITICAL CHECK. THE STATUS YOU WOULD LIKE TO SEE SHOULD BE = 'WORKFLOW UP TO DATE AND PARAMETERS ARE CORRECT!'
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select
record_set,
min_date_ts,
max_date_ts,
case
when to_char(min_date_ts,'YYYYMMDD') <> to_char(trunc(sysdate),'YYYYMMDD') 
    then 'WORKFLOW NOT UP TO DATE OR INCORRECT PARAMETERS! MIN_DATE_TS SHOULD BE = '||to_char(trunc(sysdate),'YYYYMMDD')||' and MAX_DATE_TS SHOULD BE = '||to_char(trunc(sysdate)+1,'YYYYMMDD')||'. WORKFLOW SHOULD BE RUN UNTIL THIS CHECK STATUS SAYS UP TO DATE, OR PARAMETERS NEEDS TO BE RECTIFIED.'
when to_char(max_date_ts,'YYYYMMDD') <> to_char(trunc(sysdate)+1,'YYYYMMDD')
    then 'WORKFLOW NOT UP TO DATE OR INCORRECT PARAMETERS! MIN_DATE_TS SHOULD BE = '||to_char(trunc(sysdate),'YYYYMMDD')||' and MAX_DATE_TS SHOULD BE = '||to_char(trunc(sysdate)+1,'YYYYMMDD')||'. WORKFLOW SHOULD BE RUN UNTIL THIS CHECK STATUS SAYS UP TO DATE, OR PARAMETERS NEEDS TO BE RECTIFIED.'
else 'WORKFLOW UP TO DATE AND PARAMETERS ARE CORRECT!'
end status    
from bib_aux.job_ctl
;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--27)
--ARE THERE FILES BEING REGISTERED TO THE FRAMEWORK FOR TODAY?
--INSERT RESULTS INTO SHEET 17.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT  A.TASK, A.DATE_KEY, B.COUNT_FILES, B.SUM_ROW_COUNT
FROM
(
SELECT TO_CHAR(DATE_KEY) DATE_KEY, TASK
FROM bib_meta.DW_TASKS,
BIB.DIM_DATE
WHERE TO_CHAR(DATE_KEY) BETWEEN (SELECT to_char(to_date(TRUNC(SYSDATE),'YYYYMMDD HH24:MI:SS')-28,'YYYYMMDD') FROM DUAL) AND (SELECT to_char(TRUNC(SYSDATE),'yyyymmdd') FROM DUAL)
AND TASK LIKE 'TF_S2S_%' --Can exclude or filter on specific tasks.
) A
LEFT OUTER JOIN
(
SELECT TASK, DATE_KEY, COUNT(*) COUNT_FILES,  SUM(ROW_COUNT) SUM_ROW_COUNT
FROM (
SELECT  /*+PARALLEL (F,4) */ 
TASK,
TO_CHAR(SHORT_FILENAME) SHORT_FILENAME, ROW_COUNT,
TO_CHAR(SUBSTR(SHORT_FILENAME,  INSTR(SHORT_FILENAME, (SELECT ''||SUBSTR(TRUNC(SYSDATE),1,4)||'' FROM DUAL)),8)) DATE_KEY 
FROM bib_meta.DW_RT_FILES F
JOIN bib_meta.DW_TASKS T ON (F.DW_TASK_ID=T.DW_TASK_ID)
WHERE FILENAME LIKE (SELECT '%'||SUBSTR(TRUNC(SYSDATE),1,4)||'%' FROM DUAL)
AND PROCESSING_STATUS IN ('LOADED','ARCHFAILED','ARCHIVED','ARCHIVING')
)
GROUP BY TASK, DATE_KEY
ORDER BY TASK, DATE_KEY
) B
ON A.TASK=B.TASK AND A.DATE_KEY=B.DATE_KEY

union all --This union is to get the results from the files which are being loaded via informatica. Eg. TAPIN, TAPOUT, HR...

SELECT aaa.source_system, Aaa.DATE_KEY, bbB.COUNT_FILES, bbb.SUM_ROW_COUNT
FROM
(
SELECT TO_CHAR(DATE_KEY) DATE_KEY, SOURCE_SYSTEM_CD||' - INFA LOAD' source_system
from BIB.DIM_DATE,
(select distinct SOURCE_SYSTEM_CD FROM BIB_AUX.BATCH_CTL_PROCESSEDFILES) 
WHERE TO_CHAR(DATE_KEY) BETWEEN (SELECT to_char(to_date(TRUNC(SYSDATE),'YYYYMMDD HH24:MI:SS')-28,'YYYYMMDD') FROM DUAL) AND (SELECT to_char(TRUNC(SYSDATE),'yyyymmdd') FROM DUAL)
) AAA
LEFT OUTER JOIN
(select source_system,
                date_key,
                COUNT(*) COUNT_FILES,
                sum(RECORD_COUNT) SUM_ROW_COUNT
                from
                (

    SELECT /*+PARALLEL (B,4) */
    SOURCE_SYSTEM_CD||' - INFA LOAD' source_system
                ,TO_CHAR(SUBSTR(FILENAME,  INSTR(FILENAME, (SELECT ''||SUBSTR(TRUNC(SYSDATE),1,4)||'' FROM DUAL)),8)) DATE_KEY 
                ,FILENAME
                ,RECORD_COUNT
    FROM BIB_AUX.BATCH_CTL_PROCESSEDFILES B
	WHERE FILENAME LIKE (SELECT '%'||SUBSTR(TRUNC(SYSDATE),1,4)||'%' FROM DUAL)
)
   GROUP BY source_system
                   ,date_key
)bbb
ON AAA.DATE_KEY=BBB.DATE_KEY AND AAA.SOURCE_SYSTEM=BBB.SOURCE_SYSTEM
ORDER BY 1,2
;

/***************************************************************************************************************************************/