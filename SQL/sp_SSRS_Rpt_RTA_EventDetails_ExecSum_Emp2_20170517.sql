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
	@IncludeEMPCARD int = 1

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
	   and (EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	 group by EmpNum
	   
	
	-- Stat Ords
	--   0 = Available
	--   1 = OpnToAsn
	--   2 = AsnToAcp / AsnToRej
	--   3 = AcpToRsp
	--   4 = AsnRspToNotCmp
	--   5 = AsnRspToCmp
	--   6 = TknToNotCmp
	--   7 = TknToCmp
	--   8 = JP Ver
	--   9 = Break
	--  10 = OOS
	
	
	-- EVENT OpnToAsn
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select EmpNum = '', EmpName = '', EmpJobType = '', et.PktNum, et.EventDisplay, 
	       StatOrd = 1, Stat = 'OpnToAsn', StatStart = ed.tOut, StatEnd = min(isnull(isnull(et.tAsn,et.tRea),et.tRsp))
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
	       StatOrd = 2, Stat = 'AsnToAcp', StatStart = isnull(tAsn,tRea), StatEnd = isnull(isnull(isnull(tAcp,tRsp),tCmp),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRej is null and isnull(tAsn,tRea) < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 2, Stat = 'AsnToRej', StatStart = isnull(tAsn,tRea), StatEnd = tRej
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRej is not null and isnull(tAsn,tRea) < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 3, Stat = 'AcpToRsp', StatStart = tAcp, StatEnd = isnull(isnull(isnull(tRsp,tCmp),tRej),ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tAcp is not null and tAcp < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 4, Stat = 'AsnRspToNotCmp', StatStart = tRsp, StatEnd = isnull(tRej,ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRsp is not null and tCmp is null and tRsp < @EndDt
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 5, Stat = 'AsnRspToCmp', StatStart = tRsp, StatEnd = tCmp
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and ((tAsn is not null and ((tRsp is null) or (tRsp is not null and DATEDIFF(SECOND,tAsn,tRsp) > 1))) or (tRea is not null))
	   and tRsp is not null and tCmp is not null and tRsp < @EndDt
	   
	   
	-- TAKEN EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 6, Stat = 'TknToNotCmp', StatStart = tRsp, StatEnd = isnull(tRej,ActivityEnd)
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt 
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and tRsp is not null and tRsp < @EndDt
	   and ((tAsn is null and tRea is null) or (tAsn is not null and DATEDIFF(SECOND,tAsn,tRsp) <= 1))
	   and tCmp is null
	   
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
	       StatOrd = 7, Stat = 'TknToCmp', StatStart = tRsp, StatEnd = tCmp
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and tRsp is not null and tRsp < @EndDt
	   and ((tAsn is null and tRea is null) or (tAsn is not null and DATEDIFF(SECOND,tAsn,tRsp) <= 1))
	   and tCmp is not null
	   and EventDisplay not like 'JKPT%' and EventDisplay not in ('JP VER')
	   
	   
	-- JP VER EVENTS
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
		   StatOrd = 8, Stat = EventDisplay, StatStart = tOut, StatEnd = tComplete
	  from SQLA_EventDetails_JPVER as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
		on a.EmpNum = et.EmpNum
	 where tOut < @EndDt and tComplete > @StartDt
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and tOut >= MinActivityStart and tComplete <= MaxActivityEnd
	   
	   
	-- OOS / BREAK
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatStart,StatEnd)
	select et.EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1), EmpJobType, PktNum, EventDisplay,
		   StatOrd = case when PktNum = 1 then 9 -- Break
						  when PktNum = 2 then 10 -- OOS
						  end,
		   Stat = EventDisplay, StatStart = ActivityStart, StatEnd = ActivityEnd
	  from SQLA_EmployeeEventTimes as et
	 inner join #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	    on a.EmpNum = et.EmpNum
	 where ActivityStart < @EndDt and ActivityEnd > @StartDt
	   and PktNum in (1,2) and ActivityStart >= @StartDt and ActivityStart < @EndDt
	   and (et.EmpJobType in (select JobType from #RTA_EventDetails_ExecSum_Emp2_JobTypes) or @EmpJobType is null or @EmpJobType = '')
	   and ActivityStart >= MinActivityStart and ActivityEnd <= MaxActivityEnd
	   and @UtilType = 0 and ((@IncludeOOS = 0 and PktNum not in (2)) or (@IncludeOOS = 1))
		
	
	-- UPDATE StatSecs
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatStart = @StartDt
	 where StatStart < @StartDt
	 
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatEnd = @EndDt
	 where StatEnd > @EndDt
	   
	update #RTA_EventDetails_ExecSum_Emp2_Tmp2
	   set StatSecs = datediff(second,StatStart,StatEnd)
	
	
	-- TOTAL OTHER
	insert into #RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 (EmpNum,StatSecs)
	select EmpNum, StatSecs = sum(isnull(StatSecs,0))
	  from #RTA_EventDetails_ExecSum_Emp2_Tmp2
	 where @UtilType = 0
	 group by EmpNum
	
	
	-- INSERT AVAILABLE
	insert into #RTA_EventDetails_ExecSum_Emp2_Tmp2 (EmpNum,EmpName,EmpJobType,PktNum,EventDisplay,StatOrd,Stat,StatSecs,StatStart,StatEnd)
	select a.EmpNum, EmpName = '', EmpJobType = '', PktNum = 3, EventDisplay = 'Available', StatOrd = 0, Stat = 'Available', 
	       StatSecs = a.StatSecs - isnull(o.StatSecs,0), MinActivityStart, MaxActivityEnd
	  from #RTA_EventDetails_ExecSum_Emp2_Avl_Tmp2 as a
	  left join #RTA_EventDetails_ExecSum_Emp2_Oth_Tmp2 as o
	    on a.EmpNum = o.EmpNum
	 where @UtilType = 0
		
	   
	-- RETURN table
	select u.EmpNum,
	       EmpName = case when isnull(u.EmpName,'') = '' and isnull(e.NameFirst,'') <> '' then e.NameFirst + ' ' + left(e.NameLast,1)
	                      when isnull(u.EmpName,'') = '' and isnull(e.NameFirst,'') = '' then u.EmpNum
						  else u.EmpName end,
	       EmpJobType = case when isnull(u.EmpJobType,'') = '' then e.JobType else u.EmpJobType end, 
		   u.PktNum, 
		   EventDisplay = case when u.EventDisplay like 'JKPT%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) < 1200 then 'JKPT<1200'
	                           when u.EventDisplay like 'JKPT%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) >= 1200 then 'JKPT>=1200'
							   when u.EventDisplay like 'JP%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) < 1200 then 'JKPT<1200'
	                           when u.EventDisplay like 'JP%' and isnumeric(d.AmtEvent)=1 and cast(d.AmtEvent as float) >= 1200 then 'JKPT>=1200'
							   when u.EventDisplay like 'PROG%' or u.EventDisplay like 'PJ%' then 'PROG'
							   when u.EventDisplay like 'PJ%' then 'PJ'
							   when u.EventDisplay like 'EMPCARD%' then 'EMPCARD'
							   when u.EventDisplay like 'REEL%' then 'REEL'
							   else u.EventDisplay end,
	       u.StatOrd,
		   Stat = case when @EventSum = 1 and u.StatOrd not in (0,1,2,9,10) then 'EVENT' else u.Stat end, 
		   u.StatSecs,
		   u.StatStart,
		   u.StatEnd
	  from #RTA_EventDetails_ExecSum_Emp2_Tmp2 as u
	  left join SQLA_Employees as e
	    on u.EmpNum = e.CardNum
	  left join SQLA_EventDetails as d
	    on d.PktNum = u.PktNum
	  
END



GO


