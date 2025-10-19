# Git for DBAs - Hands-On Learning

Welcome! This repository contains practical exercises to master advanced Git concepts using SQL Server scenarios.

## 🎯 What You'll Learn

1. **Git Stash** - Temporarily save work without committing
2. **Git Rebase** - Clean up commit history and integrate changes
3. **Merge Conflicts** - Resolve conflicts like a pro
4. **Git Squash** - Combine multiple commits into one
5. **Fast-Forward Merge** - Understand merge strategies
6. **Cherry-Pick** - Selectively apply commits
7. **Interactive Rebase** - Edit, reorder, and clean commit history
8. **Reset vs Revert** - Undo changes safely

## 📚 Lessons Overview

Each lesson is self-contained with:
- **Concept explanation**
- **Real-world DBA scenario**
- **Step-by-step exercises**
- **Common pitfalls and tips**

## 🚀 Getting Started

The lessons are designed to be followed in order, but you can jump to specific topics:

1. [Lesson 1: Git Stash](./lessons/01-git-stash.md) - Save work in progress
2. [Lesson 2: Merge Conflicts](./lessons/02-merge-conflicts.md) - Resolve conflicts
3. [Lesson 3: Git Rebase](./lessons/03-git-rebase.md) - Linear history
4. [Lesson 4: Interactive Rebase](./lessons/04-interactive-rebase.md) - Edit history
5. [Lesson 5: Merge Strategies](./lessons/05-merge-strategies.md) - Squash & Fast-forward
6. [Lesson 6: Cherry-Pick](./lessons/06-cherry-pick.md) - Selective commits
7. [Lesson 7: Reset vs Revert](./lessons/07-reset-revert.md) - Undo changes

## 💡 Tips for Learning

- **Practice each exercise** - Don't just read, do it!
- **Make mistakes** - They're the best teachers
- **Experiment** - Try variations of commands
- **Use `git log --graph`** - Visualize your history often

## 🗂️ Repository Structure

```
git-for-dba/
├── lessons/          # Step-by-step lesson guides
├── database/         # SQL files to work with
├── scripts/          # Helper scripts
└── exercises/        # Practice scenarios
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

