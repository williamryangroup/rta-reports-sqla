USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_MultProp_CustRsp]    Script Date: 06/02/2016 11:46:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_MultProp_CustRsp]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_MultProp_CustRsp](
		[PropCode] [varchar](10) NULL,
		[PktNum] [int] NULL,
		[tOut] [datetime] NULL,
		[EventDisplay] [nvarchar](10) NULL,
		[CustTierLevel] [nvarchar](10) NULL,
		[RspSecs] [int] NULL,
		[CmpSecs] [int] NULL,
		[TotSecs] [int] NULL
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

