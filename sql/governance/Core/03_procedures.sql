/* =====================================================================================
   BI4ALL Governance Baseline — Fabric-safe (PROCS)
   Run after 01_schema_tables.sql and 02_views.sql
   Restored full version, including original governance procedures
   plus current Power Apps / Power Automate procedures.
   ===================================================================================== */

SET NOCOUNT ON;
GO

/* -----------------------------------------------------------------------------
   Create (demo)
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_CreateCopyDataConfig_Demo
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
        configId, model,
        sourceSystemName, sourceSystemType, sourceLocationName,
        sourceObjectName, sourceSelectColumns, sourceKeyColumns,
        destinationSystemName, destinationSystemType,
        destinationObjectPattern, destinationDirectoryPattern,
        destinationObjectType, extractType,
        deltaStartDate, deltaEndDate, deltaDateColumn, deltaFilterCondition,
        flagBlock, blockSize, blockColumn,
        flagActive, createDate, lastModifiedDate, configGuid
    )
    VALUES (
        @newConfigId,
        @model,
        'DemoSource',
        'SQL',
        NULL,
        @sourceObjectName,
        NULL,
        NULL,
        'Fabric',
        'Warehouse',
        @destinationObjectPattern,
        '/demo/{model}/{date}',
        'TABLE',
        'FULL',
        NULL, NULL, NULL, NULL,
        0, NULL, NULL,
        1,
        SYSDATETIME(),
        SYSDATETIME(),
        NULL
    );

    SELECT 'CREATED' AS result, @newConfigId AS configId;
END;
GO

/* -----------------------------------------------------------------------------
   Create (UI / Power Apps)
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_CreateCopyDataConfig_Basic
(
    @model             VARCHAR(256),
    @destinationSuffix VARCHAR(15),
    @extractType       VARCHAR(64),
    @sourceObjectName  VARCHAR(256),
    @configGuid        UNIQUEIDENTIFIER,
    @flagActive        BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@model IS NULL OR LTRIM(RTRIM(@model)) = '')
    BEGIN
        SELECT 'MODEL_REQUIRED' AS result, NULL AS configId;
        RETURN;
    END;

    IF (@sourceObjectName IS NULL OR LTRIM(RTRIM(@sourceObjectName)) = '')
    BEGIN
        SELECT 'SOURCEOBJECT_REQUIRED' AS result, NULL AS configId;
        RETURN;
    END;

    IF (@destinationSuffix IS NULL OR LEN(@destinationSuffix) < 1 OR LEN(@destinationSuffix) > 15)
    BEGIN
        SELECT 'SUFFIX_INVALID_LENGTH' AS result, NULL AS configId;
        RETURN;
    END;

    IF (@destinationSuffix LIKE '%[^A-Za-z0-9]%')
    BEGIN
        SELECT 'SUFFIX_NOT_ALPHANUMERIC' AS result, NULL AS configId;
        RETURN;
    END;

    DECLARE @extractNorm VARCHAR(64) = UPPER(LTRIM(RTRIM(@extractType)));
    IF (@extractNorm NOT IN ('FULL','INCREMENTAL'))
    BEGIN
        SELECT 'EXTRACTTYPE_INVALID' AS result, NULL AS configId;
        RETURN;
    END;

    DECLARE @destinationObjectPattern VARCHAR(64) =
        CONCAT('brz_', @model, '_', @destinationSuffix);

    IF (LEN(@destinationObjectPattern) > 64)
    BEGIN
        SELECT 'DESTPATTERN_TOO_LONG' AS result, NULL AS configId;
        RETURN;
    END;

    DECLARE @destinationDirectoryPattern VARCHAR(2048) =
        CONCAT('/brz/', @model, '/');

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

    DECLARE @newConfigId INT;

    BEGIN TRY
        BEGIN TRAN;

        BEGIN TRY
            DECLARE @lockResult INT = 0;
            EXEC @lockResult = sp_getapplock
                @Resource = 'admin.copyDataConfig.configId',
                @LockMode = 'Exclusive',
                @LockTimeout = 10000,
                @DbPrincipal = 'public';
        END TRY
        BEGIN CATCH
            -- Ignore lock errors in demo / Fabric contexts where unsupported
        END CATCH;

        SELECT @newConfigId = ISNULL(MAX(configId), 0) + 1
        FROM admin.copyDataConfig;

        INSERT INTO admin.copyDataConfig
        (
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
            lastModifiedDate,
            configGuid
        )
        VALUES
        (
            @newConfigId,
            @model,
            'Default',
            'SQL',
            NULL,
            @sourceObjectName,
            NULL,
            NULL,
            'Fabric',
            'Warehouse',
            @destinationObjectPattern,
            @destinationDirectoryPattern,
            'Table',
            @extractNorm,
            NULL, NULL, NULL, NULL,
            0,
            NULL, NULL,
            COALESCE(@flagActive, 1),
            SYSDATETIME(),
            NULL,
            @configGuid
        );

        COMMIT TRAN;

        SELECT
            'CREATED' AS result,
            @newConfigId AS configId,
            @configGuid AS configGuid,
            @destinationObjectPattern AS destinationObjectPattern,
            @destinationDirectoryPattern AS destinationDirectoryPattern;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

/* -----------------------------------------------------------------------------
   Toggle active flag (legacy generic toggle)
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_ToggleCopyDataConfig
(
    @model varchar(256),
    @destinationObjectPattern varchar(64)
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE admin.copyDataConfig
    SET flagActive = CASE WHEN flagActive = 1 THEN 0 ELSE 1 END,
        lastModifiedDate = SYSDATETIME()
    WHERE model = @model
      AND destinationObjectPattern = @destinationObjectPattern;

    IF @@ROWCOUNT = 0
        SELECT 'NOT_FOUND' AS result;
    ELSE
        SELECT 'UPDATED' AS result;
END;
GO

/* -----------------------------------------------------------------------------
   Set active flag (UI explicit setter)
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_SetFlagActive
(
    @model NVARCHAR(128),
    @destinationObjectPattern NVARCHAR(256),
    @newValue BIT
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE admin.copyDataConfig
    SET
        flagActive = @newValue,
        lastModifiedDate = SYSDATETIME()
    WHERE model = @model
      AND destinationObjectPattern = @destinationObjectPattern;

    DECLARE @rc INT = @@ROWCOUNT;

    SELECT
      CASE
        WHEN @rc = 0 THEN 'NOT_FOUND'
        WHEN @rc = 1 THEN 'UPDATED'
        ELSE 'WARNING_MULTIPLE_ROWS_UPDATED'
      END AS result,
      @rc AS rows_updated;
END;
GO

/* -----------------------------------------------------------------------------
   Set block flag (UI explicit setter)
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_SetFlagBlock
(
    @model NVARCHAR(128),
    @destinationObjectPattern NVARCHAR(256),
    @newValue BIT
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE admin.copyDataConfig
    SET
        flagBlock = @newValue,
        lastModifiedDate = SYSDATETIME()
    WHERE model = @model
      AND destinationObjectPattern = @destinationObjectPattern;

    DECLARE @rc INT = @@ROWCOUNT;

    SELECT
      CASE
        WHEN @rc = 0 THEN 'NOT_FOUND'
        WHEN @rc = 1 THEN 'UPDATED'
        ELSE 'WARNING_MULTIPLE_ROWS_UPDATED'
      END AS result,
      @rc AS rows_updated;
END;
GO

/* -----------------------------------------------------------------------------
   Bronze dispatcher (Top N) + log DISPATCHED
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_DispatchCopyData_TopN_Log
(
    @topN INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @runId VARCHAR(64) =
        CONCAT(
            'RUN_BRZ_',
            REPLACE(CONVERT(VARCHAR(19), SYSDATETIME(), 120), ':', ''),
            '_',
            ABS(CHECKSUM(NEWID()))
        );

    INSERT INTO temp.dispatchSelection (runId, model, layer, processName, createdOn)
    SELECT TOP (@topN)
        @runId,
        c.model,
        'Bronze',
        CAST(c.processName AS VARCHAR(200)),
        SYSDATETIME()
    FROM admin.v_dispatch_copyData_candidates c
    ORDER BY c.lastModifiedDate DESC, c.model, c.processName;

    INSERT INTO log.copyDataLog
    (
        model, destinationPath, sourceLocationName, objectName,
        status, startDate, row_count, sourceReadCommand, endDate, duration
    )
    SELECT
        s.model,
        NULL,
        NULL,
        s.processName,
        'DISPATCHED',
        SYSDATETIME(),
        NULL,
        CONCAT('dispatch_runId=', s.runId),
        NULL,
        NULL
    FROM temp.dispatchSelection s
    WHERE s.runId = @runId;

    SELECT
        runId,
        model,
        layer,
        processName
    FROM temp.dispatchSelection
    WHERE runId = @runId
    ORDER BY model, processName;
END;
GO

/* -----------------------------------------------------------------------------
   Silver/Gold dispatcher (Top N, Silver first) + log DISPATCHED
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_DispatchSilverGold_TopN_Log
(
    @topN INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @runId VARCHAR(64) =
        CONCAT(
            'RUN_SG_',
            REPLACE(CONVERT(VARCHAR(19), SYSDATETIME(), 120), ':', ''),
            '_',
            ABS(CHECKSUM(NEWID()))
        );

    INSERT INTO temp.dispatchSelection (runId, model, layer, processName, createdOn)
    SELECT TOP (@topN)
        @runId,
        c.model,
        c.layer,
        CAST(c.processName AS VARCHAR(200)),
        SYSDATETIME()
    FROM admin.v_dispatch_silvergold_candidates c
    ORDER BY
        CASE WHEN c.layer = 'Silver' THEN 1 ELSE 2 END,
        c.model,
        c.processName;

    INSERT INTO log.copyDataLog
    (
        model, destinationPath, sourceLocationName, objectName,
        status, startDate, row_count, sourceReadCommand, endDate, duration
    )
    SELECT
        s.model,
        CAST(CONCAT('/', LOWER(s.layer), '/', s.model) AS VARCHAR(600)),
        NULL,
        s.processName,
        'DISPATCHED',
        SYSDATETIME(),
        NULL,
        CONCAT('dispatch_runId=', s.runId),
        NULL,
        NULL
    FROM temp.dispatchSelection s
    WHERE s.runId = @runId;

    SELECT
        runId,
        model,
        layer,
        processName
    FROM temp.dispatchSelection
    WHERE runId = @runId
    ORDER BY
        CASE WHEN layer = 'Silver' THEN 1 ELSE 2 END,
        model,
        processName;
END;
GO

/* -----------------------------------------------------------------------------
   Mark a dispatch run complete
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_MarkDispatchRunComplete
(
    @runId  VARCHAR(64),
    @status VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @runId IS NULL OR LTRIM(RTRIM(@runId)) = ''
    BEGIN
        SELECT 'RUNID_REQUIRED' AS result;
        RETURN;
    END;

    IF UPPER(@status) NOT IN ('SUCCESS','FAILED')
    BEGIN
        SELECT 'INVALID_STATUS' AS result;
        RETURN;
    END;

    UPDATE log.copyDataLog
    SET
        status   = UPPER(@status),
        endDate  = SYSDATETIME(),
        duration = DATEDIFF(SECOND, startDate, SYSDATETIME())
    WHERE status = 'DISPATCHED'
      AND sourceReadCommand = CONCAT('dispatch_runId=', @runId);

    SELECT 'UPDATED' AS result, @@ROWCOUNT AS rows_updated;
END;
GO

/* -----------------------------------------------------------------------------
   Retry dispatcher (FAILED last 7 days)
----------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE admin.usp_DispatchRetries_Failed7d_TopN_Log
(
    @topN INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM admin.v_rerun_candidates_failed_7d)
    BEGIN
        SELECT 'EMPTY' AS result, NULL AS runId, 0 AS rows_dispatched;
        RETURN;
    END;

    DECLARE @runId VARCHAR(64) =
        CONCAT(
            'RUN_RETRY_',
            REPLACE(CONVERT(VARCHAR(19), SYSDATETIME(), 120), ':', ''),
            '_',
            ABS(CHECKSUM(NEWID()))
        );

    ;WITH sel AS
    (
        SELECT TOP (@topN)
            model,
            processName,
            finishedOn
        FROM admin.v_rerun_candidates_failed_7d
        ORDER BY finishedOn DESC
    )
    INSERT INTO log.copyDataLog
    (
        model, destinationPath, sourceLocationName, objectName,
        status, startDate, row_count, sourceReadCommand, endDate, duration
    )
    SELECT
        s.model,
        NULL,
        NULL,
        s.processName,
        'DISPATCHED',
        SYSDATETIME(),
        NULL,
        CONCAT('dispatch_runId=', @runId),
        NULL,
        NULL
    FROM sel s;

    SELECT 'DISPATCHED' AS result, @runId AS runId, @@ROWCOUNT AS rows_dispatched;
END;
GO
