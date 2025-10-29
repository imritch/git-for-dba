# Lesson 9: Git Hooks - Automate Your DBA Workflow

## 🎯 What are Git Hooks?

Git hooks are scripts that Git automatically runs before or after certain events: committing, pushing, merging, etc. They let you automate quality checks, testing, and validation.

**DBA Analogy:** Like SQL Server triggers - they fire automatically when specific events occur, enforcing rules and standards without manual intervention.

## 🤔 Why Do DBAs Need Hooks?

**Scenario:** Your team keeps committing:
- SQL scripts with syntax errors
- Stored procedures without proper error handling
- Migration scripts that haven't been tested
- Connection strings with production credentials
- Uncommented schema changes

**Without hooks:**
- ❌ Issues discovered during code review (wasted time)
- ❌ Broken deployments to test environments
- ❌ Security incidents from committed secrets
- ❌ Inconsistent code formatting

**With hooks:**
- ✅ Automatic validation before commit
- ✅ Syntax checking before push
- ✅ Credential scanning
- ✅ Automated testing
- ✅ Enforced code standards

## 📚 Types of Git Hooks

### Client-Side Hooks (Local)
| Hook | When It Runs | Common Uses |
|------|--------------|-------------|
| **pre-commit** | Before commit message | Syntax check, linting, formatting |
| **prepare-commit-msg** | Before commit editor | Auto-generate commit template |
| **commit-msg** | After commit message | Validate message format |
| **post-commit** | After commit | Notifications, logging |
| **pre-push** | Before push to remote | Run tests, security scans |
| **post-checkout** | After checkout/switch | Restore DB snapshots |
| **post-merge** | After merge | Run migrations |

### Server-Side Hooks (Remote)
| Hook | When It Runs | Common Uses |
|------|--------------|-------------|
| **pre-receive** | Before accepting push | Enforce branch policies |
| **update** | Before updating ref | Per-branch validation |
| **post-receive** | After accepting push | Deploy, notify team |

## 📝 Exercise 1: Create Your First Hook - SQL Syntax Validator

### Step 1: Understand the Hooks Directory

```bash
# Navigate to your repo
cd /Users/riteshchawla/RC/git/git-for-dba

# Check if .git/hooks exists
ls -la .git/hooks/

# You'll see sample hooks (not active until you remove .sample)
# pre-commit.sample
# pre-push.sample
# etc.
```

### Step 2: Create a Pre-Commit Hook

```bash
# Create a pre-commit hook to validate SQL syntax
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook: Validate SQL files

echo "🔍 Running SQL syntax validation..."

# Find all staged SQL files
STAGED_SQL_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sql$')

if [ -z "$STAGED_SQL_FILES" ]; then
    echo "✅ No SQL files to validate"
    exit 0
fi

HAS_ERRORS=0

# Check each file
for FILE in $STAGED_SQL_FILES; do
    echo "Checking: $FILE"

    # Check 1: File is not empty
    if [ ! -s "$FILE" ]; then
        echo "  ❌ ERROR: File is empty"
        HAS_ERRORS=1
        continue
    fi

    # Check 2: Has CREATE statement
    if ! grep -qi "CREATE\|ALTER\|DROP\|INSERT\|UPDATE\|DELETE\|SELECT" "$FILE"; then
        echo "  ⚠️  WARNING: No SQL statements found"
    fi

    # Check 3: No obvious syntax errors
    # Check for unclosed quotes
    SINGLE_QUOTES=$(grep -o "'" "$FILE" | wc -l)
    if [ $((SINGLE_QUOTES % 2)) -ne 0 ]; then
        echo "  ❌ ERROR: Unclosed single quotes"
        HAS_ERRORS=1
    fi

    # Check 4: No production connection strings
    if grep -qi "production\|prod-db\|live-server" "$FILE"; then
        echo "  ❌ ERROR: Production reference found (possible connection string)"
        HAS_ERRORS=1
    fi

    # Check 5: No hardcoded passwords
    if grep -qi "password\s*=\|pwd\s*=" "$FILE"; then
        echo "  ❌ ERROR: Hardcoded password detected"
        HAS_ERRORS=1
    fi

    if [ $HAS_ERRORS -eq 0 ]; then
        echo "  ✅ $FILE passed all checks"
    fi
done

if [ $HAS_ERRORS -ne 0 ]; then
    echo ""
    echo "❌ Pre-commit validation FAILED"
    echo "Fix the errors above and try again"
    exit 1
fi

echo ""
echo "✅ All SQL files validated successfully"
exit 0
EOF

# Make it executable
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed!"
```

