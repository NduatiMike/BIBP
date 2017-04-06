  BEGIN 
  
      FOR i IN ( 
        select distinct task from dw_rt_log_app l, dw_rt_runs r 
		where r.dw_task_id = l.dw_task_id 
		and r.task like '%ABLT%'and r.run_status = 'FAILED' 
        and  error_sysdate > sysdate - 0.1 
        and error_code = 'E'
        and process_name = 'DW_BIB_SCHED'
        and
        (
        l.message like '%The partition number is invalid or out-of-range%'
        )
        
        ) 
LOOP   


select 
	

      update dw_rt_runs set run_status = 'RUNABLE',
      START_DATE = SYSDATE - 100 
      WHERE TASK = i.task 
      AND RUN_STATUS = 'FAILED'
      AND START_DATE > SYSDATE - 0.1;
      COMMIT;
      
      UPDATE DW_RT_RANGE_RUNS set run_status = 'RUNABLE'
      WHERE TASK = i.task 
      AND RUN_STATUS = 'FAILED'
      ;
      COMMIT;
      
      END LOOP; 

END;



nohup ./bib_stats_on_dir.sh &