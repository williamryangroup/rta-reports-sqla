USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_AreaAssoc]    Script Date: 06/21/2016 13:21:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_AreaAssoc]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_AreaAssoc]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_AreaAssoc] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AssocAreaMode nvarchar(255) = isnull((select LTRIM(rtrim(Setting)) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'AssocAreaMode'),'Default')
	
	truncate table SQLA_AreaAssoc
	
	insert into SQLA_AreaAssoc (Area, AssocArea, Priority, Mode)
	select Area, AssocArea, Priority, Mode
	  from RTSS.dbo.ASSOC_AREA WITH (NOLOCK)
	 where Mode = @AssocAreaMode
END





GO


