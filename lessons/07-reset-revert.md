# Lesson 7: Reset vs Revert - Safely Undoing Changes

## 🎯 What's the Difference?

Both undo changes, but in fundamentally different ways:

**Reset:** Moves the branch pointer backwards (rewrites history)  
**Revert:** Creates a NEW commit that undoes changes (preserves history)

**DBA Analogy:**
- **Reset** = Rolling back to a database backup (destructive, history lost)
- **Revert** = Running a compensating transaction (keeps audit trail)

## 🤔 Which Should You Use?

| Situation | Use | Why |
|-----------|-----|-----|
| Local commits not pushed | Reset | Safe to rewrite local history |
| Commits already pushed | Revert | Don't rewrite public history |
| Want to keep history | Revert | Maintains audit trail |
| Want clean history | Reset | Removes mistakes completely |
| Public/shared branch | Revert | Others might have pulled it |
| Private feature branch | Reset | Your branch, your rules |

## 📝 Exercise 1: Git Reset - The Three Modes

Git reset has three modes: `--soft`, `--mixed`, `--hard`

### Setup

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Create a series of commits
cat > database/Version1.sql << 'EOF'
-- Version 1
CREATE TABLE TestTable (Id INT);
EOF

git add database/Version1.sql
git commit -m "Commit 1: Create table"

cat >> database/Version1.sql << 'EOF'
ALTER TABLE TestTable ADD Name NVARCHAR(100);
EOF

git commit -am "Commit 2: Add Name column"

cat >> database/Version1.sql << 'EOF'
ALTER TABLE TestTable ADD Email NVARCHAR(100);
EOF

git commit -am "Commit 3: Add Email column"

cat >> database/Version1.sql << 'EOF'
CREATE INDEX IX_TestTable_Name ON TestTable(Name);
EOF

git commit -am "Commit 4: Add index"

# View history
git log --oneline
```

### Mode 1: Reset --soft (Keep changes staged)

```bash
# Reset to 2 commits ago, keep changes staged
git reset --soft HEAD~2

# Check status
git status
# Shows: Changes to be committed (staged)

# Check files
cat database/Version1.sql
# Still contains all changes (Email + Index)

# View history
git log --oneline
# Only shows first 2 commits

# You can now recommit differently
git commit -m "Commit 2-4 combined: Add Email and Index"
```

**Use --soft when:** You want to squash commits but keep all changes staged

### Mode 2: Reset --mixed (Default - Keep changes unstaged)

```bash
# Create commits again
cat >> database/Version1.sql << 'EOF'
ALTER TABLE TestTable ADD Phone NVARCHAR(20);
EOF
git commit -am "Commit 5: Add Phone"

cat >> database/Version1.sql << 'EOF'
ALTER TABLE TestTable ADD Address NVARCHAR(200);
EOF
git commit -am "Commit 6: Add Address"

# Reset with --mixed (or no flag, it's default)
git reset HEAD~2
# or
git reset --mixed HEAD~2

# Check status
git status
# Shows: Changes not staged for commit (unstaged)

# Check files
cat database/Version1.sql
# Still contains all changes (Phone + Address)

# Stage selectively
git add -p database/Version1.sql
# Or stage all
git add database/Version1.sql
git commit -m "Add Phone and Address columns"
```

**Use --mixed when:** You want to redo commits AND restage changes selectively

### Mode 3: Reset --hard (Discard changes completely)

```bash
# Create a bad commit
cat >> database/Version1.sql << 'EOF'
-- THIS IS TERRIBLE CODE
DROP TABLE TestTable;  -- Oops!
EOF

git commit -am "BAD COMMIT: Accidentally dropping table!"

# View the damage
git log --oneline
cat database/Version1.sql

# UNDO IT COMPLETELY
git reset --hard HEAD~1

# Check status
git status
# Working directory clean

# Check files
cat database/Version1.sql
# DROP TABLE line is GONE

git log --oneline
# Bad commit is GONE
```

**Use --hard when:** You want to completely discard commits and changes

⚠️ **WARNING:** `--hard` is destructive! Changes are lost (unless in reflog).

## 📝 Exercise 2: Git Revert - Safe Undo

### Basic Revert

```bash
# Create commits
cat > database/Customer.sql << 'EOF'
CREATE TABLE Customer (
    CustomerId INT PRIMARY KEY,
    CustomerName NVARCHAR(100)
);
EOF

git add database/Customer.sql
git commit -m "Add Customer table"

cat >> database/Customer.sql << 'EOF'
CREATE INDEX IX_Customer_Name ON Customer(CustomerName);
EOF

git commit -am "Add index"

