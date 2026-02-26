/* =====================================================================================
   BI4ALL Governance Baseline — Fabric-safe (VIEWS)
   Run after 01_schema_tables.sql
   ===================================================================================== */

SET NOCOUNT ON;

-- Orphans: active bronze processes not present in dependency config (either parent or child)
CREATE OR ALTER VIEW admin.v_runPreview_orphans AS
WITH active_processes AS (
    SELECT DISTINCT model, destinationObjectPattern AS processName
    FROM admin.copyDataConfig
    WHERE flagActive = 1
),
dep_processes AS (
    SELECT DISTINCT model, parentProcess AS processName
    FROM admin.processDependencyConfig WHERE isActive = 1
    UNION
    SELECT DISTINCT model, childProcess AS processName
    FROM admin.processDependencyConfig WHERE isActive = 1
)
SELECT a.model, a.processName
FROM active_processes a
LEFT JOIN dep_processes d
  ON d.model = a.model AND d.processName = a.processName
WHERE d.processName IS NULL;

-- Readiness (orphans only)
CREATE OR ALTER VIEW admin.v_runPreview_readiness AS
WITH orph AS (
    SELECT model, COUNT(*) AS orphan_count
    FROM admin.v_runPreview_orphans
    GROUP BY model
),
models AS (
    SELECT DISTINCT model
    FROM admin.copyDataConfig
    WHERE flagActive = 1
)
SELECT m.model,
       COALESCE(o.orphan_count, 0) AS orphan_count,
       CASE WHEN COALESCE(o.orphan_count, 0) > 0 THEN 'BLOCKED' ELSE 'READY' END AS readiness_status
FROM models m
LEFT JOIN orph o ON o.model = m.model;

-- Readiness message
CREATE OR ALTER VIEW admin.v_runPreview_readinessMessage AS
SELECT r.model,
       r.readiness_status,
       r.orphan_count,
       CASE
           WHEN r.orphan_count > 0 THEN CONCAT(
               'BLOCKED: orphan process(es) detected. Example: ',
               (SELECT TOP 1 o.processName
                FROM admin.v_runPreview_orphans o
                WHERE o.model = r.model
                ORDER BY o.processName)
           )
           ELSE 'READY: no orphans detected.'
       END AS readiness_message
FROM admin.v_runPreview_readiness r;

-- Last run per model+processName
CREATE OR ALTER VIEW admin.v_runPreview_lastRun AS
WITH last_run AS (
    SELECT
        model,
        objectName AS processName,
        status,
        startDate,
        endDate,
        ROW_NUMBER() OVER (PARTITION BY model, objectName ORDER BY startDate DESC) AS rn
    FROM log.copyDataLog
    WHERE objectName IS NOT NULL
)
SELECT
    model,
    processName,
    status,
    startDate AS startedOn,
    endDate   AS finishedOn
FROM last_run
WHERE rn = 1;

-- Derived status mapping (includes DISPATCHED)
CREATE OR ALTER VIEW admin.v_runPreview_processStatus AS
SELECT
    model,
    processName,
    status AS last_status,
    startedOn,
    finishedOn,
    CASE
        WHEN status IS NULL THEN 'UNKNOWN'
        WHEN UPPER(status) LIKE '%DISPATCH%' THEN 'DISPATCHED'
        WHEN UPPER(status) LIKE '%RUN%'      THEN 'RUNNING'
        WHEN UPPER(status) LIKE '%FAIL%'     THEN 'FAILED'
        WHEN UPPER(status) LIKE '%SKIP%'     THEN 'SKIPPED'
        WHEN UPPER(status) LIKE '%SUCC%'     THEN 'OK'
        ELSE 'UNKNOWN'
    END AS derived_status
FROM admin.v_runPreview_lastRun;

