USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EventDetails]    Script Date: 06/15/2016 11:35:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EventDetails]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EventDetails](
		[PktNum] [int] NOT NULL,
		[tOut] [datetime] NULL,
		[tOutHour] [int] NULL,
		[CustNum] [nvarchar](20) NULL,
		[CustName] [nvarchar](50) NULL,
		[CustTierLevel] [nvarchar](10) NULL,
		[CustPriorityLevel] [int] NULL,
		[Location] [nvarchar](20) NULL,
		[Zone] [nvarchar](10) NULL,
		[EventDisplay] [nvarchar](10) NULL,
		[tAssign] [datetime] NULL,
		[tAccept] [datetime] NULL,
		[tAuthorize] [datetime] NULL,
		[tComplete] [datetime] NULL,
		[CompCode] [int] NULL,
		[HasReject] [int] NULL,
		[EmpNumAsn] [nvarchar](20) NULL,
		[EmpNameAsn] [nvarchar](255) NULL,
		[EmpNumRsp] [nvarchar](20) NULL,
		[EmpNameRsp] [nvarchar](255) NULL,
		[EmpNumCmp] [nvarchar](20) NULL,
		[EmpNameCmp] [nvarchar](255) NULL,
		[RspRTA] [int] NULL,
		[RspCard] [int] NULL,
		[CmpMobile] [int] NULL,
		[CmpGame] [int] NULL,
		[CmpWS] [int] NULL,
		[ResolutionDescID] [int] NULL,
		[ResolutionDesc] [nvarchar](255) NULL,
		[Reassign] [int] NULL,
		[ReassignSupervisor] [int] NULL,
		[FromZone] [nvarchar](10) NULL,
		[EmpJobTypeAsn] [nvarchar](50) NULL,
		[EmpJobTypeRsp] [nvarchar](50) NULL,
		[EmpJobTypeCmp] [nvarchar](50) NULL,
		[RspSecs] [int] NULL,
		[CmpSecs] [int] NULL,
		[TotSecs] [int] NULL,
		[AsnTakeID] [int] NULL,
		[AsnTake] [nvarchar](20) NULL
	) ON [PRIMARY]
GO


-- TABLE UPDATES

-- 9/29/2016
ALTER TABLE [dbo].[SQLA_EventDetails] ADD [SourceTable] [nvarchar](255) NULL
GO
ALTER TABLE [dbo].[SQLA_EventDetails] ADD [AmtEvent] [nvarchar](12) NULL
GO

--11/17/2017
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [EmpNumAsn] [nvarchar](40) NULL
GO
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [EmpNumRsp] [nvarchar](40) NULL
GO
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [EmpNumCmp] [nvarchar](40) NULL
GO

--1/5/2018
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [CustNum] [nvarchar](40) NULL
GO

--5/15/2018
ALTER TABLE [dbo].[SQLA_EventDetails] ADD [CompVarianceReason] [nvarchar](50) NULL
GO


SET ANSI_PADDING OFF
GO

