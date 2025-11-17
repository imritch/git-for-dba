# Merge vs Rebase: Making the Right Decision

A comprehensive guide to choosing between merge and rebase in real-world scenarios, especially when working with Pull Requests and team collaboration.

---

## 📖 The Real-World Scenario

**Situation:** You've been working on a feature branch for 3 weeks (e.g., migrating Extended Events Sessions to an automated deployment application). Your PR has been through several rounds of code review with back-and-forth discussions. Meanwhile, the `main` branch has progressed with many new changes from other team members.

A senior colleague advises: *"You should merge main into your branch before submitting the PR again."*

**Questions arise:**
- What does "merge main into my branch" actually mean?
- Shouldn't I be rebasing instead?
- What's the difference and which is better?
- How do I execute this merge?

---

## 🤔 What Does "Merge Main into Your Branch" Mean?

When someone says "merge main into your branch," they mean bringing all the recent changes from the `main` branch into your feature branch by creating a **merge commit**.

**Command:**
```bash
# While on your feature branch
git checkout your-feature-branch
git fetch origin                    # Get latest changes from remote
git merge origin/main               # Merge main INTO your branch
```

**What happens:**
- Git creates a new "merge commit" that combines both histories
- Your feature branch now contains all changes from main
- The complete history of both branches is preserved
- A clear record shows exactly when you integrated main's changes

**Visual:**
```
Before merge:
    A---B---C---D---E  main (latest)
         \
          F---G---H  your-feature-branch

After merging main into your branch:
    A---B---C---D---E  main
         \           \
          F---G---H---M  your-feature-branch (M is the merge commit)
```

---

## 🔄 Merge vs Rebase: Understanding the Core Difference

### **Git Merge**

Creates a new "merge commit" that combines two branches.

**Characteristics:**
- ✅ Preserves complete history of both branches
- ✅ Shows that parallel development happened
- ✅ Non-destructive - doesn't change existing commits
- ✅ Safe for shared/reviewed branches
- ✅ Maintains PR review context and comments
- ❌ Creates extra merge commits (can look messy)
- ❌ History shows branching/converging (not linear)

**Visual:**
```
Before:
    A---B---C  main
         \
          D---E  feature

After: git merge main
    A---B---C-------M  feature
         \         /
          D---E---
    (M is a new merge commit)
```

### **Git Rebase**

Moves/rewrites your commits on top of another branch.

**Characteristics:**
- ✅ Creates linear, clean history
- ✅ No merge commits
- ✅ Makes it look like work was done sequentially
- ❌ **Rewrites commit history** (changes commit SHAs)
- ❌ Can cause problems if others pulled your branch
- ❌ Destroys PR review context (all commits change)
- ❌ Requires force-push (risky)

**Visual:**
```
Before:
    A---B---C  main
         \
          D---E  feature

After: git rebase main
    A---B---C  main
             \
              D'---E'  feature
    (D' and E' are NEW commits with different hashes)
```

---

## 🎯 Why "Merge" is Recommended for Your PR Scenario

When working on a **long-running PR with code reviews**, merging is the safer, more professional choice.

### **Reasons to Merge (Not Rebase) in this case:**

1. **PR has been reviewed for 3 weeks**
   - Reviewers have left comments on specific commits
   - Rebase changes all commit SHAs → comments lose context
   - Merge preserves the review trail

2. **Branch is already shared/public**
   - Others may have pulled your branch to test locally
   - Rebase + force-push disrupts their work
   - Merge is non-destructive and collaborative

3. **Close to approval**
   - Don't want to disrupt the review process
   - Merge shows exactly what new changes were integrated
   - Reviewers can see "just review the merge commit" for new conflicts

4. **Team-friendly workflow**
   - Many enterprise teams require merge workflows
   - Preserves exact history and traceability
   - Shows collaboration points clearly

5. **Safer operation**
   - No force-push required
   - Can't accidentally lose work
   - Easy to undo if something goes wrong

