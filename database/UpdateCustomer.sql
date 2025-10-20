-- Update Customer Information
CREATE PROCEDURE dbo.UpdateCustomer
	@CustomerId INT, 
	@CustomerName NVARCHAR(100),
	@Email NVARCHAR(100),
	@Address NVARCHAR(200)
AS
BEGIN
	UPDATE Customers
	SET
		CustomerName = @CustomerName,
		Email = @Email,
		Address = @Address
	WHERE CustomerId = @CustomerId;
END
