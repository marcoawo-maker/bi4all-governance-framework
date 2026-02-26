/* =====================================================================================
   BI4ALL Governance — UI + Validation Objects (Stage 5)
   -------------------------------------------------------------------------------------
   Purpose:
   - Objects required by the Power Apps UI (list/search/fields + CRUD procs)
   - Validation helpers (duplicates + invalid rows)
   Notes:
   - Uses CREATE OR ALTER for repeatable deployments
   ===================================================================================== */

SET NOCOUNT ON;
GO

/* =========================
   VALIDATION VIEWS
   ========================= */

CREATE OR ALTER VIEW admin.v_copyDataConfig_duplicates AS
SELECT
    model,
    sourceObjectName,
    destinationObjectPattern,
    COUNT(*) AS cnt
FROM admin.copyDataConfig
GROUP BY model, sourceObjectName, destinationObjectPattern
HAVING COUNT(*) > 1;
GO

CREATE OR ALTER VIEW admin.v_copyDataConfig_invalid AS
SELECT
    configId,
    model,
    sourceObjectName,
    destinationObjectPattern,
    sourceSystemName,
    sourceSystemType,
    destinationSystemName,
    destinationSystemType,
    destinationDirectoryPattern,
    destinationObjectType,
    extractType,
    flagActive,
    createDate,
    CASE
        WHEN model IS NULL OR LTRIM(RTRIM(model)) = '' THEN 'model missing'
        WHEN sourceObjectName IS NULL OR LTRIM(RTRIM(sourceObjectName)) = '' THEN 'sourceObjectName missing'
        WHEN destinationObjectPattern IS NULL OR LTRIM(RTRIM(destinationObjectPattern)) = '' THEN 'destinationObjectPattern missing'
        WHEN sourceSystemName IS NULL OR LTRIM(RTRIM(sourceSystemName)) = '' THEN 'sourceSystemName missing'
        WHEN sourceSystemType IS NULL OR LTRIM(RTRIM(sourceSystemType)) = '' THEN 'sourceSystemType missing'
        WHEN destinationSystemName IS NULL OR LTRIM(RTRIM(destinationSystemName)) = '' THEN 'destinationSystemName missing'
        WHEN destinationSystemType IS NULL OR LTRIM(RTRIM(destinationSystemType)) = '' THEN 'destinationSystemType missing'
        WHEN destinationDirectoryPattern IS NULL OR LTRIM(RTRIM(destinationDirectoryPattern)) = '' THEN 'destinationDirectoryPattern missing'
        WHEN destinationObjectType IS NULL OR LTRIM(RTRIM(destinationObjectType)) = '' THEN 'destinationObjectType missing'
        WHEN extractType IS NULL OR LTRIM(RTRIM(extractType)) = '' THEN 'extractType missing'
        WHEN flagActive IS NULL THEN 'flagActive missing'
        WHEN createDate IS NULL THEN 'createDate missing'
        ELSE NULL
    END AS validation_error
FROM admin.copyDataConfig
WHERE
       model IS NULL OR LTRIM(RTRIM(model)) = ''
    OR sourceObjectName IS NULL OR LTRIM(RTRIM(sourceObjectName)) = ''
    OR destinationObjectPattern IS NULL OR LTRIM(RTRIM(destinationObjectPattern)) = ''
    OR sourceSystemName IS NULL OR LTRIM(RTRIM(sourceSystemName)) = ''
    OR sourceSystemType IS NULL OR LTRIM(RTRIM(sourceSystemType)) = ''
    OR destinationSystemName IS NULL OR LTRIM(RTRIM(destinationSystemName)) = ''
    OR destinationSystemType IS NULL OR LTRIM(RTRIM(destinationSystemType)) = ''
    OR destinationDirectoryPattern IS NULL OR LTRIM(RTRIM(destinationDirectoryPattern)) = ''
    OR destinationObjectType IS NULL OR LTRIM(RTRIM(destinationObjectType)) = ''
    OR extractType IS NULL OR LTRIM(RTRIM(extractType)) = ''
    OR flagActive IS NULL
    OR createDate IS NULL;
GO

/* =========================
   UI VIEWS
   ========================= */

CREATE OR ALTER VIEW admin.v_ui_copyDataConfig AS
SELECT
    configId,
    model,
    sourceSystemName,
    sourceSystemType,
    sourceLocationName,
    sourceObjectName,
    sourceSelectColumns,
    sourceKeyColumns,
    destinationSystemName,
    destinationSystemType,
    destinationObjectPattern,
    destinationDirectoryPattern,
    destinationObjectType,
    extractType,
    deltaStartDate,
    deltaEndDate,
    deltaDateColumn,
    deltaFilterCondition,
    flagBlock,
    blockSize,
    blockColumn,
    flagActive,
    createDate,
    lastModifiedDate
