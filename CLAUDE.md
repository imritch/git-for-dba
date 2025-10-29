# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Git learning repository for DBAs** - a hands-on educational project that teaches advanced Git concepts (stash, rebase, merge conflicts, cherry-pick, etc.) through SQL Server database scenarios. It is NOT a production database project.

## Purpose

The repository contains:
- **Lessons**: Step-by-step tutorials on Git concepts (in `/lessons/`)
- **Practice SQL files**: Sample database objects (tables, stored procedures, indexes) in `/database/`
- **Exercises**: Realistic scenarios for practicing Git workflows
- **Documentation**: Comprehensive guides on Git workflows, troubleshooting, and quick references

The SQL files are intentionally simple examples used to demonstrate Git operations, not production-quality database code.

## Common Commands

### Working with the Learning Materials

This is a learning repository - there's no build, test, or deployment process. Students interact with it purely through Git commands:

```bash
# View the visual commit history (used throughout lessons)
git log --oneline --graph --all --decorate

# Common learning workflow
git checkout -b feature/my-practice
# ... make changes to SQL files ...
git add .
git commit -m "Practice: description"

# Practice rebasing
git rebase main

# Practice interactive rebase
git rebase -i HEAD~5
```

### Git Aliases

The repository includes a helper script for setting up useful Git aliases:

```bash
chmod +x scripts/git-aliases.sh
./scripts/git-aliases.sh
```

This creates shortcuts like `git lg` (pretty log), `git undo`, `git amend`, etc.

## Repository Structure

```
git-for-dba/
├── lessons/              # 10 step-by-step Git lessons
│   ├── 01-git-stash.md              # Basic + Advanced stash techniques
│   ├── 02-merge-conflicts.md         # Conflict resolution
│   ├── 03-git-rebase.md              # Linear history
│   ├── 04-interactive-rebase.md      # Advanced commit surgery
│   ├── 05-merge-strategies.md        # FF, squash, no-ff merges
│   ├── 06-cherry-pick.md             # Selective commits
│   ├── 07-reset-revert.md            # Undo strategies
│   ├── 08-git-bisect.md              # Binary search debugging (NEW)
│   ├── 09-git-hooks.md               # Automation workflows (NEW)
│   └── 10-advanced-recovery.md       # Reflog, filter-repo (NEW)
├── database/             # Sample SQL files for practice
│   ├── sample-schema.sql      # Base schema (Customers, Orders, Products, etc.)
│   └── *.sql                   # Various tables, procedures, indexes
├── exercises/            # Practice scenarios
│   ├── PRACTICE-SCENARIOS.md         # Individual scenarios
│   └── TEAM-COLLABORATION.md          # Team workflows (NEW)
├── docs/                 # Additional guides (NEW)
│   ├── MERGE-TOOLS.md            # Visual merge tool setup
│   └── GIT-WORKTREES.md          # Multiple branch workspaces
├── scripts/              # Helper scripts
│   └── git-aliases.sh
├── README.md             # Main overview (UPDATED)
├── GETTING-STARTED.md    # First steps for learners
├── GIT-WORKFLOW.md       # Visual workflow guides
├── QUICK-REFERENCE.md    # Command cheat sheet
├── TROUBLESHOOTING.md    # Common issues
└── CLAUDE.md             # This file
```

## Key Architecture Concepts

### Educational Design Pattern

The repository follows a **guided discovery** learning approach with progressive complexity:

1. **Lessons are sequential**:
   - **Core (1-7)**: Fundamentals every DBA needs (stash, merge, rebase, etc.)
   - **Advanced (8-10)**: Power user techniques (bisect, hooks, recovery)

2. **Scenario-based**: Every lesson presents a realistic DBA problem that requires the Git concept being taught

3. **Hands-on exercises**: Students execute actual Git commands and see results immediately

4. **SQL as the medium**: Uses familiar database concepts to teach Git (tables, stored procedures, indexes)

5. **Supplementary resources**: Additional guides for specific topics (merge tools, worktrees, team collaboration)

### Branching Strategy for Learning

The repository demonstrates various branching strategies as teaching examples:

- `main`: Represents "production" in examples
- `develop`: Used in some lessons for integration branch practice
- `feature/*`: Feature branch examples
- `hotfix/*`: Emergency fix examples
- `release/*`: Release branch examples

### Database Schema (Educational Sample)

The sample schema in `/database/sample-schema.sql` includes:

- **Customers table**: Basic customer info with email/phone
- **Orders table**: Orders with foreign key to Customers
- **Products table**: Product catalog with inventory
- **OrderDetails table**: Line items linking Orders and Products
- **Sample stored procedures**: GetCustomerOrders, GetProductInventory
- **Indexes**: Performance indexes on common lookup columns

This schema is intentionally simple and exists solely for Git learning exercises.

## Working with This Repository

### If helping a student learn Git:

