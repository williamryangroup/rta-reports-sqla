-- Zone changes
select t.EmpNum, t.EmpName, t.JobType, t.tStart, t.tEnd, Status = 'Zone: ' + z.ZoneArea
  from (
select s.EmpNum, s.EmpName, j.JobType, Activity = rtrim(s.Activity), tStart = s.tOut, tEnd = min(e.tOut)
  from SQLA_FloorActivity as s WITH (NOLOCK)
 inner join SQLA_FloorActivity as e WITH (NOLOCK)
    on e.EmpNum = s.EmpNum
   and e.tOut > s.tOut
  left join SQLA_Employees as j WITH (NOLOCK)
    on j.CardNum = s.EmpNum
 where (s.ActivityTypeID = 4 and s.Activity like 'Zones Served:%' and rtrim(s.Activity) <> 'Zones Served:')
   and ((e.ActivityTypeID = 4 and e.Activity like 'Zones Served:%') or (e.ActivityTypeID = 3 and e.State = 'Logout'))
 group by s.EmpNum, s.EmpName, j.JobType, s.Activity, s.tOut ) as t
 inner join (select distinct ZoneArea = rtrim(ZoneArea) from SQLA_ZoneArea WITH (NOLOCK)) as z
    on charindex(z.ZoneArea,t.Activity,13) > 0
 union all
/*
-- Login/Logout
select s.EmpNum, s.EmpName, j.JobType, tStart = s.tOut, tEnd = min(e.tOut), Status = 'Login/Logout'
  from SQLA_FloorActivity as s WITH (NOLOCK)
 inner join SQLA_FloorActivity as e WITH (NOLOCK)
    on e.EmpNum = s.EmpNum
   and e.tOut > s.tOut
  left join SQLA_Employees as j WITH (NOLOCK)
    on j.CardNum = s.EmpNum
 where (s.ActivityTypeID = 3 and s.State = 'Login')
   and (e.ActivityTypeID = 3 and e.State in ('Login','Logout'))
 group by s.EmpNum, s.EmpName, j.JobType, s.tOut
 union all
*/
-- Multi Event
select s.EmpNum, s.EmpName, j.JobType, tStart = s.tOut, tEnd = min(e.tOut), Status = 'Multi Event'
  from SQLA_FloorActivity as s WITH (NOLOCK)
 inner join SQLA_FloorActivity as e WITH (NOLOCK)
    on e.EmpNum = s.EmpNum
   and e.tOut > s.tOut
  left join SQLA_Employees as j WITH (NOLOCK)
    on j.CardNum = s.EmpNum
 where (s.ActivityTypeID = 4 and s.Activity = 'MULTI EVENT: YES')
   and ((e.ActivityTypeID = 4 and e.Activity = 'MULTI EVENT: NO') or (e.ActivityTypeID = 3 and e.State = 'Logout'))
 group by s.EmpNum, s.EmpName, j.JobType, s.tOut
 union all
 
-- JP Only
select s.EmpNum, s.EmpName, j.JobType, tStart = s.tOut, tEnd = min(e.tOut), Status = 'JP Only'
  from SQLA_FloorActivity as s WITH (NOLOCK)
 inner join SQLA_FloorActivity as e WITH (NOLOCK)
    on e.EmpNum = s.EmpNum
   and e.tOut > s.tOut
  left join SQLA_Employees as j WITH (NOLOCK)
    on j.CardNum = s.EmpNum
 where (s.ActivityTypeID = 4 and s.Activity = 'JP ONLY: YES')
   and ((e.ActivityTypeID = 4 and e.Activity = 'JP ONLY: NO') or (e.ActivityTypeID = 3 and e.State = 'Logout'))
 group by s.EmpNum, s.EmpName, j.JobType, s.tOut
 
 order by EmpNum, tStart, Status