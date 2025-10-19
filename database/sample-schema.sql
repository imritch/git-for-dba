-- Sample Database Schema for Git Practice
-- Use this as a starting point for exercises

-- Customers Table
CREATE TABLE dbo.Customers (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Create index on email for lookups
CREATE NONCLUSTERED INDEX IX_Customers_Email
ON dbo.Customers(Email)
WHERE Email IS NOT NULL;
GO

-- Orders Table
CREATE TABLE dbo.Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Pending',
    CONSTRAINT FK_Orders_Customers 
        FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId)
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON dbo.Orders(CustomerId);
GO

CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
ON dbo.Orders(OrderDate DESC);
GO

-- Products Table
CREATE TABLE dbo.Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    Price DECIMAL(10,2) NOT NULL,
    Stock INT DEFAULT 0,
    IsActive BIT DEFAULT 1
);
GO

-- OrderDetails Table
CREATE TABLE dbo.OrderDetails (
    OrderDetailId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_OrderDetails_Orders 
        FOREIGN KEY (OrderId) REFERENCES dbo.Orders(OrderId),
    CONSTRAINT FK_OrderDetails_Products 
        FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId)
);
GO

-- Basic stored procedures
CREATE PROCEDURE dbo.GetCustomerOrders
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        o.OrderId,
        o.OrderDate,
        o.TotalAmount,
        o.Status,
        COUNT(od.OrderDetailId) AS ItemCount
    FROM dbo.Orders o
    LEFT JOIN dbo.OrderDetails od ON o.OrderId = od.OrderId
    WHERE o.CustomerId = @CustomerId
    GROUP BY o.OrderId, o.OrderDate, o.TotalAmount, o.Status
    ORDER BY o.OrderDate DESC;
END
GO

CREATE PROCEDURE dbo.GetProductInventory
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ProductId,
        ProductName,
        Price,
        Stock,
        CASE 
            WHEN Stock = 0 THEN 'Out of Stock'
            WHEN Stock < 10 THEN 'Low Stock'
            ELSE 'In Stock'
        END AS StockStatus
    FROM dbo.Products
    WHERE IsActive = 1
    ORDER BY ProductName;
END
GO

