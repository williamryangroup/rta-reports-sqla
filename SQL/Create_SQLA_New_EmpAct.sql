USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_New_EmpAct]    Script Date: 04/12/2016 11:12:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_New_EmpAct]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_New_EmpAct](
		[CardNum] [nvarchar](50) NOT NULL,
		[tOut] [datetime] NOT NULL,
		[tIn] [datetime] NOT NULL,
	 CONSTRAINT [PK_SQLA_New_EmpAct] PRIMARY KEY CLUSTERED 
	(
		[CardNum] ASC,
		[tOut] ASC,
		[tIn] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

