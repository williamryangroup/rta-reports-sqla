select t3.DateTime, t3.PktNum, d.EventDisplay, EmpJobType = '', OpnToAsnSecs = sum(datediff(second,t3.tOpn,t3.tAsn)), AcpToRsp = 0, RspToCmp = 0
  from (
select t2.DateTime, t2.PktNum, 
       tOpn = case when t2.tOpn < t2.DateTime then t2.DateTime else t2.tOpn end,
	   tAsn = case when t2.tAsn > dateadd(minute,15,t2.DateTime) then dateadd(minute,15,t2.DateTime) else t2.tAsn end
  from (
select dt.DateTime, ed.PktNum, tOpn = ed.tOut, tAsn = min(et.ActivityStart)
  from DateTimes as dt
 inner join SQLA_EventDetails as ed
    on ed.tOut <= dateadd(minute,15,dt.DateTime)
   and ed.tOut >= dt.DateTime
 inner join RTA_SQLA.dbo.SQLA_EmployeeEventTimes et
    on et.PktNum = ed.PktNum
   and et.ActivityStart >= dt.DateTime
 where dt.DateTime >= '10/1/2016' and dt.DateTime < '10/2/2016'
   and ed.PktNum not in (1,2,3)
   and ed.EventDisplay not in ('OOS','EMPCARD') 
 group by dt.DateTime, ed.PktNum, ed.tOut
 union all
select DateTime, PktNum, tOpn = max(tOpn), tAsn
   from (
select dt.DateTime, ets.PktNum, tOpn = ets.ActivityEnd, tAsn = min(ete.ActivityStart)
  from DateTimes as dt
 inner join RTA_SQLA.dbo.SQLA_EmployeeEventTimes ets
    on ets.ActivityEnd <= dateadd(minute,15,dt.DateTime)
 inner join RTA_SQLA.dbo.SQLA_EmployeeEventTimes ete
    on ete.PktNum = ets.PktNum
   and ete.ActivityStart >= ets.ActivityEnd
   and ete.ActivityStart > dt.DateTime
 where dt.DateTime >= '10/1/2016' and dt.DateTime < '10/2/2016'
   and ets.PktNum not in (1,2,3)
   and ets.EventDisplay not in ('OOS','EMPCARD') 
 group by dt.DateTime, ets.PktNum, ets.ActivityEnd ) as t
 group by t.DateTime, t.PktNum, t.tAsn ) as t2 ) as t3
  left join SQLA_EventDetails as d
    on d.PktNum = t3.PktNum
 group by t3.DateTime, t3.PktNum, d.EventDisplay
 order by t3.DateTime, t3.PktNum
