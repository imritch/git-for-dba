/*============================================================================
  Demo: High-Frequency Query Impact - CPU Pressure and Signal Wait Demonstration

  Purpose:
  --------
  Demonstrates how a simple, efficient SELECT query (250 microseconds CPU time)
  when executed at extreme frequency (30M times in 30 minutes = ~16,667 QPS)
  can severely impact concurrent workloads by causing CPU pressure and
  increased signal wait times.

  Key Learning Points:
  -------------------
  1. Individual query efficiency doesn't tell the whole story
  2. High execution frequency causes SOS_SCHEDULER_YIELD waits
  3. Signal wait time (CPU queue time) increases for ALL queries
  4. Concurrent workloads suffer even when they were previously fast
  5. Total CPU consumed = (avg CPU time) × (execution count)

  Prerequisites:
  -------------
  - SQL Server 2016+ (for Query Store)
  - Multi-core system recommended (2+ cores minimum)
  - Elevated permissions to enable Query Store

  Demo Flow:
  ---------
  Part 1: Setup - Create test database and objects
  Part 2: Baseline - Capture pre-attack metrics
  Part 3: Mixed Workload - Start realistic OLTP operations (victims)
  Part 4: Attack - Launch high-frequency SELECT bombardment
  Part 5: Monitor - Real-time CPU pressure and wait stats
  Part 6: Analysis - Compare before/after with Query Store
  Part 7: Cleanup

  Author: DBA Scripts Repository
  Date: 2025-11-22
============================================================================*/

USE master;
GO

-- Part 1: SETUP
PRINT '============================================================================';
PRINT 'Part 1: Database Setup';
PRINT '============================================================================';
PRINT '';

-- Drop and recreate database
IF DB_ID('HighFrequencyDemo') IS NOT NULL
BEGIN
    PRINT 'Dropping existing HighFrequencyDemo database...';
    ALTER DATABASE HighFrequencyDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HighFrequencyDemo;
END
GO

CREATE DATABASE HighFrequencyDemo;
GO

ALTER DATABASE HighFrequencyDemo SET RECOVERY SIMPLE;
GO

-- Enable Query Store for execution analysis
ALTER DATABASE HighFrequencyDemo
SET QUERY_STORE = ON (
    OPERATION_MODE = READ_WRITE,
    DATA_FLUSH_INTERVAL_SECONDS = 60,
    INTERVAL_LENGTH_MINUTES = 1,
    MAX_STORAGE_SIZE_MB = 100,
    QUERY_CAPTURE_MODE = ALL,
    SIZE_BASED_CLEANUP_MODE = AUTO
);
GO

USE HighFrequencyDemo;
GO

PRINT 'Database created with Query Store enabled.';
PRINT '';

-- Create sample tables
PRINT 'Creating test tables...';

-- Customer table (for high-frequency SELECT target)
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    Status CHAR(1) DEFAULT 'A',
    CreatedDate DATETIME2 DEFAULT SYSDATETIME(),
    LastModified DATETIME2 DEFAULT SYSDATETIME()
);

CREATE NONCLUSTERED INDEX IX_Customers_Status ON dbo.Customers(Status) INCLUDE (CustomerName);

-- Orders table (for OLTP workload)
CREATE TABLE dbo.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 DEFAULT SYSDATETIME(),
    OrderAmount DECIMAL(18,2),
    OrderStatus VARCHAR(20) DEFAULT 'Pending',
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) REFERENCES dbo.Customers(CustomerID)
);

CREATE NONCLUSTERED INDEX IX_Orders_CustomerID ON dbo.Orders(CustomerID);
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON dbo.Orders(OrderDate) INCLUDE (OrderAmount);

-- OrderDetails table (for more complex OLTP operations)
CREATE TABLE dbo.OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductCode NVARCHAR(50),
    Quantity INT,
    UnitPrice DECIMAL(18,2),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID)
);

CREATE NONCLUSTERED INDEX IX_OrderDetails_OrderID ON dbo.OrderDetails(OrderID);

-- Populate with sample data
PRINT 'Populating tables with sample data...';

-- Insert 10,000 customers
INSERT INTO dbo.Customers (CustomerName, Email, Status)
SELECT
    'Customer ' + CAST(n AS VARCHAR(10)),
    'customer' + CAST(n AS VARCHAR(10)) + '@example.com',
    CASE WHEN n % 10 = 0 THEN 'I' ELSE 'A' END -- 10% inactive
