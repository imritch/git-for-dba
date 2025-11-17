# Practice Scenarios - Learn by Doing

These are realistic scenarios you can practice to solidify your Git skills. Each scenario builds on the concepts from the lessons.

**📖 New Addition:** Looking for guidance on when to merge vs rebase, especially for PR scenarios? Check out the [Merge vs Rebase Decision Guide](./MERGE-VS-REBASE-DECISION.md) for a comprehensive real-world walkthrough.

## 🎯 Scenario 1: The Friday Afternoon Disaster

**Situation:** It's Friday at 4:45 PM. You've been working on a complex stored procedure all afternoon with 12 commits. Code review is Monday morning. Your commit history looks like:

```
- WIP fixing bug
- still working
- almost there
- fixed typo
- another typo
- testing
- still testing
- removed debug code
- oops forgot semicolon
- fixing again
- I think this works
- Final version
```

**Task:** Clean this up into 2-3 professional commits before Monday.

**Solution Steps:**
```bash
# Use interactive rebase
git rebase -i HEAD~12

# Squash related commits
# Reword commit messages to be professional
# Result: 
#   - "Implement GetCustomerReport procedure with date filtering"
#   - "Add error handling and performance optimization"
#   - "Add unit tests and documentation"
```

**Skills Practiced:** Interactive rebase, squashing, rewording

---

## 🎯 Scenario 2: The Wrong Branch Mistake

**Situation:** You just made 5 commits to `main` when you should have been working on a feature branch called `feature/new-indexes`.

**Task:** Move your commits to the correct branch without losing any work.

**Solution Steps:**
```bash
# Note the commits you made (get their hashes)
git log --oneline -5

# Create and switch to feature branch
git checkout -b feature/new-indexes

# Go back to main
git checkout main

# Reset main to before your commits
git reset --hard HEAD~5

# Switch back to feature branch - your commits are there!
git checkout feature/new-indexes
```

**Alternative Solution (using cherry-pick):**
```bash
# From main, note commit hashes
git log --oneline -5

# Create feature branch from the correct point
git checkout -b feature/new-indexes HEAD~5

# Cherry-pick your commits
git cherry-pick <hash1> <hash2> <hash3> <hash4> <hash5>

# Reset main
git checkout main
git reset --hard HEAD~5
```

**Skills Practiced:** Reset, branching, cherry-pick

---

## 🎯 Scenario 3: The Merge Conflict Nightmare

**Situation:** Two DBAs (you and a coworker) both modified the same stored procedure. You need to merge your changes.

**Setup:**
```bash
# Create scenario
cat > database/ProcessOrders.sql << 'EOF'
CREATE PROCEDURE ProcessOrders AS
BEGIN
    SELECT * FROM Orders;
END
EOF
git add database/ProcessOrders.sql
git commit -m "Base procedure"

# Your branch
git checkout -b your-changes
cat > database/ProcessOrders.sql << 'EOF'
CREATE PROCEDURE ProcessOrders
    @StartDate DATE
AS
BEGIN
    SELECT OrderId, OrderDate, Amount 
    FROM Orders 
    WHERE OrderDate >= @StartDate;
END
EOF
git commit -am "Add date filtering"

# Coworker's branch
git checkout main
git checkout -b coworker-changes
cat > database/ProcessOrders.sql << 'EOF'
CREATE PROCEDURE ProcessOrders
    @CustomerId INT
AS
BEGIN
    SELECT OrderId, CustomerId, Amount 
    FROM Orders 
    WHERE CustomerId = @CustomerId;
END
EOF
git commit -am "Add customer filtering"

# Merge coworker to main
git checkout main
git merge coworker-changes

# Now merge your changes - CONFLICT!
git merge your-changes
```

**Task:** Resolve the conflict by keeping BOTH features.

**Solution:**
```sql
CREATE PROCEDURE ProcessOrders
    @StartDate DATE = NULL,
    @CustomerId INT = NULL
AS
BEGIN
    SELECT OrderId, CustomerId, OrderDate, Amount 
    FROM Orders 
    WHERE (@StartDate IS NULL OR OrderDate >= @StartDate)
      AND (@CustomerId IS NULL OR CustomerId = @CustomerId);
END
```

