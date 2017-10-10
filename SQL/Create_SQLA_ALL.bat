@echo off

type Create_SQLA_AreaAssoc.sql > Create_SQLA_ALL.sql
type Create_SQLA_CardInReasons.sql >> Create_SQLA_ALL.sql
type Create_SQLA_CustTiers.sql >> Create_SQLA_ALL.sql
type Create_SQLA_EmpJobTypes.sql >> Create_SQLA_ALL.sql
type Create_SQLA_EmployeeCompliance.sql >> Create_SQLA_ALL.sql
type Create_SQLA_EmployeeEventTimes.sql >> Create_SQLA_ALL.sql
type Create_SQLA_Employees.sql >> Create_SQLA_ALL.sql
type Create_SQLA_EmployeeStatus.sql >> Create_SQLA_ALL.sql
type Create_SQLA_EventDetails.sql >> Create_SQLA_ALL.sql
type Create_SQLA_EventDetails_JPVER.sql >> Create_SQLA_ALL.sql
type Create_SQLA_EventTypes.sql >> Create_SQLA_ALL.sql
type Create_SQLA_FloorActivity.sql >> Create_SQLA_ALL.sql
type Create_SQLA_Locations.sql >> Create_SQLA_ALL.sql
type Create_SQLA_MEAL.sql >> Create_SQLA_ALL.sql
type Create_SQLA_New_EmpAct.sql >> Create_SQLA_ALL.sql
type Create_SQLA_New_Events.sql >> Create_SQLA_ALL.sql
type Create_SQLA_New_SEQ.sql >> Create_SQLA_ALL.sql
type Create_SQLA_ShiftHours.sql >> Create_SQLA_ALL.sql
type Create_SQLA_ZoneArea.sql >> Create_SQLA_ALL.sql

type fn_RemoveNonASCII.sql >> Create_SQLA_ALL.sql
type fn_String_To_Table.sql >> Create_SQLA_ALL.sql

type SQLAindexes.sql >> Create_SQLA_ALL.sql