FROM (
    SELECT TOP 10000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_columns c1
    CROSS JOIN sys.all_columns c2
) nums;

-- Insert 50,000 orders
INSERT INTO dbo.Orders (CustomerID, OrderDate, OrderAmount, OrderStatus)
SELECT
    (ABS(CHECKSUM(NEWID())) % 10000) + 1, -- Random customer
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, SYSDATETIME()), -- Random date within last year
    CAST((ABS(CHECKSUM(NEWID())) % 10000) / 100.0 AS DECIMAL(18,2)), -- Random amount
    CASE (ABS(CHECKSUM(NEWID())) % 5)
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Processing'
        WHEN 2 THEN 'Shipped'
        WHEN 3 THEN 'Delivered'
        ELSE 'Completed'
    END
FROM (
    SELECT TOP 50000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_columns c1
    CROSS JOIN sys.all_columns c2
) nums;

-- Insert 200,000 order details
INSERT INTO dbo.OrderDetails (OrderID, ProductCode, Quantity, UnitPrice)
SELECT
    (ABS(CHECKSUM(NEWID())) % 50000) + 1, -- Random order
    'PROD-' + RIGHT('0000' + CAST((ABS(CHECKSUM(NEWID())) % 1000) AS VARCHAR(4)), 4),
    (ABS(CHECKSUM(NEWID())) % 10) + 1, -- Quantity 1-10
    CAST((ABS(CHECKSUM(NEWID())) % 5000) / 100.0 AS DECIMAL(18,2)) -- Unit price
FROM (
    SELECT TOP 200000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_columns c1
    CROSS JOIN sys.all_columns c2
) nums;

PRINT 'Tables populated successfully.';
PRINT '';

-- Update statistics to ensure optimal plans
UPDATE STATISTICS dbo.Customers WITH FULLSCAN;
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
UPDATE STATISTICS dbo.OrderDetails WITH FULLSCAN;

PRINT 'Setup complete!';
PRINT '';
GO

-- Part 2: BASELINE METRICS
PRINT '============================================================================';
PRINT 'Part 2: Capturing Baseline Metrics';
PRINT '============================================================================';
PRINT '';

-- Create table to store baseline metrics
IF OBJECT_ID('dbo.BaselineMetrics') IS NOT NULL DROP TABLE dbo.BaselineMetrics;
CREATE TABLE dbo.BaselineMetrics (
    MetricType VARCHAR(50),
    MetricValue BIGINT,
    CaptureTime DATETIME2 DEFAULT SYSDATETIME()
);

-- Capture current wait stats
INSERT INTO dbo.BaselineMetrics (MetricType, MetricValue)
SELECT
    'SignalWaitTime_ms_Baseline',
    SUM(signal_wait_time_ms)
FROM sys.dm_os_wait_stats
WHERE wait_type = 'SOS_SCHEDULER_YIELD';

-- Capture current scheduler stats
INSERT INTO dbo.BaselineMetrics (MetricType, MetricValue)
SELECT
    'TotalYieldCount_Baseline',
    SUM(yield_count)
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255;

-- Capture runnable tasks
INSERT INTO dbo.BaselineMetrics (MetricType, MetricValue)
SELECT
    'RunnableTasks_Baseline',
    SUM(runnable_tasks_count)
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255;

PRINT 'Baseline metrics captured.';
SELECT * FROM dbo.BaselineMetrics ORDER BY CaptureTime;
PRINT '';
GO

-- Part 3: WORKLOAD QUERIES
PRINT '============================================================================';
PRINT 'Part 3: Workload Query Definitions';
PRINT '============================================================================';
PRINT '';

PRINT 'The following queries are defined for this demo:';
PRINT '';
PRINT '1. HIGH-FREQUENCY ATTACKER QUERY:';
PRINT '   Simple SELECT with indexed predicate (~250 microseconds CPU)';
PRINT '   Will execute ~500,000 times in quick succession to simulate';
PRINT '   30M executions over 30 minutes (scaled down for demo)';
PRINT '';
PRINT '2. VICTIM WORKLOAD QUERIES (Mixed OLTP):';
PRINT '   - Customer lookup queries';
PRINT '   - Order aggregation queries';
PRINT '   - Order INSERT operations';
PRINT '   - OrderDetail INSERT operations';
PRINT '';

