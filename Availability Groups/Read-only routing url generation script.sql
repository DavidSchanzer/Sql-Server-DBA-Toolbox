-- Read-only routing url generation script
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script connects to each replica in your AlwaysOn cluster and run this script to get the read_only_routing_url for the replica. 
-- Then set this to the read_only_routing_url for the availability group replica => 
--    alter availability group MyAvailabilityGroup modify replica on N'ThisReplica' with (secondary_role(read_only_routing_url=N'<url>')) 
-- From http://blogs.msdn.com/b/mattn/archive/2012/04/25/calculating-read-only-routing-url-for-alwayson.aspx

PRINT 'Read-only-routing url script v.2012.1.24.1';

PRINT 'This SQL Server instance version is [' + CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(256)) + ']';

IF (SERVERPROPERTY('IsClustered') = 1)
BEGIN
    PRINT 'This SQL Server instance is a clustered SQL Server instance.';
END;
ELSE
BEGIN
    PRINT 'This SQL Server instance is a standard (not clustered) SQL Server instance.';
END;

IF (SERVERPROPERTY('IsHadrEnabled') = 1)
BEGIN
    PRINT 'This SQL Server instance is enabled for AlwaysOn.';
END;
ELSE
BEGIN
    PRINT 'This SQL Server instance is NOT enabled for AlwaysOn.';
END;

-- Detect SQL Azure instance. 
DECLARE @is_sql_azure BIT;
SET @is_sql_azure = 0;

BEGIN TRY
    SET @is_sql_azure = 1;
    EXEC ('declare @i int set @i = sql_connection_mode()');
    PRINT 'This SQL Server instance is a Sql Azure instance.';
END TRY
BEGIN CATCH
    SET @is_sql_azure = 0;
    PRINT 'This SQL Server instance is NOT a Sql Azure instance.';
END CATCH;

-- Check that this is SQL 11 or later, otherwise fail fast. 
IF (@@microsoftversion / 0x01000000 < 11 OR @is_sql_azure > 0)
BEGIN
    PRINT 'This SQL Server instance does not support read-only routing, exiting script.';
