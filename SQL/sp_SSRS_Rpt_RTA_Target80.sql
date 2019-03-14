USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Target80]    Script Date: 06/27/2016 13:45:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Target80]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Target80]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Target80]
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@EventType varchar(2000) = '',
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@CustNum varchar(40) = '',
	@MinRspMins int = 0,
	@MinCmpMins int = 0,
	@MinOverallMins int = 0,
	@ResDesc int = 0,
	@MinRspSecs int = 0,
	@MaxRspSecs int = 0,
	@MinCmpSecs int = 0,
	@MaxCmpSecs int = 0,
	@Location varchar(2000) = '',
	@Hour int = null,
	@RspMins int = 0,
	@EmpNum varchar(40) = '',
	@EmpCmpJobType varchar(2000) = '',
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @MaxCmpMins1 int = @MaxCmpMins
	DECLARE @EventType1 varchar(2000) = @EventType
	DECLARE @ZoneArea1 varchar(255) = @ZoneArea
	DECLARE @CustTier1 varchar(255) = @CustTier
	DECLARE @CustNum1 varchar(40) = @CustNum
	DECLARE @MinRspMins1 int = @MinRspMins
	DECLARE @MinCmpMins1 int = @MinCmpMins
	DECLARE @MinOverallMins1 int = @MinOverallMins
	DECLARE @ResDesc1 int = @ResDesc
	DECLARE @MinRspSecs1 int = @MinRspSecs
	DECLARE @MaxRspSecs1 int = @MaxRspSecs
	DECLARE @MinCmpSecs1 int = @MinCmpSecs
	DECLARE @MaxCmpSecs1 int = @MaxCmpSecs	
	DECLARE @EmpCmpJobType1 varchar(2000) = @EmpCmpJobType
	
	CREATE TABLE dbo.#RTA_EventDetails_Tmp (
		PktNum int,
		tOut datetime,
		Customer varchar(255),
		CustTierLevel varchar(255),
		Location varchar(255),
		EventDisplay varchar(255),
		tAuthorize datetime,
		tComplete datetime,
		RspSecs int,
		CmpSecs int,
		OverallSecs int,
		CompCode varchar(255),
		EmpAssign varchar(255),
		EmpRespond varchar(255),
		EmpComplete varchar(255),
		ResolutionDesc varchar(255),
		Zone varchar(255),
		CustNum varchar(255),
		SupervisorAssign int,
		Reassign int,
		ReassignSupervisor int,
		EmpCmpAsnTaken varchar(255),
		EmpCmpJobType varchar(255),
		FromZone varchar(255),
		HasReject int,
		RspType varchar(255),
		tAsnInit datetime,
		tReaInit datetime,
		tAcpInit datetime,
		tRejInit datetime,
		Asset varchar(255),
		CustPriorityLevel varchar(255),
		CompVarianceReason varchar(50),
		AsnSecs int,
		ReaSecs int,
		AcpSecs int,
		RejSecs int
	)
		
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt1, @EndDt = @EndDt1, @MaxCmpMins = @MaxCmpMins1, @EventType = @EventType1, @ZoneArea = @ZoneArea1, @CustTier = @CustTier1, @CustNum = @CustNum1, @MinRspMins = @MinRspMins1, @MinCmpMins = @MinCmpMins1, @MinOverallMins = @MinOverallMins1, @ResDesc = @ResDesc1, @MinRspSecs = @MinRspSecs1, @MaxRspSecs = @MaxRspSecs1, @MinCmpSecs = @MinCmpSecs1, @MaxCmpSecs = @MaxCmpSecs1, @Location = @Location, @Hour = @Hour, @EmpCmpJobType = @EmpCmpJobType1, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD
	
	
	--SET @RspMins = (select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'Target80NumMinutes')
	DECLARE @RspSecs int = @RspMins * 60
	
	DECLARE @UseEmpName char(255) = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'UseEmpNamesInReports'),'0')
	
	
	DECLARE @EmpNameLast nvarchar(35), @EmpNameFirst nvarchar(25)
	(select @EmpNameFirst = NameFirst, @EmpNameLast = NameLast from SQLA_Employees where CardNum = @EmpNum)
	
	select s.ShiftName, ShiftOrder = s.ShiftColumn, ShiftHour = s.StartHour, e.CustTierLevel, e.PriorityLevel,
	       RspUnder = isnull(e.RspUnder,0), RspTotal = isnull(e.RspTotal,0), 
	       SupervisorAssignUnder = isnull(e.SupervisorAssignUnder,0), SupervisorAssignTotal = isnull(SupervisorAssignTotal,0),
	       ReassignUnder = isnull(e.ReassignUnder,0), ReassignTotal = isnull(e.ReassignTotal,0),
	       ReassignSupervisorUnder = isnull(e.ReassignSupervisorUnder,0), ReassignSupervisorTotal = isnull(ReassignSupervisorTotal,0),
	       AttendantAssignUnder = isnull(e.AttendantAssignUnder,0), AttendantAssignTotal = isnull(AttendantAssignTotal,0),
	       AttendantTakeUnder = isnull(e.AttendantTakeUnder,0), AttendantTakeTotal = isnull(AttendantTakeTotal,0),
	       SupervisorTakeUnder = isnull(e.SupervisorTakeUnder,0), SupervisorTakeTotal = isnull(SupervisorTakeTotal,0),
	       HasRejectUnder = ISNULL(e.HasRejectUnder,0), HasRejectTotal = ISNULL(HasRejectTotal,0),
	       JpRspSecsTot, JpTotSecsTot, JpEvtCount, AllRspSecsTot
	  from SQLA_ShiftHours as s
	  left join (
	select EvtHour = DATEPART(hour, tOut), CustTierLevel, PriorityLevel = isnull(PriorityLevel,0),
	       RspUnder = SUM(case when ((RspSecs >= 0) and (RspSecs < @RspSecs)) then 1 else 0 end),
	       RspTotal = COUNT(*),
	       SupervisorAssignUnder = SUM(case when (EmpCmpJobType in ('Supervisor','Manager')) and (EmpCmpAsnTaken = 'Asn') and ((RspSecs >= 0) and (RspSecs < @RspSecs)) then 1 else 0 end),
	       SupervisorAssignTotal = SUM(case when (EmpCmpJobType in ('Supervisor','Manager')) and (EmpCmpAsnTaken = 'Asn') then 1 else 0 end),
	       ReassignUnder = SUM(case when ((RspSecs >= 0) and (RspSecs < @RspSecs)) then Reassign else 0 end),
	       ReassignTotal = SUM(Reassign),
	       ReassignSupervisorUnder = SUM(case when ((RspSecs >= 0) and (RspSecs < @RspSecs)) then ReassignSupervisor else 0 end),
	       ReassignSupervisorTotal = SUM(ReassignSupervisor),
	       AttendantAssignUnder = SUM(case when (EmpCmpJobType = 'Attendant') and (EmpCmpAsnTaken = 'Asn') and ((RspSecs >= 0) and (RspSecs < @RspSecs)) then 1 else 0 end),
	       AttendantAssignTotal = SUM(case when (EmpCmpJobType = 'Attendant') and (EmpCmpAsnTaken = 'Asn') then 1 else 0 end),
	       AttendantTakeUnder = SUM(case when (EmpCmpJobType = 'Attendant') and (EmpCmpAsnTaken = 'Take') and ((RspSecs >= 0) and (RspSecs < @RspSecs)) then 1 else 0 end),
	       AttendantTakeTotal = SUM(case when (EmpCmpJobType = 'Attendant') and (EmpCmpAsnTaken = 'Take') then 1 else 0 end),
	       SupervisorTakeUnder = SUM(case when (EmpCmpJobType in ('Supervisor','Manager')) and (EmpCmpAsnTaken = 'Take') and ((RspSecs >= 0) and (RspSecs < @RspSecs)) then 1 else 0 end),
	       SupervisorTakeTotal = SUM(case when (EmpCmpJobType in ('Supervisor','Manager')) and (EmpCmpAsnTaken = 'Take') then 1 else 0 end),
	       HasRejectUnder = SUM(case when (HasReject > 0) and (RspSecs >= 0) and (RspSecs < @RspSecs) then 1 else 0 end),
	       HasRejectTotal = SUM(case when HasReject > 0 then 1 else 0 end),
	       JpRspSecsTot = SUM(case when EventDisplay like 'JP%' or EventDisplay like 'JKPT%' or EventDisplay like 'PROG%' or EventDisplay like 'PJ%' then RspSecs else 0 end),
	       JpTotSecsTot = SUM(case when EventDisplay like 'JP%' or EventDisplay like 'JKPT%' or EventDisplay like 'PROG%' or EventDisplay like 'PJ%' then OverallSecs else 0 end),
	       JpEvtCount = SUM(case when EventDisplay like 'JP%' or EventDisplay like 'JKPT%' or EventDisplay like 'PROG%' or EventDisplay like 'PJ%' then 1 else 0 end),
	       AllRspSecsTot = SUM(RspSecs)
	  from dbo.#RTA_EventDetails_Tmp as d
	  left join SQLA_CustTiers as t
	    on t.TierLevel = d.CustTierLevel
	 where (    (@EmpNum = '' )
	         or (@UseEmpName = '1' and RIGHT(EmpRespond,LEN(@EmpNameLast))=@EmpNameLast)
	         or (@UseEmpName = '1' and LEFT(EmpRespond,LEN(@EmpNameFirst))=@EmpNameFirst)
	         or (@UseEmpName <> '1' and EmpRespond=@EmpNum))
	 group by DATEPART(hour, tOut), CustTierLevel, PriorityLevel ) as e
	    on e.EvtHour = s.StartHour
	
END





GO

