# Lesson 8: Git Bisect - Finding the Bug that Broke Production

## 🎯 What is Git Bisect?

Git bisect is a powerful binary search tool that helps you find which specific commit introduced a bug or performance regression. Instead of manually checking dozens of commits, bisect automatically narrows down the culprit.

**DBA Analogy:** Like using SQL Server Profiler to find which query caused a performance issue, but for your Git history - it systematically tests commits to find the "bad" one.

## 🤔 When Do You Need It?

**Scenario:** Your production database suddenly has slow queries. You know it worked fine 2 weeks ago (50 commits back), but you're not sure which stored procedure change caused the regression.

Manual checking would mean:
- ❌ Reviewing 50 commits one by one
- ❌ Testing each commit manually
- ❌ Hours or days of investigation

With Git bisect:
- ✅ Automatically narrows down to the problem commit
- ✅ Uses binary search (50 commits → ~6 tests)
- ✅ Can automate testing with scripts
- ✅ Finds the exact commit and author

## 📊 How Binary Search Works

```
50 commits to check manually = 50 tests
50 commits with binary search = ~6 tests

Example with 16 commits:
Initial: [1][2][3][4][5][6][7][8][9][10][11][12][13][14][15][16]
         ^GOOD                                              ^BAD

Test #1: [1][2][3][4][5][6][7][8]  ← Test middle (8)
Result: GOOD → Bug is in second half

Test #2: [9][10][11][12]  ← Test middle of remaining (12)
Result: BAD → Bug is in first half of this range

Test #3: [9][10]  ← Test middle (10)
Result: GOOD → Bug is between 10 and 12

Test #4: [11]  ← Only one left!
Result: BAD → Found it! Commit 11 introduced the bug
```

## 📝 Exercise 1: Manual Bisect - Finding a Performance Regression

### Scenario: Slow Customer Report

You've deployed several updates to the customer reporting stored procedure. Suddenly, reports take 10 seconds instead of 1 second. You need to find which change caused this.

### Step 1: Create the History with a "Bug"

```bash
# Ensure you're in the git-for-dba directory
cd /Users/riteshchawla/RC/git/git-for-dba

# Create a new branch for this exercise
git checkout -b exercise/bisect-practice

# Commit 1: Initial good version
cat > database/GetCustomerReport.sql << 'EOF'
-- Get Customer Report
-- Version 1.0 - Fast and efficient
CREATE PROCEDURE dbo.GetCustomerReport
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CustomerId,
        c.CustomerName,
        COUNT(o.OrderId) AS OrderCount
    FROM dbo.Customers c
    INNER JOIN dbo.Orders o ON c.CustomerId = o.CustomerId
    WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY c.CustomerId, c.CustomerName
    ORDER BY OrderCount DESC;
END
-- Performance: ~1 second
EOF

git add database/GetCustomerReport.sql
git commit -m "v1.0: Initial customer report - fast"

# Commit 2: Add email (still good)
cat > database/GetCustomerReport.sql << 'EOF'
-- Get Customer Report
-- Version 1.1 - Added email
CREATE PROCEDURE dbo.GetCustomerReport
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CustomerId,
        c.CustomerName,
        c.Email,
        COUNT(o.OrderId) AS OrderCount
    FROM dbo.Customers c
    INNER JOIN dbo.Orders o ON c.CustomerId = o.CustomerId
    WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY c.CustomerId, c.CustomerName, c.Email
    ORDER BY OrderCount DESC;
END
-- Performance: ~1 second
EOF

git add database/GetCustomerReport.sql
git commit -m "v1.1: Add email to customer report"

# Commit 3: Add phone (still good)
cat > database/GetCustomerReport.sql << 'EOF'
-- Get Customer Report
-- Version 1.2 - Added phone
CREATE PROCEDURE dbo.GetCustomerReport
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CustomerId,
        c.CustomerName,
        c.Email,
        c.Phone,
        COUNT(o.OrderId) AS OrderCount
    FROM dbo.Customers c
    INNER JOIN dbo.Orders o ON c.CustomerId = o.CustomerId
    WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY c.CustomerId, c.CustomerName, c.Email, c.Phone
    ORDER BY OrderCount DESC;
END
-- Performance: ~1 second
EOF

git add database/GetCustomerReport.sql
git commit -m "v1.2: Add phone to customer report"

# Commit 4: THE BUG - Added costly subquery
cat > database/GetCustomerReport.sql << 'EOF'
-- Get Customer Report
-- Version 1.3 - Added total revenue (SLOW!)
CREATE PROCEDURE dbo.GetCustomerReport
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CustomerId,
        c.CustomerName,
        c.Email,
        c.Phone,
        COUNT(o.OrderId) AS OrderCount,
        -- BUG: This subquery runs for EVERY row! No correlation!
        (SELECT SUM(TotalAmount) FROM dbo.Orders) AS TotalRevenue
    FROM dbo.Customers c
    INNER JOIN dbo.Orders o ON c.CustomerId = o.CustomerId
    WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY c.CustomerId, c.CustomerName, c.Email, c.Phone
    ORDER BY OrderCount DESC;
END
-- Performance: ~10 seconds (SLOW!)
EOF

git add database/GetCustomerReport.sql
git commit -m "v1.3: Add total revenue to customer report"

# Commit 5: Add more columns (still bad)
cat > database/GetCustomerReport.sql << 'EOF'
-- Get Customer Report
-- Version 1.4 - Added last order date
CREATE PROCEDURE dbo.GetCustomerReport
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CustomerId,
        c.CustomerName,
        c.Email,
        c.Phone,
        COUNT(o.OrderId) AS OrderCount,
        (SELECT SUM(TotalAmount) FROM dbo.Orders) AS TotalRevenue,
        MAX(o.OrderDate) AS LastOrderDate
    FROM dbo.Customers c
    INNER JOIN dbo.Orders o ON c.CustomerId = o.CustomerId
    WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY c.CustomerId, c.CustomerName, c.Email, c.Phone
    ORDER BY OrderCount DESC;
END
-- Performance: ~10 seconds (still SLOW!)
EOF

git add database/GetCustomerReport.sql
git commit -m "v1.4: Add last order date to customer report"

# View the history
git log --oneline
```