END;
ELSE
BEGIN -- if server supports read-only routing

    -- Fetch the dedicated admin connection (dac) port. 
    -- Normally it's always port 1434, but to be safe here we fetch it from the instance. 
    -- We use this later to exclude the admin port from read_only_routing_url. 
    DECLARE @dac_port INT;
    DECLARE @reg_value VARCHAR(255);
    EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE',
                             N'SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQLServer\SuperSocketNetLib\AdminConnection\Tcp',
                             N'TcpDynamicPorts',
                             @reg_value OUTPUT;

    SET @dac_port = CAST(@reg_value AS INT);

    PRINT 'This SQL Server instance DAC (dedicated admin) port is ' + CAST(@dac_port AS VARCHAR(255));
    IF (@dac_port = 0)
    BEGIN
        PRINT 'Note a DAC port of zero means the dedicated admin port is not enabled.';
    END;

    -- Fetch ListenOnAllIPs value. 
    -- If set to 1, this means the instance is listening to all IP addresses. 
    -- If set to 0, this means the instance is listening to specific IP addresses. 
    DECLARE @listen_all INT;
    EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE',
                             N'SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQLServer\SuperSocketNetLib\Tcp',
                             N'ListenOnAllIPs',
                             @listen_all OUTPUT;

    IF (@listen_all = 1)
    BEGIN
        PRINT 'This SQL Server instance is listening to all IP addresses (default mode).';
    END;
    ELSE
    BEGIN
        PRINT 'This SQL Server instance is listening to specific IP addresses (ListenOnAllIPs is disabled).';
    END;

    -- Check for dynamic port configuration, not recommended with read-only routing. 
    DECLARE @tcp_dynamic_ports VARCHAR(255);
    EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE',
                             N'SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQLServer\SuperSocketNetLib\Tcp\IPAll',
                             N'TcpDynamicPorts',
                             @tcp_dynamic_ports OUTPUT;

    IF (@tcp_dynamic_ports = '0')
    BEGIN
        PRINT 'This SQL Server instance is listening on a dynamic tcp port, this is NOT A RECOMMENDED CONFIGURATION when using read-only routing, because the instance port can change each time the instance is restarted.';
    END;
    ELSE
    BEGIN
        PRINT 'This SQL Server instance is listening on fixed tcp port(s) (it is not configured for dynamic ports), this is a recommended configuration when using read-only routing.';
    END;

    -- Calculate the server domain and instance FQDN. 
    -- We use @server_domain later to build the FQDN to the clustered instance. 
    DECLARE @instance_fqdn VARCHAR(255);
    DECLARE @server_domain VARCHAR(255);

    -- Get the instance FQDN using the xp_getnetname API 
    -- Note all cluster nodes must be in same domain, so this works for calculating cluster FQDN. 
    SET @instance_fqdn = '';
    EXEC xp_getnetname @instance_fqdn OUTPUT, 1;

    -- Remove embedded null character at end if found. 
    DECLARE @terminator INT;
    SET @terminator = CHARINDEX(CHAR(0), @instance_fqdn) - 1;
    IF (@terminator > 0)
    BEGIN
        SET @instance_fqdn = SUBSTRING(@instance_fqdn, 1, @terminator);
    END;

    -- Build @server_domain using @instance_fqdn. 
    SET @server_domain = @instance_fqdn;

    -- Remove trailing portion to extract domain name. 
    SET @terminator = CHARINDEX('.', @server_domain);
    IF (@terminator > 0)
    BEGIN
        SET @server_domain = SUBSTRING(@server_domain, @terminator + 1, DATALENGTH(@server_domain));
    END;
    PRINT 'This SQL Server instance resides in domain ''' + @server_domain + '''';

    IF (SERVERPROPERTY('IsClustered') = 1)
    BEGIN
        -- Fetch machine name, which for a clustered SQL instance returns the network name of the virtual server. 
        -- Append @server_domain to build the FQDN. 
        SET @instance_fqdn = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(255)) + '.' + @server_domain;
    END;

    DECLARE @ror_url VARCHAR(255);
    DECLARE @instance_port INT;

    SET @ror_url = '';

    -- Get first available port for instance. 
    SELECT TOP (1) -- Select first matching port 
           @instance_port = port
    FROM sys.dm_tcp_listener_states
    WHERE type = 0 -- Type 0 = TSQL (to avoid mirroring endpoint) 
          AND state = 0 --  State 0 is online    
          AND port <> @dac_port -- Avoid DAC port (admin port) 
          AND
        -- Avoid availability group listeners 
        ip_address NOT IN
        (
            SELECT ip_address FROM sys.availability_group_listener_ip_addresses agls
        )
    GROUP BY port
    ORDER BY port ASC; -- Pick first port in ascending order

    -- Check if there are multiple ports and warn if this is the case. 
    DECLARE @list_of_ports VARCHAR(MAX);
    SET @list_of_ports = '';

    SELECT @list_of_ports = @list_of_ports + CASE DATALENGTH(@list_of_ports)
                                                 WHEN 0 THEN
                                                     CAST(port AS VARCHAR(MAX))
                                                 ELSE
                                                     ',' + CAST(port AS VARCHAR(MAX))
                                             END
    FROM sys.dm_tcp_listener_states
    WHERE type = 0 --     Type 0 = TSQL (to avoid mirroring endpoint) 
          AND state = 0 --  State 0 is online    
          AND port <> @dac_port -- Avoid DAC port (admin port) 
          AND
        -- Avoid availability group listeners 
        ip_address NOT IN
        (
            SELECT ip_address FROM sys.availability_group_listener_ip_addresses agls
        )
    GROUP BY port
    ORDER BY port ASC;

    PRINT 'This SQL Server instance FQDN (Fully Qualified Domain Name) is ''' + @instance_fqdn + '''';
    PRINT 'This SQL Server instance port is ' + CAST(@instance_port AS VARCHAR(10));

    SET @ror_url = 'tcp://' + @instance_fqdn + ':' + CAST(@instance_port AS VARCHAR(10));

    PRINT '****************************************************************************************************************';
    PRINT 'The read_only_routing_url for this SQL Server instance is ''' + @ror_url + '''';
    PRINT '****************************************************************************************************************';

    -- If there is more than one instance port (unusual) list them out just in case. 
    IF (CHARINDEX(',', @list_of_ports) > 0)
    BEGIN
        PRINT 'Note there is more than one instance port, the list of available instance ports for read_only_routing_url is ('
              + @list_of_ports + ')';
        PRINT 'The above URL just uses the first port in the list, but you can use any of these available ports.';
    END;

END; -- if server supports read-only routing 
GO
