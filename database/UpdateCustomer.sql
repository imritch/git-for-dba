-- Update Customer Procedure (Enhanced)
CREATE PROCEDURE dbo.UpdateCustomer
    @CustomerId INT,
    @Name NVARCHAR(100),
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- BUG FIX: Add validation (COMMIT THIS)
    IF @CustomerId IS NULL OR @CustomerId <= 0
        THROW 50000, 'Invalid CustomerId', 1;

    -- BUG FIX: Add transaction (COMMIT THIS)
    BEGIN TRANSACTION;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerId = @CustomerId)
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50001, 'Customer not found', 1;
        END

        UPDATE Customers
        SET
            CustomerName = @Name,
            Email = @Email,
            ModifiedDate = GETDATE()
        WHERE CustomerId = @CustomerId;

        -- NEW FEATURE: Audit logging (STASH THIS)
        INSERT INTO AuditLog (TableName, RecordId, Action, ModifiedBy, ModifiedDate)
        VALUES ('Customers', @CustomerId, 'UPDATE', SYSTEM_USER, GETDATE());

        -- NEW FEATURE: Email notification (STASH THIS)
        DECLARE @NotificationEmail NVARCHAR(100);
        SELECT @NotificationEmail = Email FROM Customers WHERE CustomerId = @CustomerId;
        EXEC dbo.SendEmailNotification @NotificationEmail, 'Profile Updated';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
