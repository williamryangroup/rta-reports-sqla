USE [RTSS_Seneca_SBC]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_MsgSender]    Script Date: 01/19/2016 03:37:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_MsgSender]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_MsgSender]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_MsgSender] 
	@StartDt datetime,
	@EndDt datetime
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT from_name = 'All'
	 UNION ALL
	SELECT DISTINCT from_name FROM MESSAGE1
	 WHERE tCreate >= @StartDt and tCreate <= @EndDt
	 ORDER BY from_name ASC
END



GO

