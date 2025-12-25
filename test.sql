USE StudentTestingDB;
GO

-- Баллы студентов группы ЭК-24-1 по математике
SELECT 
    s.LastName + ' ' + s.FirstName AS Студент,
    dbo.fn_CalculateScore(ta.AttemptID) AS Балл,
    ta.AttemptDate AS Дата
FROM Students s
JOIN Groups g ON s.GroupID = g.GroupID
JOIN TestAttempts ta ON s.StudentID = ta.StudentID
JOIN Tests t ON ta.TestID = t.TestID
WHERE g.GroupName = N'ЭК-24-1' 
  AND t.TestName = N'Математика'
  AND ta.IsFinalized = 1
ORDER BY s.LastName;
GO
