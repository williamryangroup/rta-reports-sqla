USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EmpJobTypes]    Script Date: 06/27/2016 12:40:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EmpJobTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EmpJobTypes]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EmpJobTypes]
	@IncludeAll int = 1,
	@HostOnly int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @IncludeAll = 1
	BEGIN
		select JobType = 'All', JobTypeOrd = ''
		 union all
		select JobType, JobTypeOrd = JobType from SQLA_EmpJobTypes
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by 2
	END
	
	ELSE
	BEGIN
		select JobType, JobTypeOrd = JobType from SQLA_EmpJobTypes
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by 2
	END
END







GO

