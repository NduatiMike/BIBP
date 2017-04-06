-----------------------MONITORING EDW --------------------------------------------

select 
case when task in ('CS5_TE_S2C_FCT_CDR_PREPAID_SNAPD_SDP_DUMP_MA') then '1.1.A'
when task in ('STD_TE_I2S_POSTPAID_SUBSCRIBER_BASE_PULL') then '1.1.B'
when task in ('STD_C2E_FCT_PREPAID_SNAPD') then '1.1.B'
when task in ('STD_C2C_FCT_MSISDN_PREPAID_SUMD') then '3.1.A'
when task in ('STD_C2C_FCT_PREPAID_FIRST') then '3.2.A'
when task in ('STD_C2C_FCT_PREPAID_LAST') then '3.2.A'
when task in ('STD_C2C_FCT_PREPAID_FIRST_ACTIV') then '1.1.A'
when task in ('STD_TE_S2S_INT_SUBSCRIBER') then '1.1.A'
when task in ('STD_TE_S2S_INT_SUBSCRIBER_MISC') then '1.1.A'
when task in ('STD_DIM_SUBSCRIBER') then '1.2.A'
when task in ('STD_BRT_SUBSCRIBER') then '1.3.A'
when task in ('STD_TE_S2C_FCT_CDR_INTERCONNECT') then '4.1.A'
when task in ('STD_C2C_FCT_MSISDN_USAGE_INTERCONNECT_FIRST') then '5.1.A'
when task in ('STD_C2C_FCT_MSISDN_USAGE_INTERCONNECT_LAST') then '5.1.A'
when task in ('STD_C2C_FCT_PVT_CDR_PREPAID_RATED_DED') then '4.3.A'
when task in ('STD_C2C_FCT_CDR_RATED_COMB') then '4.3.A:'
when task in ('STD_C2C_FCT_CDR_TRANS_COMB') then '4.3.A'
when task in ('STD_C2C_FCT_MSISDN_BASE_STATION_SUMD') then '4.4.A'
when task in ('STD_C2C_FCT_MSISDN_GEOGRAPHY_SUMD') then '4.5.A'
when task in ('STD_C2C_FCT_MSISDN_RATED_SUMD') then '4.4.A'
when task in ('STD_C2C_FCT_CDR_RATED_SUMD') then '4.4.A'
when task in ('STD_C2C_FCT_MSISDN_USAGE_PREPAID_FIRST') then '4.5.A'
when task in ('STD_C2C_FCT_MSISDN_USAGE_PREPAID_LAST') then '4.5.A'
when task in ('STD_C2C_FCT_MSISDN_USAGE_TAP_IN_FIRST') then ''
when task in ('STD_C2C_FCT_MSISDN_USAGE_TAP_IN_LAST') then ''
when task in ('STD_C2C_FCT_SUBS_EVENT_SUMD') then '3.3.A'
when task in ('STD_C2C_FCT_SUBS_EVENT_FIRST') then '3.3.A'
when task in ('STD_C2C_FCT_SUBS_EVENT_LAST') then '3.3.A'
when task in ('STD_C2C_FCT_SUBS_RGE_MM_LAST') then '3.3.A'
when task in ('STD_C2C_FCT_SUBS_RGE_LAST') then '2.1.G'
when task in ('STD_C2C_FCT_SUBS_RGE_MISC_LAST') then '3.3.A'
when task in ('STD_C2C_FCT_SUBS_SNAPD') then '6.1.A'
when task in ('DAY DURATION') then '6.1.A'
when task in ('STD_C2C_FCT_SUBS_RGE_CALC') then '6.2.A'
when task in ('STD_C2E_FCT_SUBSCRIBER_SNAPD') then '6.2.A'
when task in ('STD_C2E_FCT_SUBS_FULL_SUMD') then '6.2.A'
when task in ('STD_E2E_FRU_SUBSCRIBER_SNAPD') then '6.2.A'
when task in ('STD_E2E_FRU_SUBSCRIBER_HL_SNAPD') then '6.2.A'
when task in ('STD_E2E_FRU_SUBSCRIBER_SNAPD_HL') then '6.2.A'
when task in ('STD_C2E_FCT_SUBSCRIBER_SNAPM') then '6.2.A'
when task in ('STD_C2C_FCT_CDR_INTERCONNECT_SUMD') then '6.2.B'
when task in ('STD_C2E_FCT_INTERCONNECT_EXPENSE') then '6.2.B'
when task in ('STD_C2E_FCT_INTERCONNECT_REVENUE') then '6.2.B'
when task in ('STD_C2E_FCT_USAGE_DATA_OUT') then '6.2.C'
when task in ('STD_C2E_FCT_USAGE_POSTPAID_IN') then '6.2.C'
when task in ('STD_C2E_FCT_USAGE_POSTPAID_OUT') then '6.2.C'
when task in ('STD_C2E_FCT_USAGE_PREPAID_IN') then '6.2.C'
when task in ('STD_C2E_FCT_USAGE_PREPAID_OUT') then '6.2.C'
end section, 
src_dtk,my_dtk,run_status,task,duration,
start_date,end_date, rows_loaded,dw_run_id,dw_batch_id,dw_copied_batch_id,dw_task_id,rows_error,diy_parameter,
direct_exec_sql,task_business_area, range_cnt, avg_dur, max_dur, min_rps, avg_rps, max_rps
from (
select
src_dtk,my_dtk,run_status,task,duration,rows_loaded,dw_run_id,dw_batch_id,dw_copied_batch_id,start_date,end_date,dw_task_id,rows_error,diy_parameter,
direct_exec_sql,task_business_area,
range_cnt, avg_dur, max_dur, min_rps, avg_rps, max_rps
from (
select
c.dw_date_key src_dtk,coalesce(to_char(b.dw_date_key) ,a.diy_parameter,'_') my_dtk, a.run_status,task,
numtodsinterval(end_date-start_date,'day') duration,
rows_loaded,a.dw_run_id,a.dw_batch_id,c.dw_copied_batch_id,
to_char(start_date,'yyyymmdd hh24:mi:ss') start_date, 
to_char(end_date,'yyyymmdd hh24:mi:ss')end_date,
a.dw_task_id, rows_error,diy_parameter,direct_exec_sql
,t.task_business_area,
CONCURNCY,  priority,  node
,d.range_cnt, d.avg_duration avg_dur, d.max_duration max_dur, d.min_rows_persec min_rps, d.avg_rows_persec avg_rps, d.max_rows_persec max_rps
from bib_meta.dw_rt_runs a
left outer join (select  MAX_FILE_LOAD_CONCURRENCY CONCURNCY, flex1 priority, flex2 node, dw_task_id t_id,task_business_area from bib_meta.dw_tasks ) t on a.dw_task_id=t.t_id
left outer join bib_meta.dw_rt_batches b on a.dw_batch_id=b.dw_batch_id
left outer join BIB_META.dw_rt_batches c on b.dw_copied_batch_id=c.dw_batch_id
left outer join (SELECT dw_run_id, count(1) range_cnt, min(ROUND ((24*60*60*(A.end_date-A.start_date)) / 60, 2)) min_DURATION, ROUND(avg( ( (24*60*60*(A.end_date - A.start_date)) / 60)),2) avg_DURATION,
max(ROUND ((24*60*60*(A.end_date - A.start_date))/60, 2)) max_DURATION, min(ROUND (rows_loaded/ NULLIF (24*60*60*(A.end_date - A.start_date), 0),0))  min_rows_persec,
ROUND(avg( (rows_loaded/NULLIF (24*60*60*(A.end_date - A.start_date), 0))) ,0)avg_rows_persec,max(ROUND (rows_loaded/ NULLIF (24*60*60*(A.end_date - A.start_date), 0),0)) max_rows_persec
  FROM DW_RT_RANGE_RUNS A GROUP BY DW_RUN_ID) d on a.dw_run_id = d.dw_run_id
where 1=1  --13,917,739 
and run_status not in('CANCELLED')
--and (rows_loaded>0 and run_status in ('CLOSED','SUCCESS'))
and task in ('STD_TE_S2S_INT_SUBSCRIBER','STD_BRT_SUBSCRIBER','STD_DIM_SUBSCRIBER', 'STD_C2C_FCT_CDR_PREPAID_SNAPD',
'STD_C2C_FCT_PREPAID_FIRST','STD_C2C_FCT_PREPAID_LAST',
'STD_C2C_FCT_CDR_RATED_COMB', 'STD_C2C_FCT_SUBS_SNAPD','STD_C2E_FCT_SUBSCRIBER_SNAPM',
'STD_WAIT_SUBSCRIBER_SNAPM','STD_TD_SUBSCRIBER','STD_C2C_FCT_CDR_TRANS_COMB',
'STD_C2C_FCT_MSISDN_PREPAID_SUMD','STD_C2C_FCT_SUBS_RGE_CALC','STD_C2E_FCT_SUBSCRIBER_SNAPD',
'STD_C2E_FCT_SUBS_FULL_SUMD','STD_E2E_FRU_SUBSCRIBER_SNAPD','STD_E2E_FRU_SUBSCRIBER_HL_SNAPD','STD_E2E_FRU_SUBSCRIBER_SNAPD_HL',
'STD_WAIT_SUBS_SNAPD',
'CS5_TE_S2C_FCT_CDR_PREPAID_SNAPD_SDP_DUMP_MA','STD_TE_S2S_INT_SUBSCRIBER_MISC','STD_TE_S2C_FCT_CDR_INTERCONNECT_DIY_PAR','STD_C2C_FCT_MSISDN_USAGE_INTERCONNECT_FIRST',
'STD_C2C_FCT_PVT_CDR_PREPAID_RATED_DED','STD_C2C_FCT_MSISDN_BASE_STATION_SUMD','STD_C2C_FCT_MSISDN_GEOGRAPHY_SUMD','STD_C2C_FCT_MSISDN_RATED_SUMD','STD_C2C_FCT_CDR_RATED_SUMD',
'STD_C2C_FCT_MSISDN_USAGE_PREPAID_FIRST','STD_C2C_FCT_MSISDN_USAGE_PREPAID_LAST','STD_C2C_FCT_MSISDN_USAGE_TAP_IN_FIRST','STD_C2C_FCT_MSISDN_USAGE_TAP_IN_LAST',
'STD_C2C_FCT_SUBS_EVENT_SUMD','STD_C2C_FCT_SUBS_EVENT_FIRST','STD_C2C_FCT_SUBS_EVENT_LAST','STD_C2C_FCT_SUBS_RGE_LAST','STD_C2C_FCT_SUBS_RGE_MISC_LAST','STD_C2C_FCT_PREPAID_FIRST_ACTIV',
'STD_TE_I2S_POSTPAID_SUBSCRIBER_BASE_PULL','STD_C2E_FCT_PREPAID_SNAPD',
'STD_C2C_FCT_SUBS_RGE_MM_LAST','STD_E2E_FRU_SUBSCRIBER_SNAPD',
'STD_C2E_FCT_INTERCONNECT_EXPENSE','STD_C2E_FCT_INTERCONNECT_REVENUE', 'STD_C2C_FCT_CDR_INTERCONNECT_SUMD',
'STD_C2E_FCT_USAGE_DATA_OUT','STD_C2E_FCT_USAGE_POSTPAID_IN','STD_C2E_FCT_USAGE_POSTPAID_OUT',
'STD_C2E_FCT_USAGE_PREPAID_IN','STD_C2E_FCT_USAGE_PREPAID_OUT'
)
order by case when run_status='RUNNING' then 1 when run_status in ('FAILED','WAITING','PENDING') then 2 when run_status='RUNABLE' then 3 else 4 end,
2 desc ,
start_date desc) main
where main.my_dtk=(SELECT to_char(MAX_KEY) FROM DW_TASKS WHERE TASK = 'STD_DEP_EDW_PROCESS_DATE')
--to_char(TO_DATE('20161209','YYYYMMDD'),'yyyymmdd') --Insert the STD_DEP_EDW_PROCESS_DATE you would like to have a look at.
union all
select
null src_dtk,
(SELECT to_char(MAX_KEY) FROM DW_TASKS WHERE TASK = 'STD_DEP_EDW_PROCESS_DATE') my_dtk,
case when end_run.end_date is null then 'RUNNING' else 'CLOSED' end run_status,
start_run.task,
numtodsinterval(
case when end_run.end_date is null then sysdate else end_run.end_date end 
- start_run.start_date,'day') duration,null rows_loaded,null dw_run_id,null dw_batch_id,null dw_copied_batch_id,
to_char(start_run.start_date,'yyyymmdd hh24:mi:ss') start_date,
to_char(end_run.end_date,'yyyymmdd hh24:mi:ss') end_date,
null dw_task_id,null rows_error,null diy_parameter,
null direct_exec_sql,null task_business_area,
null range_cnt, null avg_dur, null max_dur, null min_rps, null avg_rps, null max_rps
from 
(
select 'DAY DURATION' task, start_date from (
select start_date, 
rank() over (order by start_date, rownum) rnk
from bib_meta.dw_rt_runs a
left outer join (select dw_task_id t_id,task_business_area from bib_meta.dw_tasks ) t on a.dw_task_id=t.t_id
left outer join bib_meta.dw_rt_batches b on a.dw_batch_id=b.dw_batch_id
left outer join BIB_META.dw_rt_batches c on b.dw_copied_batch_id=c.dw_batch_id
where 1=1
and run_status not in('CANCELLED')
and task in ('STD_C2C_FCT_MSISDN_PREPAID_SUMD','STD_C2C_FCT_PREPAID_FIRST','STD_C2C_FCT_PREPAID_LAST','STD_C2C_FCT_CDR_RATED_COMB' )
and coalesce(to_char(b.dw_date_key) ,a.diy_parameter,'_')=(SELECT to_char(MAX_KEY) FROM DW_TASKS WHERE TASK = 'STD_DEP_EDW_PROCESS_DATE')) where rnk=1) start_run,
( select end_date from bib_meta.dw_rt_runs a
left outer join (select dw_task_id t_id,task_business_area from bib_meta.dw_tasks ) t on a.dw_task_id=t.t_id
left outer join bib_meta.dw_rt_batches b on a.dw_batch_id=b.dw_batch_id
left outer join BIB_META.dw_rt_batches c on b.dw_copied_batch_id=c.dw_batch_id
where 1=1
and run_status not in('CANCELLED')
and task in ('STD_C2C_FCT_SUBS_SNAPD')  --4,019,851
and coalesce(to_char(b.dw_date_key) ,a.diy_parameter,'_')=(SELECT to_char(MAX_KEY) FROM DW_TASKS WHERE TASK = 'STD_DEP_EDW_PROCESS_DATE')
) end_run) order by 
case when task in ('CS5_TE_S2C_FCT_CDR_PREPAID_SNAPD_SDP_DUMP_MA') then 1
when task in ('STD_TE_I2S_POSTPAID_SUBSCRIBER_BASE_PULL') then 1
when task in ('STD_C2E_FCT_PREPAID_SNAPD') then 9.1
when task in ('STD_C2C_FCT_MSISDN_PREPAID_SUMD') then 2
when task in ('STD_C2C_FCT_PREPAID_FIRST') then 3
when task in ('STD_C2C_FCT_PREPAID_LAST') then 4
when task in ('STD_C2C_FCT_PREPAID_FIRST_ACTIV') then 5
when task in ('STD_TE_S2S_INT_SUBSCRIBER') then 6
when task in ('STD_TE_S2S_INT_SUBSCRIBER_MISC') then 7
when task in ('STD_DIM_SUBSCRIBER') then 8
when task in ('STD_BRT_SUBSCRIBER') then 9
when task in ('STD_TE_S2C_FCT_CDR_INTERCONNECT_DIY_PAR') then 10
when task in ('STD_C2C_FCT_MSISDN_USAGE_INTERCONNECT_FIRST') then 11
when task in ('STD_C2C_FCT_PVT_CDR_PREPAID_RATED_DED') then 12
when task in ('STD_C2C_FCT_CDR_RATED_COMB') then 13
when task in ('STD_C2C_FCT_MSISDN_BASE_STATION_SUMD') then 14
when task in ('STD_C2C_FCT_MSISDN_GEOGRAPHY_SUMD') then 15
when task in ('STD_C2C_FCT_MSISDN_RATED_SUMD') then 16
when task in ('STD_C2C_FCT_CDR_RATED_SUMD') then 17
when task in ('STD_C2C_FCT_MSISDN_USAGE_PREPAID_FIRST') then 18
when task in ('STD_C2C_FCT_MSISDN_USAGE_PREPAID_LAST') then 19
when task in ('STD_C2C_FCT_MSISDN_USAGE_TAP_IN_FIRST') then 20
when task in ('STD_C2C_FCT_MSISDN_USAGE_TAP_IN_LAST') then 21
when task in ('STD_C2C_FCT_SUBS_EVENT_SUMD') then 22
when task in ('STD_C2C_FCT_SUBS_EVENT_FIRST') then 23
when task in ('STD_C2C_FCT_SUBS_EVENT_LAST') then 24
when task in ('STD_C2C_FCT_SUBS_RGE_LAST') then 25
when task in ('STD_C2C_FCT_SUBS_RGE_MISC_LAST','STD_C2C_FCT_SUBS_RGE_MM_LAST') then 26
when task in ('STD_C2C_FCT_SUBS_SNAPD') then 28
when task in ('DAY DURATION') then 0
when task in ('STD_C2C_FCT_SUBS_RGE_CALC') then 30
when task in ('STD_C2E_FCT_SUBSCRIBER_SNAPD') then 31 
when task in ('STD_C2E_FCT_SUBS_FULL_SUMD') then 32
when task in ('STD_E2E_FRU_SUBSCRIBER_SNAPD') then 33
when task in ('STD_E2E_FRU_SUBSCRIBER_HL_SNAPD') then 34
when task in ('STD_E2E_FRU_SUBSCRIBER_SNAPD_HL') then 35
when task in ('STD_C2C_FCT_CDR_INTERCONNECT_SUMD') then 36
when task in ('STD_C2E_FCT_INTERCONNECT_EXPENSE') then 37
when task in ('STD_C2E_FCT_INTERCONNECT_REVENUE') then 38
when task in ('STD_C2E_FCT_USAGE_DATA_OUT') then 39
when task in ('STD_C2E_FCT_USAGE_POSTPAID_IN') then 40
when task in ('STD_C2E_FCT_USAGE_POSTPAID_OUT') then 41
when task in ('STD_C2E_FCT_USAGE_PREPAID_IN') then 42
when task in ('STD_C2E_FCT_USAGE_PREPAID_OUT') then 43
when task in ('STD_C2E_FCT_SUBSCRIBER_SNAPM') then 44
end;



