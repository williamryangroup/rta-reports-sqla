USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EventDetails_JPVER]    Script Date: 10/04/2016 11:49:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EventDetails_JPVER]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EventDetails_JPVER]
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EventDetails_JPVER]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- *** JP VER - tJackpotVerify ***
	insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
	select v.PktNum, EventDisplay = 'JP VER', min(v.tOut), tComplete = d.tComplete, Source = 'tJackpotVerify', v.EmpNum, v.EmpName, e.NameFirst, e.NameLast, e.JobType
	  from SQLA_FloorActivity as v
	  left join SQLA_EventDetails as d
		on d.PktNum = v.PktNum
	  left join SQLA_Employees as e
		on e.CardNum = v.EmpNum
	  left join SQLA_EventDetails_JPVER as v2
	    on v2.PktNum = v.PktNum
	   and v2.Source = 'tJackpotVerify'
	   and v2.tOut = v.tOut
	 where v2.PktNum is null and v.State in ('tJackpotVerify','Jackpot Verify')
	 group by v.PktNum, d.tComplete, v.EmpNum, v.EmpName, e.NameFirst, e.NameLast, e.JobType
	
	/*
	-- *** JP VER - OOS ***
	insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
	select e.PktNum, e.EventDisplay, e.ActivityStart, e.ActivityEnd, 'OOS', e.EmpNum, EmpName = e.EmpNameFirst + ' ' + e.EmpNameLast, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType
	  from SQLA_EmployeeEventTimes as e
	  left join SQLA_EventDetails_JPVER as j
		on j.PktNum = e.PktNum
	 where e.EventDisplay = 'JP VER' and j.PktNum is null
	*/

	-- *** JP VER - TknCmp ***
	insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
	select e.PktNum, EventDisplay = 'JP VER', tOut = e.tRsp, tComplete = e.tCmp, Source = 'TknCmp', e.EmpNum, EmpName = e.EmpNameFirst + ' ' + e.EmpNameLast, e.EmpNameFirst, e.EmpNameLast, e.EmpJobType
	  from SQLA_EmployeeEventTimes as e
	  left join SQLA_EventDetails_JPVER as j
		on j.PktNum = e.PktNum
	 where e.EventDisplay like 'JKPT%' and j.PktNum is null
	   and ((e.tAsn is null and e.tRea is null) or (e.tAsn is not null and DATEDIFF(SECOND,e.tAsn,e.tRsp) <= 1))
	   and e.tRsp is not null and e.tCmp is not null
	   
	/*
	update e
	   set e.EventDisplay = j.EventDisplay
	--select j.EventDisplay, e.*
	  from SQLA_EventDetails as e
	 inner join SQLA_EventDetails_JPVER as j
		on j.PktNum = e.PktNum
	 where e.EventDisplay = 'OOS'
	*/
	
	-- *** JP VER - AcpRsp ***
	insert into SQLA_EventDetails_JPVER (PktNum, EventDisplay, tOut, tComplete, Source, EmpNum, EmpName, EmpNameFirst, EmpNameLast, EmpJobType)
	select v.PktNum, v.EventDisplay, o.tOut, tComplete = case when v.tOut < o.tComplete then v.tOut else o.tComplete end,
		   Source = 'AcpRsp', v.EmpNum, v.EmpName, v.EmpNameFirst, v.EmpNameLast, v.EmpJobType
	  from SQLA_EventDetails_JPVER as v  -- JP VER
	 inner join SQLA_EventDetails as j   -- JP
		on v.PktNum = j.PktNum
	 inner join SQLA_EventDetails as o   -- OOS for EmpNum started between JP start and JP VER start
		on o.EmpNumAsn = v.EmpNum
	   and o.tOut >= j.tOut  -- JP start
	   and o.tOut < v.tOut   -- JP VER start
	   and o.PktNum in (select PktNum from SQLA_FloorActivity where Activity = 'OOS - 1. Jackpot Verify')
	  left join SQLA_EventDetails_JPVER as v2
	    on v2.PktNum = v.PktNum
	   and v2.Source = v.Source
	   and v2.tOut = v.tOut
	 where v2.PktNum is null
	   and not exists
		 ( select null from SQLA_EventDetails as o2
			where o2.EmpNumAsn = v.EmpNum
			  and o2.tOut >= j.tOut
			  and o2.tOut < v.tOut
			  and o2.tout > o.tout )
 
END

GO