FROM admin.copyDataConfig;
GO

CREATE OR ALTER VIEW admin.v_ui_copyDataConfig_fields AS
SELECT
    c.column_id   AS column_ordinal,
    c.name        AS column_name,
    t.name        AS data_type,
    c.max_length  AS max_length,
    c.is_nullable AS is_nullable,
    CASE
        WHEN c.name IN ('configId','createDate','lastModifiedDate') THEN 0
        ELSE 1
    END AS is_editable
FROM sys.columns c
JOIN sys.types t
  ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('admin.copyDataConfig');
GO

CREATE OR ALTER VIEW admin.v_ui_copyDataConfig_search AS
SELECT
    configId,
    model,
    sourceSystemName,
    sourceSystemType,
    sourceLocationName,
    sourceObjectName,
    destinationSystemName,
    destinationSystemType,
    destinationObjectPattern,
    destinationDirectoryPattern,
    flagActive,
    lastModifiedDate
FROM admin.copyDataConfig;
GO

CREATE OR ALTER VIEW admin.v_ui_copyDataConfig_search_v2 AS
SELECT
    configId,
    model,
    destinationObjectPattern,
    sourceObjectName,
    flagActive,
    lastModifiedDate,
    LOWER(
        CONCAT(
            COALESCE(model,''),' ',
            COALESCE(destinationObjectPattern,''),' ',
            COALESCE(sourceObjectName,'')
        )
    ) AS search_text
FROM admin.copyDataConfig;
GO

/* =========================
   UI STORED PROCEDURES
   ========================= */

CREATE OR ALTER PROCEDURE admin.usp_CreateCopyDataConfig_UI
(
    @model varchar(256),
    @sourceObjectName varchar(256),
    @destinationObjectPattern varchar(64)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM admin.copyDataConfig
        WHERE model = @model
          AND sourceObjectName = @sourceObjectName
          AND destinationObjectPattern = @destinationObjectPattern
    )
    BEGIN
        SELECT 'DUPLICATE_NOT_CREATED' AS result, NULL AS configId;
        RETURN;
    END;

    DECLARE @newConfigId int;

    SELECT @newConfigId = ISNULL(MAX(configId), 0) + 1
    FROM admin.copyDataConfig;

    INSERT INTO admin.copyDataConfig (
        configId,
        model,
        sourceSystemName,
        sourceSystemType,
        sourceLocationName,
        sourceObjectName,
        sourceSelectColumns,
        sourceKeyColumns,
        destinationSystemName,
        destinationSystemType,
        destinationObjectPattern,
        destinationDirectoryPattern,
        destinationObjectType,
        extractType,
        deltaStartDate,
        deltaEndDate,
        deltaDateColumn,
        deltaFilterCondition,
        flagBlock,
        blockSize,
        blockColumn,
        flagActive,
        createDate,
        lastModifiedDate
    )
    VALUES (
        @newConfigId,
        @model,
        'ERP',
        'SQL',
        'SourceServer',
        @sourceObjectName,
        NULL,
        'id',
        'DataLake',
        'Delta',
        @destinationObjectPattern,
        CONCAT('/bronze/', @model),
        'Table',
        'FULL',
        NULL, NULL, NULL, NULL,
        0,
        NULL, NULL,
        1,
        SYSDATETIME(),
        SYSDATETIME()
    );

    SELECT 'CREATED' AS result, @newConfigId AS configId;
END;
GO