-- Readiness v2: orphans + failures
CREATE OR ALTER VIEW admin.v_runPreview_readiness_v2 AS
WITH orphan_count AS (
    SELECT model, COUNT(*) AS orphan_cnt
    FROM admin.v_runPreview_orphans
    GROUP BY model
),
failure_count AS (
    SELECT model, COUNT(*) AS failed_cnt
    FROM admin.v_runPreview_processStatus
    WHERE derived_status = 'FAILED'
    GROUP BY model
),
models AS (
    SELECT DISTINCT model
    FROM admin.copyDataConfig
    WHERE flagActive = 1
)
SELECT m.model,
       COALESCE(o.orphan_cnt, 0) AS orphan_count,
       COALESCE(f.failed_cnt, 0) AS failed_count,
       CASE
           WHEN COALESCE(o.orphan_cnt, 0) > 0 THEN 'BLOCKED'
           WHEN COALESCE(f.failed_cnt, 0) > 0 THEN 'DEGRADED'
           ELSE 'READY'
       END AS readiness_status
FROM models m
LEFT JOIN orphan_count o ON m.model = o.model
LEFT JOIN failure_count f ON m.model = f.model;

-- Bronze candidates (simple validity + active)
CREATE OR ALTER VIEW admin.v_dispatch_copyData_candidates AS
SELECT
    c.configId,
    c.model,
    c.destinationObjectPattern AS processName,
    c.sourceSystemName,
    c.sourceSystemType,
    c.sourceLocationName,
    c.sourceObjectName,
    c.destinationSystemName,
    c.destinationSystemType,
    c.destinationDirectoryPattern,
    c.destinationObjectType,
    c.extractType,
    c.deltaStartDate,
    c.deltaEndDate,
    c.deltaDateColumn,
    c.deltaFilterCondition,
    c.flagBlock,
    c.blockSize,
    c.blockColumn,
    c.flagActive,
    c.lastModifiedDate
FROM admin.copyDataConfig c
WHERE c.flagActive = 1
  AND c.model IS NOT NULL
  AND c.sourceObjectName IS NOT NULL
  AND c.destinationObjectPattern IS NOT NULL;

-- Bronze UI monitor (eligibility + last dispatched + last status)
CREATE OR ALTER VIEW admin.v_ui_dispatch_monitor_bronze AS
WITH last_dispatch AS (
    SELECT
        l.model,
        l.objectName AS processName,
        MAX(l.startDate) AS lastDispatchedOn
    FROM log.copyDataLog l
    WHERE l.status = 'DISPATCHED'
    GROUP BY l.model, l.objectName
)
SELECT
    c.configId,
    c.model,
    c.destinationObjectPattern AS processName,
    c.sourceObjectName,
    c.flagActive,
    c.lastModifiedDate,
    CASE WHEN cand.configId IS NOT NULL THEN 'ELIGIBLE' ELSE 'NOT_ELIGIBLE' END AS dispatch_eligibility,
    ld.lastDispatchedOn,
    ps.last_status,
    ps.startedOn,
    ps.finishedOn,
    ps.derived_status
FROM admin.copyDataConfig c
LEFT JOIN admin.v_dispatch_copyData_candidates cand
  ON cand.configId = c.configId
LEFT JOIN last_dispatch ld
  ON ld.model = c.model AND ld.processName = c.destinationObjectPattern
LEFT JOIN admin.v_runPreview_processStatus ps
  ON ps.model = c.model AND ps.processName = c.destinationObjectPattern;

-- Dependency status (strict: parent satisfied only if OK)
CREATE OR ALTER VIEW admin.v_dependency_status AS
SELECT
    d.model,
    d.parentProcess,
    d.childProcess,
    d.isActive,
    ps_parent.derived_status AS parent_status,
    CASE
        WHEN d.isActive = 0 THEN 'INACTIVE_LINK'
        WHEN ps_parent.derived_status = 'OK' THEN 'SATISFIED'
        WHEN ps_parent.derived_status IS NULL THEN 'BLOCKED_NO_RUN'
        ELSE CONCAT('BLOCKED_', ps_parent.derived_status)
    END AS dependency_state
FROM admin.processDependencyConfig d
LEFT JOIN admin.v_runPreview_processStatus ps_parent
  ON ps_parent.model = d.model AND ps_parent.processName = d.parentProcess;