### Step 2: Start Git Bisect

```bash
# Start bisect
git bisect start

# Mark current commit as bad (slow)
git bisect bad

# Find the first commit in our history
git log --oneline --reverse | head -1
# Note the hash (let's say it's abc1234)

# Mark the first commit as good
git bisect good <hash-of-v1.0-commit>

# Git will automatically checkout a middle commit
```

**What Git does:**
```
Git will output something like:
"Bisecting: 2 revisions left to test after this (roughly 1 step)"
```

### Step 3: Test Each Commit

```bash
# Git has checked out a middle commit
# Look at the file
cat database/GetCustomerReport.sql

# Check if this version has the performance issue
# Look for the problematic subquery: (SELECT SUM(TotalAmount) FROM dbo.Orders)

# If you see the bad subquery:
git bisect bad

# If you don't see it:
git bisect good

# Git automatically moves to the next commit to test
# Repeat until Git identifies the exact commit
```

### Step 4: Git Finds the Culprit

```bash
# After a few tests, Git will output:
# abc1234 is the first bad commit
# commit abc1234
# Author: YourName
# Date: ...
#
#     v1.3: Add total revenue to customer report

# View the problematic commit
git show abc1234

# End bisect session
git bisect reset
```

**Success!** You found the bug in ~3 tests instead of checking 5 commits manually.

## 📝 Exercise 2: Automated Bisect - Using a Test Script

### The Power of Automation

Instead of manually testing each commit, you can write a script that returns:
- **Exit code 0**: Good commit (test passes)
- **Exit code 1**: Bad commit (test fails)

### Step 1: Create a Test Script

```bash
# Create a test script that checks for the problematic pattern
cat > scripts/test-performance.sh << 'EOF'
#!/bin/bash
# Test if the customer report has performance issues
# Returns 0 (good) if no issues, 1 (bad) if issues found

FILE="database/GetCustomerReport.sql"

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "File not found, considering as good"
    exit 0
fi

# Check for the problematic uncorrelated subquery pattern
if grep -q "(SELECT SUM(TotalAmount) FROM dbo.Orders)" "$FILE"; then
    echo "FOUND BAD PATTERN: Uncorrelated subquery"
    exit 1  # Bad commit
else
    echo "GOOD: No performance issues detected"
    exit 0  # Good commit
fi
EOF

chmod +x scripts/test-performance.sh

# Test the script manually
./scripts/test-performance.sh
```

### Step 2: Run Automated Bisect

```bash
# Start bisect again
git bisect start

# Mark current as bad
git bisect bad

# Mark first commit as good (use the actual hash)
git log --oneline --reverse | head -1
git bisect good <first-commit-hash>

# Let Git run the script automatically!
git bisect run ./scripts/test-performance.sh
```

**Git will automatically:**
1. Check out each commit
2. Run your test script
3. Mark commits as good/bad based on exit code
4. Find the problematic commit
5. Display the results

**Output:**
```
running ./scripts/test-performance.sh
GOOD: No performance issues detected
Bisecting: 1 revision left to test after this
running ./scripts/test-performance.sh
FOUND BAD PATTERN: Uncorrelated subquery
Bisecting: 0 revisions left to test after this
running ./scripts/test-performance.sh
abc1234 is the first bad commit
```

