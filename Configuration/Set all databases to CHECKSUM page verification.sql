EXEC sp_foreachdb 'ALTER DATABASE ? SET PAGE_VERIFY CHECKSUM  WITH NO_WAIT',
                  @user_only = 1;