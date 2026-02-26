# BI4ALL Governance Baseline (Fabric-safe)

This repo contains a reproducible SQL baseline for a metadata-driven orchestration framework:
- Governance tables (configs + dependencies + dates)
- Monitoring/readiness views
- Dispatch procedures (Bronze + Silver/Gold)
- Run lifecycle updates (DISPATCHED → SUCCESS/FAILED)
- Retry queue (FAILED in last 7 days) + retry dispatcher

## Where to run
Run in Microsoft Fabric SQL endpoint (Warehouse or SQL endpoint you are using for governance).

## Install / rebuild order
Run these SQL files in order:

1. `sql/01_schema_tables.sql`
2. `sql/02_views.sql`
3. `sql/03_procedures.sql`
4. `sql/04_demo_seed.sql`
5. `sql/05_ui_views_procs.sql`

## Quick demo flow

### 1) Bronze dispatch
```sql
EXEC admin.usp_DispatchCopyData_TopN_Log @topN = 10;

SELECT TOP 20 *
FROM admin.v_ui_dispatch_monitor_bronze
ORDER BY lastModifiedDate DESC;


--2) Silver/Gold dispatch (dependency-aware)
EXEC admin.usp_DispatchSilverGold_TopN_Log @topN = 10;

SELECT TOP 30 *
FROM admin.v_ui_dispatch_monitor_silvergold
ORDER BY model, layer, processName;

--3) Mark a run complete
EXEC admin.usp_MarkDispatchRunComplete
  @runId = '<RUN_ID_HERE>',
  @status = 'SUCCESS';

--4) Retry queue (7 days)
SELECT *
FROM admin.v_rerun_candidates_failed_7d
ORDER BY finishedOn DESC;

EXEC admin.usp_DispatchRetries_Failed7d_TopN_Log @topN = 5;