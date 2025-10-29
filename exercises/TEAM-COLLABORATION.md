# Team Collaboration Scenarios

## 🎯 Overview

These scenarios simulate real-world team collaboration situations that DBAs face. Practice working with multiple developers, handling concurrent changes, code reviews, and team workflows.

**Prerequisites:**
- Complete Lessons 1-7
- Understand branching, merging, and rebasing
- Familiar with remote operations

## 📝 Scenario 1: The Parallel Development Conflict

### Situation

You and a teammate are both working on the same customer management system. You're both modifying stored procedures, and your changes will conflict.

### Exercise

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Setup: Create base version
git checkout main
cat > database/CustomerManagement.sql << 'EOF'
-- Customer Management Procedures
CREATE PROCEDURE dbo.GetCustomerDetails
    @CustomerId INT
AS
BEGIN
    SELECT CustomerId, CustomerName, Email
    FROM Customers
    WHERE CustomerId = @CustomerId;
END
GO

CREATE PROCEDURE dbo.UpdateCustomerEmail
    @CustomerId INT,
    @NewEmail NVARCHAR(100)
AS
BEGIN
    UPDATE Customers
    SET Email = @NewEmail
    WHERE CustomerId = @CustomerId;
END
GO
EOF

git add database/CustomerManagement.sql
git commit -m "Add customer management procedures"

# YOU: Work on feature/add-phone
git checkout -b feature/add-phone

cat > database/CustomerManagement.sql << 'EOF'
-- Customer Management Procedures
CREATE PROCEDURE dbo.GetCustomerDetails
    @CustomerId INT
AS
BEGIN
    -- YOU ADDED: Phone number
    SELECT CustomerId, CustomerName, Email, Phone
    FROM Customers
    WHERE CustomerId = @CustomerId;
END
GO

CREATE PROCEDURE dbo.UpdateCustomerEmail
    @CustomerId INT,
    @NewEmail NVARCHAR(100)
AS
BEGIN
    UPDATE Customers
    SET Email = @NewEmail,
        ModifiedDate = GETDATE()  -- YOU ADDED: Track modifications
    WHERE CustomerId = @CustomerId;
END
GO

-- YOU ADDED: New procedure for phone updates
CREATE PROCEDURE dbo.UpdateCustomerPhone
    @CustomerId INT,
    @NewPhone NVARCHAR(20)
AS
BEGIN
    UPDATE Customers
    SET Phone = @NewPhone,
        ModifiedDate = GETDATE()
    WHERE CustomerId = @CustomerId;
END
GO
EOF

git add database/CustomerManagement.sql
git commit -m "Add phone field and phone update procedure"

# TEAMMATE: Worked on feature/add-validation (simulate)
git checkout main
git checkout -b feature/add-validation

cat > database/CustomerManagement.sql << 'EOF'
-- Customer Management Procedures
CREATE PROCEDURE dbo.GetCustomerDetails
    @CustomerId INT
AS
BEGIN
    -- TEAMMATE ADDED: Validation
    IF @CustomerId IS NULL OR @CustomerId <= 0
        THROW 50000, 'Invalid CustomerId', 1;

    SELECT CustomerId, CustomerName, Email, LastLoginDate
    FROM Customers
    WHERE CustomerId = @CustomerId;
END
GO

CREATE PROCEDURE dbo.UpdateCustomerEmail
    @CustomerId INT,
    @NewEmail NVARCHAR(100)
AS
BEGIN
    -- TEAMMATE ADDED: Email validation
    IF @NewEmail IS NULL OR @NewEmail NOT LIKE '%@%'
        THROW 50001, 'Invalid email format', 1;

    UPDATE Customers
    SET Email = @NewEmail
    WHERE CustomerId = @CustomerId;
END
GO

-- TEAMMATE ADDED: New procedure for customer status
CREATE PROCEDURE dbo.UpdateCustomerStatus
    @CustomerId INT,
    @IsActive BIT
