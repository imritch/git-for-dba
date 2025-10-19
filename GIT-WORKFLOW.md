# Git Workflows for DBAs

Visual guides and recommended workflows for database development with Git.

## 🔄 Basic Feature Development Workflow

```
                    Start Here
                        ↓
    ┌──────────────────────────────────────┐
    │  git checkout main                   │
    │  git pull origin main                │
    └──────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────┐
    │  git checkout -b feature/new-feature │
    └──────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────┐
    │  Make changes to SQL files           │
    │  Test your changes                   │
    └──────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────┐
    │  git add .                           │
    │  git commit -m "Descriptive message" │
    └──────────────────────────────────────┘
                        ↓
            ┌───────────────────┐
            │ More changes      │ ←────┐
            │ needed?           │      │
            └───────────────────┘      │
              │ Yes          │ No      │
              └──────────────┘         │
                     │                 │
                     └─────────────────┘
                             ↓
    ┌──────────────────────────────────────┐
    │  git checkout main                   │
    │  git pull origin main                │
    └──────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────┐
    │  git checkout feature/new-feature    │
    │  git rebase main (or merge main)     │
    └──────────────────────────────────────┘
                        ↓
            ┌───────────────────┐
            │ Conflicts?        │
            └───────────────────┘
              │ Yes          │ No
              ↓              ↓
    ┌──────────────────┐    │
    │ Resolve conflicts│    │
    │ git add .        │    │
    │ git rebase --cont│    │
    └──────────────────┘    │
              ↓              │
              └──────────────┘
                     ↓
    ┌──────────────────────────────────────┐
    │  git push origin feature/new-feature │
    └──────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────┐
    │  Create Pull Request                 │
    │  Code Review                         │
    └──────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────┐
    │  Merge to main (via PR)              │
    └──────────────────────────────────────┘
```

## 🔥 Hotfix Workflow

```
    Production Bug Discovered!
              ↓
┌──────────────────────────────┐
│  git checkout main           │
│  git pull origin main        │
└──────────────────────────────┘
              ↓
┌──────────────────────────────┐
│  git checkout -b hotfix/bug  │
└──────────────────────────────┘
              ↓
┌──────────────────────────────┐
│  Fix the bug                 │
│  Test thoroughly             │
└──────────────────────────────┘
              ↓
┌──────────────────────────────┐
│  git commit -m "HOTFIX: ..." │
└──────────────────────────────┘
              ↓
┌──────────────────────────────┐
│  git checkout main           │
│  git merge hotfix/bug        │
│  git push origin main        │
└──────────────────────────────┘
              ↓
    ┌─────────────────────┐
    │ Need to apply to    │
    │ release branches?   │
    └─────────────────────┘
         │ Yes      │ No
         ↓          ↓
    Apply via       Done!
    cherry-pick
         ↓
┌──────────────────────────────┐
│  git checkout release/v1.0   │
│  git cherry-pick <hash>      │
│  git push origin release/v1.0│
└──────────────────────────────┘
```

## 📊 Branching Strategy for Database Development

```
main (production)
├── develop (integration)
│   ├── feature/new-tables
│   ├── feature/new-indexes
│   ├── feature/new-stored-procs
│   └── feature/refactor-queries
├── release/v1.0
├── release/v2.0
├── hotfix/critical-bug
└── hotfix/security-fix
```

### Branch Types