-------------------------------------------------------------------------------------------------
---------------------------PRE CHECKS --------------------------------------------------------
--check if we received postpaid data AND TREND 

select * from  i_control@IA_USER.MTN.CO.ZA   where OBJECT_NAME     ='I_POSTPAID_SUBSCRIBER_BASE' order by date_key desc;

-------------------------------------------------------------------------------------------------
---------------------------OVERALL FILE TRENDS  --------------------------------------------------------
SELECT  
   DATE_KEY 
, SUM(FILE_COUNT)FILE_COUNT 
, SUM(CDR_COUNT)CDR_COUNT 

FROM ( 
SELECT TASK 
, MAX_DW_DATE_KEY DATE_KEY 
, COUNT(*) FILE_COUNT 
, SUM(ROW_COUNT) CDR_COUNT 
--MIN(ROW_COUNT) MIN_COUNT, AVG(ROW_COUNT) AVG_COUNT, MAX(ROW_COUNT) MAX_COUNT
FROM ( 
      SELECT  /*+PARALLEL (A,20) */ TASK, MAX_DW_DATE_KEY, ROW_COUNT 
      FROM BIB_META.DW_RT_FILES A JOIN BIB_META.DW_TASKS B ON (A.DW_TASK_ID=B.DW_TASK_ID) 
      Where A.Processing_Status In ('LOADED','ARCHFAILED','ARCHIVED','ARCHIVING','ARCHIVEFAILED')
--      AND TASK like 'TF_S2S_IBF_XDR_ZA%' 
--        and task like 'TF_S2S_XDR_SV_ZA'
        AND TASK LIKE 'STD_TF_S2S_HRIS_PERSONAL%'

  AND MAX_DW_DATE_KEY BETWEEN to_char(sysdate-60,'yyyymmdd') and to_char(sysdate,'yyyymmdd')
)  
GROUP BY TASK, MAX_DW_DATE_KEY 
ORDER BY TASK, MAX_DW_DATE_KEY 
)  
GROUP BY DATE_KEY
ORDER BY 1 desc;





