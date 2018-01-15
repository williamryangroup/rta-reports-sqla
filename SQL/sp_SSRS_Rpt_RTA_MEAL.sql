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
	
	SELECT PktNum, Location, Zone, EmpNum,
		   EmpName = case when (m.EmpName is null or ltrim(rtrim(m.EmpName)) = '') and emp.CardNum is not null then '('+left(emp.JobType,1)+') '+emp.NameFirst+' '+left(emp.NameLast,1)+'.'
		                  when (m.EmpName is null or ltrim(rtrim(m.EmpName)) = '') and emp.CardNum is null and emp2.CardNum is not null then '('+left(emp2.JobType,1)+') '+emp2.NameFirst+' '+left(emp2.NameLast,1)+'.'
						  else m.EmpName end,
		   EmpLicNum, tOut, EntryReason, ParentEventID,
		   PktNumWitness1, PktNumSourceWitness1, EmpNumWitness1, 
		   EmpNameWitness1 = case when empw1.CardNum is null then EmpNameWitness1 else '('+left(empw1.JobType,1)+') '+empw1.NameFirst+' '+left(empw1.NameLast,1)+'.' end, 
		   EmpLicNumWitness1, tWitness1,
		   PktNumWitness2, PktNumSourceWitness2, EmpNumWitness2,
		   EmpNameWitness2 = case when empw2.CardNum is null then EmpNameWitness2 else '('+left(empw2.JobType,1)+') '+empw2.NameFirst+' '+left(empw2.NameLast,1)+'.' end,
		   EmpLicNumWitness2, tWitness2,
		   PktNumWitness3, PktNumSourceWitness3, EmpNumWitness3,
		   EmpNameWitness3 = case when empw3.CardNum is null then EmpNameWitness3 else '('+left(empw3.JobType,1)+') '+empw3.NameFirst+' '+left(empw3.NameLast,1)+'.' end,
		   EmpLicNumWitness3, tWitness3,
		   PktNumWitness4, PktNumSourceWitness4, EmpNumWitness4,
		   EmpNameWitness4 = case when empw4.CardNum is null then EmpNameWitness4 else '('+left(empw4.JobType,1)+') '+empw4.NameFirst+' '+left(empw4.NameLast,1)+'.' end,
		   EmpLicNumWitness4, tWitness4,
		   EventComment, Asset, 
		   EventDescription = case when m.EntryReason = 'DROP TEAM' then m.CardInEvtDisp else isnull(r.EventDescription,m.CardInEvtDesc) end
	  FROM SQLA_MEAL as m
	  left join SQLA_CardInReasons as r
	    on r.Dept = m.Source
	   and r.EventDisplay = m.CardInEvtDisp
	  left join SQLA_Employees as emp
	    on emp.CardNum = m.EmpNum
	  left join SQLA_Employees as emp2
	    on emp2.CardNum = ltrim(rtrim(m.CardInEvtDisp))
	  left join SQLA_Employees as empw1
	    on empw1.CardNum = m.EmpNum
	  left join SQLA_Employees as empw2
	    on empw2.CardNum = m.EmpNum
	  left join SQLA_Employees as empw3
	    on empw3.CardNum = m.EmpNum
	  left join SQLA_Employees as empw4
	    on empw4.CardNum = m.EmpNum
	 WHERE tOut >= @StartDt and tOut <= @EndDt
	   and ((@Location = '') or (@Location = ' All') or (Location = @Location) or (Asset = @Location))
END




GO


