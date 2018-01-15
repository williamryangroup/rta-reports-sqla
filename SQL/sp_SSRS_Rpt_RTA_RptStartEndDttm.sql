USE [RTA_SQLA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_RptStartEndDttm]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_RptStartEndDttm]
GO

CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_RptStartEndDttm]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @StartDt as datetime = cast(cast(dateadd(day,-2,getdate()) as date) as datetime)
	DECLARE @StartTm as datetime = 0
	DECLARE @EndDt as datetime = dateadd(second,-1,cast(cast(dateadd(day,1,getdate()) as date) as datetime))
	DECLARE @EndTm as datetime = 0
	
	select @StartDt = cast(cast(DATEADD(day,cast(Setting as int),getdate()) as date) as datetime) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'RptParamInitStartDateDiff'
	select @StartTm = cast(Setting as datetime) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'RptParamInitStartTm'

	select @EndDt = cast(cast(DATEADD(day,cast(Setting as int),getdate()) as date) as datetime) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'RptParamInitEndDateDiff'
	select @EndTm = cast(Setting as datetime) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'RptParamInitEndTm'
	
	select StartDttm = @StartDt + @StartTm,
	       EndDttm = @EndDt + @EndTm
	
END
GO
