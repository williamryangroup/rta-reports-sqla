USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_ShiftHours]    Script Date: 02/20/2016 18:07:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_ShiftHours]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_ShiftHours](
		[StartHour] [int] NOT NULL,
		[ShiftName] [varchar](50) NULL,
		[ShiftHours] [varchar](50) NULL,
		[ShiftColumn] [int] NULL,
	 CONSTRAINT [PK_SQLA_Shifts] PRIMARY KEY CLUSTERED 
	(
		[StartHour] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

