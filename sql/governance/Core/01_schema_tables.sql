/* =============================================================================
   BI4All Governance — Core: Schemas + Tables
   - Matches current live shape of admin.copyDataConfig (incl. nullable configGuid)
   - No demo data
   ========================================================================== */

SET NOCOUNT ON;

-- Schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'admin') EXEC('CREATE SCHEMA admin');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'log')   EXEC('CREATE SCHEMA log');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'temp')  EXEC('CREATE SCHEMA temp');
GO

-- admin.copyDataConfig (CORE TABLE)
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
        lastModifiedDate             DATETIME2(2)   NULL,
        configGuid                   UNIQUEIDENTIFIER NULL
    );
END;
GO

-- Optional: conceptual constraints (Fabric-friendly style)
-- Keep as NOT ENFORCED if your environment supports it; otherwise comment out.
IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID('admin.copyDataConfig') AND type = 'PK'
)
BEGIN
    BEGIN TRY
        ALTER TABLE admin.copyDataConfig
        ADD CONSTRAINT PK_copyDataConfig
        PRIMARY KEY NONCLUSTERED (configId) NOT ENFORCED;
    END TRY
    BEGIN CATCH
        -- If NOT ENFORCED isn't supported in your endpoint, leave PK undocumented here.
    END CATCH
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID('admin.copyDataConfig') AND type = 'UQ'
)
BEGIN
    BEGIN TRY
        ALTER TABLE admin.copyDataConfig
        ADD CONSTRAINT UQ_copyDataConfig_BusinessKey
        UNIQUE NONCLUSTERED (model, sourceObjectName, destinationObjectPattern) NOT ENFORCED;
    END TRY
    BEGIN CATCH
        -- If NOT ENFORCED isn't supported, duplicate prevention remains enforced by stored procedures.
    END CATCH
END;
GO

-- Minimal log table used by monitoring (keep if already in your project)
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