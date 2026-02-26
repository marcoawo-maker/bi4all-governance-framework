/* =====================================================================================
   BI4ALL Governance Baseline (v1) + Extensions (v2)
   -------------------------------------------------------------------------------------
   Purpose
   - v1: Core governance tables + basic readiness (orphans) + execution log + status views
   - v2: Add inferredMembersConfig + Silver/Gold config + Silver/Gold dependency

   Notes
   - This script is "rebuild from scratch": it drops and recreates objects.
   - Keep this as a repeatable baseline you can run any time to reset the demo.
   ===================================================================================== */


/* =====================================================================================
   STEP 0: DROP VIEWS (safe to run repeatedly)
   ===================================================================================== */

IF OBJECT_ID('admin.v_runPreview_readinessMessage','V') IS NOT NULL DROP VIEW admin.v_runPreview_readinessMessage;
IF OBJECT_ID('admin.v_runPreview_readiness','V')        IS NOT NULL DROP VIEW admin.v_runPreview_readiness;
IF OBJECT_ID('admin.v_runPreview_orphans','V')          IS NOT NULL DROP VIEW admin.v_runPreview_orphans;

-- v1 operational views
IF OBJECT_ID('admin.v_runPreview_lastRun','V')          IS NOT NULL DROP VIEW admin.v_runPreview_lastRun;
IF OBJECT_ID('admin.v_runPreview_processStatus','V')    IS NOT NULL DROP VIEW admin.v_runPreview_processStatus;
IF OBJECT_ID('admin.v_runPreview_readiness_v2','V')     IS NOT NULL DROP VIEW admin.v_runPreview_readiness_v2;
GO


/* =====================================================================================
   STEP 1: DROP TABLES (safe to run repeatedly)
   ===================================================================================== */

-- Logs first (depends on nothing)
IF OBJECT_ID('log.copyDataLog','U') IS NOT NULL DROP TABLE log.copyDataLog;

-- v2 tables
IF OBJECT_ID('admin.silverGoldDependency','U')   IS NOT NULL DROP TABLE admin.silverGoldDependency;
IF OBJECT_ID('admin.silverGoldConfig','U')       IS NOT NULL DROP TABLE admin.silverGoldConfig;
IF OBJECT_ID('admin.inferredMembersConfig','U')  IS NOT NULL DROP TABLE admin.inferredMembersConfig;

-- v1 tables
IF OBJECT_ID('admin.processDependencyConfig','U') IS NOT NULL DROP TABLE admin.processDependencyConfig;
IF OBJECT_ID('admin.processDatesConfig','U')      IS NOT NULL DROP TABLE admin.processDatesConfig;
IF OBJECT_ID('admin.copyDataConfig','U')          IS NOT NULL DROP TABLE admin.copyDataConfig;
GO


/* =====================================================================================
   STEP 2: CREATE SCHEMAS (if missing)
   ===================================================================================== */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'admin') EXEC('CREATE SCHEMA admin');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'log')   EXEC('CREATE SCHEMA log');
GO


/* =====================================================================================
   STEP 3: CREATE CORE TABLES (v1)
   ===================================================================================== */

-- Ingestion configuration (simplified baseline)
CREATE TABLE admin.copyDataConfig (
    copyDataConfigId BIGINT IDENTITY NOT NULL,
    model            VARCHAR(100) NOT NULL,
    sourceSystem     VARCHAR(100) NOT NULL,
    sourceObject     VARCHAR(200) NOT NULL,
    targetLayer      VARCHAR(20)  NOT NULL,
    targetObject     VARCHAR(200) NOT NULL,
    loadType         VARCHAR(20)  NOT NULL,
    isActive         BIT          NOT NULL,
    createdOn        DATETIME2(3) NOT NULL,
    createdBy        VARCHAR(100) NULL,
    updatedOn        DATETIME2(3) NULL,
    updatedBy        VARCHAR(100) NULL
);
GO

