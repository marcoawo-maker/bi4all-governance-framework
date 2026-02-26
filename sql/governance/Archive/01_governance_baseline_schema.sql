/* =====================================================================================
   BI4ALL Governance Baseline — FINAL CLEAN VERSION
   -------------------------------------------------------------------------------------
   Creates:
   - Schemas (if missing)
   - Governance tables (empty)
   - Monitoring / readiness views
   No demo data.
   No duplicates.
   ===================================================================================== */

SET NOCOUNT ON;

------------------------------------------------------------
-- 1) SCHEMAS
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'admin') EXEC('CREATE SCHEMA admin');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'log')   EXEC('CREATE SCHEMA log');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'temp')  EXEC('CREATE SCHEMA temp');
GO

------------------------------------------------------------
-- 2) TABLES
------------------------------------------------------------

-- admin.copyDataConfig
IF OBJECT_ID('admin.copyDataConfig','U') IS NULL
BEGIN
    CREATE TABLE admin.copyDataConfig(
        configId                     INT            NOT NULL,
        model                        VARCHAR(256)   NOT NULL,
        sourceSystemName             VARCHAR(256)   NOT NULL,
        sourceSystemType             VARCHAR(256)   NOT NULL,
        sourceLocationName           VARCHAR(256)   NULL,
        sourceObjectName             VARCHAR(256)   NOT NULL,
        sourceSelectColumns          VARCHAR(MAX)   NULL,
        sourceKeyColumns             VARCHAR(256)   NULL,
        destinationSystemName        VARCHAR(256)   NOT NULL,
        destinationSystemType        VARCHAR(256)   NOT NULL,
        destinationObjectPattern     VARCHAR(64)    NOT NULL,
        destinationDirectoryPattern  VARCHAR(2048)  NOT NULL,
        destinationObjectType        VARCHAR(256)   NOT NULL,
        extractType                  VARCHAR(64)    NOT NULL,
        deltaStartDate               DATETIME2(2)   NULL,
        deltaEndDate                 DATETIME2(2)   NULL,
        deltaDateColumn              VARCHAR(64)    NULL,
        deltaFilterCondition         VARCHAR(2048)  NULL,
        flagBlock                    BIT            NOT NULL,
        blockSize                    INT            NULL,
        blockColumn                  VARCHAR(64)    NULL,
        flagActive                   BIT            NOT NULL,
        createDate                   DATETIME2(2)   NOT NULL,
        lastModifiedDate             DATETIME2(2)   NULL
    );
END;
GO

-- temp.copyDataConfig
IF OBJECT_ID('temp.copyDataConfig','U') IS NULL
BEGIN
    CREATE TABLE temp.copyDataConfig(
        configId                     INT            NOT NULL,
        model                        VARCHAR(256)   NOT NULL,
        sourceSystemName             VARCHAR(256)   NOT NULL,
        sourceSystemType             VARCHAR(256)   NOT NULL,
        sourceLocationName           VARCHAR(256)   NULL,
        sourceObjectName             VARCHAR(256)   NOT NULL,
        sourceSelectColumns          VARCHAR(MAX)   NULL,
        sourceKeyColumns             VARCHAR(256)   NULL,
        destinationSystemName        VARCHAR(256)   NOT NULL,
        destinationSystemType        VARCHAR(256)   NOT NULL,
        destinationObjectPattern     VARCHAR(64)    NOT NULL,
        destinationDirectoryPattern  VARCHAR(2048)  NOT NULL,
        destinationObjectType        VARCHAR(256)   NOT NULL,
        extractType                  VARCHAR(64)    NOT NULL,
        deltaStartDate               DATETIME2(2)   NULL,
        deltaEndDate                 DATETIME2(2)   NULL,
        deltaDateColumn              VARCHAR(64)    NULL,
        deltaFilterCondition         VARCHAR(2048)  NULL,
        flagBlock                    BIT            NOT NULL,
        blockSize                    INT            NULL,
        blockColumn                  VARCHAR(64)    NULL,
        flagActive                   BIT            NOT NULL,
        createDate                   DATETIME2(2)   NOT NULL,
        lastModifiedDate             DATETIME2(2)   NULL
    );
END;
GO

-- admin.processDatesConfig
IF OBJECT_ID('admin.processDatesConfig','U') IS NULL
BEGIN
    CREATE TABLE admin.processDatesConfig(
        model            VARCHAR(200)  NULL,
        tableName        VARCHAR(200)  NULL,
        scope            VARCHAR(200)  NULL,
        fullProcess      BIT           NULL,
        dateType         VARCHAR(100)  NULL,
        filterColumn     VARCHAR(200)  NULL,
        dateColumnFormat VARCHAR(200)  NULL,
        dateUnit         INT           NULL,
        date             DATETIME2(0)  NULL
    );
END;
GO

