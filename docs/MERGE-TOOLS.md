# Merge Tools Guide for DBAs

## 🎯 Overview

While you can resolve merge conflicts manually in a text editor, visual merge tools make the process much faster and less error-prone, especially for complex SQL files.

This guide covers setting up and using popular merge tools with Git.

## 🛠️ Popular Merge Tools

| Tool | Type | Best For | Cost |
|------|------|----------|------|
| **VS Code** | Editor | Quick conflicts, SQL syntax highlighting | Free |
| **Beyond Compare** | Dedicated | Complex 3-way merges, directory comparison | Paid |
| **KDiff3** | Dedicated | Free alternative to Beyond Compare | Free |
| **P4Merge** | Dedicated | Visual 3-way merge, clean interface | Free |
| **Meld** | Dedicated | Linux/Mac users, simple UI | Free |
| **Vim/Neovim (vimdiff)** | Editor | Terminal users, SSH scenarios | Free |

## 📝 Setup: VS Code (Recommended for Most Users)

### Why VS Code?
- ✅ You probably already have it
- ✅ Excellent SQL syntax highlighting
- ✅ Built-in 3-way merge view
- ✅ Git integration
- ✅ Free and cross-platform

### Configuration

```bash
# Set VS Code as your default merge tool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'

# For merge conflicts specifically
git config --global mergetool.vscode.cmd 'code --wait --merge $REMOTE $LOCAL $BASE $MERGED'

# Don't create .orig backup files
git config --global mergetool.keepBackup false

# Trust VS Code's exit code
git config --global mergetool.vscode.trustExitCode false
```

### Usage

```bash
# When you have merge conflicts
git merge feature-branch
# CONFLICT in database/GetCustomers.sql

# Launch VS Code merge tool
git mergetool

# VS Code opens with 4-pane view:
# - Current Change (HEAD)
# - Incoming Change (feature-branch)
# - Result (what will be saved)
# - Base (common ancestor)

# Use buttons or manually edit the Result pane
# Save and close VS Code when done

# Complete the merge
git commit
```

## 📝 Setup: Beyond Compare (Professional Tool)

### Why Beyond Compare?
- ✅ Most powerful for complex merges
- ✅ Directory comparison
- ✅ Best for large SQL files
- ✅ Table view for structured data

### Configuration

```bash
# Windows
git config --global merge.tool bc
git config --global mergetool.bc.path "C:/Program Files/Beyond Compare 4/BComp.exe"

# Mac
git config --global merge.tool bc
git config --global mergetool.bc.path "/Applications/Beyond Compare.app/Contents/MacOS/bcomp"

# Linux
git config --global merge.tool bc
git config --global mergetool.bc.path "/usr/bin/bcomp"

# Configuration
git config --global mergetool.bc.trustExitCode true
git config --global mergetool.keepBackup false
```

### Usage

```bash
# Launch Beyond Compare for conflicts
git mergetool

# Beyond Compare shows:
# - Left: Your version (HEAD)
# - Center: Base (common ancestor)
# - Right: Their version (incoming)
# - Bottom: Result (output)

# Click sections to accept changes
# Or manually edit the result
# Save and exit when done
```

## 📝 Setup: KDiff3 (Free Alternative)

### Why KDiff3?
- ✅ Completely free
- ✅ Similar to Beyond Compare
- ✅ Good for complex 3-way merges
- ✅ Cross-platform

### Configuration

```bash
# Install KDiff3 first
# Windows: Download from kdiff3.sourceforge.net
# Mac: brew install kdiff3
# Linux: sudo apt install kdiff3

# Configure Git
git config --global merge.tool kdiff3
git config --global mergetool.kdiff3.path "/usr/bin/kdiff3"  # Adjust path
git config --global mergetool.kdiff3.trustExitCode false
git config --global mergetool.keepBackup false
```

### Usage

```bash
git mergetool

# KDiff3 shows 3 panes at top:
# - A: Base (common ancestor)
# - B: Local (your changes)
# - C: Remote (their changes)
#
# Bottom pane: Result (editable)

# Click buttons to accept changes:
# - A: Take base version
# - B: Take your version
# - C: Take their version
# - Or manually edit result

# Save and exit
```

## 📝 Setup: P4Merge (Perforce)

### Configuration

```bash
# Install P4Merge from perforce.com

# Windows
git config --global merge.tool p4merge
git config --global mergetool.p4merge.path "C:/Program Files/Perforce/p4merge.exe"

# Mac
git config --global merge.tool p4merge
git config --global mergetool.p4merge.path "/Applications/p4merge.app/Contents/MacOS/p4merge"

# Configuration
git config --global mergetool.p4merge.trustExitCode false
git config --global mergetool.keepBackup false
```

## 📝 Setup: Vimdiff (Terminal Users)

### Configuration

```bash
# For vim users
git config --global merge.tool vimdiff
git config --global mergetool.vimdiff.cmd 'nvim -d $LOCAL $REMOTE $MERGED -c '\''wincmd w'\'' -c '\''wincmd J'\'''

# Don't create backups
git config --global mergetool.keepBackup false
```

### Usage

```bash
git mergetool

# Vim opens with 3-way split:
# - Top left: LOCAL (your version)
# - Top middle: BASE (common ancestor)
# - Top right: REMOTE (their version)
# - Bottom: MERGED (result - this is what you edit)

# Vim commands:
# :diffget LOCAL   - Get from local
# :diffget REMOTE  - Get from remote
# :diffget BASE    - Get from base
# ]c               - Next conflict
# [c               - Previous conflict
# :wqa             - Write and quit all
```

