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
		   [SourceTable] = 'EVENT1',
		   [RtaCardTmSec] = case when tRespondCard > isnull(tRespondMobile,tAccept) then datediff(ss,isnull(tRespondMobile,tAccept),tRespondCard) else 0 end,
		   [AcpTmSec] = case when tAccept is not null then datediff(ss,tAssign,tAccept) end
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
		   tReassignRej = min(tReassignRej),
		   tRespondCard = min(case when AuthPktNum is not null and AuthPktNum <> '' then tAuthorize else null end)
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

