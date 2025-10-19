# Troubleshooting Guide - When Things Go Wrong

This guide helps you recover from common Git mistakes. Don't panic - almost everything is recoverable!

## 🆘 Emergency Recovery

### "Help! I don't know what's happening!"

```bash
# First, check your status
git status

# See what branch you're on
git branch

# See your recent history
git log --oneline -10

# See ALL recent actions (your safety net)
git reflog
```

## 🔥 Common Mistakes and Fixes

### 1. "I committed to the wrong branch"

#### Scenario
```bash
# You're on main
git branch
# * main

# You make commits (oops!)
git commit -m "Feature work"
```

#### Fix
```bash
# Note the commit hash
git log --oneline -1
# abc123 Feature work

# Create the correct branch with your commit
git branch feature/correct-branch

# Remove the commit from main
git reset --hard HEAD~1

# Switch to the correct branch
git checkout feature/correct-branch
# Your commit is there!
```

### 2. "I need to undo my last commit"

#### Scenario
```bash
# Just committed something wrong
git commit -m "Wrong changes"
```

#### Fix - If NOT pushed yet
```bash
# Option 1: Undo but keep changes (to fix them)
git reset --soft HEAD~1
# Edit files, then commit again

# Option 2: Undo but keep changes unstaged
git reset HEAD~1
# Edit and stage selectively

# Option 3: Completely discard the commit
git reset --hard HEAD~1
```

#### Fix - If ALREADY pushed
```bash
# DON'T use reset! Use revert instead
git revert HEAD
git push
```

### 3. "I accidentally deleted a branch"

#### Scenario
```bash
git branch -D feature/important
# Deleted branch feature/important
```

#### Fix
```bash
# Find the branch in reflog
git reflog | grep feature/important

# You'll see something like:
# abc123 HEAD@{4}: commit: Last commit on feature/important

# Recreate the branch
git branch feature/important abc123

# Or checkout directly
git checkout -b feature/important abc123
```

### 4. "I made changes and want to switch branches"

#### Scenario
```bash
# You have uncommitted changes
git checkout other-branch
# Error: Your local changes would be overwritten
```

#### Fix
```bash
# Option 1: Stash your changes
git stash
git checkout other-branch
# Later: git stash pop

# Option 2: Commit your changes
git add .
git commit -m "WIP: In progress"
git checkout other-branch

# Option 3: Create a new branch with changes
git checkout -b new-branch-for-these-changes
```

### 5. "I have merge conflicts and don't know what to do"

#### Scenario
```bash
git merge feature-branch
# CONFLICT in file.sql
```

#### Fix
```bash
# See what's conflicted
git status

# Open the conflicted file
# Look for conflict markers:
# <<<<<<< HEAD
# Your changes
# =======
# Their changes
# >>>>>>> feature-branch

# Edit the file to resolve (remove markers)
# Then:
git add file.sql
git commit

# If it's too complicated, abort:
git merge --abort
```

#### Quick conflict resolution commands
```bash
# Take all of our changes
git checkout --ours file.sql
git add file.sql

# Take all of their changes
git checkout --theirs file.sql
git add file.sql

# Use merge tool (if configured)
git mergetool
```

### 6. "My rebase is a mess"

#### Scenario
```bash
git rebase main
# Lots of conflicts, getting confused
```

#### Fix
```bash
# Just abort and start over
git rebase --abort

# Try merge instead
git merge main

# Or try rebase with a strategy
git rebase -X theirs main  # Prefer their changes in conflicts
git rebase -X ours main    # Prefer our changes in conflicts
```

### 7. "I accidentally committed sensitive data"

#### Scenario
```bash
# Committed a file with passwords
git commit -m "Add config"
# Oops! config.env has passwords
```

#### Fix - If NOT pushed yet
```bash
# Option 1: Remove file and amend
git rm config.env
git commit --amend

# Option 2: Reset and recommit
git reset --soft HEAD~1
git rm --cached config.env
echo "config.env" >> .gitignore
git add .
git commit -m "Add config (without sensitive file)"
```

#### Fix - If ALREADY pushed
```bash
# You need to remove from history
# Use interactive rebase
git rebase -i HEAD~N  # N is number of commits back

# Mark the commit as 'edit'
# When it stops:
git rm config.env
git commit --amend
git rebase --continue

# Force push (⚠️ coordinate with team)
git push --force-with-lease

# Add to .gitignore
echo "config.env" >> .gitignore
git add .gitignore
git commit -m "Add .gitignore for sensitive files"
```

### 8. "I did a git reset --hard and lost my work"

#### Scenario
```bash
git reset --hard HEAD~5
# Oh no! I needed those commits!
```

#### Fix
```bash
# Check reflog (keeps 90 days of history)
git reflog

# Find your lost commits
# abc123 HEAD@{1}: commit: Important work
# def456 HEAD@{2}: commit: More work

# Recover them
git reset --hard abc123

# Or cherry-pick specific commits
git cherry-pick def456
```

### 9. "I force-pushed and broke everything"

#### Scenario
```bash
git reset --hard HEAD~10
git push --force origin main
# Team's work is now lost!
```

#### Fix
```bash
# If someone else still has the good commits:
# Have them share their commit hash

# Or check GitHub/GitLab/etc's UI for the old commit

# Reset to that commit
git reset --hard <good-commit-hash>
git push --force

# Lesson learned: Never force push shared branches!
# If you must force push: use --force-with-lease
git push --force-with-lease
```

### 10. "My working directory is messy and I want to start fresh"

#### Scenario
```bash
# Lots of uncommitted changes, half-done experiments
git status
# Shows tons of modified files
```

