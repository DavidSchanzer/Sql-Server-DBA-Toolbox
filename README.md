<a name="header1"></a>
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
- [Extended Events](#extended-events)
- [Fragmentation](#fragmentation)
- [Indexing](#indexing)
- [Low-Level](#low-level)
- [Operational](#operational)
- [Parallelism](#parallelism)
- [Performance](#performance)
- [Permissions](#permissions)
- [Plan Cache](#plan-cache)
- [Query Store](#query-store)
- [Security](#security)
- [Statistics](#statistics)
- [TempDB](#tempdb)
- [VLFs](#vlfs)

[*Back to top*](#header1)

### Age Calculation
- [Calculating Age in Years](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Age%20Calculation/Calculating%20Age%20in%20Years.sql) (*a simple way to calculate someone’s current age, or age as at a particular date*)

[*Back to top*](#header1)

### Agent Jobs
- [Change the SQL Agent job history purge period from 30 days to 90 days in the Ola Hallengren sp_purge_jobhistory job](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Agent%20Jobs/Change%20the%20SQL%20Agent%20job%20history%20purge%20period%20from%2030%20days%20to%2090%20days%20in%20the%20Ola%20Hallengren%20sp_purge_jobhistory%20job.sql)
- [Remove the @StatisticsSample parameter for all Ola Hallengren IndexOptimize - USER_DATABASES jobs](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Agent%20Jobs/Remove%20the%20%40StatisticsSample%20parameter%20for%20all%20Ola%20Hallengren%20IndexOptimize%20-%20USER_DATABASES%20jobs.sql)
- [List running jobs in SQL Server with Job Start Time](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Agent%20Jobs/List%20running%20jobs%20in%20SQL%20Server%20with%20Job%20Start%20Time.sql)

[*Back to top*](#header1)

### Auditing
- [Create audit for database](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Auditing/Create%20audit%20for%20database.sql)
- [Drop server audits for which there is no corresponding database](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Auditing/Drop%20server%20audits%20for%20which%20there%20is%20no%20corresponding%20database.sql)
- [Query an audit file](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Auditing/Query%20an%20audit%20file.sql)

[*Back to top*](#header1)

### Availability Groups
- [Failover all Availability Groups](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Availability%20Groups/Failover%20all%20Availability%20Groups.sql)
- [Manually add database to an AG - needed for databases with a database master key](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Availability%20Groups/Manually%20add%20database%20to%20an%20AG%20-%20needed%20for%20databases%20with%20a%20database%20master%20key.sql)
- [Read-only routing url generation script](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Availability%20Groups/Read-only%20routing%20url%20generation%20script.sql)
- [View read-only routing configurations](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Availability%20Groups/View%20read-only%20routing%20configurations.sql)

[*Back to top*](#header1)

### Backup and Restore
- [Generate RESTORE script for all user databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Backup%20and%20Restore/Generate%20RESTORE%20script%20for%20all%20user%20databases.sql)
- [Progress of BACKUP and RESTORE](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Backup%20and%20Restore/Progress%20of%20BACKUP%20and%20RESTORE.sql)
- [sp_RestoreGene - generate RESTORE DATABASE commands](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Backup%20and%20Restore/sp_RestoreGene%20-%20generate%20RESTORE%20DATABASE%20commands.sql)
- [Update database backup schedules](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Backup%20and%20Restore/Update%20database%20backup%20schedules.sql)

[*Back to top*](#header1)

### Collation
- [Changing Database Collation](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Collation/Changing%20Database%20Collation.sql)

[*Back to top*](#header1)

### Compliance
- [Find deprecated data types on all databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Compliance/Find%20deprecated%20data%20types%20on%20all%20databases.sql)
- [SQL Server naming and design standards compliance review](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Compliance/SQL%20Server%20naming%20and%20design%20standards%20compliance%20review.sql)

[*Back to top*](#header1)

### Compression
- [Find indexes that aren't compressed in all databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Compression/Find%20indexes%20that%20aren't%20compressed%20in%20all%20databases.sql)
- [Suggest compression strategies for tables and indexes](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Compression/Suggest%20compression%20strategies%20for%20tables%20and%20indexes.sql)
- [Tracking page compression success rates](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Compression/Tracking%20page%20compression%20success%20rates.sql)

[*Back to top*](#header1)

### Configuration
- [0 to 60 - Switching to indirect checkpoints](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/0%20to%2060%20-%20Switching%20to%20indirect%20checkpoints.sql)
- [Adding trace flags to a SQL instance through Registry](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Adding%20trace%20flags%20to%20a%20SQL%20instance%20through%20Registry.sql)
- [Check for Instant File Initialization](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Check%20for%20Instant%20File%20Initialization.sql)
- [Check for Locked Pages In Memory](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Check%20for%20Locked%20Pages%20In%20Memory.sql)
- [Correct database file logical names](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Correct%20database%20file%20logical%20names.sql)
- [Correct database file physical names](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Correct%20database%20file%20physical%20names.sql)
- [Determine SQL Server version and edition](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Determine%20SQL%20Server%20version%20and%20edition.sql)
- [Find all instances that have all databases offline (to be run against all instances using a Central Management Server)](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20all%20instances%20that%20have%20all%20databases%20offline%20(to%20be%20run%20against%20all%20instances%20using%20a%20Central%20Management%20Server).sql)
- [Find database for a nominated data file](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20database%20for%20a%20nominated%20data%20file.sql)
- [Find databases at the wrong compatibility level](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20databases%20at%20the%20wrong%20compatibility%20level.sql)
- [Find databases that don't have Accelerated Database Recovery enabled](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20databases%20that%20don't%20have%20Accelerated%20Database%20Recovery%20enabled.sql)
- [Find databases with LEGACY_CARDINALITY_ESTIMATION turned on](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20databases%20with%20LEGACY_CARDINALITY_ESTIMATION%20turned%20on.sql)
- [Find databases with non-standard Automatic Tuning settings](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20databases%20with%20non-standard%20Automatic%20Tuning%20settings.sql)
- [Find databases with non-standard Query Store settings](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20databases%20with%20non-standard%20Query%20Store%20settings.sql)
- [Find non-default configuration options](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20non-default%20configuration%20options.sql)
- [Find SQL Server service info](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20SQL%20Server%20service%20info.sql)
- [Generate script to change all users to have default schema of dbo](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Generate%20script%20to%20change%20all%20users%20to%20have%20default%20schema%20of%20dbo.sql)
- [Find databases with default auto-growth values](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Find%20databases%20with%20default%20auto-growth%20values.sql)
- [Set all databases offline](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20offline.sql)
- [Set all databases to 130 compatibility level](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20130%20compatibility%20level.sql)
- [Set all databases to 140 compatibility level](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20140%20compatibility%20level.sql)
- [Set all databases to 150 compatibility level](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20150%20compatibility%20level.sql)
- [Set all databases to auto-grow data files by 100MB](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20auto-grow%20data%20files%20by%20100MB.sql)
- [Set all databases to auto-grow log files by 100MB](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20auto-grow%20log%20files%20by%20100MB.sql)
- [Set all databases to be owned by sa](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20be%20owned%20by%20sa.sql)
- [Set all databases to CHECKSUM page verification](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20CHECKSUM%20page%20verification.sql)
- [Set all databases to have Automatic Tuning with Force Last Good Plan turned on](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20have%20Automatic%20Tuning%20with%20Force%20Last%20Good%20Plan%20turned%20on.sql)
- [Set all databases to have Query Store enabled with query_capture_mode set to Auto](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20have%20Query%20Store%20enabled%20with%20query_capture_mode%20set%20to%20Auto.sql)
- [Set all databases to maximum compatibility level](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20maximum%20compatibility%20level.sql)
- [Set all databases to simple recovery](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20databases%20to%20simple%20recovery.sql)
- [Set all jobs to be owned by sa](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20all%20jobs%20to%20be%20owned%20by%20sa.sql)
- [Set AUTO_CREATE_STATISTICS and AUTO_UPDATE_STATISTICS ON for all databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20AUTO_CREATE_STATISTICS%20and%20AUTO_UPDATE_STATISTICS%20ON%20for%20all%20databases.sql)
- [Set fillfactor to 100](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20fillfactor%20to%20100.sql)
- [Set notification for all jobs to email SQL Administrator](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/Set%20notification%20for%20all%20jobs%20to%20email%20SQL%20Administrator.sql)
- [sp_foreachdb](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/sp_foreachdb.sql)
- [sp_ineachdb](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Configuration/sp_ineachdb.sql)

[*Back to top*](#header1)

### Constraints
- [Create indexes on all foreign keys](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Constraints/Create%20indexes%20on%20all%20foreign%20keys.sql)
- [Drop and re-create all foreign key constraints in SQL Server](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Constraints/Drop%20and%20re-create%20all%20foreign%20key%20constraints%20in%20SQL%20Server.sql)
- [Find all non-indexed foreign keys](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Constraints/Find%20all%20non-indexed%20foreign%20keys.sql)
- [Find foreign keys and check constraints that are not trusted](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Constraints/Find%20foreign%20keys%20and%20check%20constraints%20that%20are%20not%20trusted.sql)
- [Re-trust untrusted foreign keys](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Constraints/Re-trust%20untrusted%20foreign%20keys.sql)
- [Run DBCC CHECKCONSTRAINTS for all foreign key and check constraints](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Constraints/Run%20DBCC%20CHECKCONSTRAINTS%20for%20all%20foreign%20key%20and%20check%20constraints.sql)

[*Back to top*](#header1)

### Corruption
- [Emergency repair for when Windows Update leaves a FileStream database in Recovery Pending](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Corruption/Emergency%20repair%20for%20when%20Windows%20Update%20leaves%20a%20FileStream%20database%20in%20Recovery%20Pending.sql)

[*Back to top*](#header1)

### Database Design
- [Identity values check](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Database%20Design/Identity%20values%20check.sql)
- [spa_ShrinkColumnSizes](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Database%20Design/spa_ShrinkColumnSizes.sql)

[*Back to top*](#header1)

### Deadlocks
- [List deadlocks using the system_health Extended Events session](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Deadlocks/List%20deadlocks%20using%20the%20system_health%20Extended%20Events%20session.sql)

[*Back to top*](#header1)

### Disk Space
- [All files ordered by descending free space](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/All%20files%20ordered%20by%20descending%20free%20space.sql)
- [DBCC SHRINKFILE iteratively](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/DBCC%20SHRINKFILE%20iteratively.sql)
- [Find all Heaps ordered by increasing size and generate CCI SQL](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/Find%20all%20Heaps%20ordered%20by%20increasing%20size%20and%20generate%20CCI%20SQL.sql)
- [Find largest table in all databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/Find%20largest%20table%20in%20all%20databases.sql)
- [Get all databases sizes](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/Get%20all%20databases%20sizes.sql)
- [List all Clustered Columnstore indexes](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/List%20all%20Clustered%20Columnstore%20indexes.sql)
- [Move Primary data file](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/Move%20Primary%20data%20file.sql)
- [Shrink all log files over 1000 MB to 1000 MB](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/Shrink%20all%20log%20files%20over%201000%20MB%20to%201000%20MB.sql)
- [Turn all Heaps into Clustered Columnstore with Archive Compression](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Disk%20Space/Turn%20all%20Heaps%20into%20Clustered%20Columnstore%20with%20Archive%20Compression.sql)

[*Back to top*](#header1)

### Extended Events
- [Capture execution plan warnings using Extended Events](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Capture%20execution%20plan%20warnings%20using%20Extended%20Events.sql)
- [Extended Events session DurationOver500ms](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Extended%20Events%20session%20DurationOver500ms.sql)
- [Identifying large queries using Extended Events](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Identifying%20large%20queries%20using%20Extended%20Events.sql)
- [List all extended events sessions and whether they are running](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/List%20all%20extended%20events%20sessions%20and%20whether%20they%20are%20running.sql)
- [Looking for undesirable events](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Looking%20for%20undesirable%20events.sql)
- [Monitoring blocked processes with Extended Events](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Monitoring%20blocked%20processes%20with%20Extended%20Events.sql)
- [Monitoring errors with Extended Events](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Monitoring%20errors%20with%20Extended%20Events.sql)
- [Track activity on a table using the Lock_Acquired event](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Track%20activity%20on%20a%20table%20using%20the%20Lock_Acquired%20event.sql)
- [Track activity on a table](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Track%20activity%20on%20a%20table.sql)
- [Track calls to a stored procedure using a wildcard](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Track%20calls%20to%20a%20stored%20procedure%20using%20a%20wildcard.sql)
- [Tracking problematic page splits in Extended Events](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Extended%20Events/Tracking%20problematic%20page%20splits%20in%20Extended%20Events.sql)

[*Back to top*](#header1)

### Fragmentation
- [Rebuild active heaps](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Fragmentation/Rebuild%20active%20heaps.sql)

[*Back to top*](#header1)

### Indexing
- [Find columnstore indexes than are more than 10 percent fragmented](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20columnstore%20indexes%20than%20are%20more%20than%2010%20percent%20fragmented.sql)
- [Find duplicate indexes using sp_SQLskills_finddupes](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20duplicate%20indexes%20using%20sp_SQLskills_finddupes.sql)
- [Find large tables for potential Clustered Columnstore Indexes](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20large%20tables%20for%20potential%20Clustered%20Columnstore%20Indexes.sql)
- [Find missing indexes from the Missing Index DMVs](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20missing%20indexes%20from%20the%20Missing%20Index%20DMVs.sql)
- [Find missing indexes from the Plan Cache](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20missing%20indexes%20from%20the%20Plan%20Cache.sql)
- [Find missing indexes from the Query Store](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20missing%20indexes%20from%20the%20Query%20Store.sql)
- [Find queries that use an index from the Plan Cache](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20queries%20that%20use%20an%20index%20from%20the%20Plan%20Cache.sql)
- [Find queries that use an index from the Query Store](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20queries%20that%20use%20an%20index%20from%20the%20Query%20Store.sql)
- [Find tables without a primary key or clustered index](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20tables%20without%20a%20primary%20key%20or%20clustered%20index.sql)
- [Find unused indexes from sys.dm_db_index_usage_stats](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20unused%20indexes%20from%20sys.dm_db_index_usage_stats.sql)
- [Find unused non-clustered indexes by checking Query Store](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Find%20unused%20non-clustered%20indexes%20by%20checking%20Query%20Store.sql)
- [Identifying which databases have index fragmentation problems](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Identifying%20which%20databases%20have%20index%20fragmentation%20problems.sql)
- [Modify all fillfactors from 70 to 100](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Modify%20all%20fillfactors%20from%2070%20to%20100.sql)
- [Rebuild all fragmented heaps](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/Rebuild%20all%20fragmented%20heaps.sql)
- [SQLSkills index script 1 - sp_SQLskills_exposecolsinindexlevels](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/SQLSkills%20index%20script%201%20-%20sp_SQLskills_exposecolsinindexlevels.sql)
- [SQLSkills index script 2 - sp_SQLskills_helpindex](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/SQLSkills%20index%20script%202%20-%20sp_SQLskills_helpindex.sql)
- [SQLSkills index script 3 - sp_SQLskills_finddupes (modified)](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Indexing/SQLSkills%20index%20script%203%20-%20sp_SQLskills_finddupes%20(modified).sql)

[*Back to top*](#header1)

### Low-Level
- [Find table from page](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Low-Level/Find%20table%20from%20page.sql)
- [How far has my update got](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Low-Level/How%20far%20has%20my%20update%20got.sql)

[*Back to top*](#header1)

### Operational
- [Create a text file with specified contents](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Operational/Create%20a%20text%20file%20with%20specified%20contents.sql)
- [Last instance restart date](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Operational/Last%20instance%20restart%20date.sql)
- [List of all server names from the DBA_REP ServerList_SSIS table](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Operational/List%20of%20all%20server%20names%20from%20the%20DBA_REP%20ServerList_SSIS%20table.sql)
- [Locks summary](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Operational/Locks%20summary.sql)
- [Open transactions with text and plans](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Operational/Open%20transactions%20with%20text%20and%20plans.sql)
- [Query the Default Trace](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Operational/Query%20the%20Default%20Trace.sql)

[*Back to top*](#header1)

### Parallelism
- [Calculate MAXDOP](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Parallelism/Calculate%20MAXDOP.sql)
- [Cost Threshold For Parallelism - Plan Cache spread of query costs](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Parallelism/Cost%20Threshold%20For%20Parallelism%20-%20Plan%20Cache%20spread%20of%20query%20costs.sql)
- [Determining a setting for Cost Threshold for Parallelism](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Parallelism/Determining%20a%20setting%20for%20Cost%20Threshold%20for%20Parallelism.sql)
- [MAXDOP setting algorithm for SQL Server](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Parallelism/MAXDOP%20setting%20algorithm%20for%20SQL%20Server.sql)
- [Recommend MAXDOP settings for the server instance](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Parallelism/Recommend%20MAXDOP%20settings%20for%20the%20server%20instance.sql)

[*Back to top*](#header1)

### Performance
- [Analyzing 'death by a thousand cuts' workloads](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Analyzing%20'death%20by%20a%20thousand%20cuts'%20workloads.sql)
- [Breakdown of buffer cache usage by database](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Breakdown%20of%20buffer%20cache%20usage%20by%20database.sql)
- [Breakdown of buffer cache usage for a specific database](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Breakdown%20of%20buffer%20cache%20usage%20for%20a%20specific%20database.sql)
- [Calculate rows inserted per second for all tables](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Calculate%20rows%20inserted%20per%20second%20for%20all%20tables.sql)
- [Find mismatching column types in database schema](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Find%20mismatching%20column%20types%20in%20database%20schema.sql)
- [Find non-zero fill factors for identity columns (set back to 100)](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Find%20non-zero%20fill%20factors%20for%20identity%20columns%20(set%20back%20to%20100).sql)
- [Find non-zero fill factors](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Find%20non-zero%20fill%20factors.sql)
- [Finding the worst-performing TSQL statement](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Finding%20the%20worst-performing%20TSQL%20statement.sql)
- [Finding the worst running query in a stored procedure](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Finding%20the%20worst%20running%20query%20in%20a%20stored%20procedure.sql)
- [sp_WhoIsActive extended info](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/sp_WhoIsActive%20extended%20info.sql)
- [sp_WhoIsActive in a loop](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/sp_WhoIsActive%20in%20a%20loop.sql)
- [sp_WhoIsActive](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/sp_WhoIsActive.sql)
- [Wait statistics, or please tell me where it hurts - Paul Randal](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Performance/Wait%20statistics%2C%20or%20please%20tell%20me%20where%20it%20hurts%20-%20Paul%20Randal.sql)

[*Back to top*](#header1)

### Permissions
- [Find all permissions & access for all users in all databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Permissions/Find%20all%20permissions%20%26%20access%20for%20all%20users%20in%20all%20databases.sql)
- [Fix all orphaned users in all databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Permissions/Fix%20all%20orphaned%20users%20in%20all%20databases.sql)
- [Script DB level permissions](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Permissions/Script%20DB%20level%20permissions.sql)
- [SQL Server permissions list for read and write access for all databases](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Permissions/SQL%20Server%20permissions%20list%20for%20read%20and%20write%20access%20for%20all%20databases.sql)

[*Back to top*](#header1)

### Plan Cache
- [Find your most expensive queries in the Plan Cache](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Find%20your%20most%20expensive%20queries%20in%20the%20Plan%20Cache.sql)
- [Plan Cache queries - find queries using a specific index](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20find%20queries%20using%20a%20specific%20index.sql)
- [Plan Cache queries - find queries using any index hint](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20find%20queries%20using%20any%20index%20hint.sql)
- [Plan Cache queries - implicit column conversions](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20implicit%20column%20conversions.sql)
- [Plan Cache queries - index scans](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20index%20scans.sql)
- [Plan Cache queries - key lookups](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20key%20lookups.sql)
- [Plan Cache queries - missing index](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20missing%20index.sql)
- [Plan Cache queries - probe residuals](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20probe%20residuals.sql)
- [Plan Cache queries - query plans that may utilize parallelism](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20query%20plans%20that%20may%20utilize%20parallelism.sql)
- [Plan Cache queries - warnings](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Plan%20Cache/Plan%20Cache%20queries%20-%20warnings.sql)

[*Back to top*](#header1)

### Query Store
- [Mining the Query Store - looking for index usage in queries](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Query%20Store/Mining%20the%20Query%20Store%20-%20looking%20for%20index%20usage%20in%20queries.sql)
- [Mining the Query Store - looking for Key Lookups in queries](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Query%20Store/Mining%20the%20Query%20Store%20-%20looking%20for%20Key%20Lookups%20in%20queries.sql)
- [Mining the Query Store - looking for text strings in queries](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Query%20Store/Mining%20the%20Query%20Store%20-%20looking%20for%20text%20strings%20in%20queries.sql)
- [Most expensive queries using Query Store](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Query%20Store/Most%20expensive%20queries%20using%20Query%20Store.sql)
- [sp_QuickieStore - Erik Darling](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Query%20Store/sp_QuickieStore%20-%20Erik%20Darling.sql)

[*Back to top*](#header1)

### Security
- [Create logins on AlwaysOn Secondary with same SID as Primary](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Create%20logins%20on%20AlwaysOn%20Secondary%20with%20same%20SID%20as%20Primary.sql)
- [Delete all database user accounts for a given server login](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Delete%20all%20database%20user%20accounts%20for%20a%20given%20server%20login.sql)
- [Drop all orphan users](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Drop%20all%20orphan%20users.sql)
- [Enumerate Windows Group members](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Enumerate%20Windows%20Group%20members.sql)
- [Find all orphaned SQL Server users](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Find%20all%20orphaned%20SQL%20Server%20users.sql)
- [Find Windows logins that are no longer in AD](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Find%20Windows%20logins%20that%20are%20no%20longer%20in%20AD.sql)
- [Last user access for each database](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Last%20user%20access%20for%20each%20database.sql)
- [Orphaned users search and destroy](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Orphaned%20users%20search%20and%20destroy.sql)
- [Who are the sysadmins in this Instance](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Security/Who%20are%20the%20sysadmins%20in%20this%20Instance.sql)

[*Back to top*](#header1)

### Statistics
- [Drop all statistics](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Statistics/Drop%20all%20statistics.sql)
- [Find auto-created statistics objects that overlap with index statistics](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Statistics/Find%20auto-created%20statistics%20objects%20that%20overlap%20with%20index%20statistics.sql)
- [Generate DROP STATISTICS statements for all user-created statistics](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/Statistics/Generate%20DROP%20STATISTICS%20statements%20for%20all%20user-created%20statistics.sql)

[*Back to top*](#header1)

### TempDB
- [Find tempdb data files with differing sizes](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/TempDB/Find%20tempdb%20data%20files%20with%20differing%20sizes.sql)
- [Find tempdbs with uneven initial size or growth](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/TempDB/Find%20tempdbs%20with%20uneven%20initial%20size%20or%20growth.sql)
- [Who owns that #temp table](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/TempDB/Who%20owns%20that%20%23temp%20table.sql)

[*Back to top*](#header1)

### VLFs
- [Detect too many VLFs](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/VLFs/Detect%20too%20many%20VLFs.sql)
- [Reduce VLF count](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/VLFs/Reduce%20VLF%20count.sql)
- [Visualizing VLFs](https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox/blob/main/VLFs/Visualizing%20VLFs.sql)

[*Back to top*](#header1)

