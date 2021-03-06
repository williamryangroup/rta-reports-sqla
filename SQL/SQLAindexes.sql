USE [RTA_SQLA]
GO

DROP INDEX [xn_SQLA_FloorActivity_tOut] ON [dbo].[SQLA_FloorActivity]
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
DROP INDEX [xn_SQLA_EmployeeEventTimes_ActEnd] ON [dbo].[SQLA_EmployeeEventTimes]
GO


CREATE CLUSTERED INDEX [xn_SQLA_FloorActivity_tOut] ON [dbo].[SQLA_FloorActivity]([tOut]) ON [PRIMARY]
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
CREATE NONCLUSTERED INDEX [xn_SQLA_EmployeeEventTimes_ActEnd] ON [dbo].[SQLA_EmployeeEventTimes]([ActivityEnd]) ON [PRIMARY]
GO


USE [RTSS]
GO

CREATE NONCLUSTERED INDEX [xn_SYSTEMLOG1_EvtType] ON [dbo].[SYSTEMLOG1]([EvtType]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [xn_SYSTEMLOG1_EvtDetail3] ON [dbo].[SYSTEMLOG1]([EvtDetail3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [xn_EVENT_STATE_LOG1_PktNum] ON EVENT_STATE_LOG1 ([PktNum]) ON [PRIMARY]
GO


INSERT INTO SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','UseCustNamesInReports','1')
GO
INSERT INTO SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','UseEmpNamesInReports','1')
GO
INSERT INTO SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','RptParamInitStartTm','00:00:00')
GO
INSERT INTO SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','RptParamInitStartDateDiff','-2')
GO
INSERT INTO SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','RptParamInitEndTm','23:59:59')
GO
INSERT INTO SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','RptParamInitEndDateDiff','0')
GO
INSERT INTO SYSTEMSETTINGS (ConfigSection, ConfigParam, Setting) values ('REPORTS','EvtDetailShowAssetField','0')
GO
