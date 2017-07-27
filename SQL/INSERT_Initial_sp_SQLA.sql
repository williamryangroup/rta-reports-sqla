use RTA_SQLA
go

exec sp_SQLA_Insert_AreaAssoc
go
exec sp_SQLA_Insert_CustTiers
go
exec sp_SQLA_Insert_EmpJobTypes
go
exec sp_SQLA_Insert_Employees
go
exec sp_SQLA_Insert_EventTypes
go
exec sp_SQLA_Insert_Locations
go
exec sp_SQLA_Insert_ShiftHours
go
exec sp_SQLA_Insert_ZoneArea
go

exec sp_SQLA_Insert_EmployeeCompliance_Initial @StartDt='1/1/2016'
go
exec sp_SQLA_Insert_FloorActivity_Initial @StartDt='1/1/2016'
go
exec sp_SQLA_Insert_EventDetails_Initial @StartDt='1/1/2016'
go
exec sp_SQLA_Insert_EmployeeEventTimes_Initial @StartDt='1/1/2016'
go
exec sp_SQLA_Insert_EventDetails_JPVER
go
