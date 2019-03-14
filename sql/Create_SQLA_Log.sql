USE [RTSS]
GO

/****** Object:  Table [dbo].[SQLA_Log]    Script Date: 08/24/2018 06:47:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SQLA_Log](
	[RecordID] [bigint] IDENTITY(0,1) NOT NULL,
	[RecordDttm] [datetime] NOT NULL,
	[RecordDesc] [nvarchar](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

