USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDistance]    Script Date: 06/21/2016 11:24:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDistance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDistance]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDistance]
	@StartDt datetime,
	@EndDt datetime,
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0,
	@MinRspSecs int = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    
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
		
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt, @EndDt = @EndDt, @ZoneArea = @ZoneArea, @CustTier = @CustTier, @EmpCmpJobType = @EmpJobType, @EventType = @EventType, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD, @MinRspSecs = @MinRspSecs
    
    
    
	select Distance = ISNULL(a.Priority,0), ToArea = ltrim(rtrim(e.Zone)), FromArea = case when e.FromZone is not null and e.FromZone <> '' then ltrim(rtrim(e.FromZone)) else ltrim(rtrim(e.Zone)) end,
	       EventCount = COUNT(*),
	       SupervisorAssign = SUM(case when (e.EmpCmpJobType in ('Supervisor','Manager')) and (e.EmpCmpAsnTaken = 'Asn') then 1 else 0 end),
	       Reassign = SUM(e.Reassign),
	       ReassignSupervisor = SUM(e.ReassignSupervisor),
	       AttendantAssign = SUM(case when (e.EmpCmpJobType = 'Attendant') and (e.EmpCmpAsnTaken = 'Asn') then 1 else 0 end),
	       AttendantTake = SUM(case when (e.EmpCmpJobType = 'Attendant') and (e.EmpCmpAsnTaken = 'Take') then 1 else 0 end),
	       SupervisorTake = SUM(case when (e.EmpCmpJobType in ('Supervisor','Manager')) and (e.EmpCmpAsnTaken = 'Take') then 1 else 0 end),
	       EmpComplete
	  from dbo.#RTA_EventDetails_Tmp as e
	  left join SQLA_AreaAssoc as a
		on a.Area = e.FromZone
	   and a.AssocArea = e.Zone
	 group by a.Priority, e.Zone, e.FromZone, EmpComplete
	 
END



GO

