# Getting Started - Your First Steps

Welcome! Let's get you started with practical Git exercises right away.

## ✅ Initial Setup (5 minutes)

### 1. Install Git Aliases (Optional but Recommended)

Run the provided alias script to set up helpful shortcuts:

```bash
cd /Users/riteshchawla/RC/git/git-for-dba
chmod +x scripts/git-aliases.sh
./scripts/git-aliases.sh
```

This gives you handy commands like `git lg` (pretty log), `git undo`, `git amend`, etc.

### 2. Configure Git (If not already done)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Optional: Set default editor
git config --global core.editor "code --wait"  # For VS Code
# or
git config --global core.editor "vim"  # For Vim
```

### 3. Initialize This Repository

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Check current status
git status

# Add all the learning materials
git add .
git commit -m "Initial commit: Add Git learning materials"
```

## 🎯 Your First Exercise (15 minutes)

Let's practice the basics and build up from there.

### Exercise: Create a Simple Schema with Branching

```bash
# 1. Create the initial schema
cat > database/MyFirstTable.sql << 'EOF'
-- My First Table
CREATE TABLE dbo.Employees (
    EmployeeId INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL
);
EOF

git add database/MyFirstTable.sql
git commit -m "Create Employees table"

# 2. View your commit
git log --oneline

# 3. Create a feature branch
git checkout -b feature/add-email

# 4. Add email column
cat > database/MyFirstTable.sql << 'EOF'
-- My First Table
CREATE TABLE dbo.Employees (
    EmployeeId INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100)
);
EOF

git add database/MyFirstTable.sql
git commit -m "Add Email column to Employees"

# 5. View the difference
git log --oneline --graph --all

# 6. Merge back to main
git checkout main
git merge feature/add-email

# 7. View the result
git log --oneline --graph
```

**Congratulations!** You just:
- ✅ Created a commit
- ✅ Created a feature branch
- ✅ Made changes on the branch
- ✅ Merged back to main

## 🚀 Next Steps - Choose Your Path

### Path 1: Structured Learning (Recommended for beginners)

Follow the lessons in order:

1. **[Lesson 1: Git Stash](lessons/01-git-stash.md)** - Start here!
2. [Lesson 2: Merge Conflicts](lessons/02-merge-conflicts.md)
3. [Lesson 3: Git Rebase](lessons/03-git-rebase.md)
4. [Lesson 4: Interactive Rebase](lessons/04-interactive-rebase.md)
5. [Lesson 5: Merge Strategies](lessons/05-merge-strategies.md)
6. [Lesson 6: Cherry-Pick](lessons/06-cherry-pick.md)
7. [Lesson 7: Reset vs Revert](lessons/07-reset-revert.md)

**Time estimate:** 30-45 minutes per lesson

### Path 2: Scenario-Based Learning (For hands-on learners)

Jump straight into realistic scenarios:

- Open [Practice Scenarios](exercises/PRACTICE-SCENARIOS.md)
- Pick a scenario that interests you
- Work through it
- Refer back to lessons when you need more details

### Path 3: Reference-Based Learning (For experienced users)

Use the quick reference as you work:

- Keep [Quick Reference](QUICK-REFERENCE.md) open
- Work on your own database scripts
- Look up commands as needed
- Try the examples in the reference

## 📖 Recommended Learning Order

If you're not sure where to start, follow this order:

### Week 1: Fundamentals
- **Day 1:** Review basics (add, commit, push) + Lesson 1 (Stash)
- **Day 2:** Lesson 2 (Merge Conflicts)
- **Day 3:** Practice Scenarios 1-2
- **Day 4:** Lesson 3 (Rebase)
- **Day 5:** Practice and review

### Week 2: Advanced Topics
- **Day 1:** Lesson 4 (Interactive Rebase)
- **Day 2:** Practice Scenarios 3-4
- **Day 3:** Lesson 5 (Merge Strategies)
- **Day 4:** Lesson 6 (Cherry-Pick)
- **Day 5:** Practice Scenarios 5-6

### Week 3: Mastery
- **Day 1:** Lesson 7 (Reset vs Revert)
- **Day 2:** Practice Scenarios 7-8
- **Day 3:** Challenge Scenario (Complete Database Migration)
- **Day 4:** Apply to your real work
- **Day 5:** Review and solidify

## 🎯 Quick Practice Ideas (5-10 minutes each)

### Practice 1: Stashing
```bash
# Make some changes without committing
echo "ALTER TABLE Employees ADD Phone NVARCHAR(20);" >> database/MyFirstTable.sql

# Stash them
git stash save "Adding phone number"

# Do something else
echo "-- Quick fix" > database/QuickFix.sql
git add database/QuickFix.sql
git commit -m "Quick fix"

# Get your work back
git stash pop
```