### Step 3: Test the Hook

```bash
# Try to commit a bad SQL file
cat > database/BadSyntax.sql << 'EOF'
-- This has a syntax error (unclosed quote)
CREATE PROCEDURE dbo.TestProc
AS
BEGIN
    SELECT 'This is unclosed
    FROM dbo.Customers;
END
EOF

git add database/BadSyntax.sql
git commit -m "Test: Bad SQL syntax"

# The hook should PREVENT the commit and show error
```

**Expected output:**
```
🔍 Running SQL syntax validation...
Checking: database/BadSyntax.sql
  ❌ ERROR: Unclosed single quotes

❌ Pre-commit validation FAILED
Fix the errors above and try again
```

### Step 4: Fix and Commit

```bash
# Fix the file
cat > database/BadSyntax.sql << 'EOF'
-- This is now correct
CREATE PROCEDURE dbo.TestProc
AS
BEGIN
    SELECT 'This is properly closed'
    FROM dbo.Customers;
END
EOF

git add database/BadSyntax.sql
git commit -m "Add TestProc with proper syntax"

# This time it should succeed!
```

## 📝 Exercise 2: Advanced Pre-Commit Hook - SQL Quality Checks

### Create a Comprehensive Quality Hook

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Advanced Pre-commit Hook: SQL Quality Checks

echo "🔍 Running SQL Quality Checks..."
echo "================================"

STAGED_SQL_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sql$')

if [ -z "$STAGED_SQL_FILES" ]; then
    echo "✅ No SQL files to validate"
    exit 0
fi

HAS_ERRORS=0
HAS_WARNINGS=0

for FILE in $STAGED_SQL_FILES; do
    echo ""
    echo "📄 Checking: $FILE"
    echo "---"

    # === CRITICAL CHECKS (will block commit) ===

    # 1. Empty file
    if [ ! -s "$FILE" ]; then
        echo "  ❌ CRITICAL: File is empty"
        HAS_ERRORS=1
        continue
    fi

    # 2. Security: No credentials
    if grep -qi "password\s*=\|pwd\s*=\|Password=[^)]" "$FILE"; then
        echo "  ❌ CRITICAL: Hardcoded password detected"
        echo "     Use Windows Auth or parameterized connection strings"
        HAS_ERRORS=1
    fi

    # 3. Security: No production references
    if grep -qi "production\|prod-db\|live-server\|server=prod" "$FILE"; then
        echo "  ❌ CRITICAL: Production server reference found"
        HAS_ERRORS=1
    fi

    # 4. Syntax: Balanced quotes
    SINGLE_QUOTES=$(grep -o "'" "$FILE" | wc -l)
    if [ $((SINGLE_QUOTES % 2)) -ne 0 ]; then
        echo "  ❌ CRITICAL: Unclosed single quotes"
        HAS_ERRORS=1
    fi

    # 5. No DROP DATABASE or TRUNCATE without WHERE in production tables
    if grep -qi "DROP\s\+DATABASE\|TRUNCATE\s\+TABLE" "$FILE"; then
        echo "  ❌ CRITICAL: Destructive operation (DROP DATABASE or TRUNCATE)"
        echo "     Use DROP TABLE or DELETE with WHERE clause"
        HAS_ERRORS=1
    fi

    # === WARNING CHECKS (best practices) ===

    # 6. Stored procedures should have error handling
    if grep -qi "CREATE\s\+PROCEDURE\|ALTER\s\+PROCEDURE" "$FILE"; then
        if ! grep -qi "TRY\|BEGIN\s\+TRY\|CATCH" "$FILE"; then
            echo "  ⚠️  WARNING: Stored procedure without error handling"
            HAS_WARNINGS=1
        fi
    fi

    # 7. Should have SET NOCOUNT ON in procedures
    if grep -qi "CREATE\s\+PROCEDURE\|ALTER\s\+PROCEDURE" "$FILE"; then
        if ! grep -qi "SET\s\+NOCOUNT\s\+ON" "$FILE"; then
            echo "  ⚠️  WARNING: Procedure without SET NOCOUNT ON"
            HAS_WARNINGS=1
        fi
    fi

    # 8. Avoid SELECT * in procedures
    if grep -qi "SELECT\s\+\*" "$FILE"; then
        echo "  ⚠️  WARNING: SELECT * found (specify columns explicitly)"
        HAS_WARNINGS=1
    fi

    # 9. Check for NOLOCK hint (often misused)
    if grep -qi "WITH\s*(NOLOCK)\|NOLOCK" "$FILE"; then
        echo "  ⚠️  WARNING: NOLOCK hint found (can cause dirty reads)"
        HAS_WARNINGS=1
    fi

    # 10. Header comments
    if ! head -5 "$FILE" | grep -qi "^--"; then
        echo "  ⚠️  WARNING: No header comments in first 5 lines"
        HAS_WARNINGS=1
    fi

    if [ $HAS_ERRORS -eq 0 ] && [ $HAS_WARNINGS -eq 0 ]; then
        echo "  ✅ All checks passed"
    fi
