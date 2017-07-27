USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_EventTypes]    Script Date: 08/31/2016 08:11:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_EventTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_EventTypes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_EventTypes]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_EventTypes
	
	insert into SQLA_EventTypes (EventDisplay) values ('JP VER')
	
	insert into SQLA_EventTypes (EventDisplay)
	select distinct EventDisplay
	  from RTSS.dbo.EVENT1 WITH (NOLOCK)
	 where EventDisplay not in ('','JP VER')
	

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
			   WHERE TABLE_NAME = N'EVENT1_ST')
	BEGIN
		insert into SQLA_EventTypes (EventDisplay)
		select distinct EventDisplay
		  from RTSS.dbo.EVENT1_ST WITH (NOLOCK)
		 where EventDisplay not in ('','JP VER')
		   and EventDisplay not in (select EventDisplay from SQLA_EventTypes)
	END
	

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
			   WHERE TABLE_NAME = N'EVENT1_CE')
	BEGIN
		insert into SQLA_EventTypes (EventDisplay)
		select distinct EventDisplay
		  from RTSS.dbo.EVENT1_CE WITH (NOLOCK)
		 where EventDisplay not in ('','JP VER')
		   and EventDisplay not in (select EventDisplay from SQLA_EventTypes)
	END

	
	delete from SQLA_EventTypes
	 where EventDisplay <> dbo.RemoveNonASCII(EventDisplay)
	   and exists 
		 ( select null from SQLA_EventTypes
	        where EventDisplay = dbo.RemoveNonASCII(EventDisplay) )
	
	update SQLA_EventTypes
	   set EventDisplay = dbo.RemoveNonASCII(EventDisplay)
	
END





GO


