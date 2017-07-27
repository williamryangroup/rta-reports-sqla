USE [RTSS]
GO

/****** Object:  Table [dbo].[SQLA_FreqDist_Bins]    Script Date: 02/19/2016 09:52:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_FreqDist_Bins]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_FreqDist_Bins](
		[BinID] [int] NOT NULL,
		[BinDisplay] [nvarchar](11) NULL,
		[BinMin] [int] NULL,
		[BinMax] [int] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[BinID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (0, '00:00-00:30', 0, 30)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (1, '00:30-01:00', 30, 60)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (2, '01:00-01:30', 60, 90)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (3, '01:30-02:00', 90, 120)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (4, '02:00-02:30', 120, 150)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (5, '02:30-03:00', 150, 180)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (6, '03:00-03:30', 180, 210)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (7, '03:30-04:00', 210, 240)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (8, '04:00-04:30', 240, 270)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (9, '04:30-05:00', 270, 300)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (10, '05:00-06:00', 300, 360)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (11, '06:00-07:00', 360, 420)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (12, '07:00-08:00', 420, 480)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (13, '08:00-09:00', 480, 540)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (14, '09:00-10:00', 540, 600)
	insert into SQLA_FreqDist_Bins (BinID, BinDisplay, BinMin, BinMax) values (15, '>= 10:00', 600, 0)
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

