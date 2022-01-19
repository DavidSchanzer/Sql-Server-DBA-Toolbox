-- From https://sqlundercover.com/2017/10/05/how-far-has-my-update-got-finding-out-how-many-rows-your-long-running-insert-update-or-delete-has-actually-modified-so-far/?utm_source=DBW&utm_medium=pubemail

DECLARE @SPID INT = 54
 
SELECT COUNT(*)--fn_dblog.*
FROM fn_dblog(null,null)
WHERE
operation IN ('LOP_MODIFY_ROW', 'LOP_INSERT_ROWS','LOP_DELETE_ROWS') AND
context IN ('LCX_HEAP', 'LCX_CLUSTERED') AND
[Transaction ID] =
                    (SELECT fn_dblog.[Transaction ID]
                    FROM sys.dm_tran_session_transactions session_trans
                    JOIN fn_dblog(null,null) ON fn_dblog.[Xact ID] = session_trans.transaction_id
                    WHERE session_id = @SPID)

					sp_WhoIsActive