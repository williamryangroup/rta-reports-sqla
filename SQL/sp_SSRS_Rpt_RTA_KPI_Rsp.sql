USE [RTA_SQLA]
GO
/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_KPI_Rsp]    Script Date: 4/3/2017 11:49:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_KPI_Rsp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_KPI_Rsp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_KPI_Rsp]
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0,
	@RspMins int = 2,
	@TopTiers int = 0,
	@AsnSecs int = 10,
	@TrvSecs int = 60

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @MaxCmpMins1 int = @MaxCmpMins
	DECLARE @IncludeOOS1 int = @IncludeOOS
	DECLARE @IncludeEMPCARD1 int = @IncludeEMPCARD
	DECLARE @RspMins1 int = @RspMins
	DECLARE @AsnSecs1 int = @AsnSecs
	DECLARE @TrvSecs1 int = @TrvSecs
	

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
		
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt1, @EndDt = @EndDt1, @MaxCmpMins = @MaxCmpMins1, @IncludeOOS = @IncludeOOS1, @IncludeEMPCARD = @IncludeEMPCARD1
	

	CREATE TABLE #TmpHours (
		tHour int
	)

	DECLARE @NumHours int = datediff(hour, @StartDt, @EndDt)

	INSERT INTO #TmpHours (tHour)
	SELECT distinct tOutHour = datepart(hour,d.tOut)
	  FROM dbo.#RTA_EventDetails_Tmp as d
	 WHERE d.RspSecs > -1


	SELECT s.ShiftName, ShiftOrder = s.ShiftColumn, tOutHour = h.tHour, EvtCnt = count(distinct d.PktNum),
	       AsnCnt = count(distinct case when (d.AsnSecs) < (@AsnSecs1) then d.PktNum else null end),
		   TrvCnt = count(distinct case when (d.RspSecs-d.AcpSecs) < (@TrvSecs1) then d.PktNum else null end),
	       RspCnt = count(distinct case when (d.RspSecs) < (@RspMins1*60.0) then d.PktNum else null end),
		   AttCnt = count(distinct case when ae.JobType = 'Attendant' then ae.EmpNum else null end),
		   SupCnt = count(distinct case when ae.JobType = 'Supervisor' then ae.EmpNum else null end)
	  FROM #TmpHours as h
	  LEFT JOIN dbo.#RTA_EventDetails_Tmp as d
	    ON h.tHour = datepart(hour,d.tOut)
	   AND d.RspSecs > -1 AND (@TopTiers = 0 or (@TopTiers = 1 and d.CustTierLevel in ('DIA','SEV')))
	  LEFT JOIN SQLA_ShiftHours as s
	    ON s.StartHour = h.tHour
	  LEFT JOIN SQLA_EmployeeStatus as ae
	    ON ae.tStart < d.tComplete AND ae.tEnd > d.tOut and ae.Status = 'Login'
	 GROUP BY s.ShiftName, s.ShiftColumn, h.tHour

END

GO
