USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_Locations]    Script Date: 02/20/2016 18:34:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_Locations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_Locations]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_Locations] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UseAssetField int = isnull((select case when Setting = 'Asset' then 1 else 0 end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),0)
	DECLARE @UseArea int = isnull((select case when ltrim(rtrim(Setting)) = '1' then 1 else 0 end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'AssociatedAreasMode'),0)
	DECLARE @FeedType varchar(50) = (select ltrim(rtrim(Setting)) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'FeedType')

	truncate table SQLA_Locations
	
	IF (@FeedType <> 'SYNKROS')
	BEGIN
		insert into SQLA_Locations (Location, Asset, Zone, Area, IsActive, DisplayLocation, ZoneArea)
		select Location = case when @UseAssetField = 1 then Asset else Location end, 
		       Asset = case when @UseAssetField = 1 then Location else Asset end,
			   Zone, Area, IsActive,
			   DisplayLocation = case when @UseAssetField = 1 then Asset else Location end,
			   ZoneArea = case when @UseArea = 1 then Area else Zone end
		  from RTSS.dbo.LOCZONE WITH (NOLOCK)
	END


	IF (@FeedType = 'SYNKROS')
	BEGIN
		insert into SQLA_Locations (Location, Asset, Zone, Area, IsActive, DisplayLocation, ZoneArea)
		select distinct Location, Asset, Zone, Area = Zone, IsActive = 1,
			   DisplayLocation = case when @UseAssetField = 1 then Asset else Location end,
			   ZoneArea = Zone
		  from RTSS.dbo.EVENT4 as e1 WITH (NOLOCK)
		 where Location like '_%-___-_%'
		   and exists 
		     ( select null from RTSS.dbo.EVENT4 as e2 WITH (NOLOCK)
			    where e2.Location = e1.Location
				group by e2.Location
				having max(e2.tout) = e1.tOut )
	END
	
END




GO

