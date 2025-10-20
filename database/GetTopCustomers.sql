CREATE PROCEDURE dbo.GetTopCustomers 
	@TopN INT = 10,
	@MinPurchases DECIMAL(10,2) = 0,
	@StartDate DATE = NULL
AS
BEGIN
	SELECT TOP (@TopN)
		CustomerId,
		CustomerName,
		TotalPurchases
	FROM Customers
	WHERE TotalPurchases >= @MinPurchases
	AND (@StartDate IS NULL OR RegistrationDate >= @StartDate) 
	ORDER BY TotalPurchases DESC;
END
