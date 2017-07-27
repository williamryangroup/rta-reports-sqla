USE [RTSS]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_MultiProp_CustRsp]    Script Date: 06/02/2016 11:46:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_MultiProp_CustRsp]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_MultiProp_CustRsp]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_MultiProp_CustRsp]
	@StartDt datetime,
	@EndDt datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	truncate table RTA_FreqDist_Bins
	
    insert into RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (0, '0-:30', 0, 30)
    insert into RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (1, ':30-1:00', 30, 60)
    insert into RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (2, '1:00-2:00', 60, 120)
    insert into RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (3, '2:00-3:00', 120, 180)
    insert into RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (4, '3:00-5:00', 180, 300)
    insert into RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (5, '5:00-10:00', 300, 600)
    insert into RTA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (6, '>= 10:00', 600, 0)
	
	
	select e.PropCode, e.CustTierLevel, 
		   ThresholdSecsMin = b.BinMin,
		   ThresholdSecsMax = b.BinMax,
		   ThresholdDescr = b.BinDisplay,
		   ThresholdOrder = b.BinID,
		   EventCount = COUNT(*)
	  from dbo.SQLA_MultProp_CustRsp as e
	 inner join RTA_FreqDist_Bins as b
		on (b.BinMin <= e.RspSecs)
	   and (b.BinMax >  e.RspSecs or b.BinMax = 0)
	 where EventDisplay not in ('OOS','10 6','EMPCARD')
	   and RspSecs > 0
	   and tOut >= @StartDt and tOut < @EndDt
	 group by e.PropCode, e.CustTierLevel, b.BinMin, b.BinMax, b.BinDisplay, b.BinID
END

GO