### Step 3: Clean Up

```bash
# End bisect
git bisect reset

# You're back to your original branch
git checkout main
```

## 🎯 Exercise 3: Real-World DBA Scenario

### Scenario: Deadlock Regression

A change was made to order processing stored procedures. Now you're seeing deadlocks in production. You need to find which commit introduced the issue.

```bash
# Create the scenario
git checkout -b exercise/deadlock-hunt

# Commit 1: Good version (proper lock order)
cat > database/ProcessOrder.sql << 'EOF'
CREATE PROCEDURE dbo.ProcessOrder
    @OrderId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    -- Correct lock order: Orders first, then OrderDetails
    UPDATE dbo.Orders
    SET Status = 'Processing'
    WHERE OrderId = @OrderId;

    UPDATE dbo.OrderDetails
    SET Processed = 1
    WHERE OrderId = @OrderId;

    COMMIT TRANSACTION;
END
EOF

git add database/ProcessOrder.sql
git commit -m "ProcessOrder v1: Proper lock ordering"

# Commit 2: Added logging (still good)
cat > database/ProcessOrder.sql << 'EOF'
CREATE PROCEDURE dbo.ProcessOrder
    @OrderId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    -- Correct lock order: Orders first, then OrderDetails
    UPDATE dbo.Orders
    SET Status = 'Processing'
    WHERE OrderId = @OrderId;

    INSERT INTO ProcessLog (OrderId, ProcessedDate)
    VALUES (@OrderId, GETDATE());

    UPDATE dbo.OrderDetails
    SET Processed = 1
    WHERE OrderId = @OrderId;

    COMMIT TRANSACTION;
END
EOF

git add database/ProcessOrder.sql
git commit -m "ProcessOrder v2: Add logging"

# Commit 3: THE BUG - Reversed lock order (causes deadlocks)
cat > database/ProcessOrder.sql << 'EOF'
CREATE PROCEDURE dbo.ProcessOrder
    @OrderId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    -- BUG: Wrong lock order! OrderDetails first, then Orders
    -- This can deadlock with other procs that lock in opposite order
    UPDATE dbo.OrderDetails
    SET Processed = 1
    WHERE OrderId = @OrderId;

    INSERT INTO ProcessLog (OrderId, ProcessedDate)
    VALUES (@OrderId, GETDATE());

    UPDATE dbo.Orders
    SET Status = 'Processing'
    WHERE OrderId = @OrderId;

    COMMIT TRANSACTION;
END
EOF

git add database/ProcessOrder.sql
git commit -m "ProcessOrder v3: Refactor update order"

# Commit 4: Added error handling (still bad)
cat > database/ProcessOrder.sql << 'EOF'
CREATE PROCEDURE dbo.ProcessOrder
    @OrderId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Still wrong lock order
        UPDATE dbo.OrderDetails
        SET Processed = 1
        WHERE OrderId = @OrderId;

        INSERT INTO ProcessLog (OrderId, ProcessedDate)
        VALUES (@OrderId, GETDATE());

        UPDATE dbo.Orders
        SET Status = 'Processing'
        WHERE OrderId = @OrderId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
EOF

git add database/ProcessOrder.sql
git commit -m "ProcessOrder v4: Add error handling"
```

### Your Task: Find the Deadlock Bug

```bash
# Start bisect
git bisect start
git bisect bad

# Find first commit
git log --oneline --reverse | head -1
git bisect good <first-commit-hash>

# Create test script to detect lock order issue
cat > scripts/test-lock-order.sh << 'EOF'
#!/bin/bash
FILE="database/ProcessOrder.sql"

if [ ! -f "$FILE" ]; then
    exit 0
fi

# Extract UPDATE statements and check order
FIRST_UPDATE=$(grep -m 1 "UPDATE dbo\." "$FILE" | grep -o "dbo\.[A-Za-z]*" | head -1)

if [[ "$FIRST_UPDATE" == "dbo.OrderDetails" ]]; then
    echo "BAD: OrderDetails locked before Orders (deadlock risk)"
    exit 1
else
    echo "GOOD: Proper lock order"
    exit 0
fi
EOF

chmod +x scripts/test-lock-order.sh

# Run automated bisect
git bisect run ./scripts/test-lock-order.sh

# Review the culprit commit
# git bisect reset when done
```

## 🎓 Advanced Bisect Techniques

### 1. Skipping Commits

Sometimes a commit won't compile or can't be tested:

```bash
# During bisect, if current commit can't be tested
git bisect skip

# Git will try a nearby commit instead
```

### 2. Bisect with Terms Other than Good/Bad

For clarity, you can use custom terms:

```bash
# Use "fast" and "slow" instead of "good" and "bad"
git bisect start --term-old=fast --term-new=slow

git bisect slow        # Current commit is slow
git bisect fast <hash> # Old commit was fast
```

