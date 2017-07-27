USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EmployeeStatus]    Script Date: 07/19/2016 07:00:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EmployeeStatus]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EmployeeStatus](
		[EmpNum] [nvarchar](40) NOT NULL,
		[EmpNameFirst] [nvarchar](50) NULL,
		[EmpNameLast] [nvarchar](50) NULL,
		[Status] [nvarchar](256) NOT NULL,
		[tStart] [datetime] NOT NULL,
		[tEnd] [datetime] NULL,
	 CONSTRAINT [PK_SQLA_EmployeeStatus] PRIMARY KEY CLUSTERED 
	(
		[EmpNum] ASC,
		[Status] ASC,
		[tStart] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


-- TABLE UPDATES

-- 1/19/2017
ALTER TABLE SQLA_EmployeeStatus ADD StatusCode char(1) NULL
GO
-- 4/13/2017
ALTER TABLE SQLA_EmployeeStatus ADD JobType nvarchar(20) NULL
GO

--7/6/2017
ALTER TABLE SQLA_EmployeeStatus DROP CONSTRAINT PK_SQLA_EmployeeStatus
ALTER TABLE SQLA_EmployeeStatus ALTER COLUMN StatusCode char(2) NOT NULL
ALTER TABLE SQLA_EmployeeStatus ADD CONSTRAINT PK_SQLA_EmployeeStatus PRIMARY KEY (EmpNum,Status,tStart,StatusCode)

SET ANSI_PADDING OFF
GO
