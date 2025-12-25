USE StudentTestingDB;
GO

PRINT N'1. Представления:';
PRINT N'1.1. Отчет по успеваемости групп:';
SELECT TOP 5 * FROM v_GroupResults;
GO

PRINT N'1.2. Студенты, не прошедшие тест после 3 попыток:';
SELECT TOP 5 * FROM v_FailedStudents;
GO

PRINT N'1.3. Студенты, не приступавшие к тестированию:';
SELECT TOP 5 * FROM v_StudentsNotStarted;
GO

PRINT N'1.4. Детальный список студентов по группам с результатами:';
SELECT TOP 10 * FROM v_StudentsByGroupWithResults WHERE TestName IS NOT NULL;
GO

PRINT N'2. Функции:';
PRINT N'2.1. Расчет балла за попытку (fn_CalculateScore):';
DECLARE @TestAttemptID INT;
SELECT @TestAttemptID = (SELECT TOP 1 AttemptID FROM TestAttempts WHERE IsFinalized = 1);
IF @TestAttemptID IS NOT NULL
    SELECT dbo.fn_CalculateScore(@TestAttemptID) AS CalculatedScore;
GO

PRINT N'2.2. История тестов студента (fn_GetStudentHistory):';
DECLARE @TestStudentID INT;
SELECT @TestStudentID = (SELECT TOP 1 StudentID FROM TestAttempts WHERE IsFinalized = 1);
IF @TestStudentID IS NOT NULL
    SELECT * FROM dbo.fn_GetStudentHistory(@TestStudentID);
GO

PRINT N'2.3. Количество попыток студента (fn_CountAttempts):';
DECLARE @TestStudentID2 INT, @TestTestID INT;
SELECT @TestStudentID2 = (SELECT TOP 1 StudentID FROM TestAttempts);
SELECT @TestTestID = (SELECT TOP 1 TestID FROM TestAttempts);
IF @TestStudentID2 IS NOT NULL AND @TestTestID IS NOT NULL
    SELECT dbo.fn_CountAttempts(@TestStudentID2, @TestTestID) AS AttemptsCount;
GO

PRINT N'2.4. Средний балл по группе (fn_GetGroupAverageScore):';
DECLARE @TestGroupID4 INT, @TestTestID4 INT;
SELECT @TestGroupID4 = (SELECT TOP 1 g.GroupID FROM Groups g JOIN Students s ON g.GroupID = s.GroupID JOIN TestAttempts ta ON s.StudentID = ta.StudentID WHERE ta.IsFinalized = 1);
SELECT @TestTestID4 = (SELECT TOP 1 TestID FROM TestAttempts WHERE IsFinalized = 1);
IF @TestGroupID4 IS NOT NULL AND @TestTestID4 IS NOT NULL
BEGIN
    SELECT 
        g.GroupName,
        t.TestName,
        dbo.fn_GetGroupAverageScore(@TestGroupID4, @TestTestID4) AS AverageScore
    FROM Groups g, Tests t
    WHERE g.GroupID = @TestGroupID4 AND t.TestID = @TestTestID4;
END
GO

PRINT N'3. Хранимые процедуры:';
PRINT N'3.1. Начало новой попытки (sp_StartTest):';
DECLARE @NewAttemptID INT;
DECLARE @TestStudentID3 INT;
DECLARE @TestTestID2 INT;
SELECT @TestStudentID3 = (SELECT TOP 1 StudentID FROM Students);
SELECT @TestTestID2 = (SELECT TOP 1 TestID FROM Tests);
IF @TestStudentID3 IS NOT NULL AND @TestTestID2 IS NOT NULL
BEGIN
    EXEC sp_StartTest @StudentID = @TestStudentID3, @TestID = @TestTestID2, @NewAttemptID = @NewAttemptID OUTPUT;
    PRINT N'Создана попытка ID: ' + CAST(@NewAttemptID AS NVARCHAR(10));
END
GO

PRINT N'3.2. Сохранение ответа (sp_SaveAnswer):';
DECLARE @LastAttemptID INT;
SELECT @LastAttemptID = (SELECT TOP 1 AttemptID FROM TestAttempts WHERE IsFinalized = 0 ORDER BY AttemptID DESC);
IF @LastAttemptID IS NOT NULL
BEGIN
    DECLARE @QID INT, @AID INT;
    SELECT @QID = (SELECT TOP 1 QuestionID FROM Questions);
    SELECT @AID = (SELECT TOP 1 AnswerID FROM Answers WHERE QuestionID = @QID);
    IF @QID IS NOT NULL AND @AID IS NOT NULL
    BEGIN
        EXEC sp_SaveAnswer @AttemptID = @LastAttemptID, @QuestionID = @QID, @AnswerID = @AID;
        PRINT N'Ответ сохранен для попытки ' + CAST(@LastAttemptID AS NVARCHAR(10));
    END
