USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_LVSSvcTm]    Script Date: 02/17/2016 21:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_LVSSvcTm]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_LVSSvcTm]
GO

CREATE PROCEDURE sp_SSRS_Rpt_RTA_EventDetails_LVSSvcTm
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	select EvtMonth = dateadd(day,-day(tOut)+1,cast(cast(tOut as date) as datetime)),
	       EventTypes = 'All',
		   AvgRspSecs = avg(case when RspSecs > 0 then RspSecs else null end),
		   AvgCmpSecs = avg(case when CmpSecs > 0 then CmpSecs else null end),
		   AvgTotSecs = avg(case when TotSecs > 0 then TotSecs else null end),
	       EvtCount = count(*)
	  from SQLA_EventDetails as d
	 where tOut >= @StartDt and tOut < @EndDt
	   and (TotSecs*1.0/60.0) <= @MaxCmpMins
	   and ((@IncludeOOS = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	 group by dateadd(day,-day(tOut)+1,cast(cast(tOut as date) as datetime))
	 union all
	select EvtMonth = dateadd(day,-day(tOut)+1,cast(cast(tOut as date) as datetime)),
	       EventTypes = 'JP',
		   AvgRspSecs = avg(case when RspSecs > 0 then RspSecs else null end),
		   AvgCmpSecs = avg(case when CmpSecs > 0 then CmpSecs else null end),
		   AvgTotSecs = avg(case when TotSecs > 0 then TotSecs else null end),
	       EvtCount = count(*)
	  from SQLA_EventDetails as d
	 where (tOut >= @StartDt and tOut < @EndDt)
	   and (TotSecs*1.0/60.0) <= @MaxCmpMins
	   and ((@IncludeOOS = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	   and (EventDisplay in ('JP','JKPT','PROG','PJ'))
	 group by dateadd(day,-day(tOut)+1,cast(cast(tOut as date) as datetime))
	 order by dateadd(day,-day(tOut)+1,cast(cast(tOut as date) as datetime))

END
GO
