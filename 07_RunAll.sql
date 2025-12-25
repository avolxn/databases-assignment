USE StudentTestingDB;
GO

-- Проверка таблиц
PRINT 'Таблицы:';
SELECT TABLE_NAME, 
       (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Проверка представлений
SELECT TABLE_NAME AS ViewName
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_NAME;

-- Проверка функций
PRINT 'Функции:';
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION'
ORDER BY ROUTINE_NAME;

-- Проверка процедур
PRINT 'Хранимые процедуры:';
SELECT ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;

-- Проверка триггеров
PRINT 'Триггеры:';
SELECT name AS TriggerName, 
       OBJECT_NAME(parent_id) AS TableName,
       is_disabled AS IsDisabled
FROM sys.triggers
WHERE parent_class = 1
ORDER BY name;

-- Количество записей в таблицах
PRINT 'Количество записей в таблицах:';
SELECT 'Faculties' AS TableName, COUNT(*) AS RecordCount FROM Faculties
UNION ALL SELECT 'Groups', COUNT(*) FROM Groups
UNION ALL SELECT 'Students', COUNT(*) FROM Students
UNION ALL SELECT 'Teachers', COUNT(*) FROM Teachers
UNION ALL SELECT 'Subjects', COUNT(*) FROM Subjects
UNION ALL SELECT 'Tests', COUNT(*) FROM Tests
UNION ALL SELECT 'Questions', COUNT(*) FROM Questions
UNION ALL SELECT 'Answers', COUNT(*) FROM Answers
UNION ALL SELECT 'TestAttempts', COUNT(*) FROM TestAttempts
UNION ALL SELECT 'StudentAnswers', COUNT(*) FROM StudentAnswers;
