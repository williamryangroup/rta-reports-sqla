USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_LVSPerf]    Script Date: 02/17/2016 21:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_LVSPerf]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_LVSPerf]
GO

CREATE PROCEDURE sp_SSRS_Rpt_RTA_EventDetails_LVSPerf
	@MonthInt int = 0,
	@MaxCmpMins int = 120,
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @CurMonthInt int = month(getdate()), @CurYearInt int = year(getdate())
	DECLARE @StartDt datetime = cast(cast(@MonthInt as varchar) + '-1-' + cast(@CurYearInt as varchar) as datetime)
	

	if(@CurMonthInt < @MonthInt)
	begin
		set @StartDt = dateadd(year,-1,@StartDt)
	end

	DECLARE @EndDt datetime = dateadd(month,1,@StartDt)


	select EvtDay = cast(d.tOut as date),
		   EvtMonth = DATENAME(month, d.tOut),
		   ShiftOrd = s.ShiftColumn,
		   s.ShiftName,
		   d.PktNum,
		   d.CustTierLevel,
		   d.CustPriorityLevel,
		   d.EmpNumCmp,
		   EmpNameCmp = isnull(rtrim(ltrim(emp.NameLast)) + ', ' + rtrim(ltrim(emp.NameFirst)),''),
		   EmpJobTypeCmp = isnull(emp.JobType,''),
		   d.CmpWS,
		   HoursLoggedIn = sum(isnull(datediff(second, case when es.tStart < @StartDt then @StartDt else es.tStart end,
		                                              case when es.tEnd > @EndDt then @EndDt else es.tEnd end),0)) * 1.0 / 60.0 / 60.0
	  from SQLA_EventDetails as d
	  left join SQLA_ShiftHours as s
		on s.StartHour = datepart(hour,tOut)
	  left join SQLA_Employees as emp
	    on emp.CardNum = d.EmpNumCmp
	  left join SQLA_EmployeeStatus as es
	    on es.EmpNum = d.EmpNumCmp
	   and es.tStart < @EndDt
	   and es.tEnd > @StartDt
	   and es.Status = 'Login'
	 where tOut >= @StartDt and tOut < @EndDt
	   and (TotSecs*1.0/60.0) <= @MaxCmpMins
	   and ((@IncludeOOS = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	 group by cast(d.tOut as date),
	       DATENAME(month, d.tOut),
		   s.ShiftColumn,
		   s.ShiftName,
		   d.PktNum,
		   d.CustTierLevel,
		   d.CustPriorityLevel,
		   d.EmpNumCmp,
		   emp.NameFirst,
		   emp.NameLast,
		   emp.JobType,
		   d.CmpWS
	       
END
GO