CREATE OR ALTER PROCEDURE admin.usp_UpdateCopyDataConfig_UI
(
    @configId                    INT,

    @model                       VARCHAR(256) = NULL,
    @sourceSystemName            VARCHAR(256) = NULL,
    @sourceSystemType            VARCHAR(256) = NULL,
    @sourceLocationName          VARCHAR(256) = NULL,
    @sourceObjectName            VARCHAR(256) = NULL,
    @sourceSelectColumns         VARCHAR(MAX) = NULL,
    @sourceKeyColumns            VARCHAR(256) = NULL,

    @destinationSystemName       VARCHAR(256) = NULL,
    @destinationSystemType       VARCHAR(256) = NULL,
    @destinationObjectPattern    VARCHAR(64)  = NULL,
    @destinationDirectoryPattern VARCHAR(2048)= NULL,
    @destinationObjectType       VARCHAR(256) = NULL,

    @extractType                 VARCHAR(64)  = NULL,
    @deltaStartDate              DATETIME2(2) = NULL,
    @deltaEndDate                DATETIME2(2) = NULL,
    @deltaDateColumn             VARCHAR(64)  = NULL,
    @deltaFilterCondition        VARCHAR(2048)= NULL,

    @flagBlock                   BIT          = NULL,
    @blockSize                   INT          = NULL,
    @blockColumn                 VARCHAR(64)  = NULL,

    @flagActive                  BIT          = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM admin.copyDataConfig WHERE configId = @configId)
    BEGIN
        SELECT 'NOT_FOUND' AS result;
        RETURN;
    END;

    IF @model IS NOT NULL AND EXISTS (
        SELECT 1
        FROM admin.copyDataConfig
        WHERE configId = @configId
          AND model <> @model
    )
    BEGIN
        SELECT 'MODEL_READ_ONLY' AS result;
        RETURN;
    END;

    DECLARE
        @storedModel VARCHAR(256),
        @newSourceObjectName VARCHAR(256),
        @newDestinationObjectPattern VARCHAR(64);

    SELECT
        @storedModel = model,
        @newSourceObjectName = COALESCE(@sourceObjectName, sourceObjectName),
        @newDestinationObjectPattern = COALESCE(@destinationObjectPattern, destinationObjectPattern)
    FROM admin.copyDataConfig
    WHERE configId = @configId;

    IF EXISTS (
        SELECT 1
        FROM admin.copyDataConfig
        WHERE configId <> @configId
          AND model = @storedModel
          AND sourceObjectName = @newSourceObjectName
          AND destinationObjectPattern = @newDestinationObjectPattern
    )
    BEGIN
        SELECT 'DUPLICATE_NOT_UPDATED' AS result;
        RETURN;
    END;

    UPDATE admin.copyDataConfig
    SET
        sourceSystemName            = COALESCE(@sourceSystemName, sourceSystemName),
        sourceSystemType            = COALESCE(@sourceSystemType, sourceSystemType),
        sourceLocationName          = COALESCE(@sourceLocationName, sourceLocationName),
        sourceObjectName            = COALESCE(@sourceObjectName, sourceObjectName),
        sourceSelectColumns         = COALESCE(@sourceSelectColumns, sourceSelectColumns),
        sourceKeyColumns            = COALESCE(@sourceKeyColumns, sourceKeyColumns),

        destinationSystemName       = COALESCE(@destinationSystemName, destinationSystemName),
        destinationSystemType       = COALESCE(@destinationSystemType, destinationSystemType),
        destinationObjectPattern    = COALESCE(@destinationObjectPattern, destinationObjectPattern),
        destinationDirectoryPattern = COALESCE(@destinationDirectoryPattern, destinationDirectoryPattern),
        destinationObjectType       = COALESCE(@destinationObjectType, destinationObjectType),

        extractType                 = COALESCE(@extractType, extractType),
        deltaStartDate              = COALESCE(@deltaStartDate, deltaStartDate),
        deltaEndDate                = COALESCE(@deltaEndDate, deltaEndDate),
        deltaDateColumn             = COALESCE(@deltaDateColumn, deltaDateColumn),
        deltaFilterCondition        = COALESCE(@deltaFilterCondition, deltaFilterCondition),

        flagBlock                   = COALESCE(@flagBlock, flagBlock),
        blockSize                   = COALESCE(@blockSize, blockSize),
        blockColumn                 = COALESCE(@blockColumn, blockColumn),

        flagActive                  = COALESCE(@flagActive, flagActive),

        lastModifiedDate            = SYSDATETIME()
    WHERE configId = @configId;

    SELECT 'UPDATED' AS result;
END;
GO

CREATE OR ALTER PROCEDURE admin.usp_SetCopyDataConfigActive_UI
(
    @configId   INT,
    @flagActive BIT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM admin.copyDataConfig WHERE configId = @configId)
    BEGIN
        SELECT 'NOT_FOUND' AS result;
        RETURN;
    END;

    UPDATE admin.copyDataConfig
    SET flagActive = @flagActive,
        lastModifiedDate = SYSDATETIME()
    WHERE configId = @configId;

    SELECT 'UPDATED' AS result;
END;
GO

/* =========================
   OPTIONAL: non-log dispatcher
   ========================= */

CREATE OR ALTER PROCEDURE admin.usp_DispatchCopyData_TopN
(
    @topN INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @runId VARCHAR(64) =
        CONCAT(
            'RUN_',
            REPLACE(CONVERT(VARCHAR(19), SYSDATETIME(), 120), ':', ''),
            '_',
            ABS(CHECKSUM(NEWID()))
        );

    SELECT TOP (@topN)
        @runId AS runId,
        c.configId,
        c.model,
        c.processName,
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
    FROM admin.v_dispatch_copyData_candidates c
    ORDER BY c.lastModifiedDate DESC;
END;
GO