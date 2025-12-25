USE StudentTestingDB;
GO

-- Обновляемое представление для управления студентами
CREATE VIEW v_StudentsManage AS
SELECT 
    StudentID, 
    LastName, 
    FirstName, 
    MiddleName, 
    Email, 
    GroupID
FROM Students;
GO

-- Отчет по успеваемости групп (только лучшие попытки)
CREATE VIEW v_GroupResults AS
WITH BestAttempts AS (
    SELECT 
        ta.StudentID,
        ta.TestID,
        MAX(dbo.fn_CalculateScore(ta.AttemptID)) AS BestScore
    FROM TestAttempts ta
    WHERE ta.IsFinalized = 1
    GROUP BY ta.StudentID, ta.TestID
)
SELECT 
    g.GroupName,
    t.TestName,
    AVG(CAST(ba.BestScore AS DECIMAL(5,2))) AS AverageGroupScore,
    COUNT(DISTINCT ba.StudentID) AS StudentsTested
FROM Groups g
JOIN Students s ON g.GroupID = s.GroupID
JOIN BestAttempts ba ON s.StudentID = ba.StudentID
JOIN Tests t ON ba.TestID = t.TestID
GROUP BY g.GroupName, t.TestName;
GO

-- Студенты, не прошедшие тест после 3 попыток
CREATE VIEW v_FailedStudents AS
SELECT 
    s.StudentID,
    s.LastName + ' ' + s.FirstName + ' ' + ISNULL(s.MiddleName, '') AS FullName,
    g.GroupName,
    t.TestName,
    COUNT(ta.AttemptID) AS AttemptsCount,
    MAX(dbo.fn_CalculateScore(ta.AttemptID)) AS BestScore,
    t.MinScoreToPass
FROM Students s
JOIN Groups g ON s.GroupID = g.GroupID
JOIN TestAttempts ta ON s.StudentID = ta.StudentID
JOIN Tests t ON ta.TestID = t.TestID
WHERE ta.IsFinalized = 1
GROUP BY s.StudentID, s.LastName, s.FirstName, s.MiddleName, g.GroupName, t.TestName, t.MinScoreToPass
HAVING COUNT(ta.AttemptID) >= 3 AND MAX(dbo.fn_CalculateScore(ta.AttemptID)) < t.MinScoreToPass;
GO

-- Студенты, не приступавшие к тестированию
CREATE VIEW v_StudentsNotStarted AS
SELECT 
    s.StudentID,
    s.LastName + ' ' + s.FirstName + ' ' + ISNULL(s.MiddleName, '') AS FullName,
    g.GroupName,
    f.FacultyName,
    t.TestName,
    sub.SubjectName
FROM Students s
JOIN Groups g ON s.GroupID = g.GroupID
JOIN Faculties f ON g.FacultyID = f.FacultyID
JOIN TestGroups tg ON g.GroupID = tg.GroupID
JOIN Tests t ON tg.TestID = t.TestID
JOIN Subjects sub ON t.SubjectID = sub.SubjectID
LEFT JOIN TestAttempts ta ON s.StudentID = ta.StudentID AND ta.TestID = t.TestID
WHERE ta.AttemptID IS NULL;
GO

-- Детальный список студентов по группам с результатами тестирования
CREATE VIEW v_StudentsByGroupWithResults AS
SELECT 
    g.GroupName,
    s.StudentID,
    s.LastName + ' ' + s.FirstName + ' ' + ISNULL(s.MiddleName, '') AS FullName,
    t.TestName,
    sub.SubjectName,
    te.LastName + ' ' + te.FirstName + ' ' + ISNULL(te.MiddleName, '') AS TeacherName,
    ta.AttemptDate,
    dbo.fn_CalculateScore(ta.AttemptID) AS TotalScore,
    t.MinScoreToPass,
    CASE 
        WHEN dbo.fn_CalculateScore(ta.AttemptID) >= t.MinScoreToPass THEN N'Сдал'
        ELSE N'Не сдал'
    END AS Status,
    ROW_NUMBER() OVER (PARTITION BY s.StudentID, t.TestID ORDER BY ta.AttemptDate ASC) AS AttemptNumber
FROM Groups g
JOIN Students s ON g.GroupID = s.GroupID
LEFT JOIN TestAttempts ta ON s.StudentID = ta.StudentID AND ta.IsFinalized = 1
LEFT JOIN Tests t ON ta.TestID = t.TestID
LEFT JOIN Subjects sub ON t.SubjectID = sub.SubjectID
LEFT JOIN Teachers te ON t.TeacherID = te.TeacherID;
GO