cat >> database/Customer.sql << 'EOF'
-- Oops, this index is wrong!
CREATE INDEX IX_Customer_Wrong ON Customer(CustomerName);
EOF

git commit -am "Add wrong index"

# Revert the last commit
git revert HEAD

# An editor opens for the commit message
# Default: "Revert 'Add wrong index'"
# Save and close

# Check history
git log --oneline
# Shows:
# abc123 Revert "Add wrong index"
# def456 Add wrong index
# ghi789 Add index
# jkl012 Add Customer table

# Check file
cat database/Customer.sql
# The wrong index is REMOVED
```

**Key Difference:** History shows both the mistake AND the fix!

### Revert Multiple Commits

```bash
# Create more commits
cat >> database/Customer.sql << 'EOF'
ALTER TABLE Customer ADD BadColumn1 INT;
EOF
git commit -am "Bad change 1"

cat >> database/Customer.sql << 'EOF'
ALTER TABLE Customer ADD BadColumn2 INT;
EOF
git commit -am "Bad change 2"

cat >> database/Customer.sql << 'EOF'
ALTER TABLE Customer ADD BadColumn3 INT;
EOF
git commit -am "Bad change 3"

# Revert all three (in reverse order)
git revert HEAD~2..HEAD

# Or revert specific commits
git revert abc123 def456 ghi789

# Or revert without committing (batch them)
git revert -n HEAD~2..HEAD
git commit -m "Revert bad changes 1-3"
```

### Revert with No Commit

```bash
# Revert but don't commit yet
git revert --no-commit HEAD

# Make additional changes
cat >> database/Customer.sql << 'EOF'
-- Additional fix
EOF

# Commit all together
git add .
git commit -m "Revert bad change and apply fix"
```

## 📝 Exercise 3: Comparing Reset vs Revert

### Scenario: Undo last 3 commits

```bash
# Setup
git checkout -b comparison-test

echo "Commit 1" > file1.sql
git add file1.sql && git commit -m "Commit 1"

echo "Commit 2" > file2.sql
git add file2.sql && git commit -m "Commit 2"

echo "Commit 3" > file3.sql
git add file3.sql && git commit -m "Commit 3"

git log --oneline
```

#### Using Reset

```bash
# Create branch for reset test
git checkout -b test-reset
git reset --hard HEAD~3

# Result:
git log --oneline  # Only shows commits before the 3
ls *.sql  # Files are GONE
# History is REWRITTEN
```

#### Using Revert

```bash
# Create branch for revert test
git checkout comparison-test
git checkout -b test-revert

git revert HEAD~2..HEAD

# Result:
git log --oneline  # Shows original commits + 3 revert commits
ls *.sql  # Files are GONE (same result)
# History is PRESERVED
```

**Same file state, different history!**

## 📝 Exercise 4: Recovering from Reset

### The Reflog - Your Safety Net

```bash
# Create commits
cat > database/Important.sql << 'EOF'
CREATE TABLE Important (Data NVARCHAR(MAX));
EOF
git add database/Important.sql
git commit -m "Important work"

cat >> database/Important.sql << 'EOF'
INSERT INTO Important VALUES ('Critical data');
EOF
git commit -am "Critical data"

# Oops! Hard reset
git reset --hard HEAD~2

# Oh no! Where's my work?
git log --oneline  # Doesn't show it

# Check the reflog!
git reflog

# Output:
# abc123 HEAD@{0}: reset: moving to HEAD~2
# def456 HEAD@{1}: commit: Critical data
# ghi789 HEAD@{2}: commit: Important work

# Recover the lost commit
git reset --hard def456
# or
git reset --hard HEAD@{1}

# Your work is back!
cat database/Important.sql
```

**The reflog keeps a history of HEAD movements for ~90 days!**

## 📝 Exercise 5: Real-World Scenarios

### Scenario 1: Undo last commit (not pushed)

```bash
# Made a commit but forgot to add a file
git commit -m "Add feature"
# Oops! Forgot database/NewProc.sql

# Solution 1: Reset soft and recommit
git reset --soft HEAD~1
git add database/NewProc.sql
git commit -m "Add feature"

# Solution 2: Amend the commit
git add database/NewProc.sql
git commit --amend --no-edit
```

### Scenario 2: Undo pushed commit (public)

```bash
# Bad commit already pushed to main
git commit -m "Buggy feature"
git push origin main

# DON'T use reset (others might have pulled)
# Use revert instead
git revert HEAD
git push origin main

# Safe: History preserved, others can pull safely
```

### Scenario 3: Undo commit in the middle

```bash
# Commit history:
# A - B - C - D - E  (need to undo C)

# Option 1: Revert specific commit
git revert <hash-of-C>

