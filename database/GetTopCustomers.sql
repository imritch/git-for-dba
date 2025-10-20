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
