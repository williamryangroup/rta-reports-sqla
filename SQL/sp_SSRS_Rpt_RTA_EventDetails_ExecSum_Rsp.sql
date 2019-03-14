USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]    Script Date: 06/27/2016 12:48:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Rsp]
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@EventType varchar(2000) = '',
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@CustNum varchar(40) = '',
	@MinRspMins int = 0,
	@MinCmpMins int = 0,
	@MinOverallMins int = 0,
	@ResDesc int = 0,
	@RspCmp int = 0,
	@EmpCmpJobType varchar(2000) = '',
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0

WITH RECOMPILE
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
	DECLARE @CustNum1 varchar(40) = @CustNum
	DECLARE @MinRspMins1 int = @MinRspMins
	DECLARE @MinCmpMins1 int = @MinCmpMins
	DECLARE @MinOverallMins1 int = @MinOverallMins
	DECLARE @ResDesc1 int = @ResDesc
	DECLARE @EmpCmpJobType1 varchar(2000) = @EmpCmpJobType
	
	DECLARE @ZonesAreNumeric char(255) = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZonesAreNumeric'),'0')
	
	
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
	
	-- CREATE TABLE OF FreqDist_Bins_Jp
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_FreqDist_Bins_JP'))
    BEGIN
		drop table dbo.#RTA_FreqDist_Bins_JP;
    END    
    
    create table #RTA_FreqDist_Bins_JP (
		BinID int NOT NULL PRIMARY KEY,
		BinDisplay nvarchar(18),
		BinMin int,
		BinMax int
    )
    
	IF @RspCmp = 0
	BEGIN
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (0, '0-:30', 0, 30)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (1, ':30-1:00', 30, 60)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (2, '1:00-2:00', 60, 120)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (3, '2:00-3:00', 120, 180)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (4, '3:00-5:00', 180, 300)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (5, '5:00-10:00', 300, 600)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (6, '>= 10:00', 600, 0)
		
		insert into #RTA_FreqDist_Bins_JP (BinID, BinDisplay, BinMin, BinMax) values (0, '$0-$1,199.99', 0, 1200)
		insert into #RTA_FreqDist_Bins_JP (BinID, BinDisplay, BinMin, BinMax) values (1, '$1,200-$4,999.99', 1200, 5000)
		insert into #RTA_FreqDist_Bins_JP (BinID, BinDisplay, BinMin, BinMax) values (2, '$5,000-$9,999.99', 5000, 10000)
		insert into #RTA_FreqDist_Bins_JP (BinID, BinDisplay, BinMin, BinMax) values (3, '$10,000-$24,999.99', 10000, 25000)
		insert into #RTA_FreqDist_Bins_JP (BinID, BinDisplay, BinMin, BinMax) values (4, '>= $25,000', 25000, 0)
    END
	
	IF @RspCmp = 1
	BEGIN
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (0, '0-1:00', 0, 60)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (1, '1:00-2:00', 60, 120)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (2, '2:00-3:00', 120, 180)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (3, '3:00-5:00', 180, 300)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (4, '5:00-8:00', 300, 480)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (5, '8:00-10:00', 480, 600)
		insert into #RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (6, '>= 10:00', 600, 0)
    END
	
    	
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_Tmp'))
    BEGIN
		drop table dbo.#RTA_EventDetails_Tmp;
    END
	
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
	
	
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt1, @EndDt = @EndDt1, @MaxCmpMins = @MaxCmpMins1, @EventType = @EventType1, @ZoneArea = @ZoneArea1, @CustTier = @CustTier1, @CustNum = @CustNum1, @MinRspMins = @MinRspMins1, @MinCmpMins = @MinCmpMins1, @MinOverallMins = @MinOverallMins1, @ResDesc = @ResDesc1, @EmpCmpJobType = @EmpCmpJobType1, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD

	ALTER TABLE dbo.#RTA_EventDetails_Tmp ADD JpAmt float null
	
	UPDATE dbo.#RTA_EventDetails_Tmp SET JpAmt = 0.0
	
	UPDATE dbo.#RTA_EventDetails_Tmp SET JpAmt = right(EventDisplay,LEN(EventDisplay)-3) WHERE (EventDisplay like 'JP %' or EventDisplay like 'PJ %') and EventDisplay not like 'JP VER%' and EventDisplay not like 'JP RES%' and EventDisplay not like 'JP TECH%' and LEN(EventDisplay)-3 > 0
	UPDATE dbo.#RTA_EventDetails_Tmp SET JpAmt = right(EventDisplay,LEN(EventDisplay)-5) WHERE (EventDisplay like 'JKPT %' or EventDisplay like 'PROG %') and EventDisplay not like 'PROG JP%' and LEN(EventDisplay)-5 > 0
	UPDATE dbo.#RTA_EventDetails_Tmp SET JpAmt = right(EventDisplay,LEN(EventDisplay)-8) WHERE (EventDisplay like 'PROG JP %') and LEN(EventDisplay)-8 > 0
	
	
	-- CREATE TABLE OF RTA_EventDetails_Sum_Tmp
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_Sum_Tmp'))
    BEGIN
		drop table dbo.#RTA_EventDetails_Sum_Tmp;
    END    
    
    create table dbo.#RTA_EventDetails_Sum_Tmp (
		CustTierLevel varchar(255),
		ZoneOrder int,
		Zone varchar(255),
		ShiftColumn int,
		ShiftName varchar(50),
		ThresholdSecsMin int,
		ThresholdSecsMax int,
		ThresholdDescr varchar(255),
		ThresholdOrder int,
		EventCount int,
		HasThreshold varchar(1),
		JpAmtBinDesc varchar(255),
		JpAmtBinOrder int
    )
    
    IF (@RspCmp = 0)
	BEGIN
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, ZoneOrder = case when @ZonesAreNumeric = 1 then cast(e.Zone as int) else 0 end, e.Zone, s.ShiftColumn, s.ShiftName,
			   ThresholdSecsMin = b.BinMin,
			   ThresholdSecsMax = b.BinMax,
			   ThresholdDescr = b.BinDisplay,
			   ThresholdOrder = b.BinID,
			   EventCount = COUNT(*),
			   HasThreshold = 'N',
			   JpAmtBinDesc = bj.BinDisplay,
			   JpAmtBinOrder = bj.BinID
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join #RTA_FreqDist_Bins as b
			on (b.BinMin <= e.RspSecs)
		   and (b.BinMax >  e.RspSecs or b.BinMax = 0)
		  left join #RTA_FreqDist_Bins_JP as bj
			on (bj.BinMin <= e.JpAmt)
		   and (bj.BinMax >  e.JpAmt or bj.BinMax = 0)
		  left join SQLA_ShiftHours as s
			on s.StartHour = datepart(hour,e.tOut)
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, e.Zone, s.ShiftColumn, s.ShiftName, b.BinMin, b.BinMax, b.BinDisplay, b.BinID, bj.BinDisplay, bj.BinID
	END
	
	
	IF (@RspCmp = 1)
	BEGIN
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, ZoneOrder = case when @ZonesAreNumeric = 1 then cast(e.Zone as int) else 0 end, e.Zone, s.ShiftColumn, s.ShiftName,
			   ThresholdSecsMin = b.BinMin,
			   ThresholdSecsMax = b.BinMax,
			   ThresholdDescr = b.BinDisplay,
			   ThresholdOrder = b.BinID,
			   EventCount = COUNT(*),
			   HasThreshold = 'N',
			   JpAmtBinDesc = bj.BinDisplay,
			   JpAmtBinOrder = bj.BinID
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join #RTA_FreqDist_Bins as b
			on (b.BinMin <= e.CmpSecs)
		   and (b.BinMax >  e.CmpSecs or b.BinMax = 0)
		  left join #RTA_FreqDist_Bins_JP as bj
			on (bj.BinMin <= e.JpAmt)
		   and (bj.BinMax >  e.JpAmt or bj.BinMax = 0)
		  left join SQLA_ShiftHours as s
			on s.StartHour = datepart(hour,e.tOut)
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, e.Zone, s.ShiftColumn, s.ShiftName, b.BinMin, b.BinMax, b.BinDisplay, b.BinID, bj.BinDisplay, bj.BinID
	END       
	       
	
	select s1.CustTierLevel, s1.ZoneOrder, s1.Zone, s1.ShiftColumn, s1.ShiftName, s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, EventCount = s1.EventCount,
	       PctTotal = s1.EventCount*1.0 / SUM(s2.EventCount)*1.0, s1.HasThreshold, c.PriorityLevel, s1.JpAmtBinDesc, s1.JpAmtBinOrder
	  from dbo.#RTA_EventDetails_Sum_Tmp as s1
	 inner join dbo.#RTA_EventDetails_Sum_Tmp as s2
	    on s1.CustTierLevel = s2.CustTierLevel
	   and s1.Zone = s2.Zone
	   and s1.ShiftColumn = s2.ShiftColumn
	   and s1.ShiftName = s2.ShiftName
	  left join SQLA_CustTiers as c
	    on c.TierLevel = s1.CustTierLevel
	 group by s1.CustTierLevel, s1.ZoneOrder, s1.Zone, s1.ShiftColumn, s1.ShiftName, s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, s1.EventCount, s1.HasThreshold, c.PriorityLevel, s1.JpAmtBinDesc, s1.JpAmtBinOrder
	 union all
	select 'ALL', 0, '0', -1, 'ALL', s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, EventCount = sum(s1.EventCount), 
	       PctTotal = 1.0, s1.HasThreshold, -1, 'ALL', 0
	  from dbo.#RTA_EventDetails_Sum_Tmp as s1
	 group by s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, s1.HasThreshold
	
END






GO