-------------------------------------------------------------------------------------------------
---------------------------OVERALL FILE TRENDS  --------------------------------------------------------


SELECT TASK 
, MAX_DW_DATE_KEY DATE_KEY 
, COUNT(*) FILE_COUNT 
, SUM(ROW_COUNT) CDR_COUNT,
MIN(ROW_COUNT) MIN_COUNT, AVG(ROW_COUNT) AVG_COUNT, MAX(ROW_COUNT) MAX_COUNT
FROM ( 
      SELECT  /*+PARALLEL (A,20) */ TASK, MAX_DW_DATE_KEY, ROW_COUNT 
      FROM BIB_META.DW_RT_FILES A JOIN BIB_META.DW_TASKS B ON (A.DW_TASK_ID=B.DW_TASK_ID) 
      Where A.Processing_Status In ('LOADED','ARCHFAILED','ARCHIVED','ARCHIVING','ARCHIVEFAILED')
--      AND TASK like 'TF_S2S%' 
--        and task like 'TF_S2S_XDR_SV_ZA'
        AND TASK LIKE 'TF_I2S_I_CDR_PREPAID_SNAPD%'

  AND MAX_DW_DATE_KEY BETWEEN to_char(sysdate-10,'yyyymmdd') and to_char(sysdate,'yyyymmdd')
)  
GROUP BY TASK, MAX_DW_DATE_KEY 
ORDER BY DATE_KEY DESC, MAX_DW_DATE_KEY 
--ORDER BY DATE_KEY DESC
;

