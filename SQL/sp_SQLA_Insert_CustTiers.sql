USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_CustTiers]    Script Date: 04/11/2016 09:38:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_CustTiers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_CustTiers]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_CustTiers] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_CustTiers
	
	insert into SQLA_CustTiers (TierLevel, PriorityLevel)
	select TierLevel, PriorityLevel 
	  from RTSS.dbo.TIERPRIORITY WITH (NOLOCK)
	
	IF isnull((select 1 from SQLA_CustTiers where TierLevel = 'NUL'),0) = 0
	BEGIN
		insert into SQLA_CustTiers (TierLevel) values ('NUL')
	END
	
END




GO

