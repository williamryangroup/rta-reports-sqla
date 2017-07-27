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

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_CustTiers]    Script Date: 02/20/2016 18:57:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_CustTiers]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_CustTiers](
		[TierLevel] [nvarchar](6) NOT NULL,
		[PriorityLevel] [int] NULL,
	 CONSTRAINT [PK_SQLA_CustTiers] PRIMARY KEY CLUSTERED 
	(
		[TierLevel] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EmpJobTypes]    Script Date: 02/20/2016 19:42:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EmpJobTypes]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EmpJobTypes](
		[JobType] [nvarchar](20) NOT NULL,
	 CONSTRAINT [PK_SQLA_EmpJobTypes] PRIMARY KEY CLUSTERED 
	(
		[JobType] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

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


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EmployeeEventTimes]    Script Date: 07/19/2016 07:00:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EmployeeEventTimes]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EmployeeEventTimes](
		[EmpNum] [nvarchar](20) NOT NULL,
		[EmpNameFirst] [nvarchar](50) NULL,
		[EmpNameLast] [nvarchar](50) NULL,
		[EmpJobType] [nvarchar](50) NULL,
		[PktNum] [int] NOT NULL,
		[EventDisplay] [nvarchar](10) NULL,
		[ActivityStart] [datetime] NOT NULL,
		[ActivityEnd] [datetime] NULL,
		[ActivitySecs] [int] NULL,
	 CONSTRAINT [PK_SQLA_EmployeeEventTimes] PRIMARY KEY CLUSTERED 
	(
		[EmpNum] ASC,
		[PktNum] ASC,
		[ActivityStart] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


-- TABLE UPDATES

-- 9/29/2016
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ALTER COLUMN [EmpNum] [nvarchar](255) NOT NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ALTER COLUMN [EmpJobType] [nvarchar](20) NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ALTER COLUMN [EventDisplay] [nvarchar](255) NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tAsn] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tRea] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tDsp] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tAcp] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tRsp] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tRej] [datetime] NULL
GO
ALTER TABLE [dbo].[SQLA_EmployeeEventTimes] ADD [tCmp] [datetime] NULL
GO


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_Employees]    Script Date: 02/20/2016 20:10:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_Employees]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_Employees](
		[CardNum] [nvarchar](20) NOT NULL,
		[NameFirst] [nvarchar](50) NULL,
		[NameLast] [nvarchar](50) NULL,
		[JobType] [nvarchar](20) NULL,
	 CONSTRAINT [PK_SQLA_Employees] PRIMARY KEY CLUSTERED 
	(
		[CardNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES

-- 12/21/2016
ALTER TABLE [dbo].[SQLA_Employees] ALTER COLUMN [CardNum] [nvarchar](40) NOT NULL
GO


SET ANSI_PADDING OFF
GO

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

SET ANSI_PADDING OFF
GO
USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EventDetails]    Script Date: 06/15/2016 11:35:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EventDetails]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EventDetails](
		[PktNum] [int] NOT NULL,
		[tOut] [datetime] NULL,
		[tOutHour] [int] NULL,
		[CustNum] [nvarchar](20) NULL,
		[CustName] [nvarchar](50) NULL,
		[CustTierLevel] [nvarchar](10) NULL,
		[CustPriorityLevel] [int] NULL,
		[Location] [nvarchar](20) NULL,
		[Zone] [nvarchar](10) NULL,
		[EventDisplay] [nvarchar](10) NULL,
		[tAssign] [datetime] NULL,
		[tAccept] [datetime] NULL,
		[tAuthorize] [datetime] NULL,
		[tComplete] [datetime] NULL,
		[CompCode] [int] NULL,
		[HasReject] [int] NULL,
		[EmpNumAsn] [nvarchar](20) NULL,
		[EmpNameAsn] [nvarchar](255) NULL,
		[EmpNumRsp] [nvarchar](20) NULL,
		[EmpNameRsp] [nvarchar](255) NULL,
		[EmpNumCmp] [nvarchar](20) NULL,
		[EmpNameCmp] [nvarchar](255) NULL,
		[RspRTA] [int] NULL,
		[RspCard] [int] NULL,
		[CmpMobile] [int] NULL,
		[CmpGame] [int] NULL,
		[CmpWS] [int] NULL,
		[ResolutionDescID] [int] NULL,
		[ResolutionDesc] [nvarchar](255) NULL,
		[Reassign] [int] NULL,
		[ReassignSupervisor] [int] NULL,
		[FromZone] [nvarchar](10) NULL,
		[EmpJobTypeAsn] [nvarchar](50) NULL,
		[EmpJobTypeRsp] [nvarchar](50) NULL,
		[EmpJobTypeCmp] [nvarchar](50) NULL,
		[RspSecs] [int] NULL,
		[CmpSecs] [int] NULL,
		[TotSecs] [int] NULL,
		[AsnTakeID] [int] NULL,
		[AsnTake] [nvarchar](20) NULL
	) ON [PRIMARY]