-- admin.inferredMembersConfig
IF OBJECT_ID('admin.inferredMembersConfig','U') IS NULL
BEGIN
    CREATE TABLE admin.inferredMembersConfig(
        columnType  VARCHAR(13) NOT NULL,
        columnValue VARCHAR(10) NOT NULL,
        skValue     VARCHAR(2)  NOT NULL
    );
END;
GO

-- admin.silverGoldConfig
IF OBJECT_ID('admin.silverGoldConfig','U') IS NULL
BEGIN
    CREATE TABLE admin.silverGoldConfig(
        model                    VARCHAR(200)  NOT NULL,
        sourceSystemName         VARCHAR(200)  NULL,
        sourceLocationName       VARCHAR(200)  NULL,
        sourceDirectoryPattern   VARCHAR(1000) NULL,
        objectName               VARCHAR(200)  NOT NULL,
        keyColumns               VARCHAR(200)  NULL,
        partitionColumns         VARCHAR(500)  NULL,
        extractType              VARCHAR(50)   NULL,
        loadType                 VARCHAR(50)   NULL,
        destinationObjectPattern VARCHAR(200)  NULL,
        destinationDatabase      VARCHAR(200)  NULL,
        notebookName             VARCHAR(200)  NULL,
        layer                    VARCHAR(200)  NULL,
        flagActive               BIT           NOT NULL
    );
END;
GO

-- admin.silverGoldDependency
IF OBJECT_ID('admin.silverGoldDependency','U') IS NULL
BEGIN
    CREATE TABLE admin.silverGoldDependency(
        model                VARCHAR(200) NOT NULL,
        layer                VARCHAR(200) NOT NULL,
        objectName           VARCHAR(200) NOT NULL,
        dependencyObjectName VARCHAR(200) NOT NULL,
        SystemDateUpdate     DATETIME2(0) NOT NULL
    );
END;
GO

-- log.copyDataLog
IF OBJECT_ID('log.copyDataLog','U') IS NULL
BEGIN
    CREATE TABLE log.copyDataLog(
        model              VARCHAR(256)  NOT NULL,
        destinationPath    VARCHAR(600)  NULL,
        sourceLocationName VARCHAR(200)  NULL,
        objectName         VARCHAR(200)  NULL,
        status             VARCHAR(200)  NULL,
        startDate          DATETIME2(3)  NULL,
        row_count          INT           NULL,
        sourceReadCommand  VARCHAR(4000) NULL,
        endDate            DATETIME2(3)  NULL,
        duration           INT           NULL
    );
END;
GO

-- admin.processDependencyConfig
IF OBJECT_ID('admin.processDependencyConfig','U') IS NULL
BEGIN
    CREATE TABLE admin.processDependencyConfig(
        processDependencyConfigId BIGINT IDENTITY NOT NULL,
        model         VARCHAR(100) NOT NULL,
        parentProcess VARCHAR(200) NOT NULL,
        childProcess  VARCHAR(200) NOT NULL,
        isActive      BIT          NOT NULL,
        createdOn     DATETIME2(3) NOT NULL,
        createdBy     VARCHAR(100) NULL
    );
END;
GO

------------------------------------------------------------
-- 3) VIEWS
------------------------------------------------------------

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
  ON d.model = a.model
 AND d.processName = a.processName
WHERE d.processName IS NULL;
GO

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
       CASE WHEN COALESCE(o.orphan_count, 0) > 0
            THEN 'BLOCKED'
            ELSE 'READY'
       END AS readiness_status
FROM models m
LEFT JOIN orph o ON o.model = m.model;
GO

CREATE OR ALTER VIEW admin.v_runPreview_readinessMessage AS
SELECT r.model,
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
           ELSE 'READY: no orphans detected.'
       END AS readiness_message
FROM admin.v_runPreview_readiness r;
GO

CREATE OR ALTER VIEW admin.v_runPreview_lastRun AS
WITH last_run AS (
    SELECT model,
           objectName AS processName,
           status,
           startDate,
           endDate,
           ROW_NUMBER() OVER (
               PARTITION BY model, objectName
               ORDER BY startDate DESC
           ) AS rn
    FROM log.copyDataLog
    WHERE objectName IS NOT NULL
)
SELECT model,
       processName,
       status,
       startDate AS startedOn,
       endDate   AS finishedOn
FROM last_run
WHERE rn = 1;
GO

CREATE OR ALTER VIEW admin.v_runPreview_processStatus AS
SELECT model,
       processName,
       status AS last_status,
       startedOn,
       finishedOn,
       CASE
           WHEN status IS NULL THEN 'UNKNOWN'
           WHEN UPPER(status) LIKE '%RUN%'  THEN 'RUNNING'
           WHEN UPPER(status) LIKE '%FAIL%' THEN 'FAILED'
           WHEN UPPER(status) LIKE '%SKIP%' THEN 'SKIPPED'
           WHEN UPPER(status) LIKE '%SUCC%' THEN 'OK'
           ELSE 'UNKNOWN'
       END AS derived_status
FROM admin.v_runPreview_lastRun;
GO

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
GO