END
GO

PRINT N'3.3. Завершение теста (sp_FinishTest):';
DECLARE @FinishAttemptID INT;
SELECT @FinishAttemptID = (SELECT TOP 1 AttemptID FROM TestAttempts WHERE IsFinalized = 0 ORDER BY AttemptID DESC);
IF @FinishAttemptID IS NOT NULL
BEGIN
    EXEC sp_FinishTest @AttemptID = @FinishAttemptID;
    SELECT AttemptID, dbo.fn_CalculateScore(AttemptID) AS TotalScore, IsFinalized FROM TestAttempts WHERE AttemptID = @FinishAttemptID;
    PRINT N'Тест завершен';
END
GO

PRINT N'3.4. Отчет по группе с курсором (sp_GetGroupReport):';
DECLARE @TestGroupID INT, @TestTestID3 INT;
SELECT @TestGroupID = (SELECT TOP 1 GroupID FROM Groups);
SELECT @TestTestID3 = (SELECT TOP 1 TestID FROM Tests);
IF @TestGroupID IS NOT NULL AND @TestTestID3 IS NOT NULL
    EXEC sp_GetGroupReport @GroupID = @TestGroupID, @TestID = @TestTestID3;
GO

PRINT N'3.5. Курсор: Напоминания студентам, не приступавшим к тестированию:';
DECLARE @StudentName NVARCHAR(100);
DECLARE @GroupName NVARCHAR(20);
DECLARE cur_LazyStudents CURSOR FOR
SELECT s.LastName + ' ' + s.FirstName + ' ' + ISNULL(s.MiddleName, '') AS FullName, g.GroupName
FROM Students s
JOIN Groups g ON s.GroupID = g.GroupID
LEFT JOIN TestAttempts ta ON s.StudentID = ta.StudentID
WHERE ta.AttemptID IS NULL;
OPEN cur_LazyStudents;
FETCH NEXT FROM cur_LazyStudents INTO @StudentName, @GroupName;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'Напоминание: Студент ' + @StudentName + N' (Группа ' + @GroupName + N') еще не проходил тестирование!';
    FETCH NEXT FROM cur_LazyStudents INTO @StudentName, @GroupName;
END;
CLOSE cur_LazyStudents;
DEALLOCATE cur_LazyStudents;
GO

PRINT N'4. Обновляемое представление v_StudentsManage:';
PRINT N'4.1. UPDATE через представление:';
DECLARE @TestStudentID4 INT;
SELECT @TestStudentID4 = (SELECT TOP 1 StudentID FROM Students);
IF @TestStudentID4 IS NOT NULL
BEGIN
    UPDATE v_StudentsManage SET Email = N'test@example.com' WHERE StudentID = @TestStudentID4;
    SELECT StudentID, LastName, Email FROM v_StudentsManage WHERE StudentID = @TestStudentID4;
    PRINT N'UPDATE выполнен';
END
GO

PRINT N'4.2. INSERT через представление:';
DECLARE @TestGroupID2 INT;
SELECT @TestGroupID2 = (SELECT TOP 1 GroupID FROM Groups);
IF @TestGroupID2 IS NOT NULL
BEGIN
    DECLARE @InsertedIDs TABLE (StudentID INT);
    
    INSERT INTO v_StudentsManage (LastName, FirstName, MiddleName, Email, GroupID)
    OUTPUT INSERTED.StudentID INTO @InsertedIDs
    VALUES (N'Тестов', N'Тест', N'Тестович', N'test.insert@example.com', @TestGroupID2);
    
    DECLARE @NewStudentID INT;
    SELECT @NewStudentID = StudentID FROM @InsertedIDs;
    
    SELECT * FROM v_StudentsManage WHERE StudentID = @NewStudentID;
    PRINT N'INSERT выполнен, создан студент ID: ' + CAST(@NewStudentID AS NVARCHAR(10));
    
    DELETE FROM v_StudentsManage WHERE StudentID = @NewStudentID;
    PRINT N'Тестовый студент удален';
