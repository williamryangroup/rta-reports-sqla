USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_AreaAssoc]    Script Date: 06/21/2016 13:21:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_AreaAssoc]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_AreaAssoc]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_AreaAssoc] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AssocAreaMode nvarchar(255) = isnull((select LTRIM(rtrim(Setting)) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'AssocAreaMode'),'Default')
	
	truncate table SQLA_AreaAssoc
	
	insert into SQLA_AreaAssoc (Area, AssocArea, Priority, Mode)
	select Area, AssocArea, Priority, Mode
	  from RTSS.dbo.ASSOC_AREA WITH (NOLOCK)
	 where Mode = @AssocAreaMode
END





GO


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_CustTiers]    Script Date: 04/11/2016 09:38:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_CustTiers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_CustTiers]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_CustTiers] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_CustTiers
	
	insert into SQLA_CustTiers (TierLevel, PriorityLevel)
	select TierLevel, PriorityLevel 
	  from RTSS.dbo.TIERPRIORITY WITH (NOLOCK)
	
	IF isnull((select 1 from SQLA_CustTiers where TierLevel = 'NUL'),0) = 0
	BEGIN
		insert into SQLA_CustTiers (TierLevel) values ('NUL')
	END
	
END




GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmpJobTypes]    Script Date: 02/20/2016 19:48:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmpJobTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmpJobTypes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmpJobTypes] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_EmpJobTypes
	
	insert into SQLA_EmpJobTypes (JobType)
	select distinct ltrim(rtrim(JobType))
	  from RTSS.dbo.EMPLOYEE WITH (NOLOCK)
	 where JobType <> ''

END






GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmployeeCompliance]    Script Date: 06/15/2016 11:37:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmployeeCompliance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmployeeCompliance]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmployeeCompliance]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--DECLARE @MinPktNum int = (select isnull(MAX(PktNum),0) from SQLA_EmployeeCompliance)
	DECLARE @ServerIP varchar(15) = (select ltrim(rtrim(Setting)) from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP')
	
	-- Capture new EVENTS purged from RTSS since last SQLA insert
	truncate table SQLA_New_Events
	
	insert into SQLA_New_Events (PktNum)
	select e.PktNum from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where not exists 
		 ( select null from SQLA_EmployeeCompliance as c WITH (NOLOCK)
			where c.PktNum = e.PktNum
			  and c.SourceTable = 'EVENT1' )
			
			
	insert into SQLA_EmployeeCompliance
	select [EmpNum], [EmpNameFirst] = rtrim(emp.NameFirst), [EmpNameLast] = rtrim(emp.NameLast), [EmpJobType] = rtrim(JobType), [PktNum], [EventDisplay], [tOut] = p.tOut,
		   [Asn] = case when tAssign is not null and (tAuthorize is null or (tAuthorize is not null and DATEDIFF(millisecond,tAssign,tAuthorize) >= 1000)) then 1 else 0 end, 
		   [Acp] = case when tAccept is not null then 1 else 0 end,
		   [Rsp] = case when tAuthorize is not null then 1 else 0 end,
		   [Cmp] = case when tComplete is not null then 1 else 0 end,
		   [CmpMobile] = case when tComplete is not null and DeviceIDComplete > 0 then 1 else 0 end,
		   [RejMan] = isnull(RejMan,0),
		   [RejAuto] = isnull(RejAuto,0),
		   [RspRTA] = case when tRespondMobile is not null and AuthPktNum = 0 then 1 else 0 end,
		   [RspCard] = case when tRespondMobile is null and AuthPktNum > 0 then 1 else 0 end,
		   [RspRTAandCard] = case when tRespondMobile is not null and AuthPktNum > 0 then 1 else 0 end,
		   [RspTmSec] = case when tAssign is not null and tAuthorize is not null and tAssign <= tAuthorize then datediff(ss,tAssign,tAuthorize) end,
		   [OverallTmSec] = case when tAssign is not null and tComplete is not null and tAssign <= tComplete then datediff(ss,tAssign,tComplete) end,
		   [tAsnMin] = tAssign, [tRspMin] = tAuthorize,
		   [CustTier] = CustTier,
		   [Rea] = case when tReassign is not null then 1 else 0 end,
		   [ReaRej] = case when tReassignRej is not null then 1 else 0 end,
		   [SourceTable] = 'EVENT1'
	  from (
	select EmpNum, PktNum, EventDisplay, tOut = min(tOut), CustTier,
		   tAssign = min(tAssign),
		   tAccept = min(tAccept),
		   tRespondMobile = min(tRespondMobile),
		   tAuthorize = min(tAuthorize),
		   tComplete = min(tComplete), 
		   AuthPktNum = count(distinct AuthPktNum),
		   DeviceIDComplete = count(distinct DeviceIDComplete),
		   ClosePktNum = count(distinct ClosePktNum),
		   RejMan = count(tRejectManual),
		   RejAuto = count(tRejectAuto),
		   tReassign = min(tReassign),
		   tReassignRej = min(tReassignRej)
	  from (
	  
	-- EVENT_STATE_LOG1
	select l.EmpNum, l.PktNum, e.EventDisplay, CustTier = e.CustTierLevel, tOut = l.tEventState,
		   tAssign = case when l.EventState in ('tAssign','tAssignSupervisor') then l.tEventState else null end,
		   tAccept = case when l.EventState = 'tAcceptMobile' then l.tEventState else null end,
		   tRejectManual = case when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID = l.EventStateSource then l.tEventState
	                            else null end,
		   tRejectAuto = case when l.EventState in ('tRejectAuto','tRejectAutoDevice','tRejectAutoServer') then l.tEventState
	                          when l.EventState = 'tReject' and l.EmpName = @ServerIP then l.tEventState
							  else null end,
		   tAuthorize = case when l.EventState = 'tAuthorize' then l.tEventState else null end,
		   tRespondMobile = case when l.EventState = 'tRespondMobile' then l.tEventState else null end,
		   tComplete = case when l.EventState = 'tComplete' then l.tEventState else null end,
		   AuthPktNum = case when l.EventState = 'tAuthorize' then l.PktNumEventState else null end,
		   DeviceIDComplete = case when l.EventState = 'tComplete' then l.DeviceID else null end,
		   ClosePktNum = case when l.EventState = 'tComplete' then l.PktNumEventState else null end,
		   tReassign = case when l.EventState in ('tReassignAttendant','tReassignSupervisor','tReAssign') then l.tEventState else null end,
		   tReassignRej = case when l.EventState in ('tRejectRA','tRejectRASupervisor') then l.tEventState else null end
	  from RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
		on e.PktNum = l.PktNum and l.EventTable = 'EVENT'
	 where tOut is not null and l.EmpNum is not null and l.EmpNum <> '' and l.EmpName not in ('MGR CLEAR ALL')
	   and e.PktNum in (select PktNum from SQLA_New_Events)
	   and l.EventState in ('tAssign','tAssignSupervisor',
	                        'tAcceptMobile',
							'tReject',
							'tRejectAuto','tRejectAutoDevice','tRejectAutoServer',
							'tAuthorize',
							'tRespondMobile',
							'tComplete',
							'tReassignAttendant','tReassignSupervisor','tReAssign',
							'tRejectRA','tRejectRASupervisor')
	 union all
	 
	-- EVENT_STATE_LOG
	select l.EmpNum, l.PktNum, e.EventDisplay, CustTier = e.CustTierLevel, tOut = l.tEventState,
		   tAssign = case when l.EventState in ('tAssign','tAssignSupervisor') then l.tEventState else null end,
		   tAccept = case when l.EventState = 'tAcceptMobile' then l.tEventState else null end,
		   tRejectManual = case when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID = l.EventStateSource then l.tEventState
	                            else null end,
		   tRejectAuto = case when l.EventState in ('tRejectAuto','tRejectAutoDevice','tRejectAutoServer') then l.tEventState
	                          when l.EventState = 'tReject' and l.EmpName = @ServerIP then l.tEventState
							  else null end,
		   tAuthorize = case when l.EventState = 'tAuthorize' then l.tEventState else null end,
		   tRespondMobile = case when l.EventState = 'tRespondMobile' then l.tEventState else null end,
		   tComplete = case when l.EventState = 'tComplete' then l.tEventState else null end,
		   AuthPktNum = case when l.EventState = 'tAuthorize' then l.PktNumEventState else null end,
		   DeviceIDComplete = case when l.EventState = 'tComplete' then l.DeviceID else null end,
		   ClosePktNum = case when l.EventState = 'tComplete' then l.PktNumEventState else null end,
		   tReassign = case when l.EventState in ('tReassignAttendant','tReassignSupervisor','tReAssign') then l.tEventState else null end,
		   tReassignRej = case when l.EventState in ('tRejectRA','tRejectRASupervisor') then l.tEventState else null end
	  from RTSS.dbo.EVENT_STATE_LOG as l WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
		on e.PktNum = l.PktNum and l.EventTable = 'EVENT'
	 where tOut is not null and l.EmpNum is not null and l.EmpNum <> '' and l.EmpName not in ('MGR CLEAR ALL')
	   and e.PktNum in (select PktNum from SQLA_New_Events)
	   and l.EventState in ('tAssign','tAssignSupervisor',
	                        'tAcceptMobile',
							'tReject',
							'tRejectAuto','tRejectAutoDevice','tRejectAutoServer',
							'tAuthorize',
							'tRespondMobile',
							'tComplete',
							'tReassignAttendant','tReassignSupervisor','tReAssign',
							'tRejectRA','tRejectRASupervisor')
	 union all
	
	-- EVENT - Assign
	select EmpNumAssign, PktNum, EventDisplay, CustTierLevel, tOut, tAssign, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete = null, AuthPktNum = null, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tAssign is not null and EmpNumAssign is not null and EmpNumAssign <> ''
	   and PktNum in (select PktNum from SQLA_New_Events)
	 union all
	 
	-- EVENT - Accept
	select EmpNumAccept, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete = null, AuthPktNum = null, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tAcceptMobile is not null and EmpNumAccept is not null and EmpNumAccept <> ''
	   and PktNum in (select PktNum from SQLA_New_Events)
	 union all
	 
	-- EVENT - Authorize
	select EmpNumAuthorize, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize, tRespondMobile = null, tComplete = null, AuthPktNum, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tAuthorize is not null and EmpNumAuthorize is not null and EmpNumAuthorize <> ''
	   and PktNum in (select PktNum from SQLA_New_Events)
	 union all
	 
	-- EVENT - Respond Mobile
	select EmpNumRespond, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile, tComplete = null, AuthPktNum = null, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tRespondMobile is not null and EmpNumRespond is not null and EmpNumRespond <> ''
	   and PktNum in (select PktNum from SQLA_New_Events)
	 union all
	 
	-- EVENT - Complete
	select EmpNumComplete, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete, AuthPktNum = null, DeviceIDComplete, ClosePktNum, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tComplete is not null and EmpNumComplete is not null and EmpNumComplete <> ''
	   and PktNum in (select PktNum from SQLA_New_Events)
	 union all
	 
	-- EVENT - Complete (from Authorize)
	select EmpNumAuthorize, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete, AuthPktNum = null, DeviceIDComplete, ClosePktNum, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tComplete is not null 
	   and (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null and EmpNumAuthorize is not null and EmpNumAuthorize <> ''
	   and PktNum in (select PktNum from SQLA_New_Events)
	   
	      ) as s
	 group by EmpNum, PktNum, EventDisplay, CustTier
	      ) as p
	  left join RTSS.dbo.EMPLOYEE emp
	    on p.EmpNum = emp.CardNum
	
END



GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmployeeCompliance_Initial]    Script Date: 06/15/2016 11:37:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmployeeCompliance_Initial]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmployeeCompliance_Initial]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmployeeCompliance_Initial]
	@StartDt datetime = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ServerIP varchar(15) = (select ltrim(rtrim(Setting)) from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP')
	
	truncate table SQLA_EmployeeCompliance			
			
	insert into SQLA_EmployeeCompliance
	select [EmpNum], [EmpNameFirst] = rtrim(emp.NameFirst), [EmpNameLast] = rtrim(emp.NameLast), [EmpJobType] = rtrim(JobType), [PktNum], [EventDisplay], [tOut] = p.tOut,
		   [Asn] = case when tAssign is not null and (tAuthorize is null or (tAuthorize is not null and DATEDIFF(millisecond,tAssign,tAuthorize) >= 1000)) then 1 else 0 end, 
		   [Acp] = case when tAccept is not null then 1 else 0 end,
		   [Rsp] = case when tAuthorize is not null then 1 else 0 end,
		   [Cmp] = case when tComplete is not null then 1 else 0 end,
		   [CmpMobile] = case when tComplete is not null and DeviceIDComplete > 0 then 1 else 0 end,
		   [RejMan] = isnull(RejMan,0),
		   [RejAuto] = isnull(RejAuto,0),
		   [RspRTA] = case when tRespondMobile is not null and AuthPktNum = 0 then 1 else 0 end,
		   [RspCard] = case when tRespondMobile is null and AuthPktNum > 0 then 1 else 0 end,
		   [RspRTAandCard] = case when tRespondMobile is not null and AuthPktNum > 0 then 1 else 0 end,
		   [RspTmSec] = case when tAssign is not null and tAuthorize is not null and tAssign <= tAuthorize then datediff(ss,tAssign,tAuthorize) end,
		   [OverallTmSec] = case when tAssign is not null and tComplete is not null and tAssign <= tComplete then datediff(ss,tAssign,tComplete) end,
		   [tAsnMin] = tAssign, [tRspMin] = tAuthorize,
		   [CustTier] = CustTier,
		   [Rea] = case when tReassign is not null then 1 else 0 end,
		   [ReaRej] = case when tReassignRej is not null then 1 else 0 end,
		   [SourceTable] = 'EVENT1'
	  from (
	select EmpNum, PktNum, EventDisplay, tOut = min(tOut), CustTier,
		   tAssign = min(tAssign),
		   tAccept = min(tAccept),
		   tRespondMobile = min(tRespondMobile),
		   tAuthorize = min(tAuthorize),
		   tComplete = min(tComplete), 
		   AuthPktNum = count(distinct AuthPktNum),
		   DeviceIDComplete = count(distinct DeviceIDComplete),
		   ClosePktNum = count(distinct ClosePktNum),
		   RejMan = count(tRejectManual),
		   RejAuto = count(tRejectAuto),
		   tReassign = min(tReassign),
		   tReassignRej = min(tReassignRej)
	  from (
	  
	-- EVENT_STATE_LOG1
	select l.EmpNum, l.PktNum, e.EventDisplay, CustTier = e.CustTierLevel, tOut = l.tEventState,
		   tAssign = case when l.EventState in ('tAssign','tAssignSupervisor') then l.tEventState else null end,
		   tAccept = case when l.EventState = 'tAcceptMobile' then l.tEventState else null end,
		   tRejectManual = case when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID = l.EventStateSource then l.tEventState
	                            else null end,
		   tRejectAuto = case when l.EventState in ('tRejectAuto','tRejectAutoDevice','tRejectAutoServer') then l.tEventState
	                          when l.EventState = 'tReject' and l.EmpName = @ServerIP then l.tEventState
							  else null end,
		   tAuthorize = case when l.EventState = 'tAuthorize' then l.tEventState else null end,
		   tRespondMobile = case when l.EventState = 'tRespondMobile' then l.tEventState else null end,
		   tComplete = case when l.EventState = 'tComplete' then l.tEventState else null end,
		   AuthPktNum = case when l.EventState = 'tAuthorize' then l.PktNumEventState else null end,
		   DeviceIDComplete = case when l.EventState = 'tComplete' then l.DeviceID else null end,
		   ClosePktNum = case when l.EventState = 'tComplete' then l.PktNumEventState else null end,
		   tReassign = case when l.EventState in ('tReassignAttendant','tReassignSupervisor','tReAssign') then l.tEventState else null end,
		   tReassignRej = case when l.EventState in ('tRejectRA','tRejectRASupervisor') then l.tEventState else null end
	  from RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
		on e.PktNum = l.PktNum and l.EventTable = 'EVENT'
	 where tOut is not null and l.EmpNum is not null and l.EmpNum <> '' and l.EmpName not in ('MGR CLEAR ALL')
	   and (@StartDt = null or tOut >= @StartDt)
	   and l.EventState in ('tAssign','tAssignSupervisor',
	                        'tAcceptMobile',
							'tReject',
							'tRejectAuto','tRejectAutoDevice','tRejectAutoServer',
							'tAuthorize',
							'tRespondMobile',
							'tComplete',
							'tReassignAttendant','tReassignSupervisor','tReAssign',
							'tRejectRA','tRejectRASupervisor')
	 union all
	 
	-- EVENT_STATE_LOG
	select l.EmpNum, l.PktNum, e.EventDisplay, CustTier = e.CustTierLevel, tOut = l.tEventState,
		   tAssign = case when l.EventState in ('tAssign','tAssignSupervisor') then l.tEventState else null end,
		   tAccept = case when l.EventState = 'tAcceptMobile' then l.tEventState else null end,
		   tRejectManual = case when l.EventState = 'tReject' and l.EmpName <> @ServerIP and l.DeviceID = l.EventStateSource then l.tEventState
	                            else null end,
		   tRejectAuto = case when l.EventState in ('tRejectAuto','tRejectAutoDevice','tRejectAutoServer') then l.tEventState
	                          when l.EventState = 'tReject' and l.EmpName = @ServerIP then l.tEventState
							  else null end,
		   tAuthorize = case when l.EventState = 'tAuthorize' then l.tEventState else null end,
		   tRespondMobile = case when l.EventState = 'tRespondMobile' then l.tEventState else null end,
		   tComplete = case when l.EventState = 'tComplete' then l.tEventState else null end,
		   AuthPktNum = case when l.EventState = 'tAuthorize' then l.PktNumEventState else null end,
		   DeviceIDComplete = case when l.EventState = 'tComplete' then l.DeviceID else null end,
		   ClosePktNum = case when l.EventState = 'tComplete' then l.PktNumEventState else null end,
		   tReassign = case when l.EventState in ('tReassignAttendant','tReassignSupervisor','tReAssign') then l.tEventState else null end,
		   tReassignRej = case when l.EventState in ('tRejectRA','tRejectRASupervisor') then l.tEventState else null end
	  from RTSS.dbo.EVENT_STATE_LOG as l WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT1 as e WITH (NOLOCK)
		on e.PktNum = l.PktNum and l.EventTable = 'EVENT'
	 where tOut is not null and l.EmpNum is not null and l.EmpNum <> '' and l.EmpName not in ('MGR CLEAR ALL')
	   and (@StartDt = null or tOut >= @StartDt)
	   and l.EventState in ('tAssign','tAssignSupervisor',
	                        'tAcceptMobile',
							'tReject',
							'tRejectAuto','tRejectAutoDevice','tRejectAutoServer',
							'tAuthorize',
							'tRespondMobile',
							'tComplete',
							'tReassignAttendant','tReassignSupervisor','tReAssign',
							'tRejectRA','tRejectRASupervisor')
	 union all
	 
	-- EVENT - Assign
	select EmpNumAssign, PktNum, EventDisplay, CustTierLevel, tOut, tAssign, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete = null, AuthPktNum = null, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tAssign is not null and EmpNumAssign is not null and EmpNumAssign <> ''
	   and (@StartDt = null or tOut >= @StartDt)
	 union all
	 
	-- EVENT - Accept
	select EmpNumAccept, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete = null, AuthPktNum = null, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tAcceptMobile is not null and EmpNumAccept is not null and EmpNumAccept <> ''
	   and (@StartDt = null or tOut >= @StartDt)
	 union all
	 
	-- EVENT - Authorize
	select EmpNumAuthorize, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize, tRespondMobile = null, tComplete = null, AuthPktNum, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tAuthorize is not null and EmpNumAuthorize is not null and EmpNumAuthorize <> ''
	   --and exists (select null from RTSS.dbo.EVENT_STATE_LOG1 as l2 WITH (NOLOCK) where l2.PktNum = e.PktNum)
	   and (@StartDt = null or tOut >= @StartDt)
	 union all
	 
	-- EVENT - Respond Mobile
	select EmpNumRespond, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile, tComplete = null, AuthPktNum = null, DeviceIDComplete = null, ClosePktNum = null, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tRespondMobile is not null and EmpNumRespond is not null and EmpNumRespond <> ''
	   and (@StartDt = null or tOut >= @StartDt)
	 union all
	 
	-- EVENT - Complete
	select EmpNumComplete, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete, AuthPktNum = null, DeviceIDComplete, ClosePktNum, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tComplete is not null and EmpNumComplete is not null and EmpNumComplete <> ''
	   and (@StartDt = null or tOut >= @StartDt)
	 union all
	 
	-- EVENT - Complete (from Authorize)
	select EmpNumAuthorize, PktNum, EventDisplay, CustTierLevel, tOut, tAssign = null, tAcceptMobile = null, tRejectManual = null, tRejectAuto = null, tAuthorize = null, tRespondMobile = null, tComplete, AuthPktNum = null, DeviceIDComplete, ClosePktNum, tReassign = null, tReassignRej = null
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	 where tOut is not null and tComplete is not null 
	   and (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null and EmpNumAuthorize is not null and EmpNumAuthorize <> ''
	   and (@StartDt = null or tOut >= @StartDt)
	   
	      ) as s
	 group by EmpNum, PktNum, EventDisplay, CustTier
	      ) as p
	  left join RTSS.dbo.EMPLOYEE emp
	    on p.EmpNum = emp.CardNum
	
END



GO

USE [RTSS]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmployeeEventTimes]    Script Date: 06/21/2016 11:48:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmployeeEventTimes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmployeeEventTimes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmployeeEventTimes]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	delete from SQLA_EmployeeEventTimes where ActivityEnd is null
	
	DECLARE @MinPktNum int = (select isnull(MAX(PktNum),0) from SQLA_EmployeeEventTimes)
	DECLARE @MinBreakOOSLoginDttm datetime = (select isnull(MAX(ActivityStart),'1/1/2010') from SQLA_EmployeeEventTimes where PktNum in (1,2,3))
	
	
	CREATE TABLE #Employee_EventTimeStart_Tmp (
		PktNum int not null,
		EmpNum nvarchar(255) not null,
		EventDisplay nvarchar(255) null,
		StartTime datetime not null
	)
	
	CREATE TABLE #Employee_EventTimeEnd_Tmp (
		PktNum int not null,
		EmpNum nvarchar(255) not null,
		EventDisplay nvarchar(255) null,
		EndTime datetime not null
	)
	
	CREATE TABLE #Employee_EventTime_Tmp (
		EmpNum [nvarchar](255) NOT NULL,
		EmpNameFirst [nvarchar](50) NULL,
		EmpNameLast [nvarchar](50) NULL,
		EmpJobType [nvarchar](20) NULL,
		PktNum [int] NOT NULL,
		EventDisplay [nvarchar](255) NULL,
		ActivityStart [datetime] NOT NULL,
		ActivityEnd [datetime] NULL,
		ActivitySecs [int] NULL
	)
	
	
	-- Start Times - Employee assigned to event
	insert into #Employee_EventTimeStart_Tmp (PktNum, EmpNum, EventDisplay, StartTime)
    select distinct PktNum, EmpNum, Activity, tOut
	  from SQLA_FloorActivity
	 where PktNum > @MinPktNum and tOut is not null	and EmpNum is not null and EmpNum <> ''
	   and ActivityTypeID = 5 and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor')
	   
	-- Start Times - Employee authorized events without being assigned (Take)
	insert into #Employee_EventTimeStart_Tmp (PktNum, EmpNum, EventDisplay, StartTime)
	select distinct PktNum, EmpNum, Activity, tOut
	  from SQLA_FloorActivity as f1
	 where PktNum > @MinPktNum and tOut is not null and EmpNum is not null and EmpNum <> ''
	   and ActivityTypeID = 5 and State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile')
	   and not exists
		 ( select null from SQLA_FloorActivity as f2
			where f2.PktNum = f1.PktNum
			  and f2.EmpNum = f1.EmpNum
			  and f2.ActivityTypeID = 5
			  and f2.tOut <= f1.tOut
			  and f2.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor') )
	   and not exists
		 ( select null from SQLA_FloorActivity as f2
			where f2.PktNum = f1.PktNum
			  and f2.EmpNum = f1.EmpNum
			  and f2.ActivityTypeID = 5
			  and f2.tOut < f1.tOut
			  and f2.State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile') )
	
	
	-- End Times - Event is completed
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.State like 'Complete%'
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End Times - Employee rejects event or assigned another event
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum = s.EmpNum
	   and (f.State like 'Reject%' or f.State like 'Reassign%Reject' or f.State = 'Event Assigned Remove')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End times - Next event state is with another employee
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum <> s.EmpNum
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	   and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor',
	                 'Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile')
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End Times - Employee is assigned event again
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut > s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum = s.EmpNum
	   and f.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End times - Employee is assigned or authorized another event before event is completed
	/*insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_EventDetails as e
	    on e.PktNum = s.PktNum
	 inner join SQLA_FloorActivity as f
	    on f.tOut <= e.tComplete
	   and f.tOut > s.StartTime
	   and f.PktNum <> s.PktNum
	   and f.EmpNum = s.EmpNum
	   and f.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor','Authorize Card In')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime*/
	
	
	-- INSERT EVENTS
	insert into #Employee_EventTime_Tmp (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
	       s.PktNum, s.EventDisplay, ActivityStart = s.StartTime, ActivityEnd = min(e.EndTime),
		   ActivitySecs = case when (min(e.EndTime) is null) or (min(e.EndTime) < s.StartTime) then 0 else DATEDIFF(second,s.StartTime,min(e.EndTime)) end 
	  from #Employee_EventTimeStart_Tmp as s
	  left join #Employee_EventTimeEnd_Tmp as e
	    on e.PktNum = s.PktNum
	   and e.EmpNum = s.EmpNum
	   and e.EndTime > s.StartTime
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.PktNum, s.EventDisplay, s.StartTime
	
	
	-- DELETE ActivityEnd NULL
	delete from #Employee_EventTime_Tmp where ActivityEnd is null
	
	
	-- DROP tmp tables
	drop table #Employee_EventTimeStart_Tmp
	drop table #Employee_EventTimeEnd_Tmp

	
	-- INSERT tAsn,tRea,tDsp,tAcp,tRsp,tRej,tCmp
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs,tAsn,tRea,tDsp,tAcp,tRsp,tRej,tCmp)
	select e.EmpNum, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType, e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, e.ActivitySecs,
		   tAsn = MIN(case when f.State in ('Assign','Assign Supervisor') then f.tOut else null end),
		   tRea = MIN(case when f.State in ('Re-assign','Reassign Attendant','Reassign Supervisor') then f.tOut else null end),
		   tDsp = MIN(case when f.State in ('Event Display Mobile','Reassign Display Mobile') then f.tOut else null end),
		   tAcp = MIN(case when f.State in ('Accept Mobile') then f.tOut else null end),
		   tRsp = MIN(case when f.State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile') then f.tOut else null end),
		   tRej = MIN(case when f.State like 'Reject%' or f.State like 'Reassign%Reject' then f.tOut else null end),
		   tCmp = MIN(case when f.State like 'Complete%' then f.tOut else null end)
	  from #Employee_EventTime_Tmp as e
	  left join SQLA_FloorActivity as f
		on f.ActivityTypeID = 5
	   and f.PktNum = e.PktNum
	   and f.EmpNum = e.EmpNum
	   and f.tOut >= e.ActivityStart
	   and f.tOut <= e.ActivityEnd
	 group by e.EmpNum, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType, e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, e.ActivitySecs
	 order by e.ActivityStart
	
	
	-- DROP tmp tables
	drop table #Employee_EventTime_Tmp
	
	
	-- INSERT BREAK / OOS
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs,tRsp,tCmp)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs),
		   tRsp = MIN(ActivityStart), tCmp = ActivityEnd
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = s.ActivityTypeID, 
		   EventDisplay = s.Activity,
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
	   and s.State = 'Start' and (e.State in ('End','Start') or e.State like '%Logout%')
	   and s.ActivityTypeID in (1,2) and e.ActivityTypeID in (1,2,3) and s.Activity <> 'OOS - 1. Jackpot Verify'
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.Activity, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- OOS - JP VER
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = min(s.PktNum), 
		   EventDisplay = 'JP VER',
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
	   and s.State = 'Start' and (e.State in ('End','Start') or e.State like '%Logout%')
	   and s.ActivityTypeID in (1,2) and e.ActivityTypeID in (1,2,3) and s.Activity = 'OOS - 1. Jackpot Verify'
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- INSERT AVAILABLE (LOGIN-LOGOUT)
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = s.ActivityTypeID,
		   EventDisplay = 'Available',
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.ActivityTypeID = s.ActivityTypeID
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
	   and s.State = 'Login' and (e.State = 'Login' or e.State like '%Logout%')
	   and s.ActivityTypeID = 3
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- DELETE ActivityEnd NULL
	delete from SQLA_EmployeeEventTimes where ActivityEnd is null

