# Git Worktrees - Multiple Branches Simultaneously

## 🎯 What are Git Worktrees?

Git worktrees allow you to check out multiple branches simultaneously in different directories, all sharing the same Git repository. Think of it as having multiple working copies without cloning the repo multiple times.

**DBA Analogy:** Like having multiple query windows open in SSMS, each connected to a different database version, but all part of the same SQL Server instance.

## 🤔 Why DBAs Need Worktrees

**Without worktrees (traditional approach):**
```bash
# Working on feature
git checkout feature/new-indexes

# Emergency hotfix needed!
git stash  # Save current work
git checkout main
git checkout -b hotfix/urgent-fix
# Fix bug...
git checkout feature/new-indexes
git stash pop  # Restore work

# Frustrating context switching!
```

**With worktrees:**
```bash
# Main working directory: feature/new-indexes
cd /path/to/repo

# Create worktree for hotfix
git worktree add ../repo-hotfix hotfix/urgent-fix

# Now work in BOTH simultaneously!
# Terminal 1: Continue feature work
cd /path/to/repo
# work on feature...

# Terminal 2: Fix urgent bug
cd /path/to/repo-hotfix
# fix bug...

# No stashing, no context switching!
```

## 📝 Exercise 1: Basic Worktree Operations

### Setup

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# View current worktrees
git worktree list

# Output:
# /Users/riteshchawla/RC/git/git-for-dba  abc1234 [main]
# This shows your main working directory
```

### Create Your First Worktree

```bash
# Create a worktree for a hotfix
git worktree add ../git-for-dba-hotfix hotfix/production-fix

# This creates:
# 1. New directory: ../git-for-dba-hotfix
# 2. New branch: hotfix/production-fix (checked out in that directory)
# 3. Shares the same .git repository

# Verify
git worktree list

# Output:
# /Users/riteshchawla/RC/git/git-for-dba          abc1234 [main]
# /Users/riteshchawla/RC/git-for-dba-hotfix      def5678 [hotfix/production-fix]

# Work in the worktree
cd ../git-for-dba-hotfix
git status
# On branch hotfix/production-fix

# Create a fix
cat > database/ProductionFix.sql << 'EOF'
-- Emergency: Fix missing index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId_EMERGENCY
ON Orders(CustomerId)
INCLUDE (OrderDate, TotalAmount);
EOF

git add database/ProductionFix.sql
git commit -m "HOTFIX: Add emergency index"

# Switch back to main directory
cd /Users/riteshchawla/RC/git/git-for-dba
git status
# Still on main (or whatever branch you were on)!

# View the hotfix commit (it's in your shared repository)
git log hotfix/production-fix --oneline -1
```

### Remove Worktree When Done

```bash
# After merging the hotfix
cd /Users/riteshchawla/RC/git/git-for-dba
git merge hotfix/production-fix

# Remove the worktree
git worktree remove ../git-for-dba-hotfix

# Or if you deleted the directory manually:
git worktree prune

# Clean up the branch
git branch -d hotfix/production-fix
```

## 📝 Exercise 2: Review Code While Developing

### Scenario: Code Review While You Keep Working

You're deep in development when a teammate asks you to review their PR. With worktrees, you don't lose your flow.

```bash
# You're working on main worktree
cd /Users/riteshchawla/RC/git/git-for-dba
git checkout -b feature/my-big-feature

# Start working
cat > database/MyBigFeature.sql << 'EOF'
-- Complex feature in progress
CREATE PROCEDURE dbo.ComplexCalculation
AS
BEGIN
    -- TODO: Complex logic here
    -- You're halfway through this...
END
EOF

git add database/MyBigFeature.sql
git commit -m "WIP: Start complex feature"

# More uncommitted work
echo "-- More changes..." >> database/MyBigFeature.sql
echo "-- Not ready to commit yet..." >> database/AnotherFile.sql

# 📨 Notification: "Please review PR #456 (branch: feature/teammate-work)"

# Traditional way: Stash, checkout, review, checkout back, unstash
# Worktree way: Create parallel workspace!

# Create worktree for review
git fetch origin
git worktree add ../git-for-dba-review origin/feature/teammate-work

# Open new terminal window/tab
cd ../git-for-dba-review

# Review the code
ls database/
cat database/TeammateWork.sql

# Test it
# sqlcmd -S localhost -d TestDB -i database/TeammateWork.sql

# Add review comments (in GitHub/GitLab/etc)

# When done reviewing, just switch back
cd /Users/riteshchawla/RC/git/git-for-dba

# You're RIGHT where you left off!
# Uncommitted changes still there, no stashing needed

