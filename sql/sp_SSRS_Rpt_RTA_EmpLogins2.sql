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
	
	select EmpNum = emp.CardNum, 
	       EmpName = '(' + left(emp.JobType,1) + ') ' + emp.NameFirst + ' ' + left(emp.NameLast,1) + '.',
		   ShiftStartTm = emp.ShiftStartTm,
		   IsDualRate = emp.IsDualRate,
		   IsPartTime = emp.IsPartTime,
		   LoginTm = l.ActivityStart,
		   LogoutTm = l.ActivityEnd,
		   BreakStartTm = b.ActivityStart, 
		   BreakEndTm = b.ActivityEnd,
		   BreakDuration = datediff(s,b.ActivityStart,b.ActivityEnd)/60.0,
		   BreakSeconds = datediff(s,b.ActivityStart,b.ActivityEnd),
		   LoginSeconds = datediff(s,l.ActivityStart,l.ActivityEnd),
		   PktNum = e.PktNum,
		   RspSecs = datediff(s,isnull(e.tAsn,e.ActivityStart),e.tRsp),
		   CmpSecs = datediff(s,isnull(isnull(e.tRsp,e.tAsn),e.ActivityStart),e.tCmp),
		   OvrlSecs = datediff(s,e.ActivityStart,e.ActivityEnd)
	  from SQLA_Employees as emp
	 inner join SQLA_EmployeeEventTimes as l
	    on l.EmpNum = emp.CardNum
	  left join SQLA_EmployeeEventTimes as b
		on b.EmpNum = l.EmpNum
	   and b.ActivityStart <= l.ActivityEnd
	   and b.ActivityEnd >= l.ActivityStart
	   and b.PktNum = 1
	  left join SQLA_EmployeeEventTimes as e
		on e.EmpNum = l.EmpNum
	   and e.ActivityStart <= l.ActivityEnd
	   and e.ActivityEnd >= l.ActivityStart
	   and e.PktNum not in (1,2,3)
	 where (l.PktNum = 3)
	   and (l.ActivityStart <= @EndDt and l.ActivityEnd >= @StartDt)
	   and (l.EmpNum = @EmpNum or @EmpNum = '' or @EmpNum = 'All')
	   and (l.EmpJobType = @EmpJobType or @EmpJobType = '' or @EmpJobType = 'All')
END
GO
