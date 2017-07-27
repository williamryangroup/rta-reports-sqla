use RTA_SQLA
go

-- AcpToRsp and RspToCmp
select DateTime, PktNum, EventDisplay, EmpJobType,
       OpnToAsnSecs = 0,
	   AsnToAcpSecs = sum(isnull(DATEDIFF(second,tAsn,tAcp),0)),
	   AcpToRspSecs = sum(isnull(DATEDIFF(second,tAcp,tRsp),0)),
	   RspToCmpSecs = sum(isnull(DATEDIFF(second,tRsp,tCmp),0)),
	   EmpNum = ''
 from (
select dt.DateTime, e.PktNum, d.EventDisplay, e.EmpJobType,
	   tAsn = case when tAsn >= dt.DateTime and tAsn < dateadd(minute,15,dt.DateTime) then tAsn
				   when tAsn < dt.DateTime and tAcp >= dt.DateTime then dt.DateTime
				   else null end,
	   tAcp = case when tAcp >= dt.DateTime and tAcp < dateadd(minute,15,dt.DateTime) then tAcp
				   when tAsn < dateadd(minute,15,dt.DateTime) and tAcp >= dateadd(minute,15,dt.DateTime) then dateadd(minute,15,dt.DateTime)
				   else null end,
	   tRsp = null,
	   tCmp = null
  from DateTimes as dt
  left join RTA_SQLA.dbo.SQLA_EmployeeEventTimes e
    on e.ActivityStart <= dateadd(minute,15,dt.DateTime)
   and e.ActivityEnd >= dt.DateTime
  left join SQLA_EventDetails as d
    on d.PktNum = e.PktNum
 where d.EventDisplay not in ('OOS','EMPCARD') and d.EventDisplay not like 'EMPCARD%'
   and EmpJobType is not null
   and tAsn is not null and tAcp is not null and tAsn < tAcp
 union all
select dt.DateTime, e.PktNum, d.EventDisplay, e.EmpJobType,
	   tAsn = null,
	   tAcp = case when tAcp >= dt.DateTime and tAcp < dateadd(minute,15,dt.DateTime) then tAcp
				   when tAcp < dt.DateTime and tRsp >= dt.DateTime then dt.DateTime
				   else null end,
	   tRsp = case when tRsp >= dt.DateTime and tRsp < dateadd(minute,15,dt.DateTime) then tRsp
				   when tAcp < dateadd(minute,15,dt.DateTime) and tRsp >= dateadd(minute,15,dt.DateTime) then dateadd(minute,15,dt.DateTime)
				   else null end,
	   tCmp = null
  from DateTimes as dt
  left join RTA_SQLA.dbo.SQLA_EmployeeEventTimes e
    on e.ActivityStart <= dateadd(minute,15,dt.DateTime)
   and e.ActivityEnd >= dt.DateTime
  left join SQLA_EventDetails as d
    on d.PktNum = e.PktNum
 where d.EventDisplay not in ('OOS','EMPCARD') and d.EventDisplay not like 'EMPCARD%'
   and EmpJobType is not null
   and tAcp is not null and tRsp is not null and tAcp < tRsp
 union all
select dt.DateTime, e.PktNum, d.EventDisplay, e.EmpJobType,
	   tAsn = null,
	   tAcp = null,
	   tRsp = case when tRsp >= dt.DateTime and tRsp < dateadd(minute,15,dt.DateTime) then tRsp
				   when tRsp < dt.DateTime and tCmp >= dt.DateTime then dt.DateTime
				   else null end,
	   tCmp = case when tCmp >= dt.DateTime and tCmp < dateadd(minute,15,dt.DateTime) then tCmp
				   when tRsp < dateadd(minute,15,dt.DateTime) and tCmp >= dateadd(minute,15,dt.DateTime) then dateadd(minute,15,dt.DateTime)
				   else null end
  from DateTimes as dt
  left join RTA_SQLA.dbo.SQLA_EmployeeEventTimes e
    on e.ActivityStart <= dateadd(minute,15,dt.DateTime)
   and e.ActivityEnd >= dt.DateTime
  left join SQLA_EventDetails as d
    on d.PktNum = e.PktNum
 where d.EventDisplay not in ('OOS','EMPCARD') and d.EventDisplay not like 'EMPCARD%'
   and EmpJobType is not null
   and tRsp is not null and tCmp is not null and tRsp < tCmp ) as t
 group by DateTime, PktNum, EmpJobType, EventDisplay
 union all

