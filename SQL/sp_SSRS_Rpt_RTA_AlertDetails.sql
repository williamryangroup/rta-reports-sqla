USE [RTSS]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_AlertDetails]    Script Date: 01/19/2016 03:34:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_AlertDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_AlertDetails]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_AlertDetails] 
	@StartDt datetime,
	@EndDt datetime,
	@CustTiers varchar(255) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	-- CREATE TABLE OF CustTiers
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_AlertDetails_CustTiers'))
    BEGIN
		drop table dbo.#RTA_AlertDetails_CustTiers;
    END    
    
    create table #RTA_AlertDetails_CustTiers (
		CustTier nvarchar(20) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_AlertDetails_CustTiers (CustTier)
    select left(ltrim(rtrim(val)),20) from dbo.fn_String_To_Table(@CustTiers, ',', 1)
	
	
	SELECT ID, tCreate, tNotify, tAccept, tDismiss, location, priority, alertUser, alertJobType, alertType, alertText, EventTableName, EventTablePktNum
	  FROM ALERT1
	 WHERE tCreate >= @StartDt and tCreate <= @EndDt
	   AND alertType <> 'EVENT' 
	   AND priority in (select CustTier from #RTA_AlertDetails_CustTiers)
	ORDER BY tCreate

END




GO

