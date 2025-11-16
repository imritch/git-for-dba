# Lesson 3: Git Rebase - Rewriting History for Clarity

## 🎯 What is Git Rebase?

Rebase moves or replays your commits onto a different base commit, creating a linear history instead of a merge commit.

**DBA Analogy:** Like re-applying your SQL script changes on top of the latest production schema, instead of merging two different schema versions.

## 🤔 Rebase vs Merge

### Merge:
```
    A---B---C  main
         \   \
          D---E---M  feature (M is merge commit)
```

### Rebase:
```
    A---B---C  main
             \
              D'---E'  feature (commits replayed)
```

### More Context
Core Difference

  Git Merge:
  - Creates a new "merge commit" that combines two branches
  - Preserves the complete history of both branches
  - Shows that parallel development happened
  - Non-destructive - doesn't change existing commits

  Git Rebase:
  - Moves/rewrites your commits on top of another branch
  - Creates a linear history (no merge commits)
  - Rewrites commit history with new commit hashes
  - Makes it look like development happened sequentially

  Visual Example

  Starting point:
  main:     A---B---C
                 \
  feature:        D---E

  After git merge:
  main:     A---B---C-------M
                 \         /
  feature:        D---E---
  (M is a new merge commit)

  After git rebase:
  main:     A---B---C---D'---E'
  (D' and E' are new commits with different hashes)

  What They're Implying When They Say "Merge, Not Rebase"

  When someone specifically asks for a merge, they likely want:

  1. Preserve true history - Show that work actually happened in parallel
  2. Traceability - The merge commit acts as a milestone showing when feature work
  was integrated
  3. Safety - Avoid rewriting shared history (rebasing rewrites commits)
  4. Team visibility - Merge commits show collaboration points
  5. Code review integration - Many PR/code review workflows expect merge commits

  When to Use Each

  Use Merge when:
  - Working on shared/public branches
  - You want to preserve the context of feature development
  - Team policy requires it (common in enterprise environments)
  - Working with pull requests that others may have based work on

  Use Rebase when:
  - Cleaning up local feature branches before sharing
  - You want a clean, linear history
  - Catching up your feature branch with main before creating a PR
  - Your commits are still private/local


**Key Difference:** Rebase rewrites history to make it linear. Merge preserves the branching history.

## 📝 Exercise 1: Basic Rebase

### Step 1: Setup the scenario

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Create a base table script
cat > database/Customers.sql << 'EOF'
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100)
);
EOF

git add database/Customers.sql
git commit -m "Create Customers table"

# Create a feature branch
git checkout -b feature/add-indexes

# Add an index
cat >> database/Customers.sql << 'EOF'

-- Index for email lookups
CREATE NONCLUSTERED INDEX IX_Customers_Email
ON Customers(Email);
EOF

git add database/Customers.sql
git commit -m "Add email index"

# Add another index
cat >> database/Customers.sql << 'EOF'

-- Index for name searches
CREATE NONCLUSTERED INDEX IX_Customers_Name
ON Customers(CustomerName);
EOF

git add database/Customers.sql
git commit -m "Add name index"
```

### Step 2: Meanwhile, main branch progresses

```bash
# Switch back to main
git checkout main

# Someone adds a column
cat > database/Customers.sql << 'EOF'
CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE()
);
EOF

git add database/Customers.sql
git commit -m "Add CreatedDate column to Customers"
```

### Step 3: Rebase your feature branch

```bash
# View the current state
git log --oneline --graph --all

# Switch to feature branch
git checkout feature/add-indexes

# Rebase onto main
git rebase main
```

**What happens:**
1. Git finds the common ancestor
2. Temporarily saves your feature commits (add indexes)
3. Fast-forwards to main's latest commit
4. Replays your commits one by one on top

```bash
# View the clean linear history
git log --oneline --graph --all
```

## 📝 Exercise 2: Interactive Rebase - The Power Tool

Interactive rebase lets you edit, reorder, squash, or drop commits.

### Step 1: Create messy commits

```bash
git checkout -b feature/update-proc