GO


-- TABLE UPDATES

-- 9/29/2016
ALTER TABLE [dbo].[SQLA_EventDetails] ADD [SourceTable] [nvarchar](255) NULL
GO
ALTER TABLE [dbo].[SQLA_EventDetails] ADD [AmtEvent] [nvarchar](12) NULL
GO

--11/17
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [EmpNumAsn] [nvarchar](40) NULL
GO
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [EmpNumRsp] [nvarchar](40) NULL
GO
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [EmpNumCmp] [nvarchar](40) NULL
GO

--1/5
ALTER TABLE [dbo].[SQLA_EventDetails] ALTER COLUMN [CustNum] [nvarchar](40) NULL
GO


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EventDetails_JPVER]    Script Date: 08/24/2016 09:00:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EventDetails_JPVER]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EventDetails_JPVER](
		[PktNum] [int] NOT NULL,
		[EventDisplay] [nvarchar](10) NULL,
		[tOut] [datetime] NULL,
		[tComplete] [datetime] NULL,
		[Source] [nvarchar](255) NULL,
		[EmpNum] [nvarchar](255) NULL,
		[EmpName] [nvarchar](255) NULL,
		[EmpNameFirst] [nvarchar](255) NULL,
		[EmpNameLast] [nvarchar](255) NULL,
		[EmpJobType] [nvarchar](255) NULL,
	 CONSTRAINT [PK_SQLA_EventDetails_JPVER] PRIMARY KEY CLUSTERED 
	(
		[PktNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_EventTypes]    Script Date: 02/20/2016 20:22:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_EventTypes]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_EventTypes](
		[EventDisplay] [nvarchar](10) NOT NULL,
	 CONSTRAINT [PK_SQLA_EventTypes] PRIMARY KEY CLUSTERED 
	(
		[EventDisplay] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_FloorActivity]    Script Date: 04/12/2016 12:15:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_FloorActivity]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_FloorActivity](
		[tOut] [datetime] NOT NULL,
		[ActivityTypeID] [int] NULL,
		[State] [nvarchar](255) NULL,
		[Activity] [nvarchar](255) NULL,
		[Location] [nvarchar](255) NULL,
		[Zone] [nvarchar](255) NULL,
		[PktNum] [int] NULL,
		[Tier] [nvarchar](255) NULL,
		[EmpNum] [nvarchar](255) NULL,
		[EmpName] [nvarchar](255) NULL,
		[Source] [nvarchar](255) NULL,
		[Description] [nvarchar](255) NULL,
		[RejAfterDisp] [nvarchar](255) NULL,
		[SourceTable] [nvarchar](255) NULL,
		[SourceTableID] [int] NULL,
		[SourceTableID2] [nvarchar](50) NULL,
		[SourceTableDttm1] [datetime] NULL,
		[SourceTableDttm2] [datetime] NULL
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

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

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_New_EmpAct]    Script Date: 04/12/2016 11:12:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_New_EmpAct]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_New_EmpAct](
		[CardNum] [nvarchar](50) NOT NULL,
		[tOut] [datetime] NOT NULL,
		[tIn] [datetime] NOT NULL,
	 CONSTRAINT [PK_SQLA_New_EmpAct] PRIMARY KEY CLUSTERED 
	(
		[CardNum] ASC,
		[tOut] ASC,
		[tIn] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_New_Events]    Script Date: 04/12/2016 11:12:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_New_Events]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_New_Events](
		[PktNum] [int] NOT NULL,
	 CONSTRAINT [PK_SQLA_New_Events] PRIMARY KEY CLUSTERED 
	(
		[PktNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_New_SEQ]    Script Date: 04/12/2016 11:12:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_New_SEQ]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_New_SEQ](
		[SEQ] [int] NOT NULL,
	 CONSTRAINT [PK_SQLA_New_SEQ] PRIMARY KEY CLUSTERED 
	(
		[SEQ] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

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

USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_ZoneArea]    Script Date: 02/20/2016 17:54:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_ZoneArea]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_ZoneArea](
		[ZoneArea] [nvarchar](5) NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[ZoneArea] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

USE [RTA_SQLA]
GO

/****** Object:  UserDefinedFunction [dbo].[RemoveNonASCII]    Script Date: 09/13/2016 11:06:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[RemoveNonASCII]') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION [RemoveNonASCII]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[RemoveNonASCII] 
(
    @nstring nvarchar(255)
)
RETURNS varchar(255)
AS
BEGIN

    DECLARE @Result varchar(255)
    SET @Result = ''

    DECLARE @nchar nvarchar(1)
    DECLARE @position int

    SET @position = 1
    WHILE @position <= LEN(@nstring)
    BEGIN
        SET @nchar = SUBSTRING(@nstring, @position, 1)
        --Unicode & ASCII are the same from 1 to 255.
        --Only Unicode goes beyond 255
        --0 to 31 are non-printable characters
        IF UNICODE(@nchar) between 32 and 255
            SET @Result = @Result + @nchar
        SET @position = @position + 1
    END

    RETURN @Result

END

GO


USE [RTA_SQLA]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_String_To_Table]    Script Date: 07/09/2015 09:55:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_String_To_Table]') and OBJECTPROPERTY(id, N'IsTableFunction') = 1)
	DROP FUNCTION [fn_String_To_Table]
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[fn_String_To_Table]
(
	@String VARCHAR(max),
	@Delimeter char(1),
	@TrimSpace bit
)
RETURNS 
@Table TABLE
(
	Val varchar(4000)
)
AS
BEGIN
	DECLARE @Val VARCHAR(4000)
	
	WHILE LEN(@String) > 0
	BEGIN
		SET @Val = LEFT(@String, ISNULL(NULLIF(CHARINDEX(@Delimeter, @String) - 1, -1), LEN(@String)))
        SET @String = SUBSTRING(@String, ISNULL(NULLIF(CHARINDEX(@Delimeter, @String), 0), LEN(@String)) + 1, LEN(@String))
		
		IF @TrimSpace = 1 Set @Val = LTRIM(RTRIM(@Val))
		
		INSERT INTO @Table ( [Val] ) VALUES ( @Val )
    END

	RETURN 
END


GO


use RTA_SQLA
GO

DROP INDEX [xn_SQLA_FloorActivity_PktNumState] ON [dbo].[SQLA_FloorActivity]
GO

DROP INDEX [xn_SQLA_FloorActivity_SourceTable] ON [dbo].[SQLA_FloorActivity]
GO

DROP INDEX [xn_SQLA_FloorActivity_SourceTableDttm] ON [dbo].[SQLA_FloorActivity]
GO

DROP INDEX [xn_SQLA_EmployeeCompliance_PktNum] ON [dbo].[SQLA_EmployeeCompliance]
GO

DROP INDEX [xn_SQLA_EventDetails_PktNum] ON [dbo].[SQLA_EventDetails]
GO

DROP INDEX [xn_SQLA_EmployeeEventTimes_PktNum] ON [dbo].[SQLA_EmployeeEventTimes]
GO

DROP INDEX [xn_SQLA_EmployeeEventTimes_EmpStartEnd] ON [dbo].[SQLA_EmployeeEventTimes]
GO

CREATE NONCLUSTERED INDEX [xn_SQLA_FloorActivity_PktNumState] ON [dbo].[SQLA_FloorActivity]([PktNum],[ActivityTypeID],[State]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [xn_SQLA_FloorActivity_SourceTable] ON [dbo].[SQLA_FloorActivity]([SourceTable],[SourceTableID]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [xn_SQLA_FloorActivity_SourceTableDttm] ON [dbo].[SQLA_FloorActivity]([SourceTable],[SourceTableID2],[SourceTableDttm1],[SourceTableDttm2]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [xn_SQLA_EmployeeCompliance_PktNum] ON [dbo].[SQLA_EmployeeCompliance]([PktNum],[SourceTable]) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [xn_SQLA_EventDetails_PktNum] ON [dbo].[SQLA_EventDetails]([PktNum],[SourceTable]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [xn_SQLA_EmployeeEventTimes_PktNum] ON [dbo].[SQLA_EmployeeEventTimes]([PktNum]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [xn_SQLA_EmployeeEventTimes_EmpStartEnd] ON [dbo].[SQLA_EmployeeEventTimes]([EmpNum],[ActivityStart],[ActivityEnd]) ON [PRIMARY]
GO