done

echo ""
echo "================================"

if [ $HAS_ERRORS -ne 0 ]; then
    echo "❌ COMMIT BLOCKED: Critical issues found"
    echo ""
    echo "Fix the critical errors (❌) and try again"
    echo "Warnings (⚠️) won't block commits but should be addressed"
    exit 1
fi

if [ $HAS_WARNINGS -ne 0 ]; then
    echo "⚠️  Warnings found - commit allowed but please review"
    echo ""
fi

echo "✅ All SQL quality checks passed"
exit 0
EOF

chmod +x .git/hooks/pre-commit
```

### Test the Advanced Hook

```bash
# Test 1: Good stored procedure
cat > database/GoodProc.sql << 'EOF'
-- GetActiveCustomers
-- Returns all active customers with their order count
-- Author: DBA Team
-- Date: 2024-10-28
CREATE PROCEDURE dbo.GetActiveCustomers
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            c.CustomerId,
            c.CustomerName,
            c.Email,
            COUNT(o.OrderId) AS OrderCount
        FROM dbo.Customers c
        LEFT JOIN dbo.Orders o ON c.CustomerId = o.CustomerId
        WHERE c.IsActive = 1
        GROUP BY c.CustomerId, c.CustomerName, c.Email
        ORDER BY OrderCount DESC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
EOF

git add database/GoodProc.sql
git commit -m "Add GetActiveCustomers procedure"
# Should succeed with no warnings!

# Test 2: Procedure with warnings
cat > database/ProcWithWarnings.sql << 'EOF'
CREATE PROCEDURE dbo.QuickQuery
AS
BEGIN
    SELECT * FROM dbo.Customers WITH (NOLOCK);
END
EOF

git add database/ProcWithWarnings.sql
git commit -m "Add quick query procedure"
# Should succeed but show warnings
```

## 📝 Exercise 3: Pre-Push Hook - Run Tests Before Push

### Create Pre-Push Hook

```bash
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# Pre-push hook: Run validation tests before pushing

echo "🚀 Pre-push validation starting..."
echo ""

# Get the remote and URL
remote="$1"
url="$2"

echo "Pushing to: $remote ($url)"
echo ""

# Check 1: No uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "❌ PUSH BLOCKED: You have uncommitted changes"
    echo "   Commit or stash them first"
    exit 1
fi

# Check 2: Run SQL file validation on all changed files
echo "🔍 Validating all SQL files in repository..."

ALL_SQL_FILES=$(find database -name "*.sql" 2>/dev/null)

