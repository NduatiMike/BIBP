------------------PROCESS_DATE----------------PROCESS_DATE-------------------PROCESS_DATE----------------
select * from dw_tasks
where task = 'STD_DEP_TECH_PROCESS_DATE'
order by 5 desc;
/

update dw_tasks set max_key = 20160601 where  task='STD_DEP_TECH_PROCESS_DATE';
commit;
/
------------------SETUP----------------SETUP-------------------SETUP-----------------
-------------------------------------------------------------------------------------
--CHECK IF SETUP UP AND FOR WHAT DATE, BATCH NUMBER
select * from dw_rt_runs
where task = 'STD_FACTS_RELATIONAL_S2S_EXTRACT_SETUP'
order by 5 desc;
/

---IF NOT , SET IT UP

BEGIN
DW_BIB_UTL.SETUP_AND_RUN_ONE('STD_FACTS_RELATIONAL_S2S_EXTRACT_SETUP');
END;
/


------------------EXTRACT_CONTROL----------------EXTRACT_CONTROL-----------------
--------------------------------------------------------------------------------

select * from dw_rt_runs
where task = 'STD_FACTS_RELATIONAL_S2S_EXTRACT_CONTROL'
order by 5 desc;
/

BEGIN
DW_BIB_UTL.RUN_MANY('STD_FACTS_RELATIONAL_S2S_EXTRACT_CONTROL');
END;
/

------------------AUDIT THE BATCH TASK -----------------------------------------
--------------------------------------------------------------------------------

begin
  BIB_CTL.DW_EXEC_TASK_AUDIT('STD_FACTS_RELATIONAL_S2S_EXTRACT_SETUP');
 end;
/

-------------------------S2S-------------------------S2S-------------------------
--------------------------------------------------------------------------------

 -- 16 TASKS


select run_status, a. * from dw_rt_runs a
where task in(
'STD_TE_S2S_FACTS_ROUTECFG',
'STD_TE_S2S_FACTS_TRUNKROUTE60',
'STD_TE_S2S_FACTS_CELLCFG',
'STD_TE_S2S_FACTS_CELLSTATS_60',
'STD_TE_S2S_FACTS_CELLSTATS_LAYER_60',
'STD_TE_S2S_FACTS_EOS60',
'STD_TE_S2S_FACTS_HLRSTAT60',
'STD_TE_S2S_FACTS_HLRSUBS60',
'STD_TE_S2S_FACTS_LOAS05',
--CDC ONES WILL SETUP AFTER PREVIOUS TABLES------
'STD_TE_S2S_FACTS_TRUNKROUTE60_CDC',
'STD_TE_S2S_FACTS_CELLSTATS_60_CDC',
'STD_TE_S2S_FACTS_CELLSTATS_LAYER_60_CDC',
'STD_TE_S2S_FACTS_EOS60_CDC',
'STD_TE_S2S_FACTS_HLRSTAT60_CDC',
'STD_TE_S2S_FACTS_HLRSUBS60_CDC',
'STD_TE_S2S_FACTS_LOAS05_CDC'
)
ORDER BY 6 DESC;
/

SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; ' FROM DW_RT_RUNS WHERE TASK LIKE '%S2S%' AND RUN_STATUS = 'RUNABLE';


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


select * from dw_rt_batches where dw_batch_id =45059;
--IF BATCHES ARE NOT AUDITED 

-------------------------AUDIT THE BATCH----------------------------------------
--------------------------------------------------------------------------------

begin
  BIB_CTL.DW_EXEC_TASK_AUDIT('STD_FACTS_RELATIONAL_S2S_EXTRACT_SETUP');
 end;
/
-------------------------TR-------------------------TR--------------------------

select * from dw_rt_runs
where task = 'TR_S2S_FACTS'
order by 5 desc;

BEGIN
DW_BIB_UTL.RUN_MANY('TR_S2S_FACTS');
dw_bib_utl.RELEASE_SESSION_USER_LOCKS;
END;
/

-------------------------TD-------------------------TD--------------------------
--------------------------------------------------------------------------------
--TD SHOULD SET UP AND GO INTO PENDING

