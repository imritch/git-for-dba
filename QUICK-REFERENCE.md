# Git Quick Reference for DBAs

## 🚀 Essential Commands

### Viewing History
```bash
# Simple log
git log --oneline

# Graph view
git log --oneline --graph --all

# Pretty view with dates
git log --pretty=format:"%h - %an, %ar : %s"

# See who changed what
git log --stat

# Search commits
git log --grep="security"
git log --author="John"
```

### Stashing
```bash
# Save work
git stash
git stash save "descriptive message"
git stash -u  # Include untracked files

# View stashes
git stash list
git stash show -p stash@{0}

# Apply stashes
git stash pop           # Apply and remove
git stash apply         # Apply and keep
git stash apply stash@{2}

# Manage stashes
git stash drop stash@{0}
git stash clear
```

### Branching
```bash
# Create and switch
git checkout -b feature/my-feature
git switch -c feature/my-feature  # Newer syntax

# Switch branches
git checkout main
git switch main  # Newer syntax

# List branches
git branch              # Local
git branch -r           # Remote
git branch -a           # All

# Delete branches
git branch -d feature/old-feature    # Safe delete
git branch -D feature/old-feature    # Force delete
```

### Merging
```bash
# Fast-forward merge
git merge feature-branch

# No fast-forward (create merge commit)
git merge --no-ff feature-branch

# Squash merge
git merge --squash feature-branch
git commit -m "Merged feature"

# Abort merge
git merge --abort
```

### Rebasing
```bash
# Rebase onto main
git rebase main

# Interactive rebase
git rebase -i HEAD~5
git rebase -i main

# During rebase
git rebase --continue
git rebase --skip
git rebase --abort

# Rebase with autosquash
git commit --fixup HEAD
git rebase -i --autosquash main
```

### Cherry-Pick
```bash
# Pick single commit
git cherry-pick <hash>

# Pick multiple commits
git cherry-pick <hash1> <hash2>

# Pick range
git cherry-pick <start>^..<end>

# Pick without committing
git cherry-pick -n <hash>

# During conflict
git cherry-pick --continue
git cherry-pick --abort
```

### Reset
```bash
# Undo commits, keep changes staged
git reset --soft HEAD~N

# Undo commits, keep changes unstaged (default)
git reset HEAD~N
git reset --mixed HEAD~N

# Undo commits, discard changes
git reset --hard HEAD~N

# Unstage file
git reset HEAD <file>
```

### Revert
```bash
# Revert last commit
git revert HEAD

# Revert specific commit
git revert <hash>

# Revert range
git revert HEAD~3..HEAD

# Revert without committing
git revert -n <hash>

# Revert merge commit
git revert -m 1 <merge-hash>
```

### Conflicts
```bash
# During merge/rebase conflict:

# See conflicted files
git status

# Take ours (current branch)
git checkout --ours <file>

# Take theirs (incoming)
git checkout --theirs <file>

# After resolving
git add <file>
git commit  # for merge
git rebase --continue  # for rebase
```

## 🎯 Common Workflows

### Workflow 1: Feature Development
```bash
# Start feature
git checkout main
git pull
git checkout -b feature/new-feature

# Work and commit
git add .
git commit -m "Implement feature"

# Keep up to date
git fetch origin
git rebase origin/main

# Or merge
git merge origin/main

# When done, push
git push -u origin feature/new-feature
```

### Workflow 2: Clean Up Before PR
```bash
# Clean up commits
git rebase -i main

# Squash, reorder, reword as needed
# Force push feature branch (safe)
git push --force-with-lease
```

### Workflow 3: Hotfix
```bash
# Create hotfix
git checkout main
git checkout -b hotfix/critical-bug

# Fix and commit
git add .
git commit -m "HOTFIX: Fix critical bug"

# Merge to main
git checkout main
git merge hotfix/critical-bug

# Cherry-pick to release branches
git checkout release/v1.0
git cherry-pick <hotfix-hash>
```

### Workflow 4: Context Switching
```bash
# Save current work
git stash save "WIP: Feature A"

# Work on urgent task
git checkout -b hotfix/urgent
# ... fix ...
git commit -m "Fix urgent issue"

# Back to original work
git checkout feature/A
git stash pop
```

## 📊 Comparison Tables

### Reset Modes
| Mode | Commits | Staging Area | Working Directory |
|------|---------|--------------|-------------------|
| --soft | Reset | Unchanged | Unchanged |
| --mixed | Reset | Reset | Unchanged |
| --hard | Reset | Reset | Reset |

