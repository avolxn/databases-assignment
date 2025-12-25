USE StudentTestingDB;
GO

-- Удаление существующих таблиц
IF OBJECT_ID('StudentAnswers', 'U') IS NOT NULL DROP TABLE StudentAnswers;
IF OBJECT_ID('TestAttempts', 'U') IS NOT NULL DROP TABLE TestAttempts;
IF OBJECT_ID('TestGroups', 'U') IS NOT NULL DROP TABLE TestGroups;
IF OBJECT_ID('Answers', 'U') IS NOT NULL DROP TABLE Answers;
IF OBJECT_ID('Questions', 'U') IS NOT NULL DROP TABLE Questions;
IF OBJECT_ID('Tests', 'U') IS NOT NULL DROP TABLE Tests;
IF OBJECT_ID('Students', 'U') IS NOT NULL DROP TABLE Students;
IF OBJECT_ID('Groups', 'U') IS NOT NULL DROP TABLE Groups;
IF OBJECT_ID('Faculties', 'U') IS NOT NULL DROP TABLE Faculties;
IF OBJECT_ID('Subjects', 'U') IS NOT NULL DROP TABLE Subjects;
IF OBJECT_ID('Teachers', 'U') IS NOT NULL DROP TABLE Teachers;
GO

-- 1. Факультеты
CREATE TABLE Faculties (
    FacultyID INT IDENTITY(1,1) PRIMARY KEY,
    FacultyName NVARCHAR(100) NOT NULL
);
GO

-- 2. Группы
CREATE TABLE Groups (
    GroupID INT IDENTITY(1,1) PRIMARY KEY,
    GroupName NVARCHAR(20) NOT NULL,
    FacultyID INT NOT NULL,
    CONSTRAINT FK_Groups_FacultyID FOREIGN KEY (FacultyID) 
        REFERENCES Faculties(FacultyID) ON DELETE CASCADE
);
GO

-- 3. Студенты
CREATE TABLE Students (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    LastName NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    GroupID INT NOT NULL,
    Email NVARCHAR(100) NULL,
    CONSTRAINT FK_Students_GroupID FOREIGN KEY (GroupID) 
        REFERENCES Groups(GroupID) ON DELETE CASCADE
);
GO

-- 4. Преподаватели
CREATE TABLE Teachers (
    TeacherID INT IDENTITY(1,1) PRIMARY KEY,
    LastName NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    Email NVARCHAR(100) NULL
);
GO

-- 5. Дисциплины
CREATE TABLE Subjects (
    SubjectID INT IDENTITY(1,1) PRIMARY KEY,
    SubjectName NVARCHAR(100) NOT NULL
);
GO

-- 6. Тесты
CREATE TABLE Tests (
    TestID INT IDENTITY(1,1) PRIMARY KEY,
    TestName NVARCHAR(100) NOT NULL,
    SubjectID INT NOT NULL,
    TeacherID INT NOT NULL,
    MinScoreToPass INT DEFAULT 50,
    CONSTRAINT FK_Tests_SubjectID FOREIGN KEY (SubjectID) 
        REFERENCES Subjects(SubjectID) ON DELETE CASCADE,
    CONSTRAINT FK_Tests_TeacherID FOREIGN KEY (TeacherID) 
        REFERENCES Teachers(TeacherID) ON DELETE CASCADE
);
GO

-- 7. Вопросы
CREATE TABLE Questions (
    QuestionID INT IDENTITY(1,1) PRIMARY KEY,
    TestID INT NOT NULL,
    QuestionText NVARCHAR(MAX) NOT NULL,
    Points INT DEFAULT 1,
    CONSTRAINT FK_Questions_TestID FOREIGN KEY (TestID) 
        REFERENCES Tests(TestID) ON DELETE CASCADE
);
GO

-- 8. Варианты ответов
CREATE TABLE Answers (
    AnswerID INT IDENTITY(1,1) PRIMARY KEY,
    QuestionID INT NOT NULL,
    AnswerText NVARCHAR(MAX) NOT NULL,
    IsCorrect BIT DEFAULT 0,
    CONSTRAINT FK_Answers_QuestionID FOREIGN KEY (QuestionID) 
        REFERENCES Questions(QuestionID) ON DELETE CASCADE
);
GO

-- 9. Попытки прохождения теста
CREATE TABLE TestAttempts (
    AttemptID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    TestID INT NOT NULL,
    AttemptDate DATETIME DEFAULT GETDATE(),
    IsFinalized BIT DEFAULT 0,
    CONSTRAINT FK_TestAttempts_StudentID FOREIGN KEY (StudentID) 
        REFERENCES Students(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_TestAttempts_TestID FOREIGN KEY (TestID) 
        REFERENCES Tests(TestID) ON DELETE CASCADE
);
GO

-- 10. Ответы студентов
CREATE TABLE StudentAnswers (
    StudentAnswerID INT IDENTITY(1,1) PRIMARY KEY,
    AttemptID INT NOT NULL,
    QuestionID INT NOT NULL,
    AnswerID INT NOT NULL,
    CONSTRAINT FK_StudentAnswers_AttemptID FOREIGN KEY (AttemptID) 
        REFERENCES TestAttempts(AttemptID) ON DELETE CASCADE,
    CONSTRAINT FK_StudentAnswers_QuestionID FOREIGN KEY (QuestionID) 
        REFERENCES Questions(QuestionID) ON DELETE NO ACTION,
    CONSTRAINT FK_StudentAnswers_AnswerID FOREIGN KEY (AnswerID) 
        REFERENCES Answers(AnswerID) ON DELETE NO ACTION
);
GO

-- 11. Связь тестов и групп
CREATE TABLE TestGroups (
    TestGroupID INT IDENTITY(1,1) PRIMARY KEY,
    TestID INT NOT NULL,
    GroupID INT NOT NULL,
    CONSTRAINT FK_TestGroups_TestID FOREIGN KEY (TestID) 
        REFERENCES Tests(TestID) ON DELETE CASCADE,
    CONSTRAINT FK_TestGroups_GroupID FOREIGN KEY (GroupID) 
        REFERENCES Groups(GroupID) ON DELETE CASCADE,
    CONSTRAINT UQ_TestGroups_TestID_GroupID UNIQUE(TestID, GroupID)
);
GO
