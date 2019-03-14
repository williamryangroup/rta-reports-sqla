USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]    Script Date: 07/21/2016 12:17:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp2]
	@StartDt datetime,
	@EndDt datetime,
	@UtilType int = 0,
	@EmpJobType nvarchar(2000) = '',
	@EventSum int = 0,
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1,
	@UseQuartile int = 0,
	@RspAnalysis int = 0,
	@SeriesGrp int = 0

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp2 (
		EmpNum nvarchar(255),
		EmpName nvarchar(255),
		EmpJobType nvarchar(255),
		PktNum int,
		EventDisplay nvarchar(255),
		StatOrd int,
		Stat nvarchar(255),
		StatStart datetime,
		StatEnd datetime,
		StatSecs int
	)
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 (
		EmpNum nvarchar(255),
		MinActivityStart datetime,
		MaxActivityEnd datetime,
		StatSecs int
	)
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 (
		EmpNum nvarchar(255),
		StatSecs int
	)
	
	
	-- CREATE TABLE OF JobTypes
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_ExecSum_Emp2_JobTypes'))
    BEGIN
		drop table dbo.#RTA_EventDetails_ExecSum_Emp2_JobTypes;
    END    
    
    create table #RTA_EventDetails_ExecSum_Emp2_JobTypes (
		JobType nvarchar(20) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_EventDetails_ExecSum_Emp2_JobTypes (JobType)
    select distinct left(ltrim(rtrim(val)),20) from dbo.fn_String_To_Table(@EmpJobType, ',', 1)
	
	
	-- AVAILABLE
	insert into #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 (EmpNum,MinActivityStart,MaxActivityEnd,StatSecs)
	select EmpNum, 
	       MinActivityStart = min(ActivityStart),
		   MaxActivityEnd = max(ActivityEnd),
	       StatSecs = sum(case when ActivityEnd > @EndDt and ActivityStart < @StartDt then datediff(second,@StartDt,@EndDt)
                               when ActivityEnd < @EndDt and ActivityStart < @StartDt then datediff(second,@StartDt,ActivityEnd)
                               when ActivityEnd > @EndDt and ActivityStart > @StartDt then datediff(second,ActivityStart,@EndDt)
                               else datediff(second,ActivityStart,ActivityEnd) end)
	  from SQLA_EmployeeEventTimes
	 where PktNum = 3 and ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and (EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	 group by EmpNum
	   
	
	-- Stat Ords
	--   1 = Break
	--   2 = OOS
	--   3 = Available
	--   4 = OpnToAsn
	--   5 = AsnToAcp / AsnToRej
	--   6 = AcpToRsp
	--   7 = AsnRspToNotCmp
	--   8 = AsnRspToCmp
	--   9 = TknToNotCmp
	--  10 = TknToCmp
	--  11 = JP Ver
	
	
	-- EVENT OpnToAsn
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select EmpNum = '', EmpName = '', EmpJobType = '', et.PktNum, et.EventDisplay, 
	       StatOrd = 4, Stat = 'OpnToAsn', StatStart = ed.tOut, StatEnd = min(isnull(isnull(et.tAsn,et.tRea),et.tRsp))
	  from SQLA_EmployeeEventTimes as et
	 inner join SQLA_EventDetails as ed
	    on ed.PktNum = et.PktNum
	 where ed.tOut >= @StartDt and ed.tOut < @EndDt and (et.tAsn is not null or et.tRea is not null or et.tRsp is not null) and @UtilType = 1
	   and ((@IncludeEMPCARD = 0 and et.EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and ed.tOut <= isnull(isnull(et.tAsn,et.tRea),et.tRsp)
	 group by et.PktNum, et.EventDisplay, ed.tOut
	 
	 
	-- ASSIGNED EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 5, Stat = 'AsnToAcp', StatStart = isnull(tAsn,tRea), StatEnd = isnull(isnull(isnull(tAcp,tRsp),tCmp),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRej is null and isnull(tAsn,tRea) < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 5, Stat = 'AsnToRej', StatStart = isnull(tAsn,tRea), StatEnd = tRej
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRej is not null and isnull(tAsn,tRea) < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 6, Stat = 'AcpToRsp', StatStart = tAcp, StatEnd = isnull(isnull(isnull(tRsp,tCmp),tRej),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tAcp is not null and tAcp < @EndDt and (tRsp is not null or tCmp is not null)

	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 61, Stat = 'AcpToRej', StatStart = tAcp, StatEnd = isnull(isnull(isnull(tRsp,tCmp),tRej),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tAcp is not null and tAcp < @EndDt and tRsp is null and tCmp is null
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 7, Stat = 'AsnRspToNotCmp', StatStart = tRsp, StatEnd = isnull(tRej,ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRsp is not null and tCmp is null and tRsp < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 8, Stat = 'AsnRspToCmp', StatStart = tRsp, StatEnd = tCmp
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRsp is not null and tCmp is not null and tRsp < @EndDt
	   
	   
	-- TAKEN EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 9, Stat = 'TknToNotCmp', StatStart = tRsp, StatEnd = isnull(tRej,ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	  left join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt 
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and tRsp is not null and tRsp < @EndDt
	   and ((tAsn is null and tRea is null) or (tAsn is not null and DATEDIFF(SECOND,tAsn,tRsp) <= 1))
	   and tCmp is null
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 10, Stat = 'TknToCmp', StatStart = tRsp, StatEnd = tCmp
	  from SQLA_EmployeeEventTimes as et
	  left join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   and tRsp is not null and tRsp < @EndDt
	   and ((tAsn is null and tRea is null) or (tAsn is not null and DATEDIFF(SECOND,tAsn,tRsp) <= 1))
	   and tCmp is not null
	   and EventDisplay not like 'JKPT%' and EventDisplay not in ('JP VER')
	   
	   
	-- JP VER EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
		   StatOrd = 11, Stat = EventDisplay, StatStart = tOut, StatEnd = tComplete
	  from SQLA_EventDetails_JPVER as et
	  left join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
		on a.EmpNum = et.EmpNum
	   and tOut >= MinActivityStart and tComplete <= MaxActivityEnd
	 where tOut < @EndDt and tComplete > @StartDt
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
	   
	   
	-- OOS / BREAK
	IF (@UtilType = 0 and @SeriesGrp <> 0)
	BEGIN
		insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
		select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
			   StatOrd = case when PktNum = 1 then 1 -- Break
							  when PktNum = 2 then 2 -- OOS
							  end,
			   Stat = EventDisplay, StatStart = ActivityStart, StatEnd = ActivityEnd
		  from SQLA_EmployeeEventTimes as et
		 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
			on a.EmpNum = et.EmpNum
		 where ActivityStart < @EndDt and ActivityEnd > @StartDt
		   and PktNum in (1,2) and ActivityStart >= @StartDt and ActivityStart < @EndDt
		   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '' or @EmpJobType = 'All')
		   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
		   and ((@IncludeOOS = 0 and PktNum not in (2)) or (@IncludeOOS = 1))
	END
	
	
	-- UPDATE StatSecs
	delete from #RTA_EventDetails_ExecSum_Emp2_Tmp2
	 where StatEnd < @StartDt
	
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatStart = @StartDt
	 where StatStart < @StartDt
	 
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatEnd = @EndDt
	 where StatEnd > @EndDt
	   
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatSecs = datediff(second,StatStart,StatEnd)

	
	
	IF (@UtilType = 0 and @SeriesGrp <> 0)
	BEGIN
		-- TOTAL OTHER
		insert into #RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 (EmpNum,StatSecs)
		select EmpNum, StatSecs = sum(isnull(StatSecs,0))
		  from #RTA_EventDetails_ExecSum_Emp2_Tmp2
		 group by EmpNum
	
		-- INSERT AVAILABLE
		insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatSecs,StatStart,StatEnd)
		select a.EmpNum, EmpName = '', EmpJobType = '', PktNum = 3, EventDisplay = 'Available', StatOrd = 3, Stat = 'Available', 
			   StatSecs = a.StatSecs - isnull(o.StatSecs,0), 
			   MinActivityStart = case when MinActivityStart < @StartDt then @StartDt else MinActivityStart end, 
			   MaxActivityEnd = case when MaxActivityEnd > @EndDt then @EndDt else MaxActivityEnd end
		  from #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
		  left join #RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 as o
			on a.EmpNum = o.EmpNum
	END
	
	
	-- RETURN table
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3 (
		EmpNum nvarchar(255),
		EmpName nvarchar(255),
		EmpJobType nvarchar(255),
		PktNum int,
		EventDisplay nvarchar(255),
		StatOrd int,
		Stat nvarchar(255),
		StatSecs int,
		StatStart datetime,
		StatEnd datetime
	)
	
	
	insert into dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3 (EmpNum, EmpName, EmpJobType, PktNum, EventDisplay, StatOrd, Stat, StatSecs, StatStart, StatEnd)
	select u.EmpNum,
	       EmpName = case when isnull(u.EmpName,'') = '' and isnull(e.NameFirst,'') <> '' then e.NameFirst + ' ' + left(e.NameLast,1)
	                      when isnull(u.EmpName,'') = '' and isnull(e.NameFirst,'') = '' then u.EmpNum
						  else u.EmpName end,
	       EmpJobType = case when isnull(u.EmpJobType,'') = '' then e.JobType else u.EmpJobType end, 
		   u.PktNum, 
		   EventDisplay = case when u.EventDisplay like 'JKPT%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) < 1200 then 'JKPT<1200'
	                           when u.EventDisplay like 'JKPT%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) >= 1200 then 'JKPT>=1200'
							   when u.EventDisplay like 'JP%' and u.EventDisplay <> 'JP VER' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) < 1200 then 'JKPT<1200'
	                           when u.EventDisplay like 'JP%' and u.EventDisplay <> 'JP VER' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) >= 1200 then 'JKPT>=1200'
							   when u.EventDisplay like 'PROG%' or u.EventDisplay like 'PJ%' then 'PROG'
							   when u.EventDisplay like 'PJ%' then 'PJ'
							   when u.EventDisplay like 'EMPCARD%' then 'EMPCARD'
							   when u.EventDisplay like 'REEL%' then 'REEL'
							   when u.EventDisplay like 'OOS%' then 'OOS'
							   else u.EventDisplay end,
	       StatOrd = case when u.StatOrd = 61 then 6 else u.StatOrd end,
		   Stat = case when @EventSum = 1 and u.StatOrd not in (3,4,1,2) then 'EVENT'
                       when @EventSum = 2 then case when u.StatOrd = 4 then 'Asn'  --OpnToAsn
					                                when u.StatOrd = 5 then 'Acp'  --AsnToAcp/Rej
											        when u.StatOrd = 6 then 'Rsp'  --AcpToRsp
													when u.StatOrd = 61 then 'Rsp'  --AcpToRej
											        when u.StatOrd = 7 then 'Cmp'  --AsnRspToNotCmp
											        when u.StatOrd = 8 then 'Cmp'  --AsnRspToCmp
											        when u.StatOrd = 9 then 'Cmp'  --TknToNotCmp
											        when u.StatOrd = 10 then 'Cmp' --TknToCmp
													when u.StatOrd = 11 then 'Cmp' --JP VER
											        else u.Stat end
					   else case when u.StatOrd = 2 then 'OOS'
					             else u.Stat end end, 
		   u.StatSecs,
		   u.StatStart,
		   u.StatEnd
	  from #RTA_EventDetails_ExecSum_Emp2_Tmp2 as u
	  left join SQLA_Employees as e
	    on u.EmpNum = e.CardNum
	  left join SQLA_EventDetails as d
	    on d.PktNum = u.PktNum
	  
	
	IF (@UseQuartile <> 0 or @RspAnalysis <> 0)
	BEGIN
		DECLARE @IntervalMins int = 15
		DECLARE @Mode nvarchar(20) = isnull((select Setting from SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'AssocAreaMode'),'')
		
		IF OBJECT_ID('tempdb..#RTA_Dttm_Tmp') is not null
		BEGIN
			drop table dbo.#RTA_Dttm_Tmp;
		END 

		CREATE TABLE dbo.#RTA_Dttm_Tmp (
			DttmValue datetime
		)

		TRUNCATE TABLE dbo.#RTA_Dttm_Tmp

		INSERT INTO dbo.#RTA_Dttm_Tmp (DttmValue) VALUES (@StartDt)

		WHILE ((SELECT MAX(DttmValue) FROM dbo.#RTA_Dttm_Tmp) < @EndDt)
		BEGIN  
			INSERT INTO dbo.#RTA_Dttm_Tmp (DttmValue)
			select dateadd(minute,@IntervalMins,MAX(DttmValue)) from dbo.#RTA_Dttm_Tmp
		END 
		
		
		
		IF OBJECT_ID('tempdb..#RTA_EvtStatus_Quartiles') is not null
		BEGIN
			drop table dbo.#RTA_EvtStatus_Quartiles;
		END 

		CREATE TABLE dbo.#RTA_EvtStatus_Quartiles (
			DttmValue datetime,
			EmpNum nvarchar(255),
			EmpName nvarchar(255),
			EmpJobType nvarchar(255),
			PktNum int,
			EventDisplay nvarchar(255),
			StatOrd int,
			Stat nvarchar(255),
			StatStart datetime,
			StatEnd datetime,
			ToArea nvarchar(10),
			FromArea nvarchar(10),
			Distance int,
			CustPriorityLevel int,
			CustTierLevel nvarchar(10)
		)
				
		TRUNCATE TABLE dbo.#RTA_EvtStatus_Quartiles

		INSERT INTO dbo.#RTA_EvtStatus_Quartiles (DttmValue, EmpNum, EmpName, EmpJobType, PktNum, EventDisplay, StatOrd, Stat, StatStart, StatEnd, ToArea, FromArea, Distance, CustPriorityLevel, CustTierLevel)
		select d.DttmValue,
		       e.EmpNum,
			   e.EmpName,
			   e.EmpJobType,
			   e.PktNum,
			   e.EventDisplay,
			   e.StatOrd,
			   e.Stat,
			   StatStart = case when e.StatStart < d.DttmValue then d.DttmValue else e.StatStart end,
			   StatEnd = case when e.StatEnd > dateadd(minute,@IntervalMins,d.DttmValue) then dateadd(minute,@IntervalMins,d.DttmValue) else e.StatEnd end,
		       ToArea = ltrim(rtrim(v.Zone)),
			   FromArea = case when v.FromZone is not null and v.FromZone <> '' then ltrim(rtrim(v.FromZone)) else ltrim(rtrim(v.Zone)) end,
			   Distance = ISNULL(a.Priority,0),
			   v2.CustPriorityLevel,
			   v2.CustTierLevel
		  from dbo.#RTA_Dttm_Tmp as d
		  left join dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3 as e
			on e.StatStart < dateadd(minute,@IntervalMins,d.DttmValue)
		   and e.StatEnd >= d.DttmValue
		  left join dbo.SQLA_EventDetails as v
		    on v.PktNum = e.PktNum
		   and v.EmpNumAsn = e.EmpNum
		   and e.StatOrd in (6,61)
		  left join SQLA_AreaAssoc as a
			on a.Area = v.FromZone
		   and a.AssocArea = v.Zone
		   and (a.Mode = @Mode or @Mode = '')
		  left join dbo.SQLA_EventDetails as v2
		    on v2.PktNum = e.PktNum
		 where e.EventDisplay not in ('JP VER')
		
		IF(@UseQuartile = 1 and @RspAnalysis = 0)
		BEGIN
			select DttmValue, /*EmpNum, EmpName, EmpJobType,*/ PktNum, EventDisplay, StatOrd, Stat, /*StatStart, StatEnd,*/ StatSecs = sum(isnull(datediff(second,StatStart,StatEnd),0)), StatMins = sum(isnull(datediff(second,StatStart,StatEnd),0)*1.0/60.0)
			  from dbo.#RTA_EvtStatus_Quartiles as t
			where isnull(datediff(second,StatStart,StatEnd),0) > 0
			group by DttmValue, PktNum, EventDisplay, StatOrd, Stat
		END
		
		IF(@UseQuartile = 1 and @RspAnalysis = 1)
		BEGIN
			select *, StatSecs = isnull(datediff(second,StatStart,StatEnd),0), StatMins = isnull(datediff(second,StatStart,StatEnd),0)*1.0/60.0
			  from dbo.#RTA_EvtStatus_Quartiles
			 where StatOrd = 6 and FromArea is not null
		END
		
		IF(@UseQuartile = 0 and @RspAnalysis = 1)
		BEGIN
		    select *,
			       FreqDist = case when t.StatSecs <= 5 then '5'
				                   when t.StatSecs > 5 and t.StatSecs <= 10 then '10'
				                   when t.StatSecs > 10 and t.StatSecs <= 30 then '30'
				                   when t.StatSecs > 30 and t.StatSecs <= 60 then '60'
				                   when t.StatSecs > 60 and t.StatSecs <= 120 then '120'
				                   when t.StatSecs > 120 and t.StatSecs <= 180 then '180'
				                   when t.StatSecs > 180 and t.StatSecs <= 300 then '300'
				                   when t.StatSecs > 300 and t.StatSecs <= 600 then '600'
				                   else '600+'end
			  from (
			select PktNum, EventDisplay, StatOrd, Stat, EvtArea = ToArea, EmpArea = FromArea, Distance, 
			       StatSecs = sum(isnull(datediff(second,StatStart,StatEnd),0)), StatMins = sum(isnull(datediff(second,StatStart,StatEnd),0)*1.0/60.0)
			  from dbo.#RTA_EvtStatus_Quartiles
			 where StatOrd = 6 and FromArea is not null
			 group by PktNum, EventDisplay, StatOrd, Stat, ToArea, FromArea, Distance ) as t
		END
		
		IF(@UseQuartile = 0 and @RspAnalysis = 2)
		BEGIN
			select EmpJobType = isnull(EmpJobType,'Attendant'), PktNum, EventDisplay, Distance, CustTierLevel,
			       AsnSecs = sum(case when StatOrd = 4 then datediff(second,StatStart,StatEnd) else 0 end),
				   AcpSecs = sum(case when StatOrd = 5 then datediff(second,StatStart,StatEnd) else 0 end),
				   RspSecs = sum(case when StatOrd = 6 then datediff(second,StatStart,StatEnd) else 0 end),
				   CmpSecs = sum(case when StatOrd in (7,8,9,10,11) then datediff(second,StatStart,StatEnd) else 0 end)
			  from dbo.#RTA_EvtStatus_Quartiles
			 group by isnull(EmpJobType,'Attendant'), PktNum, EventDisplay, Distance, CustTierLevel
		END
	END
	
	IF (@UseQuartile = 0 and @RspAnalysis = 0)
	BEGIN
		select * from dbo.#RTA_EventDetails_ExecSum_Emp2_Tmp3
	END
	
END



GO