-- Ingestion dependencies (generic parent -> child)
CREATE TABLE admin.processDependencyConfig (
    processDependencyConfigId BIGINT IDENTITY NOT NULL,
    model         VARCHAR(100) NOT NULL,
    parentProcess VARCHAR(200) NOT NULL,
    childProcess  VARCHAR(200) NOT NULL,
    isActive      BIT NOT NULL,
    createdOn     DATETIME2(3) NOT NULL,
    createdBy     VARCHAR(100) NULL
);
GO

-- Process date controls (simplified baseline)
CREATE TABLE admin.processDatesConfig (
    processDatesConfigId BIGINT IDENTITY NOT NULL,
    model                VARCHAR(100) NOT NULL,
    processName          VARCHAR(200) NOT NULL,
    dateColumn           VARCHAR(200) NULL,
    startDate            DATE NULL,
    endDate              DATE NULL,
    isActive             BIT NOT NULL,
    createdOn            DATETIME2(3) NOT NULL,
    createdBy            VARCHAR(100) NULL,
    updatedOn            DATETIME2(3) NULL,
    updatedBy            VARCHAR(100) NULL
);
GO

-- Execution log (governance-friendly; used for demo monitoring)
CREATE TABLE log.copyDataLog (
    copyDataLogId BIGINT IDENTITY NOT NULL,
    model         VARCHAR(100) NOT NULL,
    processName   VARCHAR(200) NOT NULL,
    runId         VARCHAR(100) NOT NULL,
    status        VARCHAR(30)  NOT NULL,
    startedOn     DATETIME2(3) NOT NULL,
    finishedOn    DATETIME2(3) NULL,
    rowsRead      BIGINT NULL,
    rowsWritten   BIGINT NULL,
    message       VARCHAR(4000) NULL
);
GO


/* =====================================================================================
   STEP 4: SEED MINIMAL CONFIG DATA (v1)
   ===================================================================================== */

-- DemoModel: includes 1 orphan (brz_orphan)
INSERT INTO admin.copyDataConfig
(model,sourceSystem,sourceObject,targetLayer,targetObject,loadType,isActive,createdOn,createdBy)
VALUES
('DemoModel','DemoSource','src_sales','BRZ','brz_sales','FULL',1,SYSUTCDATETIME(),'seed'),
('DemoModel','DemoSource','brz_sales','SLV','slv_sales','INCR',1,SYSUTCDATETIME(),'seed'),
('DemoModel','DemoSource','slv_sales','GLD','gld_sales','INCR',1,SYSUTCDATETIME(),'seed'),
('DemoModel','DemoSource','src_lonely','BRZ','brz_orphan','FULL',1,SYSUTCDATETIME(),'seed');

INSERT INTO admin.processDependencyConfig
(model,parentProcess,childProcess,isActive,createdOn,createdBy)
VALUES
('DemoModel','brz_sales','slv_sales',1,SYSUTCDATETIME(),'seed'),
('DemoModel','slv_sales','gld_sales',1,SYSUTCDATETIME(),'seed');

-- framework: no orphans (all connected)
INSERT INTO admin.copyDataConfig
(model,sourceSystem,sourceObject,targetLayer,targetObject,loadType,isActive,createdOn,createdBy)
VALUES
('framework','adventureworks2022','Person.Person','BRZ','brz_Person','INCR',1,SYSUTCDATETIME(),'seed'),
('framework','adventureworks2022','Sales.SalesPerson','BRZ','brz_SalesPerson','FULL',1,SYSUTCDATETIME(),'seed'),
('framework','adventureworks2022','Sales.Store','BRZ','brz_Store','FULL',1,SYSUTCDATETIME(),'seed'),
('framework','adventureworks2022','Sales.SalesTerritory','BRZ','brz_SalesTerritory','FULL',1,SYSUTCDATETIME(),'seed'),
('framework','adventureworks2022','Sales.SalesOrderDetail','BRZ','brz_SalesOrderDetail','FULL',1,SYSUTCDATETIME(),'seed');