AS
BEGIN
    UPDATE Customers
    SET IsActive = @IsActive
    WHERE CustomerId = @CustomerId;
END
GO
EOF

git add database/CustomerManagement.sql
git commit -m "Add validation and status update procedure"

# Merge teammate's work to main first (they finished first)
git checkout main
git merge feature/add-validation
git branch -d feature/add-validation

# NOW YOU: Try to merge your work
git checkout feature/add-phone
git rebase main

# CONFLICT! Now resolve it
echo "🔥 CONFLICT! You need to resolve this."
echo ""
echo "Your task:"
echo "1. Resolve the conflict combining BOTH changes"
echo "2. Include phone field AND validation"
echo "3. Include phone update AND status update procedures"
echo "4. Test that both features work together"
```

### Solution

```bash
# Option 1: Use merge tool
git mergetool

# Option 2: Manual resolution
# Edit database/CustomerManagement.sql to combine:
# - Your phone additions
# - Teammate's validation
# - Both new procedures

# The final version should have:
# - GetCustomerDetails: Phone + LastLoginDate + Validation
# - UpdateCustomerEmail: ModifiedDate + Validation
# - UpdateCustomerPhone: Your new procedure
# - UpdateCustomerStatus: Teammate's new procedure

git add database/CustomerManagement.sql
git rebase --continue
git checkout main
git merge feature/add-phone
```

### Key Lessons

- **Communicate**: Talk to teammates about what you're changing
- **Pull often**: Rebase frequently to catch conflicts early
- **Small commits**: Easier to merge when commits are focused
- **Test together**: After merging, test that both features work

## 📝 Scenario 2: The Code Review Dance

### Situation

You've completed a feature. Now you need to:
1. Clean up your commits for review
2. Address review feedback
3. Keep your branch up to date with main

### Exercise

```bash
# Create a messy feature branch (realistic!)
git checkout main
git checkout -b feature/customer-search

# Commit 1: Start work
echo "-- Search v1" > database/SearchCustomers.sql
git add database/SearchCustomers.sql
git commit -m "WIP search"

# Commit 2: Fix typo
echo "-- Search v2" > database/SearchCustomers.sql
git add database/SearchCustomers.sql
git commit -m "fix typo"

# Commit 3: Add more
echo "-- Search v3" > database/SearchCustomers.sql
git add database/SearchCustomers.sql
git commit -m "add more stuff"

# Commit 4: Debug print (oops)
echo "-- Debug: SELECT * FROM Customers" >> database/SearchCustomers.sql
git add database/SearchCustomers.sql
git commit -m "debug"

# Commit 5: Remove debug
echo "-- Search v4 (cleaned)" > database/SearchCustomers.sql
git add database/SearchCustomers.sql
git commit -m "remove debug"

# Commit 6: Final touches
echo "-- Search v5 (final)" > database/SearchCustomers.sql
git add database/SearchCustomers.sql
git commit -m "done!"

git log --oneline
# See the messy history!

# TASK 1: Clean up before code review
# Use interactive rebase to squash into 1 commit
git rebase -i main

# In the editor:
# pick abc1234 WIP search
# squash def5678 fix typo
# squash ghi9012 add more stuff
# squash jkl3456 debug
# squash mno7890 remove debug
# squash pqr1234 done!

# Write a good commit message:
# "Add customer search procedure
#
# - Implements search by name, email, phone
# - Includes pagination support
# - Optimized with proper indexes"

# TASK 2: Simulate review feedback
# Reviewer says: "Add error handling"