cat > database/ProcessOrders.sql << 'EOF'
CREATE PROCEDURE ProcessOrders
AS
BEGIN
    SELECT * FROM Orders;
END
EOF

git add database/ProcessOrders.sql
git commit -m "Add ProcessOrders proc"

# Oops, typo fix
cat > database/ProcessOrders.sql << 'EOF'
CREATE PROCEDURE ProcessOrders
AS
BEGIN
    SELECT OrderId, CustomerId, OrderDate FROM Orders;
END
EOF

git add database/ProcessOrders.sql
git commit -m "Fix typo"

# Another small fix
cat > database/ProcessOrders.sql << 'EOF'
CREATE PROCEDURE ProcessOrders
AS
BEGIN
    SELECT OrderId, CustomerId, OrderDate, TotalAmount FROM Orders;
END
EOF

git add database/ProcessOrders.sql
git commit -m "Add TotalAmount column"

# Format change
cat > database/ProcessOrders.sql << 'EOF'
CREATE PROCEDURE dbo.ProcessOrders
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        OrderId, 
        CustomerId, 
        OrderDate, 
        TotalAmount 
    FROM Orders;
END
EOF

git add database/ProcessOrders.sql
git commit -m "Format code"
```

### Step 2: Clean up with interactive rebase

```bash
# Rebase the last 4 commits interactively
git rebase -i HEAD~4
```

**An editor opens with:**
```
pick a1b2c3d Add ProcessOrders proc
pick e4f5g6h Fix typo
pick i7j8k9l Add TotalAmount column
pick m1n2o3p Format code

# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's message
# d, drop = remove commit
```

**Change it to:**
```
pick a1b2c3d Add ProcessOrders proc
fixup e4f5g6h Fix typo
fixup i7j8k9l Add TotalAmount column
fixup m1n2o3p Format code
```

Save and close. Now you have ONE clean commit!

### Step 3: Reorder commits

```bash
# Create some commits
echo "-- Index 1" > database/Index1.sql
git add database/Index1.sql
git commit -m "Add Index1"

echo "-- Index 2" > database/Index2.sql
git add database/Index2.sql
git commit -m "Add Index2"

echo "-- Table" > database/NewTable.sql
git add database/NewTable.sql
git commit -m "Add NewTable"

# Reorder so table comes first
git rebase -i HEAD~3
```

**Change order:**
```
pick <hash> Add NewTable
pick <hash> Add Index1
pick <hash> Add Index2
```

## 📝 Exercise 3: Reword and Edit Commits

### Reword - Change commit message

```bash
git rebase -i HEAD~3
```

**Change 'pick' to 'reword':**
```
reword <hash> Add Index1
pick <hash> Add Index2
```

Git will prompt you to edit the message.

### Edit - Modify commit content

```bash
git rebase -i HEAD~2
```

**Change 'pick' to 'edit':**
```
edit <hash> Add Index1
pick <hash> Add Index2
```

Git stops at that commit:
```bash
# Make changes
echo "-- Modified" >> database/Index1.sql
git add database/Index1.sql

# Amend the commit
git commit --amend

# Continue rebase
git rebase --continue
```

## 📝 Exercise 4: Rebase with Autosquash

```bash
# Make a commit
cat > database/BackupProc.sql << 'EOF'
CREATE PROCEDURE BackupDatabase
AS BEGIN
    BACKUP DATABASE MyDB TO DISK = '/backup/mydb.bak';
END
EOF

git add database/BackupProc.sql
git commit -m "Add backup procedure"

# Oops, forgot error handling - create fixup commit
cat > database/BackupProc.sql << 'EOF'
CREATE PROCEDURE BackupDatabase
AS 
BEGIN
    BEGIN TRY
        BACKUP DATABASE MyDB TO DISK = '/backup/mydb.bak';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
EOF

