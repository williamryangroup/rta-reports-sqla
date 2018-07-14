USE [RTA_SQLA]
GO

/****** Object:  StoredProcedure [dbo].[sp_SQLA_Insert_MEAL]    Script Date: 09/08/2016 11:24:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_SQLA_Insert_MEAL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [sp_SQLA_Insert_MEAL]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_SQLA_Insert_MEAL]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @UseAssetField char(255) = isnull((select case when Setting = 'Asset' then '1' else '0' end from RTSS.dbo.SYSTEMSETTINGS WITH (NOLOCK) where ConfigSection = 'RTSSHH' and ConfigParam = 'EventLocationOrAssetFieldName'),'0')
	
	insert into SQLA_MEAL (PktNum, Location, Zone, EmpNum, EmpName, EmpLicNum, tOut, EntryReason, ParentEventID, PktNumWitness1, PktNumSourceWitness1, EmpNumWitness1, EmpNameWitness1, EmpLicNumWitness1, tWitness1, PktNumWitness2, PktNumSourceWitness2, EmpNumWitness2, EmpNameWitness2, EmpLicNumWitness2, tWitness2, PktNumWitness3, PktNumSourceWitness3, EmpNumWitness3, EmpNameWitness3, EmpLicNumWitness3, tWitness3, PktNumWitness4, PktNumSourceWitness4, EmpNumWitness4, EmpNameWitness4, EmpLicNumWitness4, tWitness4, PktNumWitness5, PktNumSourceWitness5, EmpNumWitness5, EmpNameWitness5, EmpLicNumWitness5, tWitness5, EventComment, Asset, CardInEvtDisp, CardInEvtDesc, Source, tComplete)
	select ml.PktNum, ml.Location, ml.Zone,
	       EmpNum = case when ml.EmpNum is null or ml.EmpNum = '' then ISNULL(ISNULL(ISNULL(es.EmpNumComplete,et.EmpNumComplete),es.EmpNumAuthorize),et.EmpNumAuthorize) else ml.EmpNum end,
		   EmpName = case when ml.EmpName is null or ml.EmpName = '' then ISNULL(ISNULL(ISNULL(es.EmpNameComplete,et.EmpNameComplete),es.EmpNameAuthorize),et.EmpNameAuthorize) else ml.EmpName end,
		   ml.EmpLicNum,
		   ml.tOut, 
		   EntryReason = case when ml.EventDisplay1 = 'EMPCARD' then 'EMPCARD'
		                      else isnull(ml.EntryReason, case when ml.EventDisplay1 = '' and ml.EventDisplay = '' then ml.EventComment
		                                                       when ml.EventDisplay1 = '' and ml.EventDisplay <> '' then ml.EventDisplay
		                                                       else ml.EventDisplay1 end) end, 
		   ParentEventID = case when ml.ParentEventID = 0 then ml.PktNumEvent else ml.ParentEventID end,
		   ml.PktNumWitness1, ml.PktNumSourceWitness1, ml.EmpNumWitness1, ml.EmpNameWitness1, ml.EmpLicNumWitness1, ml.tWitness1,
		   ml.PktNumWitness2, ml.PktNumSourceWitness2, ml.EmpNumWitness2, ml.EmpNameWitness2, ml.EmpLicNumWitness2, ml.tWitness2,
		   ml.PktNumWitness3, ml.PktNumSourceWitness3, ml.EmpNumWitness3, ml.EmpNameWitness3, ml.EmpLicNumWitness3, ml.tWitness3,
		   ml.PktNumWitness4, ml.PktNumSourceWitness4, ml.EmpNumWitness4, ml.EmpNameWitness4, ml.EmpLicNumWitness4, ml.tWitness4,
		   ml.PktNumWitness5, ml.PktNumSourceWitness5, ml.EmpNumWitness5, ml.EmpNameWitness5, ml.EmpLicNumWitness5, ml.tWitness5,
		   EventComment = isnull(es.EventComment,et.EventComment),
		   ml.Asset,
		   CardInEvtDisp = isnull(isnull(isnull(isnull(isnull(crs.EventDisplay,crt.EventDisplay),rds.CmpReasonNum),rdt.CmpReasonNum),es.ResolutionDesc),et.ResolutionDesc),
		   CardInEvtDesc = isnull(isnull(isnull(isnull(isnull(crs.EventDescription,crt.EventDescription),rds.CompleteReason),rdt.CompleteReason),es.ResolutionDesc),et.ResolutionDesc),
		   Source = case when ml.PktCbMsg = 'RTA Offline' then 'RTA Offline'
						 when et.PktNum is not null then 'TECH'
						 else 'SLOT' end,
		   ml.tComplete
	  from RTSS.dbo.EVENT4_ML as ml with (nolock)
	  left join RTSS.dbo.EVENT4 as es with (nolock)
	    on (es.PktNum = ml.ParentEventID or (ml.ParentEventID = 0 and es.PktNum = ml.PktNumEvent))
	   and es.Location = ml.Location
	  left join RTSS.dbo.EVENT4_ST as et with (nolock)
	    on (et.PktNum = ml.ParentEventID or (ml.ParentEventID = 0 and et.PktNum = ml.PktNumEvent))
	   and et.Location = ml.Location
	  left join RTSS.dbo.CARDIN_REASON as crs with (nolock)
	    on es.ResolutionDesc = crs.EventDisplay
	  left join RTSS.dbo.CARDIN_REASON_ST as crt with (nolock)
	    on et.ResolutionDesc = crt.EventDisplay
	  left join (select CmpReasonNum = cast(row_number() over(order by ConfigSection, ConfigParam)-1 as nvarchar), CompleteReason = Setting from RTSS.dbo.SYSTEMSETTINGS with (nolock) where ConfigSection = 'CompleteReason') as rds
	    on rds.CmpReasonNum = es.ResolutionDesc
	  left join (select CmpReasonNum = cast(row_number() over(order by ConfigSection, ConfigParam)-1 as nvarchar), CompleteReason = Setting from RTSS.dbo.SYSTEMSETTINGS with (nolock) where ConfigSection = 'CompleteReason_ST') as rdt
	    on rdt.CmpReasonNum = et.ResolutionDesc
	 where not exists (select null from SQLA_MEAL as sm WITH (NOLOCK) where sm.PktNum = ml.PktNum)
	   and (ml.tOut is not NULL and isdate(ml.tOut) = 1 and ml.tOut > '1/2/1980')
	   and (    (ml.ParentEventID is null) or (ml.PktCbMsg = 'RTA Offline')
	         or (ml.ParentEventID is not null and ml.ParentEventID = 0 and ml.PktNumEvent is null)
			 or (ml.ParentEventID is not null and (es.PktNum is not null or et.PktNum is not null)))
END

GO
