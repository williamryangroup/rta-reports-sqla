USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]    Script Date: 02/21/2016 18:59:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_EventDetails_ExecSum_Cmp]
	@StartDt datetime,
	@EndDt datetime,
	@EmpJobType varchar(2000) = '',
	@EventType varchar(2000) = '',
	@AsnRspOnly int = 0,
	@IncludeOOS int = 1,
	@IncludeEMPCARD int = 1
	
WITH RECOMPILE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @StartDt1 datetime = @StartDt
	DECLARE @EndDt1 datetime = @EndDt
	DECLARE @EmpJobType1 varchar(2000) = @EmpJobType
	DECLARE @EventType1 varchar(2000) = @EventType
	DECLARE @AsnRspOnly1 int = @AsnRspOnly
	DECLARE @IncludeOOS1 int = @IncludeOOS
	DECLARE @IncludeEMPCARD1 int = @IncludeEMPCARD
	
	-- CREATE TABLE OF Compliance Employee
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_Employee_Tmp'))
    BEGIN
		drop table dbo.#RTA_Compliance_Employee_Tmp;
    END    
    
    create table #RTA_Compliance_Employee_Tmp (
		EmpNum nvarchar(255),
		EmpNameFirst nvarchar(255),
		EmpNameLast nvarchar(255),
		EmpJobType nvarchar(255),
		PktNum int,
		EventDisplay nvarchar(255),
		Location nvarchar(255),
		Asn int,
		Acp int,
		Rsp int,
		Cmp int,
		CmpMobile int,
		RejMan int,
		RejAuto int,
		RspRTA int,
		RspCard int,
		RspRTAandCard int,
		RspTmSec int,
		OverallTmSec int,
		AsnOther int,
		ShiftName nvarchar(255), 
		ShiftOrder int,
		CustTier nvarchar(255),
		tOutHour int
    )
	
	INSERT INTO dbo.#RTA_Compliance_Employee_Tmp EXEC dbo.sp_SSRS_Rpt_RTA_Compliance_Employee @StartDt=@StartDt1, @EndDt=@EndDt1, @EmpJobType=@EmpJobType1, @EventType=@EventType1, @AsnRspOnly=@AsnRspOnly1, @IncludeOOS=@IncludeOOS1, @IncludeEMPCARD=@IncludeEMPCARD1
	
	
	
	-- CREATE TABLE OF Compliance Employee
	IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                   AND TABLE_NAME = '#RTA_Compliance_Employee_Tot_Tmp'))
    BEGIN
		drop table dbo.#RTA_Compliance_Employee_Tot_Tmp;
    END    
    
    create table #RTA_Compliance_Employee_Tot_Tmp (
		EmpNum nvarchar(255),
		AsnTot int,
		RspNotAsnTot int
	)
	
	INSERT INTO #RTA_Compliance_Employee_Tot_Tmp 
	SELECT EmpNum, AsnTot = SUM(Asn), RspNotAsnTot = SUM(case when Rsp > 0 and Asn = 0 then 1 else 0 end)
	  FROM dbo.#RTA_Compliance_Employee_Tmp
	 GROUP BY EmpNum
	
	
	
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'NotAcp,RejAuto',
	       StateCount = count(*),
	       Total = t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'NotAcp,RejMan',
	       StateCount = count(*),
	       Total = t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,RejMan',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,RejAuto',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp = 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,Rsp,RejMan',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,Rsp,RejAuto',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Acp,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejAuto,Acp,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejMan,Acp,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp > 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejMan,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'RejAuto,Rsp,Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp > 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Rsp,Not Cmp',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp = 0 and c.Rsp > 0 and c.Cmp = 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'Y',
	       ComplianceState = 'Taken',
	       EventCount = count(*),
	       t.AsnTot, PctTotal = count(*)*1.0/t.AsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn > 0 and c.Acp >= 0 and c.Rsp = 0 and c.Cmp = 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.AsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,Cmp',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	   and c.EventDisplay <> 'JKPT'
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'JP VER',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp > 0 and (c.RejMan + c.RejAuto) = 0
	   and c.EventDisplay = 'JKPT'
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,Not Cmp',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp = 0 and (c.RejMan + c.RejAuto) = 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,RejAuto',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejAuto > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
	 UNION ALL
	SELECT c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, Asn = 'N',
	       ComplianceState = 'Rsp,RejMan',
	       EventCount = count(*),
	       t.RspNotAsnTot, PctTotal = count(*)*1.0/t.RspNotAsnTot*1.0,
	       AsnInt = c.Asn, AcpInt = c.Acp, RspInt = c.Rsp, CmpInt = c.Cmp, RejManInt = c.RejMan, RejAutoInt = c.RejAuto
	  FROM dbo.#RTA_Compliance_Employee_Tmp as c
	 INNER JOIN dbo.#RTA_Compliance_Employee_Tot_Tmp as t
	    on t.EmpNum = c.EmpNum
	 WHERE c.Asn = 0 and c.Acp >= 0 and c.Rsp > 0 and c.Cmp = 0 and c.RejMan > 0
	 GROUP BY c.EmpNum, c.EmpNameFirst, c.EmpNameLast, c.EmpJobType, t.RspNotAsnTot,
	       c.Asn, c.Acp, c.Rsp, c.Cmp, c.RejMan, c.RejAuto
	
END


GO

