# Lesson 4: Interactive Rebase - Master Your Git History

## 🎯 What You'll Master

This lesson dives deeper into interactive rebase with real-world DBA scenarios:
- Splitting commits
- Combining work from multiple developers
- Cleaning up "WIP" commits
- Removing debugging commits
- Creating perfect commit history for code review

**DBA Analogy:** Like refactoring a messy T-SQL script with multiple GOV statements and temporary code into a clean, production-ready script.

## 📝 Exercise 1: Splitting One Commit into Many

### Scenario: You committed table + indexes + procedures all at once

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Create a branch
git checkout -b feature/database-objects

# Make one big commit (bad practice)
cat > database/SalesSchema.sql << 'EOF'
-- Create Sales table
CREATE TABLE Sales (
    SaleId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    SaleDate DATETIME DEFAULT GETDATE()
);
GO

-- Create index
CREATE NONCLUSTERED INDEX IX_Sales_ProductId
ON Sales(ProductId);
GO

-- Create stored procedure
CREATE PROCEDURE dbo.GetSalesByProduct
    @ProductId INT
AS
BEGIN
    SELECT * FROM Sales WHERE ProductId = @ProductId;
END
GO
EOF

git add database/SalesSchema.sql
git commit -m "Add sales stuff"  # Terrible commit message!
```

### Step 1: Split the commit

```bash
# Start interactive rebase
git rebase -i HEAD~1

# Change 'pick' to 'edit'
# Git stops at that commit
```

### Step 2: Undo the commit but keep changes

```bash
# Reset the commit but keep changes in working directory
git reset HEAD^

# Verify files are unstaged
git status
```

### Step 3: Create separate logical commits

```bash
# Commit 1: Just the table
cat > database/SalesTable.sql << 'EOF'
-- Create Sales table
CREATE TABLE Sales (
    SaleId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    SaleDate DATETIME DEFAULT GETDATE()
);
EOF

git add database/SalesTable.sql
git commit -m "Create Sales table"

# Commit 2: The index
cat > database/SalesIndexes.sql << 'EOF'
-- Create index for product lookups
CREATE NONCLUSTERED INDEX IX_Sales_ProductId
ON Sales(ProductId);
EOF

git add database/SalesIndexes.sql
git commit -m "Add ProductId index on Sales table"

# Commit 3: The procedure
cat > database/GetSalesByProduct.sql << 'EOF'
-- Get sales by product
CREATE PROCEDURE dbo.GetSalesByProduct
    @ProductId INT
AS
BEGIN
    SELECT 
        SaleId,
        ProductId,
        Quantity,
        SaleDate
    FROM Sales 
    WHERE ProductId = @ProductId
    ORDER BY SaleDate DESC;
END
EOF

git add database/GetSalesByProduct.sql
git commit -m "Add GetSalesByProduct stored procedure"

# Continue rebase
git rebase --continue

# Clean up the original file
rm database/SalesSchema.sql
git add -A
git commit -m "Remove combined schema file"
```

### Step 4: View your clean history

```bash
git log --oneline
# Now you have 3 logical commits instead of 1 messy one!
```

## 📝 Exercise 2: Cleaning Up "WIP" Commits

### Scenario: Friday afternoon coding session

```bash
git checkout -b feature/customer-reports

# Initial work
cat > database/CustomerReport.sql << 'EOF'
CREATE PROCEDURE GetCustomerReport
AS
BEGIN
    SELECT * FROM Customers;
END
EOF

git add database/CustomerReport.sql
git commit -m "WIP customer report"

# Add more
cat > database/CustomerReport.sql << 'EOF'
CREATE PROCEDURE GetCustomerReport
    @StartDate DATE
AS
BEGIN
    SELECT CustomerId, CustomerName, Email 
    FROM Customers
    WHERE CreatedDate >= @StartDate;
END
EOF

git commit -am "WIP - added date filter"

# More work
cat > database/CustomerReport.sql << 'EOF'
CREATE PROCEDURE GetCustomerReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT 
        CustomerId, 
        CustomerName, 
        Email,
        TotalOrders,
        TotalRevenue
    FROM Customers
    WHERE CreatedDate BETWEEN @StartDate AND @EndDate
    ORDER BY TotalRevenue DESC;
END
EOF

git commit -am "finished customer report"