----------------------------------------------------------------------------------
---------------------------CHECK DUMPS 421 AND TREND ----------------------------------------


--MA DUMPS

SELECT SUBSTR(SHORT_FILENAME,1,8) DATE_KEY,PROCESSING_STATUS, COUNT(*) DUMPS,sum(row_count) RECORD_COUNT, MAX_DW_DATE_KEY, max(REGISTER_DATETIME)
FROM DW_RT_FILES A WHERE a.dw_task_id = dw_get_task_id ('TF_I2S_I_CDR_PREPAID_SNAPD') 
AND SUBSTR(SHORT_FILENAME,1,8) = '20170306'
--between '20170121' and SUBSTR(TRUNC(to_date('20170306 00:00:00', 'yyyymmdd hh24:mi:ss')),1,8)
GROUP BY SUBSTR(SHORT_FILENAME,1,8) , PROCESSING_STATUS, MAX_DW_DATE_KEY
ORDER BY 1 desc;
/


--interconnect
select date_key, count(*) from bib_cdr.fct_cdr_interconnect  partition for (20170306) group by date_key --62 million Trend
;
/

----------------------------------------------------------------------------------
---------------------------MOVE PROCESS DATES----------------------------------------


SELECT task, max_key FROM DW_TASKS WHERE TASK LIKE '%PROCESS_DATE%';
/
UPDATE DW_TASKS
   SET MAX_KEY = '20170307'
 WHERE TASK LIKE '%STD_DEP_EDW_PROCESS_DATE%';
 
