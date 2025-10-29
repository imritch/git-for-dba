# Lesson 10: Advanced Recovery - When Things Go Wrong

## 🎯 What is Advanced Recovery?

Advanced recovery techniques help you rescue commits, branches, and data that seem "lost" in Git. The reflog is your safety net - Git rarely truly deletes anything for at least 30 days.

**DBA Analogy:** Like SQL Server transaction log and backups - even after a mistake, you can often restore to a point in time before the problem occurred.

## 🤔 When Do You Need Advanced Recovery?

**Scenarios DBAs Face:**
- Accidentally deleted a branch with important schema changes
- Force-pushed and lost commits
- Reset --hard and lost uncommitted work
- Merged the wrong branch and force-reset
- Committed sensitive data (passwords, connection strings)
- Rebased incorrectly and lost commits

**Without recovery skills:**
- ❌ Panic and recreate work from scratch
- ❌ Lost hours or days of work
- ❌ Security incidents from committed secrets

**With recovery skills:**
- ✅ Find and restore lost commits in minutes
- ✅ Remove sensitive data from history
- ✅ Undo complex mistakes confidently
- ✅ Rescue abandoned branches

## 📚 Understanding the Reflog

### What is Reflog?

The **reference log** (reflog) tracks every change to HEAD and branch tips - even changes that don't appear in regular history.

```
Regular log:      A -- B -- C -- D (main)
                         Shows only current history

Reflog:          HEAD@{0}: commit: D
                 HEAD@{1}: commit: C
                 HEAD@{2}: reset: moving to B
                 HEAD@{3}: commit: X (now "lost")
                 HEAD@{4}: commit: Y (now "lost")
                         Shows ALL moves, even to "lost" commits
```

## 📝 Exercise 1: Recovering from Accidental Reset --hard

### Scenario: Friday 5pm Disaster

You've spent all day working on stored procedures. You meant to do `git reset --soft HEAD~1` but typed `git reset --hard HEAD~5` by mistake. 5 commits vanished!

### Step 1: Create the Disaster

```bash
cd /Users/riteshchawla/RC/git/git-for-dba
git checkout -b exercise/recovery-practice

# Create 5 commits (your day's work)
for i in {1..5}; do
    cat > "database/StoredProc$i.sql" << EOF
-- Stored Procedure $i
CREATE PROCEDURE dbo.Proc$i
AS
BEGIN
    SET NOCOUNT ON;
    SELECT $i AS ProcNumber;
END
EOF
    git add "database/StoredProc$i.sql"
    git commit -m "Add StoredProc$i - important work!"
done

# View your commits
git log --oneline
echo ""
echo "You have 5 commits of important work!"
echo ""

# DISASTER: Accidentally reset hard
echo "⚠️  Simulating accidental reset --hard..."
sleep 2
git reset --hard HEAD~5

# Check what happened
git log --oneline
echo ""
echo "😱 All 5 commits are GONE!"
```

### Step 2: DON'T PANIC - Use Reflog

```bash
echo ""
echo "🔍 Checking reflog to find lost commits..."
echo ""

# View reflog
git reflog

# You'll see something like:
# abc1234 (HEAD -> exercise/recovery-practice) HEAD@{0}: reset: moving to HEAD~5
# def5678 HEAD@{1}: commit: Add StoredProc5 - important work!
# ghi9012 HEAD@{2}: commit: Add StoredProc4 - important work!
# ...
```

### Step 3: Recover the Lost Commits

```bash
# Method 1: Reset to before the disaster
# Find the commit BEFORE the reset (HEAD@{1} in reflog)
LAST_GOOD_COMMIT=$(git reflog | grep "commit: Add StoredProc5" | cut -d' ' -f1)

echo "Found last good commit: $LAST_GOOD_COMMIT"
echo "Recovering..."

git reset --hard $LAST_GOOD_COMMIT

# Check your work is back!
git log --oneline
ls database/StoredProc*.sql

echo ""
echo "🎉 Recovery successful! All commits restored!"
```

### Alternative Recovery Methods

```bash
# Method 2: Cherry-pick specific commits
git cherry-pick HEAD@{1}  # Recover just one commit

# Method 3: Create new branch from lost commit
git branch recovered-work HEAD@{1}
git checkout recovered-work

# Method 4: Merge the lost commits
git merge HEAD@{1}
```

## 📝 Exercise 2: Recovering Deleted Branches

### Scenario: Accidentally Deleted Feature Branch

You finished a feature branch, merged it, then deleted it. Later you realize the merge had issues and you need the original branch back.

### Step 1: Create and Delete a Branch