INSERT INTO admin.processDependencyConfig
(model,parentProcess,childProcess,isActive,createdOn,createdBy)
VALUES
('framework','brz_Person','brz_SalesPerson',1,SYSUTCDATETIME(),'seed'),
('framework','brz_SalesPerson','brz_SalesOrderDetail',1,SYSUTCDATETIME(),'seed'),
('framework','brz_Store','brz_SalesOrderDetail',1,SYSUTCDATETIME(),'seed'),
('framework','brz_SalesTerritory','brz_SalesOrderDetail',1,SYSUTCDATETIME(),'seed');

-- processDatesConfig: minimal presence proof
INSERT INTO admin.processDatesConfig
(model,processName,dateColumn,startDate,endDate,isActive,createdOn,createdBy)
VALUES
('DemoModel','slv_sales','SaleDate','2025-01-01',NULL,1,SYSUTCDATETIME(),'seed'),
('framework','brz_Person','ModifiedDate','2024-01-01',NULL,1,SYSUTCDATETIME(),'seed');
GO


/* =====================================================================================
   STEP 5: READINESS (v1) - ORPHANS + MODEL STATUS
   ===================================================================================== */

-- Orphans = active processes with no dependency relation at all
CREATE VIEW admin.v_runPreview_orphans
AS
WITH active_processes AS (
    SELECT DISTINCT model, targetObject AS processName
    FROM admin.copyDataConfig
    WHERE isActive = 1
),
dep_processes AS (
    SELECT DISTINCT model, parentProcess AS processName
    FROM admin.processDependencyConfig
    WHERE isActive = 1
    UNION
    SELECT DISTINCT model, childProcess AS processName
    FROM admin.processDependencyConfig
    WHERE isActive = 1
)
SELECT a.model, a.processName
FROM active_processes a
LEFT JOIN dep_processes d
    ON d.model = a.model
   AND d.processName = a.processName
WHERE d.processName IS NULL;
GO

-- Simple readiness: BLOCKED if any orphan exists
CREATE VIEW admin.v_runPreview_readiness
AS
WITH orph AS (
    SELECT model, COUNT(*) AS orphan_count
    FROM admin.v_runPreview_orphans
    GROUP BY model
),
models AS (
    SELECT DISTINCT model
    FROM admin.copyDataConfig
    WHERE isActive = 1
)
SELECT
    m.model,
    COALESCE(o.orphan_count, 0) AS orphan_count,
    CASE
        WHEN COALESCE(o.orphan_count, 0) > 0 THEN 'BLOCKED'
        ELSE 'READY'
    END AS readiness_status
FROM models m
LEFT JOIN orph o
    ON o.model = m.model;
GO

-- Human-readable readiness message
CREATE VIEW admin.v_runPreview_readinessMessage
AS
SELECT
    r.model,
    r.readiness_status,
    r.orphan_count,
    CASE
        WHEN r.orphan_count > 0 THEN
            CONCAT(
                'BLOCKED: orphan process(es) detected. Example: ',
                (SELECT TOP 1 o.processName
                 FROM admin.v_runPreview_orphans o
                 WHERE o.model = r.model
                 ORDER BY o.processName)
            )
        ELSE
            'READY: no orphans detected.'
    END AS readiness_message
FROM admin.v_runPreview_readiness r;
GO


/* =====================================================================================
   STEP 6: OPERATIONAL SIMULATION (v1) - LOGS + STATUS VIEWS
   ===================================================================================== */

-- Seed 6 initial demo executions (mixed outcomes)
DECLARE @now DATETIME2(3) = SYSUTCDATETIME();

