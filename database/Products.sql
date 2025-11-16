CREATE TABLE Products (
    ProductId INT PRIMARY KEY,
    ProductName NVARCHAR(100)
);

CREATE NONCLUSTERED INDEX IX_Products_Name
ON Products(ProductName);
