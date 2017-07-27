USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_Quartile_MachineData]    Script Date: 2/6/2017 2:39:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_Quartile_MachineData]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_Quartile_MachineData](
		[QuartileDTTM] [datetime] NULL,
		[QuartileHr] [int] NULL,
		[QuartileMin] [int] NULL,
		[GamesInPlay] [int] NULL,
		[CoinIn] [float] NULL,
		[CoinOut] [float] NULL,
		[CardedPlay] [int] NULL,
		[TotalJackpots] [float] NULL,
		[PBTIn] [float] NULL,
		[sHr] [time](7) NULL
	) ON [PRIMARY]

GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO
