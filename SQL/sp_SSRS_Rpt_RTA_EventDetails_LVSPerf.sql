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
	@IncludeEMPCARD int = 0,
	@ReportNum int = 0
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
	DECLARE @TopTierInt int = (select max(PriorityLevel) from SQLA_CustTiers)


	create table dbo.#LVSPerf_tmp (
		PktNum int,
		tOut datetime,
		ShiftHour int,
		ShiftOrd int,
		ShiftName varchar(50),
		CustPriorityLevel int,
		CustTierLevel varchar(10),
		CmpWS int,
		EmpNumCmp varchar(40),
		EmpNameCmp varchar(100),
		EmpJobTypeCmp varchar(20),
		DispatcherCmp int,
		SupervisorCmp int,
		GSRCmp int
	)
	
	insert into dbo.#LVSPerf_tmp (PktNum, tOut, ShiftHour, ShiftOrd, ShiftName, CustPriorityLevel, CustTierLevel, CmpWS, EmpNumCmp, EmpNameCmp, EmpJobTypeCmp, DispatcherCmp, SupervisorCmp, GSRCmp)
	select d.PktNum, d.tOut, ShiftHour = s.StartHour, ShiftOrd = s.ShiftColumn, ShiftName, d.CustPriorityLevel, d.CustTierLevel, 
		   d.CmpWS, EmpNumCmp, EmpNameCmp = isnull(rtrim(ltrim(emp.NameLast)) + ', ' + rtrim(ltrim(emp.NameFirst)),''), EmpJobTypeCmp = emp.JobType,
		   DispatcherCmp = case when CmpWS = 1 then 1 else 0 end,
		   SupervisorCmp = case when CmpWS = 2 then 1 else 0 end,
		   GSRCmp = case when CmpWS = 0 then 1 else 0 end
	  from SQLA_EventDetails as d
	  left join SQLA_ShiftHours as s
		on s.StartHour = datepart(hour,tOut)
	  left join SQLA_Employees as emp
	    on emp.CardNum = d.EmpNumCmp
	 where tOut >= @StartDt and tOut < @EndDt
	   and (TotSecs*1.0/60.0) <= @MaxCmpMins
	   and ((@IncludeOOS = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))

    
	IF @ReportNum = 0
	BEGIN
		select t.EvtMonth, EvtDay = t.EvtDay, t.TotEvtCount, t.DispatcherEvtCount, t.SupervisorEvtCount, t.GSREvtCount, t.GSRCount, t.TopTierEvtCount,
			   EmpHrsLoggedIn = sum(isnull(datediff(second, case when h.ActivityStart < EvtDay then EvtDay else h.ActivityStart end,
													        case when h.ActivityEnd > dateadd(day,1,EvtDay) then dateadd(day,1,EvtDay) else h.ActivityEnd end),0)) * 1.0 / 60.0 / 60.0
		  from (
		select EvtMonth = DATENAME(month, d.tOut),
			   EvtDay = cast(d.tOut as date),
		       TotEvtCount = count(d.PktNum),
			   DispatcherEvtCount = sum(d.DispatcherCmp),
			   SupervisorEvtCount = sum(d.SupervisorCmp),
			   GSREvtCount = sum(d.GSRCmp),
			   GSRCount = count(distinct case when d.GSRCmp = 1 then d.EmpNumCmp else null end),
			   TopTierEvtCount = sum(case when d.CustPriorityLevel = @TopTierInt then 1 else 0 end)
		  from dbo.#LVSPerf_tmp as d
		 group by DATENAME(month, d.tOut),
			   cast(d.tOut as date) ) as t 
		  left join SQLA_EmployeeEventTimes as h
		    on h.PktNum = 3
		   and ActivityEnd > EvtDay
		   and ActivityStart < dateadd(day,1,EvtDay)
		 group by t.EvtMonth, t.EvtDay, t.TotEvtCount, t.DispatcherEvtCount, t.SupervisorEvtCount, t.GSREvtCount, t.GSRCount, t.TopTierEvtCount
	END
	
	IF @ReportNum = 1
	BEGIN
		select EvtMonth = DATENAME(month, d.tOut),
		       EvtDay = cast(d.tOut as date),
			   ShiftOrd, ShiftName,
		       TotEvtCount = count(d.PktNum),
			   DispatcherEvtCount = sum(d.DispatcherCmp),
			   SupervisorEvtCount = sum(d.SupervisorCmp),
			   GSREvtCount = sum(d.GSRCmp),
			   GSRCount = count(distinct case when d.GSRCmp = 1 then d.EmpNumCmp else null end),
			   TopTierEvtCount = sum(case when d.CustPriorityLevel = @TopTierInt then 1 else 0 end)
		  from dbo.#LVSPerf_tmp as d
		 where CmpWS = 0
		 group by DATENAME(month, d.tOut), cast(d.tOut as date), ShiftOrd, ShiftName
	END
	
	IF @ReportNum = 2
	BEGIN
	    select t2.EvtMonth, t2.ShiftOrd, t2.ShiftName, t2.EmpNumCmp, t2.EmpNameCmp,
		       TotEvtCount = sum(t2.TotEvtCount), TopTierEvtCount = sum(t2.TopTierEvtCount), EmpHrsLoggedIn = sum(t2.EmpHrsLoggedIn)
		  from (
		select t.EvtMonth, t.EvtDay, t.ShiftOrd, t.ShiftName, t.EmpNumCmp, t.EmpNameCmp, 
		       t.TotEvtCount, t.TopTierEvtCount,
			   EmpHrsLoggedIn = sum(isnull(datediff(second, case when h.ActivityStart < EvtDay then EvtDay else h.ActivityStart end,
													        case when h.ActivityEnd > dateadd(day,1,EvtDay) then dateadd(day,1,EvtDay) else h.ActivityEnd end),0)) * 1.0 / 60.0 / 60.0
		  from (
		select EvtMonth = DATENAME(month, d.tOut),
		       EvtDay = cast(d.tOut as date),
			   ShiftOrd, ShiftName, EmpNumCmp, EmpNameCmp,
		       TotEvtCount = count(d.PktNum),
			   DispatcherEvtCount = sum(d.DispatcherCmp),
			   SupervisorEvtCount = sum(d.SupervisorCmp),
			   GSREvtCount = sum(d.GSRCmp),
			   GSRCount = count(distinct case when d.GSRCmp = 1 then d.EmpNumCmp else null end),
			   TopTierEvtCount = sum(case when d.CustPriorityLevel = @TopTierInt then 1 else 0 end)
		  from dbo.#LVSPerf_tmp as d
		 where CmpWS = 0
		 group by DATENAME(month, d.tOut), cast(d.tOut as date), ShiftOrd, ShiftName, EmpNumCmp, EmpNameCmp ) as t 
		  left join SQLA_EmployeeEventTimes as h
		    on h.PktNum = 3
		   and EmpNum = EmpNumCmp
		   and ActivityEnd > EvtDay
		   and ActivityStart < dateadd(day,1,EvtDay)
		 group by t.EvtMonth, t.EvtDay, t.ShiftOrd, t.ShiftName, t.EmpNumCmp, t.EmpNameCmp, t.TotEvtCount, t.TopTierEvtCount ) as t2
		 group by t2.EvtMonth, t2.ShiftOrd, t2.ShiftName, t2.EmpNumCmp, t2.EmpNameCmp
	END
	       
END
GO
