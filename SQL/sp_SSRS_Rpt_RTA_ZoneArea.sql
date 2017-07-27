USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_ZoneArea]    Script Date: 04/21/2016 13:08:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_ZoneArea]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_ZoneArea]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_ZoneArea] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ZonesAreNumeric int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZonesAreNumeric'),0)
	
	IF @ZonesAreNumeric = 1
	BEGIN
		select * from SQLA_ZoneArea
		 order by cast(ZoneArea as int)
	END
	
	IF @ZonesAreNumeric <> 1
	BEGIN
		select * from SQLA_ZoneArea
		 order by ZoneArea
	END
END





GO

