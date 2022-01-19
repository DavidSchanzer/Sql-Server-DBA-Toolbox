/*===================================================================================================
	2013/07/15 hakim.ali@SQLzen.com
	From: http://www.sqlservercentral.com/scripts/User/100743/

	SQL Server 2005 and higher.
	
	Script to delete (drop) all database level user accounts for a given server login from all 
	databases on a database server. This will drop users even if they have a different name from 
	the server login, so long as the two are associated. This will not drop users from a database 
	where there are schemas/roles owned by the user.
	
	** USE ONLY IF YOU ARE AN EXPERIENCED DBA FAMILIAR WITH SERVER LOGINS, DATABASE USERS, ROLES, 
	SCHEMAS ETC. USE AT YOUR OWN RISK. BACK UP ALL DATABASES BEFORE RUNNING. **
=====================================================================================================*/
use [master]
go

--------------------------------------------------------------------------------------
-- Set the login name here for which you want to delete all database user accounts.
declare @LoginName nvarchar(200); set @LoginName = 'LOGIN_NAME_HERE'
--------------------------------------------------------------------------------------

declare @counter int
declare @sql nvarchar(1000)
declare @dbname nvarchar(200)

-- To allow for repeated running of this script in one session (for separate logins).
begin try drop table #DBUsers end try begin catch end catch

----------------------------------------------------------
-- Temp table to hold database user names for the login.
----------------------------------------------------------
create table #DBUsers
(			ID				int identity(1,1)
		,	LoginName		varchar(200)
		,	DB				varchar(200)
		,	UserName		varchar(200)
		,	Deleted			bit
)

-- Add all user databases.
insert into #DBUsers
(			LoginName
		,	DB
		,	Deleted
)
select		@LoginName
		,	name
		,	1
from		sys.databases
where		name not in ('master','tempdb','model','msdb')
and			is_read_only = 0
and			[state] = 0 -- online
order by	name

----------------------------------------------------------
-- Add database level users (if they exist) for the login.
----------------------------------------------------------
set @counter = (select min(ID) from #DBUsers)

while exists (select 1 from #DBUsers where ID >= @counter)
begin
	set @dbname = (select DB from #DBUsers where ID = @counter)
	set @sql = '
	update		temp
	set			temp.UserName = users.name
	from		sys.server_principals						as logins
	inner join	[' + @dbname + '].sys.database_principals	as users
				on users.sid = logins.sid
				and logins.name = ''' + @LoginName + '''
	inner join	#DBUsers									as temp
				on temp.DB = ''' + @dbname + ''''

	exec sp_executesql @sql
	
	set @counter = @counter + 1
end

-- Don't need databases where a login-corresponding user was not found.
delete		#DBUsers
where		UserName is null

----------------------------------------------------------
-- Now drop the users.
----------------------------------------------------------
set @counter = (select min(ID) from #DBUsers)

while exists (select 1 from #DBUsers where ID >= @counter)
begin
	select	@sql = 'use [' + DB + ']; drop user [' + UserName + ']'
	from	#DBUsers
	where	ID = @counter

	--select @sql
	begin try exec sp_executesql @sql end try begin catch end catch
	set @counter = @counter + 1
end

----------------------------------------------------------
-- Report on which users were/were not dropped.
----------------------------------------------------------
set @counter = (select min(ID) from #DBUsers)

while exists (select 1 from #DBUsers where ID >= @counter)
begin
	set @dbname = (select DB from #DBUsers where ID = @counter)
	set @sql = '
	update		temp
	set			temp.Deleted = 0
	from		sys.server_principals						as logins
	inner join	[' + @dbname + '].sys.database_principals	as users
				on users.sid = logins.sid
				and logins.name = ''' + @LoginName + '''
	inner join	#DBUsers									as temp
				on temp.DB = ''' + @dbname + ''''

	exec sp_executesql @sql
	
	set @counter = @counter + 1
end

-- This shows the users that were/were not dropped, and the database they belong to.
if exists (select 1 from #DBUsers)
begin
	select		LoginName
			,	[Database]		= DB
			,	UserName		= UserName
			,	Deleted			= case Deleted when 1 then 'Yes' else 'No !!!!!!' end
	from		#DBUsers
	order by	DB
end
else
begin
	select [No Users Found] = 'No database-level users found on any database for the login "' + @LoginName + '".'
end

/*===================================================================================================
Not automatically dropping the login. If there are database level users that were not dropped, 
dropping the login will create orphaned users. Enable at your discretion.
=====================================================================================================*/
/*
set @sql = 'drop login [' + @LoginName + ']'
exec sp_executesql @sql
*/
