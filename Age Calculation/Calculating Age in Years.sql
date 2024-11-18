-- Calculating Age in Years 
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script demonstrates a simple way to calculate someone’s current age, or age as at a particular date.
-- It formats each date as YYYYMMDD and converts this to an integer, then subtracts one integer from the other, and divides the result by 10,000.
-- It’s 10,000 because you’re trying to truncate the difference between the month and day components, leaving only the years.

DECLARE @DateOfBirth DATE,
        @CurrentDate DATE = GETDATE();

SELECT CurrentAge = (CONVERT(INT, CONVERT(CHAR(8), @CurrentDate, 112))
                     - CONVERT(INT, CONVERT(CHAR(8), @DateOfBirth, 112))
                    ) / 10000;