INSERT INTO log.copyDataLog
(model, processName, runId, status, startedOn, finishedOn, rowsRead, rowsWritten, message)
VALUES
-- DemoModel
('DemoModel','brz_sales','run_demo_001','SUCCEEDED', DATEADD(MINUTE,-60,@now), DATEADD(MINUTE,-55,@now), 10000,10000,'BRZ load OK'),
('DemoModel','slv_sales','run_demo_001','FAILED',    DATEADD(MINUTE,-55,@now), DATEADD(MINUTE,-53,@now), 10000,NULL,'Transformation error'),
('DemoModel','gld_sales','run_demo_001','SKIPPED',   DATEADD(MINUTE,-53,@now), DATEADD(MINUTE,-53,@now), NULL,NULL,'Skipped due to upstream failure'),
('DemoModel','brz_orphan','run_demo_001','SUCCEEDED',DATEADD(MINUTE,-50,@now), DATEADD(MINUTE,-48,@now), 5000,5000,'Orphan executed'),

-- framework
('framework','brz_Person','run_fw_010','SUCCEEDED',  DATEADD(HOUR,-5,@now),    DATEADD(MINUTE,-297,@now), 20000,20000,'Incremental OK'),
('framework','brz_SalesOrderDetail','run_fw_011','RUNNING', DATEADD(MINUTE,-10,@now), NULL, NULL,NULL,'In progress');
GO

-- Latest run per process (by startedOn)
CREATE OR ALTER VIEW admin.v_runPreview_lastRun
AS
WITH last_run AS (
    SELECT
        model,
        processName,
        runId,
        status,
        startedOn,
        finishedOn,
        ROW_NUMBER() OVER (
            PARTITION BY model, processName
            ORDER BY startedOn DESC
        ) AS rn
    FROM log.copyDataLog
)
SELECT
    model,
    processName,
    runId,
    status,
    startedOn,
    finishedOn
FROM last_run
WHERE rn = 1;
GO

-- Derived process status (OK/FAILED/RUNNING/SKIPPED)
CREATE OR ALTER VIEW admin.v_runPreview_processStatus
AS
SELECT
    model,
    processName,
    status AS last_status,
    startedOn,
    finishedOn,
    CASE
        WHEN status = 'RUNNING'   THEN 'RUNNING'
        WHEN status = 'FAILED'    THEN 'FAILED'
        WHEN status = 'SKIPPED'   THEN 'SKIPPED'
        WHEN status = 'SUCCEEDED' THEN 'OK'
        ELSE 'UNKNOWN'
    END AS derived_status
FROM admin.v_runPreview_lastRun;
GO

-- Enhanced readiness:
-- - BLOCKED if orphans exist
-- - DEGRADED if any FAILED (and no orphans)
-- - READY otherwise
CREATE OR ALTER VIEW admin.v_runPreview_readiness_v2
AS
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
    WHERE isActive = 1
)
SELECT
    m.model,
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
GO


/* =====================================================================================
   STEP 7: BULK SIMULATED EXECUTIONS
   ===================================================================================== */

-- Add 50 deterministic demo executions (pattern-based)
DECLARE @i INT = 1;
DECLARE @now2 DATETIME2(3) = SYSUTCDATETIME();

WHILE @i <= 50
BEGIN
    INSERT INTO log.copyDataLog
    (model, processName, runId, status, startedOn, finishedOn, rowsRead, rowsWritten, message)
    VALUES
    (
        CASE WHEN @i % 2 = 0 THEN 'DemoModel' ELSE 'framework' END,
        CASE
            WHEN @i % 4 = 0 THEN 'brz_sales'
            WHEN @i % 4 = 1 THEN 'slv_sales'
            WHEN @i % 4 = 2 THEN 'gld_sales'
            ELSE 'brz_Person'
        END,
        CONCAT('auto_run_', @i),
        CASE
            WHEN @i % 5 = 0 THEN 'FAILED'
            WHEN @i % 5 = 1 THEN 'SUCCEEDED'
            WHEN @i % 5 = 2 THEN 'RUNNING'
            WHEN @i % 5 = 3 THEN 'SKIPPED'
            ELSE 'SUCCEEDED'
        END,
        DATEADD(MINUTE, -@i * 5, @now2),
        CASE
            WHEN @i % 5 = 2 THEN NULL
            ELSE DATEADD(MINUTE, -@i * 5 + 2, @now2)
        END,
        1000 + @i * 10,
        CASE WHEN @i % 5 = 0 THEN NULL ELSE 1000 + @i * 8 END,
        'Simulated execution (pattern)'
    );

    SET @i = @i + 1;
