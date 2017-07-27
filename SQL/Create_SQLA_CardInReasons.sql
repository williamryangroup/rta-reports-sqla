USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_CardInReasons]    Script Date: 09/08/2016 11:14:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_CardInReasons]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_CardInReasons](
		[Dept] [nvarchar](4) NOT NULL,
		[EventDisplay] [nvarchar](10) NOT NULL,
		[EventDescription] [nvarchar](40) NOT NULL
	 CONSTRAINT [PK_SQLA_CardInReasons] PRIMARY KEY CLUSTERED 
	(
		[Dept] ASC,
		[EventDisplay] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


-- TABLE UPDATES



SET ANSI_PADDING OFF
GO