## 🎯 Real-World DBA Scenarios

### Scenario 1: Stored Procedure Conflict

Two developers modified the same stored procedure.

```bash
# Merge causes conflict
git merge feature/add-logging
# CONFLICT in database/GetTopCustomers.sql

# Open merge tool
git mergetool

# You see:
# LEFT (yours):
CREATE PROCEDURE dbo.GetTopCustomers
    @TopN INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    -- You added: Better performance with CTE
    WITH TopCustomers AS (
        SELECT TOP (@TopN)
            CustomerId,
            CustomerName,
            TotalPurchases
        FROM Customers
        ORDER BY TotalPurchases DESC
    )
    SELECT * FROM TopCustomers;
END

# RIGHT (theirs):
CREATE PROCEDURE dbo.GetTopCustomers
    @TopN INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    -- They added: Error handling
    BEGIN TRY
        SELECT TOP (@TopN)
            CustomerId,
            CustomerName,
            TotalPurchases
        FROM Customers
        ORDER BY TotalPurchases DESC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END

# RESULT (combine both):
CREATE PROCEDURE dbo.GetTopCustomers
    @TopN INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        WITH TopCustomers AS (
            SELECT TOP (@TopN)
                CustomerId,
                CustomerName,
                TotalPurchases
            FROM Customers
            ORDER BY TotalPurchases DESC
        )
        SELECT * FROM TopCustomers;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
```

### Scenario 2: Schema Migration Conflict

```bash
# Two migration scripts modified same table
git mergetool database/migrations/003_alter_customers.sql

# Visual tool makes it easy to see:
# - You added: Email column
# - They added: Phone column
# - Result: Add both columns in correct order
```

### Scenario 3: Index Definition Conflict

```bash
# Conflicting index definitions
git mergetool database/indexes/IX_Customers.sql

# LEFT (yours): Index on Email
# RIGHT (theirs): Index on Phone
# RESULT: Create both indexes (rename appropriately)
```

## 💡 Best Practices

### 1. Always Review the Base

```bash
# Before resolving, understand what changed
git show :1:database/file.sql  # Base version
git show :2:database/file.sql  # Your version
git show :3:database/file.sql  # Their version
```

### 2. Test After Merging

```bash
# After resolving conflicts
git mergetool
git commit

# Test the SQL
sqlcmd -S localhost -d TestDB -i database/ResolvedProc.sql

# If issues found, amend the commit
git add database/ResolvedProc.sql
git commit --amend
```

### 3. Use Syntax Highlighting

All GUI merge tools provide syntax highlighting, but configure for SQL:

**VS Code:** Already supports SQL
**Beyond Compare:** File → File Formats → SQL

### 4. Create Merge Tool Aliases

```bash
# Quick launch aliases
git config --global alias.mt mergetool
git config --global alias.dt difftool

# Now use:
git mt   # Instead of git mergetool
git dt   # Instead of git difftool
```

### 5. Compare Specific Files

```bash
# Use difftool to compare specific files before merging
git difftool main feature-branch -- database/GetCustomers.sql

# Compare current version with specific commit
git difftool HEAD~1 HEAD -- database/GetCustomers.sql
```

## 🔧 Advanced Configuration

### Auto-Merge Simple Conflicts

```bash
# Let Git auto-resolve simple conflicts
git config --global merge.conflictStyle diff3

# This shows:
# <<<<<<< HEAD
# Your changes
# ||||||| BASE
# Original version
# =======
# Their changes
# >>>>>>> feature-branch

# Easier to understand what changed
```

### Configure Per-Project

```bash
# In your repo
cd /path/to/git-for-dba

# Use different tool for this project
git config merge.tool kdiff3

# This project only setting (stored in .git/config)
```

### Custom Merge Tool

```bash
# Create custom merge tool wrapper
git config --global mergetool.mymerge.cmd '/path/to/my-merge-script.sh $BASE $LOCAL $REMOTE $MERGED'
git config --global mergetool.mymerge.trustExitCode true

# Use it
git config --global merge.tool mymerge
```

## 🎓 Merge Tool Comparison for SQL Files

| Feature | VS Code | Beyond Compare | KDiff3 | P4Merge | vimdiff |
|---------|---------|----------------|---------|---------|---------|
| **SQL Syntax** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **3-Way Merge** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Performance** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Cost** | Free | $30-60 | Free | Free | Free |
| **Best For** | Most DBAs | Professionals | Budget-conscious | Visual learners | Terminal users |

## 📚 Quick Reference

```bash
# Set merge tool
git config --global merge.tool <tool-name>

# Launch merge tool for conflicts
git mergetool

# Launch diff tool to compare
git difftool

# Skip backup files
git config --global mergetool.keepBackup false

# List configured tools
git config --get merge.tool
git config --get diff.tool

# See all merge tool config
git config --global --get-regexp merge

# Abort merge if you're stuck
git merge --abort
```

## 🎊 Summary

**For most DBAs, we recommend:**
1. **Start with VS Code** - Free, familiar, great SQL support
2. **Upgrade to Beyond Compare** - If you do lots of merges professionally
3. **Learn keyboard shortcuts** - Speeds up conflict resolution 10x
4. **Practice on sample conflicts** - Get comfortable before production merges

**Key Principles:**
- Visual tools reduce errors
- 3-way merge shows context
- Always test SQL after resolving
- Don't fear conflicts - tools make them manageable

**Next:** Try resolving conflicts in [Lesson 2](../lessons/02-merge-conflicts.md) using your new merge tool!