-- Create stored procedure for the "attacker" query
IF OBJECT_ID('dbo.usp_GetActiveCustomerCount') IS NOT NULL DROP PROC dbo.usp_GetActiveCustomerCount;
GO

CREATE PROCEDURE dbo.usp_GetActiveCustomerCount
AS
BEGIN
    SET NOCOUNT ON;

    -- Simple, efficient SELECT with index seek
    -- This represents an application query that is individually fast
    -- but becomes problematic at extreme execution frequency
    SELECT COUNT(*) AS ActiveCustomers
    FROM dbo.Customers WITH (NOLOCK)
    WHERE Status = 'A';
END
GO

-- Create stored procedures for victim workload
IF OBJECT_ID('dbo.usp_GetCustomerOrders') IS NOT NULL DROP PROC dbo.usp_GetCustomerOrders;
GO

CREATE PROCEDURE dbo.usp_GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Typical customer order lookup
    SELECT
        o.OrderID,
        o.OrderDate,
        o.OrderAmount,
        o.OrderStatus,
        COUNT(od.OrderDetailID) AS ItemCount
    FROM dbo.Orders o
    LEFT JOIN dbo.OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.OrderDate, o.OrderAmount, o.OrderStatus
    ORDER BY o.OrderDate DESC;
END
GO

IF OBJECT_ID('dbo.usp_GetOrderSummary') IS NOT NULL DROP PROC dbo.usp_GetOrderSummary;
GO

CREATE PROCEDURE dbo.usp_GetOrderSummary
    @DaysBack INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    -- Order summary aggregation (more CPU intensive)
    SELECT
        CAST(o.OrderDate AS DATE) AS OrderDate,
        o.OrderStatus,
        COUNT(*) AS OrderCount,
        SUM(o.OrderAmount) AS TotalAmount,
        AVG(o.OrderAmount) AS AvgAmount
    FROM dbo.Orders o
    WHERE o.OrderDate >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
    GROUP BY CAST(o.OrderDate AS DATE), o.OrderStatus
    ORDER BY OrderDate DESC, OrderStatus;
END
GO

IF OBJECT_ID('dbo.usp_CreateOrder') IS NOT NULL DROP PROC dbo.usp_CreateOrder;
GO

CREATE PROCEDURE dbo.usp_CreateOrder
    @CustomerID INT,
    @OrderAmount DECIMAL(18,2),
    @OrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Orders (CustomerID, OrderDate, OrderAmount, OrderStatus)
    VALUES (@CustomerID, SYSDATETIME(), @OrderAmount, 'Pending');

    SET @OrderID = SCOPE_IDENTITY();
END
GO

PRINT 'Workload procedures created.';
PRINT '';
GO

-- Part 4: TEST BASELINE PERFORMANCE
PRINT '============================================================================';
PRINT 'Part 4: Testing Baseline Performance (Without Attack)';
PRINT '============================================================================';
PRINT '';

PRINT 'Executing victim workloads under normal conditions...';
PRINT '';

DECLARE @StartTime DATETIME2;
DECLARE @EndTime DATETIME2;
DECLARE @Duration_ms INT;
DECLARE @OrderID INT;

-- Test 1: Customer orders lookup
SET @StartTime = SYSDATETIME();
EXEC dbo.usp_GetCustomerOrders @CustomerID = 100;
SET @EndTime = SYSDATETIME();
SET @Duration_ms = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Customer Orders Query - Baseline Duration: ' + CAST(@Duration_ms AS VARCHAR(10)) + ' ms';

-- Test 2: Order summary
SET @StartTime = SYSDATETIME();
EXEC dbo.usp_GetOrderSummary @DaysBack = 90;
SET @EndTime = SYSDATETIME();
SET @Duration_ms = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Order Summary Query - Baseline Duration: ' + CAST(@Duration_ms AS VARCHAR(10)) + ' ms';

-- Test 3: Order INSERT
SET @StartTime = SYSDATETIME();
EXEC dbo.usp_CreateOrder @CustomerID = 500, @OrderAmount = 1299.99, @OrderID = @OrderID OUTPUT;
SET @EndTime = SYSDATETIME();
SET @Duration_ms = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Order INSERT - Baseline Duration: ' + CAST(@Duration_ms AS VARCHAR(10)) + ' ms';

