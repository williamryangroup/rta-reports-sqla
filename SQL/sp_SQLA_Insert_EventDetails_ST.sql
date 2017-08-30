USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EventDetails_ST]    Script Date: 06/15/2016 11:40:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EventDetails_ST]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EventDetails_ST]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EventDetails_ST]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--DECLARE @MinPktNum int = isnull((select MAX(PktNum) from SQLA_EventDetails),0)
	DECLARE @UseAssetField char(255) = isnull((select case when Setting = 'Asset' then '1' else '0' end from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),'0')
	DECLARE @ProcessProgJP int = isnull((select cast(Setting as int) from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'MGAM' and ConfigParam = 'ProcessProgJP'),1)
	DECLARE @ProcessTilt int = isnull((select cast(Setting as int) from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'MGAM' and ConfigParam = 'ProcessTilt'),1)
	DECLARE @FeedType char(255) = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'SYSTEM' and ConfigParam = 'FeedType'),'')
	
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
	       SourceTable = 'EVENT1_ST', AmtEvent
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
	  from RTSS.dbo.EVENT4_ST as e WITH (NOLOCK)
	  left join SQLA_FloorActivity as l WITH (NOLOCK)
	    on l.PktNum = e.PktNum
	   and l.State = 'Assign'
	   and l.Source not in ('LOGOUT')
	   and datediff(MILLISECOND,l.tOut,isnull(e.tAuthorize,e.tComplete)) >= 1000  -- authorize or complete are not within 1 second of assign time
	 where not exists (select null from SQLA_EventDetails as d WITH (NOLOCK) where e.PktNum = d.PktNum and d.SourceTable = 'EVENT1_ST')
	   and (e.tOut is not NULL and isdate(e.tOut) = 1 and e.tOut > '1/2/1980')
	   and (e.tComplete is not NULL and isdate(e.tComplete)=1 and e.tComplete >= e.tOut)
	   and ((e.tAuthorize is not null and isdate(e.tAuthorize)=1 and e.tAuthorize > '1/2/1980') or (e.tAuthorize is null))
	   and (    (@FeedType <> 'MGAM')
	         or (@FeedType = 'MGAM' and (    (EventDisplay not in ('PROG JP','TILT'))
	                                      or (EventDisplay = 'PROG JP' and @ProcessProgJP = 1)
			                              or (EventDisplay = 'TILT' and @ProcessTilt = 1))))
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