### Practice 2: Branching and Merging
```bash
# Create and work on a branch
git checkout -b feature/test
echo "-- Test" > test.sql
git add test.sql
git commit -m "Test commit"

# Merge it
git checkout main
git merge feature/test

# Clean up
git branch -d feature/test
```

### Practice 3: Viewing History
```bash
# Try different log views
git log --oneline
git log --oneline --graph --all
git log --stat
git log -p  # Shows full diff

# If you set up aliases:
git lg
git ll
```

### Practice 4: Undoing Changes
```bash
# Make a commit
echo "-- Mistake" > mistake.sql
git add mistake.sql
git commit -m "Oops"

# Undo it (local only - not pushed)
git reset --hard HEAD~1

# Check it's gone
git log --oneline
```

## 🆘 If You Get Stuck

### "I made a mistake, how do I undo it?"

```bash
# If you haven't committed: discard changes
git checkout -- <file>

# If you committed but didn't push: reset
git reset --hard HEAD~1

# If you pushed: revert
git revert HEAD

# Lost something? Check reflog
git reflog
```

### "I'm in the middle of something and confused"

```bash
# Check what's happening
git status

# See what you changed
git diff

# If merge/rebase conflict and want to abort
git merge --abort
git rebase --abort

# If totally lost, stash everything and start over
git stash
```

### "I want to see what command does before running it"

```bash
# Dry run (doesn't actually change anything)
git merge --no-commit --no-ff branch-name

# View what would happen
git log main..feature-branch  # Commits that would merge
git diff main...feature-branch  # Changes that would merge
```

## 📚 Helpful Resources

### In This Repository
- **[README.md](README.md)** - Overview
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Command cheat sheet
- **[lessons/](lessons/)** - Step-by-step lessons
- **[exercises/PRACTICE-SCENARIOS.md](exercises/PRACTICE-SCENARIOS.md)** - Realistic scenarios
- **[database/sample-schema.sql](database/sample-schema.sql)** - Sample SQL to practice with

### External Resources
- [Official Git Documentation](https://git-scm.com/doc)
- [Pro Git Book (Free)](https://git-scm.com/book/en/v2)
- [Git Visual Reference](https://marklodato.github.io/visual-git-guide/index-en.html)
- [Learn Git Branching (Interactive)](https://learngitbranching.js.org/)

## 💡 Pro Tips for DBAs

### 1. Name branches clearly
```bash
# Good branch names
git checkout -b feature/add-customer-indexes
git checkout -b hotfix/fix-deadlock
git checkout -b refactor/optimize-stored-procs
```

### 2. Write good commit messages
```bash
# Good commit message format
git commit -m "Add missing index on Orders.CustomerId

- Resolves query timeout issues on customer report
- Expected to improve query performance by 80%
- Tested on staging environment with production data sample"
```

### 3. Use branches for different database environments
```bash
# Example workflow
main             # Production schema
├─ develop       # Development schema
├─ staging       # Staging schema
└─ feature/*     # Feature branches
```

### 4. Commit migration scripts with version numbers
```bash
database/
├─ migrations/
│   ├─ 001_create_tables.sql
│   ├─ 002_add_indexes.sql
│   ├─ 003_create_stored_procs.sql
```

### 5. Use .gitignore for environment-specific files
```bash
# Create .gitignore
cat > .gitignore << 'EOF'
# Connection strings
*connection*.config
*.env

# Backup files
*.bak

# Temp files
*.tmp
~$*
EOF

git add .gitignore
git commit -m "Add .gitignore for sensitive files"
```

## ✅ Checklist: Am I Ready?

Before diving into the lessons, make sure:

- [ ] Git is installed (`git --version` works)
- [ ] Git is configured (name and email set)
- [ ] You're in the git-for-dba directory
- [ ] You've made your first commit
- [ ] You can view logs (`git log` shows commits)
- [ ] You understand basic commands (add, commit, status)

If all checked, **you're ready to start [Lesson 1](lessons/01-git-stash.md)!**

## 🎊 Final Encouragement

Git has a learning curve, but it's worth it! Here's what to remember:

1. **Make mistakes** - Git is forgiving. Most things can be undone.
2. **Practice regularly** - 15 minutes a day beats 2 hours once a week.
3. **Use it for real work** - The best way to learn is by doing.
4. **Don't memorize** - Keep the quick reference handy.
5. **Experiment** - Create a test repo and try things out.

The reflog (`git reflog`) is your safety net - you can almost always recover from mistakes!

**Ready to begin? Start with [Lesson 1: Git Stash](lessons/01-git-stash.md)**

---

Have questions? Stuck on something? That's normal! Git takes time to master, but every DBA who uses it wonders how they ever worked without it.

Happy learning! 🚀