### Merge vs Rebase
| Aspect | Merge | Rebase |
|--------|-------|--------|
| History | Preserves branches | Linear |
| Commits | Creates merge commit | Rewrites commits |
| Safety | Safe for public branches | Dangerous on public branches |
| Use When | Multiple collaborators | Clean history desired |

### Reset vs Revert
| Aspect | Reset | Revert |
|--------|-------|--------|
| History | Rewrites | Adds new commit |
| Safety | Dangerous on public | Safe on public |
| Visibility | Commits disappear | Commits visible |
| Use When | Local only | Shared branches |

## 🛠️ Troubleshooting

### "I committed to the wrong branch"
```bash
# On wrong branch
git log --oneline -1  # Note the hash

# Switch to correct branch
git checkout correct-branch
git cherry-pick <hash>

# Go back and remove from wrong branch
git checkout wrong-branch
git reset --hard HEAD~1
```

### "I need to undo my last commit"
```bash
# Keep changes
git reset --soft HEAD~1

# Discard changes
git reset --hard HEAD~1

# Already pushed? Use revert
git revert HEAD
```

### "I lost my commits!"
```bash
# Check reflog
git reflog

# Find your commit
# abc123 HEAD@{2}: commit: My lost work

# Recover it
git reset --hard abc123
```

### "I have merge conflicts"
```bash
# See what's conflicted
git status

# Edit conflicted files (remove markers)
# Then mark resolved
git add <file>

# Complete the merge/rebase
git commit  # for merge
git rebase --continue  # for rebase
```

### "I want to undo a merge"
```bash
# If not pushed yet
git reset --hard HEAD~1

# If already pushed
git revert -m 1 HEAD
```

### "My rebase is a mess"
```bash
# Just abort it
git rebase --abort

# Start over, maybe use merge instead
git merge main
```

## 🎓 Best Practices

### Commit Messages
```bash
# Good format:
# <type>: <subject>
# 
# <body>
# 
# <footer>

# Examples:
git commit -m "feat: Add customer search functionality"
git commit -m "fix: Resolve SQL injection in login"
git commit -m "perf: Add index on Orders.CustomerId"
git commit -m "docs: Update API documentation"

# Types: feat, fix, perf, refactor, test, docs, chore
```

### When to Use What

**Stash:**
- ✅ Quick context switch
- ✅ Want to pull latest changes
- ✅ Experiment with clean state

**Reset:**
- ✅ Local commits not pushed
- ✅ Want to redo commits
- ✅ Cleaning up history

**Revert:**
- ✅ Commits already pushed
- ✅ Shared branches
- ✅ Want audit trail

**Rebase:**
- ✅ Clean history
- ✅ Feature branches
- ✅ Before pull request

**Merge:**
- ✅ Preserve history
- ✅ Multiple collaborators
- ✅ Main branch

**Cherry-pick:**
- ✅ Selective commits
- ✅ Hotfixes to multiple branches
- ✅ Move commits between branches

## 🔐 Safety Tips

1. **Never force push to main/master**
2. **Never rebase public branches**
3. **Always pull before push**
4. **Use `--force-with-lease` instead of `--force`**
5. **Check `git status` frequently**
6. **Use `git diff` before committing**
7. **Keep commits small and focused**
8. **Write descriptive commit messages**

## 🚨 Emergency Commands

```bash
# Undo everything, back to last commit
git reset --hard HEAD

# Undo everything, back to remote state
git reset --hard origin/main

# Discard changes to specific file
git checkout HEAD -- <file>

# Abort any operation
git merge --abort
git rebase --abort
git cherry-pick --abort

# See what would be deleted
git clean -n

# Delete untracked files (careful!)
git clean -f
```

## 📚 Additional Resources

- **Git Documentation:** https://git-scm.com/doc
- **Pro Git Book:** https://git-scm.com/book
- **Git Cheat Sheet:** https://training.github.com/downloads/github-git-cheat-sheet/
- **Visual Git:** https://git-school.github.io/visualizing-git/

## 💡 Pro Tips

```bash
# See what changed between branches
git diff main..feature-branch

# See who modified each line
git blame <file>

# Search for code in history
git log -S "search term" --source --all

# Create alias
git config --global alias.lg "log --oneline --graph --all"

# See branches merged to main
git branch --merged main

# See branches not merged to main
git branch --no-merged main

# Temporarily switch to a commit
git checkout <hash>
# Switch back
git checkout -

# Create branch from specific commit
git branch feature-name <hash>
```

Happy Git-ing! 🎉

