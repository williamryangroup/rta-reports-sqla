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
		   EventDisplay
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
		   EventDisplay = ''
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
		   c.EventDisplay
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
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, c.EventDisplay ) as p
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, EventDisplay
END




GO