---

## ⚖️ When to Use Merge vs Rebase

### **Use MERGE when:**

✅ **Branch has been shared/reviewed** (your case!)
- PR is open and has review comments
- Others may have pulled your branch
- You're close to getting approval

✅ **Working in a team environment**
- Team policy prefers merge workflows
- Collaboration and traceability matter
- You want to preserve exact history

✅ **Integrating long-running feature branches**
- Shows the context of when integration happened
- Preserves the development timeline
- Easier to understand the project history

✅ **You want to preserve complete history**
- Need to see exactly what happened when
- Audit trails are important
- Parallel development should be visible

---

### **Use REBASE when:**

✅ **Working on a private/local branch**
- Haven't pushed yet, or working solo
- No one else has pulled your branch
- You want clean history before sharing

✅ **Cleaning up before creating a PR**
- 20 "WIP" commits → rebase into 3 clean commits
- Want to present professional commit history
- No review comments to lose

✅ **Catching up with main (pre-PR)**
- Your local branch is behind main
- You want to test against latest changes
- Haven't opened PR yet

✅ **Company policy requires linear history**
- Some teams mandate rebase workflows
- Main branch should be linear
- Specified in contribution guidelines

---

## 📝 Step-by-Step: How to Merge Main into Your Branch

Here's the complete workflow for your scenario (3-week PR needing main's changes):

### **Step 1: Ensure your work is committed**

```bash
# Check status - should show "nothing to commit, working tree clean"
git status
```

If you have uncommitted changes:
```bash
git add .
git commit -m "WIP: Save current progress"
```

### **Step 2: Checkout your feature branch**

```bash
git checkout your-extended-events-branch
```

### **Step 3: Fetch latest changes from remote**

```bash
# Download latest refs from remote without merging
git fetch origin
```

### **Step 4: Merge main into your feature branch**

```bash
git merge origin/main
```

**Two possible outcomes:**

#### **Outcome A: Clean merge (no conflicts)**
```
Merge made by the 'recursive' strategy.
 database/schema.sql | 15 +++++++++++++
 database/procs.sql  | 23 ++++++++++++++-----
 2 files changed, 38 insertions(+), 5 deletions(-)
```

✅ **Success!** Skip to Step 6.

#### **Outcome B: Merge conflicts**
```
Auto-merging database/extended-events-config.sql
CONFLICT (content): Merge conflict in database/extended-events-config.sql
Automatic merge failed; fix conflicts and then commit the result.
```

⚠️ **Conflicts detected** → Proceed to Step 5.

### **Step 5: Resolve merge conflicts (if any)**

```bash
# See which files have conflicts
git status

# Output shows:
# Unmerged paths:
#   both modified:   database/extended-events-config.sql
```

**Open the conflicted file** - you'll see conflict markers:

```sql
<<<<<<< HEAD (your changes from feature branch)
CREATE EVENT SESSION [AppPerformanceMonitoring]
ON SERVER
ADD EVENT sqlserver.sql_statement_completed
=======
CREATE EVENT SESSION [ApplicationMonitoring]
ON SERVER
ADD EVENT sqlserver.rpc_completed
>>>>>>> origin/main (changes from main branch)
```

**Resolve by choosing or combining:**
- Keep your version (HEAD)
- Keep their version (origin/main)
- Combine both changes manually

**Example resolution:**
```sql
-- Combined both monitoring approaches
CREATE EVENT SESSION [AppPerformanceMonitoring]
ON SERVER
ADD EVENT sqlserver.sql_statement_completed,
ADD EVENT sqlserver.rpc_completed
```

**Mark as resolved:**
```bash
# After editing and saving the file
git add database/extended-events-config.sql

# Check status - should now show "All conflicts fixed"
git status

# Complete the merge
git commit -m "Merge main into extended-events branch

Resolved conflicts in extended-events-config.sql by combining monitoring events"
```

### **Step 6: Push the updated branch**