if [ -n "$ALL_SQL_FILES" ]; then
    ERROR_COUNT=0

    for FILE in $ALL_SQL_FILES; do
        # Quick syntax check
        if [ -s "$FILE" ]; then
            # Check for common issues
            if grep -qi "DROP\s\+DATABASE" "$FILE"; then
                echo "  ❌ $FILE contains DROP DATABASE"
                ERROR_COUNT=$((ERROR_COUNT + 1))
            fi
        fi
    done

    if [ $ERROR_COUNT -gt 0 ]; then
        echo "❌ Found $ERROR_COUNT critical issues"
        exit 1
    fi

    echo "✅ All SQL files validated"
fi

# Check 3: Verify branch naming (if not main/master)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    # Check if branch follows naming convention
    if ! echo "$CURRENT_BRANCH" | grep -qE '^(feature|bugfix|hotfix|release)/'; then
        echo "⚠️  WARNING: Branch name doesn't follow convention"
        echo "   Expected: feature/*, bugfix/*, hotfix/*, or release/*"
        echo "   Got: $CURRENT_BRANCH"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Push cancelled"
            exit 1
        fi
    fi
fi

# Check 4: Verify commit messages
echo "📝 Checking commit message format..."

# Get commits being pushed
COMMITS=$(git rev-list @{u}..HEAD 2>/dev/null)