cat > database/SearchCustomers.sql << 'EOF'
-- Customer Search Procedure
CREATE PROCEDURE dbo.SearchCustomers
    @SearchTerm NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Review feedback: Add error handling
    BEGIN TRY
        IF @SearchTerm IS NULL OR LEN(@SearchTerm) < 3
            THROW 50000, 'Search term must be at least 3 characters', 1;

        SELECT CustomerId, CustomerName, Email, Phone
        FROM Customers
        WHERE
            CustomerName LIKE '%' + @SearchTerm + '%'
            OR Email LIKE '%' + @SearchTerm + '%'
            OR Phone LIKE '%' + @SearchTerm + '%'
        ORDER BY CustomerName;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
EOF

git add database/SearchCustomers.sql
git commit -m "Address code review: Add error handling"

# TASK 3: Main branch has moved forward
# Simulate by making a commit on main
git checkout main
echo "-- Other work" > database/OtherProcedure.sql
git add database/OtherProcedure.sql
git commit -m "Other team member's work"

# TASK 4: Rebase your feature branch
git checkout feature/customer-search
git rebase main

# Now push (simulated)
# git push --force-with-lease origin feature/customer-search
```

### Key Lessons

- **Clean commits before PR**: Use interactive rebase
- **Address feedback in new commits**: Makes review easier
- **Keep branch updated**: Rebase on main regularly
- **Force push safely**: Use `--force-with-lease`

## 📝 Scenario 3: The Emergency Hotfix During Feature Work

### Situation

You're working on a large feature when a production bug is reported. You need to:
1. Save your feature work
2. Create and deploy hotfix
3. Return to feature work
4. Ensure hotfix is in your feature branch

### Exercise

```bash
# YOU: Working on large feature
git checkout main
git checkout -b feature/reporting-system

# Create several commits
for i in {1..3}; do
    echo "-- Report $i" > "database/Report$i.sql"
    git add "database/Report$i.sql"
    git commit -m "Add Report $i"
done

# In the middle of uncommitted work
echo "-- Report 4 (half done)" > database/Report4.sql
# NOT committed yet

# 🚨 URGENT: Production bug reported!
# Current query in GetTopCustomers is missing index hint

# STEP 1: Save your work
git stash save "WIP: Report 4 - half done"

# STEP 2: Create hotfix
git checkout main
git checkout -b hotfix/missing-index-hint

cat > database/GetTopCustomers.sql << 'EOF'
-- HOTFIX: Add missing index hint
CREATE PROCEDURE dbo.GetTopCustomers
    @TopN INT
AS
BEGIN
    SELECT TOP (@TopN)
        CustomerId,
        CustomerName,
        TotalPurchases
    FROM Customers WITH (INDEX(IX_Customers_TotalPurchases))
    ORDER BY TotalPurchases DESC;
END
EOF

git add database/GetTopCustomers.sql
git commit -m "HOTFIX: Add missing index hint to GetTopCustomers"

# STEP 3: Deploy hotfix to production (merge to main)
git checkout main
git merge hotfix/missing-index-hint
git tag hotfix-v1.2.1
echo "✅ Hotfix deployed to production"

# STEP 4: Bring hotfix into your feature branch
git checkout feature/reporting-system
git merge main  # Or: git rebase main

# STEP 5: Continue your work
git stash pop

# Finish Report 4
echo "-- Report 4 (complete)" > database/Report4.sql
git add database/Report4.sql
git commit -m "Add Report 4"

git log --oneline --graph --all
```

### Key Lessons

- **Stash for quick switches**: Perfect for emergencies
- **Tag hotfixes**: Easy to track production deployments
- **Merge hotfix to feature**: Ensures your feature has the fix
- **Clean up branches**: Delete hotfix branch after merging

## 📝 Scenario 4: The Multi-Person Merge Train

### Situation

Your team has 3 developers finishing features simultaneously. You need to merge all features to main without conflicts.

### Exercise

```bash
# DEVELOPER 1: Indexes
git checkout main
git checkout -b feature/add-indexes

cat > database/Indexes.sql << 'EOF'
CREATE INDEX IX_Customers_Email ON Customers(Email);
CREATE INDEX IX_Orders_Date ON Orders(OrderDate);
EOF

