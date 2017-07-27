USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EmployeeEventTimes]    Script Date: 07/19/2016 07:00:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EmployeeEventTimes]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EmployeeEventTimes](
		[EmpNum] [nvarchar](20) NOT NULL,
		[EmpNameFirst] [nvarchar](50) NULL,
		[EmpNameLast] [nvarchar](50) NULL,
		[EmpJobType] [nvarchar](50) NULL,
		[PktNum] [int] NOT NULL,
		[EventDisplay] [nvarchar](10) NULL,
		[ActivityStart] [datetime] NOT NULL,
		[ActivityEnd] [datetime] NULL,
		[ActivitySecs] [int] NULL,
	 CONSTRAINT [PK_SQLA_EmployeeEventTimes] PRIMARY KEY CLUSTERED 
	(
		[EmpNum] ASC,
		[PktNum] ASC,
		[ActivityStart] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


-- TABLE UPDATES

-- 9/29/2016
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ALTER COLUMN [EmpNum] [nvarchar](255) NOT NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ALTER COLUMN [EmpJobType] [nvarchar](20) NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ALTER COLUMN [EventDisplay] [nvarchar](255) NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tAsn] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tRea] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tDsp] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tAcp] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tRsp] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tRej] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tCmp] [datetime] NULL
GO


SET ANSI_PADDING OFF
GO

