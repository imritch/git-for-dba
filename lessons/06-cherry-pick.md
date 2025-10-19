# Lesson 6: Cherry-Pick - Selective Commit Surgery

## 🎯 What is Cherry-Pick?

Cherry-pick applies the changes from specific commits to your current branch, creating new commits with the same changes.

**DBA Analogy:** Like extracting just one stored procedure change from a deployment script and applying it separately, without deploying everything else.

## 🤔 When Do You Need Cherry-Pick?

**Scenarios:**
- ✅ Apply a hotfix from main to release branch
- ✅ Grab a specific feature from a large feature branch
- ✅ Move commits from wrong branch to correct branch
- ✅ Apply bug fix to multiple release versions
- ✅ Recover specific commits after a reset

## 📝 Exercise 1: Basic Cherry-Pick

### Step 1: Create commits on different branches

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Main branch work
git checkout main
cat > database/MainTable.sql << 'EOF'
CREATE TABLE MainTable (
    Id INT PRIMARY KEY,
    Data NVARCHAR(100)
);
EOF

git add database/MainTable.sql
git commit -m "Create MainTable"

# Feature branch with multiple commits
git checkout -b feature/development

# Commit 1: Table
cat > database/FeatureTable.sql << 'EOF'
CREATE TABLE FeatureTable (
    FeatureId INT PRIMARY KEY,
    FeatureName NVARCHAR(100)
);
EOF

git add database/FeatureTable.sql
git commit -m "Add FeatureTable"

# Commit 2: Index
cat >> database/FeatureTable.sql << 'EOF'

CREATE NONCLUSTERED INDEX IX_Feature_Name
ON FeatureTable(FeatureName);
EOF

git commit -am "Add index on FeatureTable"

# Commit 3: Critical bug fix (this is what we want!)
cat > database/CriticalFix.sql << 'EOF'
-- Fix for SQL injection vulnerability
CREATE PROCEDURE SafeSearch
    @SearchTerm NVARCHAR(100)
AS
BEGIN
    SELECT * FROM MainTable 
    WHERE Data LIKE '%' + @SearchTerm + '%';  -- Properly parameterized
END
EOF

git add database/CriticalFix.sql
git commit -m "SECURITY: Fix SQL injection in search"

# Commit 4: More feature work
cat >> database/FeatureTable.sql << 'EOF'

-- Additional feature work
CREATE PROCEDURE GetFeatures AS SELECT * FROM FeatureTable;
EOF

git commit -am "Add GetFeatures procedure"

# View the commits
git log --oneline
```

### Step 2: Cherry-pick the security fix to main

```bash
# Get the commit hash of the security fix
git log --oneline --grep="SECURITY"
# Note the hash (let's say it's abc123d)

# Switch to main
git checkout main

# Cherry-pick just that commit
git cherry-pick abc123d

# Verify it's applied
git log --oneline
ls database/
cat database/CriticalFix.sql
```

**Result:** The security fix is now on main, but the other feature commits are not!

## 📝 Exercise 2: Cherry-Pick Multiple Commits

### Pick a range of commits

```bash
# Create scenario with multiple bug fixes
git checkout feature/development

cat > database/Fix1.sql << 'EOF'
-- Bug fix 1
CREATE INDEX IX_Performance1 ON MainTable(Data);
EOF

git add database/Fix1.sql
git commit -m "BUG: Add missing index for performance"

cat > database/Fix2.sql << 'EOF'
-- Bug fix 2
ALTER TABLE MainTable ADD UpdatedDate DATETIME DEFAULT GETDATE();
EOF

git add database/Fix2.sql
git commit -m "BUG: Add audit column"

cat > database/Fix3.sql << 'EOF'
-- Bug fix 3
CREATE TRIGGER TR_MainTable_Update
ON MainTable AFTER UPDATE
AS BEGIN
    UPDATE MainTable SET UpdatedDate = GETDATE()
    FROM MainTable m INNER JOIN inserted i ON m.Id = i.Id;
END
EOF

git add database/Fix3.sql
git commit -m "BUG: Add update trigger"

# View commits
git log --oneline -5

# Cherry-pick a range (assuming hashes are bcd234e to fgh789i)
git checkout main
git cherry-pick bcd234e^..fgh789i

