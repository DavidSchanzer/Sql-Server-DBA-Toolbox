-- From http://dba.stackexchange.com/questions/58859/script-to-see-running-jobs-in-sql-server-with-job-start-time
SELECT ja.job_id,
       j.name AS job_name,
       ja.start_execution_date,
       ISNULL(ja.last_executed_step_id, 0) + 1 AS current_executed_step_id,
       js.step_name
FROM msdb.dbo.sysjobactivity ja
    LEFT JOIN msdb.dbo.sysjobhistory jh
        ON ja.job_history_id = jh.instance_id
    JOIN msdb.dbo.sysjobs j
        ON ja.job_id = j.job_id
    JOIN msdb.dbo.sysjobsteps js
        ON ja.job_id = js.job_id
           AND ISNULL(ja.last_executed_step_id, 0) + 1 = js.step_id
WHERE ja.session_id =
(
    SELECT TOP 1
           session_id
    FROM msdb.dbo.syssessions
    ORDER BY agent_start_date DESC
)
      AND ja.start_execution_date IS NOT NULL
      AND ja.stop_execution_date IS NULL;
