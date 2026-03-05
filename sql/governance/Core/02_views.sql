/* =============================================================================
   BI4All Governance — Core: Views used by UI / validation
   ========================================================================== */

SET NOCOUNT ON;

-- UI contract view (Power Apps read)
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
    lastModifiedDate,
    configGuid
FROM admin.copyDataConfig;
GO

-- UI metadata: which fields are editable (kept simple)
CREATE OR ALTER VIEW admin.v_ui_copyDataConfig_fields AS
SELECT
    c.column_id   AS column_ordinal,
    c.name        AS column_name,
    t.name        AS data_type,
    c.max_length  AS max_length,
    c.is_nullable AS is_nullable,
    CASE
        WHEN c.name IN ('configId','model','createDate','lastModifiedDate') THEN 0
        ELSE 1
    END AS is_editable
FROM sys.columns c
JOIN sys.types t
  ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('admin.copyDataConfig');
GO

-- Optional diagnostics (useful for governance / thesis, not required by the UI)
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

-- Optional UI search helper
CREATE OR ALTER VIEW admin.v_ui_copyDataConfig_search_v2 AS
SELECT
    configId,
    model,
    destinationObjectPattern,
    sourceObjectName,
    flagActive,
    flagBlock,
    lastModifiedDate,
    LOWER(CONCAT(COALESCE(model,''),' ',COALESCE(destinationObjectPattern,''),' ',COALESCE(sourceObjectName,''))) AS search_text
FROM admin.copyDataConfig;
GO