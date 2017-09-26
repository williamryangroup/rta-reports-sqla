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

