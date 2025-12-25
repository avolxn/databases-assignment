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
        WHERE d.IsFinalized = 1 AND i.AttemptDate != d.AttemptDate
    )
    BEGIN
        THROW 50001, N'Нельзя изменять завершенную попытку тестирования.', 1;
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
        THROW 50002, N'Ответ не относится к указанному вопросу.', 1;
        ROLLBACK TRANSACTION;
    END
END;
GO

-- INSTEAD OF INSERT для представления v_StudentsManage
CREATE TRIGGER trg_v_StudentsManage_Insert
ON v_StudentsManage
INSTEAD OF INSERT
AS
BEGIN
    -- Проверка существования группы
    IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM Groups WHERE GroupID = i.GroupID))
    BEGIN
        THROW 50003, N'Указанная группа не существует.', 1;
        RETURN;
    END
    
    INSERT INTO Students (LastName, FirstName, MiddleName, Email, GroupID)
    SELECT LastName, FirstName, MiddleName, Email, GroupID
    FROM inserted;
END;
GO

-- INSTEAD OF UPDATE для представления v_StudentsManage
CREATE TRIGGER trg_v_StudentsManage_Update
ON v_StudentsManage
INSTEAD OF UPDATE
AS
BEGIN
    -- Проверка существования группы при изменении GroupID
    IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM Groups WHERE GroupID = i.GroupID))
    BEGIN
        THROW 50003, N'Указанная группа не существует.', 1;
        RETURN;
    END
    
    UPDATE Students
    SET LastName = i.LastName,
        FirstName = i.FirstName,
        MiddleName = i.MiddleName,
        Email = i.Email,
        GroupID = i.GroupID
    FROM Students s
    JOIN inserted i ON s.StudentID = i.StudentID;
END;
GO
