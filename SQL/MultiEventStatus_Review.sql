-- PARAMETERS
DECLARE @StartDttm datetime = '7/2/2017 00:00:00'
DECLARE @EndDttm datetime = '7/2/2017 23:59:59'

-- SUMMARY
select f.EmpNum, f.EmpName, e.JobType,
       ZoneChanges = sum(case when f.Activity like 'ZONES SERVED:%' then 1 else 0 end),
	   MultiEventOff = sum(case when f.Activity = 'MULTI EVENT: NO' then 1 else 0 end),
	   MultiEventOn = sum(case when f.Activity = 'MULTI EVENT: YES' then 1 else 0 end)
  from SQLA_FloorActivity as f
  left join SQLA_Employees as e
    on e.CardNum = f.EmpNum
 where f.ActivityTypeID in (4,0) and f.tOut >= @StartDttm and f.tOut <= @EndDttm
 group by f.EmpNum, f.EmpName, e.JobType
 order by e.JobType, f.EmpName

-- DETAILS
select * from SQLA_FloorActivity as f
 where f.ActivityTypeID in (4,0) and f.tOut >= @StartDttm and f.tOut <= @EndDttm
  and (f.Activity like 'ZONES SERVED:%' or f.Activity like 'MULTI EVENT:%')
  and EmpNum = '8667'
 order by tOut