USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Ameristar_DailyRpt]    Script Date: 07/26/2016 06:26:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Ameristar_DailyRpt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Ameristar_DailyRpt]
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE sp_SSRS_Rpt_RTA_Ameristar_DailyRpt
	@ReportDttm datetime,
	@MaxCmpMins int = 120,
	@IncludeOOS int = 0,
	@IncludeEMPCARD int = 0,
	@RspMins int = 2
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @ReportDttm = cast(cast(@ReportDttm as date) as datetime)
	DECLARE @StartDt datetime = dateadd(hour, 8, @ReportDttm)
	DECLARE @EndDt datetime = dateadd(hour, 24, @StartDt)
	DECLARE @RspSecs int = @RspMins * 60

	select t.ShiftName, t.ShiftOrder, t.ShiftHour, t.tOutDt, t.EmpCount, t.EvtCount, t.EvtCountGTRsp,
	       GamesInPlay = sum(q.GamesInPlay), CoinIn = sum(q.CoinIn)
	  from (
    select ShiftName, ShiftOrder = ShiftColumn, ShiftHour = StartHour, tOutDt = cast(tOut as date),
	       EmpCount = count(distinct (case when d.EmpJobTypeCmp = 'Attendant' then EmpNumCmp else null end)),
		   EvtCount = count(*),
		   EvtCountGTRsp = sum(case when RspSecs >= @RspSecs then 1 else 0 end)
	  from SQLA_EventDetails as d
	  left join SQLA_ShiftHours as s
	    on s.StartHour = datepart(hour,tOut)
	 where tOut >= @StartDt and tOut < @EndDt
	   and (TotSecs*1.0/60.0) <= @MaxCmpMins
	   and ((@IncludeOOS = 0 and EventDisplay not in ('OOS','10 6')) or (@IncludeOOS = 1))
	   and ((@IncludeEMPCARD = 0 and EventDisplay not in ('EMPCARD')) or (@IncludeEMPCARD = 1))
	 group by ShiftName, ShiftColumn, StartHour, cast(tOut as date) ) as t
	  left join SQLA_Quartile_MachineData as q
	    on cast(q.QuartileDTTM as date) = tOutDt
	   and q.QuartileHr = ShiftHour
	 group by t.ShiftName, t.ShiftOrder, t.ShiftHour, t.tOutDt, t.EmpCount, t.EvtCount, t.EvtCountGTRsp

END
GO
