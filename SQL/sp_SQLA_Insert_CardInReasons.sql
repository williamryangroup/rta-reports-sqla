USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_CardInReasons]    Script Date: 02/20/2016 19:48:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_CardInReasons]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_CardInReasons]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_CardInReasons] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- CARD IN REASONS
	insert into SQLA_CardInReasons (Dept, EventDisplay, EventDescription)	
	select Dept = 'SLOT', r1.EventDisplay, r1.EventDescription
	  from RTSS.dbo.CARDIN_REASON as r1 with (NOLOCK)
	  left join SQLA_CardInReasons as r2 with (NOLOCK)
	    on r2.EventDisplay = r1.EventDisplay
	   and r2.Dept = 'SLOT'
	 where r2.EventDisplay is null
	 
	insert into SQLA_CardInReasons (Dept, EventDisplay, EventDescription)	
	select Dept = 'TECH', r1.EventDisplay, r1.EventDescription
	  from RTSS.dbo.CARDIN_REASON_ST as r1 with (NOLOCK)
	  left join SQLA_CardInReasons as r2 with (NOLOCK)
	    on r2.EventDisplay = r1.EventDisplay
	   and r2.Dept = 'TECH'
	 where r2.EventDisplay is null
	 
	 
	-- COMPLETE REASONS
	insert into SQLA_CardInReasons (Dept, EventDisplay, EventDescription)	
	select Dept = 'SLOT', EventDisplay = s1.ConfigParam, EventDescription = s1.Setting
	  from RTSS.dbo.SYSTEMSETTINGS as s1 with (NOLOCK)
	  left join SQLA_CardInReasons as s2 with (NOLOCK)
	    on s2.EventDisplay = s1.ConfigParam
	   and s2.Dept = 'SLOT'
	 where s1.ConfigSection = 'CompleteReason' and s2.EventDisplay is null

	insert into SQLA_CardInReasons (Dept, EventDisplay, EventDescription)	
	select Dept = 'TECH', EventDisplay = s1.ConfigParam, EventDescription = s1.Setting
	  from RTSS.dbo.SYSTEMSETTINGS as s1 with (NOLOCK)
	  left join SQLA_CardInReasons as s2 with (NOLOCK)
	    on s2.EventDisplay = s1.ConfigParam
	   and s2.Dept = 'TECH'
	 where s1.ConfigSection = 'CompleteReason_ST' and s2.EventDisplay is null	 
	 
	update s2 set s2.EventDescription = s1.Setting
	  from SQLA_CardInReasons as s2 with (NOLOCK)
	 inner join RTSS.dbo.SYSTEMSETTINGS as s1 with (NOLOCK)
	    on s1.ConfigParam = s2.EventDisplay
	 where s1.ConfigSection = 'CompleteReason' and s2.Dept = 'SLOT'
	   and s1.Setting <> s2.EventDescription

	update s2 set s2.EventDescription = s1.Setting
	  from SQLA_CardInReasons as s2 with (NOLOCK)
	 inner join RTSS.dbo.SYSTEMSETTINGS as s1 with (NOLOCK)
	    on s1.ConfigParam = s2.EventDisplay
	 where s1.ConfigSection = 'CompleteReason_ST' and s2.Dept = 'TECH'
	   and s1.Setting <> s2.EventDescription
	   
END

GO