```bash
# Create feature branch with work
git checkout main
git checkout -b feature/customer-improvements

cat > database/ImprovedCustomerProc.sql << 'EOF'
-- Improved Customer Procedure
-- Contains important optimizations
CREATE PROCEDURE dbo.GetCustomersOptimized
AS
BEGIN
    SET NOCOUNT ON;

    -- Important: Uses special indexing hint
    SELECT
        CustomerId,
        CustomerName,
        Email
    FROM dbo.Customers WITH (INDEX(IX_Customers_Email))
    WHERE IsActive = 1
    ORDER BY CustomerName;
END
-- Note: This contains specific optimization you need to reference!
EOF

git add database/ImprovedCustomerProc.sql
git commit -m "Add optimized customer procedure with indexing hint"

# Create another commit
echo "-- Added comment" >> database/ImprovedCustomerProc.sql
git add database/ImprovedCustomerProc.sql
git commit -m "Document indexing strategy"

# Merge to main (squash merge, losing detailed history)
git checkout main
git merge --squash feature/customer-improvements
git commit -m "Add customer improvements"

# Delete the feature branch
git branch -D feature/customer-improvements

echo "✅ Branch merged and deleted"
echo ""

# Later... you realize you need that detailed history!
echo "😱 Wait, I need to see the original commits!"
echo "   The squash merge lost the indexing hint details!"
```

### Step 2: Recover the Deleted Branch

```bash
# Check reflog for the deleted branch
git reflog | grep "customer-improvements"

# You'll see something like:
# abc1234 HEAD@{5}: commit: Document indexing strategy
# def5678 HEAD@{6}: commit: Add optimized customer procedure

# Method 1: Recreate branch from reflog
LAST_COMMIT=$(git reflog | grep "customer-improvements" | head -1 | cut -d' ' -f1)

git branch feature/customer-improvements-recovered $LAST_COMMIT

# Checkout and verify
git checkout feature/customer-improvements-recovered
git log --oneline

echo "🎉 Branch recovered with full history!"
```

## 📝 Exercise 3: Recovering Uncommitted Work (Advanced)

### The "I Didn't Commit" Disaster

```bash
# Scenario: You worked for hours, ran git reset --hard, lost everything
# Can you recover UNCOMMITTED changes?

git checkout main
git checkout -b exercise/uncommitted-disaster

# Do some work but DON'T commit
cat > database/UnsavedWork.sql << 'EOF'
-- Hours of work here
CREATE PROCEDURE dbo.CriticalProc
AS
BEGIN
    -- Complex logic you spent hours on
    SET NOCOUNT ON;

    -- Important business logic
    SELECT * FROM dbo.Orders
    WHERE Status = 'Pending'
    AND OrderDate > DATEADD(DAY, -7, GETDATE());
END
EOF

# Stage it
git add database/UnsavedWork.sql

# DISASTER: Reset hard without committing
git reset --hard HEAD

# File is gone!
ls database/UnsavedWork.sql  # File not found
```

### Can You Recover It?

```bash
# If you STAGED the file (git add), there's hope!
# Git creates objects for staged files

# Find the blob
git fsck --lost-found

# This shows "dangling" objects
# Look for blobs created recently

# View recent blobs
for blob in $(git fsck --lost-found | grep blob | cut -d' ' -f3); do
    echo "=== Blob: $blob ==="
    git show $blob | head -5
    echo ""
done

# When you find your content, save it
git show <blob-hash> > database/UnsavedWork-recovered.sql
```

**Important:** This only works if you ran `git add` before losing the work!

## 📝 Exercise 4: Removing Sensitive Data from History

### Scenario: Committed Production Credentials

You accidentally committed a config file with production passwords. Even after deleting it, it's in history. You need to remove it completely.

### Step 1: Create the Problem

```bash
git checkout main
git checkout -b exercise/sensitive-data

# Accidentally commit sensitive file
cat > database/production-config.ini << 'EOF'
[Production]
Server=prod-sql-01.company.com
Database=CustomerDB
Username=sa
Password=SuperSecretProd123!
EOF

git add database/production-config.ini
git commit -m "Add database config"

# Make more commits
echo "-- More work" > database/OtherWork.sql
git add database/OtherWork.sql
git commit -m "Add other work"

echo "-- Even more" >> database/OtherWork.sql
git add database/OtherWork.sql
git commit -m "More changes"

# Realize mistake, delete file
git rm database/production-config.ini
git commit -m "Remove sensitive config file"

# File is gone NOW, but still in history!
git log --all --full-history -- database/production-config.ini

echo "😱 File is still in git history! Anyone can see the password!"
```

### Step 2: Remove from History with git-filter-repo

