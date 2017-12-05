USE [RTA_SQLA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_ShowPaperOut]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_ShowPaperOut]
GO

CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_ShowPaperOut]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @ShowPaperOut int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'REPORTS' and ConfigParam = 'ShowPaperOut'),0)

	select ShowPaperOut = @ShowPaperOut
END
GO
