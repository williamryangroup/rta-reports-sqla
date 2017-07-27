USE [RTSS]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Compliance_Employee2]    Script Date: 07/08/2016 14:16:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Compliance_Employee2]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Compliance_Employee2]
GO



-- =============================================================================
-- Author:		bburrows
-- Create date: June 8, 2015
-- Description:	Returns RTA Compliance by Employee
-- =============================================================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Compliance_Employee2]
	@StartDt datetime,
	@EndDt datetime,
	@IncludeOOS int = 0,
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@AsnRspOnly int = 0,
	@CustTier varchar(255) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @IncludeOOS1 int = @IncludeOOS
	DECLARE @EmpJobType1 varchar(2000) = @EmpJobType
	DECLARE @EventType1 varchar(2000) = @EventType
	DECLARE @AsnRspOnly1 int = @AsnRspOnly
	
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
    
    
    SELECT EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay,
           Asn = Asn, 
           Acp = Acp, 
           Rsp = Rsp, 
           Cmp = Cmp, 
           CmpMobile = CmpMobile, 
           RejMan = RejMan, 
           RejAuto = RejAuto, 
           RspRTA = RspRTA, 
           RspCard = RspCard, 
           RspRTAandCard = RspRTAandCard, 
           RspTmSec = RspTmSec, 
           OverallTmSec = OverallTmSec,
           AsnOther = isnull((select distinct 1 from SQLA_EmployeeCompliance as c2 where c2.PktNum = c.PktNum and c2.EmpNum <> c.EmpNum and c2.tAsnMin < c.tRspMin),0)
      FROM SQLA_EmployeeCompliance as c
	 where tOut >= @StartDt1 and tOut < @EndDt1
	   and ((@IncludeOOS1 = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS1 = 1))
	   and (EmpJobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '')
	   and (EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
	   and (@AsnRspOnly1 = 0 or (@AsnRspOnly1 = 1 and Asn > 0) or (@AsnRspOnly1 = 2 and Asn = 0 and Rsp > 0))
	   and (    (CustTier in (select CustTier from #RTA_Compliance_CustTiers))
	         or (CustTier = '' and 'NUL' in (select CustTier from #RTA_Compliance_CustTiers))
	         or (@CustTier is null or @CustTier = ''))
	 UNION ALL
    SELECT EmpNum, EmpNameFirst = e.NameFirst, EmpNameLast = e.NameLast, EmpJobType = e.JobType, PktNum, EventDisplay,
           Asn = 0, Acp = 0, Rsp = 1, Cmp = 1, CmpMobile = 0, RejMan = 0, RejAuto = 0, RspRTA = 0, RspCard = 0, RspRTAandCard = 0, 
           RspTmSec = 0, OverallTmSec = DATEDIFF(second,tOut,tComplete), AsnOther = 0
	  FROM SQLA_EventDetails_JPVER as j
	  LEFT JOIN SQLA_Employees as e
	    on e.CardNum = j.EmpNum
	 WHERE tOut >= @StartDt1 and tOut < @EndDt1
	   and (JobType in (select JobType from #RTA_Compliance_JobTypes) or @EmpJobType1 is null or @EmpJobType1 = '')
	   and (EventDisplay in (select EventType from #RTA_Compliance_EventTypes) or @EventType1 is null or @EventType1 = '')
	   and @AsnRspOnly1 <> 1
	   and Source = 'OOS'
END