git add database/BackupProc.sql
git commit --fixup HEAD  # or git commit --fixup <hash>

# View log
git log --oneline
# Shows: fixup! Add backup procedure

# Auto-squash during rebase
git rebase -i --autosquash HEAD~2
# Git automatically arranges fixup commits!
```

## 🎓 Advanced Rebase Techniques

### Technique 1: Rebase onto a Specific Commit

Sometimes you want to rebase onto a specific commit rather than the tip of a branch. This is useful when you want to base your work on a particular point in history.

**Use Case:** You're working on a feature, but you realize you should base your work on an earlier commit that has a stable schema, not the latest main branch which has experimental changes.

**Visual:**
```
Before:
    A---B---C---D---E  main (E has experimental changes)
         \
          F---G  feature

After rebasing onto C:
    A---B---C  (stable commit)
         \   \
          \   F'---G'  feature (rebased onto C)
           \
            D---E  main
```

**Example:**
```bash
# View commit history to find the commit hash
git log --oneline main
# Output:
# e5f6g7h (HEAD -> main) Add experimental feature
# d4e5f6g Update schema with nullable columns
# c3d4e5f Add stable indexes (STABLE - we want this)
# b2c3d4e Add Customers table
# a1b2c3d Initial commit

# Rebase your feature branch onto the stable commit (c3d4e5f)
git checkout feature/add-reports
git rebase c3d4e5f

# Now your feature commits are replayed on top of the stable commit
# Your feature branch is isolated from the experimental changes in D and E
```

**Real DBA Scenario:**
```bash
# You're developing a new report, but main branch has unstable schema changes
# Find the last stable commit
git log --oneline --all --graph

# Rebase onto that specific commit
git checkout feature/monthly-reports
git rebase abc1234  # The hash of the stable commit

# Later, when main is stable, rebase onto main
git rebase main
```

**Why use this?**
- Avoid unstable or experimental code in main
- Base work on a known-good commit
- Test your changes against a specific version
- Useful when main is temporarily broken

---

### Technique 2: Preserve Merge Commits (Rebase-Merges)

By default, `git rebase` flattens merge commits into linear history. But sometimes you want to preserve the merge structure to maintain the branching context.

**The Problem:**
```
Before:
    A---B---C  main
         \   \
          D---E---M  feature (M is a merge commit merging hotfix)
               \  /
                F  hotfix

After normal rebase (merge commits are lost):
    A---B---C  main
             \
              D'---E'---F'  feature (linear - merge history lost!)
```

**The Solution: `--rebase-merges` (or `-r`)**
```
After git rebase -r main:
    A---B---C  main
             \   \
              D'---E'---M'  feature (merge structure preserved!)
                   \  /
                    F'  hotfix
```

**Example:**
```bash
# Scenario: You have a feature branch with a merge commit
git checkout feature/schema-updates

# View current history
git log --oneline --graph
# * m5n6o7p (HEAD -> feature/schema-updates) Merge hotfix into feature
# |\
# | * k4l5m6n Apply critical index fix
# * | i2j3k4l Add new columns
# * | g0h1i2j Add new table
# |/
# * e5f6g7h Base commit

# Rebase onto main while preserving merge commits
git rebase --rebase-merges main
# or shorthand:
git rebase -r main

# The merge commit structure is preserved after rebase
```

**DBA Scenario:**
```bash
# You have a feature branch where you merged a hotfix mid-development
# The merge commit shows that a critical index fix was integrated

# Before rebase (with merge history):
* a1b2c3d Add reporting stored procedure
*   m5n6o7p Merge hotfix/index-fix into feature/reports
|\
| * h8i9j0k Fix missing index on Orders table (CRITICAL)
* | d4e5f6g Add initial report queries
|/
* c3d4e5f Base schema

# Preserve this merge history when rebasing onto main
git checkout feature/reports
git rebase --rebase-merges main

