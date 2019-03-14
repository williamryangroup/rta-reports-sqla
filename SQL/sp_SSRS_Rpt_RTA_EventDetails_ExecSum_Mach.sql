USE [RTSS]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Mach]    Script Date: 02/19/2016 13:34:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Mach]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Mach]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Mach]
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@EventType varchar(2000) = '',
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@CustNum varchar(10) = '',
	@MinRspMins int = 0,
	@MinCmpMins int = 0,
	@MinOverallMins int = 0,
	@ResDesc int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @MaxCmpMins1 int = @MaxCmpMins
	DECLARE @EventType1 varchar(2000) = @EventType
	DECLARE @ZoneArea1 varchar(255) = @ZoneArea
	DECLARE @CustTier1 varchar(255) = @CustTier
	DECLARE @CustNum1 varchar(10) = @CustNum
	DECLARE @MinRspMins1 int = @MinRspMins
	DECLARE @MinCmpMins1 int = @MinCmpMins
	DECLARE @MinOverallMins1 int = @MinOverallMins
	DECLARE @ResDesc1 int = @ResDesc
	
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
		Asset varchar(255),
		CustPriorityLevel varchar(255),
		CompVarianceReason varchar(50),
		AsnSecs int,
		ReaSecs int,
		AcpSecs int,
		RejSecs int
	)
		
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt1, @EndDt1, @MaxCmpMins1, @EventType1, @ZoneArea1, @CustTier1, @CustNum1, @MinRspMins1, @MinCmpMins1, @MinOverallMins1, @ResDesc1
	DECLARE @ZoneOtherTitle varchar(50) = (select Setting from dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZoneOtherTitle')
	
	select Zone = ltrim(rtrim(e.Zone)), e.Location, EventDate = cast(e.tOut as date), e.EventDisplay,
		   EventCount = COUNT(*),
		   HourType = 'Open event',
		   Hours = sum(case when e.tComplete > @EndDt1 then DATEDIFF(second,e.tOut,@EndDt1)
		                    else DATEDIFF(second,e.tOut,e.tComplete) end)*1.0/3600.0
	  from dbo.#RTA_EventDetails_Tmp as e
	 where e.Location <> @ZoneOtherTitle
	   and e.Zone <> '00' and e.ResolutionDesc <> 'No Event'
	 group by ltrim(rtrim(e.Zone)), e.Location, cast(e.tOut as date), e.EventDisplay
	 union all
	select Zone = ltrim(rtrim(e.Zone)), e.Location, EventDate = cast(e.tOut as date), EventDisplay = 'No event',
		   EventCount = 0,
		   HourType = 'No open event',
		   Hours = 24.0 - (sum(case when e.tComplete > @EndDt1 then DATEDIFF(second,e.tOut,@EndDt1)
		                            else DATEDIFF(second,e.tOut,e.tComplete) end)*1.0/3600.0)
	  from dbo.#RTA_EventDetails_Tmp as e
	 where e.Location <> @ZoneOtherTitle
	   and e.Zone <> '00' and e.ResolutionDesc <> 'No Event'
	 group by ltrim(rtrim(e.Zone)), e.Location, cast(e.tOut as date)
	 
END




GO

