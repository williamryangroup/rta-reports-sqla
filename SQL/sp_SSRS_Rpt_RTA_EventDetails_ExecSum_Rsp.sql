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
		AsnSecs int,
		ReaSecs int,
		AcpSecs int,
		RejSecs int
	)
	
	
	INSERT INTO dbo.#RTA_EventDetails_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_EventDetails @StartDt = @StartDt1, @EndDt = @EndDt1, @MaxCmpMins = @MaxCmpMins1, @EventType = @EventType1, @ZoneArea = @ZoneArea1, @CustTier = @CustTier1, @CustNum = @CustNum1, @MinRspMins = @MinRspMins1, @MinCmpMins = @MinCmpMins1, @MinOverallMins = @MinOverallMins1, @ResDesc = @ResDesc1, @EmpCmpJobType = @EmpCmpJobType1, @IncludeOOS = @IncludeOOS, @IncludeEMPCARD = @IncludeEMPCARD

	
	-- CREATE TABLE OF RTA_EventDetails_Sum_Tmp
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_Sum_Tmp'))
    BEGIN
		drop table dbo.#RTA_EventDetails_Sum_Tmp;
    END    
    
    create table dbo.#RTA_EventDetails_Sum_Tmp (
		CustTierLevel varchar(255),
		ThresholdSecsMin int,
		ThresholdSecsMax int,
		ThresholdDescr varchar(255),
		ThresholdOrder int,
		EventCount int,
		HasThreshold varchar(1)
    )
    
    IF (@RspCmp = 0)
	BEGIN
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = b.BinMin,
			   ThresholdSecsMax = b.BinMax,
			   ThresholdDescr = b.BinDisplay,
			   ThresholdOrder = b.BinID,
			   EventCount = COUNT(*),
			   HasThreshold = 'N'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join #RTA_FreqDist_Bins as b
			on (b.BinMin <= e.RspSecs)
		   and (b.BinMax >  e.RspSecs or b.BinMax = 0)
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, b.BinMin, b.BinMax, b.BinDisplay, b.BinID
		       
		/*
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = case when e.RspSecs <  t.ThresholdSecs then 0
									   when e.RspSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   ThresholdSecsMax = case when e.RspSecs <  t.ThresholdSecs then t.ThresholdSecs
									   when e.RspSecs >= t.ThresholdSecs then 0 end,
			   ThresholdDescr = case when e.RspSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
									 when e.RspSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   ThresholdOrder = case when e.RspSecs <  t.ThresholdSecs then 0
									 when e.RspSecs >= t.ThresholdSecs then 1 end,
			   EventCount = COUNT(*),
			   HasThreshold = 'Y'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join (select l.TierLevel, 
							ThresholdSecs = (cast(left(s.Setting,(LEN(s.Setting)-6)) as int) * 60 * 60)
										  + (cast(right(left(s.Setting,(LEN(s.Setting)-3)),2) as int) * 60)
										  + cast(right(s.Setting,2) as int)
					   from RTSS.dbo.SYSTEMSETTINGS as s
					  inner join (select distinct TierLevel from dbo.SQLA_CustTiers) as l
						 on cast(l.TierLevel as varchar) + cast('.RED' as varchar) = s.ConfigParam
					  where s.ConfigSection = 'TimeParams'
					    and Setting is not null and Setting <> '') as t
			on t.TierLevel = isnull(e.CustTierLevel,'')
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, 
			   case when e.RspSecs <  t.ThresholdSecs then 0
					when e.RspSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   case when e.RspSecs <  t.ThresholdSecs then t.ThresholdSecs
					when e.RspSecs >= t.ThresholdSecs then 0 end,
			   case when e.RspSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
					when e.RspSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   case when e.RspSecs <  t.ThresholdSecs then 0
					when e.RspSecs >= t.ThresholdSecs then 1 end
		*/
	END
	
	
	IF (@RspCmp = 1)
	BEGIN
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = b.BinMin,
			   ThresholdSecsMax = b.BinMax,
			   ThresholdDescr = b.BinDisplay,
			   ThresholdOrder = b.BinID,
			   EventCount = COUNT(*),
			   HasThreshold = 'N'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join #RTA_FreqDist_Bins as b
			on (b.BinMin <= e.CmpSecs)
		   and (b.BinMax >  e.CmpSecs or b.BinMax = 0)
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, b.BinMin, b.BinMax, b.BinDisplay, b.BinID
		       
		/*
		insert into dbo.#RTA_EventDetails_Sum_Tmp
		select e.CustTierLevel, 
			   ThresholdSecsMin = case when e.CmpSecs <  t.ThresholdSecs then 0
									   when e.CmpSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   ThresholdSecsMax = case when e.CmpSecs <  t.ThresholdSecs then t.ThresholdSecs
									   when e.CmpSecs >= t.ThresholdSecs then 0 end,
			   ThresholdDescr = case when e.CmpSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
									 when e.CmpSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   ThresholdOrder = case when e.CmpSecs <  t.ThresholdSecs then 0
									 when e.CmpSecs >= t.ThresholdSecs then 1 end,
			   EventCount = COUNT(*),
			   HasThreshold = 'Y'
		  from dbo.#RTA_EventDetails_Tmp as e
		 inner join (select l.TierLevel, 
							ThresholdSecs = (cast(left(s.Setting,(LEN(s.Setting)-6)) as int) * 60 * 60)
										  + (cast(right(left(s.Setting,(LEN(s.Setting)-3)),2) as int) * 60)
										  + cast(right(s.Setting,2) as int)
					   from RTSS.dbo.SYSTEMSETTINGS as s
					  inner join (select distinct TierLevel from dbo.SQLA_CustTiers) as l
						 on cast(l.TierLevel as varchar) + cast('.RED' as varchar) = s.ConfigParam
					  where s.ConfigSection = 'TimeParams'
					    and Setting is not null and Setting <> '') as t
			on t.TierLevel = isnull(e.CustTierLevel,'')
		 where e.tAuthorize is not null and e.tAuthorize >= e.tOut
		 group by e.CustTierLevel, 
			   case when e.CmpSecs <  t.ThresholdSecs then 0
					when e.CmpSecs >= t.ThresholdSecs then t.ThresholdSecs end,
			   case when e.CmpSecs <  t.ThresholdSecs then t.ThresholdSecs
					when e.CmpSecs >= t.ThresholdSecs then 0 end,
			   case when e.CmpSecs <  t.ThresholdSecs then cast('< ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar)
					when e.CmpSecs >= t.ThresholdSecs then cast('>= ' as varchar) + cast(t.ThresholdSecs as varchar) + cast(' secs' as varchar) end,
			   case when e.CmpSecs <  t.ThresholdSecs then 0
					when e.CmpSecs >= t.ThresholdSecs then 1 end
		*/
	END       
	       
	
	select s1.CustTierLevel, s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, EventCount = s1.EventCount,
	       PctTotal = s1.EventCount*1.0 / SUM(s2.EventCount)*1.0, s1.HasThreshold, c.PriorityLevel
	  from dbo.#RTA_EventDetails_Sum_Tmp as s1
	 inner join dbo.#RTA_EventDetails_Sum_Tmp as s2
	    on s1.CustTierLevel = s2.CustTierLevel
	  left join SQLA_CustTiers as c
	    on c.TierLevel = s1.CustTierLevel
	 group by s1.CustTierLevel, s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, s1.EventCount, s1.HasThreshold, c.PriorityLevel
	 union all
	select 'ALL', s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, EventCount = sum(s1.EventCount), 
	       PctTotal = 1.0, s1.HasThreshold, -1
	  from dbo.#RTA_EventDetails_Sum_Tmp as s1
	 group by s1.ThresholdSecsMin, s1.ThresholdSecsMax, s1.ThresholdDescr, s1.ThresholdOrder, s1.HasThreshold
	
END






GO

