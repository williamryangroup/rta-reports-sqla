USE [RTSS_Seneca_SBC]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_Messages]    Script Date: 01/19/2016 03:37:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_Messages]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_Messages]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_Messages] 
	@StartDt datetime,
	@EndDt datetime,
	@FromNames varchar(255) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	-- CREATE TABLE OF FromNames
	/*
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Messages_FromNames'))
    BEGIN
		drop table dbo.#RTA_Messages_FromNames;
    END    
    
    create table #RTA_Messages_FromNames (
		FromName nvarchar(50) NOT NULL PRIMARY KEY
    )
    
    insert into #RTA_Messages_FromNames (FromName)
    select left(ltrim(rtrim(val)),50) from dbo.fn_String_To_Table(@FromNames, ',', 1)*/
	
	
	SELECT ID, tCreate, tNotify, tRead, tDismiss, 
	       From_DeviceID, From_CardNum, From_Name, 
	       To_DeviceID, To_CardNum, To_Name, 
	       MessageText, MessageVoice, 
	       To_Recipients, To_Names, ReplyToMessageID
	  FROM MESSAGE1 
	 WHERE tCreate >= @StartDt and tCreate <= @EndDt
	   AND (@FromNames = 'All' or From_Name = @FromNames)
	   --AND From_Name in (select FromName from #RTA_Messages_FromNames)
	ORDER BY tCreate, From_Name
END



GO

