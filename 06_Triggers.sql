USE StudentTestingDB;
GO

-- Защита завершенных тестов от изменений
CREATE TRIGGER trg_ProtectFinalizedTest
ON TestAttempts
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted i 
        JOIN deleted d ON i.AttemptID = d.AttemptID 
        WHERE d.IsFinalized = 1 AND (i.TotalScore != d.TotalScore OR i.AttemptDate != d.AttemptDate)
    )
    BEGIN
        RAISERROR (N'Нельзя изменять завершенную попытку тестирования.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Проверка корректности ответа
CREATE TRIGGER trg_AutoCheckAnswer
ON StudentAnswers
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Answers a ON i.AnswerID = a.AnswerID
        WHERE i.QuestionID != a.QuestionID
    )
    BEGIN
        RAISERROR (N'Ответ не относится к указанному вопросу.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- INSTEAD OF DELETE для представления v_StudentsManage
CREATE TRIGGER trg_v_StudentsManage_Delete
ON v_StudentsManage
INSTEAD OF DELETE
AS
BEGIN
    -- Проверка наличия истории тестирования
    IF EXISTS (SELECT 1 FROM TestAttempts ta JOIN deleted d ON ta.StudentID = d.StudentID)
    BEGIN
        RAISERROR (N'Нельзя удалить студента с существующей историей тестирования.', 16, 1);
        RETURN;
    END
    
    DELETE FROM Students WHERE StudentID IN (SELECT StudentID FROM deleted);
END;
GO

PRINT 'Триггеры успешно созданы!';
GO
