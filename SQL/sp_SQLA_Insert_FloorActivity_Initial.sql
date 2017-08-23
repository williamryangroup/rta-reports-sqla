USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_FloorActivity_Initial]    Script Date: 06/21/2016 13:59:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_FloorActivity_Initial]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_FloorActivity_Initial]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_FloorActivity_Initial] 
	@StartDt datetime = null

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
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
	
	truncate table SQLA_FloorActivity
	
	
    -- RTSS.dbo.EMPLOYEE ACTIVITY - Login/Logout, Zone Change, Break Start
	insert into SQLA_FloorActivity
	select tOut, 
	       ActivityTypeID = case when Activity like 'Break%' then 1
	                             when Activity like 'OOS%' or Activity like '10 6%' then 2
	                             when Activity like 'Login%' or Activity like 'Start Shift%' or Activity like 'Logout%' or Activity like 'End Shift%' or Activity like 'Out%' then 3
	                             when Activity like 'Zones Served%' or Activity like 'Floor Status%' or Activity like 'Multi Event%' or Activity like 'JP Only%' then 4
	                             else null end,
	       State = case when Activity like 'Login%' then 'Login' 
	                    when Activity like 'Logout%' then 'Logout'
	                    when Activity like 'Out%' then 'Logout'
	                    when Activity like 'End Shift%' then 'End'
	                    when Activity like 'Zones Served%' or Activity like 'Floor Status%' or Activity like 'Multi Event%' or Activity like 'JP Only%' then 'Change'
	                    else 'Start' end, 
	       Activity = case when Activity like 'End Shift%' then right(rtrim(Activity),LEN(Activity)-4)
	                       when Activity like 'Login%' or Activity like 'Start Shift%' then right(rtrim(Activity),LEN(Activity)-6)
	                       when Activity like 'Logout%' then right(rtrim(Activity),LEN(Activity)-7)
	                       else rtrim(Activity) end + ' ' + isnull(rtrim(ActivityDescr),''),
	       Location = '', Zone = '', PktNum = PktNum1,  Tier = '', EmpNum = ltrim(rtrim(CardNum)),
		   EmpName = ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)), [Source] = DeviceID, '', '',
		   'EMPLOYEEACTIVITY1', null, CardNum, tOut, tIn
	  from RTSS.dbo.EMPLOYEEACTIVITY1 WITH (NOLOCK)
	 where tOut > '1/2/1980' and Activity not in ('MANUAL REJECT','') and Activity not like 'REJECT%' and Activity not like 'OOS%' and Activity not like '10 6%'
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- RTSS.dbo.EMPLOYEE ACTIVITY - Break End
	insert into SQLA_FloorActivity
	select Time = tIn, 
	       ActivityTypeID = case when Activity like 'Break%' then 1
	                             when Activity like 'OOS%' or Activity like '10 6%' then 2
	                             else null end,
	       State = 'End', Activity = ltrim(rtrim(Activity)) + ' ' + isnull(ltrim(rtrim(ActivityDescr)),''), Location = '', Zone = '', PktNum = PktNum1,  Tier = '', 
		   EmpNum = ltrim(rtrim(CardNum)), EmpName = ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)), [Source] = DeviceID, '', '',
		   'EMPLOYEEACTIVITY1', null, CardNum, tOut, tIn
	  from RTSS.dbo.EMPLOYEEACTIVITY1 WITH (NOLOCK)
	 where tOut > '1/2/1980' and Activity like 'Break%'
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	
	-- EVENT - OOS/10 6 - Start
	insert into SQLA_FloorActivity
	select tOut, 2, 'Start', PktCbMsg, '', '', PktNum, '', EmpNumAuthorize, EmpNameAuthorize, DeviceIDRespond, '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tOut > '1/2/1980' and EventDisplay in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	   
	-- EVENT - OOS/10 6 - End
	insert into SQLA_FloorActivity
	select tComplete, 2, 'End', PktCbMsg, '', '', PktNum, '', EmpNumAuthorize, EmpNameAuthorize, isnull(DeviceIDComplete,ClosePktNum), ResolutionDesc, '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tComplete is not null and tComplete > '1/2/1980' and EventDisplay in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)

	
	
	-- EVENT - Received
	insert into SQLA_FloorActivity
	select tRecd, 5, 'RTSS Receive', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tRecd is not null and tRecd > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- EVENT - Open
	insert into SQLA_FloorActivity
	select tOut, 5, 'RTSS Open', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tOut > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- EVENT - Display Workstation
	insert into SQLA_FloorActivity
	select tDisplay, 5, 'Display Workstation', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tDisplay is not null and tDisplay > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- EVENT - Reject
	insert into SQLA_FloorActivity
	select tReject, 5, 'Reject' + case when DeviceIDReject is null or DeviceIDReject = '' or DeviceIDReject = @ServerIP then ' Auto' else ' Manual' end, 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumReject, EmpNameReject, DeviceIDReject, '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tReject is not null and tReject > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- EVENT - Authorize - Initial
	insert into SQLA_FloorActivity
	select tInitialResponse, 5, 'Authorize Initial', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumInitialResponse, EmpNameInitialResponse, isnull(cast(AuthPktNum as varchar),DeviceIDInitialResponse), '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tInitialResponse is not null and tInitialResponse > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- EVENT - Authorize - no initial
	insert into SQLA_FloorActivity
	select tAuthorize, 5, 'Authorize' + case when AuthPktNum is not null then ' Card In'
	                                         when DeviceIDRespond is not null and DeviceIDRespond <> '' and DeviceIDRespond <> @ServerIP then ' Mobile' end, 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumAuthorize, EmpNameAuthorize, isnull(cast(AuthPktNum as varchar),DeviceIDRespond), '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where (tInitialResponse is null or tInitialResponse <= '1/2/1980') and tAuthorize is not null and tAuthorize > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- EVENT - Authorize - EMPCARD 
	insert into SQLA_FloorActivity
	select tAuthorize, 5, 'Authorize Card In', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumAuthorize, EmpNameAuthorize, cast(AuthPktNum as varchar), '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tAuthorize is not null and tAuthorize > '1/2/1980' and EventDisplay = 'EMPCARD'
	   and (@StartDt = null or tOut >= @StartDt)
	
	
	-- EVENT - Remove
	insert into SQLA_FloorActivity
	select tRemove, 5, 'Remove', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumComplete, EmpNameComplete, DeviceIDComplete, '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tRemove is not null and tRemove > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
	
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
				when EmpNameComplete = 'RTSSGUI' then Address end, ltrim(rtrim(ResolutionDesc)), '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tComplete is not null and tComplete > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and (@StartDt = null or tOut >= @StartDt)
	
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
					when l.EventState = 'tJackpotVerify' then 'Jackpot Verify'
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
							  isnull((select distinct 'Y' from RTSS.dbo.EVENT_STATE_LOG1 as l2 WITH (NOLOCK)
									   where l2.PktNum = l.PktNum and l2.EventTable = 'EVENT'
										 and l2.EmpNum = l.EmpNum
										 and l2.tEventState < l.tEventState
										 and l2.EventState = 'tDisplayMobile'),'N')
							  else '' end,
			   'EVENT_STATE_LOG1', l.SEQ, '', '', ''
		  from RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
			on e.PktNum = l.PktNum and l.EventTable = 'EVENT'
		 where l.tEventState is not null and e.EventDisplay not in ('OOS','10 6')
		   and EventState not in ('tRecd','tOut','tDisplay','tInitialResponse','tRemove','tComplete','tRejectAuto')
		   and (@StartDt = null or tOut >= @StartDt)
	END
	
	
	IF @CaptEvtNotifyTimes = 1
	BEGIN
		IF @UseWebSockets = 1
		BEGIN
			-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Pushed
			insert into SQLA_FloorActivity
			select tNotifyPushed, 5, 'Device Notification Pushed', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDNotify, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDNotify), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
			  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
			 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
				on e.PktNum = n.PktNum
			 where tNotifyPushed is not null and tNotifyPushed > '1/2/1980' and EventDisplay not in ('OOS','10 6')
			   and (@StartDt = null or tOut >= @StartDt)
		END
		
		-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Respond
		insert into SQLA_FloorActivity
		select tDeviceRespond, 5, 'Device Notification Respond', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDRespond, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDRespond), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
		  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
			on e.PktNum = n.PktNum
		 where tDeviceRespond is not null and tDeviceRespond > '1/2/1980' and EventDisplay not in ('OOS','10 6')
		   and (@StartDt = null or tOut >= @StartDt)
		
		IF @CaptAllGetEvents = 0
		BEGIN
			-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Pull
			insert into SQLA_FloorActivity
			select tEventSent, 5, 'Event Notification Mobile', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDNotify, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDNotify), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
			  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
			 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
				on e.PktNum = n.PktNum
			 where tEventSent is not null and tEventSent > '1/2/1980' and EventDisplay not in ('OOS','10 6') and n.DeviceIDNotify is not null
			   and (@StartDt = null or tOut >= @StartDt)
		END
	END
	
	
	IF @CaptAllGetEvents = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - GetEvent - EventDetail1
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Get Event', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone = e.Zone, PktNum = cast(EvtDetail1 as int),
		       Tier = e.CustTierLevel, EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
		    on e.PktNum = cast(s.EvtDetail1 as int)
		 where EvtType = 'GetEvents'
		   and EvtDetail1 <> '-1'
		   and (@StartDt = null or EvtTime >= @StartDt)
		
		-- RTSS.dbo.SYSTEMLOG - GetEvent - EventDetail2
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Get Event', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone = e.Zone, PktNum = cast(EvtDetail2 as int),
		       Tier = e.CustTierLevel, EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
		    on e.PktNum = cast(s.EvtDetail2 as int)
		 where EvtType = 'GetEvents'
		   and EvtDetail2 <> '-1'
		   and (@StartDt = null or EvtTime >= @StartDt)
	END
	
	
	IF @AutoDispatchLogging = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - AutoDispatch
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Auto Dispatch', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end,
			   Zone = e.Zone, PktNum = cast(EvtDetail1 as int), Tier = e.CustTierLevel, EmpNum = '', EmpName = '', [Source] = 'RTSS', EvtDetail2, '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
			on e.PktNum = cast(s.EvtDetail1 as int)
		 where EvtType = 'AutoDispatch'
		   and (@StartDt = null or EvtTime >= @StartDt)
	END
	
	
	IF @SupTrackDashboard = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - Scorecard
		insert into SQLA_FloorActivity
		select Time = EvtTime, 6, State = EvtType, Activity = ltrim(rtrim(EvtDescr)), Location = '', Zone = '', PktNum = null, Tier = '', EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where EvtType = 'SupervDashboard'
		   and (@StartDt = null or EvtTime >= @StartDt)
	END
	
	
	IF @SupTrackAdmin = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - Supervisor Admin - Event
		insert into SQLA_FloorActivity
		select Time = EvtTime, 7, State = EvtType, Activity = ltrim(rtrim(EvtDescr)), Location = '', Zone = '', PktNum = case when ISNUMERIC(EvtDetail1)= 1 then cast(EvtDetail1 as int) else null end, Tier = '', EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where EvtType = 'SupervAdmEvt'
		   and (@StartDt = null or EvtTime >= @StartDt)
		
		-- RTSS.dbo.SYSTEMLOG - Supervisor Admin - Employee
		insert into SQLA_FloorActivity
		select Time = EvtTime, 8, State = EvtType, Activity = ltrim(rtrim(EvtDescr)), Location = '', Zone = '', PktNum = null, Tier = '', EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where EvtType = 'SupervAdmEmp'
		   and (@StartDt = null or EvtTime >= @StartDt)
		
		-- RTSS.dbo.SYSTEMLOG - Supervisor Admin - Employee
		insert into SQLA_FloorActivity
		select tOut = EvtTime, 
			   ActivityTypeID = case when EvtDescr like '%Break%' then 1
									 when EvtDescr like 'OOS%' then 2
									 when EvtDescr like 'Logoff%' then 3
									 when EvtDescr like 'Assign Zones%' then 4
									 else null end,
			   State = case when EvtDescr like 'Start%' then 'Sup Start'
							when EvtDescr like 'End%' then 'Sup End'
							when EvtDescr like 'Assign Zones%' then 'Sup Change'
							when EvtDescr like 'Logoff%' then 'Sup Logout'
							else '' end,
			   Activity = case when EvtDescr like '%Break%' then 'Break'
							   when EvtDescr like '%OOS%' then 'OOS'
							   when EvtDescr like 'Logoff%' then 'DEVICE ID: ' + s.EvtDetail3
							   when EvtDescr like 'Assign Zones%' then 'Zones'
							   else ltrim(rtrim(EvtDescr)) end,
			   Location = '', Zone = '', PktNum = null, Tier = '', EmpNum = s.EvtDetail1, EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.EvtDetail1), [Source] = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), '', '',
			   'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where EvtType = 'SupervAdmEmp'
		   and (@StartDt = null or EvtTime >= @StartDt)
	END
	
	
	IF @CheckAlertsPollInterval > 0
	BEGIN
		-- RTSS.dbo.ALERT - Create - EMPLOYEE
		insert into SQLA_FloorActivity
		select Time = tCreate, 9, State = 'Alert Open', 
		       Activity = ltrim(rtrim(alertType)) + case when alertType = 'Jackpot Alert' and CHARINDEX('$',alertText,10) > 0 then ' - $' + right(ltrim(rtrim(alertText)),len(ltrim(rtrim(alertText)))-CHARINDEX('$',alertText,10)) else '' end,
			   Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = a.alertUser, EmpName = ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)), [Source] = '', ID, '', 'ALERT1', ID, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join RTSS.dbo.EMPLOYEE as e WITH (NOLOCK)
			on e.CardNum = a.alertUser
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		 where alertType <> 'EVENT' and (@StartDt = null or tCreate >= @StartDt)
		
		-- RTSS.dbo.ALERT - Create - NON-Employee
		insert into SQLA_FloorActivity
		select Time = tCreate, 9, State = 'Alert Open', 
		       Activity = ltrim(rtrim(alertType)) + case when alertType = 'Jackpot Alert' and CHARINDEX('$',alertText,10) > 0 then ' - $' + right(ltrim(rtrim(alertText)),len(ltrim(rtrim(alertText)))-CHARINDEX('$',alertText,10)) else '' end,
			   Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = '', EmpName = '', [Source] = '', ID, '', 'ALERT1', ID, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		 where alertType <> 'EVENT' and (@StartDt = null or tCreate >= @StartDt)
		   and a.alertUser not in (select CardNum from RTSS.dbo.EMPLOYEE)
		   
		-- RTSS.dbo.SYSTEMLOG - Display Alert Popup
		insert into SQLA_FloorActivity
		select Time = EvtTime, 9, State = 'Display Alert Popup', Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), ltrim(rtrim(s.EvtDescr)), '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
			on s.EvtDescr = a.ID
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		 where EvtType = 'NEW ALERT' and (@StartDt = null or EvtTime >= @StartDt)
		   
		-- RTSS.dbo.SYSTEMLOG - Alert Accept/Dismiss
		insert into SQLA_FloorActivity
		select Time = EvtTime, 9, State = 'Alert ' + ltrim(rtrim(EvtDescr)), Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), ltrim(rtrim(s.EvtDetail3)), '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
			on s.EvtDetail3 = a.ID
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		 where EvtType = 'SupervProcAlert' and (@StartDt = null or EvtTime >= @StartDt)
		 
		-- RTSS.dbo.ALERT - Alert Resolved/Evt Cmp
		insert into SQLA_FloorActivity
		select Time = e.tComplete, 9, State = 'Alert Resolved/Evt Cmp', Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = '', EmpName = '', [Source] = '', ID, '', 'ALERT1', ID, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
		    on a.EventTablePktNum = e.PktNum
		 where a.alertType <> 'EVENT' and (@StartDt = null or tCreate >= @StartDt)
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
		  left join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
		    on a.EventTablePktNum = e.PktNum
		   and a.tDismiss >= e.tComplete
		 where a.alertType <> 'EVENT' and (@StartDt = null or tCreate >= @StartDt)
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
		     'EVENTREJECT1', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENTREJECT1 as er WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT1 as ev WITH (NOLOCK)
		  on ev.PktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = er.PktNum and l.EventTable = 'EVENT'
	   and l.EmpNum = er.EmpNumReject
	   and l.tEventState < er.tReject
	   and l.EventState = 'tDisplayMobile'
	 where er.RejectReason like 'AUTOREJECT%' and ev.tReject is not null
	   and exists (select null from RTSS.dbo.EVENT_STATE_LOG1 as l2 where l2.PktNum = ev.PktNum and l2.EventTable = 'EVENT')
	   and (@StartDt = null or tOut >= @StartDt)
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
		     'EVENTREJECT', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENTREJECT as er WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT1 as ev WITH (NOLOCK)
		on ev.PktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = er.PktNum and l.EventTable = 'EVENT'
	   and l.EmpNum = er.EmpNumReject
	   and l.tEventState < er.tReject
	   and l.EventState = 'tDisplayMobile'
	 where er.RejectReason like 'AUTOREJECT%' and ev.tReject is not null
	   and exists (select null from RTSS.dbo.EVENT_STATE_LOG1 as l2 where l2.PktNum = ev.PktNum and l2.EventTable = 'EVENT')
	   and (@StartDt = null or tOut >= @StartDt)
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
		   'EVENT1', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENT1 as er
	 inner join (select RejPktNum = cast(left(right(rtrim([DESC]), LEN([DESC])-18), len(RIGHT(rtrim([DESC]),LEN([DESC])-18))-1) as int),
	                    PktNum, Asset, Location, EventDisplay, CustTierLevel, Zone
	 		           from RTSS.dbo.EVENT1 WITH (NOLOCK)
			          where [DESC] like '~r:AssignedRemove%') as ev
	    on ev.RejPktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = ev.PktNum and l.EventTable = 'EVENT'
	   and l.EmpNum = er.EmpNumAuthorize
	   and l.tEventState < er.tOut
	   and l.EventState = 'tDisplayMobile'
	 where exists (select null from RTSS.dbo.EVENT_STATE_LOG1 as l2 where l2.PktNum = ev.PktNum and l2.EventTable = 'EVENT')
	   and (@StartDt = null or tOut >= @StartDt)
	 group by er.tOut, ev.EventDisplay, case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       ev.Zone, ev.PktNum, ev.CustTierLevel, er.EmpNumAuthorize, er.EmpNameAuthorize, ev.RejPktNum, l.PktNum, er.PktNum
	       
END



GO