# Debug commit
cat >> database/CustomerReport.sql << 'EOF'
-- DEBUG: SELECT * FROM Customers
EOF

git commit -am "debug stuff"

# Remove debug
cat > database/CustomerReport.sql << 'EOF'
CREATE PROCEDURE GetCustomerReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CustomerId, 
        CustomerName, 
        Email,
        TotalOrders,
        TotalRevenue
    FROM Customers
    WHERE CreatedDate BETWEEN @StartDate AND @EndDate
    ORDER BY TotalRevenue DESC;
END
EOF

git commit -am "removed debug"
```

### Clean it up!

```bash
git log --oneline
# Shows 5 messy commits

# Interactive rebase
git rebase -i HEAD~5
```

**In the editor:**
```
pick a1b2c3d WIP customer report
squash e4f5g6h WIP - added date filter
squash i7j8k9l finished customer report
drop m1n2o3p debug stuff
squash p4q5r6s removed debug
```

**Update the commit message to:**
```
Add CustomerReport stored procedure

- Filters customers by date range
- Returns customer details with order metrics
- Ordered by revenue for business insights
```

Now you have ONE clean, professional commit!

## 📝 Exercise 3: Reordering Commits for Logical Flow

### Scenario: Commits made in development order, not logical order

```bash
git checkout -b feature/order-management

# Created in this order during development:

# 1. Procedure first (but depends on table)
cat > database/InsertOrder.sql << 'EOF'
CREATE PROCEDURE InsertOrder
    @CustomerId INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    INSERT INTO Orders (CustomerId, OrderDate, Amount)
    VALUES (@CustomerId, GETDATE(), @Amount);
END
EOF

git add database/InsertOrder.sql
git commit -m "Add InsertOrder procedure"

# 2. Then realized need the table
cat > database/OrdersTable.sql << 'EOF'
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderDate DATETIME NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);
EOF

git add database/OrdersTable.sql
git commit -m "Add Orders table"

# 3. Then add index
cat > database/OrdersIndexes.sql << 'EOF'
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON Orders(CustomerId);
EOF

git add database/OrdersIndexes.sql
git commit -m "Add index on Orders"

# 4. Finally, another procedure
cat > database/GetOrders.sql << 'EOF'
CREATE PROCEDURE GetCustomerOrders
    @CustomerId INT
AS
BEGIN
    SELECT * FROM Orders WHERE CustomerId = @CustomerId;
END
EOF

git add database/GetOrders.sql
git commit -m "Add GetCustomerOrders procedure"
```

### Reorder to logical sequence

```bash
git rebase -i HEAD~4
```

**Reorder to:**
```
pick <hash> Add Orders table
pick <hash> Add index on Orders
pick <hash> Add InsertOrder procedure
pick <hash> Add GetCustomerOrders procedure
```

Now your Git history matches the logical deployment order!

## 📝 Exercise 4: The "Exec" Command - Test Each Commit

### Scenario: Ensure each commit in history passes tests

```bash
git checkout -b feature/validated-procs

# Create 3 procedures
cat > database/Proc1.sql << 'EOF'
CREATE PROCEDURE TestProc1 AS BEGIN SELECT 1; END
EOF

git add database/Proc1.sql
git commit -m "Add TestProc1"

cat > database/Proc2.sql << 'EOF'
CREATE PROCEDURE TestProc2 AS BEGIN SELECT 2; END
EOF

git add database/Proc2.sql
git commit -m "Add TestProc2"

cat > database/Proc3.sql << 'EOF'
CREATE PROCEDURE TestProc3 AS BEGIN SELECT 3; END
EOF

git add database/Proc3.sql
git commit -m "Add TestProc3"