END







GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmployeeEventTimes_Initial]    Script Date: 07/16/2016 04:27:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmployeeEventTimes_Initial]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmployeeEventTimes_Initial]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmployeeEventTimes_Initial]
	@StartDt datetime = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_EmployeeEventTimes
		
	DECLARE @MinPktNum int = (select MIN(PktNum) from SQLA_EventDetails where tOut >= @StartDt)
	DECLARE @MinBreakOOSLoginDttm datetime = @StartDt
	
	
	CREATE TABLE #Employee_EventTimeStart_Tmp (
		PktNum int not null,
		EmpNum nvarchar(255) not null,
		EventDisplay nvarchar(255) null,
		StartTime datetime not null
	)
	
	CREATE TABLE #Employee_EventTimeEnd_Tmp (
		PktNum int not null,
		EmpNum nvarchar(255) not null,
		EventDisplay nvarchar(255) null,
		EndTime datetime not null
	)
	
	CREATE TABLE #Employee_EventTime_Tmp (
		EmpNum [nvarchar](255) NOT NULL,
		EmpNameFirst [nvarchar](50) NULL,
		EmpNameLast [nvarchar](50) NULL,
		EmpJobType [nvarchar](20) NULL,
		PktNum [int] NOT NULL,
		EventDisplay [nvarchar](255) NULL,
		ActivityStart [datetime] NOT NULL,
		ActivityEnd [datetime] NULL,
		ActivitySecs [int] NULL
	)
	
	
	-- Start Times - Employee assigned to event
	insert into #Employee_EventTimeStart_Tmp (PktNum, EmpNum, EventDisplay, StartTime)
    select distinct PktNum, EmpNum, Activity, tOut
	  from SQLA_FloorActivity
	 where PktNum > @MinPktNum and tOut is not null	and EmpNum is not null and EmpNum <> ''
	   and ActivityTypeID = 5 and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor')
	   
	-- Start Times - Employee authorized events without being assigned (Take)
	insert into #Employee_EventTimeStart_Tmp (PktNum, EmpNum, EventDisplay, StartTime)
	select distinct PktNum, EmpNum, Activity, tOut
	  from SQLA_FloorActivity as f1
	 where PktNum > @MinPktNum and tOut is not null and EmpNum is not null and EmpNum <> ''
	   and ActivityTypeID = 5 and State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile')
	   and not exists
		 ( select null from SQLA_FloorActivity as f2
			where f2.PktNum = f1.PktNum
			  and f2.EmpNum = f1.EmpNum
			  and f2.ActivityTypeID = 5
			  and f2.tOut <= f1.tOut
			  and f2.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor') )
	   and not exists
		 ( select null from SQLA_FloorActivity as f2
			where f2.PktNum = f1.PktNum
			  and f2.EmpNum = f1.EmpNum
			  and f2.ActivityTypeID = 5
			  and f2.tOut < f1.tOut
			  and f2.State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile') )
							   
	
	-- End Times - Event is completed
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.State like 'Complete%'
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End Times - Employee rejects event or assigned another event
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum = s.EmpNum
	   and (f.State like 'Reject%' or f.State like 'Reassign%Reject' or f.State = 'Event Assigned Remove')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End times - Next event state is with another employee
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum <> s.EmpNum
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	    -- State must be a 'Start Time' state from above
	   and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor',
	                 'Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile')
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End Times - Employee is assigned event again
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut > s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum = s.EmpNum
	   and f.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End times - Employee is assigned or authorized another event before event is completed
	/*insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_EventDetails as e
	    on e.PktNum = s.PktNum
	 inner join SQLA_FloorActivity as f
	    on f.tOut <= e.tComplete
	   and f.tOut > s.StartTime
	   and f.PktNum <> s.PktNum
	   and f.EmpNum = s.EmpNum
	   and f.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor','Authorize Card In')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime*/
	
	
	-- INSERT EVENTS
	insert into #Employee_EventTime_Tmp (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
	       s.PktNum, s.EventDisplay, ActivityStart = s.StartTime, ActivityEnd = min(e.EndTime),
		   ActivitySecs = case when (min(e.EndTime) is null) or (min(e.EndTime) < s.StartTime) then 0 else DATEDIFF(second,s.StartTime,min(e.EndTime)) end 
	  from #Employee_EventTimeStart_Tmp as s
	  left join #Employee_EventTimeEnd_Tmp as e
	    on e.PktNum = s.PktNum
	   and e.EmpNum = s.EmpNum
	   and e.EndTime > s.StartTime
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.PktNum, s.EventDisplay, s.StartTime
	
	
	-- DELETE ActivityEnd NULL
	delete from #Employee_EventTime_Tmp where ActivityEnd is null
	
	
	-- DROP tmp tables
	drop table #Employee_EventTimeStart_Tmp
	drop table #Employee_EventTimeEnd_Tmp

	
	-- INSERT tAsn,tRea,tDsp,tAcp,tRsp,tRej,tCmp
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs,tAsn,tRea,tDsp,tAcp,tRsp,tRej,tCmp)
	select e.EmpNum, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType, e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, e.ActivitySecs,
		   tAsn = MIN(case when f.State in ('Assign','Assign Supervisor') then f.tOut else null end),
		   tRea = MIN(case when f.State in ('Re-assign','Reassign Attendant','Reassign Supervisor') then f.tOut else null end),
		   tDsp = MIN(case when f.State in ('Event Display Mobile','Reassign Display Mobile') then f.tOut else null end),
		   tAcp = MIN(case when f.State in ('Accept Mobile') then f.tOut else null end),
		   tRsp = MIN(case when f.State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile') then f.tOut else null end),
		   tRej = MIN(case when f.State like 'Reject%' or f.State like 'Reassign%Reject' then f.tOut else null end),
		   tCmp = MIN(case when f.State like 'Complete%' then f.tOut else null end)
	  from #Employee_EventTime_Tmp as e
	  left join SQLA_FloorActivity as f
		on f.ActivityTypeID = 5
	   and f.PktNum = e.PktNum
	   and f.EmpNum = e.EmpNum
	   and f.tOut >= e.ActivityStart
	   and f.tOut <= e.ActivityEnd
	 group by e.EmpNum, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType, e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, e.ActivitySecs
	 order by e.ActivityStart
	
	
	-- DROP tmp tables
	drop table #Employee_EventTime_Tmp
	
	
	-- INSERT BREAK / OOS
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = s.ActivityTypeID, 
		   EventDisplay = case when s.ActivityTypeID = 1 then 'Break' 
							   when s.ActivityTypeID = 2 then 'OOS'
							   when s.ActivityTypeID = 3 then 'Available'
							   else '' end,
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
	   and s.State = 'Start' and (e.State in ('End','Start') or e.State like '%Logout%')
	   and s.ActivityTypeID in (1,2) and e.ActivityTypeID in (1,2,3) and s.Activity <> 'OOS - 1. Jackpot Verify'
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- OOS - JP VER
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs,tRsp,tCmp)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs),
		   tRsp = MIN(ActivityStart), tCmp = ActivityEnd
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = min(s.PktNum), 
		   EventDisplay = 'JP VER',
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
	   and s.State = 'Start' and (e.State in ('End','Start') or e.State like '%Logout%')
	   and s.ActivityTypeID in (1,2) and e.ActivityTypeID in (1,2,3) and s.Activity = 'OOS - 1. Jackpot Verify'
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- INSERT AVAILABLE (LOGIN-LOGOUT)
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = s.ActivityTypeID, 
		   EventDisplay = case when s.ActivityTypeID = 1 then 'Break' 
							   when s.ActivityTypeID = 2 then 'OOS'
							   when s.ActivityTypeID = 3 then 'Available'
							   else '' end,
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.ActivityTypeID = s.ActivityTypeID
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
	   and s.State = 'Login' and (e.State = 'Login' or e.State like '%Logout%')
	   and s.ActivityTypeID = 3
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- DELETE ActivityEnd NULL
	delete from SQLA_EmployeeEventTimes where ActivityEnd is null
	