# Clean up review worktree
git worktree remove ../git-for-dba-review
```

## 📝 Exercise 3: Testing Multiple Versions

### Scenario: Compare Performance Across Versions

You need to compare query performance between two branches.

```bash
# Main worktree: current development
cd /Users/riteshchawla/RC/git/git-for-dba
git checkout feature/new-indexes

cat > database/OptimizedQuery.sql << 'EOF'
-- New optimized version
CREATE PROCEDURE dbo.GetCustomerOrders
    @CustomerId INT
AS
BEGIN
    SELECT o.OrderId, o.OrderDate, o.TotalAmount
    FROM Orders o WITH (INDEX(IX_Orders_New))
    WHERE o.CustomerId = @CustomerId;
END
EOF

git add database/OptimizedQuery.sql
git commit -m "Add optimized query with new index"

# Create worktree with OLD version for comparison
git worktree add ../git-for-dba-old main

# Terminal 1: Test NEW version
cd /Users/riteshchawla/RC/git/git-for-dba
sqlcmd -S localhost -d TestDB -i database/OptimizedQuery.sql
# Run performance test
# SET STATISTICS IO ON
# EXEC GetCustomerOrders @CustomerId = 1

# Terminal 2: Test OLD version
cd ../git-for-dba-old
sqlcmd -S localhost -d TestDB -i database/OptimizedQuery.sql
# Run performance test
# SET STATISTICS IO ON
# EXEC GetCustomerOrders @CustomerId = 1

# Compare results side-by-side!

# Clean up
cd /Users/riteshchawla/RC/git/git-for-dba
git worktree remove ../git-for-dba-old
```

## 📝 Exercise 4: Multiple Feature Development

### Scenario: Work on Multiple Features Simultaneously

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Main worktree: Primary feature
git checkout -b feature/reporting

# Create worktrees for additional features
git worktree add ../git-for-dba-auth feature/authentication
git worktree add ../git-for-dba-api feature/api-endpoints

# List all worktrees
git worktree list

# /Users/riteshchawla/RC/git/git-for-dba           [feature/reporting]
# /Users/riteshchawla/RC/git-for-dba-auth          [feature/authentication]
# /Users/riteshchawla/RC/git-for-dba-api           [feature/api-endpoints]

# Open 3 terminals/IDE windows:

# Terminal 1: Work on reporting
cd /Users/riteshchawla/RC/git/git-for-dba
# Work on reports...

# Terminal 2: Work on authentication
cd ../git-for-dba-auth
# Work on auth...

# Terminal 3: Work on API
cd ../git-for-dba-api
# Work on API...

# Each workspace is independent but shares the same repo!

# When feature is complete, merge and remove worktree
git checkout main
git merge feature/authentication
git worktree remove ../git-for-dba-auth
git branch -d feature/authentication
```

## 🎯 Real-World DBA Scenarios

### Scenario 1: Hotfix While Developing

```bash
# You're developing
cd /Users/riteshchawla/RC/git/git-for-dba
git checkout -b feature/new-reports

# 🚨 EMERGENCY: Production down!
# Create hotfix worktree instantly
git worktree add ../hotfix hotfix/db-deadlock

cd ../hotfix
# Fix deadlock issue
cat > database/FixDeadlock.sql << 'EOF'
-- Fix: Change transaction isolation level
ALTER PROCEDURE dbo.ProcessOrder
    ...
EOF

git add database/FixDeadlock.sql
git commit -m "HOTFIX: Fix deadlock in ProcessOrder"

# Deploy immediately
git checkout main
git merge hotfix/db-deadlock
git push origin main

# Go back to your feature work
cd /Users/riteshchawla/RC/git/git-for-dba
# Continue exactly where you left off!
```

### Scenario 2: Long-Running Migration Testing

```bash
# Main worktree: Continue daily work
cd /Users/riteshchawla/RC/git/git-for-dba

# Create worktree for long-running migration test
git worktree add ../migration-test feature/schema-migration

# Start long-running test in worktree
cd ../migration-test
sqlcmd -S localhost -d TestDB -i database/migrations/large-migration.sql &
# This runs in background for 2 hours...

# Meanwhile, continue working in main worktree
cd /Users/riteshchawla/RC/git/git-for-dba
# Do other work...

# Check migration progress
cd ../migration-test
# Check if complete, review results

# No interruption to your main work!
```

### Scenario 3: Version-Specific Bug Investigation

```bash
# Customer reports bug in version 2.3
# You're on version 2.5 codebase

# Create worktree at v2.3
git worktree add ../version-2.3 v2.3.0

cd ../version-2.3
# Reproduce the bug in v2.3 environment
# Identify the issue

# Check if issue still exists in current version
cd /Users/riteshchawla/RC/git/git-for-dba
# Test current version

# Compare the procedures
diff ../version-2.3/database/BuggyProc.sql database/BuggyProc.sql

# Clean up
git worktree remove ../version-2.3
```

