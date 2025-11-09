-- Bug fix 3
CREATE TRIGGER TR_MainTable_Update
ON MainTable AFTER UPDATE
AS BEGIN
    UPDATE MainTable SET UpdatedDate = GETDATE()
    FROM MainTable m INNER JOIN inserted i ON m.Id = i.Id;
END
