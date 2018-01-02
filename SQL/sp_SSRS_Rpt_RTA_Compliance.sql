USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Compliance]    Script Date: 06/15/2016 11:35:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Compliance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Compliance]
GO



-- =============================================================================
-- Author:		bburrows
-- Create date: June 8, 2015
-- Description:	Stored Procedure for pulling RTA Compliance report data
-- =============================================================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Compliance] 
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@EventType varchar(2000) = '',
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@JobType varchar(2000) = '',
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
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
    select left(ltrim(rtrim(val)),10) from dbo.fn_String_To_Table(@EventType, ',', 1)
	
	
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
    select left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@ZoneArea, ',', 1)
	
	
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
    select left(ltrim(rtrim(val)),50) from dbo.fn_String_To_Table(@CustTier, ',', 1)
	
	
	-- CREATE TABLE OF JobTypes
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_JobTypes'))
    BEGIN
		drop table dbo.#RTA_Compliance_JobTypes;
    END    
    
    create table #RTA_Compliance_JobTypes (
		JobType nvarchar(20) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_Compliance_JobTypes (JobType)
    select left(ltrim(rtrim(val)),20) from dbo.fn_String_To_Table(@JobType, ',', 1)
		
	
	DECLARE @ZonesAreNumeric int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZonesAreNumeric'),0)


	select EventType = EventDisplay, 
		   EventZone = Zone, 
		   EventHour = tOutHour,
		   CustTier = CustTierLevel,
		   Assign = case when tAssign is not null then 1 else 0 end,
		   AcceptRTA = case when tAccept is not null then 1 else 0 end,
		   Reject = HasReject,
		   RspRTA,
		   RspCard,
		   RspRTAandCard = case when RspRTA > 0 and RspCard > 0 then 1 else 0 end,
		   Rsp = case when tAuthorize is not null then 1 else 0 end,
		   NoRsp = case when tAuthorize is null then 1 else 0 end,
		   AsnRspSame = case when (EmpNumAsn is not null and EmpNumAsn <> '') and (EmpNumRsp is not null and EmpNumRsp <> '') and (EmpNumAsn = EmpNumRsp) then 1 else 0 end,
		   Cmp = case when tComplete is not null then 1 else 0 end,
		   RspCmpSame = case when (EmpNumRsp is not null and EmpNumRsp <> '') and (EmpNumCmp is not null and EmpNumCmp <> '') and (EmpNumRsp = EmpNumCmp) then 1 else 0 end,
		   RspTmSec = RspSecs,
		   CmpMobile = case when CmpMobile > 0 then 1 else 0 end,
		   CmpGame = case when CmpGame > 0 then 1 else 0 end,
		   CmpWS = case when CmpWS > 0 then 1 else 0 end,
		   AssignSupervisor = case when EmpJobTypeAsn = 'Supervisor' and Reassign = 0 and ReassignSupervisor = 0 then 1 else 0 end,
		   Reassign,
		   ReassignSupervisor,
		   CmpTmSec = CmpSecs,
		   TotTmSec = TotSecs,
		   EmpNumCmp,
		   EventDayOfWeek = DATENAME(weekday,tOut),
		   EventMonth = DATENAME(month,tOut),
		   ShiftName,
		   CustTierOrd = CustPriorityLevel,
		   DayOfWeekOrd = DATEPART(weekday,tOut),
		   MonthOrd = DATEPART(month,tOut),
		   ShiftOrd = ShiftColumn,
		   ZoneOrd = case when @ZonesAreNumeric=1 then cast((case when ISNUMERIC(Zone)=0 then 0 else Zone end) as int)
		                  else Zone end
	  from SQLA_EventDetails as d
	  left join SQLA_ShiftHours as s
	    on s.StartHour = tOutHour
	 where tOut >= @StartDt and tOut < @EndDt
	   and (TotSecs*1.0/60.0) <= @MaxCmpMins
	   and ((@IncludeOOS = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType is null or @EventType = '')
	   and (Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '')
	   and (    (CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
	         or (CustTierLevel = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	   and (EmpJobTypeCmp in (select JobType from #RTA_Compliance_JobTypes) or @JobType is null or @JobType = '' or EmpJobTypeCmp = '')
	   and isnull(ResolutionDescID,0) <> 1
END




GO