/

--------------------------SETUP THE PULL----------------------------------------


BEGIN
--BIB_CTL.DW_BIB_UTL.DIY_RESET('STD_TE_I2S_POSTPAID_SUBSCRIBER_BASE_PULL','20170130');
BIB_CTL.DW_BIB_UTL.DIY_RESET('STD_TE_I2S_POSTPAID_SUBSCRIBER_BASE_PULL','20170301');

end;
/
----------------------------------------------------------------------------------
---------------------------activate profiles----------------------------------------
--D-1

begin
    dw_bib_sched.SET_PROFILE('NORMAL'); 
    dw_bib_utl.RELEASE_SESSION_USER_LOCKS;
end;
/


----------------------------------------------------------------------------------
---------------------------SETUP TASKS ----------------------------------------

---FORCE TASKS if they dont setup
BEGIN
--    dw_exec_task_setup(v_itask=>'CS5_TE_S2C_FCT_CDR_PREPAID_SNAPD_SDP_DUMP_MA',pi_days_back=>100);
--    dw_exec_task_setup(v_itask=>'STD_WAIT_SUBS_SNAPD',pi_days_back=>100);
--    dw_exec_task_setup(v_itask=>'STD_WAIT_SUBS_CLASSIFICATION',pi_days_back=>100);
--    dw_exec_task_setup(v_itask=>'STD_C2C_FCT_CDR_TRANS_COMB',pi_days_back=>100);
--    dw_exec_task_setup(v_itask=>'STD_C2C_FCT_CDR_RATED_COMB',pi_days_back=>100);
    dw_exec_task_setup(v_itask=>'STD_C2E_FCT_SUBSCRIBER_SNAPD',pi_days_back=>100);
      dw_bib_utl.RELEASE_SESSION_USER_LOCKS;