END


GO


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_Employees]    Script Date: 02/20/2016 20:09:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_Employees]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_Employees]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_Employees] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_Employees
	
	insert into SQLA_Employees (CardNum, NameFirst, NameLast, JobType)
	select CardNum, 
	       NameFirst = ltrim(rtrim(NameFirst)),
	       NameLast = ltrim(rtrim(NameLast)), 
	       JobType = ltrim(rtrim(JobType))
	  from RTSS.dbo.EMPLOYEE WITH (NOLOCK)

END

GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EventDetails]    Script Date: 06/15/2016 11:40:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EventDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EventDetails]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EventDetails]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--DECLARE @MinPktNum int = isnull((select MAX(PktNum) from SQLA_EventDetails),0)
	DECLARE @UseAssetField char(255) = isnull((select case when Setting = 'Asset' then '1' else '0' end from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),'0')
	
	insert into SQLA_EventDetails (PktNum, tOut, tOutHour, CustNum, CustName, CustTierLevel, CustPriorityLevel, Location, Zone, EventDisplay, tAssign, tAccept, tAuthorize, tComplete, CompCode, HasReject, EmpNumAsn, EmpNameAsn, EmpNumRsp, EmpNameRsp, EmpNumCmp, EmpNameCmp, RspRTA, RspCard, CmpMobile, CmpGame, CmpWS, ResolutionDescID, ResolutionDesc, Reassign, ReassignSupervisor, FromZone, EmpJobTypeAsn, EmpJobTypeRsp, EmpJobTypeCmp, RspSecs, CmpSecs, TotSecs, AsnTakeID, AsnTake, SourceTable, AmtEvent)
	select PktNum,
	       tOut,
	       tOutHour,
	       CustNum,
	       CustName,
	       CustTierLevel,
	       CustPriorityLevel,
	       Location,
	       Zone,
	       EventDisplay,
	       tAssign,
	       tAccept,
	       tAuthorize,
	       tComplete,
	       CompCode,
	       HasReject,
	       EmpNumAsn,
	       EmpNameAsn,
	       EmpNumRsp,
	       EmpNameRsp,
	       EmpNumCmp,
	       EmpNameCmp,
	       RspRTA,
	       RspCard,
	       CmpMobile,
	       CmpGame,
	       CmpWS,
	       ResolutionDescID,
	       ResolutionDesc,
	       Reassign,
	       ReassignSupervisor,
	       FromZone,
	       EmpJobTypeAsn = isnull((select ltrim(rtrim(JobType)) from RTSS.dbo.EMPLOYEE as j WITH (NOLOCK) where j.CardNum = d.EmpNumAsn),''),
	       EmpJobTypeRsp = isnull((select ltrim(rtrim(JobType)) from RTSS.dbo.EMPLOYEE as j WITH (NOLOCK) where j.CardNum = d.EmpNumRsp),''),
	       EmpJobTypeCmp = isnull((select ltrim(rtrim(JobType)) from RTSS.dbo.EMPLOYEE as j WITH (NOLOCK) where j.CardNum = d.EmpNumCmp),''),
	       RspSecs = case when d.tAuthorize is null then -1 when d.tAuthorize <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tAuthorize) end,
	       CmpSecs = case when d.tAuthorize is null then -1 else DATEDIFF(second, d.tAuthorize, d.tComplete) end,
	       TotSecs = DATEDIFF(second, d.tOut, d.tComplete),
	       AsnTakeID = case when (d.EmpNumAsn is null or d.EmpNumAsn = '') and (d.EmpNumRsp is null or d.EmpNumRsp = '') then 3
	                      when (d.EmpNumAsn is not null and d.EmpNumAsn <> '') and ((d.EmpNumAsn = d.EmpNumRsp) or (d.EmpNumRsp is null or d.EmpNumRsp = '')) and (DATEDIFF(millisecond,d.tAssign,d.tAuthorize) >= 1000) then 1 else 2 end,
	       AsnTake = case when (d.EmpNumAsn is null or d.EmpNumAsn = '') and (d.EmpNumRsp is null or d.EmpNumRsp = '') then 'Cmp'
	                      when (d.EmpNumAsn is not null and d.EmpNumAsn <> '') and ((d.EmpNumAsn = d.EmpNumRsp) or (d.EmpNumRsp is null or d.EmpNumRsp = '')) and (DATEDIFF(millisecond,d.tAssign,d.tAuthorize) >= 1000) then 'Asn' else 'Take' end,
	       SourceTable = 'EVENT1', AmtEvent
	  from (
	select distinct e.PktNum, e.tOut, tOutHour = DATEPART(HOUR,e.tOut),
		   CustNum,
		   CustName = case when CustName is null or CustName = '' then CustNameFirst+' '+CustNameLast else CustName end,
		   CustTierLevel = case when CustTierLevel = '' or CustTierLevel = 'NULL' or CustTierLevel IS null then 'NUL' else CustTierLevel end,
		   CustPriorityLevel,
		   Location = case when @UseAssetField = '1' then Asset else e.Location end,
		   e.Zone,
		   EventDisplay,
		   tAssign = case when l.PktNum is not null then l.tOut else e.tAssign end,
		   tAccept = tAcceptMobile,
		   tAuthorize = case when e.tInitialResponse is not null and isdate(e.tInitialResponse)=1 and e.tInitialResponse >= '1/2/1980' and (e.tInitialResponse <= e.tAuthorize or e.tAuthorize is null) and e.tInitialResponse <= e.tComplete then e.tInitialResponse else e.tAuthorize end,
		   tComplete,
		   CompCode = CloseBy911,
		   HasReject = case when tReject is not null then 1 else 0 end,
		   EmpNumAsn = case when l.PktNum is not null then l.EmpNum else EmpNumAssign end,
		   EmpNameAsn = case when l.PktNum is not null then l.EmpName else EmpNameAssign end,
		   EmpNumRsp = case when EmpNumInitialResponse is null or EmpNumInitialResponse = '' then EmpNumAuthorize else EmpNumInitialResponse end,
		   EmpNameRsp = case when EmpNameInitialResponse is null or EmpNameInitialResponse = '' then EmpNameAuthorize else EmpNameInitialResponse end,
		   EmpNumCmp = case when (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null then EmpNumAuthorize
		                    else EmpNumComplete end,
		   EmpNameCmp = case when (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null then EmpNameAuthorize
		                     else EmpNameComplete end,
		   RspRTA = case when tRespondMobile is not null and AuthPktNum is null then 1 else 0 end,
		   RspCard = case when tRespondMobile is null and AuthPktNum is not null then 1 else 0 end,
		   CmpMobile = case when DeviceIDComplete is not null and [Desc] <> '~r:Dashboard' then 1 else 0 end,
		   CmpGame = case when DeviceIDComplete is null and ClosePktNum is not null then 1 else 0 end,
		   CmpWS = case when DeviceIDComplete is null and ClosePktNum is null then 1
		                when DeviceIDComplete is not null and [Desc] = '~r:Dashboard' then 2
		                else 0 end,
		   ResolutionDescID = case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then 5
		                           when ResolutionDesc = 'No Event' then 1
		                           when EmpNumAssign in (select CardNum from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where JobType = 'Supervisor') and tReassign is null and tReassignSupervisor is null then 2
		                           when tReassign is not null and tReassign <> '' then 3
		                           when tReassignSupervisor is not null and tReassignSupervisor <> '' then 4
		                           else null end,
		   ResolutionDesc = case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ltrim(rtrim(isnull(ResolutionDesc,'')))
		                         when ResolutionDesc = 'No Event' then ltrim(rtrim(ResolutionDesc))
		                         when EmpNumAssign in (select CardNum from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where JobType = 'Supervisor') and tReassign is null and tReassignSupervisor is null then 'SupervisorAssign'
		                         when tReassign is not null and tReassign <> '' then 'Reassign'
		                         when tReassignSupervisor is not null and tReassignSupervisor <> '' then 'ReassignSupervisor'
		                         else '' end,
		   Reassign = case when tReassign is null or tReassign = '' then 0 else 1 end,
		   ReassignSupervisor = case when tReassignSupervisor is null or tReassignSupervisor = '' then 0 else 1 end,
		   FromZone = e.AssocArea,
		   e.AmtEvent
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	  left join SQLA_FloorActivity as l WITH (NOLOCK)
	    on l.PktNum = e.PktNum
	   and l.State = 'Assign'
	   and l.Source not in ('LOGOUT')
	   and datediff(MILLISECOND,l.tOut,isnull(e.tAuthorize,e.tComplete)) >= 1000  -- authorize or complete are not within 1 second of assign time
	 where not exists (select null from SQLA_EventDetails as d WITH (NOLOCK) where e.PktNum = d.PktNum and d.SourceTable = 'EVENT1')
	   and (e.tOut is not NULL and isdate(e.tOut) = 1 and e.tOut > '1/2/1980')
	   and (e.tComplete is not NULL and isdate(e.tComplete)=1 and e.tComplete >= e.tOut)
	   and ((e.tAuthorize is not null and isdate(e.tAuthorize)=1 and e.tAuthorize > '1/2/1980') or (e.tAuthorize is null))
	   and not exists
	     ( select null from SQLA_FloorActivity as l2 WITH (NOLOCK)
	        where l2.PktNum = l.PktNum
	          and l2.State = 'Assign'
	          and l2.Source not in ('LOGOUT')
	          and datediff(MILLISECOND,l2.tOut,isnull(e.tAuthorize,e.tComplete)) >= 1000  -- authorize or complete are not within 1 second of assign time
	          and l2.tOut > l.tOut )
	       ) as d
END



GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EventDetails_Initial]    Script Date: 06/15/2016 11:40:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EventDetails_Initial]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EventDetails_Initial]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EventDetails_Initial]
	@StartDt datetime = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--DECLARE @MinPktNum int = (select isnull(MAX(PktNum),0) from SQLA_EventDetails)
	DECLARE @UseAssetField char(255) = isnull((select case when Setting = 'Asset' then '1' else '0' end from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),'0')
	
	truncate table SQLA_EventDetails
	
	insert into SQLA_EventDetails (PktNum, tOut, tOutHour, CustNum, CustName, CustTierLevel, CustPriorityLevel, Location, Zone, EventDisplay, tAssign, tAccept, tAuthorize, tComplete, CompCode, HasReject, EmpNumAsn, EmpNameAsn, EmpNumRsp, EmpNameRsp, EmpNumCmp, EmpNameCmp, RspRTA, RspCard, CmpMobile, CmpGame, CmpWS, ResolutionDescID, ResolutionDesc, Reassign, ReassignSupervisor, FromZone, EmpJobTypeAsn, EmpJobTypeRsp, EmpJobTypeCmp, RspSecs, CmpSecs, TotSecs, AsnTakeID, AsnTake, SourceTable, AmtEvent)
	select PktNum,
	       tOut,
	       tOutHour,
	       CustNum,
	       CustName,
	       CustTierLevel,
	       CustPriorityLevel,
	       Location,
	       Zone,
	       EventDisplay,
	       tAssign,
	       tAccept,
	       tAuthorize,
	       tComplete,
	       CompCode,
	       HasReject,
	       EmpNumAsn,
	       EmpNameAsn,
	       EmpNumRsp,
	       EmpNameRsp,
	       EmpNumCmp,
	       EmpNameCmp,
	       RspRTA,
	       RspCard,
	       CmpMobile,
	       CmpGame,
	       CmpWS,
	       ResolutionDescID,
	       ResolutionDesc,
	       Reassign,
	       ReassignSupervisor,
	       FromZone,
	       EmpJobTypeAsn = isnull((select ltrim(rtrim(JobType)) from RTSS.dbo.EMPLOYEE as j WITH (NOLOCK) where j.CardNum = d.EmpNumAsn),''),
	       EmpJobTypeRsp = isnull((select ltrim(rtrim(JobType)) from RTSS.dbo.EMPLOYEE as j WITH (NOLOCK) where j.CardNum = d.EmpNumRsp),''),
	       EmpJobTypeCmp = isnull((select ltrim(rtrim(JobType)) from RTSS.dbo.EMPLOYEE as j WITH (NOLOCK) where j.CardNum = d.EmpNumCmp),''),
	       RspSecs = case when d.tAuthorize is null then -1 when d.tAuthorize <= d.tOut then 0 else DATEDIFF(second,d.tOut,d.tAuthorize) end,
	       CmpSecs = case when d.tAuthorize is null then -1 else DATEDIFF(second, d.tAuthorize, d.tComplete) end,
	       TotSecs = DATEDIFF(second, d.tOut, d.tComplete),
	       AsnTakeID = case when (d.EmpNumAsn is null or d.EmpNumAsn = '') and (d.EmpNumRsp is null or d.EmpNumRsp = '') then 3
	                      when (d.EmpNumAsn is not null and d.EmpNumAsn <> '') and ((d.EmpNumAsn = d.EmpNumRsp) or (d.EmpNumRsp is null or d.EmpNumRsp = '')) and (DATEDIFF(millisecond,d.tAssign,d.tAuthorize) >= 1000) then 1 else 2 end,
	       AsnTake = case when (d.EmpNumAsn is null or d.EmpNumAsn = '') and (d.EmpNumRsp is null or d.EmpNumRsp = '') then 'Cmp'
	                      when (d.EmpNumAsn is not null and d.EmpNumAsn <> '') and ((d.EmpNumAsn = d.EmpNumRsp) or (d.EmpNumRsp is null or d.EmpNumRsp = '')) and (DATEDIFF(millisecond,d.tAssign,d.tAuthorize) >= 1000) then 'Asn' else 'Take' end,
	       SourceTable = 'EVENT1', AmtEvent
	  from (
	select distinct e.PktNum, e.tOut, tOutHour = DATEPART(HOUR,e.tOut),
		   CustNum,
		   CustName = case when CustName is null or CustName = '' then CustNameFirst+' '+CustNameLast else CustName end,
		   CustTierLevel = case when CustTierLevel = '' or CustTierLevel = 'NULL' or CustTierLevel IS null then 'NUL' else CustTierLevel end,
		   CustPriorityLevel,
		   Location = case when @UseAssetField = '1' then Asset else e.Location end,
		   e.Zone,
		   EventDisplay,
		   tAssign = case when l.PktNum is not null then l.tOut else e.tAssign end,
		   tAccept = tAcceptMobile,
		   tAuthorize = case when e.tInitialResponse is not null and isdate(e.tInitialResponse)=1 and e.tInitialResponse >= '1/2/1980' and (e.tInitialResponse <= e.tAuthorize or e.tAuthorize is null) and e.tInitialResponse <= e.tComplete then e.tInitialResponse else e.tAuthorize end,
		   tComplete,
		   CompCode = CloseBy911,
		   HasReject = case when tReject is not null then 1 else 0 end,
		   EmpNumAsn = case when l.PktNum is not null then l.EmpNum else EmpNumAssign end,
		   EmpNameAsn = case when l.PktNum is not null then l.EmpName else EmpNameAssign end,
		   EmpNumRsp = case when EmpNumInitialResponse is null or EmpNumInitialResponse = '' then EmpNumAuthorize else EmpNumInitialResponse end,
		   EmpNameRsp = case when EmpNameInitialResponse is null or EmpNameInitialResponse = '' then EmpNameAuthorize else EmpNameInitialResponse end,
		   EmpNumCmp = case when (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null then EmpNumAuthorize
		                    else EmpNumComplete end,
		   EmpNameCmp = case when (EmpNumComplete is null or EmpNumComplete = '' or EmpNumComplete = '0') and ClosePktNum is not null then EmpNameAuthorize
		                     else EmpNameComplete end,
		   RspRTA = case when tRespondMobile is not null and AuthPktNum is null then 1 else 0 end,
		   RspCard = case when tRespondMobile is null and AuthPktNum is not null then 1 else 0 end,
		   CmpMobile = case when DeviceIDComplete is not null then 1 else 0 end,
		   CmpGame = case when DeviceIDComplete is null and ClosePktNum is not null then 1 else 0 end,
		   CmpWS = case when DeviceIDComplete is null and ClosePktNum is null then 1
		                when DeviceIDComplete is not null and [Desc] = '~r:Dashboard' then 2
		                else 0 end,
		   ResolutionDescID = case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then 5
		                           when ResolutionDesc = 'No Event' then 1
		                           when EmpNumAssign in (select CardNum from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where JobType = 'Supervisor') and tReassign is null and tReassignSupervisor is null then 2
		                           when tReassign is not null and tReassign <> '' then 3
		                           when tReassignSupervisor is not null and tReassignSupervisor <> '' then 4
		                           else null end,
		   ResolutionDesc = case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ltrim(rtrim(isnull(ResolutionDesc,'')))
		                         when ResolutionDesc = 'No Event' then ltrim(rtrim(ResolutionDesc))
		                         when EmpNumAssign in (select CardNum from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where JobType = 'Supervisor') and tReassign is null and tReassignSupervisor is null then 'SupervisorAssign'
		                         when tReassign is not null and tReassign <> '' then 'Reassign'
		                         when tReassignSupervisor is not null and tReassignSupervisor <> '' then 'ReassignSupervisor'
		                         else '' end,
		   Reassign = case when tReassign is null or tReassign = '' then 0 else 1 end,
		   ReassignSupervisor = case when tReassignSupervisor is null or tReassignSupervisor = '' then 0 else 1 end,
		   FromZone = e.AssocArea,
		   e.AmtEvent
	  from RTSS.dbo.EVENT1 as e WITH (NOLOCK)
	  left join SQLA_FloorActivity as l WITH (NOLOCK)
	    on l.PktNum = e.PktNum
	   and l.State = 'Assign'
	   and l.Source not in ('LOGOUT')
	   and datediff(MILLISECOND,l.tOut,isnull(e.tAuthorize,e.tComplete)) >= 1000  -- authorize or complete are not within 1 second of assign time
	 where (@StartDt = null or e.tOut >= @StartDt)
	   and (e.tOut is not NULL and isdate(e.tOut) = 1 and e.tOut > '1/2/1980')
	   and (e.tComplete is not NULL and isdate(e.tComplete)=1 and e.tComplete >= e.tOut)
	   and ((e.tAuthorize is not null and isdate(e.tAuthorize)=1 and e.tAuthorize > '1/2/1980') or (e.tAuthorize is null))
	   and not exists
	     ( select null from SQLA_FloorActivity as l2 WITH (NOLOCK)
	        where l2.PktNum = l.PktNum
	          and l2.State = 'Assign'
	          and l2.Source not in ('LOGOUT')
	          and datediff(MILLISECOND,l2.tOut,isnull(e.tAuthorize,e.tComplete)) >= 1000  -- authorize or complete are not within 1 second of assign time
	          and l2.tOut > l.tOut )
	       ) as d
END



GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EventDetails_JPVER]    Script Date: 10/04/2016 11:49:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EventDetails_JPVER]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EventDetails_JPVER]
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EventDetails_JPVER]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- *** JP VER - OOS ***
	insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
	select e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, 'OOS', e.EmpNum, EmpName = e.EmpNameFirst + ' ' + e.EmpNameLast, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType
	  from SQLA_EmployeeEventTimes as e
	  left join SQLA_EventDetails_JPVER as j
		on j.PktNum = e.PktNum
	 where e.EventDisplay = 'JP VER' and j.PktNum is null


	-- *** JP VER - TknCmp ***
	insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
	select e.PktNum, EventDisplay = 'JP VER', tOut = e.tRsp, tComplete = e.tCmp, Source = 'TknCmp', e.EmpNum, EmpName = e.EmpNameFirst + ' ' + e.EmpNameLast, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType
	  from SQLA_EmployeeEventTimes as e
	  left join SQLA_EventDetails_JPVER as j
		on j.PktNum = e.PktNum
	 where e.EventDisplay like 'JKPT%' and j.PktNum is null
	   and ((e.tAsn is null and e.tRea is null) or (e.tAsn is not null and DATEDIFF(SECOND,e.tAsn,e.tRsp) <= 1))
	   and e.tRsp is not null and e.tCmp is not null
	   
	   
	update e
	   set e.EventDisplay = j.EventDisplay
	--select j.EventDisplay, e.*
	  from SQLA_EventDetails as e
	 inner join SQLA_EventDetails_JPVER as j
		on j.PktNum = e.PktNum
	 where e.EventDisplay = 'OOS'