# Or cherry-pick multiple specific commits
git cherry-pick bcd234e def456f fgh789i
```

## 📝 Exercise 3: Cherry-Pick with Conflicts

### When cherry-pick causes conflicts

```bash
# Create conflict scenario
git checkout main
cat > database/Shared.sql << 'EOF'
CREATE TABLE Shared (
    Id INT PRIMARY KEY,
    Version INT DEFAULT 1
);
EOF

git add database/Shared.sql
git commit -m "Create Shared table"

# Branch 1: Modify the table
git checkout -b branch1
cat > database/Shared.sql << 'EOF'
CREATE TABLE Shared (
    Id INT PRIMARY KEY,
    Version INT DEFAULT 1,
    StatusA NVARCHAR(50)
);
EOF

git commit -am "Add StatusA column"

# Main also modifies same table
git checkout main
cat > database/Shared.sql << 'EOF'
CREATE TABLE Shared (
    Id INT PRIMARY KEY,
    Version INT DEFAULT 1,
    StatusB NVARCHAR(50)
);
EOF

git commit -am "Add StatusB column"

# Try to cherry-pick from branch1
git cherry-pick branch1

# CONFLICT! Resolve it:
cat > database/Shared.sql << 'EOF'
CREATE TABLE Shared (
    Id INT PRIMARY KEY,
    Version INT DEFAULT 1,
    StatusA NVARCHAR(50),
    StatusB NVARCHAR(50)
);
EOF

# Mark resolved
git add database/Shared.sql

# Continue cherry-pick
git cherry-pick --continue

# Or abort if needed
# git cherry-pick --abort
```

## 📝 Exercise 4: Cherry-Pick to Multiple Branches

### Apply fix to multiple release versions

```bash
# Setup release branches
git checkout main
echo "V3" > version.txt
git add version.txt
git commit -m "Version 3.0"

# Create older release branches
git checkout -b release/v1.0 HEAD~10  # Or appropriate commit
echo "V1" > version.txt
git add version.txt
git commit -m "Version 1.0"

git checkout main
git checkout -b release/v2.0 HEAD~5
echo "V2" > version.txt
git add version.txt
git commit -m "Version 2.0"

# Create critical fix on main
git checkout main
cat > database/CriticalFix2.sql << 'EOF'
-- HOTFIX: Fix transaction deadlock
ALTER PROCEDURE ProcessOrders
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;
    
    -- Fixed logic here
    SELECT * FROM Orders WITH (READPAST);
END
EOF

git add database/CriticalFix2.sql
git commit -m "HOTFIX: Fix deadlock in ProcessOrders"

# Get the commit hash
HOTFIX_HASH=$(git rev-parse HEAD)

# Apply to v2.0
git checkout release/v2.0
git cherry-pick $HOTFIX_HASH

# Apply to v1.0
git checkout release/v1.0
git cherry-pick $HOTFIX_HASH

# Verify all branches have the fix
git checkout main && git log --oneline -1
git checkout release/v2.0 && git log --oneline -1
git checkout release/v1.0 && git log --oneline -1
```

## 📝 Exercise 5: Advanced Cherry-Pick Options

### Cherry-pick without committing

```bash
# Apply changes but don't commit (so you can modify)
git cherry-pick -n <commit-hash>
# or
git cherry-pick --no-commit <commit-hash>

# Make additional changes
cat >> database/CriticalFix.sql << 'EOF'
-- Additional fix
EOF

git add .
git commit -m "Cherry-picked fix with additional changes"
```

### Cherry-pick with sign-off

```bash
# Add your sign-off to the commit
git cherry-pick -s <commit-hash>
# or
git cherry-pick --signoff <commit-hash>

# The commit message will include:
# Signed-off-by: Your Name <your.email@example.com>
```

### Cherry-pick and edit commit message

```bash
# Cherry-pick but allow editing commit message
git cherry-pick -e <commit-hash>
# or
git cherry-pick --edit <commit-hash>
```

### Cherry-pick merge commit

```bash
# Cherry-pick a merge commit (you must specify parent)
git cherry-pick -m 1 <merge-commit-hash>

