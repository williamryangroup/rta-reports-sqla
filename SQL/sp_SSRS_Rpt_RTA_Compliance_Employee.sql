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
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier, d.tOutHour, EvtDay = cast(c.tOut as date)
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
		   s.ShiftName, ShiftOrder = s.ShiftColumn, CustTier = '', d.tOutHour, EvtDay = cast(d.tOut as date)
	  FROM SQLA_EventDetails_JPVER as j
	 INNER JOIN SQLA_EventDetails as d
	    ON d.PktNum = j.PktNum
	  LEFT JOIN SQLA_Employees as e
	    on e.CardNum = j.EmpNum
	  LEFT JOIN SQLA_ShiftHours as s
	    ON s.StartHour = d.tOutHour
	 WHERE j.tOut >= @StartDt1 and j.tOut < @EndDt1
	   and (JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '')
	   and (j.EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
	   and @AsnRspOnly1 <> 1
	   and Source = 'OOS'
       and (d.Zone in (select ZoneArea from #RTA_Compliance_ZoneAreas) or @ZoneArea is null or @ZoneArea = '' or @ZoneArea like '00%')
END

GO

