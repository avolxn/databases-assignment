USE StudentTestingDB;
GO

-- Начать попытку тестирования
CREATE PROCEDURE sp_StartTest
    @StudentID INT,
    @TestID INT,
    @NewAttemptID INT OUTPUT
AS
BEGIN
    INSERT INTO TestAttempts (StudentID, TestID, AttemptDate, IsFinalized)
    VALUES (@StudentID, @TestID, GETDATE(), 0);
    
    SET @NewAttemptID = SCOPE_IDENTITY();
END;
GO

-- Сохранить ответ студента
CREATE PROCEDURE sp_SaveAnswer
    @AttemptID INT,
    @QuestionID INT,
    @AnswerID INT
AS
BEGIN
    -- Проверка, что тест еще не завершен
    IF EXISTS (SELECT 1 FROM TestAttempts WHERE AttemptID = @AttemptID AND IsFinalized = 1)
    BEGIN
        THROW 50001, N'Тест уже завершен. Нельзя отвечать.', 1;
        RETURN;
    END
    
    INSERT INTO StudentAnswers (AttemptID, QuestionID, AnswerID)
    VALUES (@AttemptID, @QuestionID, @AnswerID);
END;
GO

-- Завершить тест и рассчитать результат
CREATE PROCEDURE sp_FinishTest
    @AttemptID INT
AS
BEGIN
    UPDATE TestAttempts
    SET IsFinalized = 1
    WHERE AttemptID = @AttemptID;
END;
GO

-- Отчет по группе (с использованием курсора)
CREATE PROCEDURE sp_GetGroupReport
    @GroupID INT,
    @TestID INT
AS
BEGIN
    DECLARE @StudentName NVARCHAR(100);
    DECLARE @GroupName NVARCHAR(20);
    DECLARE @AttemptCount INT;
    DECLARE @BestScore INT;
    
    SELECT @GroupName = GroupName FROM Groups WHERE GroupID = @GroupID;
    
    -- Объявление курсора
    DECLARE cur_GroupStudents CURSOR FOR
        SELECT 
        s.LastName + ' ' + s.FirstName + ' ' + ISNULL(s.MiddleName, '') AS FullName,
        dbo.fn_CountAttempts(s.StudentID, @TestID) AS AttemptCount,
        ISNULL(MAX(dbo.fn_CalculateScore(ta.AttemptID)), 0) AS BestScore
        FROM Students s
    LEFT JOIN TestAttempts ta ON s.StudentID = ta.StudentID AND ta.TestID = @TestID AND ta.IsFinalized = 1
        WHERE s.GroupID = @GroupID
    GROUP BY s.StudentID, s.LastName, s.FirstName, s.MiddleName;
    
    OPEN cur_GroupStudents;
    
    FETCH NEXT FROM cur_GroupStudents INTO @StudentName, @AttemptCount, @BestScore;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'Студент: ' + @StudentName + N' (Группа: ' + @GroupName + N') - Попыток: ' + 
              CAST(@AttemptCount AS NVARCHAR(10)) + N', Лучший балл: ' + CAST(@BestScore AS NVARCHAR(10));
        
        FETCH NEXT FROM cur_GroupStudents INTO @StudentName, @AttemptCount, @BestScore;
    END;
    
    CLOSE cur_GroupStudents;
    DEALLOCATE cur_GroupStudents;
END;
GO

-- Получить историю тестирования студента
CREATE PROCEDURE sp_GetStudentTestHistory
    @StudentID INT
AS
BEGIN
    SELECT * FROM dbo.fn_GetStudentHistory(@StudentID);
END;
GO

-- Проверить успеваемость группы по тесту
CREATE PROCEDURE sp_CheckGroupPerformance
    @GroupID INT,
    @TestID INT
AS
BEGIN
    DECLARE @AvgScore DECIMAL(5,2);
    DECLARE @GroupName NVARCHAR(20);
    DECLARE @TestName NVARCHAR(100);
    
    SELECT @GroupName = GroupName FROM Groups WHERE GroupID = @GroupID;
    SELECT @TestName = TestName FROM Tests WHERE TestID = @TestID;
    
    SET @AvgScore = dbo.fn_GetGroupAverageScore(@GroupID, @TestID);
    
    PRINT N'Группа: ' + @GroupName;
    PRINT N'Тест: ' + @TestName;
    PRINT N'Средний балл: ' + CAST(@AvgScore AS NVARCHAR(10));
    
    IF @AvgScore >= 2.5
        PRINT N'Статус: Хорошая успеваемость';
    ELSE IF @AvgScore >= 1.5
        PRINT N'Статус: Удовлетворительная успеваемость';
    ELSE
        PRINT N'Статус: Низкая успеваемость';
END;
GO

PRINT N'Хранимые процедуры успешно созданы!';
GO
