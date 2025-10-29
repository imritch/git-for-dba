# Lesson 1: Git Stash - Your Temporary Workspace

## 🎯 What is Git Stash?

Git stash lets you temporarily save uncommitted changes (both staged and unstaged) so you can switch contexts without committing half-done work.

**DBA Analogy:** Like taking a SQL Server snapshot before making changes - you can come back to that exact state later.

## 🤔 When Do You Need It?

**Scenario:** You're updating a stored procedure when your manager says "DROP EVERYTHING! Production bug in another stored proc - fix it NOW!"

You don't want to:
- ❌ Commit half-finished work
- ❌ Lose your current changes
- ❌ Create a messy commit history

You want to:
- ✅ Save your work temporarily
- ✅ Switch to fix the bug
- ✅ Come back and continue where you left off

## 📝 Exercise 1: Basic Stash

### Step 1: Create a SQL file and make changes

```bash
# Make sure you're in the git-for-dba directory
cd /Users/riteshchawla/RC/git/git-for-dba

# Create and add a stored procedure
cat > database/GetCustomerOrders.sql << 'EOF'
-- Get Customer Orders
CREATE PROCEDURE dbo.GetCustomerOrders
    @CustomerId INT
AS
BEGIN
    SELECT 
        OrderId,
        OrderDate,
        TotalAmount
    FROM Orders
    WHERE CustomerId = @CustomerId;
END
EOF

# Commit this as our base
git add database/GetCustomerOrders.sql
git commit -m "Add GetCustomerOrders stored procedure"
```

### Step 2: Start making changes

```bash
# Now you're updating the stored proc to add error handling
cat > database/GetCustomerOrders.sql << 'EOF'
-- Get Customer Orders with Error Handling
CREATE PROCEDURE dbo.GetCustomerOrders
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- TODO: Add validation
        -- TODO: Add logging
        
        SELECT 
            OrderId,
            OrderDate,
            TotalAmount,
            Status  -- Adding new column
        FROM Orders
        WHERE CustomerId = @CustomerId;
        
    END TRY
    BEGIN CATCH
        -- Error handling in progress...
    END CATCH
END
EOF

# Check your changes
git status
git diff
```

### Step 3: Emergency! Need to switch tasks

```bash
# Save your work-in-progress
git stash

# OR with a descriptive message (better practice)
git stash save "WIP: Adding error handling to GetCustomerOrders"

# Verify your working directory is clean
git status
```

### Step 4: Work on the urgent bug

```bash
# Your working directory is now clean - fix the urgent bug
cat > database/FixProductionBug.sql << 'EOF'
-- Emergency fix: Add missing index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON Orders(CustomerId)
INCLUDE (OrderDate, TotalAmount, Status);
EOF

git add database/FixProductionBug.sql
git commit -m "HOTFIX: Add missing index on Orders table"
```

### Step 5: Return to your original work

```bash
# List your stashes
git stash list

# Apply your stashed changes
git stash pop

# OR if you want to keep the stash (apply without removing)
git stash apply

# Continue working on your changes
git status
```

## 📝 Exercise 2: Multiple Stashes

```bash
# First, create some files we can work with
echo "-- Proc 1" > database/Proc1.sql
echo "-- Proc 2" > database/Proc2.sql
echo "-- Proc 3" > database/Proc3.sql
git add database/Proc*.sql
git commit -m "Add three procedures"

# Now you can stash multiple times (modifying existing tracked files)
echo "-- Change 1" >> database/Proc1.sql
git stash save "Work on Proc1"

echo "-- Change 2" >> database/Proc2.sql
git stash save "Work on Proc2"

echo "-- Change 3" >> database/Proc3.sql
git stash save "Work on Proc3"

# List all stashes
git stash list
# Output:
# stash@{0}: On main: Work on Proc3
# stash@{1}: On main: Work on Proc2
# stash@{2}: On main: Work on Proc1

# Apply a specific stash
git stash apply stash@{1}

# Drop a specific stash
git stash drop stash@{1}

# Clear all stashes
git stash clear
```

## 📝 Exercise 3: Stash with Untracked Files

