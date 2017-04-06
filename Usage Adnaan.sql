select
business_area,
max_date_Key,
case
  when status = 0 then 'UP TO DATE'
else case when trim('-' from status) = 1 then trim('-' from status)||' DAY BEHIND' else trim('-' from status)||' DAYS BEHIND' end end status from ( select business_area,
to_char(to_date(min(max_date_Key),'YYYYMMDD'),'YYYYMMDD') max_date_Key,
min(business_area_status) status
from
(
SELECT
--trunc(sysdate-1)
task_business_area business_area,
max_date_Key,
case
when task like '%SUMW' and to_date(max_date_Key,'YYYYMMDD') < trunc(sysdate-2) then to_date(max_date_Key,'YYYYMMDD')-trunc(sysdate-2)
when to_date(max_date_Key,'YYYYMMDD') < trunc(sysdate-1) then to_date(max_date_Key,'YYYYMMDD')-trunc(sysdate-1)
when task like '%EWP%' and to_date(max_date_Key,'YYYYMMDD') < trunc(sysdate) then to_date(max_date_Key,'YYYYMMDD')-trunc(sysdate)
else 0
end business_area_status
FROM
(
SELECT
task,
table_name,
task_business_area,
MAX(date_key) max_date_Key
FROM
(
SELECT
m.task,
m.dw_task_id,
m.TABLE_NAME,
task_business_area,
coalesce(to_char(b.dw_date_key), r.diy_parameter, null) date_key FROM ( SELECT A.DW_TASK_ID, A.TASK, is_runnable, NVL(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SOURCE_SINGLE_TABLE_NAME,'$'||'{BIB}','BIB.'),'$'||'{CDR}','BIB_CDR.'), '$'||'{SCDR}','STG_CDR.'),'$'||'{SGEN}','STG_GEN.'),'$'||'{CTL}','BIB_CTL.'),'_')  SOURCE_SINGLE_TABLE_NAME, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TARGET_TABLE_NAME,'$'||'{BIB}','BIB.'),'$'||'{CDR}','BIB_CDR.'), '$'||'{SCDR}','STG_CDR.'),'$'||'{SGEN}','STG_GEN.'),'$'||'{CTL}','BIB_CTL.') TABLE_NAME, task_business_area FROM bib_meta.DW_TASK_EXEC_STEPS A JOIN bib_meta.DW_TASKS B ON A.DW_TASK_ID=B.DW_TASK_ID
) m
JOIN bib_meta.dw_rt_Runs r
left outer join bib_meta.dw_rt_batches b
                     on r.dw_batch_id = b.dw_batch_id LEFT OUTER JOIN bib_meta.dw_rt_batches c
                     on b.dw_copied_batch_id = c.dw_batch_id ON m.dw_task_id = r.dw_task_id WHERE( m.table_name LIKE '%FCT%') and  is_runnable = 'Yes'
AND  m.table_name NOT LIKE '%FCT%SALE%'
AND task_business_area NOT IN ('Internal','Monitoring') --AND  task_business_area NOT LIKE 'Sales%'
AND m.task NOT LIKE 'X%'
AND M.TASK NOT IN('STD_TE_S2E_FCT_HR_EMPLOYEE_EVENT','STD_C2E_FCT_PREPAID_WALLET_SNAPM','STD_S2E_FCT_BILLING_DEPOSIT','STD_S2E_FCT_STOCK_TRANSACTION','STD_TE_S2E_FCT_IT_STATE_EVENT')
and m.task not like 'STD_S2E_FCT_BILLING%INVOICE%'
and m.task not like 'STD_S2E_FCT_BILLING%TRANSACTION%'
and m.task not like 'TG_CDR_ME2U'
and m.is_runnable = 'Yes'
and m.task not in (select target_value from umd.umd_source_specific_rules where source_system_rule_cd = 'BIB_EXCLUDE_TASK_PROCESS_DATE_OVERVIEW_REPORT')
group by
m.task,
m.dw_task_id,
m.TABLE_NAME,
task_business_area,
coalesce(to_char(b.dw_date_key), r.diy_parameter, null)
)
--ORDER BY 4
group by task,
table_name,
task_business_area)
)
GROUP BY
business_area
)
order by 2