select * from dw_rt_runs
where task = 'TD_S2S_FACTS'
order by 5 desc;

UPDATE DW_RT_RUNS SET RUN_STATUS = 'RUNABLE' WHERE DW_RUN_ID = 88023 AND TASK = 'TD_S2S_FACTS';
--IF ITS SETUP - RUN MANY 
BEGIN
DW_BIB_UTL.RUN_MANY('TD_S2S_FACTS');

END;
/

--ELSE SETUP UP 

BEGIN
DW_BIB_UTL.SETUP_AND_RUN_MANY('TD_S2S_FACTS');
END;
/


--------------------RULE TASK----------------RULE TASK-------------------RULE TA--
--------------------------------------------------------------------------------
--SUPPOSED TO CLOSE THE TD TASK/ RARELY DOES SO

select * from dw_rt_runs
where task = 'STD_RULE_TD_S2S_FACTS'
order by 5 desc;


begin 
dw_exec_task_setup('STD_RULE_TD_S2S_FACTS'); 
dw_bib_utl.RELEASE_SESSION_USER_LOCKS;   
end;
/


--CLOSE IT MANUALLY IF RULE DOESNT WORK MULTIPLE TIMES
--MAKE SURE THE BATCH IS AUDITED BEFORE CLOSING 

UPDATE  DW_RT_RUNS  SET RUN_STATUS = 'CLOSED' WHERE DW_RUN_ID =  77072 AND TASK = 'TD_S2S_FACTS';

--IGNORE THE BELOW , JUST ANOTHER WAY TO SETUP TD TASK
begin
BIB_CTL.DW_EXEC_TASK_SETUP_ALL(pi_location=>'LOCATION:BIB_CTL',
pi_parameter_type1=>'BATCH',
pi_task_business_area_like=>'%',
pi_task_like=>'TD%',
pi_days_back=>120);
end;
/

-------------------------FACTSM-------------------------FACTSM------------------
--------------------------------------------------------------------------------


select * from dw_rt_runs
where task in(
'STD_TE_S2M_FACTSM_CELLSTATS_60',
'STD_TE_S2M_FACTSM_CELLSTATS_LAYER_60',
'STD_TE_S2M_FACTSM_EOS60',
'STD_TE_S2M_FACTSM_HLRSTAT60',
'STD_TE_S2M_FACTSM_CELLCFG',
'STD_TE_S2M_FACTSM_LOAS05',
'STD_TE_S2M_FACTSM_ROUTECFG',
'STD_TE_S2M_FACTSM_TRUNKROUTE60',
'STD_TE_S2M_FACTSM_HLRSUBS60')
--AND RUN_STATUS not in('CLOSED','SUCCESS')
order by 5 desc;


SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; ' FROM DW_RT_RUNS WHERE TASK LIKE '%S2M%' AND RUN_STATUS = 'RUNABLE';

--------------DIMESIONS------------DIMESIONS--------------DIMESIONS------------
--------------------------------------------------------------------------------


select * from dw_rt_runs
where task in(
'STD_TE_S2E_DIM_NETWORK_LAYER',
'STD_DIM_NETWORK_OPERATOR',
'STD_TE_S2E_DIM_NETWORK_ELEMENT',
'STD_DIM_REGION',
'STD_DIM_BASE_STATION',
'STD_DIM_TRUNK_ROUTE')
--AND RUN_STATUS not in('CLOSED','SUCCESS')
order by 5 desc;


SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; ' FROM DW_RT_RUNS WHERE TASK LIKE '%DIM%' AND RUN_STATUS = 'RUNABLE';

--------------FACTS--------------FACTS--------------FACTS-----------------------
--------------------------------------------------------------------------------
-- Current Batch: 24102 ()
select * from dw_rt_runs
where task in(
'STD_TE_S2E_FCT_NETWORK_CELL_STATS',
'STD_TE_E2E_FCT_NETWORK_CELL_STATS_SUMD',
'STD_TE_E2E_FCT_NETWORK_CELL_STATS_SUMM',
'STD_TE_E2E_FRU_NETWORK_CELL_STATS_SUMM')
--AND start_date > '20160101  22:44:44'
--AND RUN_STATUS not in('CLOSED','SUCCESS')
order by 5 desc;

SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; '  FROM DW_RT_RUNS WHERE TASK LIKE '%CELL_STATS%' AND RUN_STATUS = 'RUNABLE';


------------------ROUTE---------------------------------------------------------
--------------------------------------------------------------------------------
select * from dw_rt_runs
where task in(
'STD_TE_S2E_FCT_NETWORK_ROUTE_STATS',
'STD_TE_E2E_FCT_NETWORK_ROUTE_STATS_SUMD',
'STD_TE_E2E_FCT_NETWORK_ROUTE_STATS_SUMM',
'STD_TE_E2E_FRU_NETWORK_ROUTE_STATS_SUMM')
--AND start_date > '20140709  08:40:04'
--AND RUN_STATUS not in('CLOSED','SUCCESS')
order by 5 desc;


SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; '  FROM DW_RT_RUNS WHERE TASK LIKE '%ROUTE_STATS%' AND RUN_STATUS = 'RUNABLE';

------------------LAYER---------------------------------------------------------
--------------------------------------------------------------------------------

select * from dw_rt_runs
where task in(
'STD_TE_E2E_FCT_NETWORK_LAYER_STATS_SUMD',
'STD_TE_E2E_FCT_NETWORK_LAYER_STATS_SUMM',
'STD_TE_S2E_FCT_NETWORK_LAYER_STATS',
'STD_TE_E2E_FRU_NETWORK_LAYER_STATS_SUMM')
--AND start_date > '20140802  14:45:05'
--AND RUN_STATUS not in('CLOSED','SUCCESS')
order by 5 desc;


SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; ' FROM DW_RT_RUNS WHERE TASK LIKE '%LAYER_STATS%' AND RUN_STATUS = 'RUNABLE';

----------------LOAD-------------------------------------------------------------
--------------------------------------------------------------------------------
select * from dw_rt_runs
where task in(
'STD_TE_S2E_FCT_NETWORK_LOAD_STATS',
'STD_TE_E2E_FCT_NETWORK_LOAD_STATS_SUMD',
'STD_TE_E2E_FCT_NETWORK_LOAD_STATS_SUMM')
--AND start_date > '20140706  23:06:35'
--AND RUN_STATUS not in('CLOSED','SUCCESS')
order by 5 desc;

SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; ' FROM DW_RT_RUNS WHERE TASK LIKE '%LOAD_STATS%' AND RUN_STATUS = 'RUNABLE';

----------------ELEMENT---------------------------------------------------------
--------------------------------------------------------------------------------
select * from dw_rt_runs
where task in(
'STD_TE_E2E_FCT_NETWORK_ELEMENT_STATS_SUMD',
'STD_TE_E2E_FCT_NETWORK_ELEMENT_STATS_SUMM',
'STD_TE_S2E_FCT_NETWORK_ELEMENT_STATS')
--AND start_date > '20160106  23:10:06'
--AND RUN_STATUS not in('CLOSED','SUCCESS','DELAYED','CANCELLED')
order by 5 desc;

SELECT  'DW_BIB_UTL.RUN_MANY('''|| TASK ||  ''')' || '; ' FROM DW_RT_RUNS WHERE TASK LIKE '%ELEMENT_STATS%' AND RUN_STATUS = 'RUNABLE';

----------------OVERALL---------------------------------------------------------
--------------------------------------------------------------------------------

select * from dw_rt_runs
where task in(
'STD_TE_E2E_FCT_NETWORK_OVERALL_STATS_SUMM')
--AND RUN_STATUS not in('CLOSED','SUCCESS')
order by 5 desc;

/

UPDATE DW_RT_RUNS SET RUN_STATUS = 'HOLD_MK' WHERE TASK = 'STD_FACTS_RELATIONAL_S2S_EXTRACT_SETUP'
AND dw_run_id = 72021;