END

GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EventTypes]    Script Date: 08/31/2016 08:11:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EventTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EventTypes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EventTypes]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_EventTypes
	
	insert into SQLA_EventTypes (EventDisplay) values ('JP VER')
	
	insert into SQLA_EventTypes (EventDisplay)
	select distinct EventDisplay
	  from RTSS.dbo.EVENT1 WITH (NOLOCK)
	 where EventDisplay not in ('','JP VER')
	

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
			   WHERE TABLE_NAME = N'EVENT1_ST')
	BEGIN
		insert into SQLA_EventTypes (EventDisplay)
		select distinct EventDisplay
		  from RTSS.dbo.EVENT1_ST WITH (NOLOCK)
		 where EventDisplay not in ('','JP VER')
		   and EventDisplay not in (select EventDisplay from SQLA_EventTypes)
	END
	

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
			   WHERE TABLE_NAME = N'EVENT1_CE')
	BEGIN
		insert into SQLA_EventTypes (EventDisplay)
		select distinct EventDisplay
		  from RTSS.dbo.EVENT1_CE WITH (NOLOCK)
		 where EventDisplay not in ('','JP VER')
		   and EventDisplay not in (select EventDisplay from SQLA_EventTypes)
	END

	
	delete from SQLA_EventTypes
	 where EventDisplay <> dbo.RemoveNonASCII(EventDisplay)
	   and exists 
		 ( select null from SQLA_EventTypes
	        where EventDisplay = dbo.RemoveNonASCII(EventDisplay) )
	
	update SQLA_EventTypes
	   set EventDisplay = dbo.RemoveNonASCII(EventDisplay)
	
