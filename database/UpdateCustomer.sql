-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @CustomerName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20),
    @Address NVARCHAR(200)
AS
BEGIN
    UPDATE Customers
    SET 
        CustomerName = @CustomerName,
        Email = @Email,
        Phone = @Phone,
        Address = @Address
    WHERE CustomerId = @CustomerId;
END
