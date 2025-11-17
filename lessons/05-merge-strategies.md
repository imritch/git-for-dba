# Lesson 5: Merge Strategies - Fast-Forward, Squash, and More

## 🎯 What are Merge Strategies?

Git offers different ways to integrate changes from one branch to another. Each strategy has different impacts on your history.

**DBA Analogy:** Like different ways to deploy database changes - direct deployment, batched deployment, or rollup deployment.

## 🤔 The Three Main Merge Types

### 1. Fast-Forward Merge (Default when possible)
### 2. Regular Merge (Creates merge commit)
### 3. Squash Merge (Combines all commits into one)

## 📝 Exercise 1: Fast-Forward Merge

### What is Fast-Forward?

When your target branch hasn't diverged, Git simply "fast-forwards" the pointer.

```
Before:
    A---B---C  main
             \
              D---E  feature

After fast-forward merge:
    A---B---C---D---E  main, feature
```

No merge commit is created - linear history!

### Practice Fast-Forward

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Create initial commit
cat > database/Users.sql << 'EOF'
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL
);
EOF

git add database/Users.sql
git commit -m "Create Users table"

# Create feature branch
git checkout -b feature/add-email

# Add email column
cat > database/Users.sql << 'EOF'
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100)
);
EOF

git commit -am "Add Email column to Users"

# Add index
cat >> database/Users.sql << 'EOF'

CREATE UNIQUE NONCLUSTERED INDEX UX_Users_Email
ON Users(Email) WHERE Email IS NOT NULL;
EOF

git commit -am "Add unique index on Email"

# View the log
git log --oneline --graph --all
# You'll see feature branch ahead of main

# Switch to main
git checkout main

# Fast-forward merge (this is the default)
git merge feature/add-email

# View the log - linear history!
git log --oneline --graph
```

### Prevent Fast-Forward (Force Merge Commit)

```bash
# Create another feature
git checkout -b feature/add-phone

cat > database/Users.sql << 'EOF'
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20)
);
EOF

git commit -am "Add Phone column"

# Merge with no-ff (no fast-forward)
git checkout main
git merge --no-ff feature/add-phone -m "Merge feature: Add phone column"

# View the log - now you see a merge commit
git log --oneline --graph
```

**When to use `--no-ff`:**
- ✅ Want to preserve feature branch history
- ✅ Want clear markers where features were integrated
- ✅ Team policy requires merge commits

**When to allow fast-forward:**
- ✅ Want clean, linear history
- ✅ Small features or bug fixes
- ✅ Personal projects or simple workflows

## 📝 Exercise 2: Squash Merge - Clean History

### What is Squash Merge?

Squash merge combines ALL commits from a feature branch into a SINGLE commit on the target branch.

```
Before:
    A---B---C  main
             \
              D---E---F---G  feature (4 commits)

After squash merge:
    A---B---C---H  main (H contains all changes from D,E,F,G)
             \
              D---E---F---G  feature (still exists)
```

### Practice Squash Merge

```bash
# Create feature with multiple commits
git checkout -b feature/orders-system

# Commit 1: Table
cat > database/Orders.sql << 'EOF'
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE()
);
EOF

git add database/Orders.sql
git commit -m "Create Orders table"

# Commit 2: Add amount
cat > database/Orders.sql << 'EOF'
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL
);
EOF

git commit -am "Add TotalAmount column"

# Commit 3: Add index
cat >> database/Orders.sql << 'EOF'

CREATE NONCLUSTERED INDEX IX_Orders_UserId
ON Orders(UserId);
EOF

git commit -am "Add index on UserId"

# Commit 4: Add procedure
cat > database/OrderProcs.sql << 'EOF'
CREATE PROCEDURE GetUserOrders
    @UserId INT
AS
BEGIN
    SELECT * FROM Orders WHERE UserId = @UserId;
END
EOF

git add database/OrderProcs.sql
git commit -m "Add GetUserOrders procedure"

# View the feature branch history
git log --oneline
# Shows 4 separate commits

# Switch to main
git checkout main

# Squash merge!
git merge --squash feature/orders-system

# Check status - changes are staged but not committed
git status