```bash
# Mark resolved and commit
git add database/ProcessOrders.sql
git commit -m "Merge: Add both date and customer filtering"
```

**Skills Practiced:** Merge conflict resolution, SQL logic

---

## 🎯 Scenario 4: The Hotfix Marathon

**Situation:** A critical security vulnerability was found in production. You fixed it on `main`. Now you need to apply it to three older release branches: `release/v1.0`, `release/v2.0`, and `release/v3.0`.

**Setup:**
```bash
# Create release branches
git checkout -b release/v1.0
echo "Version 1.0" > version.txt
git add version.txt
git commit -m "Release 1.0"

git checkout main
git checkout -b release/v2.0
echo "Version 2.0" > version.txt
git add version.txt
git commit -m "Release 2.0"

git checkout main
git checkout -b release/v3.0
echo "Version 3.0" > version.txt
git add version.txt
git commit -m "Release 3.0"

# Create the security fix on main
git checkout main
cat > database/SecurityFix.sql << 'EOF'
-- FIX: SQL Injection vulnerability
CREATE PROCEDURE SafeLogin
    @Username NVARCHAR(50),
    @Password NVARCHAR(100)
AS
BEGIN
    -- Now using parameters instead of dynamic SQL
    SELECT UserId FROM Users 
    WHERE Username = @Username 
      AND PasswordHash = HASHBYTES('SHA2_256', @Password);
END
EOF
git add database/SecurityFix.sql
git commit -m "SECURITY: Fix SQL injection in login procedure"
```

**Task:** Apply this fix to all three release branches.

**Solution:**
```bash
# Get the fix commit hash
FIX_HASH=$(git rev-parse HEAD)

# Apply to each release
git checkout release/v1.0
git cherry-pick $FIX_HASH

git checkout release/v2.0
git cherry-pick $FIX_HASH

git checkout release/v3.0
git cherry-pick $FIX_HASH

# Verify all branches have the fix
for branch in main release/v1.0 release/v2.0 release/v3.0; do
    echo "=== $branch ==="
    git checkout $branch
    git log --oneline -1
done
```

**Skills Practiced:** Cherry-pick, hotfix workflow

---

## 🎯 Scenario 5: The Stash Stack

**Situation:** You're working on feature A when you get pulled into feature B, then an urgent bug fix, then back to feature A.

**Setup:**
```bash
# Start feature A
git checkout -b feature/A
echo "Feature A work" > featureA.sql
git add featureA.sql
# Don't commit yet - urgent interruption!
```

**Task:** Manage multiple context switches without losing work.

**Solution:**
```bash
# Save feature A work
git stash save "Feature A: In progress"

# Work on feature B
git checkout main
git checkout -b feature/B
echo "Feature B" > featureB.sql
git add featureB.sql
# Another interruption!

# Save feature B work
git stash save "Feature B: In progress"

# Urgent bug fix
git checkout main
git checkout -b hotfix/urgent
echo "Bug fix" > bugfix.sql
git add bugfix.sql
git commit -m "URGENT: Fix production bug"

# Merge hotfix
git checkout main
git merge hotfix/urgent

# Back to feature B
git checkout feature/B
git stash list  # See your stashes
git stash apply stash@{0}  # "Feature B: In progress"
# Complete feature B
git commit -m "Complete feature B"

# Back to feature A
git checkout feature/A
git stash apply stash@{1}  # "Feature A: In progress"
# Complete feature A
git commit -m "Complete feature A"

# Clean up stashes
git stash clear
```

**Skills Practiced:** Stash, context switching

---

## 🎯 Scenario 6: The Accidental Force Push

**Situation:** You accidentally reset main and force-pushed, erasing 5 commits that your team had already pulled.

**Setup:**
```bash
# Create commits
for i in {1..5}; do
    echo "Commit $i" > file$i.sql
    git add file$i.sql
    git commit -m "Commit $i"
done

# Oops! Accidentally reset and force push
git reset --hard HEAD~5
# In real life: git push --force
```

**Task:** Recover the lost commits.

