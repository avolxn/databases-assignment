USE StudentTestingDB;
GO

-- Скалярная функция: Расчет балла за попытку
CREATE FUNCTION fn_CalculateScore (@AttemptID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Score INT;
    SELECT @Score = SUM(q.Points)
    FROM StudentAnswers sa
    JOIN Answers a ON sa.AnswerID = a.AnswerID
    JOIN Questions q ON a.QuestionID = q.QuestionID
    WHERE sa.AttemptID = @AttemptID AND a.IsCorrect = 1;
    
    RETURN ISNULL(@Score, 0);
END;
GO

-- Табличная функция: История тестов студента
CREATE FUNCTION fn_GetStudentHistory (@StudentID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        t.TestName,
        ta.AttemptDate,
        ta.TotalScore,
        CASE WHEN ta.TotalScore >= t.MinScoreToPass THEN N'Сдал' ELSE N'Не сдал' END AS Status
    FROM TestAttempts ta
    JOIN Tests t ON ta.TestID = t.TestID
    WHERE ta.StudentID = @StudentID AND ta.IsFinalized = 1
);
GO

-- Скалярная функция: Количество попыток студента по тесту
CREATE FUNCTION fn_CountAttempts (@StudentID INT, @TestID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*) 
    FROM TestAttempts 
    WHERE StudentID = @StudentID AND TestID = @TestID;
    RETURN ISNULL(@Count, 0);
END;
GO

PRINT 'Функции успешно созданы!';
GO
