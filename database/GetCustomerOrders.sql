-- Get Customer Orders
CREATE PROCEDURE dbo.GetCustomerOrders @CustomerId INT
AS
BEGIN
SELECT 
	OrderId,
	OrderDate,
	TotalAmount
FROM Orders
WHERE CustomerId = @CustomerId;
END