END





GO


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_FloorActivity]    Script Date: 06/21/2016 13:58:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_FloorActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_FloorActivity]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_FloorActivity]

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	-- Capture new EVENT_STATES purged from RTSS since last SQLA insert
	truncate table SQLA_New_SEQ
	
	insert into SQLA_New_SEQ (SEQ)
	select l.SEQ from RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
		on e.PktNum = l.PktNum and l.EventTable = 'EVENT'
	 where l.tEventState is not null and e.EventDisplay not in ('OOS','10 6')
	   and EventState not in ('tRecd','tOut','tDisplay','tInitialResponse','tRemove','tComplete','tRejectAuto')
	   and not exists 
		 ( select null from SQLA_FloorActivity as f WITH (NOLOCK)
			where f.SourceTable = 'EVENT_STATE_LOG1' and f.SourceTableID = l.SEQ)
	
	
	-- Capture new EVENTS purged from RTSS since last SQLA insert
	truncate table SQLA_New_Events
	
	insert into SQLA_New_Events (PktNum)
	select e.PktNum from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where not exists 
		 ( select null from SQLA_FloorActivity as f WITH (NOLOCK)
			where f.SourceTable = 'EVENT1' and f.SourceTableID = e.PktNum)
	
	/*
	-- Capture new SYSTEMLOG entries purged from RTSS since last SQLA insert
	truncate table SQLA_New_SysLog
	
	declare @MinEvtNum int = isnull((select min(f.SourceTableID) from SQLA_FloorActivity as f WITH (NOLOCK) where f.SourceTable = 'SYSTEMLOG1'),1)
	
	insert into SQLA_New_SysLog (EvtNum)
	select e.EvtNum from RTSS.dbo.SYSTEMLOG1 as e WITH (NOLOCK)
	 where e.EvtNum > @MinEvtNum and not exists 
		 ( select null from SQLA_FloorActivity as f WITH (NOLOCK)
			where f.SourceTable = 'SYSTEMLOG1' and f.SourceTableID = e.EvtNum)
	*/
	
	-- Capture new RTSS.dbo.EMPLOYEEACTIVITY purged from RTSS since last SQLA insert
	truncate table SQLA_New_EmpAct
	
	declare @NewEmpActDttm datetime = dateadd(day,-3,cast(GETDATE() as date))
	
	insert into SQLA_New_EmpAct (CardNum, tOut, tIn)
	select CardNum, tOut, tIn from RTSS.dbo.EMPLOYEEACTIVITY1 as e WITH (NOLOCK)
	 where tOut >= @NewEmpActDttm
	   and not exists 
		 ( select null from SQLA_FloorActivity as f
			where f.SourceTable = 'EMPLOYEEACTIVITY1'
			  and f.SourceTableID2 = e.CardNum
			  and f.SourceTableDttm1 = e.tOut
			  and f.SourceTableDttm2 = e.tIn )
	
	insert into SQLA_New_EmpAct (CardNum, tOut, tIn)
	select CardNum, tOut, tIn from RTSS.dbo.EMPLOYEEACTIVITY as e WITH (NOLOCK)
	 where (    Activity like 'LOGIN%'
	         or Activity like 'LOGOUT%' 
	         or Activity like 'ZONES SERVED%'
	         or Activity like 'FLOOR STATUS%')
	   and not exists 
		 ( select null from SQLA_FloorActivity as f
			where f.SourceTable = 'EMPLOYEEACTIVITY1'
			  and f.SourceTableID2 = e.CardNum
			  and f.SourceTableDttm1 = e.tOut
			  and f.SourceTableDttm2 = e.tIn )
	
	
	DECLARE @MinAlert1ID int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'ALERT1')
	DECLARE @MinSysLog1EvtNum int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1')
	--DECLARE @MinEvtStateLog1Seq int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'EVENT_STATE_LOG1')
	--DECLARE @MinDeviceNotifTimesID int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'DEVICE_NOTIFICATION_TIMES')
	--DECLARE @MinEvent1PktNum int = (select isnull(MAX(SourceTableID),0) from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'EVENT1')
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
	
	
	
    -- RTSS.dbo.EMPLOYEE ACTIVITY - Login/Logout, Zone Change, Break Start
	insert into SQLA_FloorActivity
	select e.tOut, 
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
	       Location = '', Zone = '', PktNum = PktNum1,  Tier = '', EmpNum = ltrim(rtrim(e.CardNum)),
		   EmpName = ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)), [Source] = DeviceID, '', '',
		   'EMPLOYEEACTIVITY1', null, e.CardNum, e.tOut, e.tIn
	  from RTSS.dbo.EMPLOYEEACTIVITY1 as e WITH (NOLOCK)
	 inner join SQLA_New_EmpAct as n WITH (NOLOCK)
	    on n.CardNum = e.CardNum
	   and n.tOut = e.tOut
	   and n.tIn = e.tIn
	 where e.tOut > '1/2/1980' and Activity not in ('MANUAL REJECT','') and Activity not like 'REJECT%' and Activity not like 'OOS%' and Activity not like '10 6%'
	
	
	-- RTSS.dbo.EMPLOYEE ACTIVITY - Break End
	insert into SQLA_FloorActivity
	select Time = e.tIn, 
	       ActivityTypeID = case when Activity like 'Break%' then 1
	                             when Activity like 'OOS%' or Activity like '10 6%' then 2
	                             else null end,
	       State = 'End', Activity = ltrim(rtrim(Activity)) + ' ' + isnull(ltrim(rtrim(ActivityDescr)),''), Location = '', Zone = '', PktNum = PktNum1,  Tier = '', 
		   EmpNum = ltrim(rtrim(e.CardNum)), EmpName = ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)), [Source] = DeviceID, '', '',
		   'EMPLOYEEACTIVITY1',null, e.CardNum, e.tOut, e.tIn
	  from RTSS.dbo.EMPLOYEEACTIVITY1 as e WITH (NOLOCK)
	 inner join SQLA_New_EmpAct as n WITH (NOLOCK)
	    on n.CardNum = e.CardNum
	   and n.tOut = e.tOut
	   and n.tIn = e.tIn
	 where e.tOut > '1/2/1980' and Activity like 'Break%'
	
	
    -- RTSS.dbo.EMPLOYEE ACTIVITY - Login/Logout, Zone Change, Break Start
	insert into SQLA_FloorActivity
	select e.tOut, 
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
	       Location = '', Zone = '', PktNum = PktNum1,  Tier = '', EmpNum = ltrim(rtrim(e.CardNum)),
		   EmpName = ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)), [Source] = DeviceID, '', '',
		   'EMPLOYEEACTIVITY1', null, e.CardNum, e.tOut, e.tIn
	  from RTSS.dbo.EMPLOYEEACTIVITY as e WITH (NOLOCK)
	 inner join SQLA_New_EmpAct as n WITH (NOLOCK)
	    on n.CardNum = e.CardNum
	   and n.tOut = e.tOut
	   and n.tIn = e.tIn
	 where e.tOut > '1/2/1980' and Activity not in ('MANUAL REJECT','') and Activity not like 'REJECT%' and Activity not like 'OOS%' and Activity not like '10 6%'
	
	
	-- RTSS.dbo.EMPLOYEE ACTIVITY - Break End
	insert into SQLA_FloorActivity
	select Time = e.tIn, 
	       ActivityTypeID = case when Activity like 'Break%' then 1
	                             when Activity like 'OOS%' or Activity like '10 6%' then 2
	                             else null end,
	       State = 'End', Activity = ltrim(rtrim(Activity)) + ' ' + isnull(ltrim(rtrim(ActivityDescr)),''), Location = '', Zone = '', PktNum = PktNum1,  Tier = '', 
		   EmpNum = ltrim(rtrim(e.CardNum)), EmpName = ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)), [Source] = DeviceID, '', '',
		   'EMPLOYEEACTIVITY1',null, e.CardNum, e.tOut, e.tIn
	  from RTSS.dbo.EMPLOYEEACTIVITY as e WITH (NOLOCK)
	 inner join SQLA_New_EmpAct as n WITH (NOLOCK)
	    on n.CardNum = e.CardNum
	   and n.tOut = e.tOut
	   and n.tIn = e.tIn
	 where e.tOut > '1/2/1980' and Activity like 'Break%'
	
	
	
	-- EVENT - OOS/10 6 - Start
	insert into SQLA_FloorActivity
	select tOut, 2, 'Start', PktCbMsg, '', '', PktNum, '', EmpNumAuthorize, EmpNameAuthorize, DeviceIDRespond, '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tOut > '1/2/1980' and EventDisplay in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	   
	-- EVENT - OOS/10 6 - End
	insert into SQLA_FloorActivity
	select tComplete, 2, 'End', PktCbMsg, '', '', PktNum, '', EmpNumAuthorize, EmpNameAuthorize, isnull(DeviceIDComplete,ClosePktNum), ResolutionDesc, '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tComplete is not null and tComplete > '1/2/1980' and EventDisplay in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)

	
	
	-- EVENT - Received
	insert into SQLA_FloorActivity
	select tRecd, 5, 'RTSS Receive', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tRecd is not null and tRecd > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and exists (select null from RTSS.dbo.EVENT_STATE_LOG1 as l2 where l2.PktNum = e.PktNum and l2.EventTable = 'EVENT')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Open
	insert into SQLA_FloorActivity
	select tOut, 5, 'RTSS Open', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tOut is not null and tOut > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Display Workstation
	insert into SQLA_FloorActivity
	select tDisplay, 5, 'Display Workstation', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, '', '', '', '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tDisplay is not null and tDisplay > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Reject
	insert into SQLA_FloorActivity
	select tReject, 5, 'Reject' + case when DeviceIDReject is null or DeviceIDReject = '' or DeviceIDReject = @ServerIP then ' Auto' else ' Manual' end, 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
		   case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumReject, EmpNameReject, DeviceIDReject, '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tReject is not null and tReject > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Authorize - Initial
	insert into SQLA_FloorActivity
	select tInitialResponse, 5, 'Authorize Initial', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumInitialResponse, EmpNameInitialResponse, isnull(cast(AuthPktNum as varchar),DeviceIDInitialResponse), '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tInitialResponse is not null and tInitialResponse > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Authorize - no initial
	insert into SQLA_FloorActivity
	select tAuthorize, 5, 'Authorize' + case when AuthPktNum is not null then ' Card In'
	                                         when DeviceIDRespond is not null and DeviceIDRespond <> '' and DeviceIDRespond <> @ServerIP then ' Mobile' end, 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumAuthorize, EmpNameAuthorize, isnull(cast(AuthPktNum as varchar),DeviceIDRespond), '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where (tInitialResponse is null or tInitialResponse <= '1/2/1980') and tAuthorize is not null and tAuthorize > '1/2/1980' and EventDisplay not in ('OOS','10 6')
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Authorize - EMPCARD 
	insert into SQLA_FloorActivity
	select tAuthorize, 5, 'Authorize Card In', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumAuthorize, EmpNameAuthorize, cast(AuthPktNum as varchar), '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
	 where tAuthorize is not null and tAuthorize > '1/2/1980' and EventDisplay = 'EMPCARD'
	   and PktNum in (select PktNum from SQLA_New_Events)
	
	
	-- EVENT - Remove
	insert into SQLA_FloorActivity
	select tRemove, 5, 'Remove', 
	       EventDisplay = EventDisplay + case when EventDisplay = 'EMPCARD' and DeviceIDComplete is not null then ' ' + ltrim(rtrim(isnull(ResolutionDesc,'')))
	                                          when EventDisplay in ('JKPT','PJ','JP','PROG') then ' ' + isnull(AmtEvent,'')
	                                          else '' end,
	       case when @UseAssetAsLocation = 1 then Asset else Location end, Zone, PktNum, CustTierLevel, EmpNumComplete, EmpNameComplete, DeviceIDComplete, '', '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
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
				when EmpNameComplete = 'RTSSGUI' then Address end, ltrim(rtrim(ResolutionDesc)), '','EVENT1',PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as e WITH (NOLOCK)
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
							  isnull((select distinct 'Y' from RTSS.dbo.EVENT_STATE_LOG1 as l2 WITH (NOLOCK)
									   where l2.PktNum = l.PktNum and l2.EventTable = 'EVENT'
										 and l2.EmpNum = l.EmpNum
										 and l2.tEventState < l.tEventState
										 and l2.EventState = 'tDisplayMobile'),'N')
							  else '' end,
			   'EVENT_STATE_LOG1', l.SEQ, '', '', ''
		  from RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
			on e.PktNum = l.PktNum and l.EventTable = 'EVENT'
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
			 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
				on e.PktNum = n.PktNum
			 where tNotifyPushed is not null and tNotifyPushed > '1/2/1980' and EventDisplay not in ('OOS','10 6')
			   and e.PktNum in (select PktNum from SQLA_New_Events)
		END
		
		-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Respond
		insert into SQLA_FloorActivity
		select tDeviceRespond, 5, 'Device Notification Respond', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDRespond, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDRespond), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
		  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
			on e.PktNum = n.PktNum
		 where tDeviceRespond is not null and tDeviceRespond > '1/2/1980' and EventDisplay not in ('OOS','10 6')
		   and e.PktNum in (select PktNum from SQLA_New_Events)
		
		IF @CaptAllGetEvents = 0
		BEGIN
			-- RTSS.dbo.DEVICE_NOTIFICATION_TIMES - Pull
			insert into SQLA_FloorActivity
			select tEventSent, 5, 'Event Notification Mobile', e.EventDisplay, case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone, n.PktNum, e.CustTierLevel, n.DeviceIDNotify, (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = n.DeviceIDNotify), '', '', '', 'DEVICE_NOTIFICATION_TIMES', ID, '', '', ''
			  from RTSS.dbo.DEVICE_NOTIFICATION_TIMES as n WITH (NOLOCK)
			 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
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
		 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
		    on e.PktNum = cast(s.EvtDetail1 as int)
		 where EvtType = 'GetEvents' and EvtDetail1 <> '-1'
		   and not exists (select null from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1' and SourceTableID = EvtNum)
		
		-- RTSS.dbo.SYSTEMLOG - GetEvent - EventDetail2 - non-Popup
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Get Event', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone = e.Zone, PktNum = cast(EvtDetail2 as int),
		       Tier = e.CustTierLevel, EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
		    on e.PktNum = cast(s.EvtDetail2 as int)
		 where EvtType = 'GetEvents' and EvtDetail2 <> '-1' and (EvtDetail4 is null or EvtDetail4 = '')
		   and not exists (select null from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1' and SourceTableID = EvtNum)
		
		-- RTSS.dbo.SYSTEMLOG - GetEvent - EventDetail2 - Popup
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Get Event Popup', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end, Zone = e.Zone, PktNum = cast(EvtDetail2 as int),
		       Tier = e.CustTierLevel, EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
		    on e.PktNum = cast(s.EvtDetail2 as int)
		 where EvtType = 'GetEvents' and EvtDetail2 <> '-1' and EvtDetail4 is not null and EvtDetail4 <> '' 
		   and not exists (select null from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1' and SourceTableID = EvtNum)
	END
	
	
	IF @AutoDispatchLogging = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - AutoDispatch
		insert into SQLA_FloorActivity
		select Time = EvtTime, ActivityTypeID = 5, State = 'Auto Dispatch', Activity = e.EventDisplay, Location = case when @UseAssetAsLocation = 1 then e.Asset else e.Location end,
			   Zone = e.Zone, PktNum = cast(EvtDetail1 as int), Tier = e.CustTierLevel, EmpNum = '', EmpName = '', [Source] = 'RTSS', EvtDetail2, '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 inner join RTSS.dbo.EVENT2 as e WITH (NOLOCK)
			on e.PktNum = cast(s.EvtDetail1 as int)
		 where EvtType = 'AutoDispatch'
		   and not exists (select null from SQLA_FloorActivity WITH (NOLOCK) where SourceTable = 'SYSTEMLOG1' and SourceTableID = EvtNum)
	END
	
	
	IF @SupTrackDashboard = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - Scorecard
		insert into SQLA_FloorActivity
		select Time = EvtTime, 6, State = EvtType, Activity = ltrim(rtrim(EvtDescr)), Location = '', Zone = '', PktNum = null, Tier = '', EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where s.EvtNum > @MinSysLog1EvtNum and EvtType = 'SupervDashboard'
	END
	
	
	IF @SupTrackAdmin = 1
	BEGIN
		-- RTSS.dbo.SYSTEMLOG - Supervisor Admin - Event
		insert into SQLA_FloorActivity
		select Time = EvtTime, 7, State = EvtType, Activity = ltrim(rtrim(EvtDescr)), Location = '', Zone = '', PktNum = case when ISNUMERIC(EvtDetail1)= 1 then cast(EvtDetail1 as int) else null end, Tier = '', EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where s.EvtNum > @MinSysLog1EvtNum and EvtType = 'SupervAdmEvt'
		
		-- RTSS.dbo.SYSTEMLOG - Supervisor Admin - Employee
		insert into SQLA_FloorActivity
		select Time = EvtTime, 8, State = EvtType, Activity = ltrim(rtrim(EvtDescr)), Location = '', Zone = '', PktNum = null, Tier = '', EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), '', '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where s.EvtNum > @MinSysLog1EvtNum and EvtType = 'SupervAdmEmp'
		
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
			   Location = '', Zone = '', PktNum = null, Tier = '', EmpNum = s.EvtDetail1, EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE where CardNum = s.EvtDetail1), [Source] = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), '', '',
			   'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
		 where s.EvtNum > @MinSysLog1EvtNum and EvtType = 'SupervAdmEmp'
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
		 where a.ID > @MinAlert1ID and alertType <> 'EVENT'
		
		-- RTSS.dbo.ALERT - Create - NON-Employee
		insert into SQLA_FloorActivity
		select Time = tCreate, 9, State = 'Alert Open', 
		       Activity = ltrim(rtrim(alertType)) + case when alertType = 'Jackpot Alert' and CHARINDEX('$',alertText,10) > 0 then ' - $' + right(ltrim(rtrim(alertText)),len(ltrim(rtrim(alertText)))-CHARINDEX('$',alertText,10)) else '' end,
			   Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = '', EmpName = '', [Source] = '', ID, '', 'ALERT1', ID, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		 where a.ID > @MinAlert1ID and alertType <> 'EVENT'
		   and a.alertUser not in (select CardNum from RTSS.dbo.EMPLOYEE)
		   
		-- RTSS.dbo.SYSTEMLOG - Display Alert Popup
		insert into SQLA_FloorActivity
		select Time = EvtTime, 9, State = 'Display Alert Popup', Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), ltrim(rtrim(s.EvtDescr)), '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
			on s.EvtDescr = a.ID
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		 where s.EvtNum > @MinSysLog1EvtNum and EvtType = 'NEW ALERT'
		   
		-- RTSS.dbo.SYSTEMLOG - Alert Accept/Dismiss
		insert into SQLA_FloorActivity
		select Time = EvtTime, 9, State = 'Alert ' + ltrim(rtrim(EvtDescr)), Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = ltrim(rtrim(UserName)), EmpName = (select ltrim(rtrim(NameFirst)) + ' ' + ltrim(rtrim(NameLast)) from RTSS.dbo.EMPLOYEE WITH (NOLOCK) where CardNum = s.UserName), [Source] = ltrim(rtrim(MachineName)), ltrim(rtrim(s.EvtDetail3)), '', 'SYSTEMLOG1', EvtNum, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join RTSS.dbo.SYSTEMLOG1 as s WITH (NOLOCK)
			on s.EvtDetail3 = a.ID
		  left join RTSS.dbo.LOCZONE as l WITH (NOLOCK)
			on l.Location = a.location
		 where s.EvtNum > @MinSysLog1EvtNum and EvtType = 'SupervProcAlert'
		 
		-- RTSS.dbo.ALERT - Alert Resolved/Evt Cmp
		insert into SQLA_FloorActivity
		select Time = e.tComplete, 9, State = 'Alert Resolved/Evt Cmp', Activity = ltrim(rtrim(alertType)), Location = ltrim(rtrim(a.location)), Zone, PktNum = EventTablePktNum, Tier = ltrim(rtrim(priority)), EmpNum = '', EmpName = '', [Source] = '', ID, '', 'ALERT1', ID, '', '', ''
		  from RTSS.dbo.ALERT1 as a WITH (NOLOCK)
		 inner join dbo.EVENT2 as e WITH (NOLOCK)
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
		  left join dbo.EVENT2 as e WITH (NOLOCK)
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
		   'EVENTREJECT1', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENTREJECT1 as er WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2 as ev WITH (NOLOCK)
		on ev.PktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = er.PktNum and l.EventTable = 'EVENT'
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
		   'EVENTREJECT', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENTREJECT as er WITH (NOLOCK)
	 inner join RTSS.dbo.EVENT2 as ev WITH (NOLOCK)
		on ev.PktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = er.PktNum and l.EventTable = 'EVENT'
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
		   'EVENT1', er.PktNum, '', '', ''
	  from RTSS.dbo.EVENT2 as er WITH (NOLOCK)
	 inner join (select RejPktNum = cast(left(right(rtrim([DESC]), LEN([DESC])-18), len(RIGHT(rtrim([DESC]),LEN([DESC])-18))-1) as int),
	                    PktNum, Asset, Location, EventDisplay, CustTierLevel, Zone
	 		       from RTSS.dbo.EVENT2 WITH (NOLOCK)
			      where [DESC] like '~r:AssignedRemove%'
				    and PktNum in (select PktNum from SQLA_New_Events)) as ev
	    on ev.RejPktNum = er.PktNum
	  left join RTSS.dbo.EVENT_STATE_LOG1 as l WITH (NOLOCK)
	    on l.PktNum = ev.PktNum and l.EventTable = 'EVENT'
	   and l.EmpNum = er.EmpNumAuthorize
	   and l.tEventState < er.tOut
	   and l.EventState = 'tDisplayMobile'
	 where er.PktNum in (select PktNum from SQLA_New_Events)
	 group by er.tOut, ev.EventDisplay, case when @UseAssetAsLocation = 1 then ev.Asset else ev.Location end,
	       ev.Zone, ev.PktNum, ev.CustTierLevel, er.EmpNumAuthorize, er.EmpNameAuthorize, ev.RejPktNum, l.PktNum, er.PktNum
	       