END;
/


UPDATE DW_RT_RUNS SET RUN_STATUS = 'CLOSED' WHERE TASK IN ('STD_WAIT_SUBS_SNAPD') AND DW_BATCH_ID = 4143529;


select count(*)
from BIB.DIM_SUBSCRIBER
where record_force_source = 'STD_C2E_FCT_PREPAID_USAGE_SUMD';


---------------TO WORK ON FOR HOLDING INTS ----------------------------------------------

update dw_rt_runs set run_status = 'HOLD_MK' where task in
(
'CS5_TE_S2C_FCT_CDR_PREPAID_SNAPD_SDP_DUMP_MA'
--'STD_TE_S2S_INT_SUBSCRIBER'
)
--and diy_parameter = '20170208'
and run_status in ('FAILED');


and dw_batch_id not in
(
  select dw_batch_id from 
        (
        select rank () over (order by rows_loaded desc) rank, dw_batch_id 
        from dw_rt_runs where 1 =1 
        and task = 'CS5_TE_S2C_FCT_CDR_PREPAID_SNAPD_SDP_DUMP_MA'
        and diy_parameter = '20170208'
        )
  where rank = 1
);



----------------------------------------------------------- ----------------------------------------------
------------------------------------------------------------- ----------------------------------------------
------------------------------------------------------------- ----------------------------------------------
----------------------------------------------------------AFTER-- ----------------------------------------------

--generate setups 
'dw_exec_task_setup(v_itask=>'|| '''' || task ||''''|| ',pi_days_back=>41);'



--BIB sched LIST VIEW
select * from vw_dw_bib_sched_list
where task = 'STD_C2C_FCT_CDR_RATED_COMB'
;


-------------------GENERIC UPDATE-------------------------------------------------------------------------------
SELECT * FROM DW_RT_RANGE_RUNS WHERE DW_RUN_ID = 4256140
and run_status = 'FAILED';

UPDATE DW_RT_RUNS 
--UPDATE DW_RT_RANGE_RUNS 
  SET 
--RUN_STATUS = 'RUNABLE'
RUN_STATUS = 'HOLD_MK'
--RUN_STATUS = 'SUCCESS'
--RUN_STATUS = 'CLOSED'
--RUN_STATUS = 'CANCELLED'
--
--,
--start_DATE = sysdate - 100
WHERE 
1=1
--AND  TASK LIKE '%STD_C2E_FCT_SUBS_FULL_SUMD'
--and  TASK in 
--(
--)
AND  DW_RUN_ID   IN 
(
4266638
) 
-- AND DW_BATCH_ID  = 6129957
--AND DW_RANGE_VALUE_ID = 10019
--AND DIY_PARAMETER in (20161118, 20161119)
--AND RUN_STATUS IN ('RUNABLE' )
--AND RUN_STATUS  IN ('FAILED')
--  AND RUN_STATUS IN ('HOLD_MK')

;


-----------failed int_sub add a payment option-------------------------------------------------------------------

SELECT * FROM STG_GEN.I_POSTPAID_SUBSCRIBER_BASE
WHERE BATCH_ID = 3388471 --failing batch
and payment_option_cd is null;

update STG_GEN.I_POSTPAID_SUBSCRIBER_BASE set payment_option_cd = 'U' 
WHERE BATCH_ID = 3388471 --failing batch
and payment_option_cd is null;
/

--------------------------LOG APP------------------------------------------------------
----------------------------------------------------------------------------------------

SELECT *
FROM DW_RT_LOG_APP  
where 1=1
--and dw_task_id in dw_get_task_id('DW_FILE_TASK_REGISTER')
and process_name = 'DW_FILE_TASK_REGISTER'
and  ERROR_SYSDATE > sysdate - 0.5
and error_code = 'E'
--and dw_run_id = 4081470
--AND PROCESS_NAME LIKE '%TABLESPACE%'
ORDER BY error_sysdate DESC
;



select * from STG_CDR.ER_SASN_CDR ;

-----------------------------------------------------------------------------------------
SELECT * FROM DW_RT_RUNS
WHERE  1=1
--AND DW_task_ID  =  10082 
--11177
--10082
and TASK like '%EXEC_EMM_BIB_AUDIT_DETAIL%'
--and  DW_RUN_ID = 3799862
and RUN_STATUS   not in  ('CLOSED' , 'SUCCESS' ,'CANCELLED' )
--and RUN_STATUS  
--and run_status  IN  ('CLOSED' , 'SUCCESS')
--AND   DW_BATCH_ID  IN (3699498)
--OR DW_BATCH_ID IN (SELECT DW_BATCH_ID FROM DW_RT_BATCHES WHERE DW_COPIED_BATCH_ID =  4504822 )
ORDER BY 5 DESC
--order by diy_parameter desc
;
--10082

