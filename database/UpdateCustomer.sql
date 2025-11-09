-- Update Customer Procedure
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @Name NVARCHAR(100),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- BUG FIX: Add validation (WANT TO COMMIT THIS)
    IF @CustomerId IS NULL
        THROW 50000, 'CustomerId cannot be null', 1;

    -- BUG FIX: Check if customer exists (WANT TO COMMIT THIS)
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerId)
        THROW 50001, 'Customer not found', 1;

    UPDATE Customers
    SET
        CustomerName = @Name,
        Email = @Email,
        ModifiedDate = GETDATE()
    WHERE CustomerId = @CustomerId;

    -- NEW FEATURE: Add audit logging (STASH THIS FOR LATER)
    INSERT INTO AuditLog (TableName, RecordId, Action, ModifiedBy, ModifiedDate)
    VALUES ('Customers', @CustomerId, 'UPDATE', SYSTEM_USER, GETDATE());

    -- NEW FEATURE: Send notification (STASH THIS FOR LATER)
    EXEC dbo.SendCustomerUpdateNotification @CustomerId;
END