END;
GO

-- Add 50 random demo executions (random status + random time within last 30 days)
DECLARE @j INT = 1;
DECLARE @now3 DATETIME2(3) = SYSUTCDATETIME();

WHILE @j <= 50
BEGIN
    DECLARE @model VARCHAR(100);
    DECLARE @process VARCHAR(200);
    DECLARE @status VARCHAR(30);
    DECLARE @minutesBack INT;

    SET @model =
        CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'DemoModel' ELSE 'framework' END;

    SELECT TOP 1 @process = targetObject
    FROM admin.copyDataConfig
    WHERE model = @model
    ORDER BY NEWID();

    SET @status =
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'SUCCEEDED'
            WHEN 1 THEN 'FAILED'
            WHEN 2 THEN 'RUNNING'
            ELSE 'SKIPPED'
        END;

    SET @minutesBack = ABS(CHECKSUM(NEWID())) % (30 * 24 * 60);

    INSERT INTO log.copyDataLog
    (model, processName, runId, status, startedOn, finishedOn, rowsRead, rowsWritten, message)
    VALUES
    (
        @model,
        @process,
        CONCAT('rnd_run_', @j, '_', FORMAT(@now3,'yyyyMMddHHmmss')),
        @status,
        DATEADD(MINUTE, -@minutesBack, @now3),
        CASE
            WHEN @status = 'RUNNING' THEN NULL
            ELSE DATEADD(MINUTE, -@minutesBack + (ABS(CHECKSUM(NEWID())) % 10), @now3)
        END,
        ABS(CHECKSUM(NEWID())) % 50000,
        CASE WHEN @status = 'FAILED' THEN NULL ELSE ABS(CHECKSUM(NEWID())) % 50000 END,
        'Simulated execution (random)'
    );

    SET @j = @j + 1;
END;
GO


/* =====================================================================================
   STEP 8: ADD MISSING OFFICIAL TABLES (v2)
   ===================================================================================== */

-- Inferred Members config (official-style)
CREATE TABLE admin.inferredMembersConfig (
    columnType  VARCHAR(13) NOT NULL,
    columnValue VARCHAR(10) NOT NULL,
    skValue     VARCHAR(2)  NOT NULL
);
GO

INSERT INTO admin.inferredMembersConfig (columnType, columnValue, skValue)
VALUES
('TimestampType','00:00','-1'),
('TimestampType','00:00','-2'),
('BooleanType','FALSE','-1'),
('BooleanType','FALSE','-2'),
('IntegerType','-1','-1'),
('IntegerType','-2','-2'),
('LongType','-1','-1'),
('LongType','-2','-2'),
('StringType','N/A','-2'),
('StringType','Unk','-1'),
('DateType','30/12/2999','-2'),
('DateType','31/12/2999','-1'),
('DoubleType','-1','-1'),
('DoubleType','-2','-2');
GO

-- Silver/Gold configuration (official-style)
-- Note: objectName is NOT NULL in this simplified table; Gold rows use '' to satisfy it.
CREATE TABLE admin.silverGoldConfig (
    model                    VARCHAR(200) NOT NULL,
    sourceSystemName         VARCHAR(200) NULL,
    sourceLocationName       VARCHAR(200) NULL,
    sourceDirectoryPattern   VARCHAR(1000) NULL,
    objectName               VARCHAR(200) NOT NULL,
    keyColumns               VARCHAR(200) NULL,
    partitionColumns         VARCHAR(500) NULL,
    extractType              VARCHAR(50)  NULL,
    loadType                 VARCHAR(50)  NULL,
    destinationObjectPattern VARCHAR(200) NULL,
    destinationDatabase      VARCHAR(200) NULL,
    notebookName             VARCHAR(200) NULL,
    layer                    VARCHAR(200) NULL,
    flagActive               BIT NOT NULL
);
GO