END





GO


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
		 inner join dbo.EVENT1 as e WITH (NOLOCK)
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
		  left join dbo.EVENT1 as e WITH (NOLOCK)
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


USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_Locations]    Script Date: 02/20/2016 18:34:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_Locations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_Locations]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_Locations] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UseAssetField int = isnull((select case when Setting = 'Asset' then 1 else 0 end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),0)
	DECLARE @UseArea int = isnull((select case when ltrim(rtrim(Setting)) = '1' then 1 else 0 end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'AssociatedAreasMode'),0)
	
	truncate table SQLA_Locations
	
	insert into SQLA_Locations (Location, Asset, Zone, Area, IsActive, DisplayLocation, ZoneArea)
	select Location, Asset, Zone, Area, IsActive,
	       DisplayLocation = case when @UseAssetField = 1 then Asset else Location end,
	       ZoneArea = case when @UseArea = 1 then Area else Zone end
	  from RTSS.dbo.LOCZONE WITH (NOLOCK)
	
END




GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_ShiftHours]    Script Date: 02/20/2016 18:06:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_ShiftHours]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_ShiftHours]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_ShiftHours]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_ShiftHours
	
	insert into SQLA_ShiftHours (StartHour, ShiftName, ShiftHours, ShiftColumn)
    select StartHour, ShiftName, ShiftHours, ShiftColumn
      from RTSS.dbo.EmployeeShift1 WITH (NOLOCK) where StartHour >= 0 and StartHour < 24
