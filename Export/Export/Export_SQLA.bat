@echo off

E:
cd E:\RTSS\SQLA_Exports

REM Run export scripts
echo.
echo Running export scripts...
echo.
echo SQLA_AreaAssoc
dtexec /FILE "Export_SQLA_AreaAssoc_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_CustTiers
dtexec /FILE "Export_SQLA_CustTiers_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EmpJobTypes
dtexec /FILE "Export_SQLA_EmpJobTypes_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_Employees
dtexec /FILE "Export_SQLA_Employees_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventTypes
dtexec /FILE "Export_SQLA_EventTypes_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_Locations
dtexec /FILE "Export_SQLA_Locations_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_ShiftHours
dtexec /FILE "Export_SQLA_ShiftHours_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_ZoneArea
dtexec /FILE "Export_SQLA_ZoneArea_ALL.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E

echo.
echo SQLA_EmployeeCompliance
dtexec /FILE "Export_SQLA_EmployeeCompliance.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EmployeeEventTimes
dtexec /FILE "Export_SQLA_EmployeeEventTimes.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventDetails
dtexec /FILE "Export_SQLA_EventDetails.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_EventDetails_JPVER
dtexec /FILE "Export_SQLA_EventDetails_JPVER.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E
echo.
echo SQLA_FloorActivity
dtexec /FILE "Export_SQLA_FloorActivity.dtsx" /MAXCONCURRENT " -1 " /CHECKPOINTING OFF /REPORTING E


REM Update SYSTEMSETTINGS/SqlaLastExportDttm
echo.
echo Delete SYSTEMSETTINGS/SqlaLastExportDttm
sqlcmd -E -S localhost -d RTSS -Q "delete from RTSS.dbo.SYSTEMSETTINGS where ConfigSection='REPORTS' and ConfigParam='SqlaLastExportDttm'"
echo.
echo Insert SYSTEMSETTINGS/SqlaLastExportDttm
sqlcmd -E -S localhost -d RTSS -Q "insert into RTSS.dbo.SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','SqlaLastExportDttm',convert(char(255), GETDATE(),120))"



REM Set datetime variables
FOR /F "tokens=1-4 delims=/- " %%A IN ("%date%") DO (
  set mm=%%B
  set dd=%%C
  set yyyy=%%D
)

set yyyymmdd=%yyyy%%mm%%dd%

FOR /F "tokens=1-4 delims=:." %%A IN ("%time%") DO (
  set hh=%%A
  set mm=%%B
  set ss=%%C
)

set hhmmss=%hh%%mm%%ss%
set yyyymmdd_hhmmss=%yyyymmdd%_%hhmmss%



REM Add today's date to end of CSV files
echo.
echo Adding date to end of file names...
move SQLA_AreaAssoc_ALL.csv SQLA_AreaAssoc_ALL_%yyyymmdd_hhmmss%.csv >nul
move SQLA_CustTiers_ALL.csv SQLA_CustTiers_ALL_%yyyymmdd_hhmmss%.csv >nul
move SQLA_EmpJobTypes_ALL.csv SQLA_EmpJobTypes_ALL_%yyyymmdd_hhmmss%.csv >nul
move SQLA_Employees_ALL.csv SQLA_Employees_ALL_%yyyymmdd_hhmmss%.csv >nul
move SQLA_EventTypes_ALL.csv SQLA_EventTypes_ALL_%yyyymmdd_hhmmss%.csv >nul
move SQLA_Locations_ALL.csv SQLA_Locations_ALL_%yyyymmdd_hhmmss%.csv >nul
move SQLA_ShiftHours_ALL.csv SQLA_ShiftHours_ALL_%yyyymmdd_hhmmss%.csv >nul
move SQLA_ZoneArea_ALL.csv SQLA_ZoneArea_ALL_%yyyymmdd_hhmmss%.csv >nul

move SQLA_EmployeeCompliance.csv SQLA_EmployeeCompliance_%yyyymmdd_hhmmss%.csv >nul
move SQLA_EmployeeEventTimes.csv SQLA_EmployeeEventTimes_%yyyymmdd_hhmmss%.csv >nul
move SQLA_EventDetails.csv SQLA_EventDetails_%yyyymmdd_hhmmss%.csv >nul
move SQLA_EventDetails_JPVER.csv SQLA_EventDetails_JPVER_%yyyymmdd_hhmmss%.csv >nul
move SQLA_FloorActivity.csv SQLA_FloorActivity_%yyyymmdd_hhmmss%.csv >nul


REM Delete files older than 30 days
echo.
echo Deleting CSV files older than 30 days...
forfiles /p "E:\RTSS\SQLA_Exports" /s /m *.csv /c "cmd /c Del @path" /d -30
echo.
echo Deleting ZIP files older than 30 days...
forfiles /p "E:\RTSS\SQLA_Exports" /s /m *.zip /c "cmd /c Del @path" /d -30
