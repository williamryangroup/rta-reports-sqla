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
		   ZoneOrd = case when @ZonesAreNumeric = 1 then cast(Zone as int) else Zone end
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

USE [RTA_SQLA]
GO
/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Compliance_Employee]    Script Date: 07/08/2016 14:16:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Compliance_Employee]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Compliance_Employee]
GO



-- =============================================================================
-- Author:		bburrows
-- Create date: June 8, 2015
-- Description:	Returns RTA Compliance by Employee
-- =============================================================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Compliance_Employee]
	@StartDt datetime,
	@EndDt datetime,
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@AsnRspOnly int = 0,
	@CustTier varchar(255) = '',
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1,
	@ZoneArea varchar(255) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	
	DECLARE @UseAssetField char(1) = isnull((select case when Setting = 'Asset' then '1' else '0' end from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),'0')
	
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @EmpJobType1 varchar(2000) = @EmpJobType
	DECLARE @EventType1 varchar(2000) = @EventType
	DECLARE @AsnRspOnly1 int = @AsnRspOnly
	DECLARE @IncludeOOS1 int = @IncludeOOS
	DECLARE @IncludeEMPCARD1 int = @IncludeEMPCARD

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
    select distinct left(ltrim(rtrim(val)),20) from dbo.fn_String_To_Table(@EmpJobType1, ',', 1)
    

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
    select left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@CustTier, ',', 1)
	
	
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
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@ZoneArea, ',', 1)
    
    
    SELECT EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, c.PktNum, c.EventDisplay, d.Location,
           Asn = case when c.EventDisplay in ('EMPCARD','OOS','10 6') then 0 else Asn end,
           Acp = case when c.EventDisplay in ('EMPCARD','OOS','10 6') then 0 else Acp end,
           Rsp = Rsp, 
           Cmp = Cmp, 
           CmpMobile = c.CmpMobile, 
           RejMan = case when c.EventDisplay in ('EMPCARD','OOS','10 6') then 0 else RejMan end,
           RejAuto = case when c.EventDisplay in ('EMPCARD','OOS','10 6') then 0 else RejAuto end,
           RspRTA = c.RspRTA, 
           RspCard = c.RspCard, 
           RspRTAandCard = RspRTAandCard, 
           RspTmSec = RspTmSec, 
           OverallTmSec = OverallTmSec,
           AsnOther = isnull((select distinct 1 from SQLA_EmployeeCompliance as c2 where c2.PktNum = c.PktNum and c2.EmpNum <> c.EmpNum and c2.tAsnMin < c.tRspMin),0),
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier, d.tOutHour, EvtDay = cast(c.tOut as date),
	       MEALbkEntries = 0, MEALbkSignatures = 0
      FROM SQLA_EmployeeCompliance as c
	 INNER JOIN SQLA_EventDetails as d
	    ON d.PktNum = c.PktNum
	  LEFT JOIN SQLA_ShiftHours as s
	    ON s.StartHour = d.tOutHour
	 where c.tOut >= @StartDt1 and c.tOut < @EndDt1
	   and ((@IncludeOOS1 = 0 and c.EventDisplay not in ('OOS','10 6')) or (@IncludeOOS1 = 1))
	   and ((@IncludeEMPCARD1 = 0 and c.EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD1 = 1))
	   and (EmpJobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '' or @EmpJobType1 = 'All')
	   and (c.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
	   and (@AsnRspOnly1 = 0 or (@AsnRspOnly1 = 1 and Asn > 0) or (@AsnRspOnly1 = 2 and Asn = 0 and Rsp > 0))
	   and (    (CustTier in (select CustTier from #RTA_Compliance_CustTiers))
	         or (CustTier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
       and (d.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	 UNION ALL
    SELECT EmpNum, EmpNameFirst = e.NameFirst, EmpNameLast = e.NameLast, EmpJobType = e.JobType, j.PktNum, j.EventDisplay, d.Location,
           Asn = 0, Acp = 0, Rsp = 1, Cmp = 1, CmpMobile = 0, RejMan = 0, RejAuto = 0, RspRTA = 0, RspCard = 0, RspRTAandCard = 0, 
           RspTmSec = 0, OverallTmSec = DATEDIFF(second,j.tOut,j.tComplete), AsnOther = 0,
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier = '', d.tOutHour, EvtDay = cast(d.tOut as date),
	       MEALbkEntries = 0, MEALbkSignatures = 0
	  FROM SQLA_EventDetails_JPVER as j
	 INNER JOIN SQLA_EventDetails as d
	    ON d.PktNum = j.PktNum
	  LEFT JOIN SQLA_Employees as e
	    on e.CardNum = j.EmpNum
	  LEFT JOIN SQLA_ShiftHours as s
	    ON s.StartHour = d.tOutHour
	 WHERE j.tOut >= @StartDt1 and j.tOut < @EndDt1
	   and (JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '' or @EmpJobType1 = 'All')
	   and (j.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
	   and @AsnRspOnly1 <> 1
	   and Source = 'OOS'
       and (d.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	 union all

	-- MEAL book entries
    SELECT EmpNum = emp.CardNum, EmpNameFirst = emp.NameFirst, EmpNameLast = emp.NameLast, EmpJobType = emp.JobType, 
	       PktNum = ml.ParentEventID, evt.EventDisplay, Location = case when @UseAssetField = 1 then ml.Asset else ml.Location end,
           Asn = 0, Acp = 0, Rsp = 0, Cmp = 0, CmpMobile = 0, RejMan = 0, RejAuto = 0, RspRTA = 0, RspCard = 0, RspRTAandCard = 0, RspTmSec = 0, OverallTmSec = 0, AsnOther = 0,
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier = evt.CustTierLevel, tOutHour = datepart(hour,ml.tOut), EvtDay = cast(ml.tOut as date),
	       MEALbkEntries = 1, MEALbkSignatures = 0
	  FROM SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
	    on emp.CardNum = ml.EmpNum
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	  left join SQLA_ShiftHours as s
	    ON s.StartHour = datepart(hour,ml.tOut)
	 WHERE ml.tOut >= @StartDt1 and ml.tOut < @EndDt1
	   and (emp.JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '' or @EmpJobType1 = 'All')
	   and (evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
       and (ml.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
	         or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	 union all
    SELECT EmpNum = emp.CardNum, EmpNameFirst = emp.NameFirst, EmpNameLast = emp.NameLast, EmpJobType = emp.JobType, 
	       PktNum = ml.ParentEventID, evt.EventDisplay, Location = case when @UseAssetField = 1 then ml.Asset else ml.Location end,
           Asn = 0, Acp = 0, Rsp = 0, Cmp = 0, CmpMobile = 0, RejMan = 0, RejAuto = 0, RspRTA = 0, RspCard = 0, RspRTAandCard = 0, RspTmSec = 0, OverallTmSec = 0, AsnOther = 0,
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier = evt.CustTierLevel, tOutHour = datepart(hour,ml.tOut), EvtDay = cast(ml.tOut as date),
	       MEALbkEntries = 0, MEALbkSignatures = 1
	  FROM SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
	    on emp.CardNum = ml.EmpNumWitness1
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	  left join SQLA_ShiftHours as s
	    ON s.StartHour = datepart(hour,ml.tOut)
	 WHERE ml.tOut >= @StartDt1 and ml.tOut < @EndDt1
	   and (emp.JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '' or @EmpJobType1 = 'All')
	   and (evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
       and (ml.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
	         or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	 union all
    SELECT EmpNum = emp.CardNum, EmpNameFirst = emp.NameFirst, EmpNameLast = emp.NameLast, EmpJobType = emp.JobType, 
	       PktNum = ml.ParentEventID, evt.EventDisplay, Location = case when @UseAssetField = 1 then ml.Asset else ml.Location end,
           Asn = 0, Acp = 0, Rsp = 0, Cmp = 0, CmpMobile = 0, RejMan = 0, RejAuto = 0, RspRTA = 0, RspCard = 0, RspRTAandCard = 0, RspTmSec = 0, OverallTmSec = 0, AsnOther = 0,
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier = evt.CustTierLevel, tOutHour = datepart(hour,ml.tOut), EvtDay = cast(ml.tOut as date),
	       MEALbkEntries = 0, MEALbkSignatures = 1
	  FROM SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
	    on emp.CardNum = ml.EmpNumWitness2
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	  left join SQLA_ShiftHours as s
	    ON s.StartHour = datepart(hour,ml.tOut)
	 WHERE ml.tOut >= @StartDt1 and ml.tOut < @EndDt1
	   and (emp.JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '' or @EmpJobType1 = 'All')
	   and (evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
       and (ml.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
	         or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	 union all
    SELECT EmpNum = emp.CardNum, EmpNameFirst = emp.NameFirst, EmpNameLast = emp.NameLast, EmpJobType = emp.JobType, 
	       PktNum = ml.ParentEventID, evt.EventDisplay, Location = case when @UseAssetField = 1 then ml.Asset else ml.Location end,
           Asn = 0, Acp = 0, Rsp = 0, Cmp = 0, CmpMobile = 0, RejMan = 0, RejAuto = 0, RspRTA = 0, RspCard = 0, RspRTAandCard = 0, RspTmSec = 0, OverallTmSec = 0, AsnOther = 0,
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier = evt.CustTierLevel, tOutHour = datepart(hour,ml.tOut), EvtDay = cast(ml.tOut as date),
	       MEALbkEntries = 0, MEALbkSignatures = 1
	  FROM SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
	    on emp.CardNum = ml.EmpNumWitness3
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	  left join SQLA_ShiftHours as s
	    ON s.StartHour = datepart(hour,ml.tOut)
	 WHERE ml.tOut >= @StartDt1 and ml.tOut < @EndDt1
	   and (emp.JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '' or @EmpJobType1 = 'All')
	   and (evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
       and (ml.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
	         or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	 union all
    SELECT EmpNum = emp.CardNum, EmpNameFirst = emp.NameFirst, EmpNameLast = emp.NameLast, EmpJobType = emp.JobType, 
	       PktNum = ml.ParentEventID, evt.EventDisplay, Location = case when @UseAssetField = 1 then ml.Asset else ml.Location end,
           Asn = 0, Acp = 0, Rsp = 0, Cmp = 0, CmpMobile = 0, RejMan = 0, RejAuto = 0, RspRTA = 0, RspCard = 0, RspRTAandCard = 0, RspTmSec = 0, OverallTmSec = 0, AsnOther = 0,
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier = evt.CustTierLevel, tOutHour = datepart(hour,ml.tOut), EvtDay = cast(ml.tOut as date),
	       MEALbkEntries = 0, MEALbkSignatures = 1
	  FROM SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
	    on emp.CardNum = ml.EmpNumWitness4
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	  left join SQLA_ShiftHours as s
	    ON s.StartHour = datepart(hour,ml.tOut)
	 WHERE ml.tOut >= @StartDt1 and ml.tOut < @EndDt1
	   and (emp.JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '' or @EmpJobType1 = 'All')
	   and (evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
       and (ml.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
	         or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
END

GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Compliance_Supervisor]    Script Date: 07/08/2016 14:15:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Compliance_Supervisor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Compliance_Supervisor]
GO



-- =============================================================================
-- Author:		bburrows
-- Create date: June 8, 2015
-- Description:	Returns RTA Compliance by Employee
-- =============================================================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Compliance_Supervisor]
	@StartDt datetime,
	@EndDt datetime,
	@CustTier varchar(255) = '',
	@EventType varchar(2000) = '',
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1,
	@ZoneArea varchar(255) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
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
    select left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@CustTier, ',', 1)
	
	
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
    select distinct left(ltrim(rtrim(val)),10) from dbo.fn_String_To_Table(@EventType, ',', 1)
	
	
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
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@ZoneArea, ',', 1)
	
    
    DECLARE @SupervisorTitleText nvarchar(50) = ISNULL((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSHH' and ConfigParam = 'SupervisorTitleText'),'Supervisor')
	DECLARE @ManagerTitleText nvarchar(50) = ISNULL((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSHH' and ConfigParam = 'ManagerTitleText'),'Manager')
	
	
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType,
	       Asn = SUM(Asn),
	       Acp = SUM(Acp),
	       Rej = SUM(Rej),
	       Rsp = SUM(Rsp),
	       Tkn = SUM(Tkn),
	       ReaAcp = SUM(ReaAcp),
	       ReaRej = SUM(ReaRej),
	       EmpBreakStart = SUM(EmpBreakStart),
	       EmpBreakEnd = SUM(EmpBreakEnd),
	       EmpOOSStart = SUM(EmpOOSStart),
	       EmpOOSEnd = SUM(EmpOOSEnd),
	       EmpLogout = SUM(EmpLogout),
	       EmpChgArea = SUM(EmpChgArea),
	       EvtEsc = SUM(EvtEsc),
	       EvtAsn = SUM(EvtAsn),
	       EvtCmp = SUM(EvtCmp),
	       AlertRcd = SUM(AlertRcd),
	       AlertAcp = SUM(AlertAcp),
	       AlertRej = SUM(AlertRej),
		   EventDisplay,
		   MEALbkEntries = SUM(MEALbkEntries),
		   MEALbkSignatures = SUM(MEALbkSignatures)
	  from (
	select EmpNum, EmpNameFirst = ltrim(rtrim(emp.NameFirst)), EmpNameLast = ltrim(rtrim(emp.NameLast)), EmpJobType = ltrim(rtrim(emp.JobType)),
		   Asn = 0, Acp = 0, Rej = 0, Rsp = 0, Tkn = 0, ReaAcp = 0, ReaRej = 0,
		   EmpBreakStart = SUM(case when ActivityTypeID = 8 and Activity like 'Start Break%' then 1 else 0 end),
		   EmpBreakEnd = SUM(case when ActivityTypeID = 8 and Activity like 'End Break%' then 1 else 0 end),
		   EmpOOSStart = SUM(case when ActivityTypeID = 8 and Activity like 'Start OOS%' then 1 else 0 end),
		   EmpOOSEnd = SUM(case when ActivityTypeID = 8 and Activity like 'End OOS%' then 1 else 0 end),
		   EmpLogout = SUM(case when ActivityTypeID = 8 and Activity like 'Logoff%' then 1 else 0 end),
		   EmpChgArea = SUM(case when ActivityTypeID = 8 and Activity like 'Assign Zones%' then 1 else 0 end),
		   EvtEsc = 0,
		   EvtAsn = 0,
		   EvtCmp = SUM(case when ActivityTypeID = 7 and Activity like '%Complete%' then 1 else 0 end),
		   AlertRcd = 0,
		   AlertAcp = SUM(case when ActivityTypeID = 9 and State like 'Alert Accept%' then 1 else 0 end),
		   AlertRej = SUM(case when ActivityTypeID = 9 and State like 'Alert Dismiss%' then 1 else 0 end),
		   EventDisplay = '', MEALbkEntries = 0, MEALbkSignatures = 0
	  from SQLA_FloorActivity as a
	  left join SQLA_Employees as emp
	    on emp.CardNum = a.EmpNum
	 where a.tOut >= @StartDt and a.tOut < @EndDt and ActivityTypeID in (7,8,9) and State <> 'Alert' and emp.JobType in (@SupervisorTitleText, @ManagerTitleText)
	   and (    (Tier in (select CustTier from #RTA_Compliance_CustTiers))
	         or (Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
       and (a.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	 group by EmpNum, emp.NameFirst, emp.NameLast, emp.JobType
	 union all
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType,
		   Asn = SUM(Asn),
		   Acp = SUM(Acp),
		   Rej = SUM(case when (RejAuto + RejMan) > 0 then 1 else 0 end),
		   Rsp = SUM(Rsp),
		   Tkn = SUM(case when Asn = 0 and Rsp > 0 then 1 else 0 end),
		   ReaAcp = case when SUM(Rea) > SUM(ReaRej) then SUM(Rea)-SUM(ReaRej) else 0 end,
		   ReaRej = SUM(ReaRej),
		   EmpBreakStart = 0, EmpBreakEnd = 0, EmpOOSStart = 0, EmpOOSEnd = 0, EmpLogout = 0, EmpChgArea = 0,
		   EvtEsc = 0, EvtAsn = 0, EvtCmp = 0, AlertRcd = 0, AlertAcp = 0, AlertRej = 0,
		   c.EventDisplay, MEALbkEntries = 0, MEALbkSignatures = 0
	  from SQLA_EmployeeCompliance as c
	  LEFT JOIN SQLA_EventDetails as d
	    ON d.PktNum = c.PktNum
	 where c.tOut >= @StartDt and c.tOut < @EndDt and EmpJobType in (@SupervisorTitleText, @ManagerTitleText)
	   and ((@IncludeOOS = 0 and c.EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and c.EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (    (CustTier in (select CustTier from #RTA_Compliance_CustTiers))
	         or (CustTier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	   and (@EventType is null or @EventType = '' or c.EventDisplay in (select EventType from #RTA_Compliance_EventTypes))
       and (d.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, c.EventDisplay 
	 union all	 
	 
	 -- MEAL book entries
	select EmpNum = CardNum, NameFirst, NameLast, JobType,
		   Asn = 0, Acp = 0, Rej = 0, Rsp = 0, Tkn = 0, ReaAcp = 0, ReaRej = 0, 
		   EmpBreakStart = 0, EmpBreakEnd = 0, EmpOOSStart = 0, EmpOOSEnd = 0, EmpLogout = 0,EmpChgArea = 0,
		   EvtEsc = 0, EvtAsn = 0, EvtCmp = 0, AlertRcd = 0, AlertAcp = 0, AlertRej = 0, EventDisplay = EventDisplay,
		   MEALbkEntries = sum(MEALbkEntries),
		   MEALbkSignatures = sum(MEALbkSignatures)
	  from (
	select emp.CardNum, emp.NameFirst, emp.NameLast, emp.JobType, evt.EventDisplay, MEALbkEntries = 1, MEALbkSignatures = 0
	  from SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
		on emp.CardNum = ml.EmpNum
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	 where ml.tOut >= @StartDt and ml.tOut < @EndDt 
	   and emp.JobType in (@SupervisorTitleText, @ManagerTitleText)
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
			 or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
			 or (@CustTier is null or @CustTier = ''))
	   and (@EventType is null or @EventType = '' or evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes))
	 union all
	 select emp.CardNum, emp.NameFirst, emp.NameLast, emp.JobType, evt.EventDisplay, MEALbkEntries = 0, MEALbkSignatures = 1
	  from SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
		on emp.CardNum = ml.EmpNumWitness1
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	 where ml.tOut >= @StartDt and ml.tOut < @EndDt 
	   and emp.JobType in (@SupervisorTitleText, @ManagerTitleText)
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
			 or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
			 or (@CustTier is null or @CustTier = ''))
	   and (@EventType is null or @EventType = '' or evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes))
	 union all
	select emp.CardNum, emp.NameFirst, emp.NameLast, emp.JobType, evt.EventDisplay, MEALbkEntries = 0, MEALbkSignatures = 1
	  from SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
		on emp.CardNum = ml.EmpNumWitness2
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	 where ml.tOut >= @StartDt and ml.tOut < @EndDt 
	   and emp.JobType in (@SupervisorTitleText, @ManagerTitleText)
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
			 or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
			 or (@CustTier is null or @CustTier = ''))
	   and (@EventType is null or @EventType = '' or evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes))
	 union all
	select emp.CardNum, emp.NameFirst, emp.NameLast, emp.JobType, evt.EventDisplay, MEALbkEntries = 0, MEALbkSignatures = 1
	  from SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
		on emp.CardNum = ml.EmpNumWitness3
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	 where ml.tOut >= @StartDt and ml.tOut < @EndDt 
	   and emp.JobType in (@SupervisorTitleText, @ManagerTitleText)
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
			 or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
			 or (@CustTier is null or @CustTier = ''))
	   and (@EventType is null or @EventType = '' or evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes))
	 union all
	select emp.CardNum, emp.NameFirst, emp.NameLast, emp.JobType, evt.EventDisplay, MEALbkEntries = 0, MEALbkSignatures = 1
	  from SQLA_MEAL as ml
	 inner join SQLA_Employees as emp
		on emp.CardNum = ml.EmpNumWitness4
	  left join SQLA_EventDetails as evt
		on evt.PktNum = ml.ParentEventID
	 where ml.tOut >= @StartDt and ml.tOut < @EndDt 
	   and emp.JobType in (@SupervisorTitleText, @ManagerTitleText)
	   and (    (evt.CustTierLevel in (select CustTier from #RTA_Compliance_CustTiers))
			 or ((evt.CustTierLevel = '' or evt.CustTierLevel is null) and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
			 or (@CustTier is null or @CustTier = ''))
	   and (@EventType is null or @EventType = '' or evt.EventDisplay is null or evt.EventDisplay in (select EventType from #RTA_Compliance_EventTypes))
		) as t
	 group by CardNum, NameFirst, NameLast, JobType, EventDisplay ) as p
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, EventDisplay
END




GO


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_CustTiers]    Script Date: 04/21/2016 12:59:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_CustTiers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_CustTiers]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_CustTiers] 
	@IncludeALL int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @IncludeALL = 0
	BEGIN
		select TierLevel, PriorityLevel
		  from SQLA_CustTiers
		 order by PriorityLevel desc, TierLevel
	END
	
	IF @IncludeALL = 1
	BEGIN
		select TierLevel = 'ALL', PriorityLevel = -1
		 union all
		select TierLevel, PriorityLevel
		  from SQLA_CustTiers
		 order by PriorityLevel desc, TierLevel
	END
END




GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EmpJobTypes]    Script Date: 06/27/2016 12:40:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EmpJobTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EmpJobTypes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EmpJobTypes]
	@IncludeAll int = 1,
	@HostOnly int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @IncludeAll = 1
	BEGIN
		select JobType = 'All', JobTypeOrd = ''
		 union all
		select JobType, JobTypeOrd = JobType from SQLA_EmpJobTypes
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by 2
	END
	
	ELSE
	BEGIN
		select JobType, JobTypeOrd = JobType from SQLA_EmpJobTypes
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by 2
	END
END







GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Employees]    Script Date: 07/26/2016 06:26:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Employees]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Employees]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Employees] 
	@IncludeAll int = 1,
	@HostOnly int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @IncludeAll = 1
	BEGIN
		select CardNum = '', 
			   NameFirst = '',
			   NameLast = '',
			   JobType = 'All',
			   NameDisplay = 'All',
			   DisplayOrd = 0
		 union all
		select CardNum = LTRIM(rtrim(CardNum)), isnull(NameFirst,''), isnull(NameLast,''), isnull(JobType,''),
			   NameDisplay = '(' + left(isnull(JobType,''),1) + ') ' + isnull(NameFirst,'') + ' ' + isnull(NameLast,''),
			   ROW_NUMBER() OVER(ORDER BY JobType, NameFirst, NameLast, CardNum ASC) AS DisplayOrd
		  from SQLA_Employees
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by DisplayOrd
	END
	
	ELSE
	BEGIN
		select CardNum = LTRIM(rtrim(CardNum)), isnull(NameFirst,''), isnull(NameLast,''), isnull(JobType,''),
			   NameDisplay = '(' + left(isnull(JobType,''),1) + ') ' + isnull(NameFirst,'') + ' ' + isnull(NameLast,'')
		  from SQLA_Employees
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by JobType, NameFirst, NameLast, CardNum
	END
END



GO


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

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]    Script Date: 02/21/2016 18:59:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]
	@StartDt datetime,
	@EndDt datetime,
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@AsnRspOnly int = 0,
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
	DECLARE @EmpJobType1 varchar(2000) = @EmpJobType
	DECLARE @EventType1 varchar(2000) = @EventType
	DECLARE @AsnRspOnly1 int = @AsnRspOnly
	DECLARE @IncludeOOS1 int = @IncludeOOS
	DECLARE @IncludeEMPCARD1 int = @IncludeEMPCARD
	
	-- CREATE TABLE OF Compliance Employee
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_Employee_Tmp'))
    BEGIN
		drop table dbo.#RTA_Compliance_Employee_Tmp;
    END    
    
    create table #RTA_Compliance_Employee_Tmp (
		EmpNum nvarchar(255),
		EmpNameFirst nvarchar(255),
		EmpNameLast nvarchar(255),
		EmpJobType nvarchar(255),
		PktNum int,
		EventDisplay nvarchar(255),
		Location nvarchar(255),
		Asn int,
		Acp int,
		Rsp int,
		Cmp int,
		CmpMobile int,
		RejMan int,
		RejAuto int,
		RspRTA int,
		RspCard int,
		RspRTAandCard int,
		RspTmSec int,
		OverallTmSec int,
		AsnOther int,
		ShiftName nvarchar(255), 
		ShiftOrder int,
		CustTier nvarchar(255),
		tOutHour int,
		EvtDay date,
		MEALbkEntries int,
		MEALbkSignatures int
    )
	
	INSERT INTO dbo.#RTA_Compliance_Employee_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_Compliance_Employee @StartDt=@StartDt1, @EndDt=@EndDt1, @EmpJobType=@EmpJobType1, @EventType=@EventType1, @AsnRspOnly=@AsnRspOnly1, @IncludeOOS=@IncludeOOS1, @IncludeEMPCARD=@IncludeEMPCARD1
	
	
	
	-- CREATE TABLE OF Compliance Employee
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_Employee_Tot_Tmp'))
    BEGIN
		drop table dbo.#RTA_Compliance_Employee_Tot_Tmp;
    END    
    
    create table #RTA_Compliance_Employee_Tot_Tmp (
		EmpNum nvarchar(255),
		AsnTot int,
		RspNotAsnTot int
	)
	
	INSERT INTO #RTA_Compliance_Employee_Tot_Tmp 
	SELECT EmpNum, AsnTot = SUM(Asn), RspNotAsnTot = SUM(case when Rsp > 0 and Asn = 0 then 1 else 0 end)
	  FROM dbo.#RTA_Compliance_Employee_Tmp
	 GROUP BY EmpNum
	
	
	
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'NotAcp,RejAuto',
	       StateCount = count(*),
	       Total = t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'NotAcp,RejMan',
	       StateCount = count(*),
	       Total = t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,RejMan',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,RejAuto',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,Rsp,RejMan',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,Rsp,RejAuto',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejAuto,Acp,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejMan,Acp,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejMan,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejAuto,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Rsp,Not Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp = 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Taken',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp >= 0 and c.Rsp = 0 and c.Cmp = 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,Cmp',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	   and c.EventDisplay <> 'JKPT'
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'JP VER',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	   and c.EventDisplay = 'JKPT'
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,Not Cmp',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp = 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,RejAuto',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,RejMan',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
END


GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]    Script Date: 06/21/2016 11:45:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@EventType varchar(255) = '',
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@CustNum varchar(10) = '',
	@MinRspMins int = 0,
	@MinCmpMins int = 0,
	@MinOverallMins int = 0,
	@ResDesc int = 0,
	@EmpJobType nvarchar(2000) = '',
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
	DECLARE @EventType1 varchar(255) = @EventType
	DECLARE @ZoneArea1 varchar(255) = @ZoneArea
	DECLARE @CustTier1 varchar(255) = @CustTier
	DECLARE @CustNum1 varchar(10) = @CustNum
	DECLARE @MinRspMins1 int = @MinRspMins
	DECLARE @MinCmpMins1 int = @MinCmpMins
	DECLARE @MinOverallMins1 int = @MinOverallMins
	DECLARE @ResDesc1 int = @ResDesc
	
	
	-- CREATE TABLE OF JobTypes
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_ExecSum_Emp_JobTypes'))
    BEGIN
		drop table dbo.#RTA_EventDetails_ExecSum_Emp_JobTypes;
    END    
    
    create table #RTA_EventDetails_ExecSum_Emp_JobTypes (
		JobType nvarchar(20) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_EventDetails_ExecSum_Emp_JobTypes (JobType)
    select distinct left(ltrim(rtrim(val)),20) from dbo.fn_String_To_Table(@EmpJobType, ',', 1)
	
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 (
		CardNum nvarchar(20),
		EmpName nvarchar(255),
		Activity nvarchar(255),
		ActivityType int,
		ActivitySecs int,
		ActivityOrd int
	)
	
	INSERT INTO dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 (CardNum, EmpName, Activity, ActivityType, ActivitySecs, ActivityOrd)
	select EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1) + '.',
	       Activity = case when PktNum in (1,2,3) then EventDisplay else 'Event' end,
	       ActivityType = case when PktNum in (1,2,3) then PktNum else 5 end,
	       ActivitySecs = SUM(ActivitySecs),
	       ActivityOrd = case when PktNum = 1 then 3 -- BREAK
	                          when PktNum = 2 then 4 -- OOS
	                          when PktNum = 3 then 1 -- Available
	                          when PktNum not in (1,2,3) then 2 end
	  from SQLA_EmployeeEventTimes as et
	 inner join SQLA_Employees as e
	    on e.CardNum = et.EmpNum
	 where ActivityStart >= @StartDt1 and ActivityStart < @EndDt1
	   and ((@IncludeOOS = 0 and PktNum not in (2)) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and ((@EmpJobType = '') or (@EmpJobType = 'All') or (@EmpJobType = EmpJobType))
	 group by EmpNum, EmpNameFirst, EmpNameLast,
	       case when PktNum in (1,2,3) then EventDisplay else 'Event' end,
	       case when PktNum in (1,2,3) then PktNum else 5 end,
	       case when PktNum = 1 then 3 -- BREAK
	            when PktNum = 2 then 4 -- OOS
	            when PktNum = 3 then 1 -- Available
	            when PktNum not in (1,2,3) then 2 end
	

	
	SELECT act.CardNum, act.EmpName, act.Activity, act.ActivityType, act.ActivitySecs, ActivityOrd
	  FROM dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 as act
	 WHERE act.ActivityType <> 3
	 UNION ALL
	SELECT act.CardNum, act.EmpName, act.Activity, act.ActivityType, ActivitySecs = act.ActivitySecs-SUM(isnull(act2.ActivitySecs,0)), act.ActivityOrd
	  FROM dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 as act
	  LEFT JOIN dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 as act2
	    ON act2.CardNum = act.CardNum
	   AND act2.ActivityType <> 3
	 WHERE act.ActivityType = 3
	 GROUP BY act.CardNum, act.EmpName, act.Activity, act.ActivityType, act.ActivitySecs, act.ActivityOrd
	
END








GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]    Script Date: 07/21/2016 12:17:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]
	@StartDt datetime,
	@EndDt datetime,
	@UtilType int = 0,
	@EmpJobType nvarchar(2000) = '',
	@EventSum int = 0,
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1,
	@UseQuartile int = 0,
	@RspAnalysis int = 0

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp2 (
		EmpNum nvarchar(255),
		EmpName nvarchar(255),
		EmpJobType nvarchar(255),
		PktNum int,
		EventDisplay nvarchar(255),
		StatOrd int,
		Stat nvarchar(255),
		StatStart datetime,
		StatEnd datetime,
		StatSecs int
	)
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 (
		EmpNum nvarchar(255),
		MinActivityStart datetime,
		MaxActivityEnd datetime,
		StatSecs int
	)
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 (
		EmpNum nvarchar(255),
		StatSecs int
	)
	
	
	-- CREATE TABLE OF JobTypes
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_ExecSum_Emp2_JobTypes'))
    BEGIN
		drop table dbo.#RTA_EventDetails_ExecSum_Emp2_JobTypes;
    END    
    
    create table #RTA_EventDetails_ExecSum_Emp2_JobTypes (
		JobType nvarchar(20) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_EventDetails_ExecSum_Emp2_JobTypes (JobType)
    select distinct left(ltrim(rtrim(val)),20) from dbo.fn_String_To_Table(@EmpJobType, ',', 1)
	
	
	-- AVAILABLE
	insert into #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 (EmpNum,MinActivityStart,MaxActivityEnd,StatSecs)
	select EmpNum, 
	       MinActivityStart = min(ActivityStart),
		   MaxActivityEnd = max(ActivityEnd),
	       StatSecs = sum(case when ActivityEnd > @EndDt and ActivityStart < @StartDt then datediff(second,@StartDt,@EndDt)
                               when ActivityEnd < @EndDt and ActivityStart < @StartDt then datediff(second,@StartDt,ActivityEnd)
                               when ActivityEnd > @EndDt and ActivityStart > @StartDt then datediff(second,ActivityStart,@EndDt)
                               else datediff(second,ActivityStart,ActivityEnd) end)
	  from SQLA_EmployeeEventTimes
	 where PktNum = 3 and ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and (EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	 group by EmpNum
	   
	
	-- Stat Ords
	--   1 = Break
	--   2 = OOS
	--   3 = Available
	--   4 = OpnToAsn
	--   5 = AsnToAcp / AsnToRej
	--   6 = AcpToRsp
	--   7 = AsnRspToNotCmp
	--   8 = AsnRspToCmp
	--   9 = TknToNotCmp
	--  10 = TknToCmp
	--  11 = JP Ver
	
	
	-- EVENT OpnToAsn
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select EmpNum = '', EmpName = '', EmpJobType = '', et.PktNum, et.EventDisplay, 
	       StatOrd = 4, Stat = 'OpnToAsn', StatStart = ed.tOut, StatEnd = min(isnull(isnull(et.tAsn,et.tRea),et.tRsp))
	  from SQLA_EmployeeEventTimes as et
	 inner join SQLA_EventDetails as ed
	    on ed.PktNum = et.PktNum
	 where ed.tOut >= @StartDt and ed.tOut < @EndDt and (et.tAsn is not null or et.tRea is not null or et.tRsp is not null) and @UtilType = 1
	   and ((@IncludeEMPCARD = 0 and et.EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and ed.tOut <= isnull(isnull(et.tAsn,et.tRea),et.tRsp)
	 group by et.PktNum, et.EventDisplay, ed.tOut
	 
	 
	-- ASSIGNED EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 5, Stat = 'AsnToAcp', StatStart = isnull(tAsn,tRea), StatEnd = isnull(isnull(isnull(tAcp,tRsp),tCmp),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRej is null and isnull(tAsn,tRea) < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 5, Stat = 'AsnToRej', StatStart = isnull(tAsn,tRea), StatEnd = tRej
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRej is not null and isnull(tAsn,tRea) < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 6, Stat = 'AcpToRsp', StatStart = tAcp, StatEnd = isnull(isnull(isnull(tRsp,tCmp),tRej),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tAcp is not null and tAcp < @EndDt and (tRsp is not null or tCmp is not null)

	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 61, Stat = 'AcpToRej', StatStart = tAcp, StatEnd = isnull(isnull(isnull(tRsp,tCmp),tRej),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tAcp is not null and tAcp < @EndDt and tRsp is null and tCmp is null
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 7, Stat = 'AsnRspToNotCmp', StatStart = tRsp, StatEnd = isnull(tRej,ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRsp is not null and tCmp is null and tRsp < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 8, Stat = 'AsnRspToCmp', StatStart = tRsp, StatEnd = tCmp
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRsp is not null and tCmp is not null and tRsp < @EndDt
	   
	   
	-- TAKEN EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 9, Stat = 'TknToNotCmp', StatStart = tRsp, StatEnd = isnull(tRej,ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	  left join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt 
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and tRsp is not null and tRsp < @EndDt
	   and ((tAsn is null and tRea is null) or (tAsn is not null and DATEDIFF(SECOND,tAsn,tRsp) <= 1))
	   and tCmp is null
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 10, Stat = 'TknToCmp', StatStart = tRsp, StatEnd = tCmp
	  from SQLA_EmployeeEventTimes as et
	  left join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and tRsp is not null and tRsp < @EndDt
	   and ((tAsn is null and tRea is null) or (tAsn is not null and DATEDIFF(SECOND,tAsn,tRsp) <= 1))
	   and tCmp is not null
	   and EventDisplay not like 'JKPT%' and EventDisplay not in ('JP VER')
	   
	   
	-- JP VER EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
		   StatOrd = 11, Stat = EventDisplay, StatStart = tOut, StatEnd = tComplete
	  from SQLA_EventDetails_JPVER as et
	  left join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
		on a.EmpNum = et.EmpNum
	   and tOut >= MinActivityStart and tComplete <= MaxActivityEnd
	 where tOut < @EndDt and tComplete > @StartDt
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   
	   
	-- OOS / BREAK
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
		   StatOrd = case when PktNum = 1 then 1 -- Break
						  when PktNum = 2 then 2 -- OOS
						  end,
		   Stat = EventDisplay, StatStart = ActivityStart, StatEnd = ActivityEnd
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and PktNum in (1,2) and ActivityStart >= @StartDt and ActivityStart < @EndDt
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and @UtilType = 0 and ((@IncludeOOS = 0 and PktNum not in (2)) or (@IncludeOOS = 1))
		
	
	-- UPDATE StatSecs
	delete from #RTA_EventDetails_ExecSum_Emp2_Tmp2
	 where StatEnd < @StartDt
	
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatStart = @StartDt
	 where StatStart < @StartDt
	 
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatEnd = @EndDt
	 where StatEnd > @EndDt
	   
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatSecs = datediff(second,StatStart,StatEnd)
	
	
	-- TOTAL OTHER
	insert into #RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 (EmpNum,StatSecs)
	select EmpNum, StatSecs = sum(isnull(StatSecs,0))
	  from #RTA_EventDetails_ExecSum_Emp2_Tmp2
	 where @UtilType = 0
	 group by EmpNum
	
	
	-- INSERT AVAILABLE
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatSecs,StatStart,StatEnd)
	select a.EmpNum, EmpName = '', EmpJobType = '', PktNum = 3, EventDisplay = 'Available', StatOrd = 3, Stat = 'Available', 
	       StatSecs = a.StatSecs - isnull(o.StatSecs,0), 
		   MinActivityStart = case when MinActivityStart < @StartDt then @StartDt else MinActivityStart end, 
		   MaxActivityEnd = case when MaxActivityEnd > @EndDt then @EndDt else MaxActivityEnd end
	  from #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	  left join #RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 as o
	    on a.EmpNum = o.EmpNum
	 where @UtilType = 0
		
	
	
	-- RETURN table
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3 (
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
	
	
	insert into dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3 (EmpNum, EmpName, EmpJobType, PktNum, EventDisplay, StatOrd, Stat, StatSecs, StatStart, StatEnd)
	select u.EmpNum,
	       EmpName = case when isnull(u.EmpName,'') = '' and isnull(e.NameFirst,'') <> '' then e.NameFirst + ' ' + left(e.NameLast,1)
	                      when isnull(u.EmpName,'') = '' and isnull(e.NameFirst,'') = '' then u.EmpNum
						  else u.EmpName end,
	       EmpJobType = case when isnull(u.EmpJobType,'') = '' then e.JobType else u.EmpJobType end, 
		   u.PktNum, 
		   EventDisplay = case when u.EventDisplay like 'JKPT%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) < 1200 then 'JKPT<1200'
	                           when u.EventDisplay like 'JKPT%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) >= 1200 then 'JKPT>=1200'
							   when u.EventDisplay like 'JP%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) < 1200 then 'JKPT<1200'
	                           when u.EventDisplay like 'JP%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) >= 1200 then 'JKPT>=1200'
							   when u.EventDisplay like 'PROG%' or u.EventDisplay like 'PJ%' then 'PROG'
							   when u.EventDisplay like 'PJ%' then 'PJ'
							   when u.EventDisplay like 'EMPCARD%' then 'EMPCARD'
							   when u.EventDisplay like 'REEL%' then 'REEL'
							   when u.EventDisplay like 'OOS%' then 'OOS'
							   else u.EventDisplay end,
	       u.StatOrd,
		   Stat = case when @EventSum = 1 and u.StatOrd not in (3,4,1,2) then 'EVENT'
                       when @EventSum = 2 then case when u.StatOrd = 4 then 'Asn'  --OpnToAsn
					                                when u.StatOrd = 5 then 'Acp'  --AsnToAcp/Rej
											        when u.StatOrd = 6 then 'Rsp'  --AcpToRsp
													when u.StatOrd = 61 then 'Rsp'  --AcpToRej
											        when u.StatOrd = 7 then 'Cmp'  --AsnRspToNotCmp
											        when u.StatOrd = 8 then 'Cmp'  --AsnRspToCmp
											        when u.StatOrd = 9 then 'Cmp'  --TknToNotCmp
											        when u.StatOrd = 10 then 'Cmp' --TknToCmp
													when u.StatOrd = 11 then 'Cmp' --JP VER
											        else u.Stat end
					   else case when u.StatOrd = 2 then 'OOS'
					             else u.Stat end end, 
		   u.StatSecs,
		   u.StatStart,
		   u.StatEnd
	  from #RTA_EventDetails_ExecSum_Emp2_Tmp2 as u
	  left join SQLA_Employees as e
	    on u.EmpNum = e.CardNum
	  left join SQLA_EventDetails as d
	    on d.PktNum = u.PktNum
	  
	
	IF (@UseQuartile <> 0 or @RspAnalysis <> 0)
	BEGIN
		DECLARE @IntervalMins int = 15
		DECLARE @Mode nvarchar(20) = isnull((select Setting from SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'AssocAreaMode'),'')
		
		IF OBJECT_ID('tempdb..#RTA_Dttm_Tmp') is not null
		BEGIN
			drop table dbo.#RTA_Dttm_Tmp;
		END 

		CREATE TABLE dbo.#RTA_Dttm_Tmp (
			DttmValue datetime
		)

		TRUNCATE TABLE dbo.#RTA_Dttm_Tmp

		INSERT INTO dbo.#RTA_Dttm_Tmp (DttmValue) VALUES (@StartDt)

		WHILE ((SELECT MAX(DttmValue) FROM dbo.#RTA_Dttm_Tmp) < @EndDt)
		BEGIN  
			INSERT INTO dbo.#RTA_Dttm_Tmp (DttmValue)
			select dateadd(minute,@IntervalMins,MAX(DttmValue)) from dbo.#RTA_Dttm_Tmp
		END 
		
		
		
		IF OBJECT_ID('tempdb..#RTA_EvtStatus_Quartiles') is not null
		BEGIN
			drop table dbo.#RTA_EvtStatus_Quartiles;
		END 

		CREATE TABLE dbo.#RTA_EvtStatus_Quartiles (
			DttmValue datetime,
			EmpNum nvarchar(255),
			EmpName nvarchar(255),
			EmpJobType nvarchar(255),
			PktNum int,
			EventDisplay nvarchar(255),
			StatOrd int,
			Stat nvarchar(255),
			StatStart datetime,
			StatEnd datetime,
			ToArea nvarchar(10),
			FromArea nvarchar(10),
			Distance int,
			CustPriorityLevel int,
			CustTierLevel nvarchar(10)
		)
				
		TRUNCATE TABLE dbo.#RTA_EvtStatus_Quartiles

		INSERT INTO dbo.#RTA_EvtStatus_Quartiles (DttmValue, EmpNum, EmpName, EmpJobType, PktNum, EventDisplay, StatOrd, Stat, StatStart, StatEnd, ToArea, FromArea, Distance, CustPriorityLevel, CustTierLevel)
		select d.DttmValue,
		       e.EmpNum,
			   e.EmpName,
			   e.EmpJobType,
			   e.PktNum,
			   e.EventDisplay,
			   e.StatOrd,
			   e.Stat,
			   StatStart = case when e.StatStart < d.DttmValue then d.DttmValue else e.StatStart end,
			   StatEnd = case when e.StatEnd > dateadd(minute,@IntervalMins,d.DttmValue) then dateadd(minute,@IntervalMins,d.DttmValue) else e.StatEnd end,
		       ToArea = ltrim(rtrim(v.Zone)),
			   FromArea = case when v.FromZone is not null and v.FromZone <> '' then ltrim(rtrim(v.FromZone)) else ltrim(rtrim(v.Zone)) end,
			   Distance = ISNULL(a.Priority,0),
			   v2.CustPriorityLevel,
			   v2.CustTierLevel
		  from dbo.#RTA_Dttm_Tmp as d
		  left join dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3 as e
			on e.StatStart < dateadd(minute,@IntervalMins,d.DttmValue)
		   and e.StatEnd >= d.DttmValue
		  left join dbo.SQLA_EventDetails as v
		    on v.PktNum = e.PktNum
		   and v.EmpNumAsn = e.EmpNum
		   and e.StatOrd in (6,61)
		  left join SQLA_AreaAssoc as a
			on a.Area = v.FromZone
		   and a.AssocArea = v.Zone
		   and (a.Mode = @Mode or @Mode = '')
		  left join dbo.SQLA_EventDetails as v2
		    on v2.PktNum = e.PktNum
		 where e.EventDisplay not in ('JP VER')
		
		IF(@UseQuartile = 1 and @RspAnalysis = 0)
		BEGIN
			select DttmValue, /*EmpNum, EmpName, EmpJobType,*/ PktNum, EventDisplay, StatOrd, Stat, /*StatStart, StatEnd,*/ StatSecs = sum(isnull(datediff(second,StatStart,StatEnd),0)), StatMins = sum(isnull(datediff(second,StatStart,StatEnd),0)*1.0/60.0)
			  from dbo.#RTA_EvtStatus_Quartiles as t
			where isnull(datediff(second,StatStart,StatEnd),0) > 0
			group by DttmValue, PktNum, EventDisplay, StatOrd, Stat
		END
		
		IF(@UseQuartile = 1 and @RspAnalysis = 1)
		BEGIN
			select *, StatSecs = isnull(datediff(second,StatStart,StatEnd),0), StatMins = isnull(datediff(second,StatStart,StatEnd),0)*1.0/60.0
			  from dbo.#RTA_EvtStatus_Quartiles
			 where StatOrd = 6 and FromArea is not null
		END
		
		IF(@UseQuartile = 0 and @RspAnalysis = 1)
		BEGIN
		    select *,
			       FreqDist = case when t.StatSecs <= 5 then '5'
				                   when t.StatSecs > 5 and t.StatSecs <= 10 then '10'
				                   when t.StatSecs > 10 and t.StatSecs <= 30 then '30'
				                   when t.StatSecs > 30 and t.StatSecs <= 60 then '60'
				                   when t.StatSecs > 60 and t.StatSecs <= 120 then '120'
				                   when t.StatSecs > 120 and t.StatSecs <= 180 then '180'
				                   when t.StatSecs > 180 and t.StatSecs <= 300 then '300'
				                   when t.StatSecs > 300 and t.StatSecs <= 600 then '600'
				                   else '600+'end
			  from (
			select PktNum, EventDisplay, StatOrd, Stat, EvtArea = ToArea, EmpArea = FromArea, Distance, 
			       StatSecs = sum(isnull(datediff(second,StatStart,StatEnd),0)), StatMins = sum(isnull(datediff(second,StatStart,StatEnd),0)*1.0/60.0)
			  from dbo.#RTA_EvtStatus_Quartiles
			 where StatOrd = 6 and FromArea is not null
			 group by PktNum, EventDisplay, StatOrd, Stat, ToArea, FromArea, Distance ) as t
		END
		
		IF(@UseQuartile = 0 and @RspAnalysis = 2)
		BEGIN
			select EmpJobType = isnull(EmpJobType,'Attendant'), PktNum, EventDisplay, Distance, CustTierLevel,
			       AsnSecs = sum(case when StatOrd = 4 then datediff(second,StatStart,StatEnd) else 0 end),
				   AcpSecs = sum(case when StatOrd = 5 then datediff(second,StatStart,StatEnd) else 0 end),
				   RspSecs = sum(case when StatOrd = 6 then datediff(second,StatStart,StatEnd) else 0 end),
				   CmpSecs = sum(case when StatOrd in (7,8,9,10,11) then datediff(second,StatStart,StatEnd) else 0 end)
			  from dbo.#RTA_EvtStatus_Quartiles
			 group by isnull(EmpJobType,'Attendant'), PktNum, EventDisplay, Distance, CustTierLevel
		END
	END
	
	IF (@UseQuartile = 0 and @RspAnalysis = 0)
	BEGIN
		select * from dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3
	END
	
END



GO


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]    Script Date: 06/27/2016 12:48:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]
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
	@RspCmp int = 0,
	@EmpCmpJobType varchar(2000) = '',
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0

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
	DECLARE @EmpCmpJobType1 varchar(2000) = @EmpCmpJobType
	
	-- CREATE TABLE OF FreqDist_Bins
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_FreqDist_Bins'))
    BEGIN
		drop table dbo.#RTA_FreqDist_Bins;
    END    
    
    create table #RTA_FreqDist_Bins (
		BinID int NOT NULL PRIMARY KEY,
		BinDisplay nvarchar(11),
		BinMin int,
		BinMax int
    )
    
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (0, '0-:30', 0, 30)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (1, ':30-1:00', 30, 60)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (2, '1:00-2:00', 60, 120)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (3, '2:00-3:00', 120, 180)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (4, '3:00-5:00', 180, 300)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (5, '5:00-10:00', 300, 600)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (6, '>= 10:00', 600, 0)
    
    	
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
		AsnSecs int,
		ReaSecs int,
		AcpSecs int,
		RejSecs int
	)
	
	
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt1, @EndDt = @EndDt1, @MaxCmpMins = @MaxCmpMins1, @EventType = @EventType1, @ZoneArea = @ZoneArea1, @CustTier = @CustTier1, @CustNum = @CustNum1, @MinRspMins = @MinRspMins1, @MinCmpMins = @MinCmpMins1, @MinOverallMins = @MinOverallMins1, @ResDesc = @ResDesc1, @EmpCmpJobType = @EmpCmpJobType1, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD

	
	-- CREATE TABLE OF RTA_EventDetails_Sum_Tmp
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_Sum_Tmp'))
    BEGIN
		drop table dbo.#RTA_EventDetails_Sum_Tmp;
    END    
    
    create table dbo.#RTA_EventDetails_Sum_Tmp (
		CustTierLevel varchar(255),
		ThresholdSecsMin int,
		ThresholdSecsMax int,
		ThresholdDescr varchar(255),
		ThresholdOrder int,
		EventCount int,
		HasThreshold varchar(1)
    )
    
    IF (@RspCmp = 0)
	BEGIN
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = b.BinMin,
			   ThresholdSecsMax = b.BinMax,
			   ThresholdDescr = b.BinDisplay,
			   ThresholdOrder = b.BinID,
			   EventCount = COUNT(*),
			   HasThreshold = 'N'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join #RTA_FreqDist_Bins as b
			on (b.BinMin <= e.RspSecs)
		   and (b.BinMax >  e.RspSecs or b.BinMax = 0)
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, b.BinMin, b.BinMax, b.BinDisplay, b.BinID
		       
		/*
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = case when e.RspSecs <  t.ThresholdSecs then 0
									   when e.RspSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   ThresholdSecsMax = case when e.RspSecs <  t.ThresholdSecs then t.ThresholdSecs
									   when e.RspSecs >= t.ThresholdSecs then 0 end,
			   ThresholdDescr = case when e.RspSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
									 when e.RspSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   ThresholdOrder = case when e.RspSecs <  t.ThresholdSecs then 0
									 when e.RspSecs >= t.ThresholdSecs then 1 end,
			   EventCount = COUNT(*),
			   HasThreshold = 'Y'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join (select l.TierLevel, 
							ThresholdSecs = (cast(left(s.Setting,(LEN(s.Setting)-6)) as int) * 60 * 60)
										  + (cast(right(left(s.Setting,(LEN(s.Setting)-3)),2) as int) * 60)
										  + cast(right(s.Setting,2) as int)
					   from RTSS.dbo.SYSTEMSETTINGS as s
					  inner join (select distinct TierLevel from dbo.SQLA_CustTiers) as l
						 on cast(l.TierLevel as varchar) + cast('.RED' as varchar) = s.ConfigParam
					  where s.ConfigSection = 'TimeParams'
					    and Setting is not null and Setting <> '') as t
			on t.TierLevel = isnull(e.CustTierLevel,'')
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, 
			   case when e.RspSecs <  t.ThresholdSecs then 0
					when e.RspSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   case when e.RspSecs <  t.ThresholdSecs then t.ThresholdSecs
					when e.RspSecs >= t.ThresholdSecs then 0 end,
			   case when e.RspSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
					when e.RspSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   case when e.RspSecs <  t.ThresholdSecs then 0
					when e.RspSecs >= t.ThresholdSecs then 1 end
		*/
	END
	
	
	IF (@RspCmp = 1)
	BEGIN
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = b.BinMin,
			   ThresholdSecsMax = b.BinMax,
			   ThresholdDescr = b.BinDisplay,
			   ThresholdOrder = b.BinID,
			   EventCount = COUNT(*),
			   HasThreshold = 'N'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join #RTA_FreqDist_Bins as b
			on (b.BinMin <= e.CmpSecs)
		   and (b.BinMax >  e.CmpSecs or b.BinMax = 0)
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, b.BinMin, b.BinMax, b.BinDisplay, b.BinID
		       
		/*
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = case when e.CmpSecs <  t.ThresholdSecs then 0
									   when e.CmpSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   ThresholdSecsMax = case when e.CmpSecs <  t.ThresholdSecs then t.ThresholdSecs
									   when e.CmpSecs >= t.ThresholdSecs then 0 end,
			   ThresholdDescr = case when e.CmpSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
									 when e.CmpSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   ThresholdOrder = case when e.CmpSecs <  t.ThresholdSecs then 0
									 when e.CmpSecs >= t.ThresholdSecs then 1 end,
			   EventCount = COUNT(*),
			   HasThreshold = 'Y'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join (select l.TierLevel, 
							ThresholdSecs = (cast(left(s.Setting,(LEN(s.Setting)-6)) as int) * 60 * 60)
										  + (cast(right(left(s.Setting,(LEN(s.Setting)-3)),2) as int) * 60)
										  + cast(right(s.Setting,2) as int)
					   from RTSS.dbo.SYSTEMSETTINGS as s
					  inner join (select distinct TierLevel from dbo.SQLA_CustTiers) as l
						 on cast(l.TierLevel as varchar) + cast('.RED' as varchar) = s.ConfigParam
					  where s.ConfigSection = 'TimeParams'
					    and Setting is not null and Setting <> '') as t
			on t.TierLevel = isnull(e.CustTierLevel,'')
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, 
			   case when e.CmpSecs <  t.ThresholdSecs then 0
					when e.CmpSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   case when e.CmpSecs <  t.ThresholdSecs then t.ThresholdSecs
					when e.CmpSecs >= t.ThresholdSecs then 0 end,
			   case when e.CmpSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
					when e.CmpSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   case when e.CmpSecs <  t.ThresholdSecs then 0
					when e.CmpSecs >= t.ThresholdSecs then 1 end
		*/
	END       
	       
	
	select s1.CustTierLevel, s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, EventCount = s1.EventCount,
	       PctTotal = s1.EventCount*1.0 / SUM(s2.EventCount)*1.0, s1.HasThreshold, c.PriorityLevel
	  from dbo.#RTA_EventDetails_Sum_Tmp as s1
	 inner join dbo.#RTA_EventDetails_Sum_Tmp as s2
	    on s1.CustTierLevel = s2.CustTierLevel
	  left join SQLA_CustTiers as c
	    on c.TierLevel = s1.CustTierLevel
	 group by s1.CustTierLevel, s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, s1.EventCount, s1.HasThreshold, c.PriorityLevel
	 union all
	select 'ALL', s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, EventCount = sum(s1.EventCount), 
	       PctTotal = 1.0, s1.HasThreshold, -1
	  from dbo.#RTA_EventDetails_Sum_Tmp as s1
	 group by s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, s1.HasThreshold
	
END






GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDistance]    Script Date: 06/21/2016 11:24:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDistance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDistance]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDistance]
	@StartDt datetime,
	@EndDt datetime,
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0,
	@MinRspSecs int = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    
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
		AsnSecs int,
		ReaSecs int,
		AcpSecs int,
		RejSecs int
	)
		
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt, @EndDt = @EndDt, @ZoneArea = @ZoneArea, @CustTier = @CustTier, @EmpCmpJobType = @EmpJobType, @EventType = @EventType, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD, @MinRspSecs = @MinRspSecs
    
    
    
	select Distance = ISNULL(a.Priority,0), ToArea = ltrim(rtrim(e.Zone)), FromArea = case when e.FromZone is not null and e.FromZone <> '' then ltrim(rtrim(e.FromZone)) else ltrim(rtrim(e.Zone)) end,
	       EventCount = COUNT(*),
	       SupervisorAssign = SUM(case when (e.EmpCmpJobType in ('Supervisor','Manager')) and (e.EmpCmpAsnTaken = 'Asn') then 1 else 0 end),
	       Reassign = SUM(e.Reassign),
	       ReassignSupervisor = SUM(e.ReassignSupervisor),
	       AttendantAssign = SUM(case when (e.EmpCmpJobType = 'Attendant') and (e.EmpCmpAsnTaken = 'Asn') then 1 else 0 end),
	       AttendantTake = SUM(case when (e.EmpCmpJobType = 'Attendant') and (e.EmpCmpAsnTaken = 'Take') then 1 else 0 end),
	       SupervisorTake = SUM(case when (e.EmpCmpJobType in ('Supervisor','Manager')) and (e.EmpCmpAsnTaken = 'Take') then 1 else 0 end),
	       EmpComplete
	  from dbo.#RTA_EventDetails_Tmp as e
	  left join SQLA_AreaAssoc as a
		on a.Area = e.FromZone
	   and a.AssocArea = e.Zone
	 group by a.Priority, e.Zone, e.FromZone, EmpComplete
	 
END



GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDistanceDetail]    Script Date: 06/21/2016 11:24:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDistanceDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDistanceDetail]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDistanceDetail]
	@StartDt datetime,
	@EndDt datetime,
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0,
	@MinRspSecs int = 0,
	@Distance int = -1,
	@EmpComplete varchar(255) = '',
	@Mode nvarchar(20) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    
	-- CREATE TABLE OF EventDetails data
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
		AsnSecs int,
		ReaSecs int,
		AcpSecs int,
		RejSecs int
	)
		
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt, @EndDt = @EndDt, @ZoneArea = @ZoneArea, @CustTier = @CustTier, @EmpCmpJobType = @EmpJobType, @EventType = @EventType, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD, @MinRspSecs = @MinRspSecs, @EmpComplete = @EmpComplete 
    
    

	-- CREATE TABLE OF FreqDist_Bins
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_FreqDist_Bins'))
    BEGIN
		drop table dbo.#RTA_FreqDist_Bins;
    END    
    
    create table #RTA_FreqDist_Bins (
		BinID int NOT NULL PRIMARY KEY,
		BinDisplay nvarchar(11),
		BinMin int,
		BinMax int
    )
    
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (0, '0-:30', 0, 30)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (1, ':30-1:00', 30, 60)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (2, '1:00-2:00', 60, 120)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (3, '2:00-3:00', 120, 180)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (4, '3:00-5:00', 180, 300)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (5, '5:00-10:00', 300, 600)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (6, '>= 10:00', 600, 0)



	select t.*,
		   ThresholdSecsMin = b.BinMin,
		   ThresholdSecsMax = b.BinMax,
		   ThresholdDescr = b.BinDisplay,
		   ThresholdOrder = b.BinID
	  from (
	select e.PktNum, e.EventDisplay, e.CustTierLevel, e.EmpRespond,
	       Distance = ISNULL(a.Priority,0),
	       ToArea = ltrim(rtrim(e.Zone)),
		   FromArea = case when e.FromZone is not null and e.FromZone <> '' then ltrim(rtrim(e.FromZone)) else ltrim(rtrim(e.Zone)) end,
		   tTravel = case when e.tAuthorize is null then -1 when e.tAuthorize <= e.tAcpInit then 0 else DATEDIFF(second,e.tAcpInit,e.tAuthorize) end
	  from dbo.#RTA_EventDetails_Tmp as e
	  left join SQLA_AreaAssoc as a
		on a.Area = e.FromZone
	   and a.AssocArea = e.Zone
	   and (a.Mode = @Mode or @Mode = '')
	 where (@Distance = -1 or (@Distance = 0 and a.Priority is null) or (a.Priority is not null and a.Priority = @Distance)) ) as t
	 inner join #RTA_FreqDist_Bins as b
	    on (b.BinMin <= t.tTravel)
	   and (b.BinMax >  t.tTravel or b.BinMax = 0)
	 
END



GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventReject]    Script Date: 02/17/2016 21:00:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventReject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventReject]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[sp_SSRS_Rpt_RTA_EventReject]
	@StartDt datetime,
	@EndDt datetime,
	@EventType varchar(2000) = '',
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UseEmpName char(255) = (select isnull(Setting,'0') from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'UseEmpNamesInReports')
	
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
    select distinct left(ltrim(rtrim(val)),10) from dbo.fn_String_To_Table(@EventType, ',', 1)
	
	
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
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@ZoneArea, ',', 1)
	
	
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
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@CustTier, ',', 1)
	
	
	select PktNum,
		   Location,
		   EventDisplay = Activity, 
		   CustTierLevel = Tier,
		   tReject = er.tOut,
		   Employee = case when @UseEmpName = '1' and EmpName <> '' then EmpName
		                   when @UseEmpName = '1' and EmpName = '' and EmpNum <> '' then (select ltrim(rtrim(emp.NameFirst)) + ' ' + LEFT(ltrim(rtrim(emp.NameLast)),1)
		                                                                                    from SQLA_Employees as emp
		                                                                                   where emp.CardNum = er.EmpNum)
		                   else er.EmpNum end,
		   Reason = case when [Description] is null or [Description] = '' then State else [Description] end,
		   AfterDisplay = er.RejAfterDisp								 
	  from SQLA_FloorActivity as er
	 where er.tOut >= @StartDt and er.tout < @EndDt
	   and er.ActivityTypeID = 5
	   and er.State like '%Reject%'
	   and Source <> 'RTSSPPE'
	   and (er.Activity in (select EventType from #RTA_Compliance_EventTypes) or @EventType is null or @EventType = '')
	   and (er.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '')
	   and (    (er.Tier in (select CustTier from #RTA_Compliance_CustTiers))
	         or (er.Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	
END



GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventTypes]    Script Date: 02/20/2016 20:25:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventTypes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventTypes]
	@HostOnly int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select [EventType] = EventDisplay
	  from SQLA_EventTypes 
	 where (    (@HostOnly = 0)
	         or (@HostOnly = 1 and EventDisplay in ('GREET','BDAY','ANNIV','HI ACTN','EMPCARD','OOS')))
	 order by EventDisplay
END



GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_FloorActivity]    Script Date: 06/27/2016 07:14:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_FloorActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_FloorActivity]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_FloorActivity]
	@StartDt datetime,
	@EndDt datetime,
	@Location nvarchar(10) = '',
	@EmpNum nvarchar(40) = '',
	@DeviceID nvarchar(20) = '',
	@PktNum int = 0,
	@ActivityType int = 0,
	@UseEmpCmp int = 0,
	@Asn int = 0,
	@Acp int = 0,
	@Rsp int = 0,
	@Cmp int = 0,
	@RejAuto int = 0,
	@RejMan int = 0,
	@EventDisplay nvarchar(10) = '',
	@ViewMode int = 0,
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@RspVar varchar(11) = ''

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @RspVarMin int = -1
	DECLARE @RspVarMax int = 0
	
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @Location1 nvarchar(10) = @Location
	DECLARE @EmpNum1 nvarchar(40) = @EmpNum
	DECLARE @DeviceID1 nvarchar(20) = @DeviceID
	DECLARE @PktNum1 int = @PktNum
	DECLARE @ActivityType1 int = @ActivityType
		
	DECLARE @ServerIP varchar(15) = isnull((select ltrim(rtrim(Setting)) from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP'),'0.0.0.0')
	DECLARE @UseAssetField char(1) = isnull((select case when Setting = 'Asset' then '1' else '0' end from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),'0')
	
	IF @UseAssetField  = '1' 
	BEGIN
		SET @Location1 = isnull((select Asset from SQLA_Locations where Location = @Location1),@Location1)
	END 
	
	
	
	
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
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@ZoneArea, ',', 1)
	
	
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
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@CustTier, ',', 1)
	
	DECLARE @CustTiersAll int = isnull((select 1 from #RTA_Compliance_CustTiers where CustTier = 'ALL'),0)
	
	IF @CustTiersAll = 1
	BEGIN
		insert into #RTA_Compliance_CustTiers (CustTier)
		select TierLevel from SQLA_CustTiers where TierLevel not in (select CustTier from #RTA_Compliance_CustTiers)
		
		delete from #RTA_Compliance_CustTiers where CustTier = 'ALL'
	END
	
	
	
	-- CREATE TABLE OF FreqDist_Bins
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_FreqDist_Bins'))
    BEGIN
		drop table dbo.#RTA_FreqDist_Bins;
    END    
    
    create table #RTA_FreqDist_Bins (
		BinID int NOT NULL PRIMARY KEY,
		BinDisplay nvarchar(11),
		BinMin int,
		BinMax int
    )
    
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (0, '0-:30', 0, 30)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (1, ':30-1:00', 30, 60)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (2, '1:00-2:00', 60, 120)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (3, '2:00-3:00', 120, 180)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (4, '3:00-5:00', 180, 300)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (5, '5:00-10:00', 300, 600)
    insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (6, '>= 10:00', 600, 0)
	
	
	select @RspVarMin = isnull(BinMin,-1), @RspVarMax = isnull(BinMax,0)
	  from #RTA_FreqDist_Bins 
	 where BinDisplay = @RspVar
	
	
	
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_FloorActivity_Tmp'))
    BEGIN
		drop table dbo.#RTA_FloorActivity_Tmp;
    END    
    
    create table #RTA_FloorActivity_Tmp (
		Time datetime,
		State nvarchar(255),
		Activity nvarchar(255),
		Location nvarchar(255),
		PktNum int,
		Tier nvarchar(255),
		EmpNum nvarchar(255),
		EmpName nvarchar(255),
		JobType nvarchar(255),
		Source nvarchar(255),
		LastArea nvarchar(255),
		AsnArea nvarchar(255),
		ActivityTypeID int,
		LastLocation nvarchar(255),
		EmpStatusM int,
		EmpStatusJ int
    )
	
	IF @UseEmpCmp = 0
	BEGIN 
		insert into #RTA_FloorActivity_Tmp
		select distinct Time = f.tOut, 
		       State = f.State + (case when f.State = 'Complete' 
							           then (case when f.Source like '%.%.%.%' and f.Source <> @ServerIP and f.EmpName <> 'RTSSGUI' then ' Mobile'
										          when f.Source like '%.%.%.%' and (f.Source = @ServerIP or f.EmpName = 'RTSSGUI') then ' Workstation'
										          when f.Source = '~r:Dashboard' then ' Dashboard'
										          when f.Source = 'MGR Clear All' then ' MGR Clear All'
										          when ISNUMERIC(f.Source) = 1 then ' Game'
										          else '' end)
									   else '' end),
		       Activity = case when f.State = 'Auto Dispatch'
							   then (case when f.Description =  '0' then 'Not assigned'
								          when f.Description =  '1' then 'Assigned to employee'
								          when f.Description = '-2' then 'Not assigned, no employee available'
								          when f.Description = '-3' then 'Not assigned, higher priority event open'
								          else f.Description end)
		                       else f.Activity end,
			   Location = ltrim(rtrim(f.Location)), f.PktNum, f.Tier,
			   f.EmpNum, 
			   EmpName = case when e.CardNum is null then f.EmpName
			                  else ltrim(rtrim(e.NameFirst)) + ' ' + left(e.NameFirst,1) + '.' end,
			   e.JobType,
		       [Source] = case when f.Source in ('RTSSPPE','RTSS.exe') then 'Server'
							   when f.Source like '%.%.%.%' and f.Source = @ServerIP then 'Server'
							   when f.Source like '%.%.%.%' and f.Source <> @ServerIP and f.EmpName = 'RTSSGUI' then 'Workstation'
		                       when f.Source like '%.%.%.%' and f.Source <> @ServerIP and f.EmpName <> 'RTSSGUI' then 'Device'
							   when f.State = 'Reject Auto Server' then 'Server'
							   else ltrim(rtrim(f.[Source])) end,
		       LastArea = le.Zone,
			   AsnArea = case when len(ltrim(rtrim(zc.Activity))) < 14 then ''
		                      else right(ltrim(rtrim(zc.Activity)),len(ltrim(rtrim(zc.Activity)))-14) end,
		       f.ActivityTypeID,
			   LastLocation = le.Location,
			   EmpStatusM = sum(case when es.StatusCode = 'M' then 1 else 0 end),
			   EmpStatusJ = sum(case when es.StatusCode = 'J' then 1 else 0 end)
		  from SQLA_FloorActivity as f
		  left join SQLA_Employees as e
		    on e.CardNum = f.EmpNum
		  left join SQLA_FloorActivity as zc
			on zc.ActivityTypeID = 4
		   and zc.Activity like 'ZONES SERVED%'
		   and zc.EmpNum = f.EmpNum
		   and zc.EmpNum <> ''
		   and zc.tOut < f.tOut
		   and zc.tOut > DATEADD(hour,-8,f.tOut)
		  left join SQLA_FloorActivity as le
			on le.ActivityTypeID = 5
		   and le.State like 'Complete%'
		   and le.EmpNum = f.EmpNum
		   and le.EmpNum <> ''
		   and le.tOut < f.tOut
		   and le.tOut > DATEADD(hour,-8,f.tOut)
		  left join SQLA_EmployeeStatus as es
		    on es.EmpNum = f.EmpNum
		   and es.tStart <= f.tOut
		   and es.tEnd > f.tOut
		 where f.tOut >= @StartDt1 and f.tOut < @EndDt1
		   and (@Location1 = '' or @Location1 = f.Location)
		   and (@EmpNum1 = '' or @EmpNum1 = f.EmpNum)
		   and (@DeviceID1 = '' or @DeviceID1 = f.[Source])
		   and (@PktNum1 = 0 or @PktNum1 = f.PktNum)
		   and (    (f.Tier in (select CustTier from #RTA_Compliance_CustTiers))
			 	 or (f.Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
				 or (@CustTier is null or @CustTier = '' or @Custtier = 'All'))
		   and (f.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
		   and (    (@ActivityType1 = 0) or (@ActivityType1 = f.ActivityTypeID)
		         or (@ActivityType1 = 10 and f.ActivityTypeID = 5 and f.State in ('Reject Manual','Reassign Reject','Reassign Supervisor Reject','Reassign Reject Manual'))
				 or (@ActivityType1 = 11 and f.ActivityTypeID = 5 and (f.State like 'Reject Auto%' or f.State = 'Reassign Reject Auto')))
		   and (    (@ViewMode <> 0)
		         or (     @ViewMode = 0  -- States to ignore in Consolidated mode
				      and f.State not in ('Display Workstation','Re-assign','Reject','Remove','Reassign Reject Manual',
					                      'Get Event','Get Event Popup','Auto Dispatch','Alert Dismiss','Display Alert Popup',
										  'Device Notification Pushed','Device Notification Respond','Event Notification Mobile',
										  'BeepAssignedEvent','Display-NEW EVENT','InformAssignedEvent','VibrateAssignedEvent')
					  and not exists  -- Display only 1st 'Alert Accept'
						( select null from SQLA_FloorActivity as f2
		                   where f.State = 'Alert Accept' and f2.State = 'Alert Accept'
		                     and f2.PktNum = f.PktNum 
							 and f2.Description = f.Description
							 and f2.Activity = f.Activity
							 and f2.tOut < f.tOut) ))
		   and not exists
			 ( select * from SQLA_FloorActivity as zc2
				where zc2.ActivityTypeID = 4
				  and zc2.Activity like 'ZONES SERVED%'
				  and zc2.EmpNum = f.EmpNum
				  and zc2.tOut < f.tOut
		          and zc2.tOut > DATEADD(hour,-8,f.tOut)
				  and zc2.tOut > zc.tOut )
		   and not exists
			 ( select * from SQLA_FloorActivity as le2
				where le2.ActivityTypeID = 5
				  and le2.State like 'Complete%'
				  and le2.EmpNum = f.EmpNum
				  and le2.tOut < f.tOut
		          and le2.tOut > DATEADD(hour,-8,f.tOut)
				  and le2.tOut > le.tOut )
		 group by f.tOut, f.State, f.Source, f.Description, f.Activity, f.Location, f.PktNum, f.Tier,
		       f.EmpNum, e.CardNum, f.EmpName, e.NameFirst, e.NameFirst, e.JobType, f.[Zone], le.[Zone], zc.Activity, f.ActivityTypeID, le.Location
		 
		IF (@ViewMode = 0)  -- Consolidated mode
		BEGIN
			-- Add single instances of Beep/Vibrate
			insert into #RTA_FloorActivity_Tmp
			select Time = min(f.tOut), State = 'Beep/Vibrate',
				   f.Activity, Location = ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.EmpNum, f.EmpName, JobType = '',
				   [Source] = 'Device',
				   LastArea = '',
				   AsnArea = '',
				   f.ActivityTypeID,
				   LastLocation = '',
				   EmpStatusM = 0,
				   EmpStatusJ = 0
			  from SQLA_FloorActivity as f
			  left join SQLA_FloorActivity as na
				on na.ActivityTypeID = 5 and na.State in ('Assign')
			   and na.PktNum = f.PktNum
			   and na.tOut > f.tOut
			 where f.tOut >= @StartDt1 and f.tOut < @EndDt1
			   and (@Location1 = '' or @Location1 = f.Location)
			   and (@EmpNum1 = '' or @EmpNum1 = f.EmpNum)
			   and (@DeviceID1 = '' or @DeviceID1 = f.[Source])
			   and (@PktNum1 = 0 or @PktNum1 = f.PktNum)
			   and (    (f.Tier in (select CustTier from #RTA_Compliance_CustTiers))
					 or (f.Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
					 or (@CustTier is null or @CustTier = '' or @Custtier = 'All'))
			   and f.ActivityTypeID = 5 and f.State in ('BeepAssignedEvent','VibrateAssignedEvent')
			   and @ActivityType1 in (0,5)
			   and (f.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
			   and not exists
				 ( select null from SQLA_FloorActivity as na2
					where na2.ActivityTypeID = 5 and na2.State in ('Assign')
					  and na2.PktNum = na.PktNum
					  and na2.tOut > f.tOut
					  and na2.tOut < na.tOut )
			 group by na.tOut, f.Activity, ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.EmpNum, f.EmpName, f.ActivityTypeID
			
			
			-- Add single instances of Display Alert Popup
			insert into #RTA_FloorActivity_Tmp
			select Time = min(f.tOut), f.State,	f.Activity, Location = ltrim(rtrim(f.Location)), f.PktNum, f.Tier, 
			       EmpNum = cast(count(distinct [Source]) as varchar), EmpName = cast(count(distinct [Source]) as varchar),
				   JobType = '', [Source] = 'Device', LastArea = '', AsnArea = '', f.ActivityTypeID, LastLocation = '',
				   EmpStatusM = 0,
				   EmpStatusJ = 0
			  from SQLA_FloorActivity as f
			 where f.tOut >= @StartDt1 and f.tOut < @EndDt1
			   and (@Location1 = '' or @Location1 = f.Location)
			   and (@EmpNum1 = '' or @EmpNum1 = f.EmpNum)
			   and (@DeviceID1 = '' or @DeviceID1 = f.[Source])
			   and (@PktNum1 = 0 or @PktNum1 = f.PktNum)
			   and (    (f.Tier in (select CustTier from #RTA_Compliance_CustTiers))
					 or (f.Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
					 or (@CustTier is null or @CustTier = '' or @Custtier = 'All'))
			   and f.ActivityTypeID = 9 and f.State = 'Display Alert Popup'
			   and (f.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
			 group by f.State, f.Activity, ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.ActivityTypeID, f.Description
		END
	END
	
	IF @UseEmpCmp = 1
	BEGIN 
		insert into #RTA_FloorActivity_Tmp
		select Time = f.tOut,
		       State = f.State + (case when f.State = 'Complete' 
							           then (case when f.Source like '%.%.%.%' and f.Source <> @ServerIP and f.EmpName <> 'RTSSGUI' then ' Mobile'
										          when f.Source like '%.%.%.%' and (f.Source = @ServerIP or f.EmpName = 'RTSSGUI') then ' Workstation'
										          when f.Source = '~r:Dashboard' then ' Dashboard'
										          when f.Source = 'MGR Clear All' then ' MGR Clear All'
										          when ISNUMERIC(f.Source) = 1 then ' Game'
										          else '' end)
							           else '' end),
		       f.Activity, Location = ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.EmpNum, f.EmpName, e.JobType,
		       [Source] = case when f.Source in ('RTSSPPE','RTSS.exe') then 'Server'
							   when f.Source like '%.%.%.%' and f.Source = @ServerIP then 'Server'
							   when f.Source like '%.%.%.%' and f.Source <> @ServerIP and f.EmpName = 'RTSSGUI' then 'Workstation'
		                       when f.Source like '%.%.%.%' and f.Source <> @ServerIP and f.EmpName <> 'RTSSGUI' then 'Device'
							   when f.State = 'Reject Auto Server' then 'Server'
							   else ltrim(rtrim(f.[Source])) end,
		       LastArea = le.Zone,
			   AsnArea = case when len(ltrim(rtrim(zc.Activity))) < 14 then ''
		                      else right(ltrim(rtrim(zc.Activity)),len(ltrim(rtrim(zc.Activity)))-14) end,
		       f.ActivityTypeID,
			   LastLocation = le.Location
		  from SQLA_FloorActivity as f
	     inner join SQLA_EmployeeCompliance as c
	        on c.PktNum = f.PktNum
	       and c.EmpNum = f.EmpNum
		  left join SQLA_Employees as e
		    on e.CardNum = f.EmpNum
		  left join SQLA_FloorActivity as zc
			on zc.ActivityTypeID = 4
		   and zc.Activity like 'ZONES SERVED%'
		   and zc.EmpNum = f.EmpNum
		   and zc.EmpNum <> ''
		   and zc.tOut < f.tOut
		   and zc.tOut > DATEADD(hour,-8,f.tOut)
		  left join SQLA_FloorActivity as le
			on le.ActivityTypeID = 5
		   and le.State like 'Complete%'
		   and le.EmpNum = f.EmpNum
		   and le.EmpNum <> ''
		   and le.tOut < f.tOut
		   and le.tOut > DATEADD(hour,-8,f.tOut)
		 where f.tOut >= @StartDt1 and f.tOut < @EndDt1
		   and (@Location1 = '' or @Location1 = f.Location)
		   and (@EmpNum1 = '' or @EmpNum1 = f.EmpNum)
		   and (@DeviceID1 = '' or @DeviceID1 = f.[Source])
		   and (@PktNum1 = 0 or @PktNum1 = f.PktNum)
		   and (    (f.Tier in (select CustTier from #RTA_Compliance_CustTiers))
			 	 or (f.Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
				 or (@CustTier is null or @CustTier = '' or @Custtier = 'All'))
		   and (f.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
		   and (    (@ActivityType1 = 0) or (@ActivityType1 = f.ActivityTypeID)
		         or (@ActivityType1 = 10 and f.ActivityTypeID = 5 and f.State in ('Reject Manual','Reassign Reject','Reassign Supervisor Reject','Reassign Reject Manual'))
				 or (@ActivityType1 = 11 and f.ActivityTypeID = 5 and (f.State like 'Reject Auto%' or f.State = 'Reassign Reject Auto')))
		   and (    (@ViewMode <> 0)
		         or (     @ViewMode = 0  -- States to ignore in Consolidated mode
				      and f.State not in ('Display Workstation','Re-assign','Reject','Remove','Reassign Reject Manual',
					                      'Get Event','Get Event Popup','Auto Dispatch','Alert Dismiss','Display Alert Popup',
										  'Device Notification Pushed','Device Notification Respond','Event Notification Mobile',
										  'BeepAssignedEvent','Display-NEW EVENT','InformAssignedEvent','VibrateAssignedEvent')
					  and not exists  -- Display only 1st 'Alert Accept'
						( select null from SQLA_FloorActivity as f2
		                   where f.State = 'Alert Accept' and f2.State = 'Alert Accept'
		                     and f2.PktNum = f.PktNum 
							 and f2.Description = f.Description
							 and f2.Activity = f.Activity
							 and f2.tOut < f.tOut) ))
		   and not exists
			 ( select * from SQLA_FloorActivity as zc2
				where zc2.ActivityTypeID = 4
				  and zc2.Activity like 'ZONES SERVED%'
				  and zc2.EmpNum = f.EmpNum
				  and zc2.tOut < f.tOut
		          and zc2.tOut > DATEADD(hour,-8,f.tOut)
				  and zc2.tOut > zc.tOut )
		   and not exists
			 ( select * from SQLA_FloorActivity as le2
				where le2.ActivityTypeID = 5
				  and le2.State like 'Complete%'
				  and le2.EmpNum = f.EmpNum
				  and le2.tOut < f.tOut
		          and le2.tOut > DATEADD(hour,-8,f.tOut)
				  and le2.tOut > le.tOut )
	       and (c.Asn = @Asn)
	       and (c.Acp = @Acp)
	       and (c.Rsp = @Rsp)
	       and (c.Cmp = @Cmp)
	       and (c.RejAuto = @RejAuto)
	       and (c.RejMan = @RejMan)
		   and (c.EventDisplay = @EventDisplay or @EventDisplay = '')

		IF (@ViewMode = 0)  -- Consolidated mode
		BEGIN
			-- Add single instances of Beep/Vibrate
			insert into #RTA_FloorActivity_Tmp
			select Time = min(f.tOut), State = 'Beep/Vibrate',
				   f.Activity, Location = ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.EmpNum, f.EmpName, JobType = '',
				   [Source] = 'Device',
				   LastArea = '',
				   AsnArea = '',
				   f.ActivityTypeID,
				   LastLocation = ''
			  from SQLA_FloorActivity as f
			  left join SQLA_FloorActivity as na
				on na.ActivityTypeID = 5 and na.State in ('Assign')
			   and na.PktNum = f.PktNum
			   and na.tOut > f.tOut
			 where f.tOut >= @StartDt1 and f.tOut < @EndDt1
			   and (@Location1 = '' or @Location1 = f.Location)
			   and (@EmpNum1 = '' or @EmpNum1 = f.EmpNum)
			   and (@DeviceID1 = '' or @DeviceID1 = f.[Source])
			   and (@PktNum1 = 0 or @PktNum1 = f.PktNum)
			   and (    (f.Tier in (select CustTier from #RTA_Compliance_CustTiers))
					 or (f.Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
					 or (@CustTier is null or @CustTier = '' or @Custtier = 'All'))
			   and f.ActivityTypeID = 5 and f.State in ('BeepAssignedEvent','VibrateAssignedEvent')
			   and (f.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
			   and not exists
				 ( select null from SQLA_FloorActivity as na2
					where na2.ActivityTypeID = 5 and na2.State in ('Assign')
					  and na2.PktNum = na.PktNum
					  and na2.tOut > f.tOut
					  and na2.tOut < na.tOut )
			 group by na.tOut, f.Activity, ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.EmpNum, f.EmpName, f.ActivityTypeID
			
			
			-- Add single instances of Display Alert Popup
			insert into #RTA_FloorActivity_Tmp
			select Time = min(f.tOut), f.State,	f.Activity, Location = ltrim(rtrim(f.Location)), f.PktNum, f.Tier, 
			       EmpNum = cast(count(distinct [Source]) as varchar), EmpName = cast(count(distinct [Source]) as varchar),
				   JobType = '', [Source] = 'Device', LastArea = '', AsnArea = '', f.ActivityTypeID, LastLocation = ''
			  from SQLA_FloorActivity as f
			 where f.tOut >= @StartDt1 and f.tOut < @EndDt1
			   and (@Location1 = '' or @Location1 = f.Location)
			   and (@EmpNum1 = '' or @EmpNum1 = f.EmpNum)
			   and (@DeviceID1 = '' or @DeviceID1 = f.[Source])
			   and (@PktNum1 = 0 or @PktNum1 = f.PktNum)
			   and (    (f.Tier in (select CustTier from #RTA_Compliance_CustTiers))
					 or (f.Tier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
					 or (@CustTier is null or @CustTier = '' or @Custtier = 'All'))
			   and f.ActivityTypeID = 9 and f.State = 'Display Alert Popup'
			   and (f.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
			 group by f.State, f.Activity, ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.ActivityTypeID, f.Description
		END
	END	
	
	
	-- MEAL BOOK transactions
	IF (@ActivityType1 = 0 or @ActivityType1 = 12)
	BEGIN
	
		-- DOOR OPEN
		insert into #RTA_FloorActivity_Tmp (Time, State, Activity, Location, PktNum, Tier, EmpNum, EmpName, JobType, Source, LastArea, AsnArea, ActivityTypeID, LastLocation, EmpStatusM, EmpStatusJ)
		select Time = m.tOut,
			   State = 'Door Open',
			   Activity = isnull(e.EventDisplay,m.EntryReason),
			   Location = case when @UseAssetField = 1 then m.Asset else m.Location end,
			   PktNum = m.ParentEventID,
			   Tier = isnull(e.CustTierLevel,'NUL'),
			   EmpNum = m.EmpNum,
			   EmpName = m.EmpName,
			   JobType = p.JobType,
			   Source = m.Source,
			   LastArea = '',
			   AsnArea = '',
			   ActivityTypeID = 12,
			   LastLocation = '',
			   EmpStatusM = 0,
			   EmpStatusJ = 0
		  from SQLA_MEAL as m
		  left join SQLA_EventDetails as e
			on e.PktNum = m.ParentEventID
		   and (    (e.SourceTable = 'EVENT1' and m.Source = 'SLOT')
				 or (e.SourceTable = 'EVENT1_ST' and m.Source = 'TECH')
				 or (m.Source not in ('SLOT','TECH')) )
		  left join SQLA_Employees as p
			on p.CardNum = m.EmpNum
		 where m.tOut is not null
		   and (@EmpNum1 = '' or @EmpNum1 = m.EmpNum)
		   and (    (@ActivityType1 = 12 and (@PktNum1 = 0 or @PktNum1 = m.ParentEventID))
		         or (     @ActivityType1 <> 12
		              and exists
			            ( select null from #RTA_FloorActivity_Tmp as a
			               where a.PktNum = m.ParentEventID ) ) )

		-- DOOR CLOSE
		insert into #RTA_FloorActivity_Tmp (Time, State, Activity, Location, PktNum, Tier, EmpNum, EmpName, JobType, Source, LastArea, AsnArea, ActivityTypeID, LastLocation, EmpStatusM, EmpStatusJ)
		select Time = m.tComplete,
			   State = 'Door Close',
			   Activity = isnull(e.EventDisplay,m.EntryReason),
			   Location = case when @UseAssetField = 1 then m.Asset else m.Location end,
			   PktNum = m.ParentEventID,
			   Tier = isnull(e.CustTierLevel,'NUL'),
			   EmpNum = m.EmpNum,
			   EmpName = m.EmpName,
			   JobType = p.JobType,
			   Source = m.Source,
			   LastArea = '',
			   AsnArea = '',
			   ActivityTypeID = 12,
			   LastLocation = '',
			   EmpStatusM = 0,
			   EmpStatusJ = 0
		  from SQLA_MEAL as m
		  left join SQLA_EventDetails as e
			on e.PktNum = m.ParentEventID
		   and (    (e.SourceTable = 'EVENT1' and m.Source = 'SLOT')
				 or (e.SourceTable = 'EVENT1_ST' and m.Source = 'TECH')
				 or (m.Source not in ('SLOT','TECH')) )
		  left join SQLA_Employees as p
			on p.CardNum = m.EmpNum
		 where m.tComplete is not null
		   and (@EmpNum1 = '' or @EmpNum1 = m.EmpNum)
		   and (    (@ActivityType1 = 12 and (@PktNum1 = 0 or @PktNum1 = m.ParentEventID))
		         or (     @ActivityType1 <> 12
		              and exists
			            ( select null from #RTA_FloorActivity_Tmp as a
			               where a.PktNum = m.ParentEventID ) ) )

		-- WITNESS SIGNATURE 1
		insert into #RTA_FloorActivity_Tmp (Time, State, Activity, Location, PktNum, Tier, EmpNum, EmpName, JobType, Source, LastArea, AsnArea, ActivityTypeID, LastLocation, EmpStatusM, EmpStatusJ)
		select Time = m.tWitness1,
			   State = 'Witness Signature',
			   Activity = isnull(e.EventDisplay,m.EntryReason),
			   Location = case when @UseAssetField = 1 then m.Asset else m.Location end,
			   PktNum = m.ParentEventID,
			   Tier = isnull(e.CustTierLevel,'NUL'),
			   EmpNum = m.EmpNumWitness1,
			   EmpName = m.EmpNameWitness1,
			   JobType = p.JobType,
			   Source = m.Source,
			   LastArea = '',
			   AsnArea = '',
			   ActivityTypeID = 12,
			   LastLocation = '',
			   EmpStatusM = 0,
			   EmpStatusJ = 0
		  from SQLA_MEAL as m
		  left join SQLA_EventDetails as e
			on e.PktNum = m.ParentEventID
		   and (    (e.SourceTable = 'EVENT1' and m.Source = 'SLOT')
				 or (e.SourceTable = 'EVENT1_ST' and m.Source = 'TECH')
				 or (m.Source not in ('SLOT','TECH')) )
		  left join SQLA_Employees as p
			on p.CardNum = m.EmpNumWitness1
		 where m.tWitness1 is not null
		   and (@EmpNum1 = '' or @EmpNum1 = m.EmpNumWitness1)
		   and (    (@ActivityType1 = 12 and (@PktNum1 = 0 or @PktNum1 = m.ParentEventID))
		         or (     @ActivityType1 <> 12
		              and exists
			            ( select null from #RTA_FloorActivity_Tmp as a
			               where a.PktNum = m.ParentEventID ) ) )

		-- WITNESS SIGNATURE 2
		insert into #RTA_FloorActivity_Tmp (Time, State, Activity, Location, PktNum, Tier, EmpNum, EmpName, JobType, Source, LastArea, AsnArea, ActivityTypeID, LastLocation, EmpStatusM, EmpStatusJ)
		select Time = m.tWitness2,
			   State = 'Witness Signature',
			   Activity = isnull(e.EventDisplay,m.EntryReason),
			   Location = case when @UseAssetField = 1 then m.Asset else m.Location end,
			   PktNum = m.ParentEventID,
			   Tier = isnull(e.CustTierLevel,'NUL'),
			   EmpNum = m.EmpNumWitness2,
			   EmpName = m.EmpNameWitness2,
			   JobType = p.JobType,
			   Source = m.Source,
			   LastArea = '',
			   AsnArea = '',
			   ActivityTypeID = 12,
			   LastLocation = '',
			   EmpStatusM = 0,
			   EmpStatusJ = 0
		  from SQLA_MEAL as m
		  left join SQLA_EventDetails as e
			on e.PktNum = m.ParentEventID
		   and (    (e.SourceTable = 'EVENT1' and m.Source = 'SLOT')
				 or (e.SourceTable = 'EVENT1_ST' and m.Source = 'TECH')
				 or (m.Source not in ('SLOT','TECH')) )
		  left join SQLA_Employees as p
			on p.CardNum = m.EmpNumWitness2
		 where m.tWitness2 is not null
		   and (@EmpNum1 = '' or @EmpNum1 = m.EmpNumWitness2)
		   and (    (@ActivityType1 = 12 and (@PktNum1 = 0 or @PktNum1 = m.ParentEventID))
		         or (     @ActivityType1 <> 12
		              and exists
			            ( select null from #RTA_FloorActivity_Tmp as a
			               where a.PktNum = m.ParentEventID ) ) )

		-- WITNESS SIGNATURE 3
		insert into #RTA_FloorActivity_Tmp (Time, State, Activity, Location, PktNum, Tier, EmpNum, EmpName, JobType, Source, LastArea, AsnArea, ActivityTypeID, LastLocation, EmpStatusM, EmpStatusJ)
		select Time = m.tWitness3,
			   State = 'Witness Signature',
			   Activity = isnull(e.EventDisplay,m.EntryReason),
			   Location = case when @UseAssetField = 1 then m.Asset else m.Location end,
			   PktNum = m.ParentEventID,
			   Tier = isnull(e.CustTierLevel,'NUL'),
			   EmpNum = m.EmpNumWitness3,
			   EmpName = m.EmpNameWitness3,
			   JobType = p.JobType,
			   Source = m.Source,
			   LastArea = '',
			   AsnArea = '',
			   ActivityTypeID = 12,
			   LastLocation = '',
			   EmpStatusM = 0,
			   EmpStatusJ = 0
		  from SQLA_MEAL as m
		  left join SQLA_EventDetails as e
			on e.PktNum = m.ParentEventID
		   and (    (e.SourceTable = 'EVENT1' and m.Source = 'SLOT')
				 or (e.SourceTable = 'EVENT1_ST' and m.Source = 'TECH')
				 or (m.Source not in ('SLOT','TECH')) )
		  left join SQLA_Employees as p
			on p.CardNum = m.EmpNumWitness3
		 where m.tWitness3 is not null
		   and (@EmpNum1 = '' or @EmpNum1 = m.EmpNumWitness3)
		   and (    (@ActivityType1 = 12 and (@PktNum1 = 0 or @PktNum1 = m.ParentEventID))
		         or (     @ActivityType1 <> 12
		              and exists
			            ( select null from #RTA_FloorActivity_Tmp as a
			               where a.PktNum = m.ParentEventID ) ) )

		-- WITNESS SIGNATURE 4
		insert into #RTA_FloorActivity_Tmp (Time, State, Activity, Location, PktNum, Tier, EmpNum, EmpName, JobType, Source, LastArea, AsnArea, ActivityTypeID, LastLocation, EmpStatusM, EmpStatusJ)
		select Time = m.tWitness4,
			   State = 'Witness Signature',
			   Activity = isnull(e.EventDisplay,m.EntryReason),
			   Location = case when @UseAssetField = 1 then m.Asset else m.Location end,
			   PktNum = m.ParentEventID,
			   Tier = isnull(e.CustTierLevel,'NUL'),
			   EmpNum = m.EmpNumWitness4,
			   EmpName = m.EmpNameWitness4,
			   JobType = p.JobType,
			   Source = m.Source,
			   LastArea = '',
			   AsnArea = '',
			   ActivityTypeID = 12,
			   LastLocation = '',
			   EmpStatusM = 0,
			   EmpStatusJ = 0
		  from SQLA_MEAL as m
		  left join SQLA_EventDetails as e
			on e.PktNum = m.ParentEventID
		   and (    (e.SourceTable = 'EVENT1' and m.Source = 'SLOT')
				 or (e.SourceTable = 'EVENT1_ST' and m.Source = 'TECH')
				 or (m.Source not in ('SLOT','TECH')) )
		  left join SQLA_Employees as p
			on p.CardNum = m.EmpNumWitness4
		 where m.tWitness4 is not null
		   and (@EmpNum1 = '' or @EmpNum1 = m.EmpNumWitness4)
		   and (    (@ActivityType1 = 12 and (@PktNum1 = 0 or @PktNum1 = m.ParentEventID))
		         or (     @ActivityType1 <> 12
		              and exists
			            ( select null from #RTA_FloorActivity_Tmp as a
			               where a.PktNum = m.ParentEventID ) ) )
	
	END
	
	
	IF (@RspVar <> '' and @RspVar <> 'All')
	BEGIN
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
			AsnSecs int,
			ReaSecs int,
			AcpSecs int,
			RejSecs int
		)
		
		
		INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt1, @EndDt = @EndDt1, @MinRspSecs = @RspVarMin, @MaxRspSecs = @RspVarMax
		
		select * from #RTA_FloorActivity_Tmp 
		 where PktNum in (select PktNum from #RTA_EventDetails_Tmp)
	
	END
	
	
	-- Return results
	ELSE
		select * from #RTA_FloorActivity_Tmp

	
END


GO


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Locations]    Script Date: 04/21/2016 12:56:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Locations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Locations]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Locations] 
	@IsActive nvarchar(1) = ''	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select Location = '', 
	       Asset = '', 
	       Zone = 'All', 
	       Area = 'All', 
	       IsActive = '1',
	       DisplayLocation = ' All'
	 union all
	select ltrim(rtrim(Location)), Asset, Zone, Area, IsActive, DisplayLocation
	  from SQLA_Locations
	 where ((@IsActive = '') or (@IsActive = IsActive)) 
	 order by DisplayLocation
END







GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_MEAL]    Script Date: 09/08/2016 11:27:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_MEAL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_MEAL]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_MEAL] 
	@StartDt datetime,
	@EndDt datetime,
	@Location nvarchar(10) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT PktNum, Location, Zone, EmpNum,
		   EmpName = case when (m.EmpName is null or ltrim(rtrim(m.EmpName)) = '') and emp.CardNum is not null then emp.NameFirst+' '+left(emp.NameLast,1)+'.'
		                  when (m.EmpName is null or ltrim(rtrim(m.EmpName)) = '') and emp.CardNum is null and emp2.CardNum is not null then emp2.NameFirst+' '+left(emp2.NameLast,1)+'.'
						  else m.EmpName end,
		   EmpLicNum, tOut, EntryReason, ParentEventID,
		   PktNumWitness1, PktNumSourceWitness1, EmpNumWitness1, EmpNameWitness1, EmpLicNumWitness1, tWitness1,
		   PktNumWitness2, PktNumSourceWitness2, EmpNumWitness2, EmpNameWitness2, EmpLicNumWitness2, tWitness2,
		   PktNumWitness3, PktNumSourceWitness3, EmpNumWitness3, EmpNameWitness3, EmpLicNumWitness3, tWitness3,
		   PktNumWitness4, PktNumSourceWitness4, EmpNumWitness4, EmpNameWitness4, EmpLicNumWitness4, tWitness4,
		   EventComment, Asset, 
		   EventDescription = case when m.EntryReason = 'DROP TEAM' then m.CardInEvtDisp else isnull(r.EventDescription,m.CardInEvtDesc) end
	  FROM SQLA_MEAL as m
	  left join SQLA_CardInReasons as r
	    on r.Dept = m.Source
	   and r.EventDisplay = m.CardInEvtDisp
	  left join SQLA_Employees as emp
	    on emp.CardNum = m.EmpNum
	  left join SQLA_Employees as emp2
	    on emp2.CardNum = ltrim(rtrim(m.CardInEvtDisp))
	 WHERE tOut >= @StartDt and tOut <= @EndDt
	   and ((@Location = '') or (@Location = ' All') or (Location = @Location) or (Asset = @Location))
END




GO


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_PaperOut]    Script Date: 04/21/2016 13:08:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_PaperOut]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_PaperOut]
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_PaperOut] 
	@StartDt datetime,
	@EndDt datetime,
	@ZoneArea varchar(255) = '',
	@Location nvarchar(10) = '',
	@IncludeAsn int = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
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
    select distinct left(ltrim(rtrim(val)),4) from dbo.fn_String_To_Table(@ZoneArea, ',', 1)

	
	SELECT d.EventDisplay, d.tOut, d.Zone, d.Location, d.tAssign, d.EmpNumAsn, d.EmpNameAsn, d.tComplete
	  FROM dbo.SQLA_EventDetails as d
	 WHERE d.EventDisplay in ('PPR OUT','PRT OUT')
	   and d.tOut >= @StartDt and d.tOut < @EndDt
	   and ((@Location = '' or @Location = d.Location))
	   and (d.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '')
	   and ((@IncludeAsn = 1) or (@IncludeAsn = 0 and EmpNumAsn=''))

END

GO

USE [RTA_SQLA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_ShowPaperOut]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_ShowPaperOut]
GO

CREATE PROCEDURE sp_SSRS_Rpt_RTA_ShowPaperOut

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @ShowPaperOut int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'ShowPaperOut'),0)

	select ShowPaperOut = @ShowPaperOut
END
GO
USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_SupReview]    Script Date: 08/31/2016 12:08:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_SupReview]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_SupReview]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_SupReview]
	@StartDt datetime,
	@EndDt datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select PktNum, EventDisplay, CustTierLevel, EmpJobTypeRsp, RspSecs, AsnTake,
		   RspBin = case when RspSecs <= 30 then '00:00 - 00:30'
						 when RspSecs >  30 and RspSecs <=  60 then '00:30 - 01:00'
						 when RspSecs >  60 and RspSecs <= 120 then '01:00 - 02:00'
						 when RspSecs > 120 and RspSecs <= 180 then '02:00 - 03:00'
						 when RspSecs > 180 and RspSecs <= 300 then '03:00 - 05:00'
						 when RspSecs > 300 and RspSecs <= 600 then '05:00 - 10:00'
						 when RspSecs > 600 then '> 10:00' end,
		   InTopTwoTiers = case when CustTierLevel in (select top 2 TierLevel from SQLA_CustTiers order by PriorityLevel desc) then 'Y' else 'N' end
	  from SQLA_EventDetails
	 where tOut >= @StartDt and tOut < @EndDt
	   and RspSecs >= 0
	   and EmpJobTypeRsp <> ''
END

GO
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

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_ZoneArea]    Script Date: 04/21/2016 13:08:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_ZoneArea]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_ZoneArea]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_ZoneArea] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ZonesAreNumeric int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZonesAreNumeric'),0)
	
	IF @ZonesAreNumeric = 1
	BEGIN
		select * from SQLA_ZoneArea
		 order by cast(ZoneArea as int)
	END
	
	IF @ZonesAreNumeric <> 1
	BEGIN
		select * from SQLA_ZoneArea
		 order by ZoneArea
	END
END





GO

USE [ANI]
GO

/****** Object:  StoredProcedure [dbo].[sp_ANI_Users]    Script Date: 09/09/2015 11:52:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_ANI_Users]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_ANI_Users]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ANI_Users]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select UserId = null, UserName = 'All'
	 union all
	select u.UserId, u.UserName
	  from dbo.aspnet_Users as u
END

GO


USE [ANI]
GO

/****** Object:  StoredProcedure [dbo].[sp_ANI_UserSessions]    Script Date: 09/09/2015 11:52:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_ANI_UserSessions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_ANI_UserSessions]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ANI_UserSessions]
	@StartDt datetime,
	@EndDt datetime,
	@UserID uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select SessionDt = s.startDT,
		   u.UserName,
		   ReportDttm = r.RequestDT,
		   ReportName = right(r.ReportPath,LEN(r.ReportPath)-12)
	  from dbo.trcSession as s
	 inner join dbo.aspnet_Users as u
		on u.UserId = s.UserId
	 inner join dbo.trcReport as r
		on r.SessionId = s.SessionID
	 where r.RequestDT >= @StartDt and r.RequestDT < @EndDt
	   and (u.UserId = @UserID or @UserID is null)
END

GO


