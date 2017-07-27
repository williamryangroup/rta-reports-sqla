USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EmployeeAvailableTime]    Script Date: 07/19/2016 07:00:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EmployeeAvailableTime]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EmployeeAvailableTime](
		[EmpNum] [nvarchar](255) NOT NULL,
		[EmpNameFirst] [nvarchar](50) NULL,
		[EmpNameLast] [nvarchar](50) NULL,
		[EmpJobType] [nvarchar](20) NULL,
		[AvailableStart] [datetime] NOT NULL,
		[AvailableEnd] [datetime] NULL,
		[AvailableSecs] [int] NULL,
	) ON [PRIMARY]
GO


-- TABLE UPDATES

-- mm/dd/yyyy


SET ANSI_PADDING OFF
GO