if [ -n "$COMMITS" ]; then
    for COMMIT in $COMMITS; do
        MSG=$(git log -1 --pretty=%B $COMMIT)

        # Check if message is too short
        if [ ${#MSG} -lt 10 ]; then
            echo "⚠️  WARNING: Short commit message: $MSG"
        fi
    done
fi

echo ""
echo "✅ Pre-push validation passed"
echo "🚀 Pushing to remote..."
exit 0
EOF

chmod +x .git/hooks/pre-push
```

### Test Pre-Push Hook

```bash
# Create a test branch
git checkout -b feature/test-pre-push

# Make a change
echo "-- Test" > database/TestFile.sql
git add database/TestFile.sql
git commit -m "Add test file"

# Try to push (will run pre-push hook)
# git push -u origin feature/test-pre-push
# (Don't actually push if you don't have a remote configured)

# The hook will validate everything before pushing
```

## 📝 Exercise 4: Commit Message Validation Hook

### Create Commit-Msg Hook

```bash
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash
# Commit-msg hook: Enforce commit message standards

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

echo "📝 Validating commit message..."

# Rule 1: Minimum length
if [ ${#COMMIT_MSG} -lt 10 ]; then
    echo "❌ Commit message too short (minimum 10 characters)"
    echo "Current message: $COMMIT_MSG"
    exit 1
fi

# Rule 2: Not all caps
if echo "$COMMIT_MSG" | grep -q '^[A-Z ]\+$'; then
    echo "❌ Don't use all caps in commit message"
    exit 1
fi

# Rule 3: Should start with verb or type prefix
FIRST_WORD=$(echo "$COMMIT_MSG" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')

VALID_PREFIXES="add|update|fix|remove|refactor|docs|test|feat|chore|style|perf"
VALID_VERBS="add|update|fix|remove|create|delete|modify|change|improve|optimize"

if ! echo "$FIRST_WORD" | grep -qE "^($VALID_PREFIXES|$VALID_VERBS)"; then
    if ! echo "$COMMIT_MSG" | grep -qE "^\[.*\]"; then
        echo "⚠️  WARNING: Commit message should start with:"
        echo "   - A verb (Add, Fix, Update, etc.)"
        echo "   - Or a type prefix [TABLE], [PROC], [INDEX], etc."
        echo ""
        echo "Current message: $COMMIT_MSG"
        echo ""
        # Allow but warn
    fi
fi

# Rule 4: No WIP on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    if echo "$COMMIT_MSG" | grep -qi "WIP\|work in progress\|temp\|temporary"; then
        echo "❌ WIP commits not allowed on main branch"
        echo "Create a feature branch for work in progress"
        exit 1
    fi
fi

echo "✅ Commit message format validated"
exit 0
EOF

chmod +x .git/hooks/commit-msg
```

### Test Commit Message Hook

```bash
# Test 1: Message too short
git commit --allow-empty -m "fix"
# Should fail

# Test 2: Valid message
git commit --allow-empty -m "Fix: Customer report performance issue"
# Should succeed

# Test 3: Good message with context
git commit --allow-empty -m "Add index on Orders.CustomerId for better join performance"
# Should succeed
```

## 🎯 Exercise 5: Post-Checkout Hook - Environment Setup

### Create Post-Checkout Hook

```bash
cat > .git/hooks/post-checkout << 'EOF'
#!/bin/bash
# Post-checkout hook: Remind about environment-specific tasks

PREV_HEAD=$1
NEW_HEAD=$2
BRANCH_CHECKOUT=$3

# Only run on branch checkout (not file checkout)
if [ "$BRANCH_CHECKOUT" = "1" ]; then
    NEW_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    echo ""
    echo "📌 Checked out branch: $NEW_BRANCH"
    echo ""

    # Check if this is a feature branch
    if echo "$NEW_BRANCH" | grep -qE '^feature/'; then
        echo "💡 Reminder for feature branch:"
        echo "   • Pull latest from main: git pull origin main"
        echo "   • Check database schema compatibility"
        echo "   • Verify local test database is up to date"
    fi

    # Check if this is a hotfix branch
    if echo "$NEW_BRANCH" | grep -qE '^hotfix/'; then
        echo "🚨 HOTFIX BRANCH - Important reminders:"
        echo "   • Test thoroughly before merging"
        echo "   • Document the issue and fix"
        echo "   • Plan deployment carefully"
        echo "   • Notify team of production change"
    fi

    # Check if switching to main
    if [ "$NEW_BRANCH" = "main" ] || [ "$NEW_BRANCH" = "master" ]; then
        echo "🏠 On main branch:"
        echo "   • Pull latest: git pull"
        echo "   • Create feature branch before making changes"
        echo "   • Never commit directly to main without review"
    fi

    echo ""
fi

exit 0
EOF

chmod +x .git/hooks/post-checkout
```

### Test Post-Checkout Hook

```bash
# Switch branches to see the reminders
git checkout -b feature/test-feature
# See feature branch reminder

git checkout -b hotfix/urgent-fix
# See hotfix reminder

git checkout main
# See main branch reminder
```

## 🔧 Advanced Hook Patterns

### 1. Shared Hooks with Git (via Repository)

Hooks in `.git/hooks/` are local only. To share them:

```bash
# Create a hooks directory in your repo
mkdir -p .githooks

# Move your hooks there
cp .git/hooks/pre-commit .githooks/pre-commit

# Configure Git to use this directory
git config core.hooksPath .githooks

# Now commit the hooks
git add .githooks/
git commit -m "Add shared Git hooks"

# Team members run:
# git config core.hooksPath .githooks
```

### 2. Hook with External SQL Parser

```bash
# Install sqlfluff (Python SQL linter)
# pip install sqlfluff

cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit with sqlfluff linter

STAGED_SQL=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sql$')

if [ -n "$STAGED_SQL" ]; then
    echo "🔍 Running sqlfluff on SQL files..."

    # Check if sqlfluff is installed
    if ! command -v sqlfluff &> /dev/null; then
        echo "⚠️  sqlfluff not found, skipping lint"
        exit 0
    fi

    # Run sqlfluff
    echo "$STAGED_SQL" | xargs sqlfluff lint --dialect tsql

    if [ $? -ne 0 ]; then
        echo "❌ SQL linting failed"
        echo "Run: sqlfluff fix <file> to auto-fix issues"
        exit 1
    fi

    echo "✅ SQL linting passed"
fi

exit 0
EOF
```

### 3. Hook with Database Connectivity Test

```bash
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# Test database connectivity before push

echo "🔌 Testing database connectivity..."

# Test connection (requires sqlcmd)
if command -v sqlcmd &> /dev/null; then
    sqlcmd -S localhost -d TestDB -Q "SELECT 1" -o /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "⚠️  WARNING: Cannot connect to local test database"
        echo "   Scripts haven't been tested against database"
        echo ""
        read -p "Continue push anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✅ Database connection successful"
    fi
fi

exit 0
EOF
```

## 📚 Hook Management Best Practices

### 1. Document Your Hooks

Create a `HOOKS.md` file:

```bash
cat > HOOKS.md << 'EOF'
# Git Hooks Configuration

This repository uses Git hooks for automated validation.

## Active Hooks

### pre-commit
- Validates SQL syntax
- Checks for credentials
- Enforces code quality standards

### commit-msg
- Enforces commit message format
- Minimum 10 characters
- No WIP on main branch

### pre-push
- Runs full validation suite
- Verifies branch naming convention
- Checks for critical issues

## Setup

```bash
# Configure Git to use shared hooks
git config core.hooksPath .githooks
```

## Bypassing Hooks (Emergency Only)

```bash
# Skip pre-commit hook
git commit --no-verify

# Skip pre-push hook
git push --no-verify
```

**Note:** Only bypass hooks in emergencies. Fix the issues instead.
EOF

git add HOOKS.md
git commit -m "Add hooks documentation"
```

### 2. Make Hooks Fast

```bash
# Bad: Check every file in repo
for FILE in $(find . -name "*.sql"); do
    # ... slow checks ...
done

# Good: Check only changed files
for FILE in $(git diff --cached --name-only | grep '\.sql$'); do
    # ... fast checks ...
done
```

### 3. Provide Clear Error Messages

```bash
# Bad
echo "Error"
exit 1

# Good
echo "❌ COMMIT BLOCKED: SQL syntax error in database/BadProc.sql"
echo ""
echo "Fix: Remove unclosed quote on line 15"
echo "Then retry: git commit"
exit 1
```

### 4. Allow Emergency Bypasses

Sometimes you need to bypass hooks:

```bash
# Bypass pre-commit
git commit --no-verify -m "Emergency fix"

# Bypass pre-push
git push --no-verify
```

Document when this is acceptable!

## 🎓 Real-World DBA Hook Scenarios

### Scenario 1: Prevent Committing Test Data

```bash
# Add to pre-commit hook
if grep -r "INSERT INTO.*VALUES.*'test@test.com'" database/; then
    echo "❌ Test data detected in SQL files"
    exit 1
fi
```

### Scenario 2: Enforce Migration Naming

```bash
# Add to pre-commit hook
for FILE in $(git diff --cached --name-only | grep 'migrations/.*\.sql$'); do
    FILENAME=$(basename "$FILE")
    if ! echo "$FILENAME" | grep -qE '^[0-9]{3}_.*\.sql$'; then
        echo "❌ Migration file must be named: 001_description.sql"
        echo "   Got: $FILENAME"
        exit 1
    fi
done
```

### Scenario 3: Tag Releases Automatically

```bash
# post-merge hook
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash
# Auto-tag releases when release branch merges to main

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" = "main" ]; then
    LAST_COMMIT_MSG=$(git log -1 --pretty=%B)

    if echo "$LAST_COMMIT_MSG" | grep -qi "release"; then
        echo "🏷️  Release detected!"
        read -p "Create tag? (version number): " VERSION

        if [ -n "$VERSION" ]; then
            git tag -a "v$VERSION" -m "Release version $VERSION"
            echo "✅ Created tag: v$VERSION"
        fi
    fi
fi
EOF

chmod +x .git/hooks/post-merge
```

## 🎊 Summary

Git hooks are **powerful automation tools** that:
- ✅ Enforce code quality automatically
- ✅ Catch issues before they reach remote
- ✅ Standardize team workflows
- ✅ Save time in code reviews
- ✅ Prevent security issues

**Common DBA Hooks:**
- **pre-commit**: SQL syntax, security scans, formatting
- **commit-msg**: Message format enforcement
- **pre-push**: Full test suite, deployment checks
- **post-checkout**: Environment reminders
- **post-merge**: Database migrations

**Best Practices:**
1. Make hooks fast (only check changed files)
2. Provide clear error messages
3. Document your hooks
4. Share hooks via `.githooks/` directory
5. Allow emergency bypasses with `--no-verify`

**Next Steps:**
- Implement hooks for your team
- Create shared hooks repository
- Integrate with CI/CD pipeline
- Add database connectivity tests

**Next Lesson:** [Lesson 10: Advanced Recovery](./10-advanced-recovery.md) - Master reflog and rescue techniques!
