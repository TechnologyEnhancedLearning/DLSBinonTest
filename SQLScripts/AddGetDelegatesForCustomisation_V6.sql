/****** Object:  StoredProcedure [dbo].[GetDelegatesForCustomisation_V5]    Script Date: 23/11/2021 13:45:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Kevin Whittaker
-- Create date: 02/07/2019
-- Description:	Returns data for Course Delegates grid. 
-- V3 limits to only one customisation to allow nested grid view implementation.
-- V4 adds admin category ID parameter
-- V6 23/11/2021 includes CourseField1PromptID in return schema
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[GetDelegatesForCustomisation_V6]
	-- Add the parameters for the stored procedure here
	@CustomisationID Int,
	@CentreID Int,
	@AdminCategoryID Int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ProgressID, CourseName, CandidateID, LastName + ', ' + FirstName AS DelegateName, Email, SelfReg, DateRegistered, CandidateNumber, SubmittedTime AS LastUpdated, 
                  Active, AliasID, JobGroupID,
                      (SELECT JobGroupName
                       FROM      JobGroups
                       WHERE   (JobGroupID = q2.JobGroupID)) AS JobGroupName, Completed, RemovedDate, Logins, Duration, Passes, Attempts, PLLocked, CASE WHEN q2.Attempts = 0 THEN NULL 
                  ELSE q2.PassRate END AS PassRatio, DiagnosticScore, CustomisationID, Answer1, Answer2, Answer3, Answer4, Answer5, Answer6, CompleteByDate, CourseAnswer1, CourseAnswer2, CourseAnswer3, CourseField1PromptID
FROM     (SELECT ProgressID, CourseName, CandidateID, FirstName, LastName, Email, SelfReg, DateRegistered, CandidateNumber, SubmittedTime, Active, AliasID, JobGroupID, 
                                    Completed, RemovedDate, Logins, Duration, Attempts, Passes, CASE WHEN q1.Attempts = 0 THEN 0.0 ELSE 100.0 * CAST(q1.Passes AS float) / CAST(q1.Attempts AS float) 
                                    END AS PassRate, DiagnosticScore, CustomisationID, PLLocked, Answer1, Answer2, Answer3, Answer4, Answer5, Answer6, CompleteByDate, CourseAnswer1, CourseAnswer2, CourseAnswer3, CourseField1PromptID
                  FROM      (SELECT        p.ProgressID, dbo.GetCourseNameByCustomisationID(p.CustomisationID) AS CourseName, c.CandidateID, c.FirstName, c.LastName, c.EmailAddress AS Email, c.SelfReg, p.FirstSubmittedTime AS DateRegistered, 
                         c.CandidateNumber, c.Active, c.AliasID, c.JobGroupID, p.SubmittedTime, p.Completed, p.RemovedDate, p.DiagnosticScore, p.CustomisationID, p.LoginCount AS Logins, p.Duration,
                             (SELECT        COUNT(*) AS Expr1
                               FROM            AssessAttempts AS a
                               WHERE        (ProgressID = p.ProgressID)) AS Attempts,
                             (SELECT        SUM(CAST(Status AS int)) AS Expr1
                               FROM            AssessAttempts AS a1
                               WHERE        (ProgressID = p.ProgressID)) AS Passes, p.PLLocked, c.Answer1, c.Answer2, c.Answer3, c.Answer4, c.Answer5, c.Answer6, p.CompleteByDate, p.Answer1 AS CourseAnswer1, p.Answer2 AS CourseAnswer2, 
                         p.Answer3 AS CourseAnswer3, cu.CourseField1PromptID
FROM            Candidates AS c INNER JOIN
                         Progress AS p ON c.CandidateID = p.CandidateID INNER JOIN
                                         Customisations AS cu ON p.CustomisationID = cu.CustomisationID
WHERE        (p.CustomisationID = @CustomisationID) AND (c.CentreID = @CentreID) OR
                         (p.CustomisationID IN
                             (SELECT        CustomisationID
                               FROM            Customisations AS c1
                               WHERE        (CentreID = @CentreID))) AND (@AdminCategoryID = 0) AND (CAST(@CustomisationID AS Int) < 1) AND (c.CentreID = @CentreID) OR
                         (p.CustomisationID IN
                             (SELECT        CustomisationID
                               FROM            Customisations AS c1
                               WHERE        (CentreID = @CentreID))) AND (CAST(@CustomisationID AS Int) < 1) AND
                             ((SELECT        a.CourseCategoryID
                                 FROM            Applications AS a INNER JOIN
                                                          Customisations AS cu ON a.ApplicationID = cu.ApplicationID
                                 WHERE        (cu.CustomisationID = p.CustomisationID)) = @AdminCategoryID) AND (c.CentreID = @CentreID)) AS q1) AS q2
ORDER BY LastName, FirstName
END