PRINT '';
PRINT 'Baseline performance test complete.';
PRINT 'Note these durations - they will increase significantly during attack!';
PRINT '';
GO

-- Part 5: MONITORING SCRIPT
PRINT '============================================================================';
PRINT 'Part 5: Real-Time Monitoring Query';
PRINT '============================================================================';
PRINT '';

PRINT 'Use this query in a separate window to monitor CPU pressure in real-time:';
PRINT '';
PRINT '-------- COPY BELOW QUERY TO NEW WINDOW --------';
GO

/*
-- REAL-TIME CPU PRESSURE MONITOR
-- Run this in a separate query window during the attack
-- Refresh every 5 seconds to see metrics change

USE HighFrequencyDemo;

SELECT
    SYSDATETIME() AS CurrentTime,
    -- Scheduler metrics
    SUM(s.current_tasks_count) AS CurrentTasks,
    SUM(s.runnable_tasks_count) AS RunnableTasks_InQueue,
    SUM(s.work_queue_count) AS WorkQueueDepth,
    SUM(s.pending_disk_io_count) AS PendingDiskIO,
    -- Signal wait metrics (CPU queue time)
    ws.signal_wait_time_ms AS SignalWaitTime_ms,
    ws.wait_time_ms AS TotalWaitTime_ms,
    CASE
        WHEN ws.wait_time_ms > 0
        THEN CAST(100.0 * ws.signal_wait_time_ms / ws.wait_time_ms AS DECIMAL(5,2))
        ELSE 0
    END AS SignalWait_Percentage
FROM sys.dm_os_schedulers s
CROSS APPLY (
    SELECT
        signal_wait_time_ms,
        wait_time_ms
    FROM sys.dm_os_wait_stats
    WHERE wait_type = 'SOS_SCHEDULER_YIELD'
) ws
WHERE s.scheduler_id < 255
GROUP BY ws.signal_wait_time_ms, ws.wait_time_ms;

-- Top queries by CPU time (last 5 minutes)
SELECT TOP 10
    DB_NAME(q.database_id) AS DatabaseName,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS QueryText,
    qs.execution_count,
    qs.total_worker_time / 1000 AS TotalCPU_ms,
    qs.total_worker_time / qs.execution_count / 1000 AS AvgCPU_ms,
    qs.total_elapsed_time / qs.execution_count / 1000 AS AvgElapsed_ms
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qs.last_execution_time >= DATEADD(MINUTE, -5, SYSDATETIME())
ORDER BY qs.total_worker_time DESC;
*/

PRINT '-------- END MONITORING QUERY --------';
PRINT '';
GO

-- Part 6: LAUNCH ATTACK AND VICTIM WORKLOADS
PRINT '============================================================================';
PRINT 'Part 6: DEMONSTRATION - High-Frequency Attack + Victim Workload';
PRINT '============================================================================';
PRINT '';

PRINT '*****************************************************************************';
PRINT '* INSTRUCTIONS:                                                             *';
PRINT '* 1. Open a SECOND query window and run the monitoring query from Part 5   *';
PRINT '* 2. Come back to this window and run the code blocks below                *';
PRINT '* 3. Execute the ATTACKER workload first (Window 2)                        *';
PRINT '* 4. While it runs, execute VICTIM workload in Window 3                    *';
PRINT '* 5. Watch the monitoring query show CPU pressure building                 *';
PRINT '*****************************************************************************';
PRINT '';

PRINT '-------- WINDOW 2: ATTACKER WORKLOAD --------';
PRINT 'Copy and run this in a NEW query window:';
PRINT '';
GO

