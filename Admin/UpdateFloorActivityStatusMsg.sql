update SQLA_FloorActivity
   set State = 'Alert Open'
--select * from SQLA_FloorActivity
 where State = 'Alert'

update SQLA_FloorActivity
   set State = 'Display Reassign Popup'
--select * from SQLA_FloorActivity
 where State = 'Reassign Display Mobile'

update SQLA_FloorActivity
   set State = 'Re-assign'
--select * from SQLA_FloorActivity
 where State = 'Remove from Prior Event'

update SQLA_FloorActivity
   set State = 'Reassign Reject Manual'
--select * from SQLA_FloorActivity
 where State = 'Reassign Reject'