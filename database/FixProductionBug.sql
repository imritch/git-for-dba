-- Emergency fix: Add missing index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON  Orders(CustomerId)
INCLUDE (OrderDate, TotalAmount, Status);
