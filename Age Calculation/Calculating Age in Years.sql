-- Calculating Age in Years
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script demonstrates a simple way to calculate someone’s current age, or age as at a particular date.
-- It formats each date as YYYYMMDD and converts this to an integer, then subtracts one integer from the other, and divides the result by 10,000.
-- It’s 10,000 because you’re trying to truncate the difference month and day components, leaving only the years.

DECLARE @DateOfBirth DATE = '1960/01/19',
        @CurrentDate DATE = GETDATE();

SELECT CurrentAge = DATEDIFF(DAY, @DateOfBirth, @CurrentDate) / 365;
