USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDistanceDetail]    Script Date: 06/21/2016 11:24:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDistanceDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDistanceDetail]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDistanceDetail]
	@StartDt datetime,
	@EndDt datetime,
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0,
	@MinRspSecs int = 0,
	@Distance int = -1,
	@EmpComplete varchar(255) = '',
	@Mode nvarchar(20) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    
	-- CREATE TABLE OF EventDetails data
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
		
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt, @EndDt = @EndDt, @ZoneArea = @ZoneArea, @CustTier = @CustTier, @EmpCmpJobType = @EmpJobType, @EventType = @EventType, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD, @MinRspSecs = @MinRspSecs, @EmpComplete = @EmpComplete 
    
    

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



	select t.*,
		   ThresholdSecsMin = b.BinMin,
		   ThresholdSecsMax = b.BinMax,
		   ThresholdDescr = b.BinDisplay,
		   ThresholdOrder = b.BinID
	  from (
	select e.PktNum, e.EventDisplay, e.CustTierLevel, e.EmpRespond,
	       Distance = ISNULL(a.Priority,0),
	       ToArea = ltrim(rtrim(e.Zone)),
		   FromArea = case when e.FromZone is not null and e.FromZone <> '' then ltrim(rtrim(e.FromZone)) else ltrim(rtrim(e.Zone)) end,
		   tTravel = case when e.tAuthorize is null then -1 when e.tAuthorize <= e.tAcpInit then 0 else DATEDIFF(second,e.tAcpInit,e.tAuthorize) end
	  from dbo.#RTA_EventDetails_Tmp as e
	  left join SQLA_AreaAssoc as a
		on a.Area = e.FromZone
	   and a.AssocArea = e.Zone
	   and (a.Mode = @Mode or @Mode = '')
	 where (@Distance = -1 or (@Distance = 0 and a.Priority is null) or (a.Priority is not null and a.Priority = @Distance)) ) as t
	 inner join #RTA_FreqDist_Bins as b
	    on (b.BinMin <= t.tTravel)
	   and (b.BinMax >  t.tTravel or b.BinMax = 0)
	 
END



GO

