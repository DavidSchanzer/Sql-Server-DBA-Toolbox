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
- [Patching](#patching)
- [Performance](#performance)
- [Periodic audits](#periodic-audits)
- [Permissions](#permissions)
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
### Fragmentation
### Indexing
### Low-Level
### Operational
### Patching
### Performance
### Periodic audits
### Permissions
### Query Store
### Security
### Standard scripts for new installations
### Statistics
### Table Design
### TempDB
### VLFs
