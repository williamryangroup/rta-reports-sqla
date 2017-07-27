
select RptStart = '1/23/2017', RptEnd = '1/24/2017',
       DayHour, q.EmpNum, q.DeviceID, EmpName = '(' + left(emp.JobType,1) + ') ' + RTRIM(emp.NameFirst) + ' ' + LEFT(emp.NameLast,1) + '.',
       AsnCount = sum(q.AsnCount),
	   AsnNoBeepVibCount = sum(q.AsnNoBeepVibCount),
	   LoginCount = sum(q.LoginCount),
	   LogoutCount = sum(q.LogoutCount),
	   RejAutoServerCount = sum(RejAutoServerCount),
	   GetEvtCount = sum(GetEvtCount)
 from (
 
-- AsnCount
select DayHour = dateadd(hour,datepart(hour,a.tEventState),cast(cast(a.tEventState as date) as datetime)),
       a.EmpNum, a.DeviceID,
       AsnCount = count(distinct a.tEventState),
	   AsnNoBeepVibCount = 0,
	   LoginCount = 0,
	   LogoutCount = 0,
	   RejAutoServerCount = 0,
	   GetEvtCount = 0,
	   MinsLoggedIn = 0,
	   FirstLogin = null,
	   LastLogout = null
  from EVENT1 as e WITH (NOLOCK)
 inner join EVENT_STATE_LOG1 as a WITH (NOLOCK)
    on a.PktNum = e.PktNum
 where a.EventState in ('tAssign','tAssignSupervisor','tReassign','ReassignAttendant','tReassignSupervisor')
   and e.tOut >= '1/23/2017' and e.tOut < '1/24/2017'
 group by dateadd(hour,datepart(hour,a.tEventState),cast(cast(a.tEventState as date) as datetime)), a.EmpNum, a.DeviceID
 union all
 
-- AsnNoBeepVibCount
select DayHour = dateadd(hour,datepart(hour,a.tEventState),cast(cast(a.tEventState as date) as datetime)),
       a.EmpNum, a.DeviceID, 
       AsnCount = 0,
       AsnNoBeepVibCount = count(distinct r.tEventState),
	   LoginCount = 0,
	   LogoutCount = 0,
	   RejAutoServerCount = 0,
	   GetEvtCount = 0,
	   MinsLoggedIn = 0,
	   FirstLogin = null,
	   LastLogout = null
  from EVENT1 as e WITH (NOLOCK)
 inner join EVENT_STATE_LOG1 as a WITH (NOLOCK)
    on a.PktNum = e.PktNum
 inner join EVENT_STATE_LOG1 as r WITH (NOLOCK)
    on r.PktNum = a.PktNum
   and r.EmpNum = a.EmpNum
   and r.tEventState > a.tEventState
  left join EVENT_STATE_LOG1 as v WITH (NOLOCK)
    on v.PktNum = a.PktNum
   and v.EmpNum = a.EmpNum
   and v.tEventState > a.tEventState
   and v.tEventState < r.tEventState
   and v.EventState in ('Display-NEW EVENT','BeepAssignedEvent','VibrateAssignedEvent','tReassignDisplayed')
 where (a.EventState in ('tAssign','tAssignSupervisor','tReassign','ReassignAttendant','tReassignSupervisor'))
   and (    (r.EventState in ('tRejectAutoServer'))
         or (     r.EventState = 'tReject'
              and r.EmpName = (select ltrim(rtrim(Setting))  -- Server IP
                                 from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK)
                                where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP') ) )
   and e.tOut >= '1/23/2017' and e.tOut < '1/24/2017'
   and (v.PktNum is null)
 group by dateadd(hour,datepart(hour,a.tEventState),cast(cast(a.tEventState as date) as datetime)), a.EmpNum, a.DeviceID
 union all
 
-- Login Counts
select DayHour,
       EmpNum = CardNum, DeviceID, 
       AsnCount = 0,
       AsnNoBeepVibCount = 0,
       LoginCount = SUM(LoginCount),
       LogoutCount = SUM(LogoutCount),
	   RejAutoServerCount = 0,
	   GetEvtCount = 0,
	   MinsLoggedIn = 0,
	   FirstLogin = null,
	   LastLogout = null
  from (
select DayHour = dateadd(hour,datepart(hour,ea.tOut),cast(cast(ea.tOut as date) as datetime)),
       ea.CardNum, ea.DeviceID,
       LoginCount = case when ea.Activity like 'Login%' then 1 else 0 end,
       LogoutCount = case when ea.Activity like 'Logout%' then 1 else 0 end
  from EMPLOYEEACTIVITY as ea WITH (NOLOCK)
 where (ea.Activity like 'Login%' or ea.Activity like 'Logout%')
   and ea.tOut >= '1/23/2017' and ea.tOut < '1/24/2017'
 union all
select DayHour = dateadd(hour,datepart(hour,ea.tOut),cast(cast(ea.tOut as date) as datetime)),
       ea.CardNum, ea.DeviceID,
       LoginCount = case when ea.Activity like 'Login%' then 1 else 0 end,
       LogoutCount = case when ea.Activity like 'Logout%' then 1 else 0 end
  from EMPLOYEEACTIVITY1 as ea WITH (NOLOCK)
 where (ea.Activity like 'Login%' or ea.Activity like 'Logout%')
   and ea.tOut >= '1/23/2017' and ea.tOut < '1/24/2017'
       ) as t
 group by DayHour, CardNum, DeviceID
 union all
 
-- RejAutoServerCount
select DayHour = dateadd(hour,datepart(hour,r.tEventState),cast(cast(r.tEventState as date) as datetime)),
       r.EmpNum, r.DeviceID,
       AsnCount = 0,
	   AsnNoBeepVibCount = 0,
	   LoginCount = 0,
	   LogoutCount = 0,
	   RejAutoServerCount = count(distinct r.tEventState),
	   GetEvtCount = 0,
	   MinsLoggedIn = 0,
	   FirstLogin = null,
	   LastLogout = null
  from EVENT1 as e WITH (NOLOCK)
 inner join EVENT_STATE_LOG1 as r WITH (NOLOCK)
    on r.PktNum = e.PktNum
 where (    (r.EventState in ('tRejectAutoServer'))
         or (     r.EventState = 'tReject'
              and r.EmpName = (select ltrim(rtrim(Setting))  -- Server IP
                                 from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK)
                                where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP') ) )
   and e.tOut >= '1/23/2017' and e.tOut < '1/24/2017'
 group by dateadd(hour,datepart(hour,r.tEventState),cast(cast(r.tEventState as date) as datetime)), r.EmpNum, r.DeviceID
 union all
 
-- GetEvtCount
select DayHour = dateadd(hour,datepart(hour,EvtTime),cast(cast(EvtTime as date) as datetime)),
       EmpNum = UserName, DeviceId = MachineName,
       AsnCount = 0,
	   AsnNoBeepVibCount = 0,
	   LoginCount = 0,
	   LogoutCount = 0,
	   RejAutoServerCount = 0,
	   GetEvtCount = COUNT(*),
	   MinsLoggedIn = 0,
	   FirstLogin = null,
	   LastLogout = null
  from SYSTEMLOG1 WITH (NOLOCK)
 where EvtType = 'GetEvents'
   and EvtTime >= '1/23/2017' and EvtTime < '1/24/2017'
 group by dateadd(hour,datepart(hour,EvtTime),cast(cast(EvtTime as date) as datetime)), UserName, MachineName

     ) as q
  left join RTSS.dbo.EMPLOYEE as emp WITH (NOLOCK)
    on emp.CardNum = q.EmpNum
 group by q.DayHour, q.EmpNum, q.DeviceID, emp.JobType, emp.NameFirst, emp.NameLast