# Create a validation script
cat > scripts/validate.sh << 'EOF'
#!/bin/bash
echo "Validating SQL files..."
for file in database/*.sql; do
    if grep -q "PROCEDURE" "$file"; then
        echo "✓ $file looks valid"
    else
        echo "✗ $file is invalid"
        exit 1
    fi
done
echo "All files valid!"
EOF

chmod +x scripts/validate.sh

# Rebase with exec to test each commit
git rebase -i HEAD~3
```

**In the editor:**
```
pick <hash> Add TestProc1
exec ./scripts/validate.sh
pick <hash> Add TestProc2
exec ./scripts/validate.sh
pick <hash> Add TestProc3
exec ./scripts/validate.sh
```

Git will run your validation after each commit!

## 📝 Exercise 5: Editing Commit Content

### Scenario: Need to fix a commit in the middle

```bash
git checkout -b feature/fix-middle-commit

# Create 3 commits
echo "Commit 1" > file1.sql
git add file1.sql && git commit -m "Add file1"

echo "Commit 2 with TYPO" > file2.sql
git add file2.sql && git commit -m "Add file2"

echo "Commit 3" > file3.sql
git add file3.sql && git commit -m "Add file3"

# Want to fix the middle commit
git rebase -i HEAD~3
```

**Change to 'edit':**
```
pick <hash> Add file1
edit <hash> Add file2
pick <hash> Add file3
```

Git stops at commit 2:
```bash
# Fix the typo
echo "Commit 2 FIXED" > file2.sql

# Amend the commit
git add file2.sql
git commit --amend

# Continue
git rebase --continue
```

## 🎓 Advanced: Combining Work from Multiple Feature Branches

### Scenario: Merge and cleanup multiple related features

```bash
# Main work
git checkout main

# Feature 1: Table
git checkout -b feature/table
cat > database/Products.sql << 'EOF'
CREATE TABLE Products (ProductId INT, ProductName NVARCHAR(100));
EOF
git add database/Products.sql
git commit -m "Add Products table"

# Feature 2: Index
git checkout main
git checkout -b feature/index
git cherry-pick feature/table  # Get the table
cat >> database/Products.sql << 'EOF'
CREATE INDEX IX_Products_Name ON Products(ProductName);
EOF
git commit -am "Add index"

# Feature 3: Procedure
git checkout main
git checkout -b feature/integration

# Merge both features
git merge feature/table
git merge feature/index

# Clean up the history
git rebase -i main
# Squash merge commits, reorder, clean up
```

## ⚠️ Common Pitfalls

1. **Editing while conflicts exist**: Resolve conflicts first, then continue

2. **Losing track during complex rebase**: Use `git reflog` to recover

3. **Changing commit order when there are dependencies**: Git will conflict

4. **Not testing after reordering**: Always test the final result!

## 🎯 Real-World DBA Scenarios

### Scenario 1: Friday Afternoon Cleanup
```
Monday code review is coming
Clean up all "WIP", "fixing bug", "oops" commits
Create professional, logical commits
```

### Scenario 2: Preparing for Production
```
Development branch has 50 commits
Need to merge to main with clean history
Squash into 5-10 logical commits
Each commit should be deployable
```

### Scenario 3: Open Source Contribution
```
Forked a repo, made changes
Original repo moved forward
Rebase your changes on their latest
Clean up your commits before PR
```

## ✅ Practice Exercise

Create this complex scenario:
1. Make 10 commits with: tables, indexes, procedures, bug fixes, debug code
2. Use interactive rebase to:
   - Reorder: tables first, then indexes, then procedures
   - Squash: combine bug fix commits
   - Drop: remove debug commits
   - Edit: fix a commit in the middle
   - Reword: improve commit messages
3. Result: 4-5 clean, logical commits

## 🎓 Key Takeaways

- Interactive rebase is your history editor
- **Split commits**: `edit` → `reset HEAD^` → make new commits
- **Combine commits**: Use `squash` or `fixup`
- **Remove commits**: Use `drop`
- **Reorder commits**: Change line order (watch for dependencies!)
- **Test commits**: Use `exec` command
- Always create logical, reviewable commits
- Clean history = easier debugging and maintenance

## 🔧 Quick Reference

```bash
# Start interactive rebase
git rebase -i HEAD~N
git rebase -i <branch-name>
git rebase -i <commit-hash>

# Commands in interactive mode:
# pick   = use commit as-is
# reword = change commit message
# edit   = stop to amend commit
# squash = combine with previous (keep message)
# fixup  = combine with previous (discard message)
# drop   = remove commit
# exec   = run command

# During edit mode:
git commit --amend     # Modify current commit
git reset HEAD^        # Undo commit, keep changes
git rebase --continue  # Continue rebase
git rebase --abort     # Cancel rebase

# Helper commands:
git reflog            # See all HEAD movements
git cherry-pick <hash> # Apply specific commit
```

## 📚 Next Lesson

Ready to master merge strategies? Move to [Lesson 5: Merge Strategies](./05-merge-strategies.md)

