USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Locations]    Script Date: 04/21/2016 12:56:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Locations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Locations]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Locations] 
	@IsActive nvarchar(1) = ''	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select Location = '', 
	       Asset = '', 
	       Zone = 'All', 
	       Area = 'All', 
	       IsActive = '1',
	       DisplayLocation = ' All'
	 union all
	select ltrim(rtrim(Location)), Asset, Zone, Area, IsActive, DisplayLocation
	  from SQLA_Locations
	 where ((@IsActive = '') or (@IsActive = IsActive)) 
	 order by DisplayLocation
END







GO

