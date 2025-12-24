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

-- Отчет по успеваемости групп
CREATE VIEW v_GroupResults AS
SELECT 
    g.GroupName,
    t.TestName,
    AVG(CAST(ta.TotalScore AS DECIMAL(5,2))) AS AverageGroupScore,
    COUNT(DISTINCT ta.StudentID) AS StudentsTested
FROM Groups g
JOIN Students s ON g.GroupID = s.GroupID
JOIN TestAttempts ta ON s.StudentID = ta.StudentID
JOIN Tests t ON ta.TestID = t.TestID
WHERE ta.IsFinalized = 1
GROUP BY g.GroupName, t.TestName;
GO

-- Студенты, не прошедшие тест после 3 попыток
CREATE VIEW v_FailedStudents AS
SELECT 
    s.LastName + ' ' + s.FirstName + ' ' + ISNULL(s.MiddleName, '') AS FullName,
    g.GroupName,
    t.TestName,
    COUNT(ta.AttemptID) AS AttemptsCount,
    MAX(ta.TotalScore) AS BestScore,
    t.MinScoreToPass
FROM Students s
JOIN Groups g ON s.GroupID = g.GroupID
JOIN TestAttempts ta ON s.StudentID = ta.StudentID
JOIN Tests t ON ta.TestID = t.TestID
WHERE ta.IsFinalized = 1
GROUP BY s.StudentID, s.LastName, s.FirstName, s.MiddleName, g.GroupName, t.TestName, t.MinScoreToPass
HAVING COUNT(ta.AttemptID) >= 3 AND MAX(ta.TotalScore) < t.MinScoreToPass;
GO

-- Студенты, не приступавшие к тестированию
CREATE VIEW v_StudentsNotStarted AS
SELECT 
    s.StudentID,
    s.LastName + ' ' + s.FirstName + ' ' + ISNULL(s.MiddleName, '') AS FullName,
    g.GroupName
FROM Students s
JOIN Groups g ON s.GroupID = g.GroupID
LEFT JOIN TestAttempts ta ON s.StudentID = ta.StudentID
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
    ta.TotalScore,
    t.MinScoreToPass,
    CASE 
        WHEN ta.TotalScore >= t.MinScoreToPass THEN N'Сдал'
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

PRINT 'Представления успешно созданы!';
GO