INSERT INTO admin.silverGoldConfig
(model, sourceSystemName, sourceLocationName, sourceDirectoryPattern,
 objectName, keyColumns, partitionColumns, extractType, loadType,
 destinationObjectPattern, destinationDatabase, notebookName, layer, flagActive)
VALUES
-- Gold layer
('framework', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL,
 'framework/fact_sales_full', 'lh_modernBI_fabricFramework_gold_01', 'NB_FACT_Sales_Full', 'Gold', 1),
('framework', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL,
 'framework/dim_store', 'lh_modernBI_fabricFramework_gold_01', 'NB_DIM_Store', 'Gold', 1),
('framework', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL,
 'framework/dim_person', 'lh_modernBI_fabricFramework_gold_01', 'NB_DIM_Person', 'Gold', 1),

-- Silver layer
('framework', 'lh_modernBI_fabricFramework_bronze_01', 'adventureworks2022',
 'adventureworks2022/Person/Person/',
 'Person.Person', 'BusinessEntityID', NULL, 'delta', 'merge',
 'Person/Person_Silver', 'lh_modernBI_fabricFramework_silver_01', 'NB_Load_Silver', 'Silver', 1),

('framework', 'lh_modernBI_fabricFramework_bronze_01', 'adventureworks2022',
 'adventureworks2022/Sales/SalesOrderDetail/',
 'Sales.SalesOrderDetail', NULL, NULL, 'full', 'overwrite',
 'Sales/SalesOrderDetail_Silver', 'lh_modernBI_fabricFramework_silver_01', 'NB_Load_Silver', 'Silver', 1),

('framework', 'lh_modernBI_fabricFramework_bronze_01', 'adventureworks2022',
 'adventureworks2022/Sales/Store/',
 'Sales.Store', NULL, NULL, 'full', 'overwrite',
 'Sales/Store_Silver', 'lh_modernBI_fabricFramework_silver_01', 'NB_Load_Silver', 'Silver', 1);
GO

-- Silver/Gold dependencies (official-style)
CREATE TABLE admin.silverGoldDependency (
    model               VARCHAR(200) NOT NULL,
    layer               VARCHAR(200) NOT NULL,
    objectName          VARCHAR(200) NOT NULL,
    dependencyObjectName VARCHAR(200) NOT NULL,
    SystemDateUpdate    DATETIME2(0) NOT NULL
);
GO

INSERT INTO admin.silverGoldDependency
(model, layer, objectName, dependencyObjectName, SystemDateUpdate)
VALUES
('framework', 'Gold', 'framework/fact_sales_full', 'framework/dim_person', SYSDATETIME()),
('framework', 'Gold', 'framework/fact_sales_full', 'framework/dim_store', SYSDATETIME());
GO


/* =====================================================================================
   STEP 9: QUICK VERIFICATION (optional)
   ===================================================================================== */

-- Confirm total executions (should be 106 with this script: 6 + 50 + 50)
SELECT COUNT(*) AS total_executions
FROM log.copyDataLog;

-- Confirm inferred members
SELECT COUNT(*) AS inferred_members_rows
FROM admin.inferredMembersConfig;

-- Confirm silver/gold config & deps
SELECT COUNT(*) AS silver_gold_rows
FROM admin.silverGoldConfig;

SELECT COUNT(*) AS silver_gold_dependency_rows
FROM admin.silverGoldDependency;

-- Confirm readiness overview
SELECT *
FROM admin.v_runPreview_readiness_v2
ORDER BY model;
GO