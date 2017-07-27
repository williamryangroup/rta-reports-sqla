USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_Employees]    Script Date: 02/20/2016 20:10:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_Employees]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_Employees](
		[CardNum] [nvarchar](20) NOT NULL,
		[NameFirst] [nvarchar](50) NULL,
		[NameLast] [nvarchar](50) NULL,
		[JobType] [nvarchar](20) NULL,
	 CONSTRAINT [PK_SQLA_Employees] PRIMARY KEY CLUSTERED 
	(
		[CardNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES

-- 12/21/2016
ALTER TABLE [dbo].[SQLA_Employees] ALTER COLUMN [CardNum] [nvarchar](40) NOT NULL
GO


SET ANSI_PADDING OFF
GO