update dw_rt_runs set run_status = 'HOLD_MK' WHERE TASK = 'STD_C2E_FCT_SUBSCRIBER_SNAPD' AND RUN_STATUS = 'RUNABLE' 
AND DW_RUN_ID   ! = 4266639
;
------------------------------------------------FAVOURITE METAS -------------------------------------------------

select * from  DW_RT_DIY_LIST
where dw_run_id = 4211382;


SELECT /*+parallel (A,10) FULL(A)*/ 
       A.SHORT_FILENAME, FILENAME, 
       PROCESSING_STATUS, 
       TO_CHAR(TRUNC(REGISTER_DATETIME),'YYYYMMDD') REG_DATE, 
       COUNT(*) CNT
FROM BIB_META.DW_RT_FILES A
JOIN BIB_META.DW_TASKS B
    ON A.DW_TASK_ID = B.DW_TASK_ID
where 1=1
--AND b.parameter_type = 'LOAD'

--      AND PROCESSING_STATUS like '%DUP%' 
        AND REGISTER_DATETIME  > SYSDATE - 0.5

  AND TASK in 
  (
  'STD_TF_S2S_HRIS_ADDRESS'
--  'STD_TF_S2S_HRIS_ASSIGNMENT'
--  'STD_TF_S2S_HRIS_BENEFITS'
--  'STD_TF_S2S_HRIS_PERSONAL'
  )
GROUP BY 
       SHORT_FILENAME,
       FILENAME,
        PROCESSING_STATUS, 
        TO_CHAR(TRUNC(REGISTER_DATETIME),'YYYYMMDD')
ORDER BY 4 DESC;

--------------who did what ---------------------------------------------

bib_ctl.audit_ddl


select * 
from stg_cdr.audit_ddl
where name = 'ER_SASN_CDR';

select dbms_metadata.get_ddl('TABLE','ER_SASN_CDR','STG_CDR') from dual;
/

select * from dw_rt_files  where  dw_batch_id = 3970007;

select * from DW_RT_DO_BATCH_LOG  where dw_batch_id = 4177891;
--return code 15 concatenation error.

SELECT 'mv '||REPLACE(filename,'incoming','work')||'* '||filename as mv FROM DW_RT_FILES WHERE DW_BATCH_ID in
(
4029808
) ;




SELECT 'mv '||REPLACE(short_filename,'incoming','work')||'*  '||short_filename as mv FROM DW_RT_FILES WHERE DW_BATCH_ID in
(
4029808
) ;





select * from dw_rt_files where processing_status LIKE  '%REG%
%'
AND START_DATETIME > SYSDATE - 0.5;

select * from dw_column_mappings where task = 'STD_C2E_FCT_PREPAID_SNAPD';

\

select column_order,task, column_name, sqlloader_format, oracle_format from DW_TASK_FILE_COLUMNS
  where task LIKE '%TF_S2S_HLR_NORM_ZA%'
order by task , column_order;

select * from dw_rt_batches  WHERE DW_BATCH_ID IN 
(
4029808
) ;


select * from dw_task_attributes;

select * from dw_TASK_DATA_DEPEND WHERE DEPENDENT_TASK = 'STD_C2E_FCT_SUBS_FULL_SUMD' ;


UPDATE dw_task_data_depend
set SUPER_BATCH_IND = 'Y'
where dependent_task = 'STD_C2C_FCT_MSISDN_GEOGRAPHY_SUMD'
AND task = 'STD_C2C_FCT_CDR_RATED_COMB'
AND SUPER_BATCH_IND = 'N';



tar zxvf 89205.tar.gz


----------------------------------------------------------------------------------------------------------------
SELECT ''''|| TASK || ''',' , FLEX1, LAG_TIME, flex2, max_file_load_concurrency ,IS_RUNNABLE,  a.* FROM DW_TASKS a 
WHERE 
1=1
--AND FLEX1 LIKE '2'
--AND FLEX2 LIKE 'NA'
--AND IS_RUNNABLE = 'Yes
--and parameter_type = 'BATCH'
AND TASK LIKE '%LATE_ARRIVING_CDRS%'
--AND DW_TEMPLATE_ID = 11093
--AND TASK IN
--(
--'EXEC_EMM_BIB_AUDIT_DETAIL'
--
--)
--and IS_RUNNABLE = 'Yes'
;

----------------------------------------------------------------------------------------------------------------

UPDATE
DW_TASKS
--dw_environment_variables 
SET
--FLEX1 = '30'
--LAG_TIME = NULL
-- VARIABLE_VALUE =  10
IS_RUNNABLE = 'No'
--max_file_load_concurrency = 100

WHERE
1=1
--and VARIABLE_NAME = 'LOCATION:BIB_CTL:DW_EXEC_TASK_RUN:7'
--AND FLEX1 = '17'
--and parameter_type = 'BATCH'
AND TASK LIKE '%EXEC_REPORT_LATE_ARRIVING_CDRS'

