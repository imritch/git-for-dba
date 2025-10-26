CREATE PROCEDURE dbo.ProcessOrders
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        OrderId, 
        CustomerId, 
        OrderDate, 
        TotalAmount 
    FROM Orders;
END
