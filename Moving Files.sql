
--SV
--ls > /data01/infa/PROD/scripts/mike_clean_work.csv
--SV work to move mike_clean_work_o

--GGSN
--ls > /data01/infa/PROD/scripts/mike_cleanggsn_work.csv
--SV work to move mike_clean_work_o

--MSC_VOICE_TR

--ls > /data01/infa/PROD/scripts/mike_voicetr_work.csv
--SV work to move mike_voicetr_work_o



drop table mike_clean_work;

CREATE TABLE mike_clean_work  (short_filename VARCHAR (1000 BYTE))
ORGANIZATION EXTERNAL
   (TYPE ORACLE_LOADER
         DEFAULT DIRECTORY "DW_SCRIPT_DIR_SAPROD" ACCESS PARAMETERS ( FIELDS TERMINATED BY ',')
         LOCATION ('mike_clean_work.csv'));
         
         drop table mike_clean_work purge;
         
  create table mike_clean_work_o  as 
  select  *  from mike_clean_work;
  

         
select 'mv -f '||short_filename||' /data01/infa/PROD/CDR/XDR_SV/incoming/ '   from dw_rt_files 
where 1=1
--SHORT_FILENAME LIKE '%SDP%20170223%'
AND PROCESSING_STATUS = 'ARCHIVED'
AND SHORT_FILENAME  IN(
         select * from michael_xt_file_list
         );
         
    
    
    ALTER TABLE mike_clean_work_o  ADD (min_processing_status VARCHAR (1000 BYTE), max_processing_status VARCHAR (1000 BYTE), file_count number);
/ 
select * from mike_errors_ours
WHERE  LENGTH (short_filename)  <=  36;  
/

MERGE INTO mike_clean_work_o a
     USING (  SELECT /*+ parallel 10*/ 
                     short_filename,
                     MIN (processing_status) min_processing_status,
                     MAX (processing_status) max_processing_status,
                     COUNT (*) file_count
                FROM dw_rt_files
               WHERE     dw_task_id = dw_get_task_id ('TF_S2S_XDR_SV_ZA')
                 AND short_filename IN (SELECT short_filename FROM mike_clean_work_o)
            GROUP BY short_filename) b
        ON ((a.short_filename) = (b.short_filename))
WHEN MATCHED
THEN
   UPDATE SET
      a.min_processing_status = b.min_processing_status,
      a.max_processing_status = b.max_processing_status,
      a.file_count = b.file_count;
      
COMMIT;

-------------------  ------------------------------------------------------------------------------
         
select min_processing_status, max_processing_status, file_count, count(*)
 from mike_clean_work_o
 group by min_processing_status, max_processing_status, file_count;
 
 
 select * from dw_rt_files where short_filename = 'TTFILE08-4396_20170314140251.dat'
 and dw_task_id = 23104 ;
 

 
-------------------get the files ------------------------------------------------------------------------------

  select distinct  'rm  -f '||  SHORT_FILENAME    from mike_voicetr_work_o  where min_processing_status  is null
--  and max_processing_status = 'ARCHIVING'
 ;
 
 
 select  'rm  -f '||  SHORT_FILENAME   from dw_rt_files where short_filename in 
 (
   select  SHORT_FILENAME    from mike_voicetr_work_o  where min_processing_status = 'ARCHIVING'
  and max_processing_status = 'ARCHIVING'
  ) 
  and processing_status NOT IN   ( 'ARCHIVED') 
--  ('LOADED','ARCHFAILED','ARCHIVED','ARCHIVING' , 'LOADING')
 ;
 
 
-- SELECT PROCESSING_STATUS FROM DW_RT_FILES
 
 update dw_rt_files set processing_status = 'LOADED'
 WHERE DW_FILE_KEY IN
 (
 select keys from
 (
 select dw_file_key  keys, SHORT_FILENAME from dw_rt_files where 
 short_filename in
(
  select DISTINCT SHORT_FILENAME from mike_voicetr_work_o  where min_processing_status = 'ARCHIVING' 
  and max_processing_status =  'ARCHIVING'
)
--and processing_status not in ('LOADED','ARCHFAILED','ARCHIVED','ARCHIVING' , 'LOADING')
and processing_status IN   ('ARCHIVING' )
--group by SHORT_FILENAME
)
)
 ;
 
 
 
 
 select * from dw_rt_files where dw_file_key =248391179;
 update dw_rt_files set processing_status = 'REGISTERED' where dw_file_key = 265786258;
 
 
 
-- select dw_file_key  keys,  'rm  -f '||  SHORT_FILENAME  from dw_rt_files where 
--update dw_rt_files set processing_status = 'LOADED'
--where dw_file_key in
--(
 select  *    from dw_rt_files where 
 short_filename in
(
  select  SHORT_FILENAME from mike_clean_work_o  where min_processing_status = 'ARCHIVING' 
  and max_processing_status =  'ARCHIVING'
)
--and processing_status not in ('LOADED','ARCHFAILED','ARCHIVED','ARCHIVING' , 'LOADING')
and processing_status IN   ('ARCHIVING' )
--and ARCHIVE_START_DATETIME <  sysdate - 1

--and dw_task_id = 23104
--group by SHORT_FILENAME
--)
;   


select  SHORT_FILENAME from mike_clean_work_o  where min_processing_status = 'ARCHIVING' 
  and max_processing_status =  'ARCHIVING';