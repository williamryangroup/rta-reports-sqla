use RTA_SQLA
go

select * from SQLA_EmployeeCompliance_DST
select * from SQLA_EventDetails_DST


update SQLA_EmployeeCompliance_DST set RspTmSec = RspTmSec - 3600 where RspTmSec > 3600
go
update SQLA_EmployeeCompliance_DST set OverallTmSec = OverallTmSec - 3600 where OverallTmSec > 3600
go
update SQLA_EmployeeCompliance_DST set tOut = DATEADD(hour,-1,tOut) where tOut >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeCompliance_DST set tAsnMin = DATEADD(hour,-1,tAsnMin) where tAsnMin >= '3/12/2017 03:00:00'
go
update SQLA_EmployeeCompliance_DST set tRspMin = DATEADD(hour,-1,tRspMin) where tRspMin >= '3/12/2017 03:00:00'
go

update SQLA_EventDetails_DST set RspSecs = RspSecs - 3600 where tOut < '3/12/2017 02:00:00' and tAuthorize >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails_DST set CmpSecs = CmpSecs - 3600 where tAuthorize < '3/12/2017 02:00:00' and tComplete >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails_DST set TotSecs = TotSecs - 3600 where tOut < '3/12/2017 02:00:00' and tComplete >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails_DST set tAssign = DATEADD(hour,-1,tAssign) where tOut < '3/12/2017 02:00:00' and tAssign >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails_DST set tAccept = DATEADD(hour,-1,tAccept) where tOut < '3/12/2017 02:00:00' and tAccept >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails_DST set tAuthorize = DATEADD(hour,-1,tAuthorize) where tOut < '3/12/2017 02:00:00' and tAuthorize >= '3/12/2017 03:00:00'
go
update SQLA_EventDetails_DST set tComplete = DATEADD(hour,-1,tComplete) where tOut < '3/12/2017 03:00:00' and tComplete >= '3/12/2017 03:00:00'
go


insert into RTA_SQLA.dbo.SQLA_EmployeeCompliance select * from RTA_SQLA.dbo.SQLA_EmployeeCompliance_DST
go
insert into RTA_SQLA.dbo.SQLA_EventDetails select * from RTA_SQLA.dbo.SQLA_EventDetails_DST
go
insert into RTA_SQLA.dbo.SQLA_FloorActivity select * from RTA_SQLA.dbo.SQLA_FloorActivity_DST
go