## 🔧 Advanced Worktree Commands

### Create Worktree from Existing Branch

```bash
# Create worktree checking out existing branch
git worktree add ../my-worktree existing-branch

# Create worktree from remote branch
git worktree add ../review-worktree origin/feature/teammate-pr
```

### Create Worktree with New Branch

```bash
# Create worktree AND new branch in one command
git worktree add -b feature/new-feature ../new-feature-worktree main

# This:
# 1. Creates new branch 'feature/new-feature' from 'main'
# 2. Creates worktree directory '../new-feature-worktree'
# 3. Checks out the new branch in that worktree
```

### Move/Rename Worktree

```bash
# Move a worktree to different location
git worktree move ../old-location ../new-location
```

### Lock Worktree

```bash
# Lock worktree (prevent accidental deletion during cleanup)
git worktree lock ../important-worktree --reason "Long-running test"

# Unlock
git worktree unlock ../important-worktree
```

### Repair Worktrees

```bash
# If you manually moved a worktree directory
git worktree repair

# Repair specific worktree
git worktree repair ../moved-worktree
```

## 💡 Best Practices

### 1. Naming Convention

```bash
# Use descriptive directory names
git worktree add ../git-for-dba-hotfix-auth hotfix/auth-issue
git worktree add ../git-for-dba-review-pr123 feature/pr-123

# Pattern: {repo-name}-{purpose}
```

### 2. Clean Up Regularly

```bash
# List all worktrees
git worktree list

# Remove unused worktrees
git worktree remove ../old-worktree

# Prune stale worktrees (if directory was manually deleted)
git worktree prune
```

### 3. One Branch Per Worktree

```bash
# You can't have the same branch checked out in multiple worktrees
git worktree add ../worktree1 feature/my-branch  # ✅ OK
git worktree add ../worktree2 feature/my-branch  # ❌ ERROR

# Solution: Create a new branch
git worktree add -b feature/my-branch-test ../worktree2 feature/my-branch
```

### 4. Shared .git Directory

```bash
# All worktrees share the same .git
# This means:
# - Commits in any worktree appear in all worktrees
# - Branches created in one worktree exist in all
# - Fetching in one worktree updates all

# Advantage: Only one .git directory (saves disk space)
# Only one set of objects, refs, etc.
```

### 5. Use for Short-Term Tasks

```bash
# Good use cases:
✅ Code reviews
✅ Hotfixes
✅ Testing different versions
✅ Parallel feature development
✅ Bisecting while keeping main work

# Less ideal:
❌ Permanent workspaces (just use separate clones)
❌ Very large numbers of worktrees (>5-10)
```

## 🎓 Worktrees vs Other Approaches

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Worktrees** | No stashing, instant switch, shared .git | Slight complexity, manage multiple dirs | DBA daily work, code reviews |
| **Stash** | Simple, built-in | Context switching, can't work in parallel | Quick switches, simple tasks |
| **Multiple Clones** | Complete isolation | Duplicate .git, more disk space | Long-term parallel work |
| **Branches** | Standard Git workflow | Must switch, stash/commit required | Normal development |

## 📊 Worktree Commands Cheat Sheet

```bash
# Create worktree
git worktree add <path> <branch>
git worktree add -b <new-branch> <path> <start-point>

# List worktrees
git worktree list
git worktree list --porcelain  # Machine-readable

# Remove worktree
git worktree remove <path>
git worktree remove --force <path>  # Force even if dirty

# Prune stale worktrees
git worktree prune
git worktree prune --dry-run  # See what would be pruned

# Move worktree
git worktree move <old-path> <new-path>

# Lock/unlock worktree
git worktree lock <path> --reason "reason"
git worktree unlock <path>

# Repair worktrees
git worktree repair
git worktree repair <path>
```

## 🎊 Summary

Git worktrees are **powerful for DBAs** who:
- ✅ Need to quickly switch contexts (emergencies, code reviews)
- ✅ Want to test multiple versions simultaneously
- ✅ Work on multiple features in parallel
- ✅ Need to compare before/after changes
- ✅ Don't want to constantly stash/unstash

**Key Benefits:**
- No context switching delays
- No stashing required
- Work on multiple branches simultaneously
- Shared .git (efficient disk usage)
- Perfect for code reviews

**When to Use:**
- Emergency hotfixes during feature work
- Code review while developing
- Performance testing across versions
- Parallel feature development
- Long-running operations (migrations, tests)

**Golden Rule:**
> "Use worktrees for short-term parallel work, use separate clones for long-term workspaces"

**Next Steps:**
- Try creating your first worktree
- Use worktrees for your next code review
- Set up worktree for your next hotfix
- Practice the exercises above

You now have a powerful tool for managing multiple branches efficiently!