# After rebase - merge structure preserved, shows hotfix was integrated
```

**When to use `--rebase-merges`:**
- You have meaningful merge commits (e.g., integrating a hotfix)
- You want to preserve the context of when branches were integrated
- Team policy requires showing merge points
- You're rebasing complex branch structures

**Note:** The older `-p` or `--preserve-merges` flag is deprecated. Always use `-r` or `--rebase-merges`.

---

### Technique 3: Rebase with Exec (Auto-Testing)

The `--exec` option runs a command after each commit during rebase. This is powerful for validating that every commit in your history is buildable/testable.

**Use Case:** You want to ensure that EVERY commit in your feature branch passes tests or can be deployed successfully, not just the final commit.

**Why this matters:**
- Ensures each commit is individually valid
- Makes bisecting easier (every commit works)
- Catches issues introduced mid-development
- Professional practice for production code

**Basic Syntax:**
```bash
git rebase -i HEAD~5 --exec "command-to-run"
```

**Example 1: Run tests after each commit**
```bash
# Ensure every commit passes tests
git rebase -i HEAD~3 --exec "npm test"

# What happens:
# 1. Git applies commit 1
# 2. Runs "npm test"
# 3. If test passes, continues to commit 2
# 4. If test fails, rebase stops - you fix the issue
```

**Example 2: DBA Scenario - Validate SQL Scripts**
```bash
# You've made 4 commits modifying stored procedures
# Ensure each commit's SQL is valid syntax

git checkout feature/update-procedures
git rebase -i HEAD~4 --exec "sqlcmd -S localhost -d TestDB -i database/*.sql"

# What happens:
# After each commit is applied, SQL scripts are executed
# If any script has syntax errors, rebase stops
# You fix the issue at that specific commit
# Continue with: git rebase --continue
```

**Example 3: Check for specific patterns (security check)**
```bash
# Ensure no commit contains hardcoded credentials
git rebase -i HEAD~5 --exec "grep -r 'password' database/ && exit 1 || exit 0"

