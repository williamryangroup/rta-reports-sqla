USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails]    Script Date: 06/21/2016 11:24:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails]
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
	@MinRspSecs int = -1,
	@MaxRspSecs int = 0,
	@MinCmpSecs int = 0,
	@MaxCmpSecs int = 0,
	@Location varchar(2000) = '',
	@Hour int = null,
	@Shift int = null,
	@EmpCmpAsnTaken int = 0,
	@EmpCmpJobType varchar(2000) = '',
	@FromZoneArea varchar(255) = '',
	@MaxEvents int = 0,
	@RejectOnly int = 0,
	@Distance int = null,
	@EmpComplete varchar(255) = '',
	@FromReport varchar(255) = '',
	@EmpActUtil int = 0,
	@EmpActEvtSum int = 0,
	@EmpActJobType varchar(2000) = '',
	@EmpActEmpNum nvarchar(255) = '',
	@EmpActEvtDisplay nvarchar(2000) = '',
	@EmpActStat nvarchar(255) = '',
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1,
	@MinTrvSecs int = -1,
	@MaxTrvSecs int = 0,
	@NoBeepVib int = 0

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
	DECLARE @RejectOnly1 int = @RejectOnly
	DECLARE @Distance1 int = @Distance
	DECLARE @EmpComplete1 varchar(255) = @EmpComplete

	DECLARE @UseCustName char(255) = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'UseCustNamesInReports'),'1')
	DECLARE @UseEmpName char(255) = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'UseEmpNamesInReports'),'1')

	-- CREATE TABLE OF EventTypes
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_EventTypes'))
    BEGIN
		drop table dbo.#RTA_Compliance_EventTypes;
    END    
    
    create table #RTA_Compliance_EventTypes (
		EventType nvarchar(10) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_Compliance_EventTypes (EventType)
    select distinct left(ltrim(rtrim(val)),10) from dbo.fn_String_To_Table(@EventType1, ',', 1)
	
	
	-- CREATE TABLE OF ZoneAreas
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_ZoneAreas'))
    BEGIN
		drop table dbo.#RTA_Compliance_ZoneAreas;
    END    
    
    create table #RTA_Compliance_ZoneAreas (
		ZoneArea nvarchar(4) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_Compliance_ZoneAreas (ZoneArea)
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@ZoneArea1, ',', 1)
	
	
	-- CREATE TABLE OF CustTiers
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_CustTiers'))
    BEGIN
		drop table dbo.#RTA_Compliance_CustTiers;
    END    
    
    create table #RTA_Compliance_CustTiers (
		CustTier nvarchar(4) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_Compliance_CustTiers (CustTier)
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@CustTier1, ',', 1)
	
	DECLARE @CustTiersAll int = isnull((select 1 from #RTA_Compliance_CustTiers where CustTier = 'ALL'),0)
	
	IF @CustTiersAll = 1
	BEGIN
		insert into #RTA_Compliance_CustTiers (CustTier)
		select TierLevel from SQLA_CustTiers where TierLevel not in (select CustTier from #RTA_Compliance_CustTiers)
		
		delete from #RTA_Compliance_CustTiers where CustTier = 'ALL'
	END
	

	CREATE TABLE #RTA_EventDetails_ExecSum_Emp2_Tmp (
		EmpNum nvarchar(255),
		EmpName nvarchar(255),
		EmpJobType nvarchar(255),
		PktNum int,
		EventDisplay nvarchar(255),
		StatOrd int,
		Stat nvarchar(255),
		StatSecs int,
		StatStart datetime,
		StatEnd datetime
	)
	
	IF (@FromReport='Executive Scorecard Employee Activity')
	BEGIN
		INSERT INTO #RTA_EventDetails_ExecSum_Emp2_Tmp EXEC [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2] @StartDt=@StartDt1, @EndDt=@EndDt1, @UtilType=@EmpActUtil, @EmpJobType=@EmpActJobType, @EventSum=@EmpActEvtSum
	END
	
	
	
	IF (@MaxEvents = 0)
	BEGIN
		select d.*, 
		       AsnSecs = case when d.tAsnInit is null then -1 when d.tAsnInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tAsnInit) end,
			   ReaSecs = case when d.tReaInit is null then -1 when d.tReaInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tReaInit) end,
			   AcpSecs = case when d.tAcpInit is null then -1 when d.tAcpInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tAcpInit) end,
			   RejSecs = case when d.tRejInit is null then -1 when d.tRejInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tRejInit) end
		  from (
		select e.PktNum,
			   tOut, 
			   Customer = case when @UseCustName = '1' then CustName else CustNum end,
			   CustTierLevel,
			   Location,
			   EventDisplay = case when EventDisplay in ('JKPT','PJ','JP','PROG') then EventDisplay + ' ' + isnull(AmtEvent,'') else EventDisplay end,
			   tAuthorize,
			   tComplete,
			   RspSecs = RspSecs,
			   CmpSecs = CmpSecs,
			   OverallSecs = TotSecs,
			   CompCode = case when CmpWS = 1 then 'Workstation'
			                   when CmpWS = 2 then 'Dashboard'
			                   when CmpMobile = 1 then 'Mobile'
			                   when CmpGame = 1 then 'Game'
			                   else 'Other' end,
			   EmpAssign = case when @UseEmpName = '1' and EmpNameAsn <> '' then EmpNameAsn else EmpNumAsn end,
			   EmpRespond = case when @UseEmpName = '1' and EmpNameRsp <> '' then EmpNameRsp else EmpNumRsp end,
			   EmpComplete = case when @UseEmpName = '1' and EmpNameCmp <> '' then EmpNameCmp else EmpNumCmp end,
			   ResolutionDesc,
			   Zone,
			   CustNum,
			   SupervisorAssign = case when EmpJobTypeAsn = 'Supervisor' and Reassign = 0 and ReassignSupervisor = 0 then 1 else 0 end,
			   Reassign,
			   ReassignSupervisor,
			   EmpCmpAsnTaken = AsnTake,
			   EmpCmpJobType = EmpJobTypeCmp,
			   FromZone = e.FromZone,
			   e.HasReject,
			   RspType = case when RspRTA = 1 then 'Mobile'
			                  when RspCard = 1 then 'Card'
			                  else 'Other' end,
			   tAsnInit = (select min(tAsn) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum),
			   tReaInit = (select min(tRea) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum),
			   tAcpInit = (select min(tAcp) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum),
			   tRejInit = (select min(tRej) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum)
		  from SQLA_EventDetails as e
		  left join SQLA_ShiftHours as s
			on s.StartHour = tOutHour
		  left join SQLA_AreaAssoc as a
			on a.Area = e.FromZone
		   and a.AssocArea = e.Zone
		 where (    (     @FromReport not in ('Executive Scorecard Employee Activity','Supervisor Review')
		              and tOut >= @StartDt1 and tOut < @EndDt1
		              and (TotSecs*1.0/60.0) <= @MaxCmpMins1
		              and (EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
		              and (Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea1 is null or @ZoneArea1 = '')
		              and (    (CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
				            or (CustTierLevel = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
				            or (@CustTier1 is null or @CustTier1 = ''))
		              and (@CustNum1 is null or @CustNum1 = '' or CustNum = @CustNum1)
		              and ((@MinRspMins1 = 0) or (RspSecs >= @MinRspMins1 * 60))
		              and ((@MinRspSecs1 = -1) or (RspSecs >= @MinRspSecs1))
		              and ((@MaxRspSecs1 = 0) or (RspSecs < @MaxRspSecs1))
		              and ((@MinCmpMins1 = 0) or (CmpSecs >= @MinCmpMins1 * 60))
		              and ((@MinCmpSecs = 0) or (CmpSecs >= @MinCmpSecs))
		              and ((@MaxCmpSecs = 0) or (CmpSecs < @MaxCmpSecs))
		              and ((@MinOverallMins1 = 0) or (TotSecs >= @MinOverallMins1 * 60))
		              and ((@ResDesc1 = 0) or (@ResDesc1 = ResolutionDescID))
		              and ((@Location = '') or (@Location = Location))
		              and ((@Hour is null) or (@Hour = tOutHour))
		              and ((@Shift is null) or (@Shift = ShiftColumn))
		              and ((@EmpCmpAsnTaken = 0) or (@EmpCmpAsnTaken = AsnTakeID))
		              and ((@EmpCmpJobType = '') or (@EmpCmpJobType = 'All') or (@EmpCmpJobType = EmpJobTypeCmp))
		              and ((@FromZoneArea = '') or (@FromZoneArea = 'All') or (@FromZoneArea = FromZone) or ((FromZone is null or FromZone = '') and @FromZoneArea = e.Zone))
		              and ((@RejectOnly1 = 0) or (@RejectOnly1 = 1 and e.HasReject > 0))
		              and ((@Distance1 is null) or (@Distance1 = ISNULL(a.Priority,0)))
		              and ((@EmpComplete1 = '') or (@EmpComplete1 = EmpNameCmp) or (@EmpComplete1 = EmpNumCmp))
		              and ((@IncludeOOS = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
		              and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
					  and (      @NoBeepVib = 0
							or (     @NoBeepVib = 1
								 and exists (select null from SQLA_FloorActivity as f where f.PktNum = e.PktNum and f.ActivityTypeID = 5 and f.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor'))
								 and exists	(select null from SQLA_FloorActivity as f where f.PktNum = e.PktNum and f.ActivityTypeID = 5 and f.State in ('Reject Auto Server'))
								 and not exists
								   ( select null from SQLA_FloorActivity as fv
									  inner join SQLA_FloorActivity as fa   -- event assigned
										 on fa.PktNum = fv.PktNum
										and fa.tOut < fv.tOut
										and fa.ActivityTypeID = 5
										and fa.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor')
									  inner join SQLA_FloorActivity as fr   -- reject/employee removed from event
										 on fr.PktNum = fv.PktNum
										and fr.tOut > fv.tOut
										and fr.ActivityTypeID = 5
										and fr.State = 'Reject Auto Server'
									  where fv.PktNum = e.PktNum and fv.ActivityTypeID = 5 and fv.State in ('Display-NEW EVENT','BeepAssignedEvent','VibrateAssignedEvent') ) ) ) )
		         or (     @FromReport = 'Supervisor Review' and tOut >= @StartDt1 and tOut < @EndDt1 and RspSecs >= 0
					  and (    (@EventType1 in ('OOS','10 6','EMPCARD') and EventDisplay in (select EventType from #RTA_Compliance_EventTypes))
					        or (EventDisplay not in ('OOS','10 6','EMPCARD')) )
					  and ((@EmpCmpJobType = '') or (@EmpCmpJobType = 'All') or (@EmpCmpJobType = EmpJobTypeRsp))
		              and (    (@CustTier = 'NUL' and CustTierLevel not in ('DIA','SEV'))
					        or (@CustTier <> 'NUL' and CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
				            or (@CustTier1 is null or @CustTier1 = '') )
					  and ((@EmpCmpAsnTaken = 0) or (@EmpCmpAsnTaken = AsnTakeID)) )
		         or (     @FromReport = 'Executive Scorecard Employee Activity'
				      and (    (     @EmpActStat = 'OOS' and EventDisplay like 'OOS%'
					             and tOut >= @StartDt1 and tOut < @EndDt1 and EmpNumAsn = @EmpActEmpNum
					             and e.tOut in (select StatStart from #RTA_EventDetails_ExecSum_Emp2_Tmp
					                             where EmpNum = @EmpActEmpNum
										           and EventDisplay = @EmpActEvtDisplay
										           and Stat = @EmpActStat))
		                    or (     @EmpActStat <> 'OOS'
							     and e.PktNum in (select PktNum from #RTA_EventDetails_ExecSum_Emp2_Tmp
					                               where (EmpNum = @EmpActEmpNum or @EmpActEmpNum='')
										             and EventDisplay = @EmpActEvtDisplay
										             and (Stat = @EmpActStat or @EmpActStat=''))) ) ) ) ) as d
		 where ((@MinTrvSecs = -1) or (d.tAuthorize is not null and d.tAcpInit <= d.tAuthorize and DATEDIFF(second,d.tAcpInit,d.tAuthorize) >= @MinTrvSecs))
		   and ((@MaxTrvSecs = 0) or (d.tAuthorize is not null and d.tAcpInit <= d.tAuthorize and DATEDIFF(second,d.tAcpInit,d.tAuthorize) < @MaxTrvSecs))
	END
	
	IF (@MaxEvents > 0)
	BEGIN
		select TOP (@MaxEvents) d.*, 
		       AsnSecs = case when d.tAsnInit is null then -1 when d.tAsnInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tAsnInit) end,
			   ReaSecs = case when d.tReaInit is null then -1 when d.tReaInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tReaInit) end,
			   AcpSecs = case when d.tAcpInit is null then -1 when d.tAcpInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tAcpInit) end,
			   RejSecs = case when d.tRejInit is null then -1 when d.tRejInit <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tRejInit) end
		  from (
		select e.PktNum,
			   tOut, 
			   Customer = case when @UseCustName = '1' then CustName else CustNum end,
			   CustTierLevel,
			   Location,
			   EventDisplay = case when EventDisplay in ('JKPT','PJ','JP','PROG') then EventDisplay + ' ' + isnull(AmtEvent,'') else EventDisplay end,
			   tAuthorize,
			   tComplete,
			   RspSecs = RspSecs,
			   CmpSecs = CmpSecs,
			   OverallSecs = TotSecs,
			   CompCode = case when CmpWS = 1 then 'Workstation'
			                   when CmpWS = 2 then 'Dashboard'
			                   when CmpMobile = 1 then 'Mobile'
			                   when CmpGame = 1 then 'Game'
			                   else 'Other' end,
			   EmpAssign = case when @UseEmpName = '1' then EmpNameAsn else EmpNumAsn end,
			   EmpRespond = case when @UseEmpName = '1' then EmpNameRsp else EmpNumRsp end,
			   EmpComplete = case when @UseEmpName = '1' then EmpNameCmp else EmpNumCmp end,
			   ResolutionDesc,
			   Zone,
			   CustNum,
			   SupervisorAssign = case when EmpJobTypeAsn = 'Supervisor' and Reassign = 0 and ReassignSupervisor = 0 then 1 else 0 end,
			   Reassign,
			   ReassignSupervisor,
			   EmpCmpAsnTaken = AsnTake,
			   EmpCmpJobType = EmpJobTypeCmp,
			   FromZone = e.FromZone,
			   e.HasReject,
			   RspType = case when RspRTA = 1 then 'Mobile'
			                  when RspCard = 1 then 'Card'
			                  else 'Other' end,
			   tAsnInit = (select min(tAsn) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum),
			   tReaInit = (select min(tRea) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum),
			   tAcpInit = (select min(tAcp) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum),
			   tRejInit = (select min(tRej) from SQLA_EmployeeEventTimes as t where t.PktNum = e.PktNum)
		  from SQLA_EventDetails as e
		  left join SQLA_ShiftHours as s
			on s.StartHour = tOutHour ) as d
		 order by tOut desc
	END
END



GO

