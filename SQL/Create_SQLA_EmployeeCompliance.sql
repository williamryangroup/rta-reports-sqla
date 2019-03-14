USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EmployeeCompliance]    Script Date: 06/15/2016 11:36:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EmployeeCompliance]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EmployeeCompliance](
		[EmpNum] [nvarchar](255) NOT NULL,
		[EmpNameFirst] [nvarchar](255) NULL,
		[EmpNameLast] [nvarchar](255) NULL,
		[EmpJobType] [nvarchar](255) NULL,
		[PktNum] [int] NOT NULL,
		[EventDisplay] [nvarchar](255) NULL,
		[tOut] [datetime] NULL,
		[Asn] [int] NULL,
		[Acp] [int] NULL,
		[Rsp] [int] NULL,
		[Cmp] [int] NULL,
		[CmpMobile] [int] NULL,
		[RejMan] [int] NULL,
		[RejAuto] [int] NULL,
		[RspRTA] [int] NULL,
		[RspCard] [int] NULL,
		[RspRTAandCard] [int] NULL,
		[RspTmSec] [int] NULL,
		[OverallTmSec] [int] NULL,
		[tAsnMin] [datetime] NULL,
		[tRspMin] [datetime] NULL,
		[CustTier] [nvarchar](10) NULL,
		[Rea] [int] NULL,
		[ReaRej] [int] NULL,
	 CONSTRAINT [PK_SQLA_EmployeeCompliance] PRIMARY KEY CLUSTERED 
	(
		[EmpNum] ASC,
		[PktNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


-- TABLE UPDATES

-- 9/29/2016
ALTER TABLE [dbo].[SQLA_EmployeeCompliance] ADD [SourceTable] [nvarchar](255) NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeCompliance] ADD [RtaCardTmSec] [nvarchar](255) NULL
GO

-- 12/3/2018
ALTER TABLE [dbo].[SQLA_EmployeeCompliance] ADD [AcpTmSec] [int] NULL
GO


SET ANSI_PADDING OFF
GO
