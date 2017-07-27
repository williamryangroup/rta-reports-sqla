USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_MEAL]    Script Date: 09/08/2016 11:27:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_MEAL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_MEAL]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_MEAL] 
	@StartDt datetime,
	@EndDt datetime,
	@Location nvarchar(10) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT PktNum, Location, Zone, EmpNum, EmpName = isnull(m.EmpName,emp.NameFirst+' '+left(emp.NameLast,1)+'.'), EmpLicNum, tOut, EntryReason, ParentEventID,
		   PktNumWitness1, PktNumSourceWitness1, EmpNumWitness1, EmpNameWitness1, EmpLicNumWitness1, tWitness1,
		   PktNumWitness2, PktNumSourceWitness2, EmpNumWitness2, EmpNameWitness2, EmpLicNumWitness2, tWitness2,
		   PktNumWitness3, PktNumSourceWitness3, EmpNumWitness3, EmpNameWitness3, EmpLicNumWitness3, tWitness3,
		   PktNumWitness4, PktNumSourceWitness4, EmpNumWitness4, EmpNameWitness4, EmpLicNumWitness4, tWitness4,
		   EventComment, Asset, r.EventDescription
	  FROM SQLA_MEAL as m
	  left join SQLA_CardInReasons as r
	    on r.Dept = m.Source
	   and r.EventDisplay = m.CardInEvtDisp
	  left join SQLA_Employees as emp
	    on emp.CardNum = m.EmpNum
	 WHERE tOut >= @StartDt and tOut <= @EndDt
	   and ((@Location = '') or (@Location = ' All') or (Location = @Location) or (Asset = @Location))
END




GO