# Option 2: Interactive rebase (if not pushed)
git rebase -i A
# Mark C as 'drop'
```

### Scenario 4: Undo merge commit

```bash
# Merged feature branch but it broke things
git merge feature-branch
git push

# Revert the merge
git revert -m 1 HEAD
# -m 1 means keep changes from parent 1 (main)

git push
```

### Scenario 5: Reset on feature branch (safe)

```bash
# Your personal feature branch (not shared)
git checkout feature/my-work

# Made 10 messy commits
git log --oneline

# Clean it up with reset (safe because it's your branch)
git reset --soft HEAD~10
git commit -m "Clean commit with all changes"

# Force push (safe on personal branch)
git push --force-with-lease origin feature/my-work
```

## 🎓 Advanced: Combining Techniques

### Technique 1: Reset part of a file

```bash
# Staged changes you don't want
git add database/Proc.sql

# Unstage specific file
git reset HEAD database/Proc.sql

# Or unstage specific lines
git reset -p database/Proc.sql
```

### Technique 2: Revert without parent

```bash
# Revert merge commit
git revert -m 1 <merge-commit-hash>

# Later, to revert the revert
git revert <revert-commit-hash>
```

### Technique 3: Soft reset for commit splitting

```bash
# One commit with multiple changes
git commit -m "Multiple things"

# Split it
git reset --soft HEAD~1
git add database/Table.sql
git commit -m "Add table"
git add database/Proc.sql
git commit -m "Add procedure"
```

## ⚠️ Common Pitfalls

1. **Using reset on public branches**: Never reset commits that are pushed and shared!

2. **Forgetting reflog**: If you lose commits, check `git reflog` first

3. **reset --hard without checking**: Always verify what you're about to delete

4. **Revert conflicts**: Reverting can cause conflicts, especially if subsequent commits modified the same code

5. **Force push without lease**: Use `--force-with-lease` instead of `--force`

## 🎯 Decision Tree

```
Do you need to undo commits?
│
├─ Are the commits pushed/public?
│  │
│  ├─ YES → Use REVERT
│  │         git revert <commit>
│  │
│  └─ NO → Continue below
│
├─ Do you want to keep changes?
│  │
│  ├─ YES (staged) → Use RESET --soft
│  │                 git reset --soft HEAD~N
│  │
│  ├─ YES (unstaged) → Use RESET --mixed
│  │                   git reset HEAD~N
│  │
│  └─ NO → Use RESET --hard
│           git reset --hard HEAD~N
│
└─ Is it a public branch?
   │
   ├─ YES → Use REVERT (mentioned above)
   │
   └─ NO → RESET is safe
```

## ✅ Practice Exercise

Create this workflow:
1. Make 5 commits on a feature branch
2. Use `reset --soft HEAD~3` to squash last 3
3. Make 3 more commits
4. Use `reset --hard HEAD~1` to remove last commit
5. Recover the lost commit using reflog
6. Use `revert` to undo a middle commit
7. View history at each step

## 🎓 Key Takeaways

- **Reset** rewrites history (local use)
- **Revert** creates new commits (safe for public branches)
- `--soft` = keep changes staged
- `--mixed` = keep changes unstaged
- `--hard` = discard changes completely
- **Reflog** is your safety net (90 days)
- Never reset public/shared branches
- Use `revert` for commits already pushed
- `git commit --amend` for fixing last commit

## 🔧 Quick Reference

```bash
# RESET (rewrite history)
git reset --soft HEAD~N   # Undo commits, keep staged
git reset HEAD~N          # Undo commits, keep unstaged (default)
git reset --hard HEAD~N   # Undo commits, discard changes

# REVERT (new commits)
git revert HEAD           # Revert last commit
git revert HEAD~3..HEAD   # Revert last 3 commits
git revert -n <commit>    # Revert without committing
git revert -m 1 <merge>   # Revert merge commit

# AMEND (fix last commit)
git commit --amend        # Modify last commit
git commit --amend --no-edit  # Add to last commit, keep message

# RECOVERY
git reflog                # View HEAD history
git reset --hard HEAD@{N} # Recover to specific state

# UNSTAGE
git reset HEAD <file>     # Unstage file
git reset -p              # Unstage selectively
```

## 📚 What's Next?

You've completed all the core advanced Git concepts! Here are some next steps:

1. **Practice**: Go through the exercises multiple times
2. **Real project**: Apply these techniques to a real database project
3. **Git aliases**: Create shortcuts for common commands
4. **Git hooks**: Automate validations before commits
5. **Advanced topics**: Submodules, subtrees, worktrees

Keep practicing, and Git will become second nature!

