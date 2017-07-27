
select RptStart = '1/23/2017', RptEnd = '1/24/2017',
       q.EmpNum, q.DeviceID, EmpName = '(' + left(emp.JobType,1) + ') ' + RTRIM(emp.NameFirst) + ' ' + LEFT(emp.NameLast,1) + '.',
       AsnCount = sum(q.AsnCount),
	   AsnNoBeepVibCount = sum(q.AsnNoBeepVibCount),
	   PctNoBeepVib = case when sum(q.AsnCount) = 0 or sum(q.AsnNoBeepVibCount) = 0 then 0.0
						   else (sum(q.AsnNoBeepVibCount)*1.0 / sum(q.AsnCount)*1.0)*100.0 end,
	   LoginCount = sum(q.LoginCount),
	   LogoutCount = sum(q.LogoutCount),
	   PctLogout = case when sum(q.LoginCount) = 0 or sum(q.LogoutCount) = 0 then 0.0
	                    else (sum(q.LogoutCount)*1.0 / sum(q.LoginCount)*1.0)*100.0 end,
	   RejAutoServerCount = sum(RejAutoServerCount),
	   GetEvtCount = sum(GetEvtCount),
	   MinsLoggedIn = sum(MinsLoggedIn),
	   FirstLogin = MIN(FirstLogin),
	   LastLogout = MAX(LastLogout)
 from (
 
-- AsnCount
select a.EmpNum, a.DeviceID,
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
 group by a.EmpNum, a.DeviceID
 union all
 
-- AsnNoBeepVibCount
select a.EmpNum, a.DeviceID, 
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
 group by a.EmpNum, a.DeviceID
 union all
 
-- Login Counts
select EmpNum = CardNum, DeviceID, 
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
select ea.CardNum, ea.DeviceID,
       LoginCount = case when ea.Activity like 'Login%' then 1 else 0 end,
       LogoutCount = case when ea.Activity like 'Logout%' then 1 else 0 end
  from EMPLOYEEACTIVITY as ea WITH (NOLOCK)
 where (ea.Activity like 'Login%' or ea.Activity like 'Logout%')
   and ea.tOut >= '1/23/2017' and ea.tOut < '1/24/2017'
 union all
select ea.CardNum, ea.DeviceID,
       LoginCount = case when ea.Activity like 'Login%' then 1 else 0 end,
       LogoutCount = case when ea.Activity like 'Logout%' then 1 else 0 end
  from EMPLOYEEACTIVITY1 as ea WITH (NOLOCK)
 where (ea.Activity like 'Login%' or ea.Activity like 'Logout%')
   and ea.tOut >= '1/23/2017' and ea.tOut < '1/24/2017'
       ) as t
 group by CardNum, DeviceID 
 union all
 
-- RejAutoServerCount
select r.EmpNum, r.DeviceID,
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
 group by r.EmpNum, r.DeviceID
 union all
 
-- GetEvtCount
select EmpNum = UserName, DeviceId = MachineName,
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
 group by UserName, MachineName
 union all
 
-- MinsLoggedIn
select EmpNum, DeviceID,
       AsnCount = 0,
	   AsnNoBeepVibCount = 0,
	   LoginCount = 0,
	   LogoutCount = 0,
	   RejAutoServerCount = 0,
	   GetEvtCount = 0,
	   MinsLoggedIn = sum(datediff(SECOND,tStart,tEnd))*1.0/60.0,
	   FirstLogin = min(tStart),
	   LastLogout = max(tEnd)
  from (
select EmpNum = a.CardNum, a.DeviceID, tStart = min(a.tStart), a.tEnd
  from (
select s.CardNum, s.DeviceID,
       tStart = case when s.tOut < '1/23/2017' then '1/23/2017' else s.tOut end,
       tEnd = min(case when e.tOut > '1/24/2017' then '1/24/2017' else e.tOut end)
  from (select CardNum, DeviceID, tOut
          from RTSS.dbo.EMPLOYEEACTIVITY WITH (NOLOCK)
         where tOut < '1/24/2017' and tOut > DATEADD(hour,-12,'1/23/2017')
           and Activity like 'Login%' or Activity like 'Start Shift%'
         union all
        select CardNum, DeviceID, tOut
          from RTSS.dbo.EMPLOYEEACTIVITY1 WITH (NOLOCK)
         where tOut < '1/24/2017' and tOut > DATEADD(hour,-12,'1/23/2017')
           and Activity like 'Login%' or Activity like 'Start Shift%') as s 
 inner join (select CardNum, DeviceID, tOut
               from RTSS.dbo.EMPLOYEEACTIVITY WITH (NOLOCK)
              where tOut >= '1/23/2017' and tOut < DATEADD(hour,12,'1/24/2017')
                and Activity like 'Logout%' or Activity like 'End Shift%'
              union all
             select CardNum, DeviceID, tOut
               from RTSS.dbo.EMPLOYEEACTIVITY1 WITH (NOLOCK)
              where tOut >= '1/23/2017' and tOut < DATEADD(hour,12,'1/24/2017')
                and Activity like 'Logout%' or Activity like 'End Shift%') as e
	on e.CardNum = s.CardNum
   and e.DeviceID = s.DeviceID
   and e.tOut > s.tOut
 where e.tOut >= '1/23/2017' and s.tOut < '1/24/2017'
 group by s.CardNum, s.DeviceID, s.tOut ) as a
 group by a.CardNum, a.DeviceID, a.tEnd ) as l
 group by l.EmpNum, l.DeviceID
 
     ) as q
  left join RTSS.dbo.EMPLOYEE as emp WITH (NOLOCK)
    on emp.CardNum = q.EmpNum
 group by q.EmpNum, q.DeviceID, emp.JobType, emp.NameFirst, emp.NameLast