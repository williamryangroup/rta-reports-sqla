USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_Locations]    Script Date: 02/20/2016 18:33:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_Locations]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_Locations](
		[Location] [nvarchar](10) NOT NULL,
		[Asset] [nvarchar](10) NULL,
		[Zone] [nvarchar](5) NULL,
		[Area] [nvarchar](5) NULL,
		[IsActive] [nvarchar](1) NULL,
		[DisplayLocation] [nvarchar](10) NULL,
		[ZoneArea] [nvarchar](10) NULL,
	 CONSTRAINT [PK_SQLA_Locations] PRIMARY KEY CLUSTERED 
	(
		[Location] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