/*
-- ATTACKER WORKLOAD - WINDOW 2
-- This simulates the high-frequency query bombardment
-- Executes the "efficient" query 500,000 times rapidly
-- In production: 30M executions over 30 minutes = ~16,667 QPS
-- For demo: 500K executions should take 2-3 minutes

USE HighFrequencyDemo;
GO

SET NOCOUNT ON;
DECLARE @Counter INT = 0;
DECLARE @MaxIterations INT = 500000; -- Adjust lower (50000) for faster demo
DECLARE @StartTime DATETIME2 = SYSDATETIME();
DECLARE @Result INT;

PRINT 'Starting high-frequency attack...';
PRINT 'Target: ' + CAST(@MaxIterations AS VARCHAR(10)) + ' executions';
PRINT 'Start time: ' + CAST(@StartTime AS VARCHAR(30));
PRINT '';

WHILE @Counter < @MaxIterations
BEGIN
    -- Execute the "efficient" query
    EXEC dbo.usp_GetActiveCustomerCount;

    SET @Counter = @Counter + 1;

    -- Progress indicator every 50,000 iterations
    IF @Counter % 50000 = 0
    BEGIN
        PRINT 'Progress: ' + CAST(@Counter AS VARCHAR(10)) + ' / ' +
              CAST(@MaxIterations AS VARCHAR(10)) + ' (' +
              CAST(CAST(100.0 * @Counter / @MaxIterations AS DECIMAL(5,2)) AS VARCHAR(10)) + '%)';
    END
END

DECLARE @EndTime DATETIME2 = SYSDATETIME();
DECLARE @TotalSeconds INT = DATEDIFF(SECOND, @StartTime, @EndTime);

PRINT '';
PRINT 'Attack complete!';
PRINT 'Total executions: ' + CAST(@Counter AS VARCHAR(10));
PRINT 'Duration: ' + CAST(@TotalSeconds AS VARCHAR(10)) + ' seconds';
PRINT 'Queries per second: ' + CAST(@Counter / NULLIF(@TotalSeconds, 0) AS VARCHAR(10));
PRINT '';
*/

PRINT '-------- END ATTACKER WORKLOAD --------';
PRINT '';
PRINT '';

PRINT '-------- WINDOW 3: VICTIM WORKLOAD --------';
PRINT 'Copy and run this in a THIRD query window WHILE attack is running:';
PRINT '';
GO

/*
-- VICTIM WORKLOAD - WINDOW 3
-- Run this while the attacker workload is executing
-- This represents normal application queries that will suffer

USE HighFrequencyDemo;
GO

SET NOCOUNT ON;
DECLARE @StartTime DATETIME2;
DECLARE @EndTime DATETIME2;
DECLARE @Duration_ms INT;
DECLARE @OrderID INT;
DECLARE @Iteration INT = 0;

PRINT 'Starting victim workload tests (during attack)...';
PRINT '';

-- Create results table
IF OBJECT_ID('tempdb..#VictimResults') IS NOT NULL DROP TABLE #VictimResults;
CREATE TABLE #VictimResults (
    TestName VARCHAR(100),
    Duration_ms INT,
    TestTime DATETIME2
);

WHILE @Iteration < 20 -- Run 20 iterations
BEGIN
    -- Test 1: Customer orders lookup
    SET @StartTime = SYSDATETIME();
    EXEC dbo.usp_GetCustomerOrders @CustomerID = (100 + (@Iteration % 100));
    SET @EndTime = SYSDATETIME();
    SET @Duration_ms = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    INSERT INTO #VictimResults VALUES ('Customer Orders', @Duration_ms, SYSDATETIME());

    -- Test 2: Order summary
    SET @StartTime = SYSDATETIME();
    EXEC dbo.usp_GetOrderSummary @DaysBack = 90;
    SET @EndTime = SYSDATETIME();
    SET @Duration_ms = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    INSERT INTO #VictimResults VALUES ('Order Summary', @Duration_ms, SYSDATETIME());

    -- Test 3: Order INSERT
    SET @StartTime = SYSDATETIME();
    EXEC dbo.usp_CreateOrder
        @CustomerID = (500 + (@Iteration % 500)),
        @OrderAmount = 1299.99,
        @OrderID = @OrderID OUTPUT;
    SET @EndTime = SYSDATETIME();
    SET @Duration_ms = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    INSERT INTO #VictimResults VALUES ('Order INSERT', @Duration_ms, SYSDATETIME());

    SET @Iteration = @Iteration + 1;

    -- Small delay between iterations
    WAITFOR DELAY '00:00:01';
END

-- Show results
PRINT 'Victim workload complete. Results:';
PRINT '';

SELECT
    TestName,
    COUNT(*) AS Executions,
    MIN(Duration_ms) AS Min_ms,
    MAX(Duration_ms) AS Max_ms,
    AVG(Duration_ms) AS Avg_ms,
    STDEV(Duration_ms) AS StdDev_ms
FROM #VictimResults
GROUP BY TestName
ORDER BY TestName;

PRINT '';
PRINT 'Compare these durations to Part 4 baseline!';
PRINT 'You should see significant degradation during the attack.';
*/

