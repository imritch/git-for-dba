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

