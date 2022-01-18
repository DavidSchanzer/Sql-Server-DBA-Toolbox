# Sql Server DBA Toolbox
Welcome to my box of tricks (SQL scripts) for Microsoft SQL Server instance and database administration!

I've put considerable effort, over many years, into creating my own scripts, as well as adapting the efforts of many other talented folk in the SQL Server community, to help with my day-to-day job as a Database Administrator on Microsoft SQL Server. Now that I'm approaching the twilight of my professional IT career, I wanted to ensure that this accumulated DBA knowledge store is not lost but is instead shared as widely as possible.

My experience is that **having the right tool for the job** is half the battle (*and knowing how to wield it is the other!*), and so I wanted to be able to share as widely as possible these tools that I use: some every day, some frequently, and some only occasionally. But they all deserve a place in my toolbox!

When faced with a SQL Server DBA challenge, don't re-invent the wheel or give it up as too hard: check my toolbox and the blogs of the many generous SQL giants out there on whose shoulders we stand!

I hope you find them useful.

## What's in the box?
- [Age Calculation](#age-calculation)
- [Agent Jobs](#agent-jobs)
- [Auditing](#auditing)
- [Availability Groups](#availability-groups)
- [Backup and Restore](#backup-and-restore)
- [Collation](#collation)
- [Compliance](#compliance)
- [Compression](#compression)
- [Configuration](#configuration)
- [Constraints](#constraints)
- [Corruption](#corruption)
- [Database Design](#database-design)
- [Deadlocks](#deadlocks)
- [Disk Space](#disk-space)
- [Edition](#edition)
- [Extended Events](#extended-events)
- [Foreign Keys](#foreign-keys)
- [Fragmentation](#fragmentation)
- [Indexing](#indexing)
- [Low-Level](#low-level)
- [Operational](#operational)
- [Parallelism](#parallelism)
- [Patching](#patching)
- [Performance](#performance)
- [Periodic audits](#periodic-audits)
- [Permissions](#permissions)
- [Plan Cache](#plan-cache)
- [Query Store](#query-store)
- [Security](#security)
- [Standard scripts for new installations](#standard-scripts-for-new-installations)
- [Statistics](#statistics)
- [Table Design](#table-design)
- [TempDB](#tempdb)
- [VLFs](#vlfs)

### Age Calculation
- Calculating Age in Years (*a simple way to calculate someone’s current age, or age as at a particular date*)

### Agent Jobs
- Change the SQL Agent job history purge period from 30 days to 90 days in the Ola Hallengren sp_purge_jobhistory job
- Remove the @StatisticsSample parameter for all Ola Hallengren IndexOptimize - USER_DATABASES jobs
- Script to see running jobs in SQL Server with Job Start Time

### Auditing
- Create audit for database
- Drop server audits for which there is no corresponding database
- Query an audit file

### Availability Groups
- Configure Read-Only Routing for an Availability Group
- Failover all Availability Groups
- Manually add database to an AG - needed for databases with a database master key
- Read-only routing url generation script
- View read-only routing configurations

### Backup and Restore
- Generate RESTORE script for all user databases
- Progress of BACKUP and RESTORE
- sp_RestoreGene - generate RESTORE DATABASE commands
- Update database backup schedules

### Collation
- Changing Database Collation

### Compliance
- Find deprecated data types on all databases
- SQL Server naming and design standards compliance review

### Compression
- Find indexes that aren't compressed in all databases
- Suggest compression strategies for tables and indexes
- Tracking page compression success rates

### Configuration
- 0 to 60 - Switching to indirect checkpoints
- Adding trace flags to a SQL instance through Registry
- Check for Instant File Initialization
- Check for Locked Pages In Memory
- Correct database file logical names
- Correct database file physical names
- Find all instances that have all databases offline (to be run against all instances)
- Find database for a nominated data file
- Find databases at the wrong compatibility level
- Find databases that don't have Accelerated Database Recovery enabled
- Find databases with LEGACY_CARDINALITY_ESTIMATION turned on
- Find databases with non-standard Automatic Tuning settings
- Find databases with non-standard Query Store settings
- Find non-default configuration options
- Find SQL Server service info
- Generate script to change all users to have default schema of dbo
- List databases with default auto-growth values
- Set all databases offline
- Set all databases to 130 compatibility level
- Set all databases to 140 compatibility level
- Set all databases to 150 compatibility level
- Set all databases to auto-grow data files by 100MB
- Set all databases to auto-grow log files by 100MB
- Set all databases to be owned by sa
- Set all databases to CHECKSUM page verification
- Set all databases to have Automatic Tuning with Force Last Good Plan turned on
- Set all databases to have Query Store enabled with query_capture_mode set to Auto
- Set all databases to maximum compatibility level
- Set all databases to simple recovery
- Set all jobs to be owned by sa
- Set AUTO_CREATE_STATISTICS and AUTO_UPDATE_STATISTICS ON for all databases
- Set fillfactor to 100
- Set notification for all jobs to email SQL Administrator
- sp_foreachdb
- sp_ineachdb

### Constraints
- DBCC CHECKCONSTRAINTS
- Find check constraints that are not trusted
- Find foreign keys that are not trusted
- List foreign keys and check constraints that are not trusted
- Re-trust untrusted foreign keys and constraints

### Corruption
- Emergency repair for when Windows Update leaves the database in Recovery Pending

### Database Design
- Identity values check

### Deadlocks
- List deadlocks using Extended Events

### Disk Space
- All files ordered by descending free space
- DBCC SHRINKFILE iteratively
- Find all Heaps ordered by increasing size and generate CCI SQL
- Find largest table in all databases
- Get all databases sizes
- List all Clustered Columnstore indexes
- Move Primary data file
- Shrink all log files over 1000 MB to 1000 MB
- Turn all Heaps into Clustered Columnstore with Archive Compression

### Edition
- Determine SQL Server version and edition

### Extended Events
- Capture execution plan warnings using Extended Events
- Extended Events session DurationOver500ms
- Identifying large queries using Extended Events
- Looking for undesirable events
- Monitoring blocked processes with Extended Events
- Monitoring errors with Extended Events
- Track activity on a table using the Lock_Acquired event3
- Track activity on a table
- Track calls to a stored procedure
- Track calls to a stored procedure using a wildcard
- Tracking problematic page splits in Extended Events

### Foreign Keys
- Drop and re-create all foreign key constraints in SQL Server

### Fragmentation
- Rebuild active heaps

### Indexing
- Create indexes on all foreign keys
- Find all non-indexed foreign keys
- Find columnstore indexes than are more than 10 percent fragmented
- Find duplicate indexes using sp_SQLskills_finddupes
- Find large tables for potential Clustered Columnstore Indexes
- Find missing indexes from the Missing Index DMVs
- Find missing indexes from the Plan Cache
- Find missing indexes from the Query Store
- Find queries that use an index
- Find queries using a specific index
- Find tables without a primary key or clustered index
- Find unused indexes from sys.dm_db_index_usage_stats
- Find unused non-clustered indexes by checking Query Store
- Identifying which databases have index fragmentation problems
- Modify all fillfactors from 70 to 100
- Rebuild all fragmented heaps
- SQLSkills index script 1 - 00 sp_SQLskills_exposecolsinindexlevels
- SQLSkills index script 2 - 01 sp_SQLskills_helpindex
- SQLSkills index script 3 - 02 sp_SQLskills_finddupes (modified)

### Low-Level
- Find table from page
- How far has my update got

### Operational
- Create a text file with specified contents
- Last instance restart date
- List of all server names from the DBA_REP ServerList_SSIS table
- Locks summary
- Open transactions with text and plans
- Query the Default Trace

### Parallelism
- Calculate MAXDOP
- Cost Threshold For Parallelism - Plan Cache spread of query costs
- Determining a setting for Cost Threshold for Parallelism
- MAXDOP setting algorithm for SQL Server
- Recommend MAXDOP settings for the server instance

### Patching
- Randomly assign a patch time on the agreed patch date for Prod and Non-Prod servers

### Performance
- Analyzing 'death by a thousand cuts' workloads
- Breakdown of buffer cache usage by database
- Breakdown of buffer cache usage for a specific database
- Calculate rows inserted per second for all tables
- Find mismatching column types in database schema
- Find non-zero fill factors for identity columns (set back to 100)
- Find non-zero fill factors
- Finding the worst-performing TSQL statement
- Finding the worst running query in a stored procedure
- Paul Randal - Wait statistics, or please tell me where it hurts
- sp_WhoIsActive extended info
- sp_WhoIsActive in a loop
- sp_WhoIsActive v12.00
- Waits and queues performance analysis - cumulative latches
- Waits and queues performance analysis - cumulative waits
- Waits and queues performance analysis - current spinlocks
- Waits and queues performance analysis - waiting tasks - create SQL Agent job that runs every 10 mins
- Waits and queues performance analysis - waiting tasks

### Periodic audits
- Find individual logins to be dropped
- Run sp_Blitz for all instances

### Permissions
- Find all permissions & access for all users in all databases
- Fix all orphaned users in all databases
- Script DB level permissions
- SQL Server permissions list for read and write access for all databases

### Plan Cache
- Find your most expensive queries in the Plan Cache
- Plan Cache queries - find queries using a specific index
- Plan Cache queries - find queries using any index hint
- Plan Cache queries - implicit column conversions
- Plan Cache queries - index scans
- Plan Cache queries - key lookups
- Plan Cache queries - missing index
- Plan Cache queries - probe residuals
- Plan Cache queries - query plans that may utilize parallelism
- Plan Cache queries - warnings

### Query Store
- Mining the Query Store - looking for index usage in queries
- Mining the Query Store - looking for Key Lookups in queries
- Mining the Query Store - looking for text strings in queries
- Most expensive queries using Query Store
- sp_QuickieStore - Erik Darling

### Security
- Create logins on AlwaysOn Secondary with same SID as Primary
- Delete all database user accounts for a given server login
- Drop all orphan users
- Enumerate Windows Group members
- Find all orphaned SQL Server users
- Find Windows logins that are no longer in AD
- Last user access for each database
- Orphaned users search and destroy
- Who are the sysadmins in this Instance

### Standard scripts for new installations
- Step 1 - Create an Operator
- Step 2 - Configure SQL Server Agent to use Database Mail profile
- Step 3 - Alerts for SQL Server
- Step 4 - Adding notifications
- Step 5 - AuditDatabaseDDL
- Step 6 - Optimize For Ad-Hoc Workloads and Cost Threshold For Parallelism
- Step 7 - Set database size and growth for some system databases
- Step 8 – Create login for DBA_Server_Info reports
- Step 9 – Enable remote DAC
- Step 10 – Configure failsafe operator
- Step 11 – Set 'Backup Compression Default' and 'Backup Checksum Default' on
- Step 12 – Add hourly SQL Agent job ClearSingleUsePlansFromCache
- Step 13 – Add SQL Agent job Cycle Errorlog Weekly
- Step 14 – Add SQL Agent job Patch SQL Server instance
- Step 15 – Add notification of SQL Server restarts
- Step 16 - Create SQL Agent job for sp_Blitz
- Step 17 - Create SQL Agent job for Compress Indexes
- Step 18 - Create SQL Agent job for Rebuild Active Heaps

### Statistics
- Drop all statistics
- Find auto-created statistics objects that overlap with index statistics
- Generate DROP STATISTICS statements for all user-created statistics

### Table Design
- spa_ShrinkColumnSizes

### TempDB
- Find tempdb data files with differing sizes
- Find tempdbs with uneven initial size or growth
- Who owns that #temp table

### VLFs
- Detect too many VLFs
- Reduce VLF count
- Visualizing VLFs
