-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email
    WHERE CustomerId = @CustomerId;
END