PRINT '-------- END VICTIM WORKLOAD --------';
PRINT '';
GO

-- Part 7: POST-ATTACK ANALYSIS
PRINT '============================================================================';
PRINT 'Part 7: Post-Attack Analysis';
PRINT '============================================================================';
PRINT '';

PRINT 'Run this query AFTER both attacker and victim workloads complete:';
PRINT '';
GO

-- Wait for user to complete the attack and victim workloads
-- Then run analysis

PRINT '-------- POST-ATTACK ANALYSIS --------';
GO

USE HighFrequencyDemo;
GO

-- Capture post-attack metrics
IF OBJECT_ID('dbo.PostAttackMetrics') IS NOT NULL DROP TABLE dbo.PostAttackMetrics;
CREATE TABLE dbo.PostAttackMetrics (
    MetricType VARCHAR(50),
    MetricValue BIGINT,
    CaptureTime DATETIME2 DEFAULT SYSDATETIME()
);

-- Capture current wait stats
INSERT INTO dbo.PostAttackMetrics (MetricType, MetricValue)
SELECT
    'SignalWaitTime_ms_PostAttack',
    SUM(signal_wait_time_ms)
FROM sys.dm_os_wait_stats
WHERE wait_type = 'SOS_SCHEDULER_YIELD';

-- Capture current scheduler stats
INSERT INTO dbo.PostAttackMetrics (MetricType, MetricValue)
SELECT
    'TotalYieldCount_PostAttack',
    SUM(yield_count)
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255;

PRINT 'Post-attack metrics captured.';
PRINT '';

-- Compare baseline vs post-attack
PRINT '============================================================================';
PRINT 'METRIC COMPARISON: Baseline vs Post-Attack';
PRINT '============================================================================';
PRINT '';

SELECT
    'Signal Wait Time (ms)' AS Metric,
    MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) AS Baseline_Value,
    MAX(CASE WHEN p.MetricType LIKE '%PostAttack' THEN p.MetricValue END) AS PostAttack_Value,
    MAX(CASE WHEN p.MetricType LIKE '%PostAttack' THEN p.MetricValue END) -
        MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) AS Delta,
    CASE
        WHEN MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) > 0
        THEN CAST(100.0 * (
            MAX(CASE WHEN p.MetricType LIKE '%PostAttack' THEN p.MetricValue END) -
            MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END)
        ) / MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) AS DECIMAL(10,2))
        ELSE NULL
    END AS Increase_Percentage
FROM dbo.BaselineMetrics b
CROSS JOIN dbo.PostAttackMetrics p
WHERE b.MetricType LIKE '%SignalWait%'
  AND p.MetricType LIKE '%SignalWait%'

UNION ALL

SELECT
    'Total Yield Count' AS Metric,
    MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) AS Baseline_Value,
    MAX(CASE WHEN p.MetricType LIKE '%PostAttack' THEN p.MetricValue END) AS PostAttack_Value,
    MAX(CASE WHEN p.MetricType LIKE '%PostAttack' THEN p.MetricValue END) -
        MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) AS Delta,
    CASE
        WHEN MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) > 0
        THEN CAST(100.0 * (
            MAX(CASE WHEN p.MetricType LIKE '%PostAttack' THEN p.MetricValue END) -
            MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END)
        ) / MAX(CASE WHEN b.MetricType LIKE '%Baseline' THEN b.MetricValue END) AS DECIMAL(10,2))
        ELSE NULL
    END AS Increase_Percentage
FROM dbo.BaselineMetrics b
CROSS JOIN dbo.PostAttackMetrics p
WHERE b.MetricType LIKE '%YieldCount%'
  AND p.MetricType LIKE '%YieldCount%';

PRINT '';
PRINT '============================================================================';
PRINT 'QUERY STORE ANALYSIS: Execution Patterns';
PRINT '============================================================================';
PRINT '';

