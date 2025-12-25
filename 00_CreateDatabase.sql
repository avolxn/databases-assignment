-- Создание базы данных
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'StudentTestingDB')
BEGIN
    ALTER DATABASE StudentTestingDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE StudentTestingDB;
END
GO

CREATE DATABASE StudentTestingDB;
GO