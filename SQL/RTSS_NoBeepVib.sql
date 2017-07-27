use RTSS
go

-- Summary
select DayHour = dateadd(hour,datepart(hour,a.tEventState),cast(cast(a.tEventState as date) as datetime)),
       a.EmpNum, a.DeviceID, a.PktNum, EvtZone = e.Zone, EmpZone = le.Zone, COUNT(distinct r.tEventState)
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
  left join EVENT1 as le WITH (NOLOCK)
	on le.EmpNumComplete = a.EmpNum
   and le.tComplete < a.tEventState
   and le.tComplete > DATEADD(hour,-8,a.tEventState)
 where (a.EventState in ('tAssign','tAssignSupervisor','tReassign','ReassignAttendant','tReassignSupervisor'))
   and (    (r.EventState in ('tRejectAutoServer'))
         or (     r.EventState = 'tReject'
              and r.EmpName = (select ltrim(rtrim(Setting))  -- Server IP
                                 from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK)
                                where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP') ) )
   and e.tOut >= '1/23/2017' and e.tOut < '1/24/2017'
   and (v.PktNum is null)
   and not exists
	 ( select * from EVENT1 as le2 WITH (NOLOCK)
		where le2.EmpNumComplete = a.EmpNum
		  and le2.tComplete < a.tEventState
          and le2.tComplete > DATEADD(hour,-8,a.tEventState)
		  and le2.tComplete > le.tComplete )
 group by dateadd(hour,datepart(hour,a.tEventState),cast(cast(a.tEventState as date) as datetime)), a.EmpNum, a.DeviceID, a.PktNum, e.Zone, le.Zone


--Event Details
select l.PktNum, d.EventDisplay, d.CustTierLevel, l.tEventState, l.EventState, l.EmpNum, l.EmpName
  from EVENT_STATE_LOG1 as l WITH (NOLOCK)
 inner join EVENT4 as d WITH (NOLOCK)
    on d.PktNum = l.PktNum
 where l.PktNum
    in (
select distinct e.PktNum
  from EVENT4 as e WITH (NOLOCK)
 inner join EVENT_STATE_LOG1 as a WITH (NOLOCK)
    on a.PktNum = e.PktNum
 inner join EVENT_STATE_LOG1 as r WITH (NOLOCK)
    on r.PktNum = e.PktNum
   and r.tEventState > a.tEventState
  left join EVENT_STATE_LOG1 as v WITH (NOLOCK)
    on v.PktNum = e.PktNum
   and v.tEventState > a.tEventState
   and v.tEventState < r.tEventState
   and v.EventState in ('Display-NEW EVENT','BeepAssignedEvent','VibrateAssignedEvent','tReassignDisplayed')
 where (a.EventState in ('tAssign','tAssignSupervisor','tReassign','ReassignAttendant','tReassignSupervisor'))
   and (    (r.EventState in ('tRejectAutoServer'))
         or (     r.EventState = 'tReject'
              and r.EmpName = (select ltrim(rtrim(Setting))  -- Server IP
                                 from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK)
                                where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP') ) )
   and e.tOut >= '1/14/2017' and e.tOut < '1/21/2017'
   and (v.PktNum is null) )
 order by l.PktNum, l.tEventState

