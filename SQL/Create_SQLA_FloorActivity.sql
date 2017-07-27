USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_FloorActivity]    Script Date: 04/12/2016 12:15:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_FloorActivity]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_FloorActivity](
		[tOut] [datetime] NOT NULL,
		[ActivityTypeID] [int] NULL,
		[State] [nvarchar](255) NULL,
		[Activity] [nvarchar](255) NULL,
		[Location] [nvarchar](255) NULL,
		[Zone] [nvarchar](255) NULL,
		[PktNum] [int] NULL,
		[Tier] [nvarchar](255) NULL,
		[EmpNum] [nvarchar](255) NULL,
		[EmpName] [nvarchar](255) NULL,
		[Source] [nvarchar](255) NULL,
		[Description] [nvarchar](255) NULL,
		[RejAfterDisp] [nvarchar](255) NULL,
		[SourceTable] [nvarchar](255) NULL,
		[SourceTableID] [int] NULL,
		[SourceTableID2] [nvarchar](50) NULL,
		[SourceTableDttm1] [datetime] NULL,
		[SourceTableDttm2] [datetime] NULL
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

