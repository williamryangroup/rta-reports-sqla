USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_MEAL]    Script Date: 09/08/2016 11:14:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_MEAL]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_MEAL](
		[PktNum] [int] NOT NULL,
		[Location] [nvarchar](20) NULL,
		[Zone] [char](2) NULL,
		[EmpNum] [nvarchar](20) NULL,
		[EmpName] [nvarchar](50) NULL,
		[EmpLicNum] [nvarchar](20) NULL,
		[tOut] [datetime] NULL,
		[EntryReason] [nvarchar](50) NULL,
		[ParentEventID] [int] NOT NULL,
		[PktNumWitness1] [int] NULL,
		[PktNumSourceWitness1] [nvarchar](20) NULL,
		[EmpNumWitness1] [nvarchar](20) NULL,
		[EmpNameWitness1] [nvarchar](50) NULL,
		[EmpLicNumWitness1] [nvarchar](20) NULL,
		[tWitness1] [datetime] NULL,
		[PktNumWitness2] [int] NULL,
		[PktNumSourceWitness2] [nvarchar](20) NULL,
		[EmpNumWitness2] [nvarchar](20) NULL,
		[EmpNameWitness2] [nvarchar](50) NULL,
		[EmpLicNumWitness2] [nvarchar](20) NULL,
		[tWitness2] [datetime] NULL,
		[PktNumWitness3] [int] NULL,
		[PktNumSourceWitness3] [nvarchar](20) NULL,
		[EmpNumWitness3] [nvarchar](20) NULL,
		[EmpNameWitness3] [nvarchar](50) NULL,
		[EmpLicNumWitness3] [nvarchar](20) NULL,
		[tWitness3] [datetime] NULL,
		[PktNumWitness4] [int] NULL,
		[PktNumSourceWitness4] [nvarchar](20) NULL,
		[EmpNumWitness4] [nvarchar](20) NULL,
		[EmpNameWitness4] [nvarchar](50) NULL,
		[EmpLicNumWitness4] [nvarchar](20) NULL,
		[tWitness4] [datetime] NULL
	) ON [PRIMARY]
GO


-- TABLE UPDATES
ALTER TABLE [dbo].[SQLA_MEAL] ADD [EventComment] [nvarchar](255) NULL
GO
-- 12/19/2016
ALTER TABLE [dbo].[SQLA_MEAL] ADD [Asset] [nvarchar](20) NULL
GO
-- 2/7/2017
ALTER TABLE [dbo].[SQLA_MEAL] ADD [CardInEvtDisp] [nvarchar](10) NULL
GO
ALTER TABLE [dbo].[SQLA_MEAL] ADD [CardInEvtDesc] [nvarchar](40) NULL
GO
ALTER TABLE [dbo].[SQLA_MEAL] ADD [Source] [nvarchar](4) NULL
GO
--4/6/2017
ALTER TABLE [dbo].[SQLA_MEAL] ALTER COLUMN [Source] [nvarchar](11) NULL
GO
--8/16/2017
ALTER TABLE [dbo].[SQLA_MEAL] ADD [tComplete] [datetime] NULL
GO
--2/27/2018
ALTER TABLE [dbo].[SQLA_MEAL] ADD [PktNumWitness5] [int] NULL
GO
ALTER TABLE [dbo].[SQLA_MEAL] ADD [PktNumSourceWitness5] [nvarchar](20) NULL
GO
ALTER TABLE [dbo].[SQLA_MEAL] ADD [EmpNumWitness5] [nvarchar](20) NULL
GO
ALTER TABLE [dbo].[SQLA_MEAL] ADD [EmpNameWitness5] [nvarchar](50) NULL
GO
ALTER TABLE [dbo].[SQLA_MEAL] ADD [EmpLicNumWitness5] [nvarchar](20) NULL
GO
ALTER TABLE [dbo].[SQLA_MEAL] ADD [tWitness5] [datetime] NULL
GO
-- 5/7/2018
ALTER TABLE [dbo].[SQLA_MEAL] ALTER COLUMN [CardInEvtDesc] [nvarchar](255) NULL
GO


SET ANSI_PADDING OFF
GO