```bash
git push origin your-extended-events-branch
```

**Note:** This is a regular push, **NOT** a force-push. That's the beauty of merge!

### **Step 7: Update your PR**

- Your PR automatically updates with the new merge commit
- Reviewers can see exactly what was integrated from main
- Review comments on previous commits remain intact
- You can add a comment: "Merged latest main to resolve conflicts and incorporate recent changes"

---

## 🛠️ Handling Merge Conflicts - Detailed Guide

Merge conflicts happen when the same lines of code were changed in both branches. This is common after 3 weeks of divergent development.

### **Common SQL Conflict Scenarios for DBAs:**

#### **Scenario 1: Same table modified differently**

**Your branch:**
```sql
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT,
    OrderDate DATETIME
);
```

**Main branch:**
```sql
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT,
    TotalAmount DECIMAL(10,2)
);
```

**Conflict markers:**
```sql
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT,
<<<<<<< HEAD
    OrderDate DATETIME
=======
    TotalAmount DECIMAL(10,2)
>>>>>>> origin/main
);
```

**Resolution (combine both):**
```sql
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY,
    CustomerId INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2)
);
```

#### **Scenario 2: Deployment changelog conflicts**

**Your branch:**
```xml
<changeSet id="20241001-01" author="you">
    <createTable tableName="Events"/>
</changeSet>
```

**Main branch:**
```xml
<changeSet id="20241001-01" author="teammate">
    <createTable tableName="Logs"/>
</changeSet>
```

**Resolution (renumber your changeset):**
```xml
<changeSet id="20241001-01" author="teammate">
    <createTable tableName="Logs"/>
</changeSet>
<changeSet id="20241001-02" author="you">
    <createTable tableName="Events"/>
</changeSet>
```

### **Using Visual Merge Tools**

Instead of manually editing conflict markers, use visual tools for easier resolution:

```bash
# Configure VS Code as merge tool (if not already)
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait --merge $REMOTE $LOCAL $BASE $MERGED'

# When conflicts occur, launch merge tool
git mergetool
```

**See `docs/MERGE-TOOLS.md` in this repo for detailed setup of:**
- VS Code (built-in 3-way merge)
- Beyond Compare
- KDiff3
- P4Merge
- vimdiff

---

## 🚨 What About Force-Push and Rebase?

### **Why NOT to rebase in your scenario:**

If you had rebased instead of merged:

```bash
# DON'T DO THIS for a 3-week PR!
git checkout your-extended-events-branch
git rebase origin/main  # Rewrites ALL your commits
git push --force origin your-extended-events-branch  # Dangerous!
```

**Consequences:**
1. ❌ **All commit SHAs change** → Review comments lose context
2. ❌ **Force-push overwrites remote** → Can lose work if done wrong
3. ❌ **Colleagues who pulled your branch have problems** → Their local copies conflict
4. ❌ **Reviewers confused** → "Where did all the commits I reviewed go?"
5. ❌ **Merge conflicts harder to resolve** → Must resolve per-commit during rebase

### **When force-push is acceptable:**

✅ **Solo feature branch** - You're the only one working on it
✅ **Pre-PR cleanup** - Squashing commits before initial PR creation
✅ **Explicitly requested** - Team asks you to rebase

**If you must force-push:**
```bash
# Safer force-push (rejects if remote has unexpected changes)
git push --force-with-lease origin your-branch
```

---

## 📊 Decision Tree: Merge vs Rebase

```
                Is your branch shared/public?
                (PR open, others have pulled it)
                          │
                ┌─────────┴─────────┐
               YES                 NO
                │                   │
                ↓                   ↓
        Has it been reviewed?    Is it pushed?
                │                   │
          ┌─────┴─────┐       ┌─────┴─────┐
         YES         NO      YES         NO
          │           │       │            │
          ↓           ↓       ↓            ↓
      USE MERGE   MERGE or   Your      USE REBASE
                   REBASE    Choice    (can still
                                        change freely)

Key Guidelines:
├─ Reviewed PR → ALWAYS MERGE
├─ Pushed but not reviewed → MERGE (safer) or rebase with force-push
├─ Local only → REBASE (clean history)
└─ Close to approval → DEFINITELY MERGE
```

