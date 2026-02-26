/* =====================================================================================
   BI4ALL Governance Baseline — Fabric-safe (DDL only)
   Creates schemas + tables (idempotent). No views. No procs. No demo data.
   ===================================================================================== */

SET NOCOUNT ON;

-- Schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'admin') EXEC('CREATE SCHEMA admin');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'log')   EXEC('CREATE SCHEMA log');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'temp')  EXEC('CREATE SCHEMA temp');

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

-- temp.copyDataConfig (mirror)
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

-- admin.inferredMembersConfig
IF OBJECT_ID('admin.inferredMembersConfig','U') IS NULL
BEGIN
    CREATE TABLE admin.inferredMembersConfig(
        columnType  VARCHAR(13) NOT NULL,
        columnValue VARCHAR(10) NOT NULL,
        skValue     VARCHAR(2)  NOT NULL
    );
END;

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

-- temp.dispatchSelection (used to make Top-N deterministic in Fabric)
IF OBJECT_ID('temp.dispatchSelection','U') IS NULL
BEGIN
    CREATE TABLE temp.dispatchSelection
    (
        runId       VARCHAR(64)  NOT NULL,
        model       VARCHAR(256) NOT NULL,
        layer       VARCHAR(200) NOT NULL,
        processName VARCHAR(200) NOT NULL,
        createdOn   DATETIME2(3) NOT NULL
    );
END;