```bash
# Install git-filter-repo (better than filter-branch)
# pip install git-filter-repo
# or
# brew install git-filter-repo

# Check if available
if command -v git-filter-repo &> /dev/null; then
    echo "✅ git-filter-repo is available"

    # Remove file from all history
    git filter-repo --path database/production-config.ini --invert-paths

    echo "🎉 File removed from all history!"

    # Verify it's gone
    git log --all --full-history -- database/production-config.ini
    echo "No commits found (good!)"
else
    echo "⚠️  git-filter-repo not installed"
    echo "Install: pip install git-filter-repo"
    echo ""
    echo "Alternative: Use git filter-branch (slower):"
    echo 'git filter-branch --force --index-filter \
      "git rm --cached --ignore-unmatch database/production-config.ini" \
      --prune-empty --tag-name-filter cat -- --all'
fi
```

### Step 3: Using filter-branch (Alternative)

```bash
# If git-filter-repo isn't available, use filter-branch
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch database/production-config.ini' \
  --prune-empty --tag-name-filter cat -- --all

# Force push to remote (if you've pushed)
# git push origin --force --all

# Clean up
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "🎉 Sensitive data removed from all history"
```

### Step 4: Prevent Future Accidents

```bash
# Add to .gitignore
cat >> .gitignore << 'EOF'

# Sensitive files
*config.ini
*.env
*password*
*credentials*
*secret*
EOF

git add .gitignore
git commit -m "Add sensitive files to .gitignore"

# Add pre-commit hook to scan for secrets
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Scan for potential secrets

for FILE in $(git diff --cached --name-only); do
    if [ -f "$FILE" ]; then
        if grep -iE "password.*=|api[_-]?key.*=|secret.*=|token.*=" "$FILE"; then
            echo "❌ Potential secret detected in $FILE"
            echo "   Review carefully before committing"
            exit 1
        fi
    fi
done
EOF

chmod +x .git/hooks/pre-commit
```

## 📝 Exercise 5: Recovering from Rebase Disasters

### Scenario: Rebase Gone Wrong

You started an interactive rebase, got confused, and now your branch is a mess.

### Step 1: Create Rebase Problem

```bash
git checkout main
git checkout -b exercise/rebase-disaster

# Create several commits
for i in {1..5}; do
    echo "File $i" > "file$i.txt"
    git add "file$i.txt"
    git commit -m "Add file $i"
done

# Start interactive rebase and make it messy
# (In real scenario, you'd drop commits accidentally, reorder badly, etc.)
git rebase -i HEAD~5
# Simulate messing it up by aborting
git rebase --abort

# Now let's say you DID mess it up and continued
# Simulate by force-resetting to remove some commits
git reset --hard HEAD~2

git log --oneline
echo "😱 Lost commits during rebase!"
```

### Step 2: Recover Using Reflog

```bash
# Find the state before rebase started
git reflog

# Look for "rebase -i (start)" or the commit before you started
# Or find the last good commit

# Method 1: Reset to before rebase
git reset --hard HEAD@{1}

# Method 2: Find the exact commit
ORIG_HEAD=$(git reflog | grep "rebase" -B 1 | tail -2 | head -1 | cut -d' ' -f1)
git reset --hard $ORIG_HEAD

git log --oneline
echo "🎉 Recovered from rebase disaster!"
```

### Understanding ORIG_HEAD

```bash
# Git saves original HEAD as ORIG_HEAD during dangerous operations
# After reset, rebase, merge:
git reset --hard ORIG_HEAD

# This is often the quickest recovery!
```

## 🔧 Advanced Reflog Techniques

### 1. Reflog for Specific Branches

```bash
# View reflog for specific branch (not just HEAD)
git reflog show main
git reflog show feature/my-branch

# Useful when recovering deleted branches
```

### 2. Time-Based Recovery

```bash
# Go back to where HEAD was 2 hours ago
git reset --hard HEAD@{2.hours.ago}

# Go back to yesterday
git reset --hard HEAD@{yesterday}

# Go back to specific time
git reset --hard HEAD@{2024-10-28.14:00}
```

### 3. Find When File Was Deleted

```bash
# Find when specific file was removed
git log --all --full-history -- database/MissingProc.sql

# See the content of the deleted file
git show HEAD~3:database/MissingProc.sql

# Recover it
git checkout HEAD~3 -- database/MissingProc.sql
```

### 4. Visualize Reflog

```bash
# See reflog with graph
git log --graph --oneline --all --reflog

# See what happened in last 10 operations
git reflog -10

# See detailed reflog
git log -g --abbrev-commit --pretty=oneline
```

## 📊 Recovery Decision Tree

```
Something went wrong?
        ↓
Did you commit the work?
        ↓
    Yes → Check reflog: git reflog
        ↓
    Find the commit before the mistake
        ↓
    git reset --hard <commit-hash>
        ↓
    ✅ Recovered!

    No → Was it staged (git add)?
        ↓
    Yes → git fsck --lost-found
        ↓
    Find blob, recover content
        ↓
    ⚠️  Partially recovered

    No → 😢 Lost forever
        ↓
    Lesson learned: commit often!
```

