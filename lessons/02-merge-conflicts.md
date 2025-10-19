# Lesson 2: Merge Conflicts - When Changes Collide

## 🎯 What are Merge Conflicts?

A merge conflict occurs when Git can't automatically combine changes because two branches modified the same part of a file differently.

**DBA Analogy:** Like two DBAs updating the same stored procedure simultaneously - someone needs to decide which changes to keep!

## 🤔 Why Do Conflicts Happen?

Conflicts occur when:
- Two branches modify the same line(s) in a file
- One branch deletes a file that another branch modifies
- Changes are too close together for Git to auto-merge

## 📝 Exercise 1: Create Your First Conflict

### Step 1: Setup - Create a base stored procedure

```bash
cd /Users/riteshchawla/RC/git/git-for-dba

# Create a stored procedure
cat > database/UpdateCustomer.sql << 'EOF'
-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email
    WHERE CustomerId = @CustomerId;
END
EOF

git add database/UpdateCustomer.sql
git commit -m "Add UpdateCustomer stored procedure"
```

### Step 2: Create two branches with conflicting changes

```bash
# Create and switch to feature branch 1
git checkout -b feature/add-phone

# Add phone number parameter
cat > database/UpdateCustomer.sql << 'EOF'
-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email,
        Phone = @Phone
    WHERE CustomerId = @CustomerId;
END
EOF

git add database/UpdateCustomer.sql
git commit -m "Add phone number to UpdateCustomer"

# Go back to main
git checkout main

# Create another feature branch
git checkout -b feature/add-address

# Add address parameter (conflicts with phone!)
cat > database/UpdateCustomer.sql << 'EOF'
-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email,
        Address = @Address
    WHERE CustomerId = @CustomerId;
END
EOF

git add database/UpdateCustomer.sql
git commit -m "Add address to UpdateCustomer"
```

### Step 3: Create the conflict

```bash
# Go back to main and merge the first feature
git checkout main
git merge feature/add-phone
# This merges cleanly

# Now try to merge the second feature - CONFLICT!
git merge feature/add-address
```

**Output you'll see:**
```
Auto-merging database/UpdateCustomer.sql
CONFLICT (content): Merge conflict in database/UpdateCustomer.sql
Automatic merge failed; fix conflicts and then commit the result.
```

### Step 4: Examine the conflict

```bash
# Check status
git status

# Look at the conflicted file
cat database/UpdateCustomer.sql
```

**You'll see conflict markers:**
```sql
-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100),
<<<<<<< HEAD
    @Phone NVARCHAR(20)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email,
        Phone = @Phone
=======
    @Address NVARCHAR(200)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email,
        Address = @Address
>>>>>>> feature/add-address
    WHERE CustomerId = @CustomerId;
END
```

**Understanding the markers:**
- `<<<<<<< HEAD` - Your current branch's version (main, which has phone)
- `=======` - Separator
- `>>>>>>> feature/add-address` - Incoming branch's version (address)

### Step 5: Resolve the conflict

**Option 1: Keep both changes (best solution here)**

```bash
# Edit the file to include BOTH phone and address
cat > database/UpdateCustomer.sql << 'EOF'
-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20),
    @Address NVARCHAR(200)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email,
        Phone = @Phone,
        Address = @Address
    WHERE CustomerId = @CustomerId;
END
EOF

# Mark as resolved
git add database/UpdateCustomer.sql

# Complete the merge
git commit -m "Merge feature/add-address - resolved by including both phone and address"
```

**Option 2: Keep only HEAD version**
```bash
git checkout --ours database/UpdateCustomer.sql
git add database/UpdateCustomer.sql
```

**Option 3: Keep only incoming version**
```bash
git checkout --theirs database/UpdateCustomer.sql
git add database/UpdateCustomer.sql
```

## 📝 Exercise 2: Merge Conflict Tools

```bash
# View conflicts with different tools

# See which files have conflicts
git diff --name-only --diff-filter=U

# See the conflict in detail
git diff

# Use merge tool (if configured)
git mergetool

# Abort the merge if you want to start over
git merge --abort
```

## 📝 Exercise 3: Rebase Conflicts

Conflicts can also happen during rebase. Let's create one:

