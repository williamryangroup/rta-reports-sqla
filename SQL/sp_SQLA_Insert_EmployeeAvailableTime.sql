USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EmployeeAvailableTime]    Script Date: 07/16/2016 04:27:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EmployeeAvailableTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EmployeeAvailableTime]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EmployeeAvailableTime]
		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @StartDt datetime = (select max(AvailableEnd) from SQLA_EmployeeAvailableTime)

	-- Time available between RTA login and first activity
	insert into SQLA_EmployeeAvailableTime
	select a.EmpNum, a.EmpNameFirst, a.EmpNameLast, a.EmpJobType, 
		   AvailableStart = a.ActivityStart, AvailableEnd = isnull(b.ActivityStart,a.ActivityEnd),
		   AvailableSecs = datediff(second,a.ActivityStart,isnull(b.ActivityStart,a.ActivityEnd))
	  from SQLA_EmployeeEventTimes as a
	  left join SQLA_EmployeeEventTimes as b
		on b.EmpNum = a.EmpNum
	   and b.ActivityStart < a.ActivityEnd     
	   and b.ActivityStart >= a.ActivityStart  
	   and b.PktNum <> 3
	 where a.ActivityEnd > @StartDt and a.PktNum = 3
	   and not exists 
	     ( select null from SQLA_EmployeeEventTimes as b1
		    where b1.EmpNum = a.EmpNum
			  and b1.ActivityStart < a.ActivityStart
			  and b1.ActivityEnd > a.ActivityStart
			  and b1.PktNum <> 3 )
	   and not exists 
		 ( select null from SQLA_EmployeeEventTimes as b2
			where b2.EmpNum = a.EmpNum
			  and b2.ActivityStart < a.ActivityEnd
			  and b2.ActivityStart >= a.ActivityStart
			  and b2.PktNum <> 3
			  and b2.ActivityStart < b.ActivityStart )

	-- Time available between activities activity
	insert into SQLA_EmployeeAvailableTime
	select b.EmpNum, b.EmpNameFirst, b.EmpNameLast, b.EmpJobType, max(b.ActivityEnd), b2.ActivityStart,
	       AvailSecs = datediff(second,max(b.ActivityEnd),b2.ActivityStart)
	  from SQLA_EmployeeEventTimes as a
	 inner join SQLA_EmployeeEventTimes as b
		on b.EmpNum = a.EmpNum
	   and b.ActivityStart < a.ActivityEnd
	   and b.ActivityEnd >= a.ActivityStart
	 inner join SQLA_EmployeeEventTimes as b2
		on b2.EmpNum = a.EmpNum
	   and b2.ActivityStart < a.ActivityEnd
	   and b2.ActivityEnd >= a.ActivityStart
	   and b2.ActivityStart > b.ActivityEnd
	 where a.ActivityEnd > @StartDt and a.PktNum = 3 and b.PktNum <> 3 and b2.PktNum <> 3
	   and not exists
	     ( select null from SQLA_EmployeeEventTimes as b1
		    where b1.EmpNum = a.EmpNum
			  and b1.ActivityStart < a.ActivityEnd
			  and b1.ActivityEnd >= a.ActivityStart
			  and b1.ActivityStart > b.ActivityStart
			  and b1.ActivityStart < b.ActivityEnd
			  and b1.PktNum <> 3 )
	   and not exists 
		 ( select null from SQLA_EmployeeEventTimes as b3
			where b3.EmpNum = a.EmpNum
			  and b3.ActivityStart < a.ActivityEnd
			  and b3.ActivityEnd >= a.ActivityStart
			  and b3.ActivityStart > b.ActivityEnd
			  and b3.ActivityStart < b2.ActivityStart
			  and b3.PktNum <> 3 )
	 group by b.EmpNum, b.EmpNameFirst, b.EmpNameLast, b.EmpJobType, b2.ActivityStart

	-- Time available between activity and RTA logout
	insert into SQLA_EmployeeAvailableTime
	select a.EmpNum, a.EmpNameFirst, a.EmpNameLast, a.EmpJobType, 
		   AvailStart = b.ActivityEnd, AvailEnd = a.ActivityEnd,
		   AvailSecs = datediff(second,b.ActivityEnd,a.ActivityEnd)
	  from SQLA_EmployeeEventTimes as a
	 inner join SQLA_EmployeeEventTimes as b
		on b.EmpNum = a.EmpNum
	   and b.ActivityEnd >= a.ActivityStart  
	   and b.ActivityEnd < a.ActivityEnd     
	 where a.ActivityEnd > @StartDt and a.PktNum = 3 and b.PktNum <> 3
	   and not exists 
	     ( select null from SQLA_EmployeeEventTimes as b1
		    where b1.EmpNum = a.EmpNum
			  and b1.ActivityStart < a.ActivityEnd
			  and b1.ActivityEnd > a.ActivityEnd
			  and b1.PktNum <> 3 )
	   and not exists 
		 ( select null from SQLA_EmployeeEventTimes as b2
			where b2.EmpNum = a.EmpNum
			  and b2.ActivityEnd >= a.ActivityStart
			  and b2.ActivityEnd < a.ActivityEnd
			  and b2.PktNum <> 3
			  and b2.ActivityStart > b.ActivityStart )
	

	delete a
	  from SQLA_EmployeeAvailableTime as a
	 inner join SQLA_EmployeeEventTimes as b
		on b.EmpNum = a.EmpNum
	   and b.ActivityStart <= a.AvailableStart
	   and b.ActivityEnd >= a.AvailableEnd
	 where b.PktNum <> 3
	 
	update a 
	   set AvailableStart = ActivityEnd
	  from SQLA_EmployeeAvailableTime as a
	 inner join SQLA_EmployeeEventTimes as b
		on b.EmpNum = a.EmpNum
	   and b.ActivityStart < a.AvailableEnd
	   and b.ActivityEnd > a.AvailableStart
	 where b.PktNum <> 3

	update SQLA_EmployeeAvailableTime
	   set AvailableSecs = DATEDIFF(second,AvailableStart,AvailableEnd)
	 where DATEDIFF(second,AvailableStart,AvailableEnd) <> AvailableSecs
	
END


GO


