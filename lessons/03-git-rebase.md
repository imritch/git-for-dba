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

### Technique 1: Rebase onto specific commit

```bash
# Rebase onto a specific commit instead of a branch
git rebase <commit-hash>
```

### Technique 2: Preserve merge commits

```bash
# If you have merge commits you want to keep
git rebase -p main  # or --preserve-merges (deprecated)
git rebase -r main  # --rebase-merges (newer approach)
```

### Technique 3: Rebase with exec

```bash
# Run a command after each commit
git rebase -i HEAD~5 --exec "npm test"

# Or in interactive mode, add:
pick <hash> Commit 1
exec npm test
pick <hash> Commit 2
exec npm test
```

For DBAs:
```bash
git rebase -i HEAD~3 --exec "sqlcmd -S localhost -i database/*.sql"
```

### Technique 4: Skip commits during rebase

```bash
# If a commit is causing issues
git rebase --skip
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