;


--STD_C2E_FCT_SUBS_FULL_SUMD return to 25 
--EXEC_EMM_BIB_AUDIT_DETAIL return to 1


--------------------------------------ENVIRONMENTAL VARIABLES--------------------------------------

select /*+ parallel(2)*/ * from dw_environment_variables
where variable_name like 'LOCATION:BIB_CTL:DW_EXEC_TASK_RUN%32'
order by 2;



update dw_environment_variables set VARIABLE_VALUE = 'PM_ADMIN.' WHERE VARIABLE_NAME = 'ABL_CONTRACT';


-----------------CLEAR CACHE-------------------------------------------------------------------------

begin
  dw_utl.log_app('FW_CACHE_CLEAR', 'Clearing task cache', 'I', 1);
  dw_exec.Task_Cache_Clear_Request_All('SCHED');
exception when others then
  dw_utl.log_app('FW_CACHE_CLEAR', 'Clearing task cache - ERROR ' || SQLERRM, 'E', 1);
end;
/



begin
   dw_exec.clear_cache(23102);
end;
/


---------------------CHECK SPACE -------------------------------------------------

SELECT distinct  TOTAL_MB/1024 AS TOTAL_IN_GB, 
ROUND(TOTAL_MB/1024/1024,2) AS TOTAL_IN_TB, 
ROUND(USABLE_FILE_MB/1024,0) AS AVAILABLE_GB, 
ROUND(USABLE_FILE_MB/1024/1024,3) AS AVAILABLE_TB,
ROUND((USABLE_FILE_MB/1024)/(TOTAL_MB/1024)*100,0)||'%' PERC_AVAILABLE, NAME 
FROM GV$ASM_DISKGROUP
ORDER by 6 ASC

;

----------------------------------------------------------------------------------

SELECT  tablespace_name, tablespace_size /1000000/1024 tablespace_size, allocated_space /1000000/1024  allocated_space, 
 free_space /1000000/1024  free_space FROM dba_temp_free_space;

--------------INSERT DEPENDANCY-------------------------------------------------------

begin
dw_bib_utl.insert_dependency(  
  pi_parent_task_like =>'STD_E2E_FRU_PVT_POSTPAID_SUMD',
  pi_dependent_task_like =>'STD_C2C_FCT_SUBS_RGE_MISC_LAST',
  pi_SUPER_BATCH_IND =>'N',
  pi_DEPENDENCY_TYPE=> 'DIY_DIY_DATE');
end;
/


-------------------------------------------------------------------------------------------------


---WHEN BATCH ROWS LOADED NOT IN TREND ------------------------------------------
--------------CLEANING UP META TABLES ------------------------------------------
--------------------------------------------------------------------------------
DELETE FROM bib_meta.dw_rt_file_date_histograms 
WHERE DW_FILE_KEY IN 
(SELECT DW_FILE_KEY FROM bib_meta.dw_rt_files WHERE dw_batch_id IN (

3984881)); --INSERT DW_BATCH_ID


DELETE FROM bib_meta.dw_rt_batch_date_histograms 
WHERE dw_batch_id IN (

);--INSERT DW_BATCH_ID
DELETE FROM bib_meta.dw_rt_files 
WHERE dw_batch_id IN (

) ;--INSERT DW_BATCH_ID
DELETE FROM bib_meta.DW_RT_RUN_ERRORS 
WHERE dw_run_id IN (

);--INSERT DW_RUN_ID
DELETE FROM bib_meta.dw_rt_batches 
WHERE dw_batch_id IN (

);--INSERT DW_BATCH_ID
DELETE FROM bib_meta.dw_rt_runs 
WHERE dw_batch_id IN (

);--INSERT DW_BATCH_ID
commit;

--------------RESET THE TASK (DIY RESET) ------------------------------------------
--------------------------------------------------------------------------------


 select COUNT(*)  from STG_CDR.IBF_XDR
 WHERE BATCH_ID = 4029827 ;
 
 
 SELECT COUNT (*) FROM DW_RT_FILES 
 WHERE DW_BATCH_ID  = 4029827;


describe STG_CDR.HLR_NORM;

SELECT * FROM STG_CDR.CTA_FIL4081470;


SELECT  BIB_CTL.DW_UTL_REMOTE.DW_DATE_KEY(to_date(to_number(substr(BIB_CTL.DW_UTL_REMOTE.LKU_SHORT_FILENAME(249414622),1,8)),'YYYYMMDD')) FROM DUAL;


select  count (*) , msisdn_nsk  from BIB_CDR.C_4124840_20170305_2
group by msisdn_nsk having count(*) > 1;


select  *  from BIB_CDR.C_4124840_20170305_2
;


select * from STG_GEN.HRIS_PERSONAL
ORDER BY CREATE_DT DESC;



SELECT * FROM STG_CDR.LATE_ARRIVING_CDRS_CONFIG where NVL(ACTIVE_STATUS,'N') ='Y'



