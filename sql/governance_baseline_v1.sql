/* ============================================================
   BI4ALL PROJECT
   GOVERNANCE BASELINE – VERSION 1
   ------------------------------------------------------------
   This script:
   1. Drops existing governance objects (clean reset)
   2. Creates required schemas
   3. Creates configuration and log tables
   4. Seeds minimal demo data
   5. Creates validation and readiness views
   ============================================================ */


/* ============================================================
   STEP 1 – CLEAN RESET (DROP VIEWS FIRST, THEN TABLES)
   ============================================================ */

-- Drop views (if they exist)
IF OBJECT_ID('admin.v_runPreview_readinessMessage','V') IS NOT NULL DROP VIEW admin.v_runPreview_readinessMessage;
IF OBJECT_ID('admin.v_runPreview_readiness','V')        IS NOT NULL DROP VIEW admin.v_runPreview_readiness;
IF OBJECT_ID('admin.v_runPreview_orphans','V')          IS NOT NULL DROP VIEW admin.v_runPreview_orphans;
GO

-- Drop tables
IF OBJECT_ID('log.copyDataLog','U')               IS NOT NULL DROP TABLE log.copyDataLog;
IF OBJECT_ID('admin.processDependencyConfig','U') IS NOT NULL DROP TABLE admin.processDependencyConfig;
IF OBJECT_ID('admin.processDatesConfig','U')      IS NOT NULL DROP TABLE admin.processDatesConfig;
IF OBJECT_ID('admin.copyDataConfig','U')          IS NOT NULL DROP TABLE admin.copyDataConfig;
GO


/* ============================================================
   STEP 2 – CREATE SCHEMAS
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'admin')
    EXEC('CREATE SCHEMA admin');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'log')
    EXEC('CREATE SCHEMA log');
GO


/* ============================================================
   STEP 3 – CREATE GOVERNANCE TABLES
   ============================================================ */

-- ------------------------------------------------------------
-- Table: admin.copyDataConfig
-- Purpose: Stores metadata-driven ingestion configuration
-- ------------------------------------------------------------
CREATE TABLE admin.copyDataConfig (
    copyDataConfigId BIGINT IDENTITY PRIMARY KEY,
    model            VARCHAR(100) NOT NULL,
    sourceSystem     VARCHAR(100) NOT NULL,
    sourceObject     VARCHAR(200) NOT NULL,
    targetLayer      VARCHAR(20)  NOT NULL,
    targetObject     VARCHAR(200) NOT NULL,
    loadType         VARCHAR(20)  NOT NULL,  -- FULL / INCR
    isActive         BIT          NOT NULL,
    createdOn        DATETIME2(3) NOT NULL,
    createdBy        VARCHAR(100) NULL,
    updatedOn        DATETIME2(3) NULL,
    updatedBy        VARCHAR(100) NULL
);
GO


-- ------------------------------------------------------------
-- Table: admin.processDependencyConfig
-- Purpose: Defines parent-child execution dependencies
-- ------------------------------------------------------------
CREATE TABLE admin.processDependencyConfig (
    processDependencyConfigId BIGINT IDENTITY PRIMARY KEY,
    model         VARCHAR(100) NOT NULL,
    parentProcess VARCHAR(200) NOT NULL,
    childProcess  VARCHAR(200) NOT NULL,
    isActive      BIT NOT NULL,
    createdOn     DATETIME2(3) NOT NULL,
    createdBy     VARCHAR(100) NULL
);
GO


-- ------------------------------------------------------------
-- Table: admin.processDatesConfig
-- Purpose: Stores incremental load date boundaries
-- ------------------------------------------------------------
CREATE TABLE admin.processDatesConfig (
    processDatesConfigId BIGINT IDENTITY PRIMARY KEY,
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


-- ------------------------------------------------------------
-- Table: log.copyDataLog
-- Purpose: Execution log for ingestion processes
-- ------------------------------------------------------------
CREATE TABLE log.copyDataLog (
    copyDataLogId BIGINT IDENTITY PRIMARY KEY,
    model         VARCHAR(100) NOT NULL,
    processName   VARCHAR(200) NOT NULL,
    runId         VARCHAR(100) NOT NULL,
    status        VARCHAR(30)  NOT NULL,  -- SUCCEEDED / FAILED / RUNNING / SKIPPED
    startedOn     DATETIME2(3) NOT NULL,
    finishedOn    DATETIME2(3) NULL,
    rowsRead      BIGINT NULL,
    rowsWritten   BIGINT NULL,
    message       VARCHAR(4000) NULL
);
GO


/* ============================================================
   STEP 4 – SEED DEMO DATA
   ============================================================ */

-- DemoModel (includes one orphan process)
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


-- Framework model (fully connected)
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

INSERT INTO admin.processDatesConfig
(model,processName,dateColumn,startDate,endDate,isActive,createdOn,createdBy)
VALUES
('DemoModel','slv_sales','SaleDate','2025-01-01',NULL,1,SYSUTCDATETIME(),'seed'),
('framework','brz_Person','ModifiedDate','2024-01-01',NULL,1,SYSUTCDATETIME(),'seed');
GO


/* ============================================================
   STEP 5 – VALIDATION VIEWS
   ============================================================ */

-- ------------------------------------------------------------
-- View: admin.v_runPreview_orphans
-- Purpose: Detect active processes without dependencies
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- View: admin.v_runPreview_readiness
-- Purpose: Determine model-level readiness (orphan check)
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- View: admin.v_runPreview_readinessMessage
-- Purpose: Human-readable readiness explanation
-- ------------------------------------------------------------
CREATE VIEW admin.v_runPreview_readinessMessage
AS
SELECT
    r.model,
    r.readiness_status,
    r.orphan_count,
    CASE
        WHEN r.orphan_count > 0 THEN
            CONCAT('BLOCKED: orphan process(es) detected. Example: ',
                   (SELECT TOP 1 o.processName
                    FROM admin.v_runPreview_orphans o
                    WHERE o.model = r.model
                    ORDER BY o.processName))
        ELSE
            'READY: no orphans detected.'
    END AS readiness_message
FROM admin.v_runPreview_readiness r;
GO
