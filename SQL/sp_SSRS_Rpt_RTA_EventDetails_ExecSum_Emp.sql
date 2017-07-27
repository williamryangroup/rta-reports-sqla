USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]    Script Date: 06/21/2016 11:45:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Emp]
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@EventType varchar(255) = '',
	@ZoneArea varchar(255) = '',
	@CustTier varchar(255) = '',
	@CustNum varchar(10) = '',
	@MinRspMins int = 0,
	@MinCmpMins int = 0,
	@MinOverallMins int = 0,
	@ResDesc int = 0,
	@EmpJobType nvarchar(2000) = '',
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1

WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @MaxCmpMins1 int = @MaxCmpMins
	DECLARE @EventType1 varchar(255) = @EventType
	DECLARE @ZoneArea1 varchar(255) = @ZoneArea
	DECLARE @CustTier1 varchar(255) = @CustTier
	DECLARE @CustNum1 varchar(10) = @CustNum
	DECLARE @MinRspMins1 int = @MinRspMins
	DECLARE @MinCmpMins1 int = @MinCmpMins
	DECLARE @MinOverallMins1 int = @MinOverallMins
	DECLARE @ResDesc1 int = @ResDesc
	
	
	-- CREATE TABLE OF JobTypes
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_EventDetails_ExecSum_Emp_JobTypes'))
    BEGIN
		drop table dbo.#RTA_EventDetails_ExecSum_Emp_JobTypes;
    END    
    
    create table #RTA_EventDetails_ExecSum_Emp_JobTypes (
		JobType nvarchar(20) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_EventDetails_ExecSum_Emp_JobTypes (JobType)
    select distinct left(ltrim(rtrim(val)),20) from dbo.fn_String_To_Table(@EmpJobType, ',', 1)
	
	
	CREATE TABLE dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 (
		CardNum nvarchar(20),
		EmpName nvarchar(255),
		Activity nvarchar(255),
		ActivityType int,
		ActivitySecs int,
		ActivityOrd int
	)
	
	INSERT INTO dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 (CardNum, EmpName, Activity, ActivityType, ActivitySecs, ActivityOrd)
	select EmpNum, EmpName = EmpNameFirst + ' ' + left(EmpNameLast,1) + '.',
	       Activity = case when PktNum in (1,2,3) then EventDisplay else 'Event' end,
	       ActivityType = case when PktNum in (1,2,3) then PktNum else 5 end,
	       ActivitySecs = SUM(ActivitySecs),
	       ActivityOrd = case when PktNum = 1 then 3 -- BREAK
	                          when PktNum = 2 then 4 -- OOS
	                          when PktNum = 3 then 1 -- Available
	                          when PktNum not in (1,2,3) then 2 end
	  from SQLA_EmployeeEventTimes as et
	 inner join SQLA_Employees as e
	    on e.CardNum = et.EmpNum
	 where ActivityStart >= @StartDt1 and ActivityStart < @EndDt1
	   and ((@IncludeOOS = 0 and PktNum not in (2)) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and ((@EmpJobType = '') or (@EmpJobType = 'All') or (@EmpJobType = EmpJobType))
	 group by EmpNum, EmpNameFirst, EmpNameLast,
	       case when PktNum in (1,2,3) then EventDisplay else 'Event' end,
	       case when PktNum in (1,2,3) then PktNum else 5 end,
	       case when PktNum = 1 then 3 -- BREAK
	            when PktNum = 2 then 4 -- OOS
	            when PktNum = 3 then 1 -- Available
	            when PktNum not in (1,2,3) then 2 end
	

	
	SELECT act.CardNum, act.EmpName, act.Activity, act.ActivityType, act.ActivitySecs, ActivityOrd
	  FROM dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 as act
	 WHERE act.ActivityType <> 3
	 UNION ALL
	SELECT act.CardNum, act.EmpName, act.Activity, act.ActivityType, ActivitySecs = act.ActivitySecs-SUM(isnull(act2.ActivitySecs,0)), act.ActivityOrd
	  FROM dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 as act
	  LEFT JOIN dbo.#RTA_EventDetails_ExecSum_Emp_Tmp2 as act2
	    ON act2.CardNum = act.CardNum
	   AND act2.ActivityType <> 3
	 WHERE act.ActivityType = 3
	 GROUP BY act.CardNum, act.EmpName, act.Activity, act.ActivityType, act.ActivitySecs, act.ActivityOrd
	
END








GO

