USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmployeeStatus_Initial]    Script Date: 06/21/2016 13:58:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmployeeStatus_Initial]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmployeeStatus_Initial]
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmployeeStatus_Initial]
	@StartDt datetime = null

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	TRUNCATE TABLE SQLA_EmployeeStatus

/*
	INSERT INTO SQLA_EmployeeStatus (EmpNum, EmpNameFirst, EmpNameLast, Status, tStart, tEnd, StatusCode)
	SELECT EmpNum = a.CardNum, EmpNameFirst = a.NameFirst, EmpNameLast = a.NameLast, a.Status, tStart = min(a.tStart), a.tEnd, a.StatusCode
	  FROM (
	SELECT s.CardNum, s.NameFirst, s.NameLast, 
		   Status = case when s.Activity like 'MULTI EVENT: YES%' then 'Multi Event'
						 when s.Activity like 'JP ONLY: YES%' then 'JP Only'
						 when s.Activity like 'Login%' then 'Login'
						 else s.Activity end,
		   tStart = s.tOut, tEnd = min(e.tOut),
		   StatusCode = case when s.Activity like 'MULTI EVENT: YES%' then 'M'
						     when s.Activity like 'JP ONLY: YES%' then 'J'
						     else '' end
	  FROM RTSS.dbo.EMPLOYEEACTIVITY1 as s WITH (NOLOCK)
	 inner join RTSS.dbo.EMPLOYEEACTIVITY1 as e WITH (NOLOCK)
		on e.CardNum = s.CardNum
	   and e.tOut > s.tOut
	 WHERE (s.tOut > '1/2/1980' and e.tOut > '1/2/1980')
	   and (s.Activity like 'MULTI EVENT: YES%' or s.Activity like 'JP ONLY: YES%' or s.Activity like 'Login%')
	   and (    (s.Activity like 'MULTI EVENT: YES%' and e.Activity like 'MULTI EVENT: NO%')
			 or (s.Activity like 'JP ONLY: YES%' and e.Activity like 'JP ONLY: NO%')
			 or (e.Activity like 'Logout%' or e.Activity like 'End Shift%') )
	 GROUP BY s.CardNum, s.NameFirst, s.NameLast, s.Activity, s.tOut ) as a
	 GROUP BY a.CardNum, a.NameFirst, a.NameLast, a.Status, a.tEnd, a.StatusCode

*/

	INSERT INTO SQLA_EmployeeStatus (EmpNum, EmpNameFirst, EmpNameLast, Status, tStart, tEnd, StatusCode, JobType)
	SELECT EmpNum = a.CardNum, EmpNameFirst = a.NameFirst, EmpNameLast = a.NameLast, a.Status, tStart = min(a.tStart), a.tEnd, a.StatusCode, a.JobType
	  FROM (
	SELECT CardNum = s.EmpNum, emp.NameFirst, emp.NameLast, Status = 'Login',
	       tStart = s.tOut, tEnd = min(e.tOut), StatusCode = '', emp.JobType
	  FROM SQLA_FloorActivity as s WITH (NOLOCK)
	 inner join SQLA_FloorActivity as e WITH (NOLOCK)
		on e.EmpNum = s.EmpNum
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 WHERE (@StartDt = null or s.tOut >= @StartDt)
	   AND (s.tOut > '1/2/1980' and e.tOut > '1/2/1980')
	   AND s.ActivityTypeID = 3 and s.State = 'Login'
	   AND e.ActivityTypeID = 3 and e.State = 'Logout'
	 GROUP BY s.EmpNum, emp.NameFirst, emp.NameLast, s.tOut, emp.JobType ) as a
	 GROUP BY a.CardNum, a.NameFirst, a.NameLast, a.Status, a.tEnd, a.StatusCode, a.JobType

	 
	INSERT INTO SQLA_EmployeeStatus (EmpNum, EmpNameFirst, EmpNameLast, Status, tStart, tEnd, StatusCode, JobType)
	SELECT t.EmpNum, t.NameFirst, t.NameLast, Status = Activity, t.tStart, t.tEnd, StatusCode = left(z.ZoneArea,2), t.JobType
	  FROM (
	SELECT s.EmpNum, j.NameFirst, j.NameLast, j.JobType, Activity = rtrim(s.Activity), tStart = s.tOut, tEnd = min(e.tOut)
	  FROM SQLA_FloorActivity as s WITH (NOLOCK)
	 INNER JOIN SQLA_FloorActivity as e WITH (NOLOCK)
		ON e.EmpNum = s.EmpNum
	   AND e.tOut > s.tOut
	  LEFT JOIN SQLA_Employees as j WITH (NOLOCK)
		ON j.CardNum = s.EmpNum
	 WHERE (@StartDt = null or s.tOut >= @StartDt)
	   AND (s.tOut > '1/2/1980' and e.tOut > '1/2/1980')
	   AND (s.ActivityTypeID = 4 and s.Activity like 'Zones Served:%' and rtrim(s.Activity) <> 'Zones Served:')
	   AND ((e.ActivityTypeID = 4 and e.Activity like 'Zones Served:%') or (e.ActivityTypeID = 3 and e.State = 'Logout'))
	 GROUP BY s.EmpNum, j.NameFirst, j.NameLast, j.JobType, s.Activity, s.tOut ) as t
	 --INNER JOIN (select distinct ZoneArea = rtrim(ZoneArea) from SQLA_ZoneArea WITH (NOLOCK)) as z
	 --   ON charindex(z.ZoneArea,t.Activity,13) > 0
	 INNER JOIN (select distinct ZoneArea, ZoneAreaLike = '% ' + rtrim(ZoneArea) from SQLA_ZoneArea WITH (NOLOCK)
	              union all
				 select distinct ZoneArea, ZoneAreaLike = '% '+rtrim(ZoneArea)+',%' from SQLA_ZoneArea WITH (NOLOCK)
	              union all
				 select distinct ZoneArea, ZoneAreaLike = '%,'+rtrim(ZoneArea)+',%' from SQLA_ZoneArea WITH (NOLOCK)
	              union all
				 select distinct ZoneArea, ZoneAreaLike = '%,'+rtrim(ZoneArea) from SQLA_ZoneArea WITH (NOLOCK) ) as z
		ON t.Activity like z.ZoneAreaLike
END

GO


