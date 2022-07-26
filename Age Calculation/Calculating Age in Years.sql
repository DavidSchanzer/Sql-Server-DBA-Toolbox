-- Calculating Age in Years
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script demonstrates a simple way to calculate someone’s current age, or age as at a particular date.
-- Counts the days between dates and devide by 365 (days per year)

DECLARE @DateOfBirth DATE = '1960/01/19',
        @CurrentDate DATE = GETDATE();

SELECT CurrentAge = DATEDIFF(DAY, @DateOfBirth, @CurrentDate) / 365;
