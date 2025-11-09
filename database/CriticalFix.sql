-- Fix for SQL injection vulnerability
CREATE PROCEDURE SafeSearch
    @SearchTerm NVARCHAR(100)
AS
BEGIN
    SELECT * FROM MainTable 
    WHERE Data LIKE '%' + @SearchTerm + '%';  -- Properly parameterized
END