| Branch | Purpose | Lifetime | Can Merge To |
|--------|---------|----------|--------------|
| **main** | Production | Forever | release/* |
| **develop** | Integration | Forever | main, release/* |
| **feature/** | New features | Temporary | develop |
| **hotfix/** | Urgent fixes | Temporary | main, develop, release/* |
| **release/** | Release versions | Long-term | main (via hotfix) |

## 🎯 Decision Trees

### "Should I use merge or rebase?"

```
Do you need to integrate changes?
        ↓
Is this a public/shared branch?
        ↓
    Yes → Use MERGE
        git merge other-branch
        
    No → Is clean history important?
        ↓
    Yes → Use REBASE
        git rebase other-branch
        
    No → Use MERGE
        git merge other-branch
```

### "How should I undo this commit?"

```
Need to undo a commit?
        ↓
Is it pushed to remote?
        ↓
    Yes → Use REVERT
        git revert <hash>
        
    No → Do you want to keep changes?
        ↓
    Yes → Use RESET --soft
        git reset --soft HEAD~1
        
    No → Use RESET --hard
        git reset --hard HEAD~1
```

### "How should I clean up my commits?"

```
Multiple messy commits to clean up?
        ↓
Are they pushed to remote?
        ↓
    Yes → Is this your branch only?
        ↓
    Yes → Interactive rebase + force push
        git rebase -i origin/main
        git push --force-with-lease
        
    No → Leave as is or discuss with team
        
    No (not pushed) → Interactive rebase
        git rebase -i main
```

## 🔀 Merge Strategies for Different Scenarios

### Scenario 1: Small Feature (1-3 commits)

**Recommendation:** Fast-forward merge

```bash
git checkout main
git merge feature/small-change
# Results in clean linear history
```

```
Before:                After:
A---B---C  main       A---B---C---D---E  main
     \                
      D---E  feature   
```

### Scenario 2: Large Feature (10+ commits)

**Recommendation:** Squash merge

```bash
git checkout main
git merge --squash feature/large-feature
git commit -m "Add customer management system

- Add Customer table with audit columns
- Add indexes for performance  
- Add CRUD stored procedures
- Add data validation triggers"
```

```
Before:                       After:
A---B  main                  A---B---S  main
 \                            
  C-D-E-F-G-H-I-J  feature   (S = single squashed commit)
```

### Scenario 3: Long-Running Feature Branch

**Recommendation:** No-FF merge (preserve history)

```bash
git checkout main
git merge --no-ff feature/complex-system
```

```
Before:                After:
A---B---C  main       A---B---C------M  main
     \                     \        /
      D---E---F  feature    D---E--F
```

## 📅 Daily Workflow Examples

### Morning Routine

```bash
# 1. Update your local repository
git checkout main
git pull origin main

# 2. Update your feature branch
git checkout feature/my-work
git rebase main  # or: git merge main

# 3. View what you worked on yesterday
git log --since="1 day ago" --oneline

# 4. Continue working
```

### Before Lunch (Save Progress)

```bash
# Save work in progress
git add .
git commit -m "WIP: Customer search - in progress"

# Or stash if not ready to commit
git stash save "Customer search - half done"
```

### End of Day

```bash
# Commit your work
git add .
git commit -m "Add customer search functionality"

# Push to backup (even if not complete)
git push origin feature/my-work
```

### Before Pull Request

```bash
# 1. Update from main
git fetch origin
git rebase origin/main

# 2. Clean up commits
git rebase -i origin/main
# Squash, reorder, reword as needed

# 3. Force push cleaned branch
git push --force-with-lease origin feature/my-work

# 4. Create pull request
```

## 🎭 Role-Based Workflows

### Solo DBA

```bash
# Simple workflow for personal projects
main (your production)
└── feature/* (your features)

# Workflow:
1. Create feature branch
2. Work and commit
3. Merge to main (can use fast-forward)
4. Delete feature branch
```

### Small Team (2-5 DBAs)

```bash
# Shared repository workflow
main (production)
├── develop (shared integration)
└── feature/* (individual work)

# Workflow:
1. Create feature from develop
2. Work and commit locally
3. Merge feature to develop
4. Test on develop
5. Merge develop to main for releases
```

### Large Team (6+ DBAs)

```bash
# Git flow with code review
main (production)
├── develop (integration)
├── release/* (version branches)
├── feature/* (new features)
└── hotfix/* (urgent fixes)

# Workflow:
1. Create feature from develop
2. Work and commit
3. Rebase/update from develop regularly
4. Push and create Pull Request
5. Code review
6. Merge to develop
7. Release branches from develop
8. Hotfixes cherry-picked to multiple branches
```

## 🗂️ File Organization Strategies

### Strategy 1: By Object Type

```
database/
├── tables/
│   ├── Customers.sql
│   ├── Orders.sql
│   └── Products.sql
├── indexes/
│   ├── IX_Customers.sql
│   └── IX_Orders.sql
├── stored-procedures/
│   ├── GetCustomers.sql
│   └── ProcessOrders.sql
└── views/
    └── CustomerOrders.sql
```

### Strategy 2: By Schema/Module

```
database/
├── customer-module/
│   ├── tables.sql
│   ├── indexes.sql
│   └── procedures.sql
├── order-module/
│   ├── tables.sql
│   ├── indexes.sql
│   └── procedures.sql
└── shared/
    └── common-functions.sql
```

### Strategy 3: Migration-Based

```
database/
├── migrations/
│   ├── 001_initial_schema.sql
│   ├── 002_add_indexes.sql
│   ├── 003_add_procedures.sql
│   └── 004_add_audit_columns.sql
└── rollbacks/
    ├── 004_rollback.sql
    └── 003_rollback.sql
```

## 🔄 Integration with CI/CD

```
Developer commits
       ↓
Git Push to feature branch
       ↓
Automated tests run
       ↓
    Pass? ──→ No ──→ Fix and commit
       │
      Yes
       ↓
Create Pull Request
       ↓
Code Review
       ↓
Approved?
       │
      Yes
       ↓
Merge to develop
       ↓
Automated deployment to DEV
       ↓
Integration tests
       ↓
    Pass?
       │
      Yes
       ↓
Merge to main
       ↓
Automated deployment to STAGING
       ↓
Manual approval
       ↓
Deployment to PRODUCTION
```

## 📝 Commit Message Templates

### Template 1: Conventional Commits

```
<type>: <short summary>

<body - optional>

<footer - optional>

Types:
- feat: New feature
- fix: Bug fix
- perf: Performance improvement
- refactor: Code refactoring
- docs: Documentation
- test: Tests
- chore: Maintenance

Example:
feat: Add customer search procedure

- Implements full-text search on customer names
- Includes pagination support
- Optimized with proper indexes

Closes #123
```

### Template 2: Database-Specific

```
[TYPE] Object: Description

Details:
- Change 1
- Change 2

Impact: [LOW/MEDIUM/HIGH]
Rollback: [Script location or description]

Types:
- [TABLE] - Table changes
- [INDEX] - Index changes
- [PROC] - Stored procedure changes
- [VIEW] - View changes
- [TRIG] - Trigger changes
- [FIX] - Bug fix
- [PERF] - Performance improvement

Example:
[TABLE] Customers: Add loyalty program fields

Details:
- Add LoyaltyPoints INT column
- Add LoyaltyTier VARCHAR(20) column
- Add default values

Impact: LOW
Rollback: migrations/rollback_003.sql
```

## 🎓 Best Practices Summary

1. **Branch frequently** - Create branches for features, not just for releases
2. **Commit often** - Small, focused commits are better than large ones
3. **Write good messages** - Future you will thank present you
4. **Keep main stable** - Only merge tested, working code
5. **Rebase before PR** - Clean history makes reviews easier
6. **Test before merge** - Run scripts in test environment
7. **Document migrations** - Keep track of schema changes
8. **Use tags for releases** - Mark production deployments
9. **Review before push** - Check `git diff` before committing
10. **Communicate** - Tell team about major changes

## 📚 Next Steps

- Choose a workflow that fits your team size
- Set up branch protection rules
- Configure CI/CD for automated testing
- Establish code review processes
- Document your team's Git conventions

Happy collaborating! 🚀