END

GO

USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_ZoneArea]    Script Date: 03/15/2016 04:07:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_ZoneArea]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_ZoneArea]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_ZoneArea] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UseArea int = 0
	DECLARE @ZonesAreNumeric int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZonesAreNumeric'),0)
	
	select @UseArea = case when ltrim(rtrim(Setting)) = '1' then 1 else 0 end
	  from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK)
	 where ConfigSection = 'System' and ConfigParam = 'AssociatedAreasMode'
		
	truncate table SQLA_ZoneArea
	
	insert into SQLA_ZoneArea (ZoneArea) values ('00')
	
	insert into SQLA_ZoneArea (ZoneArea)
	select distinct ZoneArea = case when @UseArea = 1 then ltrim(rtrim(Area)) else ltrim(rtrim(Zone)) end
	  from RTSS.dbo.LOCZONE WITH (NOLOCK)
	 where (    ((@UseArea =  1) and (Area is not null and Area <> '00') and ((@ZonesAreNumeric = 0) or (@ZonesAreNumeric = 1 and isnumeric(Area)=1)) )
	         or ((@UseArea <> 1) and (Zone is not null and Zone <> '00') and ((@ZonesAreNumeric = 0) or (@ZonesAreNumeric = 1 and isnumeric(Zone)=1)) ))
END



GO

