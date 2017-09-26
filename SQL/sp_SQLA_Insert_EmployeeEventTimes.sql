USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmployeeEventTimes]    Script Date: 06/21/2016 11:48:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmployeeEventTimes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmployeeEventTimes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmployeeEventTimes]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	delete from SQLA_EmployeeEventTimes where ActivityEnd is null
	
	DECLARE @MinPktNum int = (select isnull(MAX(PktNum),0) from SQLA_EmployeeEventTimes)
	DECLARE @MinBreakOOSLoginDttm datetime = (select isnull(MAX(ActivityStart),'1/1/2010') from SQLA_EmployeeEventTimes where PktNum in (1,2,3))
	
	
	CREATE TABLE #Employee_EventTimeStart_Tmp (
		PktNum int not null,
		EmpNum nvarchar(255) not null,
		EventDisplay nvarchar(255) null,
		StartTime datetime not null
	)
	
	CREATE TABLE #Employee_EventTimeEnd_Tmp (
		PktNum int not null,
		EmpNum nvarchar(255) not null,
		EventDisplay nvarchar(255) null,
		EndTime datetime not null
	)
	
	CREATE TABLE #Employee_EventTime_Tmp (
		EmpNum [nvarchar](255) NOT NULL,
		EmpNameFirst [nvarchar](50) NULL,
		EmpNameLast [nvarchar](50) NULL,
		EmpJobType [nvarchar](20) NULL,
		PktNum [int] NOT NULL,
		EventDisplay [nvarchar](255) NULL,
		ActivityStart [datetime] NOT NULL,
		ActivityEnd [datetime] NULL,
		ActivitySecs [int] NULL
	)
	
	
	-- Start Times - Employee assigned to event
	insert into #Employee_EventTimeStart_Tmp (PktNum, EmpNum, EventDisplay, StartTime)
    select distinct PktNum, EmpNum, Activity, tOut
	  from SQLA_FloorActivity
	 where PktNum > @MinPktNum and tOut is not null	and EmpNum is not null and EmpNum <> ''
	   and ActivityTypeID = 5 and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor','tReassignPrior')
	   
	-- Start Times - Employee authorized events without being assigned (Take)
	insert into #Employee_EventTimeStart_Tmp (PktNum, EmpNum, EventDisplay, StartTime)
	select distinct PktNum, EmpNum, Activity, tOut
	  from SQLA_FloorActivity as f1
	 where PktNum > @MinPktNum and tOut is not null and EmpNum is not null and EmpNum <> ''
	   and ActivityTypeID = 5 and State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile')
	   and not exists
		 ( select null from SQLA_FloorActivity as f2
			where f2.PktNum = f1.PktNum
			  and f2.EmpNum = f1.EmpNum
			  and f2.ActivityTypeID = 5
			  and f2.tOut <= f1.tOut
			  and f2.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor','tReassignPrior') )
	   and not exists
		 ( select null from SQLA_FloorActivity as f2
			where f2.PktNum = f1.PktNum
			  and f2.EmpNum = f1.EmpNum
			  and f2.ActivityTypeID = 5
			  and f2.tOut < f1.tOut
			  and f2.State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile') )
	
	
	-- End Times - Event is completed
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.State like 'Complete%'
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End Times - Employee rejects event or assigned another event
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum = s.EmpNum
	   and (f.State like 'Reject%' or f.State like 'Reassign%Reject%' or f.State = 'Event Assigned Remove')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End times - Next event state is with another employee
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut >= s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum <> s.EmpNum
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	   and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor','tReassignPrior',
	                 'Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile')
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End Times - Employee is assigned event again
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_FloorActivity as f
	    on f.tOut > s.StartTime
	   and f.PktNum = s.PktNum
	   and f.EmpNum = s.EmpNum
	   and f.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor','tReassignPrior')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	-- End times - Employee is assigned or authorized another event before event is completed
	insert into #Employee_EventTimeEnd_Tmp (PktNum, EmpNum, EventDisplay, EndTime)
	select s.PktNum, s.EmpNum, s.EventDisplay, min(f.tOut)
	  from #Employee_EventTimeStart_Tmp as s
	 inner join SQLA_EventDetails as e
	    on e.PktNum = s.PktNum
	 inner join SQLA_FloorActivity as f
	    on f.tOut <= e.tComplete
	   and f.tOut > s.StartTime
	   and f.PktNum <> s.PktNum
	   and f.EmpNum = s.EmpNum
	   and f.State in ('Re-assign')
	 where f.PktNum > @MinPktNum and f.ActivityTypeID = 5 and f.EmpNum is not null and f.EmpNum <> ''
	 group by s.PktNum, s.EmpNum, s.EventDisplay, s.StartTime
	
	
	-- INSERT EVENTS
	insert into #Employee_EventTime_Tmp (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
	       s.PktNum, s.EventDisplay, ActivityStart = s.StartTime, ActivityEnd = min(e.EndTime),
		   ActivitySecs = case when (min(e.EndTime) is null) or (min(e.EndTime) < s.StartTime) then 0 else DATEDIFF(second,s.StartTime,min(e.EndTime)) end 
	  from #Employee_EventTimeStart_Tmp as s
	  left join #Employee_EventTimeEnd_Tmp as e
	    on e.PktNum = s.PktNum
	   and e.EmpNum = s.EmpNum
	   and e.EndTime > s.StartTime
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.PktNum, s.EventDisplay, s.StartTime
	
	
	-- DELETE ActivityEnd NULL
	delete from #Employee_EventTime_Tmp where ActivityEnd is null
	
	
	-- DROP tmp tables
	drop table #Employee_EventTimeStart_Tmp
	drop table #Employee_EventTimeEnd_Tmp

	
	-- INSERT tAsn,tRea,tDsp,tAcp,tRsp,tRej,tCmp
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs,tAsn,tRea,tDsp,tAcp,tRsp,tRej,tCmp)
	select e.EmpNum, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType, e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, e.ActivitySecs,
		   tAsn = MIN(case when f.State in ('Assign','Assign Supervisor') then f.tOut else null end),
		   tRea = MIN(case when f.State in ('Re-assign','Reassign Attendant','Reassign Supervisor') then f.tOut else null end),
		   tDsp = MIN(case when f.State in ('Event Display Mobile','Reassign Display Mobile') then f.tOut else null end),
		   tAcp = MIN(case when f.State in ('Accept Mobile') then f.tOut else null end),
		   tRsp = MIN(case when f.State in ('Authorize Card In','Authorize Initial','Authorize Mobile','Initial Response','Respond Mobile') then f.tOut else null end),
		   tRej = MIN(case when f.State like 'Reject%' or f.State like 'Reassign%Reject' then f.tOut else null end),
		   tCmp = MIN(case when f.State like 'Complete%' then f.tOut else null end)
	  from #Employee_EventTime_Tmp as e
	  left join SQLA_FloorActivity as f
		on f.ActivityTypeID = 5
	   and f.PktNum = e.PktNum
	   and f.EmpNum = e.EmpNum
	   and f.tOut >= e.ActivityStart
	   and f.tOut <= e.ActivityEnd
	 group by e.EmpNum, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType, e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, e.ActivitySecs
	 order by e.ActivityStart
	
	
	-- DROP tmp tables
	drop table #Employee_EventTime_Tmp
	
	
	-- INSERT BREAK
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = s.ActivityTypeID, 
		   EventDisplay = case when s.ActivityTypeID = 1 then 'Break' 
							   when s.ActivityTypeID = 2 then 'OOS'
							   when s.ActivityTypeID = 3 then 'Available'
							   else '' end,
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.tOut >= s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
       and s.State = 'Start' and s.ActivityTypeID = 1
	   and e.ActivityTypeID in (1,3,7) and ((e.State = 'End' or e.State like '%Logout%') or (e.State = 'Start' and e.tOut > s.tOut))
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- INSERT OOS
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = s.ActivityTypeID, 
		   EventDisplay = case when s.ActivityTypeID = 1 then 'Break' 
							   when s.ActivityTypeID = 2 then 'OOS'
							   when s.ActivityTypeID = 3 then 'Available'
							   else '' end,
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.PktNum = s.PktNum
	   and e.tOut >= s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
       and s.State = 'Start' and s.ActivityTypeID = 2 --and s.Activity <> 'OOS - 1. Jackpot Verify'
	   and (    (e.ActivityTypeID = 2 and (e.State = 'End' or (e.State = 'Start' and e.tOut > s.tOut)))
	         or (e.ActivityTypeID = 3 and (e.State like '%Logout%'))
			 or (e.ActivityTypeID = 7 and (e.State = 'SupervAdmEvt' and e.Activity = 'AdminEventActionComplete')))
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	/*
	-- OOS - JP VER
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = min(s.PktNum), 
		   EventDisplay = 'JP VER',
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.PktNum = s.PktNum
	   and e.tOut >= s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
       and s.State = 'Start' and s.ActivityTypeID = 2 and s.Activity = 'OOS - 1. Jackpot Verify'
	   and (    (e.ActivityTypeID = 2 and (e.State = 'End' or (e.State = 'Start' and e.tOut > s.tOut)))
	         or (e.ActivityTypeID = 3 and (e.State like '%Logout%'))
			 or (e.ActivityTypeID = 7 and (e.State = 'SupervAdmEvt' and e.Activity = 'AdminEventActionComplete')))
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	*/
	
	-- INSERT AVAILABLE (LOGIN-LOGOUT)
	insert into SQLA_EmployeeEventTimes (EmpNum,EmpNameFirst,EmpNameLast,EmpJobType,PktNum,EventDisplay,ActivityStart,ActivityEnd,ActivitySecs)
	select EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, 
	       ActivityStart = MIN(ActivityStart), ActivityEnd, ActivitySecs = MAX(ActivitySecs)
	  from (
	select s.EmpNum, EmpNameFirst = rtrim(emp.NameFirst), EmpNameLast = rtrim(emp.NameLast), EmpJobType = rtrim(JobType),
		   PktNum = s.ActivityTypeID,
		   EventDisplay = 'Available',
		   ActivityStart = s.tOut, 
		   ActivityEnd = min(e.tOut),
		   ActivitySecs = case when (min(e.tOut) is null) or (min(e.tOut) < s.tOut) then 0 else DATEDIFF(second,s.tOut,min(e.tOut)) end
	  from SQLA_FloorActivity as s
	 inner join SQLA_FloorActivity as e
		on e.EmpNum = s.EmpNum
	   and e.ActivityTypeID = s.ActivityTypeID
	   and e.tOut > s.tOut
	  left join SQLA_Employees as emp
	    on emp.CardNum = s.EmpNum
	 where s.tOut > @MinBreakOOSLoginDttm
	   and s.State = 'Login' and (e.State = 'Login' or e.State like '%Logout%')
	   and s.ActivityTypeID = 3
	 group by s.EmpNum, emp.NameFirst, emp.NameLast, emp.JobType, s.ActivityTypeID, s.tOut ) as a
	 group by EmpNum, EmpNameFirst, EmpNameLast, EmpJobType, PktNum, EventDisplay, ActivityEnd
	
	
	-- DASHBOARD completed events
	insert into SQLA_EmployeeEventTimes
	select f.EmpNum, EmpNameFirst = e.NameFirst, EmpNameLast = e.NameLast, EmpJobType = e.JobType, f.PktNum, EventDisplay = f.Activity, ActivityStart = f.tOut, ActivityEnd = f.tOut, ActivitySecs = 0,
		   tAsn = null, tRea = null, tDsp = null, tAcp = null, tRsp = null, tRej = null, tCmp = tOut
	  from SQLA_FloorActivity as f
	  left join SQLA_Employees as e
		on e.CardNum = f.EmpNum
	 where ActivityTypeID = 5 and State = 'Complete' and Source = '~r:Dashboard' 
	   and PktNum in (select PktNum from SQLA_EmployeeEventTimes group by PktNum having max(tCmp) is null)
	   
	
	-- DELETE ActivityEnd NULL
	delete from SQLA_EmployeeEventTimes where ActivityEnd is null
	
	
	-- UPDATE ActivityEnd
	update e1
	   set e1.ActivityEnd = e2.ActivityStart
      from SQLA_EmployeeEventTimes as e1
	 inner join SQLA_EmployeeEventTimes as e2
	    on e2.EmpNum = e1.EmpNum
	   and e2.ActivityStart < e1.ActivityEnd
	   and e2.ActivityStart > e1.ActivityStart
	   and e2.PktNum <> 3
	 where e1.PktNum <> 3 and e1.ActivityStart >= @MinBreakOOSLoginDttm
	   and not exists
	     ( select null from SQLA_EmployeeEventTimes as e3
		    where e3.EmpNum = e1.EmpNum
			  and e3.ActivityStart < e1.ActivityEnd
			  and e3.ActivityStart > e1.ActivityStart
			  and e3.PktNum <> 3
			  and e3.ActivityStart < e2.ActivityStart )

END







GO