### 3. Bisect Log and Replay

```bash
# View what you've tested so far
git bisect log

# Save the log
git bisect log > bisect-session.txt

# Later, replay the session
git bisect replay bisect-session.txt
```

### 4. Visualize During Bisect

```bash
# See where you are in the bisect process
git bisect visualize
# or
git bisect view
```

## 📊 Bisect Cheat Sheet

```bash
# Start bisect
git bisect start
git bisect bad                    # Current commit is bad
git bisect good <commit>          # Old commit was good

# Manual testing
git bisect good                   # Current is good, move forward
git bisect bad                    # Current is bad, move backward
git bisect skip                   # Can't test this commit

# Automated testing
git bisect run <test-script.sh>

# View progress
git bisect log
git bisect visualize

# End session
git bisect reset                  # Return to original commit
```

## 💡 Real-World DBA Use Cases

### 1. Performance Regression
```bash
# Find when query performance degraded
# Test script: Run STATISTICS IO and check logical reads
git bisect run ./scripts/test-query-performance.sh
```

### 2. Broken Deployment Script
```bash
# Find when migration script started failing
# Test script: Try to run the script against test DB
git bisect run ./scripts/test-migration.sh
```

### 3. Data Integrity Issue
```bash
# Find when constraint violations started
# Test script: Check for orphaned records
git bisect run ./scripts/test-data-integrity.sh
```

### 4. Index Missing
```bash
# Find when important index was dropped
# Test script: Query sys.indexes
git bisect run ./scripts/test-indexes.sh
```

## ⚠️ Common Pitfalls

### 1. Bisecting Unstable Tests
**Problem:** Test gives different results on same commit
**Solution:** Make tests deterministic, avoid time-based checks

### 2. Bisecting with Merge Commits
**Problem:** Merge commits can be confusing
**Solution:** Use `--first-parent` to follow main branch only
```bash
git bisect start --first-parent
```

### 3. Large Binary Files
**Problem:** Checking out old commits is slow with large files
**Solution:** Use sparse checkout or test specific directories only

### 4. Database Schema Evolution
**Problem:** Old commits expect old schema
**Solution:** Test script should handle schema differences gracefully

## 🎯 Practice Challenges

### Challenge 1: Index Performance Hunt
Create a series of commits where one adds a bad index that slows queries. Use bisect to find it.

### Challenge 2: Stored Procedure Parameter Bug
Create commits where one changes a parameter default that breaks application logic.

### Challenge 3: Transaction Isolation Issue
Find the commit that changed isolation level causing dirty reads.

### Challenge 4: Automated Full Suite
Write a test script that:
- Checks syntax (SQL parsing)
- Checks for anti-patterns (cursors in OLTP procs)
- Checks for security issues (dynamic SQL without parameterization)
- Returns proper exit codes

## 📚 Best Practices

1. **Keep Test Scripts Simple**: Fast execution, clear pass/fail
2. **Use Exit Codes Correctly**: 0 = good, 1-127 = bad, 125 = skip
3. **Tag Known Good States**: `git tag v1.0-stable` for reference points
4. **Document Bisect Sessions**: Save logs for future reference
5. **Combine with git log --since**: Narrow down date range first
6. **Test Before Bisecting**: Verify your test script works on known good/bad commits

## 🔄 Integration with DBA Workflows

### Daily Use Pattern
```bash
# Morning: Production issue reported
1. Identify symptom (slow query, error, etc.)
2. Find last known good state (tag, branch, or date)
3. Write test to detect the symptom
4. Run git bisect run with test script
5. Find culprit commit and author
6. Analyze the change
7. Fix the issue
8. Tag the fix: git tag hotfix/v1.2.3
```

### Team Communication
```bash
# After finding the bad commit
git show <bad-commit>

# Email to team:
# "Found performance regression introduced in commit abc1234
# by John Doe on 2024-10-15. The issue is uncorrelated subquery
# in GetCustomerReport. Fix in progress."
```

## 🎊 Summary

Git bisect is a **powerful debugging tool** that:
- ✅ Finds problematic commits fast (binary search)
- ✅ Can be automated with test scripts
- ✅ Works with any measurable regression (performance, bugs, etc.)
- ✅ Integrates well with DBA testing workflows
- ✅ Saves hours of manual investigation

**When to use bisect:**
- Something broke and you know it worked before
- You have many commits to check
- You can write a test to detect the issue
- You need to find the exact commit (and author) responsible

**Next Steps:**
- Practice with the exercises above
- Write test scripts for your common issues
- Tag your stable releases for easy bisecting
- Share bisect knowledge with your team

**Next Lesson:** [Lesson 9: Git Hooks](./09-git-hooks.md) - Automate your workflow!
