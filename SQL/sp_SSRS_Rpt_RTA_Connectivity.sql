USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Connectivity]    Script Date: 06/21/2016 11:24:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Connectivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Connectivity]
GO


CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Connectivity]
	@StartDt datetime,
	@EndDt datetime

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	select DayHour, /*q.EmpNum, q.DeviceID, EmpName = '(' + left(emp.JobType,1) + ') ' + RTRIM(emp.NameFirst) + ' ' + LEFT(emp.NameLast,1) + '.',*/
		   AsnCount = sum(q.AsnCount),
		   AsnNoBeepVibCount = sum(q.AsnNoBeepVibCount),
		   LoginCount = sum(q.LoginCount),
		   LogoutCount = sum(q.LogoutCount),
		   RejAutoServerCount = sum(RejAutoServerCount),
		   GetEvtCount = sum(GetEvtCount),
		   EvtCount = sum(EvtCount)
	 from (
 
	-- EvtCount
	select DayHour = dateadd(hour,datepart(hour,a.tOut),cast(cast(a.tOut as date) as datetime)),
		   EmpNum='', DeviceID = '',
		   AsnCount = 0,
		   AsnNoBeepVibCount = 0,
		   LoginCount = 0,
		   LogoutCount = 0,
		   RejAutoServerCount = 0,
		   GetEvtCount = 0,
		   MinsLoggedIn = 0,
		   FirstLogin = null,
		   LastLogout = null,
		   EvtCount = count(distinct PktNum)
	  from SQLA_FloorActivity as a WITH (NOLOCK)
	 where ActivityTypeID = 5
	   and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor')
	   and tOut >= @StartDt and tOut < @EndDt
	 group by dateadd(hour,datepart(hour,a.tOut),cast(cast(a.tOut as date) as datetime))
	 union all
 
	-- AsnCount / RejAutoServerCount / GetEvtCount
	select DayHour = dateadd(hour,datepart(hour,a.tOut),cast(cast(a.tOut as date) as datetime)),
		   a.EmpNum, DeviceID = a.Source,
		   AsnCount = sum(case when State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor') then 1 else 0 end),
		   AsnNoBeepVibCount = 0,
		   LoginCount = 0,
		   LogoutCount = 0,
		   RejAutoServerCount = sum(case when State = 'Reject Auto Server' then 1 else 0 end),
		   GetEvtCount = sum(case when State = 'Get Event' then 1 else 0 end),
		   MinsLoggedIn = 0,
		   FirstLogin = null,
		   LastLogout = null,
		   EvtCount = 0
	  from SQLA_FloorActivity as a WITH (NOLOCK)
	 where ActivityTypeID = 5
	   and State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor',
	                 'Reject Auto Server',
					 'Get Event')
	   and tOut >= @StartDt and tOut < @EndDt
	 group by dateadd(hour,datepart(hour,a.tOut),cast(cast(a.tOut as date) as datetime)), a.EmpNum, a.Source
	 union all
 
	-- AsnNoBeepVibCount
	select DayHour = dateadd(hour,datepart(hour,a.tOut),cast(cast(a.tOut as date) as datetime)),
		   a.EmpNum, a.Source, 
		   AsnCount = 0,
		   AsnNoBeepVibCount = count(*),
		   LoginCount = 0,
		   LogoutCount = 0,
		   RejAutoServerCount = 0,
		   GetEvtCount = 0,
		   MinsLoggedIn = 0,
		   FirstLogin = null,
		   LastLogout = null,
		   EvtCount = 0
	  from SQLA_FloorActivity as a WITH (NOLOCK)
	 inner join SQLA_FloorActivity as r WITH (NOLOCK)
		on r.PktNum = a.PktNum
	   and r.EmpNum = a.EmpNum
	   and r.tOut > a.tOut
	  left join SQLA_FloorActivity as v WITH (NOLOCK)
		on v.PktNum = a.PktNum
	   and v.EmpNum = a.EmpNum
	   and v.tOut > a.tOut
	   and v.tOut < r.tOut
	   and v.ActivityTypeID = 5 and v.State in ('Display-NEW EVENT','BeepAssignedEvent','VibrateAssignedEvent','Display Reassign Popup')
	 where a.ActivityTypeID = 5 and a.State in ('Assign','Assign Supervisor','Re-assign','Reassign Attendant','Reassign Supervisor')
	   and r.ActivityTypeID = 5 and r.State = 'Reject Auto Server'
	   and a.tOut >= @StartDt and a.tOut < @EndDt
	   and v.PktNum is null
	 group by dateadd(hour,datepart(hour,a.tOut),cast(cast(a.tOut as date) as datetime)), a.EmpNum, a.Source
	 union all
 
	-- Login Counts
	select DayHour = dateadd(hour,datepart(hour,ea.tOut),cast(cast(ea.tOut as date) as datetime)),
		   ea.EmpNum, ea.Source, 
		   AsnCount = 0,
		   AsnNoBeepVibCount = 0,
		   LoginCount = sum(case when ea.State = 'Login' then 1 else 0 end),
		   LogoutCount = sum(case when ea.State = 'Logout' then 1 else 0 end),
		   RejAutoServerCount = 0,
		   GetEvtCount = 0,
		   MinsLoggedIn = 0,
		   FirstLogin = null,
		   LastLogout = null,
		   EvtCount = 0
	  from SQLA_FloorActivity as ea WITH (NOLOCK)
	 where ea.ActivityTypeID = 3 
	   and (ea.State = 'Login' or ea.State = 'Logout')
	   and ea.tOut >= @StartDt and ea.tOut < @EndDt
	 group by dateadd(hour,datepart(hour,ea.tOut),cast(cast(ea.tOut as date) as datetime)), EmpNum, Source

		 ) as q
	  left join SQLA_Employees as emp WITH (NOLOCK)
		on emp.CardNum = q.EmpNum
	 group by q.DayHour/*, q.EmpNum, q.DeviceID, emp.JobType, emp.NameFirst, emp.NameLast*/

END


GO