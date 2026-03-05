<<<<<<< HEAD
/* =============================================================================
   BI4All Governance — Core: Procedures used by Power Automate
   - Create: admin.usp_CreateCopyDataConfig_Basic
   - Toggle: admin.usp_SetFlagActive / admin.usp_SetFlagBlock
   ========================================================================== */

SET NOCOUNT ON;
GO

-------------------------------------------------------------------------------
-- Create config (matches your flow choice)
-------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE admin.usp_CreateCopyDataConfig_Basic
(
    @model            VARCHAR(256),
    @destinationSuffix VARCHAR(15),
    @extractType       VARCHAR(64),     -- 'Full' or 'Incremental' (case-insensitive)
    @sourceObjectName  VARCHAR(256),
    @flagActive        BIT = 1          -- allow caller to create inactive
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Basic validations
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

    -- Alphanumeric only
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

    -- Build governed patterns
    DECLARE @destinationObjectPattern VARCHAR(64) =
        CONCAT('brz_', @model, '_', @destinationSuffix);

    IF (LEN(@destinationObjectPattern) > 64)
    BEGIN
        SELECT 'DESTPATTERN_TOO_LONG' AS result, NULL AS configId;
        RETURN;
    END;

    DECLARE @destinationDirectoryPattern VARCHAR(2048) =
        CONCAT('/brz/', @model, '/');

    -- Prevent duplicates on business key
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

    -- Generate configId safely enough for a prototype
    DECLARE @newConfigId INT;

    BEGIN TRY
        BEGIN TRAN;

        -- Optional: serialise ID generation (works in many SQL endpoints; harmless if unsupported)
        DECLARE @lockResult INT = 0;
        BEGIN TRY
            EXEC @lockResult = sp_getapplock
                @Resource = 'admin.copyDataConfig.configId',
                @LockMode = 'Exclusive',
                @LockTimeout = 10000,
                @DbPrincipal = 'public';
        END TRY
        BEGIN CATCH
            -- ignore lock errors; still proceed for demo usage
        END CATCH

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
            'ERP',
            'SQL',
            'SourceServer',
            @sourceObjectName,
            NULL,
            'id',
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
            NULL
        );

        COMMIT TRAN;

        SELECT
            'CREATED' AS result,
            @newConfigId AS configId,
            @destinationObjectPattern AS destinationObjectPattern,
            @destinationDirectoryPattern AS destinationDirectoryPattern;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT 'ERROR' AS result, NULL AS configId;
        THROW;
    END CATCH
END;
GO

-------------------------------------------------------------------------------
-- Toggle Active (matches your flow choice)
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Toggle Block (matches your flow choice)
-------------------------------------------------------------------------------
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
=======
/* =============================================================================
   BI4All Governance — Core: Procedures used by Power Automate
   - Create: admin.usp_CreateCopyDataConfig_Basic
   - Toggle: admin.usp_SetFlagActive / admin.usp_SetFlagBlock
   ========================================================================== */

SET NOCOUNT ON;
GO

-------------------------------------------------------------------------------
-- Create config (matches your flow choice)
-------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE admin.usp_CreateCopyDataConfig_Basic
(
    @model            VARCHAR(256),
    @destinationSuffix VARCHAR(15),
    @extractType       VARCHAR(64),     -- 'Full' or 'Incremental' (case-insensitive)
    @sourceObjectName  VARCHAR(256),
    @flagActive        BIT = 1          -- allow caller to create inactive
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Basic validations
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

    -- Alphanumeric only
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

    -- Build governed patterns
    DECLARE @destinationObjectPattern VARCHAR(64) =
        CONCAT('brz_', @model, '_', @destinationSuffix);

    IF (LEN(@destinationObjectPattern) > 64)
    BEGIN
        SELECT 'DESTPATTERN_TOO_LONG' AS result, NULL AS configId;
        RETURN;
    END;

    DECLARE @destinationDirectoryPattern VARCHAR(2048) =
        CONCAT('/brz/', @model, '/');

    -- Prevent duplicates on business key
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

    -- Generate configId safely enough for a prototype
    DECLARE @newConfigId INT;

    BEGIN TRY
        BEGIN TRAN;

        -- Optional: serialise ID generation (works in many SQL endpoints; harmless if unsupported)
        DECLARE @lockResult INT = 0;
        BEGIN TRY
            EXEC @lockResult = sp_getapplock
                @Resource = 'admin.copyDataConfig.configId',
                @LockMode = 'Exclusive',
                @LockTimeout = 10000,
                @DbPrincipal = 'public';
        END TRY
        BEGIN CATCH
            -- ignore lock errors; still proceed for demo usage
        END CATCH

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
            'ERP',
            'SQL',
            'SourceServer',
            @sourceObjectName,
            NULL,
            'id',
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
            NULL
        );

        COMMIT TRAN;

        SELECT
            'CREATED' AS result,
            @newConfigId AS configId,
            @destinationObjectPattern AS destinationObjectPattern,
            @destinationDirectoryPattern AS destinationDirectoryPattern;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SELECT 'ERROR' AS result, NULL AS configId;
        THROW;
    END CATCH
END;
GO

-------------------------------------------------------------------------------
-- Toggle Active (matches your flow choice)
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Toggle Block (matches your flow choice)
-------------------------------------------------------------------------------
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
>>>>>>> 88bbf1aad7e883f8c19e0d3796f34cc884d3698b
