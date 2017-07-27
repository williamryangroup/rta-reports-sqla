USE [RTSS]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_FreqDist]    Script Date: 02/19/2016 13:10:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_FreqDist]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_FreqDist]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_FreqDist]
	@StartDt datetime,
	@EndDt datetime,
	@MaxCmpMins int = 120,
	@SvcTimeType int = 1,
	@GroupBy int = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ZonesAreNumeric varchar(1) = (select left(Setting,1) from SYSTEMSETTINGS where ConfigSection = 'RTSSWS' and ConfigParam = 'ZonesAreNumeric')
	DECLARE @MaxCmpSecs int = @MaxCmpMins * 60
	
	IF @SvcTimeType = 1   -- Rsp
	BEGIN
		select b.BinID, b.BinDisplay, b.BinMin, b.BinMax,
			   GroupBy = case when @GroupBy = 1 then isnull(CustTierLevel,'NUL')
							  when @GroupBy = 2 then isnull(Zone,'00')
							  when @GroupBy = 3 then EventDisplay end,
			   GroupByOrd = case when @GroupBy = 1 then CustPriorityLevel
								 when @GroupBy = 2 and @ZonesAreNumeric = '1' then CAST(Zone as int)
								 else 0 end,
			   EventCount = count(distinct e.PktNum)
		  from SQLA_FreqDist_Bins as b
		  left join SQLA_EventDetails as e
		    on e.RspSecs >= b.BinMin
		   and (e.RspSecs <  b.BinMax or b.BinMax = 0)
		   and e.tOut >= @StartDt  and e.tOut < @EndDt
		   and e.TotSecs <= @MaxCmpSecs and e.RspSecs > 0
	       
		 group by b.BinID, b.BinDisplay, b.BinMin, b.BinMax,
		       case when @GroupBy = 1 then isnull(CustTierLevel,'NUL')
		            when @GroupBy = 2 then isnull(Zone,'00')
		            when @GroupBy = 3 then EventDisplay end,
		       case when @GroupBy = 1 then CustPriorityLevel
		            when @GroupBy = 2 and @ZonesAreNumeric = '1' then CAST(Zone as int)
		            else 0 end
	END
	
	IF @SvcTimeType = 2  -- Cmp
	BEGIN
		select b.BinID, b.BinDisplay, b.BinMin, b.BinMax,
			   GroupBy = case when @GroupBy = 1 then isnull(CustTierLevel,'NUL')
							  when @GroupBy = 2 then isnull(Zone,'00')
							  when @GroupBy = 3 then EventDisplay end,
			   GroupByOrd = case when @GroupBy = 1 then CustPriorityLevel
								 when @GroupBy = 2 and @ZonesAreNumeric = '1' then CAST(Zone as int)
								 else 0 end,
			   EventCount = count(distinct e.PktNum)
		  from SQLA_FreqDist_Bins as b
		  left join SQLA_EventDetails as e
		    on e.CmpSecs >= b.BinMin
		   and (e.CmpSecs <  b.BinMax or b.BinMax = 0)
		   and e.tOut >= @StartDt  and e.tOut < @EndDt
		   and e.TotSecs <= @MaxCmpSecs and e.CmpSecs > 0
		 group by b.BinID, b.BinDisplay, b.BinMin, b.BinMax,
		       case when @GroupBy = 1 then isnull(CustTierLevel,'NUL')
		            when @GroupBy = 2 then isnull(Zone,'00')
		            when @GroupBy = 3 then EventDisplay end,
		       case when @GroupBy = 1 then CustPriorityLevel
		            when @GroupBy = 2 and @ZonesAreNumeric = '1' then CAST(Zone as int)
		            else 0 end
	END
	
	IF @SvcTimeType = 3   -- Tot
	BEGIN
		select b.BinID, b.BinDisplay, b.BinMin, b.BinMax,
			   GroupBy = case when @GroupBy = 1 then isnull(CustTierLevel,'NUL')
							  when @GroupBy = 2 then isnull(Zone,'00')
							  when @GroupBy = 3 then EventDisplay end,
			   GroupByOrd = case when @GroupBy = 1 then CustPriorityLevel
								 when @GroupBy = 2 and @ZonesAreNumeric = '1' then CAST(Zone as int)
								 else 0 end,
			   EventCount = count(distinct e.PktNum)
		  from SQLA_FreqDist_Bins as b
		  left join SQLA_EventDetails as e
		    on e.TotSecs >= b.BinMin
		   and (e.TotSecs <  b.BinMax or b.BinMax = 0)
		   and e.tOut >= @StartDt  and e.tOut < @EndDt
		   and e.TotSecs <= @MaxCmpSecs and e.TotSecs > 0
		 group by b.BinID, b.BinDisplay, b.BinMin, b.BinMax,
		       case when @GroupBy = 1 then isnull(CustTierLevel,'NUL')
		            when @GroupBy = 2 then isnull(Zone,'00')
		            when @GroupBy = 3 then EventDisplay end,
		       case when @GroupBy = 1 then CustPriorityLevel
		            when @GroupBy = 2 and @ZonesAreNumeric = '1' then CAST(Zone as int)
		            else 0 end
		            
	END
	
END



GO

