CREATE PROCEDURE dbo.GetTopCustomers @TopN INT = 10
AS 
BEGIN
	SELECT TOP (@TopN)
		CustomerId, 
		CustomerName,
		TotalPurchases
	FROM Customers
	ORDER BY TotalPurchases DESC;
END
