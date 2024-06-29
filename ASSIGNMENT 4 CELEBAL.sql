--SRUTI PRAKASH BEHERA
-- Drop foreign key constraints and tables if they exist
IF OBJECT_ID('dbo.StudentPreference', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.StudentPreference;
END
GO

IF OBJECT_ID('dbo.Allotments', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Allotments;
END
GO

IF OBJECT_ID('dbo.UnallotedStudents', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.UnallotedStudents;
END
GO

IF OBJECT_ID('dbo.SubjectDetails', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.SubjectDetails;
END
GO

IF OBJECT_ID('dbo.StudentDetails', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.StudentDetails;
END
GO

-- Drop the stored procedure if it exists
IF OBJECT_ID('dbo.AllocateElectiveSubjects', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.AllocateElectiveSubjects;
END
GO
-- Create the StudentDetails table
CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName VARCHAR(50),
    GPA FLOAT,
    Branch VARCHAR(10),
    Section VARCHAR(10)
);
GO

-- Create the SubjectDetails table
CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);
GO

-- Create the StudentPreference table
CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId VARCHAR(10),
    Preference INT,
    PRIMARY KEY (StudentId, SubjectId, Preference),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);
GO

-- Create the Allotments table
CREATE TABLE Allotments (
    SubjectId VARCHAR(10),
    StudentId INT,
    PRIMARY KEY (SubjectId, StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);
GO

-- Create the UnallotedStudents table
CREATE TABLE UnallotedStudents (
    StudentId INT PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);
GO

-- Insert sample data into StudentDetails
INSERT INTO StudentDetails (StudentId, StudentName, GPA, Branch, Section) VALUES
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');
GO

-- Insert sample data into SubjectDetails
INSERT INTO SubjectDetails (SubjectId, SubjectName, MaxSeats, RemainingSeats) VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);
GO

-- Insert sample data into StudentPreference
INSERT INTO StudentPreference (StudentId, SubjectId, Preference) VALUES
(159103036, 'PO1491', 1),
(159103036, 'PO1492', 2),
(159103036, 'PO1493', 3),
(159103036, 'PO1494', 4),
(159103036, 'PO1495', 5),
(159103037, 'PO1492', 1),
(159103037, 'PO1494', 2),
(159103037, 'PO1493', 3),
(159103037, 'PO1491', 4),
(159103037, 'PO1495', 5),
(159103038, 'PO1493', 1),
(159103038, 'PO1494', 2),
(159103038, 'PO1492', 3),
(159103038, 'PO1495', 4),
(159103038, 'PO1491', 5),
(159103039, 'PO1492', 1),
(159103039, 'PO1491', 2),
(159103039, 'PO1494', 3),
(159103039, 'PO1495', 4),
(159103039, 'PO1493', 5),
(159103040, 'PO1495', 1),
(159103040, 'PO1494', 2),
(159103040, 'PO1492', 3),
(159103040, 'PO1491', 4),
(159103040, 'PO1493', 5);
GO
-- Create the stored procedure for allocating subjects
CREATE PROCEDURE AllocateElectiveSubjects
AS
BEGIN
    DECLARE @StudentId INT, @GPA FLOAT;
    DECLARE @SubjectId VARCHAR(10), @RemainingSeats INT;
    DECLARE @Preference INT;
    
    -- Cursor for iterating through students ordered by GPA
    DECLARE student_cursor CURSOR FOR
    SELECT StudentId, GPA
    FROM StudentDetails
    ORDER BY GPA DESC;
    
    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Preference = 1;
        
        WHILE @Preference <= 5
        BEGIN
            SELECT @SubjectId = SubjectId
            FROM StudentPreference
            WHERE StudentId = @StudentId AND Preference = @Preference;
            
            IF @SubjectId IS NOT NULL
            BEGIN
                SELECT @RemainingSeats = RemainingSeats
                FROM SubjectDetails
                WHERE SubjectId = @SubjectId;
                
                IF @RemainingSeats > 0
                BEGIN
                    -- Allocate the subject to the student
                    INSERT INTO Allotments (SubjectId, StudentId)
                    VALUES (@SubjectId, @StudentId);
                    
                    -- Update the remaining seats
                    UPDATE SubjectDetails
                    SET RemainingSeats = RemainingSeats - 1
                    WHERE SubjectId = @SubjectId;
                    
                    BREAK;
                END
            END
            
            SET @Preference = @Preference + 1;
        END
        
        -- If no subjects could be allocated, mark the student as unallotted
        IF @Preference > 5
        BEGIN
            INSERT INTO UnallotedStudents (StudentId)
            VALUES (@StudentId);
        END
        
        FETCH NEXT FROM student_cursor INTO @StudentId, @GPA;
    END
    
    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END;
GO
-- Execute the stored procedure to perform the allocation
EXEC AllocateElectiveSubjects;
GO
-- Check the allotments
SELECT * FROM Allotments;
GO

-- Check the unallotted students
SELECT * FROM UnallotedStudents;
GO