## 🎓 Recovery Scenarios Cheat Sheet

### Lost Commits After Reset

```bash
git reflog
git reset --hard HEAD@{1}
```

### Deleted Branch

```bash
git reflog | grep <branch-name>
git branch <branch-name> <commit-hash>
```

### Bad Merge

```bash
git reset --hard ORIG_HEAD
# or
git reset --hard HEAD@{1}
```

### Bad Rebase

```bash
git rebase --abort  # If still in progress
# or
git reset --hard ORIG_HEAD  # If completed
```

### Committed Sensitive Data

```bash
# Small repos:
git filter-repo --path <file> --invert-paths

# Large repos or specific content:
git filter-repo --replace-text sensitive-patterns.txt
```

### Deleted Stash

```bash
git fsck --unreachable | grep commit
git show <commit-hash>  # Check if it's your stash
git stash apply <commit-hash>
```

## ⚠️ Reflog Limitations

### 1. Reflog is Local Only

```bash
# Reflog is NOT pushed to remote
# Each developer has their own reflog
# Can't recover from someone else's reflog
```

### 2. Reflog Expires

```bash
# Default: 90 days for reachable, 30 days for unreachable

# Check expiry settings
git config --get gc.reflogExpire
git config --get gc.reflogExpireUnreachable

# Extend reflog retention
git config gc.reflogExpire 180.days
git config gc.reflogExpireUnreachable 90.days
```

### 3. Uncommitted Work is Hard to Recover

```bash
# Only possible if:
# 1. You ran git add (creates blob)
# 2. Or file still exists in working directory
# 3. Or you have editor backup/autosave

# Prevention: Commit often! Use WIP commits
git add .
git commit -m "WIP: Work in progress"
# Can always clean up later with interactive rebase
```

## 💡 Prevention Better Than Recovery

### 1. Commit Often with WIP

```bash
# Don't fear committing incomplete work
git commit -m "WIP: Half done with customer report"

# Clean up later
git rebase -i main
# Squash WIP commits together
```

### 2. Use Branches Liberally

```bash
# Create backup branches before dangerous operations
git branch backup-before-rebase

# If rebase goes wrong, just:
git checkout backup-before-rebase
```

### 3. Tag Important States

```bash
# Before major changes
git tag before-major-refactor

# Easy recovery
git reset --hard before-major-refactor
```

### 4. Stash Before Experiments

```bash
# Before trying something risky
git stash save "Before experimenting with complex rebase"

# If it fails
git stash pop
```

### 5. Use Git GUI Tools

```bash
# Visual tools make reflog easier
# - GitKraken
# - SourceTree
# - VS Code Git Graph extension
```

## 🎯 Practice Challenges

### Challenge 1: The Complete Disaster

1. Create 10 commits
2. Delete 3 files
3. Reset --hard to remove 5 commits
4. Delete your branch
5. Checkout different branch
6. Recover EVERYTHING

### Challenge 2: Secret Hunt

1. Accidentally commit API key in config file
2. Make 20 more commits
3. Remove the API key from entire history
4. Verify it's truly gone

### Challenge 3: Time Travel

1. Break your stored procedure
2. Don't know which commit broke it
3. Use reflog to find working version from yesterday
4. Recover and compare

## 🎊 Summary

Advanced recovery techniques:
- ✅ **Reflog** - Your safety net for 30-90 days
- ✅ **filter-repo** - Remove sensitive data from history
- ✅ **fsck** - Find orphaned objects
- ✅ **ORIG_HEAD** - Quick undo for reset/rebase/merge
- ✅ **Time-based recovery** - Go back to specific times

**Key Principles:**
1. Git rarely deletes anything permanently (30+ days)
2. Reflog tracks ALL head movements
3. Staged files create recoverable blobs
4. Prevention is better than recovery
5. Commit often, fix history later

**Best Practices:**
- Tag before major operations
- Create backup branches
- Commit WIP frequently
- Extend reflog retention
- Use git hooks to prevent sensitive commits

**Golden Rule:**
> "It's not truly lost until garbage collection runs (30-90 days)"

You now have the skills to recover from almost any Git disaster. Use them wisely, but more importantly, use prevention techniques to avoid needing them!

**Congratulations!** You've completed all 10 lessons of Git for DBAs. You're now equipped to handle any Git scenario with confidence!

## 📚 What's Next?

- Review [Practice Scenarios](../exercises/PRACTICE-SCENARIOS.md)
- Try [Team Collaboration Scenarios](../exercises/TEAM-COLLABORATION.md)
- Explore [Git Worktrees](../docs/GIT-WORKTREES.md)
- Master your workflow with [Quick Reference](../QUICK-REFERENCE.md)
