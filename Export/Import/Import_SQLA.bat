@echo off

E:
cd E:\RTSS\SQLA_Import


REM Rename CSV files for use with import scripts
echo.
echo Renaming CSV files for use with import scripts...
echo.
ren SQLA_AreaAssoc_*.csv SQLA_AreaAssoc.csv
ren SQLA_CustTiers_*.csv SQLA_CustTiers.csv
ren SQLA_EmpJobTypes_*.csv SQLA_EmpJobTypes.csv
ren SQLA_Employees_*.csv SQLA_Employees.csv
ren SQLA_EventTypes_*.csv SQLA_EventTypes.csv
ren SQLA_Locations_*.csv SQLA_Locations.csv
ren SQLA_ShiftHours_*.csv SQLA_ShiftHours.csv
ren SQLA_ZoneArea_*.csv SQLA_ZoneArea.csv

ren SQLA_EmployeeCompliance_*.csv SQLA_EmployeeCompliance.csv
ren SQLA_EmployeeEventTimes_*.csv SQLA_EmployeeEventTimes.csv
ren SQLA_EventDetails_JPVER_*.csv SQLA_EventDetailsJPVER.csv
ren SQLA_EventDetails_*.csv SQLA_EventDetails.csv
ren SQLA_FloorActivity_*.csv SQLA_FloorActivity.csv


REM Run import scripts
echo.
echo Running import scripts...
echo.
echo SQLA_AreaAssoc
dtexec /FILE "Import_SQLA_AreaAssoc.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_CustTiers
dtexec /FILE "Import_SQLA_CustTiers.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EmpJobTypes
dtexec /FILE "Import_SQLA_EmpJobTypes.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_Employees
dtexec /FILE "Import_SQLA_Employees.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventTypes
dtexec /FILE "Import_SQLA_EventTypes.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_Locations
dtexec /FILE "Import_SQLA_Locations.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_ShiftHours
dtexec /FILE "Import_SQLA_ShiftHours.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_ZoneArea
dtexec /FILE "Import_SQLA_ZoneArea.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E

echo.
echo SQLA_EmployeeCompliance_Stage
dtexec /FILE "Import_SQLA_EmployeeCompliance_Stage.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EmployeeEventTimes_Stage
dtexec /FILE "Import_SQLA_EmployeeEventTimes_Stage.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventDetails_Stage
dtexec /FILE "Import_SQLA_EventDetails_Stage.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventDetails_JPVER_Stage
dtexec /FILE "Import_SQLA_EventDetails_JPVER_Stage.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_FloorActivity_Stage
dtexec /FILE "Import_SQLA_FloorActivity_Stage.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E


REM Move data from stage tables
echo.
echo Moving data from stage tables...
echo.
echo SQLA_EmployeeCompliance
sqlcmd -E -S localhost -d RTSS -Q "insert into SQLA_EmployeeCompliance select * from SQLA_EmployeeCompliance_Stage as s where not exists (select null from SQLA_EmployeeCompliance as d where d.EmpNum = s.EmpNum and d.PktNum = s.PktNum)"
echo.
echo SQLA_EmployeeEventTimes
sqlcmd -E -S localhost -d RTSS -Q "insert into SQLA_EmployeeEventTimes select * from SQLA_EmployeeEventTimes_Stage as s where not exists (select null from SQLA_EmployeeEventTimes as d where d.EmpNum = s.EmpNum and d.PktNum = s.PktNum and d.ActivityStart = s.ActivityStart)"
echo.
echo SQLA_EventDetails
sqlcmd -E -S localhost -d RTSS -Q "insert into SQLA_EventDetails select * from SQLA_EventDetails_Stage as s where not exists (select null from SQLA_EventDetails as d where d.PktNum = s.PktNum)"
echo.
echo SQLA_EventDetails_JPVER
sqlcmd -E -S localhost -d RTSS -Q "insert into SQLA_EventDetails_JPVER select * from SQLA_EventDetails_JPVER_Stage as s where not exists (select null from SQLA_EventDetails_JPVER as d where d.PktNum = s.PktNum)"
echo.
echo SQLA_FloorActivity
sqlcmd -E -S localhost -d RTSS -Q "insert into SQLA_FloorActivity select * from SQLA_FloorActivity_Stage as s where not exists (select null from SQLA_FloorActivity as d where d.SourceTable = s.SourceTable and d.SourceTableID = s.SourceTableID and d.SourceTableID2 = s.SourceTableID2 and d.SourceTableDttm1 = s.SourceTableDttm1 and d.SourceTableDttm2 = s.SourceTableDttm2)"


REM Truncate stage data
echo.
echo Truncating stage tables...
echo.
sqlcmd -E -S localhost -d RTSS -Q "truncate table SQLA_EmployeeCompliance_Stage"
sqlcmd -E -S localhost -d RTSS -Q "truncate table SQLA_EmployeeEventTimes_Stage"
sqlcmd -E -S localhost -d RTSS -Q "truncate table SQLA_EventDetails_Stage"
sqlcmd -E -S localhost -d RTSS -Q "truncate table SQLA_EventDetails_JPVER_Stage"
sqlcmd -E -S localhost -d RTSS -Q "truncate table SQLA_FloorActivity_Stage"


REM Reindex SQLA tables
echo.
echo Indexing SQLA tables...
echo.
sqlcmd -E -S localhost -i E:\RTSS\SQLA_Import\SQLAindexes.sql


REM Shrink DB
echo.
echo Shrinking RTSS database...
echo.
sqlcmd -E -S localhost -d RTSS -Q "DBCC SHRINKDATABASE (RTSS,10,TRUNCATEONLY)"
sqlcmd -E -S localhost -d RTSS -Q "DBCC SHRINKDATABASE(RTSS)"