**Solution:**
```bash
# Check reflog
git reflog

# Find the commit before the reset
# Look for: abc123 HEAD@{1}: commit: Commit 5

# Recover
git reset --hard HEAD@{1}

# Or if you know the commit hash
git reset --hard <hash-of-commit-5>

# Verify
git log --oneline

# If you really did force push, notify team:
# git push --force
# And tell them to: git fetch origin && git reset --hard origin/main
```

**Skills Practiced:** Reflog, recovery

---

## 🎯 Scenario 7: The Rebase Cleanup

**Situation:** Your feature branch is 2 weeks old. Main has moved forward with 50 commits. Your branch has 20 messy commits.

**Task:** Bring your branch up to date and clean up your history.

**Setup:**
```bash
# Simulate old feature branch
git checkout -b feature/old-work

# Make messy commits
for i in {1..20}; do
    echo "Change $i" >> mywork.sql
    git add mywork.sql
    git commit -m "WIP $i"
done

# Simulate main moving forward
git checkout main
for i in {1..50}; do
    echo "Main change $i" > main-file-$i.sql
    git add main-file-$i.sql
    git commit -m "Main: Change $i"
done
```

**Solution:**
```bash
# First, rebase onto latest main
git checkout feature/old-work
git rebase main
# Resolve any conflicts

# Then, clean up your commits
git rebase -i main

# In the editor, squash your 20 commits into 3-5 logical commits
# pick for first commit of each logical group
# squash for the rest

# Force push your cleaned branch (safe on feature branches)
git push --force-with-lease origin feature/old-work
```

**Skills Practiced:** Rebase, interactive rebase, squashing

---

## 🎯 Scenario 8: The Deployment Rollback

**Situation:** You deployed a change to production (committed and pushed to main). It's causing issues. You need to rollback immediately.

**Setup:**
```bash
# Good state
cat > database/Procedure.sql << 'EOF'
CREATE PROCEDURE GetData AS
BEGIN
    SELECT * FROM GoodTable;
END
EOF
git add database/Procedure.sql
git commit -m "Working procedure"

# Bad deployment
cat > database/Procedure.sql << 'EOF'
CREATE PROCEDURE GetData AS
BEGIN
    SELECT * FROM BadTable;  -- This table doesn't exist!
END
EOF
git commit -am "DEPLOYED: Update procedure"
git push origin main
```

**Task:** Rollback the deployment safely.

**Solution (Correct way - revert):**
```bash
# Revert the bad commit
git revert HEAD
git push origin main

# Now production has:
# Commit 3: Revert "DEPLOYED: Update procedure"
# Commit 2: DEPLOYED: Update procedure
# Commit 1: Working procedure

# Procedure is back to working state
```

**Solution (Wrong way - never do this):**
```bash
# ❌ DON'T DO THIS
git reset --hard HEAD~1
git push --force origin main
# This will cause problems for everyone who pulled the bad commit
```

**Skills Practiced:** Revert, safe rollback practices

---

## 🎯 Challenge: Complete Database Migration Workflow

**Situation:** Implement a complete database change workflow with proper Git practices.

**Requirements:**
1. Create a new table with 3 versions (v1, v2, v3)
2. Add 2 indexes
3. Create 3 stored procedures
4. Make mistakes and clean them up
5. Have merge conflicts and resolve them
6. Create a clean history

**Try to incorporate:**
- ✅ Feature branches
- ✅ Commits with good messages
- ✅ Merge conflicts
- ✅ Interactive rebase cleanup
- ✅ Stashing
- ✅ Cherry-picking
- ✅ Reverting bad changes

This is your comprehensive exercise - good luck!

---

## 📝 Quick Tips for All Scenarios

1. **Always check your status:** `git status`
2. **View your history:** `git log --oneline --graph --all`
3. **Before force operations:** `git reflog` is your friend
4. **When in doubt:** `git stash` your work first
5. **Made a mistake?** Check `git reflog` to recover

## 🎓 Next Steps

After completing these scenarios:
1. Create your own scenarios based on your work
2. Practice with real database scripts
3. Set up your own Git workflow
4. Share knowledge with your team

Keep practicing! Git mastery comes with repetition. 🚀