```bash
# Create a new scenario
git checkout main
cat > database/GetTopCustomers.sql << 'EOF'
CREATE PROCEDURE dbo.GetTopCustomers
    @TopN INT = 10
AS
BEGIN
    SELECT TOP (@TopN)
        CustomerId,
        CustomerName,
        TotalPurchases
    FROM Customers
    ORDER BY TotalPurchases DESC;
END
EOF

git add database/GetTopCustomers.sql
git commit -m "Add GetTopCustomers procedure"

# Create feature branch
git checkout -b feature/add-date-filter
cat > database/GetTopCustomers.sql << 'EOF'
CREATE PROCEDURE dbo.GetTopCustomers
    @TopN INT = 10,
    @StartDate DATE = NULL
AS
BEGIN
    SELECT TOP (@TopN)
        CustomerId,
        CustomerName,
        TotalPurchases
    FROM Customers
    WHERE @StartDate IS NULL OR RegistrationDate >= @StartDate
    ORDER BY TotalPurchases DESC;
END
EOF

git add database/GetTopCustomers.sql
git commit -m "Add date filter to GetTopCustomers"

# Meanwhile, main branch also changes
git checkout main
cat > database/GetTopCustomers.sql << 'EOF'
CREATE PROCEDURE dbo.GetTopCustomers
    @TopN INT = 10,
    @MinPurchases DECIMAL(10,2) = 0
AS
BEGIN
    SELECT TOP (@TopN)
        CustomerId,
        CustomerName,
        TotalPurchases
    FROM Customers
    WHERE TotalPurchases >= @MinPurchases
    ORDER BY TotalPurchases DESC;
END
EOF

git add database/GetTopCustomers.sql
git commit -m "Add minimum purchase filter to GetTopCustomers"

# Now try to rebase feature branch
git checkout feature/add-date-filter
git rebase main
# CONFLICT!

# Resolve similar to merge conflicts
# Edit the file, then:
git add database/GetTopCustomers.sql
git rebase --continue

# Or abort
git rebase --abort
```

## 🎓 Advanced Conflict Resolution

### Strategy 1: Three-way comparison

```bash
# During a conflict, see all three versions:
git show :1:database/UpdateCustomer.sql  # Common ancestor
git show :2:database/UpdateCustomer.sql  # HEAD (ours)
git show :3:database/UpdateCustomer.sql  # Incoming (theirs)
```

### Strategy 2: Accept one side entirely

```bash
# For all conflicts, accept ours
git merge -X ours feature-branch

# For all conflicts, accept theirs
git merge -X theirs feature-branch
```

### Strategy 3: Cherry-pick conflicts

```bash
# Cherry-picking can also cause conflicts
git cherry-pick <commit-hash>
# If conflict:
# Resolve, then:
git cherry-pick --continue
# Or abort:
git cherry-pick --abort
```

## ⚠️ Common Pitfalls

1. **Forgetting conflict markers**: Always search for `<<<<<<<` before committing

2. **Not testing after resolution**: Always test your merged code!

3. **Resolving without understanding**: Read both versions carefully

4. **Committing conflict markers**: Git will let you commit files with conflict markers - DON'T!

## 🎯 Real-World DBA Scenarios

### Scenario 1: Multiple DBAs on Same Procedure
```
DBA 1: Adds error handling
DBA 2: Adds performance optimization
Result: Merge conflict in the same procedure
Solution: Combine both improvements
```

### Scenario 2: Schema Changes
```
Branch A: Adds column "Email" to table
Branch B: Adds column "Phone" to table
Same migration file modified
Solution: Include both columns in the merge
```

### Scenario 3: Different Approaches
```
Branch A: Uses cursor-based approach
Branch B: Uses set-based approach
Solution: Choose the better approach (usually set-based!)
```

## ✅ Practice Exercise

Create this scenario:
1. Create a stored procedure on main
2. Branch 1: Add transaction handling
3. Branch 2: Add parameter validation
4. Merge branch 1 to main
5. Merge branch 2 to main (conflict!)
6. Resolve by including both features

## 🎓 Key Takeaways

- Conflicts are normal in collaborative development
- `git status` shows which files have conflicts
- Always remove conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- `git merge --abort` or `git rebase --abort` to bail out
- Test your code after resolving conflicts
- Communication with team helps prevent conflicts

## 📚 Next Lesson

Ready to rewrite history? Move to [Lesson 3: Git Rebase](./03-git-rebase.md)

