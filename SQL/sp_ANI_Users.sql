USE [ANI]
GO

/****** Object:  StoredProcedure [dbo].[sp_ANI_Users]    Script Date: 09/09/2015 11:52:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_ANI_Users]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_ANI_Users]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ANI_Users]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select UserId = null, UserName = 'All'
	 union all
	select u.UserId, u.UserName
	  from dbo.aspnet_Users as u
END

GO