# Create the squash commit
git commit -m "Add Orders system

- Created Orders table with UserId and TotalAmount
- Added index on UserId for performance
- Added GetUserOrders stored procedure for data retrieval"

# View main history - just ONE commit!
git log --oneline
```

### When to Use Squash Merge

**✅ Use squash merge when:**
- Feature branch has many small, incremental commits
- You want clean main branch history
- Individual feature commits aren't important for main history
- Common in pull request workflows (GitHub/GitLab often default to squash)

**❌ Don't use squash merge when:**
- You need to preserve detailed commit history
- Each commit on feature branch is significant
- You might need to cherry-pick individual commits later

## 📝 Exercise 3: Regular Merge (No Fast-Forward)

### Create a Divergent Branch

```bash
# Create base
git checkout main
cat > database/Products.sql << 'EOF'
CREATE TABLE Products (
    ProductId INT PRIMARY KEY,
    ProductName NVARCHAR(100)
);
EOF

git add database/Products.sql
git commit -m "Create Products table"

# Create feature branch
git checkout -b feature/product-enhancements

# Work on feature
cat >> database/Products.sql << 'EOF'

CREATE NONCLUSTERED INDEX IX_Products_Name
ON Products(ProductName);
EOF

git commit -am "Add index on ProductName"

# Meanwhile, main branch also progresses
git checkout main
cat > database/Categories.sql << 'EOF'
CREATE TABLE Categories (
    CategoryId INT PRIMARY KEY,
    CategoryName NVARCHAR(100)
);
EOF

git add database/Categories.sql
git commit -m "Create Categories table"

# Now branches have diverged!
git log --oneline --graph --all

# Merge feature into main (creates merge commit)
git merge feature/product-enhancements

# View the merge commit
git log --oneline --graph
```

## 📝 Exercise 4: Merge Strategy Options

Git has advanced merge strategies for special situations:

### Strategy: Ours (Keep our version)

```bash
# Create scenario
git checkout -b feature/experimental

cat > database/Experimental.sql << 'EOF'
-- Experimental changes that we'll discard
CREATE TABLE TempExperiment (Id INT);
EOF

git add database/Experimental.sql
git commit -m "Experimental changes"

# Go back to main
git checkout main

# Merge but keep ALL of our changes (discard theirs)
git merge -s ours feature/experimental -m "Merge experimental (keeping main version)"

# The merge commit exists, but no actual changes from feature!
git log --oneline --graph
```

### Strategy: Theirs (During conflicts)

```bash
# Note: There's no '-s theirs', but you can use '-X theirs'
git merge -X theirs feature-branch

# This prefers their changes in conflicts
```

### Strategy: Recursive with Options

```bash
# Ignore whitespace changes
git merge -X ignore-all-space feature-branch

# Be more aggressive in auto-resolving conflicts
git merge -X patience feature-branch

# Prefer our changes in conflicts
git merge -X ours feature-branch
```

## 📝 Exercise 5: Octopus Merge (Multiple Branches)

You can merge multiple branches at once!

```bash
# Create multiple feature branches
git checkout main

# Feature 1
git checkout -b feature/indexes
echo "CREATE INDEX IX1" > database/Index1.sql
git add database/Index1.sql
git commit -m "Add Index1"

# Feature 2
git checkout main
git checkout -b feature/procs
echo "CREATE PROCEDURE Proc1" > database/Proc1.sql
git add database/Proc1.sql
git commit -m "Add Proc1"

# Feature 3
git checkout main
git checkout -b feature/views
echo "CREATE VIEW View1" > database/View1.sql
git add database/View1.sql
git commit -m "Add View1"

# Merge all three at once!
git checkout main
git merge feature/indexes feature/procs feature/views -m "Merge all database objects"

# View the octopus merge
git log --oneline --graph --all
```

## 🎯 Real-World DBA Scenarios

### Scenario 1: Release Branches

```bash
# Sprint work with multiple features
git checkout -b release/v1.0

# Merge multiple feature branches with --no-ff
git merge --no-ff feature/schema-updates
git merge --no-ff feature/new-indexes
git merge --no-ff feature/stored-procs

