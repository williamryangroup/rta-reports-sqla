update f set f.tOut = e.tComplete
--select * 
  from RTA_SQLA.dbo.SQLA_FloorActivity as f
 inner join RTA_SQLA.dbo.SQLA_EventDetails as e
    on e.PktNum = f.PktNum
 where f.ActivityTypeID = 2 and f.State = 'End'
   and e.EventDisplay = 'OOS' and e.tComplete <> f.tOut
   
update f set f.tOut = e.tOut
--select * 
  from RTA_SQLA.dbo.SQLA_FloorActivity as f
 inner join RTA_SQLA.dbo.SQLA_EventDetails as e
    on e.PktNum = f.PktNum
 where f.ActivityTypeID = 2 and f.State = 'Start'
   and e.EventDisplay = 'OOS' and e.tOut <> f.tOut