EXEC sp_foreachdb 'ALTER DATABASE [?] SET OFFLINE', @user_only = 1;
