# Git for DBAs - Hands-On Learning

Welcome! This repository contains practical exercises to master advanced Git concepts using SQL Server scenarios.

## 🎯 What You'll Learn

### Core Lessons (1-7)
1. **Git Stash** - Temporarily save work without committing (+ Advanced stash techniques)
2. **Merge Conflicts** - Resolve conflicts like a pro (+ Visual merge tools)
3. **Git Rebase** - Clean up commit history and integrate changes
4. **Interactive Rebase** - Edit, reorder, and clean commit history
5. **Merge Strategies** - Fast-forward, squash, and no-ff merges
6. **Cherry-Pick** - Selectively apply commits
7. **Reset vs Revert** - Undo changes safely

### Advanced Lessons (8-10)
8. **Git Bisect** - Find bugs using binary search
9. **Git Hooks** - Automate validation and workflows
10. **Advanced Recovery** - Reflog, filter-repo, and rescue techniques

## 📚 Lessons Overview

Each lesson is self-contained with:
- **Concept explanation**
- **Real-world DBA scenario**
- **Step-by-step exercises**
- **Common pitfalls and tips**

## 🚀 Getting Started

The lessons are designed to be followed in order, but you can jump to specific topics:

### Core Lessons
1. [Lesson 1: Git Stash](./lessons/01-git-stash.md) - Save work in progress + Advanced stashing
2. [Lesson 2: Merge Conflicts](./lessons/02-merge-conflicts.md) - Resolve conflicts + Merge tools
3. [Lesson 3: Git Rebase](./lessons/03-git-rebase.md) - Linear history
4. [Lesson 4: Interactive Rebase](./lessons/04-interactive-rebase.md) - Edit history
5. [Lesson 5: Merge Strategies](./lessons/05-merge-strategies.md) - Squash & Fast-forward
6. [Lesson 6: Cherry-Pick](./lessons/06-cherry-pick.md) - Selective commits
7. [Lesson 7: Reset vs Revert](./lessons/07-reset-revert.md) - Undo changes

### Advanced Lessons
8. [Lesson 8: Git Bisect](./lessons/08-git-bisect.md) - Debug with binary search
9. [Lesson 9: Git Hooks](./lessons/09-git-hooks.md) - Automate your workflow
10. [Lesson 10: Advanced Recovery](./lessons/10-advanced-recovery.md) - Rescue lost work

### Additional Resources
- [Merge Tools Guide](./docs/MERGE-TOOLS.md) - Visual merge tool setup (VS Code, Beyond Compare, etc.)
- [Git Worktrees](./docs/GIT-WORKTREES.md) - Work on multiple branches simultaneously
- [Team Collaboration Scenarios](./exercises/TEAM-COLLABORATION.md) - Multi-developer workflows

## 💡 Tips for Learning

- **Practice each exercise** - Don't just read, do it!
- **Make mistakes** - They're the best teachers
- **Experiment** - Try variations of commands
- **Use `git log --graph`** - Visualize your history often

## 🗂️ Repository Structure

```
git-for-dba/
├── lessons/          # Step-by-step lesson guides (1-10)
├── database/         # SQL files to work with
├── scripts/          # Helper scripts (git-aliases.sh)
├── exercises/        # Practice scenarios + team collaboration
├── docs/             # Additional guides (merge tools, worktrees)
├── README.md         # This file
├── GETTING-STARTED.md
├── GIT-WORKFLOW.md
├── QUICK-REFERENCE.md
├── TROUBLESHOOTING.md
└── CLAUDE.md         # Guide for Claude Code AI assistant
```

## 🆘 Quick Reference

```bash
# View commit history with graph
git log --oneline --graph --all --decorate

# Check current status
git status

# See what branch you're on
git branch

# Undo last commit (keep changes)
git reset --soft HEAD~1

# View stashed items
git stash list
```

Let's get started! Open [Lesson 1: Git Stash](./lessons/01-git-stash.md) to begin.

