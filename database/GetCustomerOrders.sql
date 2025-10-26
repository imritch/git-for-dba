-- Get Customer Orders with Error Handling
CREATE PROCEDURE dbo.GetCustomerOrders
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- TODO: Add validation
        -- TODO: Add logging
        
        SELECT 
            OrderId,
            OrderDate,
            TotalAmount,
            Status  -- Adding new column
        FROM Orders
        WHERE CustomerId = @CustomerId;
        
    END TRY
    BEGIN CATCH
        -- Error handling in progress...
    END CATCH
END
