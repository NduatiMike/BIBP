select 
   (select username from v$session where sid=a.sid) blocker,
   a.sid,
   ' is blocking ',
   (select username from v$session where sid=b.sid) blockee,
   b.sid
from 
   v$lock a, 
   v$lock b
where 
   a.block = 1
and 
   b.request > 0
and 
   a.id1 = b.id1
and 
   a.id2 = b.id2;
   
   
   
   select
   c.owner,
   c.object_name,
   c.object_type,
   b.sid,
   b.serial#,
   b.status,
   b.osuser,
   b.machine
from
   v$locked_object a ,
   v$session b,
   dba_objects c
where
   b.sid = a.session_id
and
   a.object_id = c.object_id;
   
   
   
   
  
  SELECT username U_NAME, owner OBJ_OWNER,
object_name, object_type, s.osuser,
DECODE(l.block,
  0, 'Not Blocking',
  1, 'Blocking',
  2, 'Global') STATUS,
  DECODE(v.locked_mode,
    0, 'None',
    1, 'Null',
    2, 'Row-S (SS)',
    3, 'Row-X (SX)',
    4, 'Share',
    5, 'S/Row-X (SSX)',
    6, 'Exclusive', TO_CHAR(lmode)
  ) MODE_HELD
FROM gv$locked_object v, dba_objects d,
gv$lock l, gv$session s
WHERE v.object_id = d.object_id
AND (v.object_id = l.id1)
AND v.session_id = s.sid
AND object_name like '%DDL%'
ORDER BY username, session_id;


select SESSION_ID || ',' from DBA_DDL_LOCKS where name like '%DW_BIB_UTL%'  order by SESSION_ID;



select 
u.inst_id, schemaname, u.module, u.client_info, u.logon_time,  u.sid, serial#, machine, status, s.sql_text, substr(event,1,509) event ,seconds_in_wait, u.blocking_session, 
u.final_blocking_session,
'alter system kill session  ''' ||to_char(sid)||','||to_char("SERIAL#")||',@'||u.inst_id||'''  immediate;' kill_session
from gv$session u 
left outer join gv$sqltext s 
on (s.hash_value = u.sql_hash_value and s.inst_id = u.inst_id)
where 1=1
and nvl(s.piece,0)=0
--and u.final_blocking_session is not null
--and u.module like 'TE_S2E_FCT_CDR_EVD_ERS'
--and upper(machine) like '%OBIEE_BIB_RW%'
and u.sid in ( 
680,
680,
701,
701,
886,
886,
1203,
1203,
1399,
1399,
1400,
1400,
1666,
1666,
1934,
1934,
1939,
1939,
2442,
2442,
2927,
2927,
2934
) 
--and serial# like '21821'
--and upper(schemaname) like '%OBIEE_BIB_RW%'
order by  u.logon_time, u.seconds_in_wait desc, u.sid, s.piece asc;


                      
begin
DW_BIB_UTL.DROP_CTL_JOB('FW_EXEC_RUN_BATCH_NA_PRIO_6');
  dw_bib_utl.RELEASE_SESSION_USER_LOCKS;
end;
/




DW_BIB_UTL.DROP_CTL_JOB('FW_EXEC_SETUP_DIY_E2E');
DW_BIB_UTL.DROP_CTL_JOB('FW_EXEC_RUN_BATCH_NA_PRIO_1');
DW_BIB_UTL.DROP_CTL_JOB('FW_EXEC_TASK_RUN_CTL_CATCH');
DW_BIB_UTL.DROP_CTL_JOB('FW_EXEC_SETUP_DIY_E2E');
DW_BIB_UTL.DROP_CTL_JOB('FW_EXEC_RUN_BATCH_NA_PRIO_6');
DW_BIB_UTL.DROP_CTL_JOB('FW_EXEC_RUN_BATCH');