END
GO

PRINT N'4.3. DELETE через представление (студент без истории):';
DECLARE @TestGroupID3 INT;
SELECT @TestGroupID3 = (SELECT TOP 1 GroupID FROM Groups);
IF @TestGroupID3 IS NOT NULL
BEGIN
    DECLARE @InsertedIDs2 TABLE (StudentID INT);
    
    INSERT INTO v_StudentsManage (LastName, FirstName, MiddleName, Email, GroupID)
    OUTPUT INSERTED.StudentID INTO @InsertedIDs2
    VALUES (N'Удаляемый', N'Студент', NULL, N'delete.test@example.com', @TestGroupID3);
    
    DECLARE @TempStudentID INT;
    SELECT @TempStudentID = StudentID FROM @InsertedIDs2;
    
    PRINT N'Создан студент ID: ' + CAST(@TempStudentID AS NVARCHAR(10));
    
    DELETE FROM v_StudentsManage WHERE StudentID = @TempStudentID;
    
    IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @TempStudentID)
        PRINT N'DELETE выполнен, студент ID ' + CAST(@TempStudentID AS NVARCHAR(10)) + N' удален';
    ELSE
        PRINT N'ОШИБКА: студент не был удален';
END
GO

-- ============================================
-- 5. ТЕСТЫ ТРИГГЕРОВ
-- ============================================

PRINT N'5. Триггеры:';
PRINT N'5.1. Защита завершенных тестов (trg_ProtectFinalizedTest):';
DECLARE @FinalizedAttemptID INT;
SELECT @FinalizedAttemptID = (SELECT TOP 1 AttemptID FROM TestAttempts WHERE IsFinalized = 1);
IF @FinalizedAttemptID IS NOT NULL
BEGIN
    BEGIN TRY
        UPDATE TestAttempts SET AttemptDate = GETDATE() WHERE AttemptID = @FinalizedAttemptID;
        PRINT N'✗ Триггер не сработал';
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE N'%завершенную попытку%'
            PRINT N'✓ Триггер защищает завершенные тесты';
    END CATCH
END
GO

PRINT N'5.2. Проверка корректности ответа (trg_AutoCheckAnswer):';
DECLARE @UnfinishedAttemptID INT;
SELECT @UnfinishedAttemptID = (SELECT TOP 1 AttemptID FROM TestAttempts WHERE IsFinalized = 0);
IF @UnfinishedAttemptID IS NOT NULL
BEGIN
    DECLARE @WrongQID INT, @WrongAID INT;
    SELECT @WrongQID = (SELECT TOP 1 QuestionID FROM Questions);
    SELECT @WrongAID = (SELECT TOP 1 AnswerID FROM Answers WHERE QuestionID != @WrongQID);
    IF @WrongQID IS NOT NULL AND @WrongAID IS NOT NULL
    BEGIN
        BEGIN TRY
            INSERT INTO StudentAnswers (AttemptID, QuestionID, AnswerID)
            VALUES (@UnfinishedAttemptID, @WrongQID, @WrongAID);
            PRINT N'✗ Триггер не сработал';
        END TRY
        BEGIN CATCH
            IF ERROR_MESSAGE() LIKE N'%не относится к указанному вопросу%'
                PRINT N'✓ Триггер проверяет корректность ответа';
        END CATCH
    END
END
GO

-- Проверка функциональных требований ТЗ
PRINT N'6. Функциональные требования ТЗ:';
PRINT N'6.1. Расчет балла за тестирование:';
SELECT TOP 5 StudentID, TestID, dbo.fn_CalculateScore(AttemptID) AS TotalScore
FROM TestAttempts 
WHERE IsFinalized = 1 
ORDER BY AttemptDate DESC;
GO

PRINT N'6.2. Средний балл по группе:';
SELECT TOP 5 * FROM v_GroupResults;
GO

PRINT N'6.3. Студенты, не прошедшие после 3 попыток:';
SELECT * FROM v_FailedStudents;
GO

PRINT N'6.4. Студенты, не приступавшие к тестированию:';
SELECT TOP 5 * FROM v_StudentsNotStarted;
GO

PRINT N'6.5. Список студентов по группам с результатами:';
SELECT TOP 10 GroupName, FullName, TestName, TotalScore, Status 
FROM v_StudentsByGroupWithResults 
WHERE TestName IS NOT NULL;
GO
