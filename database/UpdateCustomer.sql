-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email,
        Phone = @Phone
    WHERE CustomerId = @CustomerId;
END