git add database/Indexes.sql
git commit -m "Add performance indexes"

# DEVELOPER 2: Stored Procedures
git checkout main
git checkout -b feature/add-procedures

cat > database/NewProcedures.sql << 'EOF'
CREATE PROCEDURE dbo.GetOrderHistory
    @CustomerId INT
AS
BEGIN
    SELECT * FROM Orders WHERE CustomerId = @CustomerId;
END
EOF

git add database/NewProcedures.sql
git commit -m "Add order history procedure"

# DEVELOPER 3: Views (you)
git checkout main
git checkout -b feature/add-views

cat > database/Views.sql << 'EOF'
CREATE VIEW vw_CustomerSummary AS
SELECT CustomerId, CustomerName, COUNT(OrderId) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerId = o.CustomerId
GROUP BY c.CustomerId, c.CustomerName;
EOF

git add database/Views.sql
git commit -m "Add customer summary view"

# MERGE TRAIN: Dev 1 merges first
git checkout main
git merge feature/add-indexes
echo "✅ Dev 1 merged"

# Dev 2 needs to rebase
git checkout feature/add-procedures
git rebase main
git checkout main
git merge feature/add-procedures
echo "✅ Dev 2 merged"

# YOUR TURN: Rebase and merge
git checkout feature/add-views
git rebase main  # Should be clean since different files
git checkout main
git merge feature/add-views
echo "✅ You merged"

# View the result
git log --oneline --graph
```

### Best Practices for Merge Trains

1. **First In**: Simplest merge (no rebasing needed)
2. **Others**: Rebase before merging
3. **Communicate**: Use chat/Slack to coordinate
4. **Small PRs**: Easier to merge quickly
5. **CI/CD**: Automated tests catch integration issues

## 📝 Scenario 5: The Shared Feature Branch

### Situation

You and a teammate are working on the same feature branch. You need to coordinate pushing and pulling changes.

### Exercise

```bash
# Setup shared feature branch
git checkout main
git checkout -b feature/customer-portal

# YOU: Make first commit
cat > database/PortalLogin.sql << 'EOF'
CREATE PROCEDURE dbo.ValidatePortalLogin
    @Username NVARCHAR(100),
    @Password NVARCHAR(100)
AS
BEGIN
    -- Login validation
    SELECT UserId FROM PortalUsers
    WHERE Username = @Username AND PasswordHash = HASHBYTES('SHA2_256', @Password);
END
EOF

git add database/PortalLogin.sql
git commit -m "Add portal login validation"

# Push to remote (simulated)
# git push -u origin feature/customer-portal

echo "✅ You pushed your changes"

# TEAMMATE: Makes their commit (simulated)
cat > database/PortalRegistration.sql << 'EOF'
CREATE PROCEDURE dbo.RegisterPortalUser
    @Username NVARCHAR(100),
    @Email NVARCHAR(100),
    @Password NVARCHAR(100)
AS
BEGIN
    -- User registration
    INSERT INTO PortalUsers (Username, Email, PasswordHash, CreatedDate)
    VALUES (@Username, @Email, HASHBYTES('SHA2_256', @Password), GETDATE());
END
EOF

git add database/PortalRegistration.sql
git commit -m "Add portal user registration"

echo "📨 Teammate pushed their changes"

# YOU: Try to push again
echo "-- Added comment" >> database/PortalLogin.sql
git add database/PortalLogin.sql
git commit -m "Add comment to login procedure"

# git push
# ❌ Rejected! Remote has changes you don't have

# SOLUTION 1: Pull with rebase (cleaner history)
# git pull --rebase origin feature/customer-portal
git rebase HEAD~1  # Simulate pulling teammate's commit

# SOLUTION 2: Pull with merge (preserves parallel work)
# git pull origin feature/customer-portal

