USE [RTA_SQLA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EmpTransactionSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EmpTransactionSummary]
GO

CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EmpTransactionSummary]
	@StartDt datetime,
	@EndDt datetime,
	@EmpNum nvarchar(40) = '',
	@EmpJobType varchar(20) = '',
	@IncludeEMPCARD int = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select EmpNum, EmpName, ShiftStartTm, IsDualRate, IsPartTime,
	       LoginSeconds = sum(LoginSeconds),
		   LoginHours = sum(LoginSeconds)*1.0/60.0/60.0,
		   RspSecs = sum(RspSecs),
		   RspEvts = sum(RspEvts),
		   RspSecsAvg = case when sum(RspEvts) = null or sum(RspEvts) = 0 then 0 else sum(RspSecs)*1.0 / sum(RspEvts)*1.0 end,
		   CmpSecs = sum(CmpSecs),
		   CmpEvts = sum(CmpEvts),
		   CmpSecsAvg = case when sum(CmpEvts) = null or sum(CmpEvts) = 0 then 0 else sum(CmpSecs)*1.0 / sum(CmpEvts)*1.0 end,
		   EvtsPerHour = sum(CmpEvts)*1.0 / (sum(LoginSeconds)*1.0/60.0/60.0)
	  from (
	select EmpNum = emp.CardNum, 
	       EmpName = '(' + left(emp.JobType,1) + ') ' + emp.NameFirst + ' ' + left(emp.NameLast,1) + '.',
		   ShiftStartTm = emp.ShiftStartTm,
		   IsDualRate = emp.IsDualRate,
		   IsPartTime = emp.IsPartTime,
		   l.ActivityStart,
		   l.ActivityEnd,
		   LoginSeconds = datediff(s,l.ActivityStart,l.ActivityEnd),
		   RspSecs = sum(case when e.tRsp is null then 0 else datediff(s,isnull(e.tAsn,e.ActivityStart),e.tRsp) end),
		   RspEvts = count(distinct (case when e.tRsp is not null then e.PktNum else null end)),
		   CmpSecs = sum(case when e.tCmp is null then 0 else datediff(s,isnull(isnull(e.tRsp,e.tAsn),e.ActivityStart),e.tCmp) end),
		   CmpEvts = count(distinct (case when e.tCmp is not null then e.PktNum else null end))
	  from SQLA_Employees as emp
	 inner join SQLA_EmployeeEventTimes as l
	    on l.EmpNum = emp.CardNum
	  left join SQLA_EmployeeEventTimes as e
		on e.EmpNum = l.EmpNum
	   and e.ActivityStart <= l.ActivityEnd
	   and e.ActivityEnd >= l.ActivityStart
	   and e.PktNum not in (1,2,3)
	   and ((@IncludeEMPCARD = 0 and e.EventDisplay not like 'EMPCARD%') or (@IncludeEMPCARD = 1))
	 where (l.PktNum = 3)
	   and (l.ActivityStart <= @EndDt and l.ActivityEnd >= @StartDt)
	   and (l.EmpNum = @EmpNum or @EmpNum = '' or @EmpNum = 'All')
	   and (l.EmpJobType = @EmpJobType or @EmpJobType = '' or @EmpJobType = 'All')
	 group by emp.CardNum, emp.JobType, emp.NameFirst, emp.NameLast, emp.ShiftStartTm, emp.IsDualRate, emp.IsPartTime, l.ActivityStart, l.ActivityEnd ) as t
	 group by EmpNum, EmpName, ShiftStartTm, IsDualRate, IsPartTime
END
GO
