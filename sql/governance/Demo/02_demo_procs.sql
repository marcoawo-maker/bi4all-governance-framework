/*
================================================================================
Procedure: admin.usp_CreateCopyDataConfig_Demo
Purpose  : Demo procedure to create ingestion metadata in admin.copyDataConfig
Notes    : 
  - Prevents duplicate definitions
  - Generates configId manually (demo-safe approach)
  - Inserts default demo values for required columns
================================================================================
*/

CREATE OR ALTER PROCEDURE admin.usp_CreateCopyDataConfig_Demo
(
    @model varchar(256),
    @sourceObjectName varchar(256),
    @destinationObjectPattern varchar(64)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Prevent duplicate ingestion definitions
    IF EXISTS (
        SELECT 1
        FROM admin.copyDataConfig
        WHERE model = @model
          AND sourceObjectName = @sourceObjectName
          AND destinationObjectPattern = @destinationObjectPattern
    )
    BEGIN
        SELECT 
            'DUPLICATE_NOT_CREATED' AS result,
            NULL AS configId;
        RETURN;
    END

    DECLARE @newConfigId int;

    -- Generate next configId (demo-safe approach)
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
        0,
        NULL, NULL,
        1,
        SYSDATETIME(),
        SYSDATETIME()
    );

    SELECT 
        'CREATED' AS result,
        @newConfigId AS configId;
END;

/*
================================================================================
Procedure: admin.usp_ToggleCopyDataConfig_Demo
Purpose  : Toggle flagActive for a given ingestion configuration
================================================================================
*/

CREATE OR ALTER PROCEDURE admin.usp_ToggleCopyDataConfig_Demo
(
    @model varchar(256),
    @destinationObjectPattern varchar(64)
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE admin.copyDataConfig
    SET 
        flagActive = CASE 
                        WHEN flagActive = 1 THEN 0
                        ELSE 1
                     END,
        lastModifiedDate = SYSDATETIME()
    WHERE model = @model
      AND destinationObjectPattern = @destinationObjectPattern;

    SELECT 
        'TOGGLED' AS result;
END;