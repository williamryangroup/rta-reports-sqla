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
			   Location = ltrim(rtrim(f.Location)), f.PktNum, f.Tier, f.EmpNum, f.EmpName, e.JobType,
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
		 group by f.tOut, f.State, f.Source, f.Description, f.Activity, f.Location, f.PktNum, f.Tier, f.EmpNum, f.EmpName, e.JobType, f.[Zone], le.[Zone], zc.Activity, f.ActivityTypeID, le.Location

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