---

## ✅ Real-World Example: The 3-Week PR

Let's walk through your exact scenario step-by-step:

### **Current State:**

```bash
# You've been on feature/extended-events-migration for 3 weeks
# Made 15 commits, PR has 8 review comments
# Main branch has moved ahead with 20+ commits from teammates

git log --oneline --graph --all
# * f8e9d2c (HEAD -> feature/extended-events-migration) Add session startup options
# * a7c8d1b Implement event filtering logic
# * 9d2e4f5 Configure extended events sessions
# ...  (12 more commits)
# | * 5f6g7h8 (origin/main) Fix database connection timeout
# | * 3d4e5f6 Update authentication procedure
# | * 1a2b3c4 Refactor logging mechanism
# |/
# * b3c4d5e (3 weeks ago) Common ancestor
```

### **Step-by-Step Execution:**

```bash
# 1. Ensure clean working directory
git status
# On branch feature/extended-events-migration
# nothing to commit, working tree clean ✓

# 2. Fetch latest from remote
git fetch origin
# Fetching origin...
# From github.com:yourteam/yourproject
#  * branch            main       -> FETCH_HEAD
#    1a2b3c4..5f6g7h8  main       -> origin/main

# 3. Merge main into your feature branch
git merge origin/main
# Auto-merging config/deployment.properties
# CONFLICT (content): Merge conflict in config/deployment.properties
# Auto-merging database/extended-events/monitoring-session.sql
# Automatic merge failed; fix conflicts and then commit the result.

# 4. Check which files have conflicts
git status
# On branch feature/extended-events-migration
# You have unmerged paths.
#
# Unmerged paths:
#   both modified:   config/deployment.properties

# 5. Open and resolve conflict
# Edit config/deployment.properties, resolve conflict markers
# Save the file

# 6. Mark as resolved and commit
git add config/deployment.properties
git commit -m "Merge main into extended-events-migration branch

Integrated latest changes from main including:
- Database connection timeout fix
- Authentication procedure updates
- Logging refactor

Resolved conflict in deployment.properties by combining connection settings"

# 7. Push to update PR
git push origin feature/extended-events-migration
# Enumerating objects: 8, done.
# Writing objects: 100% (8/8), done.
# To github.com:yourteam/yourproject.git
#    f8e9d2c..m9n0o1p  feature/extended-events-migration -> feature/extended-events-migration

# 8. Check the updated history
git log --oneline --graph --all
# * m9n0o1p (HEAD -> feature/extended-events-migration, origin/feature/extended-events-migration) Merge main into extended-events-migration
# |\
# | * 5f6g7h8 (origin/main) Fix database connection timeout
# | * 3d4e5f6 Update authentication procedure
# | * 1a2b3c4 Refactor logging mechanism
# * | f8e9d2c Add session startup options
# * | a7c8d1b Implement event filtering logic
# * | 9d2e4f5 Configure extended events sessions
# |/
# * b3c4d5e (3 weeks ago) Common ancestor
```

### **What Your PR Shows Now:**

- ✅ All your original 15 commits (preserved with review comments intact)
- ✅ One new merge commit showing integration with main
- ✅ Reviewers can see exactly what changed from main
- ✅ No force-push warnings or confusion
- ✅ Ready for final review and approval

---

## 🎓 Key Takeaways

1. **"Merge main into your branch"** = `git merge origin/main` while on your feature branch

2. **Merge vs Rebase choice depends on branch state:**
   - **Reviewed/shared branch** → MERGE (preserves review context)
   - **Private/local branch** → REBASE (clean history)

