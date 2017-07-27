USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_SupReview]    Script Date: 08/31/2016 12:08:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_SupReview]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_SupReview]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_SupReview]
	@StartDt datetime,
	@EndDt datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select PktNum, EventDisplay, CustTierLevel, EmpJobTypeRsp, RspSecs, AsnTake,
		   RspBin = case when RspSecs <= 30 then '00:00 - 00:30'
						 when RspSecs >  30 and RspSecs <=  60 then '00:30 - 01:00'
						 when RspSecs >  60 and RspSecs <= 120 then '01:00 - 02:00'
						 when RspSecs > 120 and RspSecs <= 180 then '02:00 - 03:00'
						 when RspSecs > 180 and RspSecs <= 300 then '03:00 - 05:00'
						 when RspSecs > 300 and RspSecs <= 600 then '05:00 - 10:00'
						 when RspSecs > 600 then '> 10:00' end,
		   InTopTwoTiers = case when CustTierLevel in (select top 2 TierLevel from SQLA_CustTiers order by PriorityLevel desc) then 'Y' else 'N' end
	  from SQLA_EventDetails
	 where tOut >= @StartDt and tOut < @EndDt
	   and RspSecs >= 0
	   and EmpJobTypeRsp <> ''
END

GO
