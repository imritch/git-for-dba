
/*************************************************************************************************************************
* Author: Ritesh Chawla
*
* Description: This script demonstrates how a high volume of very fast, low-CPU queries can overwhelm the SQL Server 
* scheduler, leading to high signal waits and causing significant performance degradation for other concurrent workloads.
* This phenomenon is often referred to as "death by a thousand cuts."
*
* Pre-requisites:
* 1. SQL Server Instance (any recent version).
* 2. RML Utilities for SQL Server, specifically ostress.exe. This is a free download from Microsoft.
*    You can find it by searching for "RML Utilities for SQL Server". Make sure ostress.exe is in your system's PATH 
*    or run the commands from its installation directory.
* 3. A SQL Server login with permissions to create databases.
*
*************************************************************************************************************************/

-- =======================================================================================================================
-- STEP 1: SETUP - Create the databases and tables for the demo.
-- =======================================================================================================================

USE master;
GO

-- Drop databases if they already exist to ensure a clean run
IF DB_ID('HighFrequencyDB') IS NOT NULL
BEGIN
    ALTER DATABASE HighFrequencyDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HighFrequencyDB;
END
GO

IF DB_ID('ConcurrentWorkloadDB') IS NOT NULL
BEGIN
    ALTER DATABASE ConcurrentWorkloadDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ConcurrentWorkloadDB;
END
GO

PRINT 'Creating databases...';

CREATE DATABASE HighFrequencyDB;
GO
CREATE DATABASE ConcurrentWorkloadDB;
GO

-- 1a. Create the target for our high-frequency query. A single-row table is sufficient.
USE HighFrequencyDB;
GO
CREATE TABLE dbo.HighFrequencyTarget
(
    ID INT PRIMARY KEY,
    SomeValue VARCHAR(100)
);
INSERT INTO dbo.HighFrequencyTarget (ID, SomeValue) VALUES (1, 'This is a very fast query target.');
GO

-- 1b. Create the table for our "other" workload that will be impacted.
USE ConcurrentWorkloadDB;
GO
CREATE TABLE dbo.WorkloadTable
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Category INT,
    DataValue DECIMAL(18,4),
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

-- Populate the workload table with 1 million rows. This will make our concurrent query do some actual work.
PRINT 'Populating workload table... This may take a minute.';
INSERT INTO dbo.WorkloadTable (Category, DataValue)
SELECT TOP 1000000
    ABS(CHECKSUM(NEWID())) % 1000,
    CAST(ABS(CHECKSUM(NEWID())) AS DECIMAL(18,4)) / 1000
FROM sys.all_objects a
CROSS JOIN sys.all_objects b;
GO

PRINT 'Setup Complete.';
GO


-- =======================================================================================================================
-- STEP 2: DEFINE THE QUERIES
-- =======================================================================================================================

-- 2a. This is the "fast query". It completes in microseconds and appears harmless on its own.
-- We will execute this query at a very high frequency using ostress.exe.
/*
USE HighFrequencyDB;
GO
SELECT ID, SomeValue FROM dbo.HighFrequencyTarget WHERE ID = 1;
GO
*/


-- 2b. This is our "concurrent workload". It's a simple aggregate query that is reasonably fast on an idle server.
-- We will run this to measure the performance impact.
/*
USE ConcurrentWorkloadDB;
GO
SET STATISTICS TIME ON;
SELECT Category, AVG(DataValue) AS AverageValue, COUNT(*) AS NumberOfRows
FROM dbo.WorkloadTable
GROUP BY Category
ORDER BY Category;
SET STATISTICS TIME OFF;
GO
*/


-- =======================================================================================================================
-- STEP 3: ESTABLISH A BASELINE
-- =======================================================================================================================

/*
*   First, let's run the concurrent workload on an idle server to see how long it takes.
*   Open a new query window in SSMS and run the script below.
*   Note the "SQL Server Execution Times" in the Messages tab. It should be relatively fast.
*/

/* -- RUN THIS IN A NEW WINDOW TO GET BASELINE --
USE ConcurrentWorkloadDB;
GO
SET STATISTICS TIME ON;
PRINT '--- Baseline Run ---';
SELECT Category, AVG(DataValue) AS AverageValue, COUNT(*) AS NumberOfRows
FROM dbo.WorkloadTable
GROUP BY Category
ORDER BY Category;
PRINT '--- Baseline Run Complete ---';
SET STATISTICS TIME OFF;
GO
*/