3. **Merge is safer for team collaboration:**
   - Non-destructive
   - No force-push needed
   - Preserves complete history
   - Maintains PR review trail

4. **Rebase is for clean history:**
   - Before creating PR
   - Solo branches
   - When explicitly required by team policy

5. **Your 3-week PR scenario → DEFINITELY MERGE:**
   - PR already reviewed
   - Branch shared with team
   - Close to approval
   - Team member explicitly suggested merge

6. **Conflicts are normal** after 3 weeks of divergent development:
   - Resolve carefully
   - Use visual merge tools if helpful
   - Test after merging

7. **After merging, communicate with reviewers:**
   - "Merged latest main - please review merge commit for conflicts resolved"
   - Shows professionalism and keeps everyone informed

---

## 🔧 Quick Reference Commands

```bash
# THE RECOMMENDED WORKFLOW (for your scenario)
git checkout your-feature-branch
git fetch origin
git merge origin/main
# (resolve any conflicts)
git add .
git commit -m "Merge main into feature branch"
git push origin your-feature-branch

# IF CONFLICTS OCCUR
git status                    # See conflicted files
# (edit files to resolve)
git add <resolved-files>
git commit                    # Completes the merge

# UNDO IF SOMETHING GOES WRONG
git merge --abort            # Before committing merge
git reset --hard HEAD~1      # After merge commit (dangerous!)

# VIEW MERGE TOOLS
git mergetool                # Launch configured merge tool

# CHECK WHAT CHANGED IN MAIN
git log your-branch..origin/main --oneline
git diff your-branch...origin/main
```

---

## 📚 Further Reading

- [Lesson 3: Git Rebase](../lessons/03-git-rebase.md) - Deep dive into rebase
- [Lesson 5: Merge Strategies](../lessons/05-merge-strategies.md) - Fast-forward, squash, no-ff
- [docs/MERGE-TOOLS.md](../docs/MERGE-TOOLS.md) - Visual merge tool setup
- [exercises/TEAM-COLLABORATION.md](./TEAM-COLLABORATION.md) - Team workflow scenarios
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - Common Git problems

---

## 💡 Pro Tips

1. **Always fetch before merging**
   ```bash
   git fetch origin  # Not just git pull
   ```

2. **Check what you're about to merge**
   ```bash
   git log your-branch..origin/main --oneline
   ```

3. **Communicate with your team**
   - Comment on PR after merging main
   - Mention if you resolved conflicts
   - Ask for re-review if significant changes

4. **Test after merging**
   - Run tests locally
   - Ensure merged code works
   - Check for integration issues

5. **Use merge tools for complex conflicts**
   - Don't struggle with text markers
   - Visual tools make resolution clearer
   - See docs/MERGE-TOOLS.md

6. **Preserve your work before risky operations**
   ```bash
   git branch backup-branch  # Quick backup
   ```

---

## ❓ FAQ

**Q: Can I rebase after merging?**
A: Technically yes, but don't. Pick one strategy and stick with it for a given branch.

**Q: What if I already rebased by mistake?**
A: If you haven't force-pushed yet, you can reset to the previous state:
```bash
git reflog  # Find the commit before rebase
git reset --hard HEAD@{n}
```

**Q: My team uses both merge and rebase - which do I follow?**
A: Follow team policy. Ask your tech lead. When in doubt for reviewed PRs, merge.

**Q: How do I handle merge conflicts in deployment changelogs?**
A: Usually involves renumbering changeset IDs. Keep chronological order. Both changesets should exist.

**Q: Is squash-merge different?**
A: Yes! Squash-merge is done when merging PR to main (all your commits become one). That's different from "merge main into your branch."

---

**Summary:** For your 3-week PR scenario with code reviews and team collaboration, **MERGE is the correct choice**. It's safer, preserves review context, and is team-friendly. Follow the step-by-step guide above, resolve any conflicts carefully, and you'll successfully integrate main's changes into your branch while maintaining all your hard work.

Good luck with your PR approval! 🚀
