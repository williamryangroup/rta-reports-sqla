USE [ANI]
GO

/****** Object:  StoredProcedure [dbo].[sp_ANI_UserSessions]    Script Date: 09/09/2015 11:52:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_ANI_UserSessions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_ANI_UserSessions]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ANI_UserSessions]
	@StartDt datetime,
	@EndDt datetime,
	@UserID uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select SessionDt = s.startDT,
		   u.UserName,
		   ReportDttm = r.RequestDT,
		   ReportName = right(r.ReportPath,LEN(r.ReportPath)-12)
	  from dbo.trcSession as s
	 inner join dbo.aspnet_Users as u
		on u.UserId = s.UserId
	 inner join dbo.trcReport as r
		on r.SessionId = s.SessionID
	 where r.RequestDT >= @StartDt and r.RequestDT < @EndDt
	   and (u.UserId = @UserID or @UserID is null)
END

GO


