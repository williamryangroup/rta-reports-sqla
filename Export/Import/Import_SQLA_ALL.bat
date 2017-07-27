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
echo SQLA_EmployeeCompliance
dtexec /FILE "Import_SQLA_EmployeeCompliance.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EmployeeEventTimes
dtexec /FILE "Import_SQLA_EmployeeEventTimes.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventDetails
dtexec /FILE "Import_SQLA_EventDetails.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventDetails_JPVER
dtexec /FILE "Import_SQLA_EventDetails_JPVER.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_FloorActivity
dtexec /FILE "Import_SQLA_FloorActivity.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E


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