**Important:** By default, `git stash` only stashes changes to **tracked files** (files already in Git). It ignores **untracked files** (new files never added).

```bash
# Create a new file (untracked - not in Git yet)
echo "-- New procedure" > database/NewProc.sql

# Check status
git status
# Shows: Untracked files: database/NewProc.sql

# Regular stash WON'T include untracked files
git stash
git status  # NewProc.sql is still there!

# Solution 1: Include untracked files with -u flag
echo "-- Another new proc" > database/AnotherProc.sql
git stash -u  # or --include-untracked
git status    # Now it's clean!

# Solution 2: Add files first (makes them tracked)
echo "-- Yet another proc" > database/YetAnotherProc.sql
git add database/YetAnotherProc.sql
git stash  # Now it works because file is tracked

# Solution 3: Include everything, even .gitignore files
git stash -a  # or --all (be careful with this!)
```

**Summary:**
- `git stash` → Only stashes tracked files
- `git stash -u` → Stashes tracked + untracked files
- `git stash -a` → Stashes everything including ignored files

## 🎓 Advanced: Stash Operations

```bash
# View what's in a stash
git stash show stash@{0}

# View full diff of a stash
git stash show -p stash@{0}

# Create a branch from a stash
git stash branch feature-error-handling stash@{0}
# This creates a new branch and applies the stash
```

## ⚠️ Common Pitfalls

1. **Stashing untracked files**: By default, `git stash` only saves changes to tracked files!
   ```bash
   # Wrong - new file won't be stashed
   echo "-- New" > NewFile.sql
   git stash  # NewFile.sql is NOT stashed!
   
   # Right - use -u flag for untracked files
   git stash -u
   
   # Or add the file first to make it tracked
   git add NewFile.sql
   git stash
   ```

2. **Forgetting what's stashed**: Always use descriptive messages
   ```bash
   git stash save "Adding pagination to customer search - halfway done"
   ```

3. **Stash conflicts**: If you apply a stash and there are conflicts, resolve them like merge conflicts

4. **Stashing partial changes**: You can stash specific files
   ```bash
   git stash push -m "Only stash this file" database/SpecificProc.sql
   ```

## 🎯 Real-World DBA Scenarios

### Scenario 1: Context Switching
```bash
# Working on index optimization
git stash save "Index optimization for Orders table"

# Switch to statistics update
# ... do work ...
git commit -m "Update statistics job"

# Back to indexes
git stash pop
```

### Scenario 2: Testing Clean State
```bash
# You made changes but want to test without them
git stash
# Test...
git stash pop  # Bring changes back
```

### Scenario 3: Splitting Work
```bash
# You modified 5 stored procs but should commit separately
git stash  # Stash all changes
git stash pop  # Get them back
git add database/Proc1.sql
git commit -m "Update Proc1"
# Repeat for other files
```

## ✅ Practice Exercise

Try this sequence:
1. Create a new SQL file with a table definition
2. Commit it
3. Modify the file (add columns)
4. Stash your changes
5. Create a different file and commit it
6. Pop your stash
7. Commit your stashed changes

## 🚀 Advanced Stash Techniques

### Exercise 4: Partial Stashing (Interactive Mode)

Sometimes you want to stash only PART of your changes, not everything. This is where interactive stashing shines!

**Scenario:** You're working on a stored procedure. You fixed a bug AND started adding a new feature. You want to commit the bug fix now, but save the feature work for later.

