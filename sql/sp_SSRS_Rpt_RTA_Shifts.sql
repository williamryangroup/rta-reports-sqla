USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Shifts]    Script Date: 04/21/2016 13:08:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Shifts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Shifts]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Shifts] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select ShiftName = 'All', ShiftColumn = -1
	 union all
	select distinct ShiftName, ShiftColumn
	  from SQLA_ShiftHours
	 order by ShiftColumn
END





GO

