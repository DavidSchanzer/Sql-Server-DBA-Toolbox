-- Find non-default configuration options
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists any non-standard instance-level settings

DECLARE @config_defaults TABLE
(
    name NVARCHAR(35) NOT NULL,
    default_value SQL_VARIANT NOT NULL
);

INSERT INTO @config_defaults (name, default_value)
VALUES ( 'access check cache bucket count', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'access check cache quota', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'Ad Hoc Distributed Queries', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'affinity I/O mask', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'affinity mask', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'affinity64 mask', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'affinity64 I/O mask', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'Agent XPs', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'allow updates', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'awe enabled', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'backup checksum default', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'backup compression default', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'blocked process threshold', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'blocked process threshold (s)', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'c2 audit mode', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'clr enabled', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'common criteria compliance enabled', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'contained database authentication', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'cost threshold for parallelism', 5 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'cross db ownership chaining', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'cursor threshold', -1 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'Database Mail XPs', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'default full-text language', 1033 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'default language', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'default trace enabled', 1 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'disallow results from triggers', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'EKM provider enabled', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'filestream access level', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'fill factor (%)', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'ft crawl bandwidth (max)', 100 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'ft crawl bandwidth (min)', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'ft notify bandwidth (max)', 100 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'ft notify bandwidth (min)', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'index create memory (KB)', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'in-doubt xact resolution', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'lightweight pooling', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'locks', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'max degree of parallelism', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'max full-text crawl range', 4 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'max server memory (MB)', 2147483647 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'max text repl size (B)', 65536 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'max worker threads', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'media retention', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'min memory per query (KB)', 1024 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'min server memory (MB)', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'nested triggers', 1 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'network packet size (B)', 4096 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'Ole Automation Procedures', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'open objects', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'optimize for ad hoc workloads', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'PH timeout (s)', 60 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'precompute rank', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'priority boost', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'query governor cost limit', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'query wait (s)', -1 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'recovery interval (min)', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'remote access', 1 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'remote admin connections', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'remote login timeout (s)', 10 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'remote proc trans', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'remote query timeout (s)', 600 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'Replication XPs', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'RPC parameter data validation', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'scan for startup procs', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'server trigger recursion', 1 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'set working set size', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'show advanced options', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'SMO and DMO XPs', 1 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'SQL Mail XPs', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'transform noise words', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'two digit year cutoff', 2049 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'user connections', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'user options', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'Web Assistant Procedures', 0 );
INSERT INTO @config_defaults (name, default_value)
VALUES ( 'xp_cmdshell', 0 );

SELECT c.name,
       c.value,
       c.value_in_use,
       d.default_value
FROM sys.configurations c
    INNER JOIN @config_defaults d
        ON c.name = d.name
WHERE c.value <> c.value_in_use
      OR c.value_in_use <> d.default_value;
GO