# Stops if 'password' string is found in any commit
```

**Example 4: Using exec in interactive rebase editor**

When you run `git rebase -i HEAD~3`, you can manually add `exec` lines:

```bash
git rebase -i HEAD~3
```

**Editor opens:**
```
pick a1b2c3d Add Customers table
exec sqlcmd -S localhost -i database/Customers.sql
pick b2c3d4e Add Orders table
exec sqlcmd -S localhost -i database/Orders.sql
pick c3d4e5f Add indexes
exec sqlcmd -S localhost -i database/*.sql

# Rebase will:
# 1. Apply "Add Customers table"
# 2. Run sqlcmd to validate Customers.sql
# 3. Apply "Add Orders table"
# 4. Run sqlcmd to validate Orders.sql
# 5. Apply "Add indexes"
# 6. Run sqlcmd to validate all SQL files
```

**Real-World DBA Scenario:**
```bash
# You've made multiple commits updating database schema
# You want to ensure each commit can be applied to a fresh database

# Create test script
cat > test-sql.sh << 'EOF'
#!/bin/bash
# Reset test database
sqlcmd -S localhost -Q "DROP DATABASE IF EXISTS TestRebaseDB; CREATE DATABASE TestRebaseDB;"

# Apply all SQL files in order
for file in database/*.sql; do
    echo "Testing $file..."
    sqlcmd -S localhost -d TestRebaseDB -i "$file"
    if [ $? -ne 0 ]; then
        echo "ERROR: $file failed!"
        exit 1
    fi
done
echo "All SQL files validated successfully!"
EOF

chmod +x test-sql.sh

# Rebase with validation after each commit
git rebase -i HEAD~5 --exec "./test-sql.sh"

# Now you know every single commit has valid, deployable SQL
```

**Practical Example - Building a clean history:**
```bash
# You have 3 commits:
# 1. Add table
# 2. Add procedure (has a bug)
# 3. Fix procedure

# Run tests on each commit
git rebase -i HEAD~3 --exec "npm test"

# Rebase stops at commit 2 (procedure has bug)
# You can:
# - Fix the bug in commit 2 itself: git commit --amend
# - Or skip and let commit 3 fix it: git rebase --continue

# Best practice: Fix it in commit 2 to maintain clean history
```

**Benefits of --exec:**
✅ Every commit is validated
✅ Easier debugging with `git bisect` (every commit works)
✅ Cleaner history (no broken commits)
✅ Catches issues early in the commit sequence
✅ Professional-grade commit hygiene

---

### Technique 4: Skip commits during rebase

```bash
# If a commit is causing issues during rebase and you want to exclude it
git rebase --skip

# Use case: A commit conflicts or is no longer needed
# Skip it and continue with remaining commits
```

## ⚠️ The Golden Rule of Rebase

**NEVER rebase commits that have been pushed to a shared/public branch!**

✅ **Good - Rebase your local feature branch:**
```bash
git checkout feature/my-work
git rebase main  # OK - feature branch is yours
```

❌ **Bad - Rebase shared branch:**
```bash
git checkout main
git rebase feature/my-work  # BAD - main is shared!
```

**Why?** Rebase rewrites history. If others have pulled the old history, their repos will conflict with your rewritten history.

**Exception:** If you're working on a feature branch alone and force-push to it, that's acceptable.

## 🎯 Real-World DBA Scenarios

### Scenario 1: Clean up before PR
```bash
# You made 15 commits while developing
# Clean them up to 3 logical commits before pull request
git rebase -i main
# Squash related commits together
```

### Scenario 2: Keep feature branch current
```bash
# Your feature branch is a week old
# Main has moved forward
git checkout feature/my-indexes
git rebase main  # Bring in latest changes
```

### Scenario 3: Remove sensitive commit
```bash
# Accidentally committed password
git rebase -i HEAD~5
# Change that commit to 'edit'
# Remove the password
git commit --amend
git rebase --continue
```

### Scenario 4: Split a large commit
```bash
git rebase -i HEAD~3
# Mark commit as 'edit'
git reset HEAD^  # Unstage changes
git add -p  # Stage parts selectively
git commit -m "First logical change"
git add .
git commit -m "Second logical change"
git rebase --continue
```

## ⚠️ Common Pitfalls

1. **Rebasing public branches**: Don't do it!

2. **Losing commits**: If something goes wrong:
   ```bash
   git reflog  # Find your lost commit
   git reset --hard <commit-hash>
   ```

3. **Complex conflicts during rebase**: Can happen with many commits
   ```bash
   git rebase --abort  # Start over if needed
   ```

4. **Forgetting autosquash**: Use `--fixup` and `--autosquash` for cleaner workflow

## ✅ Practice Exercise

Create this workflow:
1. Create a feature branch with 5 small commits
2. Use interactive rebase to:
   - Squash commits 2-4 into commit 1
   - Reword commit 5
3. Rebase onto main
4. Verify clean linear history with `git log --oneline --graph`

## 🎓 Key Takeaways

- **Rebase** = Replay commits on a new base
- **Interactive rebase** = Edit, reorder, squash, drop commits
- Use `git rebase -i HEAD~N` to edit last N commits
- `pick`, `squash`, `fixup`, `reword`, `edit`, `drop` are your tools
- **Golden Rule**: Never rebase public/shared branches
- `git rebase --abort` is your safety net
- Clean history makes code review easier

## 🔧 Quick Reference

```bash
# Basic rebase
git rebase main

# Interactive rebase
git rebase -i HEAD~5
git rebase -i main

# During rebase
git rebase --continue  # After resolving conflicts
git rebase --skip      # Skip current commit
git rebase --abort     # Cancel rebase

# Autosquash workflow
git commit --fixup <hash>
git rebase -i --autosquash main
```

## 📚 Next Lesson

Want more power over your history? Move to [Lesson 4: Interactive Rebase Advanced](./04-interactive-rebase.md)

