USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_AreaAssoc]    Script Date: 02/20/2016 18:37:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_AreaAssoc]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_AreaAssoc](
		[Area] [char](4) NOT NULL,
		[AssocArea] [char](4) NOT NULL,
		[Priority] [int] NULL,
		[Mode] [nvarchar](20) NOT NULL,
	 CONSTRAINT [PK_SQLA_AreaAssoc] PRIMARY KEY CLUSTERED 
	(
		[Area] ASC,
		[AssocArea] ASC,
		[Mode] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

