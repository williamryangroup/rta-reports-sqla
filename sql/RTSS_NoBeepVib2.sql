use RTSS_TSC
go

create table #rta_autorej (
	pktnum int not null primary key
)
go

truncate table #rta_autorej
go


DECLARE @StartDt datetime = '8/11/2018 19:00'


insert into #rta_autorej
select distinct pktnum from EVENT_STATE_LOG1 where EventState = 'tRejectAutoServer' and tEventState >= @StartDt


DECLARE @LastCmpEvtLookbackHrs int = 8
DECLARE @ServerIP varchar(15) = (select ltrim(rtrim(Setting)) from SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'WSSIP')

select tAsn = a.tEventState, tRej = r.tEventState, rejSecs = DATEDIFF(second,a.tEventState,r.tEventState), a.EmpName, a.DeviceID, a.PktNum, e.EventDisplay,
       EmpLastCmpZone = le.Zone, EmpLastCmpLoc = le.Location, EvtZone = e.Zone, EvtLoc = e.Location, AutoRej_NoBeepVib = 1
  from EVENT4 as e WITH (NOLOCK)
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
   and v.PktNum in (select pktnum from #rta_autorej)
   and v.EventState in ('Display-NEW EVENT','BeepAssignedEvent','VibrateAssignedEvent','tReassignDisplayed')
  left join EVENT4 as le WITH (NOLOCK)
	on le.EmpNumComplete = a.EmpNum
   and le.tComplete < a.tEventState
   and le.tComplete > DATEADD(hour,@LastCmpEvtLookbackHrs*-1,a.tEventState)
   and le.PktNum in (select pktnum from #rta_autorej)
 where (a.EventState in ('tAssign','tAssignSupervisor','tReassign','ReassignAttendant','tReassignSupervisor'))
   and ((r.EventState in ('tRejectAutoServer')) or (r.EventState = 'tReject' and r.EmpName = @ServerIP))
   and not exists
     ( select null from EVENT_STATE_LOG1 as a2 WITH (NOLOCK)
	    where a2.PktNum = a.PktNum
		  and a2.EmpNum = a.EmpNum
		  and a2.EventState in ('tAssign','tAssignSupervisor','tReassign','ReassignAttendant','tReassignSupervisor')
		  and a2.tEventState > a.tEventState
		  and a2.tEventState < r.tEventState
		  and a2.PktNum in (select pktnum from #rta_autorej) )
   and not exists
	 ( select null from EVENT4 as le2 WITH (NOLOCK)
		where le2.EmpNumComplete = a.EmpNum
		  and le2.tComplete < a.tEventState
          and le2.tComplete > DATEADD(hour,@LastCmpEvtLookbackHrs*-1,a.tEventState)
		  and le2.tComplete > le.tComplete
		  and le2.PktNum in (select pktnum from #rta_autorej) )
   and v.PktNum is null
   and e.PktNum in (select pktnum from #rta_autorej)
   and a.PktNum in (select pktnum from #rta_autorej)
   and r.PktNum in (select pktnum from #rta_autorej)