1. **Core lessons first (01-07)**: Essential Git skills every DBA needs
2. **Advanced lessons (08-10)**: For users wanting to master Git
3. **Supplementary resources**: Point to docs/ for specific topics:
   - Struggling with merge conflicts? → docs/MERGE-TOOLS.md
   - Need to work on multiple branches? → docs/GIT-WORKTREES.md
   - Working in a team? → exercises/TEAM-COLLABORATION.md
4. Encourage use of `git log --oneline --graph --all` to visualize changes
5. Point to QUICK-REFERENCE.md for command syntax
6. Reference TROUBLESHOOTING.md when students get stuck
7. The SQL files are just examples - focus on Git concepts, not SQL quality

### If modifying the learning materials:

1. Keep SQL examples simple and relatable to DBAs
2. Test all exercise instructions before committing
3. Maintain the existing lesson numbering and structure (01-10)
4. New advanced topics → Create new lessons (11+) or add to docs/
5. Updates to existing concepts → Enhance existing lessons
6. Update QUICK-REFERENCE.md if introducing new Git commands
7. Ensure all paths in documentation match actual file locations
8. Update README.md if adding new lessons or resources

### If creating new exercises:

1. Follow the established pattern: Problem → Concept → Exercise → Solution
2. Use realistic DBA scenarios (e.g., hotfixes, schema changes, concurrent work)
3. Include specific Git commands students should run
4. Add visual diagrams where helpful (ASCII art is fine)
5. Test the exercise flow completely before adding to repository

## Important Notes

- **This is NOT production code**: The SQL files are intentionally simplified for teaching
- **Git history is part of the lesson**: Don't rewrite history that's used in examples
- **Commits are learning artifacts**: Some commits may look "wrong" (e.g., incomplete work) because they demonstrate specific Git concepts
- **Branch cleanup**: Feature branches from exercises can be deleted after merging
- **Safe experimentation**: Students are encouraged to make mistakes - it's a learning environment

## Commit Message Style

Based on the repository history, commit messages follow a simple descriptive format:

```
Add [object type] [object name]
Fix [description]
Update [what was changed]
```

Examples from history:
- "Add ProcessOrders SP"
- "Add Index1"
- "Add NewTable"
- "Used git rebase to amend the file as per discussed changes"

Keep messages concise and focused on what changed, as this is primarily a learning repository.

## Workflow Examples for Common Tasks

### Creating a new lesson:

```bash
git checkout main
git checkout -b feature/lesson-08-advanced-topic
# Create lessons/08-advanced-topic.md
git add lessons/08-advanced-topic.md
git commit -m "Add Lesson 8: Advanced Topic"
git checkout main
git merge feature/lesson-08-advanced-topic
```

### Adding practice SQL files:

```bash
# Add files to database/ directory
git add database/NewProcedure.sql
git commit -m "Add NewProcedure SP for Lesson 4 exercise"
```

### Updating documentation:

```bash
git add QUICK-REFERENCE.md
git commit -m "Update QUICK-REFERENCE with new examples"
```

## Visual Workflow Reference

The GIT-WORKFLOW.md file contains extensive ASCII diagrams showing:
- Feature development workflow
- Hotfix workflow
- Branching strategies (solo DBA, small team, large team)
- Decision trees (merge vs rebase, reset vs revert)
- Merge strategies for different scenarios
- Daily workflow routines

Reference these diagrams when explaining Git concepts to students or creating new lessons.

## Recent Enhancements (2024)

The repository has been significantly enhanced with:

### New Lessons (8-10)
- **Lesson 8: Git Bisect** - Binary search debugging for finding which commit introduced a bug
- **Lesson 9: Git Hooks** - Automation (pre-commit validation, SQL syntax checking, credential scanning)
- **Lesson 10: Advanced Recovery** - Reflog, filter-repo, recovering lost commits

### Enhanced Existing Lessons
- **Lesson 1**: Added advanced stash techniques (partial stashing with -p, recovering dropped stashes, stash vs WIP commits)
- **Lesson 2**: Now references merge tools guide

### New Supplementary Resources
- **docs/MERGE-TOOLS.md**: Complete guide to visual merge tools (VS Code, Beyond Compare, KDiff3, P4Merge, vimdiff) with setup and usage
- **docs/GIT-WORKTREES.md**: Work on multiple branches simultaneously without stashing
- **exercises/TEAM-COLLABORATION.md**: 6 realistic team scenarios (parallel development, code reviews, hotfixes, merge trains, shared branches)

### Content Coverage
The repository now comprehensively covers:
- ✅ All core Git concepts for DBAs
- ✅ Advanced debugging techniques (bisect)
- ✅ Automation and quality control (hooks)
- ✅ Disaster recovery (reflog, filter-repo)
- ✅ Team collaboration workflows
- ✅ Modern tooling (visual merge tools, worktrees)
- ✅ Real-world scenarios and best practices

**Completeness**: The repository is now a comprehensive Git training program for DBAs, covering beginner through advanced topics with practical, hands-on exercises.
