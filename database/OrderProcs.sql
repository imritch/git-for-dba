CREATE PROCEDURE GetUserOrders
    @UserId INT
AS
BEGIN
    SELECT * FROM Orders WHERE UserId = @UserId;
END
