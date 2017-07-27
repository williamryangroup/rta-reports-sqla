USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SSRS_Rpt_RTA_RulesOfEngagement]    Script Date: 04/21/2016 13:08:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SSRS_Rpt_RTA_RulesOfEngagement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SSRS_Rpt_RTA_RulesOfEngagement]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SSRS_Rpt_RTA_RulesOfEngagement]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select AssocAreaEnabled = isnull((select case when Setting = '1' then 'Yes' else 'No' end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'AssociatedAreasMode'),'No'),
		   AssocAreaTiers = isnull((select TierNames = LEFT(TierNames,LEN(TierNames)-1)
									  from (select TierNames = case when TierName0 is not null then TierName0 + ',' else '' end +
															   case when TierName1 is not null then TierName1 + ',' else '' end +
															   case when TierName2 is not null then TierName2 + ',' else '' end +
															   case when TierName3 is not null then TierName3 + ',' else '' end +
															   case when TierName4 is not null then TierName4 + ',' else '' end +
															   case when TierName5 is not null then TierName5 + ',' else '' end +
															   case when TierName6 is not null then TierName6 + ',' else '' end +
															   case when TierName7 is not null then TierName7 + ',' else '' end +
															   case when TierName8 is not null then TierName8 + ',' else '' end +
															   case when TierName9 is not null then TierName9 + ',' else '' end +
															   case when TierName10 is not null then TierName10 + ',' else '' end +
															   case when TierName11 is not null then TierName11 + ',' else '' end +
															   case when TierName12 is not null then TierName12 + ',' else '' end +
															   case when TierName13 is not null then TierName13 + ',' else '' end +
															   case when TierName14 is not null then TierName14 + ',' else '' end +
															   case when TierName15 is not null then TierName15 + ',' else '' end
											  from (select Tier = rtrim(replace(ConfigParam,'AssocAreasTier','')), ColumnName='TierName'+cast(PriorityLevel as varchar) from RTSS.dbo.SYSTEMSETTINGS left join SQLA_CustTiers on TierLevel = replace(ConfigParam,'AssocAreasTier','')where ConfigSection = 'SYSTEM' and ConfigParam like 'AssocAreasTier%' and Setting = '1') as t
											 pivot (max(Tier) for ColumnName in (TierName0, TierName1, TierName2, TierName3, TierName4, TierName5, TierName6, TierName7, TierName8, TierName9, TierName10, TierName11, TierName12, TierName13, TierName14, TierName15)) as piv) as l),'None'),
		   UseAreaLastEvt = isnull((select case when Setting = '1' then 'Yes' else 'No' end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'UseAreaLastEvent'),'No'),
		   RejEvtIndefinite = isnull((select case when Setting = '1' then 'Yes' else 'No' end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSHH' and ConfigParam = 'RejectEventIndefinite'),'No'),
		   AutoRejSecs = isnull((select rtrim(Setting) from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSHH' and ConfigParam = 'AutoAssignRejectSeconds'),'60'),
		   OOSAfterAutoRej = isnull((select case when Setting = '1' then 'Yes' else 'No' end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'RTSSHH' and ConfigParam = 'OosAfterAutoReject'),'No'),
		   AttEvtReassign = isnull((select case when Setting = '1' then 'Yes' else 'No' end from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'CZR' and ConfigParam = 'AttendantEventReassign' and 'CZR' = (select Setting from RTSS.dbo.SYSTEMSETTINGS where ConfigSection = 'SYSTEM' and ConfigParam = 'FeedType')),'No'),
		   NumAreas = isnull((select count(*) from SQLA_ZoneArea where ZoneArea <> '00'),0)
END

GO