-- Silver/Gold candidates (STRICT + MUST HAVE DEPS + ALL SATISFIED)
CREATE OR ALTER VIEW admin.v_dispatch_silvergold_candidates AS
WITH active_sg AS (
    SELECT
        sg.model,
        sg.layer,
        sg.objectName AS processName
    FROM admin.silverGoldConfig sg
    WHERE sg.flagActive = 1
),
dep_summary AS (
    SELECT
        ds.model,
        ds.childProcess AS processName,
        SUM(CASE WHEN ds.isActive = 1 THEN 1 ELSE 0 END) AS active_dep_links,
        SUM(CASE WHEN ds.isActive = 1 AND ds.dependency_state = 'SATISFIED' THEN 1 ELSE 0 END) AS satisfied_links
    FROM admin.v_dependency_status ds
    GROUP BY ds.model, ds.childProcess
)
SELECT
    a.model,
    a.layer,
    a.processName,
    d.active_dep_links,
    d.satisfied_links
FROM active_sg a
JOIN dep_summary d
  ON d.model = a.model AND d.processName = a.processName
WHERE d.active_dep_links > 0
  AND d.active_dep_links = d.satisfied_links;

-- Silver/Gold UI monitor
CREATE OR ALTER VIEW admin.v_ui_dispatch_monitor_silvergold AS
WITH dep_block AS (
    SELECT
        ds.model,
        ds.childProcess AS processName,
        SUM(CASE WHEN ds.isActive = 1 THEN 1 ELSE 0 END) AS active_dep_links,
        SUM(CASE WHEN ds.isActive = 1 AND ds.dependency_state = 'SATISFIED' THEN 1 ELSE 0 END) AS satisfied_links,
        SUM(CASE WHEN ds.isActive = 1 AND ds.dependency_state <> 'SATISFIED' THEN 1 ELSE 0 END) AS blocking_links
    FROM admin.v_dependency_status ds
    GROUP BY ds.model, ds.childProcess
),
last_dispatch AS (
    SELECT
        l.model,
        l.objectName AS processName,
        MAX(l.startDate) AS lastDispatchedOn
    FROM log.copyDataLog l
    WHERE l.sourceReadCommand LIKE 'dispatch_runId=RUN_SG_%'
       OR l.sourceReadCommand LIKE 'dispatch_runId=RUN_RETRY_%'
    GROUP BY l.model, l.objectName
)
SELECT
    sg.model,
    sg.layer,
    sg.objectName AS processName,
    sg.flagActive,
    COALESCE(db.active_dep_links, 0) AS active_dep_links,
    COALESCE(db.satisfied_links, 0)  AS satisfied_links,
    COALESCE(db.blocking_links, 0)   AS blocking_links,
    CASE
        WHEN sg.flagActive <> 1 THEN 'NOT_ACTIVE'
        WHEN COALESCE(db.active_dep_links, 0) = 0 THEN 'BLOCKED_NO_DEPENDENCIES'
        WHEN COALESCE(db.blocking_links, 0) > 0 THEN 'BLOCKED_DEPENDENCIES'
        ELSE 'ELIGIBLE'
    END AS dispatch_eligibility,
    ld.lastDispatchedOn,
    ps.last_status,
    ps.derived_status,
    ps.startedOn,
    ps.finishedOn
FROM admin.silverGoldConfig sg
LEFT JOIN dep_block db
  ON db.model = sg.model AND db.processName = sg.objectName
LEFT JOIN last_dispatch ld
  ON ld.model = sg.model AND ld.processName = sg.objectName
LEFT JOIN admin.v_runPreview_processStatus ps
  ON ps.model = sg.model AND ps.processName = sg.objectName;

-- Failed rerun candidates (no window)
CREATE OR ALTER VIEW admin.v_rerun_candidates_failed AS
SELECT
    f.model,
    f.processName,
    f.last_status,
    f.derived_status,
    f.startedOn,
    f.finishedOn
FROM admin.v_runPreview_processStatus f
WHERE f.derived_status = 'FAILED';

-- Failed rerun candidates (last 7 days)
CREATE OR ALTER VIEW admin.v_rerun_candidates_failed_7d AS
SELECT
    f.model,
    f.processName,
    f.last_status,
    f.derived_status,
    f.startedOn,
    f.finishedOn
FROM admin.v_runPreview_processStatus f
WHERE f.derived_status = 'FAILED'
  AND f.finishedOn >= DATEADD(DAY, -7, SYSDATETIME());