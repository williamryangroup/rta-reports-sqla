use RTA_SQLA
go

update SQLA_EmployeeCompliance set RspTmSec = RspTmSec - 3600 where tAsnMin < '3/12/2017 02:00:00' and tRspMin >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeCompliance set OverallTmSec = OverallTmSec - 3600 where tAsnMin < '3/12/2017 02:00:00' and dateadd(second,OverallTmSec,tAsnMin) >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeCompliance set tAsnMin = DATEADD(hour,-1,tAsnMin) where tOut < '3/12/2017 02:00:00' and tAsnMin >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeCompliance set tRspMin = DATEADD(hour,-1,tRspMin) where tOut < '3/12/2017 02:00:00' and tRspMin >= '3/12/2017 03:00:00'
go

update SQLA_EmployeeEventTimes set ActivitySecs = ActivitySecs - 3600 where ActivityStart < '3/12/2017 02:00:00' and ActivityEnd >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set tAsn = DATEADD(hour,-1,tAsn) where ActivityStart < '3/12/2017 02:00:00' and tAsn >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set tRea = DATEADD(hour,-1,tRea) where ActivityStart < '3/12/2017 02:00:00' and tRea >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set tDsp = DATEADD(hour,-1,tDsp) where ActivityStart < '3/12/2017 02:00:00' and tDsp >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set tAcp = DATEADD(hour,-1,tAcp) where ActivityStart < '3/12/2017 02:00:00' and tAcp >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set tRsp = DATEADD(hour,-1,tRsp) where ActivityStart < '3/12/2017 02:00:00' and tRsp >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set tRej = DATEADD(hour,-1,tRej) where ActivityStart < '3/12/2017 02:00:00' and tRej >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set tCmp = DATEADD(hour,-1,tCmp) where ActivityStart < '3/12/2017 02:00:00' and tCmp >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeEventTimes set ActivityEnd = DATEADD(hour,-1,ActivityEnd) where ActivityStart < '3/12/2017 02:00:00' and ActivityEnd >= '3/12/2017 03:00:00'
go

update SQLA_EventDetails set RspSecs = RspSecs - 3600 where tOut < '3/12/2017 02:00:00' and tAuthorize >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails set CmpSecs = CmpSecs - 3600 where tAuthorize < '3/12/2017 02:00:00' and tComplete >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails set TotSecs = TotSecs - 3600 where tOut < '3/12/2017 02:00:00' and tComplete >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails set tAssign = DATEADD(hour,-1,tAssign) where tOut < '3/12/2017 02:00:00' and tAssign >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails set tAccept = DATEADD(hour,-1,tAccept) where tOut < '3/12/2017 02:00:00' and tAccept >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails set tAuthorize = DATEADD(hour,-1,tAuthorize) where tOut < '3/12/2017 02:00:00' and tAuthorize >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails set tComplete = DATEADD(hour,-1,tComplete) where tOut < '3/12/2017 03:00:00' and tComplete >= '3/12/2017 03:00:00'
go

update SQLA_EventDetails_JPVER set tComplete = DATEADD(hour,-1,tComplete) where tOut < '3/12/2017 02:00:00' and tComplete >= '3/12/2017 03:00:00'
go

--SQLA_FloorActivity  -- no updates