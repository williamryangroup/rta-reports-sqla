-- Update JP AmtEvent
update d set d.AmtEvent = f.AmtEvent
  from SQLA_EventDetails as d
 inner join (select distinct PktNum, AmtEvent = RIGHT(Activity,LEN(Activity)-5)
               from SQLA_FloorActivity
              where ActivityTypeID = 5
                and (Activity like 'JKPT%' or Activity like 'PROG')
                and LEN(Activity) > 5) as f
    on f.PktNum = d.PktNum
 where EventDisplay in ('JKPT','PROG') and d.AmtEvent is null
go

update d set d.AmtEvent = f.AmtEvent
  from SQLA_EventDetails as d
 inner join (select distinct PktNum, AmtEvent = RIGHT(Activity,LEN(Activity)-3)
               from SQLA_FloorActivity
              where ActivityTypeID = 5
                and (Activity like 'JP%' or Activity like 'PG')
                and LEN(Activity) > 3) as f
    on f.PktNum = d.PktNum
 where EventDisplay in ('JP','PG') and d.AmtEvent is null
go


--Update Floor Activity
update SQLA_FloorActivity set State = 'Alert Open' where State = 'Alert'
update SQLA_FloorActivity set State = 'Display Reassign Popup' where State = 'Reassign Display Mobile'
update SQLA_FloorActivity set State = 'Re-assign' where State = 'Remove from Prior Event'
update SQLA_FloorActivity set State = 'Reassign Reject Manual' where State = 'Reassign Reject'
go


-- Update OOS times
update f set f.tOut = e.tComplete
--select * 
  from SQLA_FloorActivity as f
 inner join SQLA_EventDetails as e
    on e.PktNum = f.PktNum
 where f.ActivityTypeID = 2 and f.State = 'End'
   and e.EventDisplay = 'OOS' and e.tComplete <> f.tOut
go

update f set f.tOut = e.tOut
--select * 
  from SQLA_FloorActivity as f
 inner join SQLA_EventDetails as e
    on e.PktNum = f.PktNum
 where f.ActivityTypeID = 2 and f.State = 'Start'
   and e.EventDisplay = 'OOS' and e.tOut <> f.tOut
go



-- EmployeeEventTimes Initialize
exec sp_SQLA_Insert_EmployeeEventTimes_Initial @StartDt = '8/1/2016'
go



-- JPVER Initialize 

truncate table SQLA_EventDetails_JPVER
go

-- *** JP VER - OOS ***
insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
select e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, 'OOS', e.EmpNum, EmpName = e.EmpNameFirst + ' ' + e.EmpNameLast, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType
  from SQLA_EmployeeEventTimes as e
  left join SQLA_EventDetails_JPVER as j
    on j.PktNum = e.PktNum
 where e.EventDisplay = 'JP VER' and j.PktNum is null
go

-- *** JP VER - TknCmp ***
insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
select e.PktNum, EventDisplay = 'JP VER', tOut = e.tRsp, tComplete = e.tCmp, Source = 'TknCmp', e.EmpNum, EmpName = e.EmpNameFirst + ' ' + e.EmpNameLast, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType
  from SQLA_EmployeeEventTimes as e
  left join SQLA_EventDetails_JPVER as j
    on j.PktNum = e.PktNum
 where e.EventDisplay like 'JKPT%' and j.PktNum is null
   and ((e.tAsn is null and e.tRea is null) or (e.tAsn is not null and DATEDIFF(SECOND,e.tAsn,e.tRsp) <= 1))
   and e.tRsp is not null and e.tCmp is not null
go
   
update e set e.EventDisplay = j.EventDisplay
--select j.EventDisplay, e.*
  from SQLA_EventDetails as e
 inner join SQLA_EventDetails_JPVER as j
    on j.PktNum = e.PktNum
 where e.EventDisplay = 'OOS'
go