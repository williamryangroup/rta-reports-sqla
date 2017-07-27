USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Employees]    Script Date: 07/26/2016 06:26:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Employees]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Employees]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Employees] 
	@IncludeAll int = 1,
	@HostOnly int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @IncludeAll = 1
	BEGIN
		select CardNum = '', 
			   NameFirst = '',
			   NameLast = '',
			   JobType = 'All',
			   NameDisplay = 'All',
			   DisplayOrd = 0
		 union all
		select CardNum = LTRIM(rtrim(CardNum)), isnull(NameFirst,''), isnull(NameLast,''), isnull(JobType,''),
			   NameDisplay = '(' + left(isnull(JobType,''),1) + ') ' + isnull(NameFirst,'') + ' ' + isnull(NameLast,''),
			   ROW_NUMBER() OVER(ORDER BY JobType, NameFirst, NameLast, CardNum ASC) AS DisplayOrd
		  from SQLA_Employees
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by DisplayOrd
	END
	
	ELSE
	BEGIN
		select CardNum = LTRIM(rtrim(CardNum)), isnull(NameFirst,''), isnull(NameLast,''), isnull(JobType,''),
			   NameDisplay = '(' + left(isnull(JobType,''),1) + ') ' + isnull(NameFirst,'') + ' ' + isnull(NameLast,'')
		  from SQLA_Employees
		 where (    (@HostOnly = 0)
		         or (@HostOnly = 1 and JobType in ('CE1','CE2','CE3','CE4','SupervisorCE','Host','Ambassador')))
		 order by JobType, NameFirst, NameLast, CardNum
	END
END



GO