```bash
# Create a file with mixed changes
cat > database/UpdateCustomer.sql << 'EOF'
-- Update Customer Procedure
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @Name NVARCHAR(100),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- BUG FIX: Add validation (WANT TO COMMIT THIS)
    IF @CustomerId IS NULL
        THROW 50000, 'CustomerId cannot be null', 1;

    -- BUG FIX: Check if customer exists (WANT TO COMMIT THIS)
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerId)
        THROW 50001, 'Customer not found', 1;

    UPDATE Customers
    SET
        CustomerName = @Name,
        Email = @Email,
        ModifiedDate = GETDATE()
    WHERE CustomerId = @CustomerId;

    -- NEW FEATURE: Add audit logging (STASH THIS FOR LATER)
    INSERT INTO AuditLog (TableName, RecordId, Action, ModifiedBy, ModifiedDate)
    VALUES ('Customers', @CustomerId, 'UPDATE', SYSTEM_USER, GETDATE());

    -- NEW FEATURE: Send notification (STASH THIS FOR LATER)
    EXEC dbo.SendCustomerUpdateNotification @CustomerId;
END
EOF

git add database/UpdateCustomer.sql
git commit -m "Initial version of UpdateCustomer"

# Now modify it with bug fixes AND new features
cat > database/UpdateCustomer.sql << 'EOF'
-- Update Customer Procedure (Enhanced)
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @Name NVARCHAR(100),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- BUG FIX: Add validation (COMMIT THIS)
    IF @CustomerId IS NULL OR @CustomerId <= 0
        THROW 50000, 'Invalid CustomerId', 1;

    -- BUG FIX: Add transaction (COMMIT THIS)
    BEGIN TRANSACTION;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerId)
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50001, 'Customer not found', 1;
        END

        UPDATE Customers
        SET
            CustomerName = @Name,
            Email = @Email,
            ModifiedDate = GETDATE()
        WHERE CustomerId = @CustomerId;

        -- NEW FEATURE: Audit logging (STASH THIS)
        INSERT INTO AuditLog (TableName, RecordId, Action, ModifiedBy, ModifiedDate)
        VALUES ('Customers', @CustomerId, 'UPDATE', SYSTEM_USER, GETDATE());

        -- NEW FEATURE: Email notification (STASH THIS)
        DECLARE @NotificationEmail NVARCHAR(100);
        SELECT @NotificationEmail = Email FROM Customers WHERE CustomerId = @CustomerId;
        EXEC dbo.SendEmailNotification @NotificationEmail, 'Profile Updated';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
EOF

# Now use interactive stashing to stash ONLY the new feature parts
git stash push -p

# Git will show each change (hunk) and ask what to do:
# Stage this hunk [y,n,q,a,d,e,?]?
#
# y - stash this hunk
# n - don't stash this hunk
# q - quit
# a - stash this and all remaining hunks
# d - don't stash this or remaining hunks
# e - manually edit the hunk
# ? - help

# Walk through and:
# - Type 'n' for bug fix changes (keep them to commit)
# - Type 'y' for new feature changes (stash for later)
```

**Interactive stashing is powerful for:**
- Separating bug fixes from features
- Committing only related changes
- Keeping your commits focused and atomic

### Exercise 5: Stashing Specific Files Only

```bash
# Create multiple files
echo "-- Proc 1 changes" >> database/Proc1.sql
echo "-- Proc 2 changes" >> database/Proc2.sql
echo "-- Proc 3 changes" >> database/Proc3.sql

# Stash only Proc1 and Proc2, keep Proc3 changes
git stash push -m "Stash Proc1 and Proc2 only" database/Proc1.sql database/Proc2.sql

# Verify: Proc3 changes are still in working directory
git status  # Should show Proc3.sql modified
git stash list  # Should show your stash

# Later, get them back
git stash pop
```

### Exercise 6: Creating a Branch from a Stash

**Scenario:** You stashed some work, but now realize it's complex enough to deserve its own feature branch.

```bash
# You have some stashed work
echo "-- Complex feature" >> database/ComplexProc.sql
git stash save "Complex feature work"

# Instead of popping on current branch, create new branch
git stash branch feature/complex-feature stash@{0}

# This:
# 1. Creates new branch 'feature/complex-feature'
# 2. Checks out the branch
# 3. Applies the stash
# 4. Drops the stash if successful

# You're now on a new branch with your changes applied!
git branch  # Shows you're on feature/complex-feature
git status  # Shows your changes
```

### Exercise 7: Inspecting Stashes Without Applying

```bash
# List all stashes with more detail
git stash list --stat

# See what's in a specific stash (summary)
git stash show stash@{0}

# See full diff of what's in a stash
git stash show -p stash@{0}

# Or use:
git stash show --patch stash@{0}

# Search for specific content in stashes
git stash list | while read stash; do
    echo "Checking $stash"
    git stash show -p "$stash" | grep -i "CustomerId"
done
```

