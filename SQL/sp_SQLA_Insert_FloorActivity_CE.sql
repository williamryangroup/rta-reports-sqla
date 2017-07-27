USE [RTSS]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_FloorActivity_CE]    Script Date: 06/15/2016 11:39:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_FloorActivity_CE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_FloorActivity_CE]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_FloorActivity_CE]

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	-- Capture new EVENT_CEATES purged from RTSS since last SQLA insert
	truncate table SQLA_New_SEQ
	
	insert into SQLA_New_SEQ (SEQ)
	select l.SEQ from RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
		on e.PktNum = l.PktNum and l.EventTable = 'EVENT_CE'
	 where l.tEventState is not null and e.EventDisplay not in ('OOS','10 6')
	   and EventState not in ('tRecd','tOut','tDisplay','tInitialResponse','tRemove','tComplete','tRejectAuto')
	   and not exists 
		 ( select null from SQLA_FloorActivity as f WITH (NOLOCK)
			where f.SourceTable = 'EVENT_STATE_LOG1' and f.SourceTableID = l.SEQ)
	
	
	-- Capture new EVENTS purged from RTSS since last SQLA insert
	truncate table SQLA_New_Events
	
	insert into SQLA_New_Events (PktNum)
	select e.PktNum from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where not exists 
		 ( select null from SQLA_FloorActivity as f WITH (NOLOCK)
			where f.SourceTable = 'EVENT1_CE' and f.SourceTableID = e.PktNum)
	
	
	DECLARE @MinAlert1ID int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'ALERT1')
	DECLARE @MinSysLog1EvtNum int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1')
	--DECLARE @MinEvtStateLog1Seq int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'EVENT_STATE_LOG1')
	--DECLARE @MinDeviceNotifTimesID int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'DEVICE_NOTIFICATION_TIMES')
	--DECLARE @MinEvent1PktNum int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'EVENT1_CE')
	--DECLARE @MinEvtRejPktNum int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'EVENTREJECT')
	--DECLARE @MinEvtRej1PktNum int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'EVENTREJECT1')
	--DECLARE @MinEmpActDttm datetime = (select isnull(MAX(tOut),'1/1/2010') from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'EMPLOYEEACTIVITY1')
	
	DECLARE @ServerIP varchar(15) = (select ltrim(rtrim(Setting)) from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP')
	DECLARE @UseAssetAsLocation int = isnull((select case when Setting = 'Asset' then 1 else 0 end from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),0)
	DECLARE @UseWebSockets int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'UseWebSockets'),0)
	DECLARE @CaptEvtNotifyTimes int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'CaptEvtNotifyTimes'),0)
	DECLARE @CaptEvtStateTimes int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'SYSTEM' and ConfigParam = 'CaptEvtStateTimes'),0)
	DECLARE @SupTrackDashboard int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'SupervisorTrackDashboard'),1)
	DECLARE @SupTrackAdmin int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'SupervisorTrackAdmin'),1)
	DECLARE @CheckAlertsPollInterval int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'CheckAlertsPollInterval'),5500)
	DECLARE @CaptAllGetEvents int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'CaptAllGetEvents'),0)
	DECLARE @AutoDispatchLogging int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'SYSTEM' and ConfigParam = 'AutoDispatchLogging'),0)
	
	
	
    -- EVENT - OOS/10 6 - Start
	insert into SQLA_FloorActivity
	select tOut, 2, 'Start', PktCbMsg, '', '', PktNum, '', EmpNumAuthorize, EmpNameAuthorize, DeviceIDRespond, '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tOut is not null and tOut > '1/2/1980' and EventDisplay in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	   
	-- EVENT - OOS/10 6 - End
	insert into SQLA_FloorActivity
	select tComplete, 2, 'End', PktCbMsg, '', '', PktNum, '', EmpNumAuthorize, EmpNameAuthorize, isnull(DeviceIDComplete,ClosePktNum), ResolutionDesc, '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tComplete is not null and tComplete > '1/2/1980' and EventDisplay in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)

	
	
	-- EVENT - Received
	insert into SQLA_FloorActivity
	select tRecd, 5, 'RTSS Receive', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tRecd is not null and tRecd > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and exists (select null from RTSS.dbo.EVENT_STATE_LOG1 as l2 where l2.PktNum = e.PktNum and l2.EventTable = 'EVENT_CE')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Open
	insert into SQLA_FloorActivity
	select tOut, 5, 'RTSS Open', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tOut is not null and tOut > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Display Workstation
	insert into SQLA_FloorActivity
	select tDisplay, 5, 'Display Workstation', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tDisplay is not null and tDisplay > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Reject
	insert into SQLA_FloorActivity
	select tReject, 5, 'Reject' + case when DeviceIDReject is null or DeviceIDReject = '' or DeviceIDReject = @ServerIP then ' Auto' else ' Manual' end, 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumReject, EmpNameReject, DeviceIDReject, '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tReject is not null and tReject > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Authorize - Initial
	insert into SQLA_FloorActivity
	select tInitialResponse, 5, 'Authorize Initial', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumInitialResponse, EmpNameInitialResponse, isnull(cast(AuthPktNum as varchar),DeviceIDInitialResponse), '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tInitialResponse is not null and tInitialResponse > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Authorize - EMPCARD 
	insert into SQLA_FloorActivity
	select tAuthorize, 5, 'Authorize Card In', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumAuthorize, EmpNameAuthorize, cast(AuthPktNum as varchar), '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tAuthorize is not null and tAuthorize > '1/2/1980' and EventDisplay = 'EMPCARD'
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Remove
	insert into SQLA_FloorActivity
	select tRemove, 5, 'Remove', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumComplete, EmpNameComplete, DeviceIDComplete, '', '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tRemove is not null and tRemove > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Complete
	insert into SQLA_FloorActivity
	select tComplete, 5, 'Complete', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone,
		   PktNum,  CustTierLevel,
		   EmpNumComplete = case when (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null then EmpNumAuthorize
		                         else EmpNumComplete end,
		   EmpNameComplete = case when (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null then EmpNameAuthorize
		                         else EmpNameComplete end,
		   case when [Desc] in ('MGR Clear All','~r:Dashboard') then ltrim(rtrim([Desc]))
				when DeviceIDComplete is not null then DeviceIDComplete
				when CloseBy911 is not null then cast(ClosePktNum as varchar)
				when EmpNameComplete = 'RTSSGUI' then Address end, ltrim(rtrim(ResolutionDesc)), '','EVENT1_CE',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
	 where tComplete is not null and tComplete > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	   
	
	IF @CaptEvtStateTimes > 0
	BEGIN
		-- EVENT_STATE_LOG1
		insert into SQLA_FloorActivity
		select distinct l.tEventState, 5, 
			   case when l.EventState = 'tAuthorize' and l.PktNumEventState is not null then 'Authorize Card In'
					when l.EventState = 'tAuthorize' and l.PktNumEventState is null and EmpName <> 'RTSSGUI' then 'Authorize Mobile'
					when l.EventState = 'tAuthorize' and EmpName = 'RTSSGUI' then 'Authorize Workstation'
					when l.EventState = 'tInitialResponse' then 'Initial Response'
					when l.EventState = 'tRespondMobile' then 'Respond Mobile'
					when l.EventState = 'tReassign' then 'Re-assign'
					when l.EventState = 'tRejectAuto' then 'Reject Auto'
					when l.EventState = 'tComplete' then 'Complete'
					when l.EventState = 'tReject' and l.EmpName = @ServerIP then 'Reject Auto Server'
					when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID = l.EventStateSource then 'Reject Manual'
					when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID <> l.EventStateSource then 'Reject'
					when l.EventState = 'tOut' then 'RTSS Open'
					when l.EventState = 'tDisplayMobile' then 'Event Display Mobile'
					when l.EventState = 'tAcceptMobile' then 'Accept Mobile'
					when l.EventState = 'tRemove' then 'Remove'
					when l.EventState = 'tAssign' then 'Assign'
					when l.EventState = 'tDisplay' then 'Display Workstation'
					when l.EventState = 'tAssignSupervisor' then 'Assign Supervisor'
					when l.EventState = 'tReassignAttendant' then 'Reassign Attendant'
					when l.EventState = 'tReassignSupervisor' then 'Reassign Supervisor'
					when l.EventState = 'tReassignRemove' then 'Reassign Remove'
					when l.EventState = 'tRejectRA' and l.DeviceID = l.EventStateSource then 'Reassign Reject Manual'
					when l.EventState = 'tRejectRA' and l.DeviceID <> l.EventStateSource then 'Reassign Reject Auto'
					when l.EventState = 'tRejectRASupervisor' then 'Reassign Supervisor Reject'
					when l.EventState = 'tRejectAutoServer' then 'Reject Auto Server'
					when l.EventState = 'tRejectAutoDevice' then 'Reject Auto Device'
					when l.EventState = 'tReassignDisplayed' then 'Display Reassign Popup'
					when l.EventState = 'EventMainButton' then 'Main Menu Button'
					when l.EventState = 'EventAssignedRemove' then 'Event Assigned Remove'
					when l.EventState = 'tReassignPrior' then 'Reassigned to Prior Event'
					else l.EventState end,
			   EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
												  when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
												  else '' end,
		       case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone,
			   l.PktNum, e.CustTierLevel, l.EmpNum, l.EmpName,
			   case when l.PktNumEventState is not null and l.PktNumEventState <> 0 then cast(l.PktNumEventState as varchar)
			        when (l.PktNumEventState is null or l.PktNumEventState = 0) and l.EventStateSource is not null then l.EventStateSource
			        else l.DeviceID end,
			   Description =  case when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID = l.EventStateSource then 'MANUAL REJECT' else '' end,
			   RejAfterDisp = case when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID = l.EventStateSource then
							  isnull((select distinct 'Y' from dbo.EVENT_STATE_LOG1 as l2 WITH (NOLOCK)
									   where l2.PktNum = l.PktNum and l2.EventTable = 'EVENT_CE'
										 and l2.EmpNum = l.EmpNum
										 and l2.tEventState < l.tEventState
										 and l2.EventState = 'tDisplayMobile'),'N')
							  else '' end,
			   'EVENT_STATE_LOG1', l.SEQ, '', '', ''
		  from RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
			on e.PktNum = l.PktNum and l.EventTable = 'EVENT_CE'
		 where l.tEventState is not null and e.EventDisplay not in ('OOS','10 6')
		   and EventState not in ('tRecd','tOut','tDisplay','tInitialResponse','tRemove','tComplete','tRejectAuto')
		   and l.SEQ in (select SEQ from SQLA_New_SEQ)
	END
	
	
	IF @CaptEvtNotifyTimes = 1
	BEGIN
		IF @UseWebSockets = 1
		BEGIN
			-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Pushed
			insert into SQLA_FloorActivity
			select tNotifyPushed, 5, 'Device Notification Pushed', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDNotify, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDNotify), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
			  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
			 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
				on e.PktNum = n.PktNum
			 where tNotifyPushed is not null and tNotifyPushed > '1/2/1980' and EventDisplay not in ('OOS','10 6')
			   and e.PktNum in (select PktNum from SQLA_New_Events)
		END
		
		-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Respond
		insert into SQLA_FloorActivity
		select tDeviceRespond, 5, 'Device Notification Respond', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDRespond, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDRespond), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
		  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
			on e.PktNum = n.PktNum
		 where tDeviceRespond is not null and tDeviceRespond > '1/2/1980' and EventDisplay not in ('OOS','10 6')
		   and e.PktNum in (select PktNum from SQLA_New_Events)
		
		IF @CaptAllGetEvents = 0
		BEGIN
			-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Pull
			insert into SQLA_FloorActivity
			select tEventSent, 5, 'Event Notification Mobile', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDNotify, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDNotify), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
			  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
			 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
				on e.PktNum = n.PktNum
			 where tEventSent is not null and tEventSent > '1/2/1980' and EventDisplay not in ('OOS','10 6') and n.DeviceIDNotify is not null
			   and e.PktNum in (select PktNum from SQLA_New_Events)
		END
	END
	
	
	IF @CaptAllGetEvents = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - GetEvent - EventDetail1
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Get Event', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone = e.Zone, PktNum = cast(EvtDetail1 as int),
		       Tier = e.CustTierLevel, EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
		    on e.PktNum = cast(s.EvtDetail1 as int)
		 where EvtType = 'GetEvents' and EvtDetail1 <> '-1'
		   and not exists (select null from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1' and SourceTableID = EvtNum)
		
		-- RTSS.dbo.SYSTEMLOG - GetEvent - EventDetail2
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Get Event', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone = e.Zone, PktNum = cast(EvtDetail2 as int),
		       Tier = e.CustTierLevel, EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
		    on e.PktNum = cast(s.EvtDetail2 as int)
		 where EvtType = 'GetEvents' and EvtDetail2 <> '-1'
		   and not exists (select null from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1' and SourceTableID = EvtNum)
	END
	
	
	IF @AutoDispatchLogging = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - AutoDispatch
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Auto Dispatch', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end,
			   Zone = e.Zone, PktNum = cast(EvtDetail1 as int), Tier = e.CustTierLevel, EmpNum = '', EmpName = '', [Source] = 'RTSS', EvtDetail2, '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2_CE as e WITH (NOLOCK)
			on e.PktNum = cast(s.EvtDetail1 as int)
		 where EvtType = 'AutoDispatch'
		   and not exists (select null from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1' and SourceTableID = EvtNum)
	END
	
	
	IF @CheckAlertsPollInterval > 0
	BEGIN
		-- RTSS.dbo.ALERT - Alert Resolved/Evt Cmp
		insert into SQLA_FloorActivity
		select Time = e.tComplete, 9, State = 'Alert Resolved/Evt Cmp', Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = '', EmpName = '', [Source] = '', ID, '', 'ALERT1', ID, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join dbo.EVENT2_CE as e WITH (NOLOCK)
		    on a.EventTablePktNum = e.PktNum
		 where a.ID > @MinAlert1ID and a.alertType <> 'EVENT'
		   and (    (a.tNotify is null and a.tDismiss is null) 
		         or (a.tDismiss is not null and a.tDismiss >= a.tCreate and a.tDismiss >= e.tComplete))
		 
		-- RTSS.dbo.ALERT - Alert Resolved
		insert into SQLA_FloorActivity
		select Time = a.tDismiss, 9, State = 'Alert Resolved', Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), l.Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = '', EmpName = '', [Source] = '', ID, '', 'ALERT1', ID, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		  left join RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
			on s.EvtDetail3 = a.ID and s.EvtType = 'SupervProcAlert'
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		  left join dbo.EVENT2_CE as e WITH (NOLOCK)
		    on a.EventTablePktNum = e.PktNum
		   and a.tDismiss >= e.tComplete
		 where a.ID > @MinAlert1ID and a.alertType <> 'EVENT'
		   and a.tDismiss is not null and s.EvtNum is null and e.PktNum is null
	END
	
	
	-- EVENT - Auto Reject - EventReject1/Event1/EventStateLog1
	insert into SQLA_FloorActivity
	select tOut = er.tReject,
	       ActivityTypeID = 5,
	       State = 'Reject Auto',
	       Activity = ev.EventDisplay,
	       Location = case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       Zone,
	       er.PktNum, 
	       ev.CustTierLevel,
	       EmpNum = er.EmpNumReject,
	       EmpName = er.EmpNameReject,
	       Source = er.DeviceIDReject,
	       Description = er.RejectReason,
		   AfterDisplay = case when l.PktNum is null then 'N' else 'Y' end,
		   'EVENTREJECT1_CE', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENTREJECT1_CE as er WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2_CE as ev WITH (NOLOCK)
		on ev.PktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = er.PktNum and l.EventTable = 'EVENT_CE'
	   and l.EmpNum = er.EmpNumReject
	   and l.tEventState < er.tReject
	   and l.EventState = 'tDisplayMobile'
	 where er.RejectReason like 'AUTOREJECT%' and ev.tReject is not null
	   and er.PktNum in (select PktNum from SQLA_New_Events)
	 group by er.tReject, ev.EventDisplay, case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       Zone, er.PktNum, ev.CustTierLevel, er.EmpNumReject, er.EmpNameReject, er.DeviceIDReject, er.RejectReason, l.PktNum
	
	
	-- EVENT - Auto Reject - EventReject/Event1/EventStateLog1
	insert into SQLA_FloorActivity
	select tOut = er.tReject,
	       ActivityTypeID = 5,
	       State = 'Reject Auto',
	       Activity = ev.EventDisplay,
	       Location = case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       Zone,
	       er.PktNum, 
	       ev.CustTierLevel,
	       EmpNum = er.EmpNumReject,
	       EmpName = er.EmpNameReject,
	       Source = er.DeviceIDReject,
	       Description = er.RejectReason,
		   AfterDisplay = case when l.PktNum is null then 'N' else 'Y' end,
		   'EVENTREJECT_CE', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENTREJECT_CE as er WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2_CE as ev WITH (NOLOCK)
		on ev.PktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = er.PktNum and l.EventTable = 'EVENT_CE'
	   and l.EmpNum = er.EmpNumReject
	   and l.tEventState < er.tReject
	   and l.EventState = 'tDisplayMobile'
	 where er.RejectReason like 'AUTOREJECT%' and ev.tReject is not null
	   and er.PktNum in (select PktNum from SQLA_New_Events)
	 group by er.tReject, ev.EventDisplay, case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       Zone, er.PktNum, ev.CustTierLevel, er.EmpNumReject, er.EmpNameReject, er.DeviceIDReject, er.RejectReason, l.PktNum
	
	
	-- EVENT - Rejects due to assigned RTSS.dbo.EMPLOYEE carding another location
	insert into SQLA_FloorActivity
	select tOut = er.tOut,
	       ActivityTypeID = 5,
	       State = 'Reject',
	       Activity = ev.EventDisplay,
	       Location = case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       ev.Zone,
	       ev.PktNum, 
	       ev.CustTierLevel,
	       EmpNum = er.EmpNumAuthorize,
	       EmpName = er.EmpNameAuthorize,
	       Source = ev.RejPktNum,
	       Description = 'EMPCARD REMOVE',
		   AfterDisplay = case when l.PktNum is null then 'N' else 'Y' end,
		   'EVENT1_CE', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENT2_CE as er WITH (NOLOCK)
	 inner join (select RejPktNum = cast(left(right(rtrim([DESC]), LEN([DESC])-18), len(RIGHT(rtrim([DESC]),LEN([DESC])-18))-1) as int),
	                    PktNum, Asset, Location, EventDisplay, CustTierLevel, Zone
	 		       from RTSS.dbo.EVENT2_CE WITH (NOLOCK)
			      where [DESC] like '~r:AssignedRemove%'
				    and PktNum in (select PktNum from SQLA_New_Events)) as ev
	    on ev.RejPktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = ev.PktNum and l.EventTable = 'EVENT_CE'
	   and l.EmpNum = er.EmpNumAuthorize
	   and l.tEventState < er.tOut
	   and l.EventState = 'tDisplayMobile'
	 where er.PktNum in (select PktNum from SQLA_New_Events)
	 group by er.tOut, ev.EventDisplay, case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       ev.Zone, ev.PktNum, ev.CustTierLevel, er.EmpNumAuthorize, er.EmpNameAuthorize, ev.RejPktNum, l.PktNum, er.PktNum
	       
END





GO