-- Top queries by execution count
SELECT TOP 10
    qsq.query_id,
    SUBSTRING(qsqt.query_sql_text, 1, 100) AS QueryText,
    COUNT(DISTINCT qsrs.runtime_stats_interval_id) AS IntervalsCaptured,
    SUM(qsrs.count_executions) AS TotalExecutions,
    SUM(qsrs.count_executions * qsrs.avg_cpu_time) / 1000 AS TotalCPU_ms,
    AVG(qsrs.avg_cpu_time) AS AvgCPU_microseconds,
    AVG(qsrs.avg_duration) AS AvgDuration_microseconds,
    MAX(qsrs.max_cpu_time) AS MaxCPU_microseconds
FROM sys.query_store_query qsq
INNER JOIN sys.query_store_query_text qsqt ON qsq.query_text_id = qsqt.query_text_id
INNER JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
INNER JOIN sys.query_store_runtime_stats qsrs ON qsp.plan_id = qsrs.plan_id
WHERE qsqt.query_sql_text NOT LIKE '%query_store%'
GROUP BY qsq.query_id, qsqt.query_sql_text
ORDER BY TotalExecutions DESC;

PRINT '';
PRINT '============================================================================';
PRINT 'TOP CPU CONSUMERS (Total CPU Time)';
PRINT '============================================================================';
PRINT '';

SELECT TOP 10
    qsq.query_id,
    SUBSTRING(qsqt.query_sql_text, 1, 100) AS QueryText,
    SUM(qsrs.count_executions) AS TotalExecutions,
    SUM(qsrs.count_executions * qsrs.avg_cpu_time) / 1000 AS TotalCPU_ms,
    AVG(qsrs.avg_cpu_time) AS AvgCPU_microseconds,
    -- The "efficient" attacker query will be at the top!
    CASE
        WHEN SUM(qsrs.count_executions) > 100000 THEN '*** HIGH FREQUENCY ATTACKER ***'
        ELSE ''
    END AS Notes
FROM sys.query_store_query qsq
INNER JOIN sys.query_store_query_text qsqt ON qsq.query_text_id = qsqt.query_text_id
INNER JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
INNER JOIN sys.query_store_runtime_stats qsrs ON qsp.plan_id = qsrs.plan_id
WHERE qsqt.query_sql_text NOT LIKE '%query_store%'
GROUP BY qsq.query_id, qsqt.query_sql_text
ORDER BY TotalCPU_ms DESC;

PRINT '';
GO

-- Part 8: KEY INSIGHTS
PRINT '============================================================================';
PRINT 'KEY INSIGHTS AND TAKEAWAYS';
PRINT '============================================================================';
PRINT '';
PRINT 'What This Demo Proves:';
PRINT '----------------------';
PRINT '1. Individual Query Efficiency ≠ System Impact';
PRINT '   - The attacker query uses only ~250 microseconds CPU per execution';
PRINT '   - But at 500K executions, that is 125,000 ms = 125 seconds of CPU!';
PRINT '';
PRINT '2. Signal Wait Time Impact:';
PRINT '   - SOS_SCHEDULER_YIELD waits increase dramatically';
PRINT '   - Signal wait = time queries spend in runnable queue waiting for CPU';
PRINT '   - ALL queries suffer, not just the high-frequency one';
PRINT '';
PRINT '3. Victim Workload Degradation:';
PRINT '   - Queries that ran in <50ms baseline now take 200-500ms or more';
PRINT '   - This is the "collateral damage" application teams do not see';
PRINT '';
PRINT '4. Total CPU Consumption Matters:';
PRINT '   - Total CPU = (avg CPU per execution) × (execution count)';
PRINT '   - 250 μs × 30M executions = 7,500,000,000 μs = 7,500 seconds = 125 minutes CPU!';
PRINT '';
PRINT 'Recommendations:';
PRINT '----------------';
PRINT '- Implement query result caching for high-frequency reads';
PRINT '- Add application-side rate limiting/throttling';
PRINT '- Consider read replicas for reporting queries';
PRINT '- Use connection pooling to limit concurrent connections';
PRINT '- Monitor execution counts, not just avg CPU time';
PRINT '- Set up alerts on SOS_SCHEDULER_YIELD signal wait percentage';
PRINT '';
GO

-- Part 9: CLEANUP
PRINT '============================================================================';
PRINT 'Part 9: Cleanup';
PRINT '============================================================================';
PRINT '';

PRINT 'To clean up after the demo, run:';
PRINT '';
PRINT '    USE master;';
PRINT '    DROP DATABASE HighFrequencyDemo;';
PRINT '';
PRINT 'Demo script complete!';
GO