### Exercise 8: Stash with Pathspec (Wildcards)

```bash
# Stash all stored procedures but not tables
git stash push -m "Stash all SPs" database/*Proc*.sql

# Stash all index files
git stash push -m "Stash indexes" database/Index*.sql

# Stash everything in a subdirectory
git stash push -m "Stash migrations" database/migrations/*.sql
```

### Exercise 9: Recovering a Dropped Stash

**Scenario:** You accidentally dropped a stash! Can you recover it?

```bash
# Create and drop a stash
echo "-- Important work" >> database/ImportantWork.sql
git stash save "Important work I'll accidentally drop"

# Oops, dropped it!
git stash drop stash@{0}

# OH NO! Can we recover it?
# YES! Stashes are commits in disguise

# Find the dropped stash
git fsck --unreachable | grep commit

# This shows unreachable commits
# Stashes will have commit messages starting with "WIP on" or your message

# View the stash commits
for commit in $(git fsck --unreachable | grep commit | cut -d' ' -f3); do
    echo "=== Commit $commit ==="
    git log -1 --pretty=format:"%s" $commit
    echo ""
done

# When you find your stash, apply it
git stash apply <commit-hash>

# Or recreate the stash
git stash store -m "Recovered important work" <commit-hash>
```

### Exercise 10: Stash vs WIP Commits (When to Use Each)

**When to use stash:**
```bash
# ✅ Quick context switch (coming back soon)
git stash save "WIP: Adding pagination"

# ✅ Testing without your changes
git stash
# Test...
git stash pop

# ✅ Pulling latest changes
git stash
git pull
git stash pop
```

**When to use WIP commits instead:**
```bash
# ✅ End of day (might not come back to this for days)
git add .
git commit -m "WIP: Pagination - halfway through page size logic"

# ✅ Complex work you want in history
git commit -m "WIP: Complex refactoring checkpoint"

# ✅ Want to share work-in-progress with team
git commit -m "WIP: Need help with this approach"
git push

# Later, squash WIP commits with interactive rebase
git rebase -i main
# Mark WIP commits as 'fixup' or 'squash'
```

**Comparison:**
| Aspect | Stash | WIP Commits |
|--------|-------|-------------|
| **Visibility** | Local only | In commit history |
| **Sharing** | Can't share | Can push to remote |
| **Duration** | Short-term | Long-term |
| **Organization** | Stack (LIFO) | Linear history |
| **Multiple files** | All or selected | Any combination |
| **Cleanup** | Automatic (pop) | Manual (rebase) |

### 🎯 Advanced Stash Patterns

#### Pattern 1: The Experimentation Stash

```bash
# Before risky experiment
git stash save "BACKUP: Before trying risky refactoring"

# Try experiment
# ... make changes ...

# If it works:
git stash drop

# If it fails:
git reset --hard HEAD
git stash pop  # Back to starting point
```

#### Pattern 2: The Cherry-Pick Stash

```bash
# You made changes but need only some of them now
git stash save "Mixed changes"

# Get them back
git stash apply

# Stage only what you want
git add -p  # Interactive add

# Commit
git commit -m "Just the parts I needed"

# Restore stash to original state
git reset --hard HEAD
git stash apply  # All changes back
```

#### Pattern 3: The Multi-Branch Stash

```bash
# Stash work from feature branch
git stash save "Feature work"

# Switch to different branch
git checkout main

# Create new branch
git checkout -b feature/different-approach

# Apply the same stashed changes here
git stash apply stash@{0}

# You now have the same changes on a different branch!
```

## 🎓 Key Takeaways

- `git stash` = temporary storage for uncommitted work
- **By default, only stashes tracked files** (use `-u` for untracked files)
- `git stash pop` = apply and remove stash
- `git stash apply` = apply but keep stash
- `git stash list` = see all your stashes
- Always use descriptive messages with `git stash save "message"`
- Stashes are local - they don't push to remote
- `git stash -u` = include untracked (new) files
- `git stash -a` = include all files, even ignored ones

## 📚 Next Lesson

Ready to handle conflicts when code collides? Move to [Lesson 2: Merge Conflicts](./02-merge-conflicts.md)