-- =======================================================================================================================
-- STEP 4: GENERATE THE HIGH-FREQUENCY LOAD
-- =======================================================================================================================

/*
*   Now, we will simulate the "death by a thousand cuts" scenario.
*   Open a command prompt (cmd.exe) and run the following ostress.exe command.
*   This command will start 50 concurrent threads, each executing the "fast query" in a loop.
*
*   Replace "-S ." with your SQL Server instance name if it's not the default local instance.
*   Use "-U <user> -P <password>" if you are not using a trusted connection.
*
*   LET THIS COMMAND RUN IN THE BACKGROUND while you proceed to the next step.
*/

-- COMMAND TO RUN IN CMD.EXE:
-- ostress -E -S . -d HighFrequencyDB -Q "SELECT ID, SomeValue FROM dbo.HighFrequencyTarget WHERE ID = 1;" -n 50 -r 1000000 -q


-- =======================================================================================================================
-- STEP 5: OBSERVE THE IMPACT
-- =======================================================================================================================

/*
*   5a. RERUN THE CONCURRENT WORKLOAD
*
*   While the ostress command from Step 4 is running, go back to your SSMS window (the same one from Step 3)
*   and execute the concurrent workload script again.
*
*   You should observe that the query takes significantly longer to complete.
*   The "SQL Server Execution Times" will show a much higher "elapsed time" compared to the baseline.
*   This is because the query is spending a lot of time waiting for its turn on the CPU (Signal Waits).
*/

/* -- RUN THIS IN A NEW WINDOW WHILE OSTRESS IS RUNNING --
USE ConcurrentWorkloadDB;
GO
SET STATISTICS TIME ON;
PRINT '--- Run Under Load ---';
SELECT Category, AVG(DataValue) AS AverageValue, COUNT(*) AS NumberOfRows
FROM dbo.WorkloadTable
GROUP BY Category
ORDER BY Category;
PRINT '--- Run Under Load Complete ---';
SET STATISTICS TIME OFF;
GO
*/


/*
*   5b. CHECK WAIT STATISTICS AND SCHEDULER STATS
*
*   While the load is still running, execute the queries below in a new window.
*   You will see a high number of 'SOS_SCHEDULER_YIELD' waits. This wait type occurs when a task yields the scheduler 
*   for other tasks to run. A high value indicates intense CPU pressure.
*
*   The second query shows the signal wait time, which is the time a query spends in the runnable queue waiting for a 
*   CPU to become available. You will see that signal waits are a significant percentage of total waits.
*/

/* -- RUN THIS IN A NEW WINDOW WHILE OSTRESS IS RUNNING --
-- Query 1: Check for top waits. SOS_SCHEDULER_YIELD will likely be at or near the top.
SELECT TOP 10
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    signal_wait_time_ms,
    wait_time_ms - signal_wait_time_ms AS resource_wait_time_ms
FROM sys.dm_os_wait_stats
ORDER BY wait_time_ms DESC;

-- Query 2: Check scheduler details. Notice the high signal_wait_time_ms compared to cpu_time_ms.
SELECT
    scheduler_id,
    cpu_id,
    current_tasks_count,
    runnable_tasks_count,
    current_workers_count,
    active_workers_count,
    signal_wait_time_ms,
    cpu_time_ms
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255; -- Ignore internal schedulers
*/


-- =======================================================================================================================
-- STEP 6: CLEANUP
-- =======================================================================================================================
/*
*   Stop the ostress.exe command in the command prompt by pressing Ctrl+C.
*   Then, run the script below to drop the databases created for this demo.
*/

/* -- CLEANUP SCRIPT --
USE master;
GO

IF DB_ID('HighFrequencyDB') IS NOT NULL
BEGIN
    ALTER DATABASE HighFrequencyDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HighFrequencyDB;
END
GO

IF DB_ID('ConcurrentWorkloadDB') IS NOT NULL
BEGIN
    ALTER DATABASE ConcurrentWorkloadDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ConcurrentWorkloadDB;
END
GO

PRINT 'Cleanup complete.';
*/