-- OpnToAsnSecs - ATTENDANT
select o.DateTime, o.PktNum, o.EventDisplay, o.EmpJobType, OpnToAsnSecs = sum(DATEDIFF(second,o.tOpn,o.tAsn)), AsnToAcpSecs = 0, AcpToRspSecs = 0, RspToCmpSecs = 0, EmpNum = ''
  from (
-- Join Quartiles to OpnToAsn times
select dt.DateTime, a.PktNum, dsp.EventDisplay, EmpJobType = 'Attendant',
       tOpn = case when tOpn < dt.DateTime then dt.DateTime else tOpn end,
	   tAsn = case when tAsn > dateadd(minute,15,dt.DateTime) then dateadd(minute,15,dt.DateTime) else tAsn end
  from DateTimes as dt
 inner join (

-- tOut to initial Assign/Authorize
select et.PktNum, tOpn = ed.tOut, tAsn = min(et.ActivityStart)
  from SQLA_EmployeeEventTimes et
 inner join SQLA_EventDetails as ed
   on et.PktNum = ed.PktNum
 where ed.EventDisplay not in ('OOS','EMPCARD') and ed.EventDisplay not like 'EMPCARD%'
 group by et.PktNum, ed.tOut
 union all

-- Rejects to next assign/authorize
select ets.PktNum, tOpn = ets.ActivityEnd, tAsn = min(ete.ActivityStart)
  from SQLA_EmployeeEventTimes ets
 inner join SQLA_EmployeeEventTimes ete
    on ets.PktNum = ete.PktNum
   and ets.ActivityEnd < ete.ActivityStart
 where ets.EventDisplay not in ('OOS','EMPCARD') and ets.EventDisplay not like 'EMPCARD%'
   and not exists (select null from SQLA_EmployeeEventTimes et where et.PktNum = ets.PktNum and et.ActivityStart = ets.ActivityEnd)
 group by ets.PktNum, ets.ActivityEnd
 union all

-- Completed without being assigned to an employee
select ed.PktNum, tOpn = max(et.ActivityEnd), tAsn = ed.tComplete
  from SQLA_EventDetails as ed
 inner join SQLA_EmployeeEventTimes et
   on et.PktNum = ed.PktNum
 where ed.EventDisplay not in ('OOS','EMPCARD') and ed.EventDisplay not like 'EMPCARD%'
 group by ed.PktNum, ed.tComplete
 having max(et.ActivityEnd) < ed.tComplete
 
  ) as a
    on a.tOpn < dateadd(minute,15,dt.DateTime)
   and a.tAsn > dt.DateTime 
 inner join SQLA_EventDetails as  dsp
    on dsp.PktNum = a.PktNum ) as o
 group by o.DateTime, o.PktNum, o.EventDisplay, o.EmpJobType
 union all

-- OpnToAsnSecs - SUPERVISOR
select o.DateTime, o.PktNum, o.EventDisplay, o.EmpJobType, OpnToAsnSecs = sum(DATEDIFF(second,o.tOpn,o.tAsn)), AsnToAcpSecs = 0, AcpToRspSecs = 0, RspToCmpSecs = 0, EmpNum = ''
  from (
-- Join Quartiles to OpnToAsn times
select dt.DateTime, a.PktNum, dsp.EventDisplay, EmpJobType = 'Slot Supervisor',
       tOpn = case when tOpn < dt.DateTime then dt.DateTime else tOpn end,
	   tAsn = case when tAsn > dateadd(minute,15,dt.DateTime) then dateadd(minute,15,dt.DateTime) else tAsn end
  from DateTimes as dt
 inner join (

-- tOut to initial Assign/Authorize
select et.PktNum, tOpn = ed.tOut, tAsn = min(et.ActivityStart)
  from SQLA_EmployeeEventTimes et
 inner join SQLA_EventDetails as ed
   on et.PktNum = ed.PktNum
 where ed.EventDisplay not in ('OOS','EMPCARD') and ed.EventDisplay not like 'EMPCARD%'
 group by et.PktNum, ed.tOut
 union all

-- Rejects to next assign/authorize
select ets.PktNum, tOpn = ets.ActivityEnd, tAsn = min(ete.ActivityStart)
  from SQLA_EmployeeEventTimes ets
 inner join SQLA_EmployeeEventTimes ete
    on ets.PktNum = ete.PktNum
   and ets.ActivityEnd < ete.ActivityStart
 where ets.EventDisplay not in ('OOS','EMPCARD') and ets.EventDisplay not like 'EMPCARD%'
   and not exists (select null from SQLA_EmployeeEventTimes et where et.PktNum = ets.PktNum and et.ActivityStart = ets.ActivityEnd)
 group by ets.PktNum, ets.ActivityEnd
 union all

-- Completed without being assigned to an employee
select ed.PktNum, tOpn = max(et.ActivityEnd), tAsn = ed.tComplete
  from SQLA_EventDetails as ed
 inner join SQLA_EmployeeEventTimes et
   on et.PktNum = ed.PktNum
 where ed.EventDisplay not in ('OOS','EMPCARD') and ed.EventDisplay not like 'EMPCARD%'
 group by ed.PktNum, ed.tComplete
 having max(et.ActivityEnd) < ed.tComplete
 
  ) as a
    on a.tOpn < dateadd(minute,15,dt.DateTime)
   and a.tAsn > dt.DateTime 
 inner join SQLA_EventDetails as  dsp
    on dsp.PktNum = a.PktNum ) as o
 group by o.DateTime, o.PktNum, o.EventDisplay, o.EmpJobType
 union all

-- EMPLOYEE counts
select distinct dt.DateTime, PktNum = null, EventDisplay = '', EmpJobType = l.JobType,
       OpnToAsnSecs = 0, AsnToAcpSecs = 0, AcpToRspSecs = 0, RspToCmpSecs = 0, l.EmpNum
  from DateTimes as dt
 inner join (
select s.EmpNum, j.JobType, tLogin = s.tOut, tLogout = min(e.tOut)
  from SQLA_FloorActivity as s
 inner join SQLA_FloorActivity as e
    on e.EmpNum = s.EmpNum
   and e.tOut > s.tOut
  left join SQLA_Employees as j
    on j.CardNum = s.EmpNum
 where s.ActivityTypeID = 3 and (s.State like 'Login%' or s.State like 'Start%')
   and e.ActivityTypeID = 3 and (e.State like 'Login%' or e.State like 'Start%' or e.State like '%Logout%' or e.State like 'End%')
 group by s.EmpNum, j.JobType, s.tOut ) as l
    on l.tLogin < dateadd(minute,15,dt.DateTime)
   and l.tLogout > dt.DateTime

 order by PktNum, EmpJobType, DateTime
