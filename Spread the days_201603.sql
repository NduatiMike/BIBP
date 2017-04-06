--select /*+ parallel(10)*/ * from dual;
begin 
dw_bib_utl. PERIOD_BATCH_ANALYSIS(v_task_like =>'CS5_TE_S2C_FCT_CDR_PREPAID_RATED_CCN_GPRS_MA',v_from_key =>20160701, v_to_key=>20161010);
     dw_bib_utl.RELEASE_SESSION_USER_LOCKS;
    end;

rollback;
/


-- SERIAL load by date... pick the earliers few days
update dw_rt_runs set start_date=to_date(DIY_PARAMETER,'YYYYMMDD') , rows_loaded=null  -- if you want them to runs as FIRST
where run_status='RUNABLE'
and task like 'CS5_TE_S2C_FCT_CDR_PREPAID_RATED_CCN_VOICE_MA'
and diy_parameter <= 20160915
and start_date<>to_date(DIY_PARAMETER,'YYYYMMDD')
;
commit;
---
--- 'spread' the load for certain days - do this for days higher the date user above.
---
merge into dw_rt_runs tgt
using (
select 
--sysdate -3000 new_st, 
 to_date('20140401','YYYYMMDD')+rown*(1/(24*60*60)) new_st, 
xx.*
from (
select diy_parameter date_key,x.*
,row_number() over (partition by task,diy_parameter order by dw_batch_id desc) rown
from dw_rt_runs x
where run_status='RUNABLE' --and rows_loaded is null
and task like 'CS5_TE_S2C_FCT_CDR_PREPAID_RATED_CCN_GPRS_MA%'
and task not like '%xxxxxx%'
) xx
-- > date key used above for SERIAL.
where date_key >=20160916 and date_key <= 20160931 -- use an upper limit if you want
and rown<=2000  -- XXX per day for these days if you want to slip them in, or a huge number if all
order by task,rown
)src
on (tgt.dw_run_id=src.dw_run_id)
when matched
then update
set tgt.start_date=src.new_st
;
commit;
exit;