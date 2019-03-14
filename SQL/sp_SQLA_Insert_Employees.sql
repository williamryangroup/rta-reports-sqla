USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_Employees]    Script Date: 02/20/2016 20:09:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_Employees]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_Employees]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_Employees] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	delete from SQLA_Employees
	 where CardNum in (select CardNum from RTSS.dbo.EMPLOYEE WITH (NOLOCK))
	
	insert into SQLA_Employees (CardNum, NameFirst, NameLast, JobType)
	select CardNum, 
	       NameFirst = ltrim(rtrim(NameFirst)),
	       NameLast = ltrim(rtrim(NameLast)), 
	       JobType = ltrim(rtrim(JobType))
	  from RTSS.dbo.EMPLOYEE WITH (NOLOCK)

END

GO

