USE [RTA_SQLA]
GO

/****** Object:  Table [dbo].[SQLA_Legend]    Script Date: 05/13/2016 08:30:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

-- CREATE INITIAL TABLE IF IT DOES NOT EXIST
IF NOT EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[SQLA_Legend]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	CREATE TABLE [dbo].[SQLA_Legend](
		[Report] [nvarchar](50) NULL,
		[Key] [nvarchar](50) NULL,
		[Definition] [nvarchar](255) NULL
	) ON [PRIMARY]

	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Accept Mobile','Event was accepted via mobile device')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Assign','Event was assigned to employee')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Assign Supervisor','Event was assigned to supervisor after designated time and no attendant was available')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Authorize Card In','Event was authorized/responded to via card-in at game')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Authorize Initial','Initial response captured for event')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Authorize Mobile','Event was responded to via mobile device')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Complete','Event completion')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Display Workstation','Event was displayed on the workstation')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Event Display Mobile','Event button on mobile device was pressed by employee')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Get Event','GetEvent call was made from device to server to get any assigned events')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Re-assign','Event was reassigned to employee')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reassign Attendant','Event was reassigned to attendant')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reassign Display Mobile','Reassign pop-up was displayed on mobile device')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reassign Reject','Reassign was rejected')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reassign Remove','Employee was removed from event because they were reassigned a higher priority event')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reassign Supervisor','Event was reassigned to supervisor')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reassign Supervisor Reject','Event reassigned to supervisor was rejected')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reject Auto','Event was auto-rejected, see Description field for reason')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reject Auto Device','Event was auto-rejected by the mobile device')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reject Auto Server','Event was auto-rejected by the server')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Reject Manual','Event was manually rejected by employee')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Remove','Event was completed by removing it via the workstation or supervisor dashboard')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','Respond Mobile','Event was responded to via mobile device')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','RTSS Open','Received event from slot feed was opened in RTSS to be assigned')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','RTSS Receive','Event was received by RTSS from slot feed')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','SupervAdmEmp','Supervisor performed an admin function on an employee;  see Activity field for action taken')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','SupervAdmEvt','Supervisor performed an admin function on an event;  see Activity field for action taken')
	insert into SQLA_Legend (Report, [Key], Definition) values ('FloorActivityState','SupervDashboard','Dashboard views by supervisor; see Activity tab for action taken')
GO

-- TABLE UPDATES


SET ANSI_PADDING OFF
GO