#### Fix
```bash
# Save everything just in case
git stash

# See clean state
git status

# If you want those changes back
git stash pop

# If you really want to discard everything
git reset --hard HEAD
git clean -fd  # Remove untracked files and directories

# But be careful! This is permanent
# Check what would be deleted first:
git clean -n  # Dry run
```

### 11. "I merged the wrong branch"

#### Scenario
```bash
git merge feature-wrong
# Oops! Meant to merge feature-right
```

#### Fix
```bash
# If NOT pushed yet
git reset --hard HEAD~1

# If ALREADY pushed
git revert -m 1 HEAD
git push

# Then merge the correct branch
git merge feature-right
```

### 12. "I want to split a commit into multiple commits"

#### Scenario
```bash
# One commit has too many changes
git log --oneline -1
# abc123 Add tables, indexes, and procedures
```

#### Fix
```bash
# Use interactive rebase
git rebase -i HEAD~1

# Change 'pick' to 'edit'
# Git will stop at that commit

# Undo the commit but keep changes
git reset HEAD^

# Now commit changes separately
git add database/tables.sql
git commit -m "Add tables"

git add database/indexes.sql
git commit -m "Add indexes"

git add database/procedures.sql
git commit -m "Add procedures"

# Continue
git rebase --continue
```

### 13. "I pulled and got conflicts I don't understand"

#### Scenario
```bash
git pull
# Merge conflict in multiple files
```

#### Fix
```bash
# Abort the pull
git merge --abort

# Update your local branch first
git fetch origin

# View the differences before merging
git diff HEAD origin/main

# If you want to keep your changes on top
git rebase origin/main

# Or merge (creates merge commit)
git merge origin/main
```

### 14. "Git says 'Detached HEAD state'"

#### Scenario
```bash
git checkout abc123
# You are in 'detached HEAD' state
```

#### Fix
```bash
# If you made commits you want to keep
git branch new-branch-name
git checkout new-branch-name

# Or directly
git checkout -b new-branch-name

# If you didn't make commits, just checkout a branch
git checkout main
```

### 15. "I committed a huge file by mistake"

#### Scenario
```bash
# Committed a 2GB database backup
git commit -m "Add files"
# Everything is slow now
```

#### Fix - If NOT pushed yet
```bash
# Remove from last commit
git rm --cached huge-file.bak
git commit --amend

# Add to .gitignore
echo "*.bak" >> .gitignore
```

#### Fix - If ALREADY pushed
```bash
# Use BFG Repo Cleaner or git filter-branch
# This is complex - see: https://rtyley.github.io/bfg-repo-cleaner/

# Simple but destructive approach:
# Remove from history with filter-branch
git filter-branch --tree-filter 'rm -f huge-file.bak' HEAD
git push --force
```

## 🔍 Diagnostic Commands

When you're not sure what's wrong:

```bash
# Where am I?
git status
git branch

# What did I just do?
git reflog -10
git log --oneline -10

# What's different?
git diff                    # Unstaged changes
git diff --staged           # Staged changes
git diff HEAD               # All changes

# What branches exist?
git branch -a               # All branches
git remote -v               # Remote repositories

# What's the history?
git log --oneline --graph --all

# Who changed what?
git blame file.sql
git log -p file.sql         # History of a file
```

## 🛡️ Prevention Tips

### 1. Always check before dangerous operations
```bash
# Before reset
git log --oneline -5

# Before force push
git log --oneline origin/main..HEAD

# Before delete
git branch -d feature  # Safe delete (prevents deleting unmerged)
git branch -D feature  # Force delete (dangerous)
```

### 2. Use safer alternatives
```bash
# Instead of --force, use:
git push --force-with-lease

# Instead of reset on public branches, use:
git revert

# Instead of deleting changes, use:
git stash
```

### 3. Create backup branches
```bash
# Before risky operations
git branch backup-just-in-case

# Do your risky operation
# If it works:
git branch -D backup-just-in-case

# If it fails:
git reset --hard backup-just-in-case
```

### 4. Configure helpful aliases
```bash
git config --global alias.undo "reset HEAD~1 --mixed"
git config --global alias.nuke "reset --hard HEAD"
git config --global alias.save "stash save"
```

## 📞 Getting Help

### Built-in Help
```bash
# General help
git help

# Help for specific command
git help commit
git help rebase

# Quick reference
git commit --help
```

### Check Git Version
```bash
git --version
# Make sure you're on a recent version
```

### Verify Repository State
```bash
# Is this a Git repo?
git rev-parse --git-dir

# What's the current commit?
git rev-parse HEAD

# What's the current branch?
git rev-parse --abbrev-ref HEAD
```

## 🎓 Key Principles for Recovery

1. **Don't panic** - Almost everything can be recovered
2. **Check reflog first** - It's your safety net
3. **Commits aren't lost for ~90 days** - Even after reset
4. **Stash when in doubt** - Save your work before experimenting
5. **Abort when confused** - `--abort` is your friend
6. **Ask for help** - Better than making it worse

## 🆘 Last Resort

If everything is completely broken and you have a backup:

```bash
# Save your current state (just in case)
cp -r .git .git-backup

# Start fresh from remote
git fetch origin
git reset --hard origin/main

# Or clone fresh and copy your changes
cd ..
git clone <url> fresh-clone
# Copy your changes from old directory
```

Remember: Git is designed to not lose data. Even "deleted" commits stay in the reflog for months. Take a deep breath and work through it systematically!

## 📚 Additional Resources

- **Git Reflog Documentation:** https://git-scm.com/docs/git-reflog
- **Git Recovery Guide:** https://github.blog/2015-06-08-how-to-undo-almost-anything-with-git/
- **Oh Shit, Git!?!:** https://ohshitgit.com/ (practical recovery recipes)

Keep this guide handy - everyone makes mistakes with Git! 🚀

