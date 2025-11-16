CREATE TABLE Customers (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    CreatedDate DATETIME DEFAULT GETDATE()
);
-- Index for email lookups
CREATE NONCLUSTERED INDEX IX_Customers_Email
ON Customers(Email);
