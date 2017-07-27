-- CHECK FOR DUPS
select SourceTable, SourceTableID, tOut, State, PktNum, COUNT(*) 
  from SQLA_FloorActivity
 where SourceTable in ('ALERT1','EVENT1','EVENT_STATE_LOG1')
 group by SourceTable, SourceTableID, tOut, State, PktNum
having COUNT(*) > 1

select SourceTable, SourceTableID2, SourceTableDttm1, SourceTableDttm2, COUNT(*) 
  from SQLA_FloorActivity
 where SourceTable in ('EMPLOYEEACTIVITY1')
 group by SourceTable, SourceTableID, SourceTableID2, SourceTableDttm1, SourceTableDttm2, tOut, State, PktNum
having COUNT(*) > 1


-- VERIFY - SQLA_FloorActivity / EVENT_STATE_LOG1 
select * from EVENT_STATE_LOG1 as l
 inner join EVENT1 as e
	on e.PktNum = l.PktNum
 where l.tEventState is not null and e.EventDisplay not in ('OOS','10 6')
   and l.EventState not in ('tRecd','tOut','tDisplay','tInitialResponse','tRemove','tComplete','tRejectAuto')
   and DATEDIFF(second,l.tEventState,GETDATE()) > 480 --state not in last 8 minutes
   and e.tOut >= '4/1/2016'
   and not exists (select null from SQLA_FloorActivity as f 
                    where f.SourceTable = 'EVENT_STATE_LOG1' and f.SourceTableID = l.SEQ)
 order by l.SEQ
 

-- VERIFY - SQLA_FloorActivity / EVENT1 
select * from EVENT1 as e
 where e.tOut is not null and e.EventDisplay not in ('OOS','10 6')
   and e.tOut >= '4/1/2016'
   and DATEDIFF(second,e.tComplete,GETDATE()) > 480 --not completed in last 8 minutes
   --and exists (select null from EVENT_STATE_LOG1 as l2 where l2.PktNum = e.PktNum)
   and not exists (select null from SQLA_FloorActivity as f 
                    where f.SourceTable = 'EVENT1' and f.SourceTableID = e.PktNum)
 order by e.PktNum


-- VERIFY SQLA_FloorActivity / ALERT1
select * from ALERT1 as a
 where alertType <> 'EVENT'
   and a.tCreate >= '4/1/2016'
   and not exists (select null from SQLA_FloorActivity as f 
                    where f.SourceTable = 'ALERT1' and f.SourceTableID = a.ID)
 order by ID desc


-- VERIFY SQLA_FloorActivity / EMPLOYEEACTIVITY1
select * from EMPLOYEEACTIVITY1 as a
 where tOut > '1/2/1980' and Activity not like 'REJECT%' and Activity not in ('MANUAL REJECT','')
   and tOut >= '4/1/2016'
   and not exists (select null from SQLA_FloorActivity as f 
                    where f.SourceTable = 'EMPLOYEEACTIVITY1'
                      and f.SourceTableID2 = a.CardNum
                      and f.SourceTableDttm1 = a.tOut
                      and f.SourceTableDttm2 = a.tIn)
order by tOut


-- VERIFY SQLA_EventDetails / EVENT1
select * from EVENT1 as e
 where (e.tOut is not NULL and isdate(e.tOut) = 1 and e.tOut > '1/2/1980')
   and (e.tComplete is not NULL and isdate(e.tComplete)=1 and e.tComplete >= e.tOut)
   and ((e.tAuthorize is not null and isdate(e.tAuthorize)=1 and e.tAuthorize > '1/2/1980') or (e.tAuthorize is null))
   and not exists (select null from SQLA_EventDetails as s where e.PktNum = s.PktNum)
   and DATEDIFF(second,e.tComplete,GETDATE()) > 480 --not completed in last 8 minutes
   and e.tOut >= '4/1/2016'
 order by PktNum desc


-- VERIFY SQLA_EmployeeCompliance / EVENT_STATE_LOG1
select *
  from EVENT_STATE_LOG1 as l
 inner join EVENT1 as e
	on e.PktNum = l.PktNum
 where e.tOut >= '4/1/2016'
   and DATEDIFF(second,l.tEventState,GETDATE()) > 480 --state not in last 8 minutes
   and l.EmpNum is not null and l.EmpNum <> '' and l.EmpName not in ('MGR CLEAR ALL')
   and l.EventState not in ('tDisplay','tInitialResponse','tRemove','tDisplayMobile')
   and not exists (select null from SQLA_EmployeeCompliance as c
                    where c.PktNum = l.PktNum and c.EmpNum = l.EmpNum)
					
select s.*
  from SYSTEMLOG1 as s
 inner join EVENT1 as e
    on s.EvtDetail1 = e.PktNum
 where EvtType = 'GetEvents' and (EvtDetail1 <> '-1' or EvtDetail2 <> '-1')
   and EvtTime >= '6/21/2016 13:30:00'
   and EvtNum not in 
     ( select SourceTableID from SQLA_FloorActivity
        where SourceTable = 'SYSTEMLOG1' )
 union all
select s.*
  from SYSTEMLOG1 as s
 inner join EVENT1 as e
    on s.EvtDetail2 = e.PktNum
 where EvtType = 'GetEvents' and (EvtDetail1 <> '-1' or EvtDetail2 <> '-1')
   and EvtTime >= '6/21/2016 13:30:00'
   and EvtNum not in 
     ( select SourceTableID from SQLA_FloorActivity
        where SourceTable = 'SYSTEMLOG1' )