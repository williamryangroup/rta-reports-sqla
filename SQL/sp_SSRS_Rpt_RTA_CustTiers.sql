USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_CustTiers]    Script Date: 04/21/2016 12:59:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_CustTiers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_CustTiers]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_CustTiers] 
	@IncludeALL int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @IncludeALL = 0
	BEGIN
		select TierLevel, PriorityLevel
		  from SQLA_CustTiers
		 order by PriorityLevel desc, TierLevel
	END
	
	IF @IncludeALL = 1
	BEGIN
		select TierLevel = 'ALL', PriorityLevel = -1
		 union all
		select TierLevel, PriorityLevel
		  from SQLA_CustTiers
		 order by PriorityLevel desc, TierLevel
	END
END




GO