# Now push
# git push origin feature/customer-portal
```

### Rules for Shared Branches

1. **Pull before push**: Always get latest changes first
2. **Use rebase**: `git pull --rebase` for cleaner history
3. **Communicate**: Tell teammate before force-pushing
4. **Never force push without --force-with-lease**
5. **Commit often**: Smaller commits = fewer conflicts

## 📝 Scenario 6: The Code Review Revision Loop

### Situation

You submitted a PR. Reviewer requested changes. You need to address feedback while main branch continues to move forward.

### Exercise

```bash
# Initial PR
git checkout main
git checkout -b feature/audit-logging

cat > database/AuditLog.sql << 'EOF'
CREATE TABLE AuditLog (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100),
    Action NVARCHAR(50),
    UserId INT,
    Timestamp DATETIME DEFAULT GETDATE()
);
EOF

git add database/AuditLog.sql
git commit -m "Add audit log table"

# Push and create PR (simulated)
echo "✅ PR created: #123"

# REVIEWER: Requests changes
echo "📝 Review feedback:"
echo "1. Add indexed column for faster queries"
echo "2. Include IP address tracking"
echo "3. Add stored procedure for logging"

# MEANWHILE: Main branch moves forward
git checkout main
echo "-- Other work" > database/OtherChanges.sql
git add database/OtherChanges.sql
git commit -m "Other team changes"

# YOU: Address feedback
git checkout feature/audit-logging

cat > database/AuditLog.sql << 'EOF'
CREATE TABLE AuditLog (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100),
    Action NVARCHAR(50),
    UserId INT,
    Timestamp DATETIME DEFAULT GETDATE(),
    IpAddress NVARCHAR(45),  -- Review feedback: Add IP tracking
    INDEX IX_AuditLog_Timestamp (Timestamp DESC)  -- Review feedback: Add index
);
GO

-- Review feedback: Add logging procedure
CREATE PROCEDURE dbo.LogAuditEntry
    @TableName NVARCHAR(100),
    @Action NVARCHAR(50),
    @UserId INT,
    @IpAddress NVARCHAR(45)
AS
BEGIN
    INSERT INTO AuditLog (TableName, Action, UserId, IpAddress)
    VALUES (@TableName, @Action, @UserId, @IpAddress);
END
EOF

git add database/AuditLog.sql
git commit -m "Address review feedback: Add IP tracking, index, and logging procedure"

# Update your branch with latest main
git fetch origin
git rebase origin/main

# Push updated branch (force push needed after rebase)
# git push --force-with-lease origin feature/audit-logging

echo "✅ PR updated with review feedback"

# REVIEWER: Approves
echo "✅ PR approved!"

# Final merge
git checkout main
git merge feature/audit-logging
git push origin main
git branch -d feature/audit-logging
```

### PR Best Practices

1. **Address feedback in new commits**: Easier for reviewer to see changes
2. **Rebase before final merge**: Clean history in main
3. **Test after addressing feedback**: Don't break existing functionality
4. **Communicate**: Comment on PR explaining your changes
5. **Be patient**: Good reviews take time

## 🎓 Summary

**Key Team Collaboration Skills:**
- **Communicate**: Talk before changing shared files
- **Pull often**: Stay up to date with team's work
- **Clean commits**: Squash before PR, address feedback in new commits
- **Rebase vs merge**: Know when to use each
- **Stash for emergencies**: Quick context switching
- **Coordinate merges**: Be aware of merge trains
- **Review feedback loop**: Address, rebase, push with --force-with-lease

**Next Steps:**
- Practice these scenarios with a real teammate
- Set up team workflows documented in [GIT-WORKFLOW.md](../GIT-WORKFLOW.md)
- Configure Git hooks for team standards ([Lesson 9](../lessons/09-git-hooks.md))
- Learn about worktrees for managing multiple branches ([GIT-WORKTREES.md](../docs/GIT-WORKTREES.md))