# Clear history showing what went into release
git log --oneline --graph
```

### Scenario 2: Pull Request Workflow

```bash
# Feature branch with messy history
git checkout -b feature/customer-module
# ... 20 commits of "WIP", "fix", "oops" ...

# When PR is ready, squash merge to main
git checkout main
git merge --squash feature/customer-module
git commit -m "Add customer module

Complete customer management system including:
- Customer CRUD procedures
- Email validation triggers
- Performance indexes
- Customer activity views"
```

### Scenario 3: Hotfix to Multiple Branches

```bash
# Critical bug fix
git checkout main
git checkout -b hotfix/sql-injection

# Fix the bug
cat > database/FixedProc.sql << 'EOF'
CREATE PROCEDURE SafeProc
    @UserId INT  -- Now properly parameterized
AS
BEGIN
    SELECT * FROM Users WHERE UserId = @UserId;
END
EOF

git add database/FixedProc.sql
git commit -m "SECURITY: Fix SQL injection in SafeProc"

# Fast-forward merge to main
git checkout main
git merge hotfix/sql-injection

# Also merge to release branches
git checkout release/v1.0
git merge hotfix/sql-injection

git checkout release/v2.0
git merge hotfix/sql-injection
```

## 📊 Merge Strategy Comparison

| Strategy | History | Use Case | Command |
|----------|---------|----------|---------|
| **Fast-Forward** | Linear | Simple features, no divergence | `git merge` (default) |
| **No-FF** | Shows branches | Preserve feature history | `git merge --no-ff` |
| **Squash** | Single commit | Clean main, many WIP commits | `git merge --squash` |
| **Ours** | Keep our version | Merge but discard their changes | `git merge -s ours` |
| **Recursive** | Standard | Most common (default) | `git merge -s recursive` |

## ⚠️ Common Pitfalls

1. **Squashing important commits**: Don't squash if individual commits matter

2. **Forgetting to commit after squash**: `git merge --squash` stages changes but doesn't commit

3. **Fast-forward when you wanted merge commit**: Use `--no-ff` if needed

4. **Wrong strategy for conflicts**: `-X theirs` vs `-s ours` are very different!

## ✅ Practice Exercise

Create this complete workflow:
1. Create 3 feature branches with different changes
2. Use fast-forward merge for feature1
3. Use --no-ff merge for feature2
4. Use --squash merge for feature3 (with 5+ commits)
5. View final history with `git log --oneline --graph`
6. Understand why each strategy was chosen

## 🎓 Key Takeaways

- **Fast-forward**: Linear history, no merge commit (default when possible)
- **--no-ff**: Forces merge commit, preserves branch structure
- **--squash**: Combines all feature commits into one
- **-s ours**: Merge commit exists but keeps our version
- **-X ours/theirs**: Conflict resolution preference
- Choose strategy based on your project's history needs
- Main branch usually benefits from cleaner history (squash)
- Release branches often preserve structure (no-ff)

## 🔧 Quick Reference

```bash
# Fast-forward merge (default)
git merge feature-branch

# Force merge commit
git merge --no-ff feature-branch

# Squash all commits into one
git merge --squash feature-branch
git commit -m "Descriptive message"

# Merge but keep our version
git merge -s ours feature-branch

# Merge with conflict resolution preference
git merge -X ours feature-branch     # Prefer our changes
git merge -X theirs feature-branch   # Prefer their changes

# Merge multiple branches
git merge branch1 branch2 branch3

# Abort merge
git merge --abort
```

## 📚 Next Lesson

Want to selectively pick commits? Move to [Lesson 6: Cherry-Pick](./06-cherry-pick.md)

---

## 🎯 Merge vs Rebase: Making the Right Choice

**Working on a long-running PR and unsure whether to merge or rebase?** Check out the comprehensive [Merge vs Rebase Decision Guide](../exercises/MERGE-VS-REBASE-DECISION.md) which provides:
- Real-world scenario: 3-week PR with code reviews
- Detailed comparison of merge vs rebase
- When to use each strategy
- Step-by-step instructions for merging main into your feature branch
- Conflict resolution techniques
- Decision tree for choosing the right approach

