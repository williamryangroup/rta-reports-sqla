USE [RTA_SQLA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EmpLogins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EmpLogins]
GO

CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EmpLogins]
	@StartDt datetime,
	@EndDt datetime,
	@EmpNum nvarchar(40) = '',
	@EmpJobType varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select EmpName = '(' + left(l.EmpJobType,1) + ') ' + l.EmpNameFirst + ' ' + left(l.EmpNameLast,1) + '.',
		   l.EmpNum,
		   LoginTm = l.ActivityStart,
		   LogoutTm = l.ActivityEnd,
		   BreakStartTm = b.ActivityStart, 
		   BreakEndTm = b.ActivityEnd,
		   BreakDuration = datediff(s,b.ActivityStart,b.ActivityEnd)/60.0
	  from SQLA_EmployeeEventTimes as l
	  left join SQLA_EmployeeEventTimes as b
		on b.EmpNum = l.EmpNum
	   and b.ActivityStart <= l.ActivityEnd
	   and b.ActivityEnd >= l.ActivityStart
	   and b.PktNum = 1
	 where (l.PktNum = 3)
	   and (l.ActivityStart <= @EndDt and l.ActivityEnd >= @StartDt)
	   and (l.EmpNum = @EmpNum or @EmpNum = '')
	   and (l.EmpJobType = @EmpJobType or @EmpJobType = '' or @EmpJobType = 'All')	
END
GO
