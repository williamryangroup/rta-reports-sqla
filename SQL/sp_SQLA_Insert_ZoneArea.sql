USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_ZoneArea]    Script Date: 03/15/2016 04:07:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_ZoneArea]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_ZoneArea]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_ZoneArea] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UseArea int = 0
	DECLARE @ZonesAreNumeric int = isnull((select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZonesAreNumeric'),0)
	
	select @UseArea = case when ltrim(rtrim(Setting)) = '1' then 1 else 0 end
	  from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK)
	 where ConfigSection = 'System' and ConfigParam = 'AssociatedAreasMode'
		
	truncate table SQLA_ZoneArea
	
	insert into SQLA_ZoneArea (ZoneArea) values ('00')
	
	insert into SQLA_ZoneArea (ZoneArea)
	select distinct ZoneArea = case when @UseArea = 1 then ltrim(rtrim(Area)) else ltrim(rtrim(Zone)) end
	  from RTSS.dbo.LOCZONE WITH (NOLOCK)
	 where (    ((@UseArea =  1) and (Area is not null and Area <> '00' and Area <> '') and ((@ZonesAreNumeric = 0) or (@ZonesAreNumeric = 1 and isnumeric(Area)=1)) )
	         or ((@UseArea <> 1) and (Zone is not null and Zone <> '00' and Zone <> '') and ((@ZonesAreNumeric = 0) or (@ZonesAreNumeric = 1 and isnumeric(Zone)=1)) ))
END



GO