# -m 1 means use parent 1 (usually main branch)
# -m 2 means use parent 2 (usually feature branch)
```

## 🎓 Advanced: Cherry-Pick Workflows

### Workflow 1: Move commits to different branch

```bash
# Oops! Committed to wrong branch
git checkout wrong-branch
git log --oneline -3  # Note the commit hashes

# Create correct branch
git checkout main
git checkout -b correct-branch

# Cherry-pick the commits
git cherry-pick hash1 hash2 hash3

# Remove from wrong branch
git checkout wrong-branch
git reset --hard HEAD~3  # Remove last 3 commits
```

### Workflow 2: Selective feature porting

```bash
# Feature branch has 20 commits
# But you only want 3 specific ones

git checkout main
git cherry-pick feature-branch~19  # Pick 1st commit
git cherry-pick feature-branch~10  # Pick 10th commit
git cherry-pick feature-branch~2   # Pick 18th commit

# Or use interactive rebase on a temp branch
git checkout -b temp feature-branch
git rebase -i main
# Mark only wanted commits as 'pick', others as 'drop'
```

### Workflow 3: Backporting fixes

```bash
# Fix in main, backport to old releases
git checkout main
git commit -m "Fix critical bug"

FIX_HASH=$(git rev-parse HEAD)

# Backport to all supported releases
for release in release/v1.0 release/v2.0 release/v3.0; do
    git checkout $release
    git cherry-pick $FIX_HASH
done

git checkout main
```

## ⚠️ Common Pitfalls

1. **Cherry-picking creates new commits**: Original and cherry-picked are different hashes

2. **Lost context**: Cherry-picked commit might depend on other commits

3. **Duplicate commits**: Cherry-picking then merging creates duplicates (Git usually handles this)

4. **Conflict resolution**: May need to resolve conflicts multiple times (once per branch)

5. **Breaking dependencies**: Cherry-picking commit D when commit C is required

## 🎯 Real-World DBA Scenarios

### Scenario 1: Emergency Production Fix

```
Production issue found
Fix applied to main branch
Need to backport to 3 release branches
Cherry-pick to each release branch
```

### Scenario 2: Extracting Single Procedure

```
Large feature branch with 50 changes
Need just the new index optimization
Cherry-pick only that commit to main
Deploy quickly without full feature
```

### Scenario 3: Reorganizing Work

```
Committed 5 changes to feature-A
Realized 2 belong in feature-B
Cherry-pick those 2 to feature-B
Remove them from feature-A with rebase
```

### Scenario 4: Client-Specific Fixes

```
Multiple clients on different versions
Security fix needed for all
Cherry-pick fix to each client branch
```

## ✅ Practice Exercise

Create this scenario:
1. Main branch with base schema
2. Create 3 branches: feature-A, feature-B, release-1.0
3. On feature-A, make 5 commits
4. Cherry-pick commits 2 and 4 to feature-B
5. Cherry-pick commit 3 to release-1.0
6. Verify each branch has correct commits
7. Resolve any conflicts that arise

## 🎓 Key Takeaways

- **Cherry-pick** = Apply specific commits elsewhere
- Creates new commits (different hashes)
- Useful for selective porting of features/fixes
- Can cause conflicts - resolve like merges
- `git cherry-pick <hash>` for single commit
- `git cherry-pick hash1 hash2 hash3` for multiple
- `git cherry-pick hash1^..hash3` for range
- `--no-commit` to apply without committing
- Great for hotfixes across versions

## 🔧 Quick Reference

```bash
# Basic cherry-pick
git cherry-pick <commit-hash>

# Multiple commits
git cherry-pick <hash1> <hash2> <hash3>

# Range of commits
git cherry-pick <start-hash>^..<end-hash>

# Apply without committing
git cherry-pick -n <hash>

# Edit commit message
git cherry-pick -e <hash>

# Add sign-off
git cherry-pick -s <hash>

# During conflict
git cherry-pick --continue
git cherry-pick --abort
git cherry-pick --skip

# Cherry-pick merge commit
git cherry-pick -m 1 <merge-hash>

# View what will be cherry-picked
git show <commit-hash>
```

## 📚 Next Lesson

Need to undo changes safely? Move to [Lesson 7: Reset vs Revert](./07-reset-revert.md)

