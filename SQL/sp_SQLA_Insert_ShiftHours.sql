USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_ShiftHours]    Script Date: 02/20/2016 18:06:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_ShiftHours]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_ShiftHours]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_ShiftHours]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table SQLA_ShiftHours
	
	insert into SQLA_ShiftHours (StartHour, ShiftName, ShiftHours, ShiftColumn)
    select StartHour, ShiftName, ShiftHours, ShiftColumn
      from RTSS.dbo.EmployeeShift1 WITH (NOLOCK) where StartHour >= 0 and StartHour < 24
END

GO

