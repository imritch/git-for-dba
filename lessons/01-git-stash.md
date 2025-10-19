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
# You can stash multiple times
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

```bash
# Create a new file (untracked)
echo "-- New procedure" > database/NewProc.sql

# Regular stash won't include untracked files
git stash  # This won't stash NewProc.sql

# Include untracked files
git stash -u  # or --include-untracked

# Include everything, even ignored files
git stash -a  # or --all
```

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

1. **Forgetting what's stashed**: Always use descriptive messages
   ```bash
   git stash save "Adding pagination to customer search - halfway done"
   ```

2. **Stash conflicts**: If you apply a stash and there are conflicts, resolve them like merge conflicts

3. **Stashing partial changes**: You can stash specific files
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
- `git stash pop` = apply and remove stash
- `git stash apply` = apply but keep stash
- Always use descriptive messages with `git stash save "message"`
- Stashes are local - they don't push to remote

## 📚 Next Lesson

Ready to handle conflicts when code collides? Move to [Lesson 2: Merge Conflicts](./02-merge-conflicts.md)

