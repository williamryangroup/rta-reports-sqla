USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EventDetails_JPVER]    Script Date: 08/24/2016 09:00:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EventDetails_JPVER]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EventDetails_JPVER](
		[PktNum] [int] NOT NULL,
		[EventDisplay] [nvarchar](10) NULL,
		[tOut] [datetime] NULL,
		[tComplete] [datetime] NULL,
		[Source] [nvarchar](25) NULL,
		[EmpNum] [nvarchar](255) NULL,
		[EmpName] [nvarchar](255) NULL,
		[EmpNameFirst] [nvarchar](255) NULL,
		[EmpNameLast] [nvarchar](255) NULL,
		[EmpJobType] [nvarchar](255) NULL,
	 CONSTRAINT [PK_SQLA_EventDetails_JPVER] PRIMARY KEY CLUSTERED 
	(
		[PktNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES

--6/21/2017
ALTER TABLE SQLA_EventDetails_JPVER DROP CONSTRAINT PK_SQLA_EventDetails_JPVER
ALTER TABLE SQLA_EventDetails_JPVER ALTER COLUMN Source nvarchar(255) NOT NULL
ALTER TABLE SQLA_EventDetails_JPVER ALTER COLUMN tOut datetime NOT NULL
ALTER TABLE SQLA_EventDetails_JPVER ADD CONSTRAINT PK_SQLA_EventDetails_JPVER PRIMARY KEY (PktNum,Source,tOut)


SET ANSI_PADDING OFF
GO

