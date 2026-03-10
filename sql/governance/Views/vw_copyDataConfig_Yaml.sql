CREATE OR ALTER VIEW admin.vw_copyDataConfig_Yaml
AS
SELECT
    c.configId,
    c.configGuid,
    c.model,
    c.destinationObjectPattern,
    c.flagActive,
    c.flagBlock,
    CONCAT(
        'pipeline:', CHAR(10),
        '  configId: ', CAST(c.configId AS VARCHAR(20)), CHAR(10),
        '  configGuid: "', ISNULL(CAST(c.configGuid AS VARCHAR(100)), ''), '"', CHAR(10),
        '  model: "', ISNULL(c.model, ''), '"', CHAR(10),
        '  name: "', ISNULL(c.destinationObjectPattern, ''), '"', CHAR(10),

        'source:', CHAR(10),
        '  systemName: "', ISNULL(c.sourceSystemName, ''), '"', CHAR(10),
        '  systemType: "', ISNULL(c.sourceSystemType, ''), '"', CHAR(10),
        '  locationName: "', ISNULL(c.sourceLocationName, ''), '"', CHAR(10),
        '  objectName: "', ISNULL(c.sourceObjectName, ''), '"', CHAR(10),
        '  selectColumns: "', ISNULL(c.sourceSelectColumns, ''), '"', CHAR(10),
        '  keyColumns: "', ISNULL(c.sourceKeyColumns, ''), '"', CHAR(10),

        'destination:', CHAR(10),
        '  systemName: "', ISNULL(c.destinationSystemName, ''), '"', CHAR(10),
        '  systemType: "', ISNULL(c.destinationSystemType, ''), '"', CHAR(10),
        '  objectPattern: "', ISNULL(c.destinationObjectPattern, ''), '"', CHAR(10),
        '  directoryPattern: "', ISNULL(c.destinationDirectoryPattern, ''), '"', CHAR(10),
        '  objectType: "', ISNULL(c.destinationObjectType, ''), '"', CHAR(10),

        'extract:', CHAR(10),
        '  type: "', ISNULL(c.extractType, ''), '"', CHAR(10),
        '  deltaStartDate: "', ISNULL(CONVERT(VARCHAR(30), c.deltaStartDate, 126), ''), '"', CHAR(10),
        '  deltaEndDate: "', ISNULL(CONVERT(VARCHAR(30), c.deltaEndDate, 126), ''), '"', CHAR(10),
        '  deltaDateColumn: "', ISNULL(c.deltaDateColumn, ''), '"', CHAR(10),
        '  deltaFilterCondition: "', ISNULL(c.deltaFilterCondition, ''), '"', CHAR(10),

        'settings:', CHAR(10),
        '  blockFlag: ', CASE WHEN c.flagBlock = 1 THEN 'true' ELSE 'false' END, CHAR(10),
        '  blockSize: "', ISNULL(CAST(c.blockSize AS VARCHAR(30)), ''), '"', CHAR(10),
        '  blockColumn: "', ISNULL(c.blockColumn, ''), '"', CHAR(10),
        '  active: ', CASE WHEN c.flagActive = 1 THEN 'true' ELSE 'false' END, CHAR(10),

        'audit:', CHAR(10),
        '  createDate: "', ISNULL(CONVERT(VARCHAR(30), c.createDate, 126), ''), '"', CHAR(10),
        '  lastModifiedDate: "', ISNULL(CONVERT(VARCHAR(30), c.lastModifiedDate, 126), ''), '"'
    ) AS yaml_definition
FROM admin.copyDataConfig c;
GO

CREATE OR ALTER VIEW admin.vw_copyDataConfig_Yaml_Latest
AS
WITH ranked AS
(
    SELECT
        c.*,
        ROW_NUMBER() OVER (
            PARTITION BY c.destinationObjectPattern
            ORDER BY c.lastModifiedDate DESC, c.createDate DESC, c.configId DESC
        ) AS rn
    FROM admin.copyDataConfig c
)
SELECT
    r.configId,
    r.configGuid,
    r.model,
    r.destinationObjectPattern,
    r.flagActive,
    r.flagBlock,
    CONCAT(
        'pipeline:', CHAR(10),
        '  configId: ', CAST(r.configId AS VARCHAR(20)), CHAR(10),
        '  configGuid: "', ISNULL(CAST(r.configGuid AS VARCHAR(100)), ''), '"', CHAR(10),
        '  model: "', ISNULL(r.model, ''), '"', CHAR(10),
        '  name: "', ISNULL(r.destinationObjectPattern, ''), '"', CHAR(10),

        'source:', CHAR(10),
        '  systemName: "', ISNULL(r.sourceSystemName, ''), '"', CHAR(10),
        '  systemType: "', ISNULL(r.sourceSystemType, ''), '"', CHAR(10),
        '  locationName: "', ISNULL(r.sourceLocationName, ''), '"', CHAR(10),
        '  objectName: "', ISNULL(r.sourceObjectName, ''), '"', CHAR(10),
        '  selectColumns: "', ISNULL(r.sourceSelectColumns, ''), '"', CHAR(10),
        '  keyColumns: "', ISNULL(r.sourceKeyColumns, ''), '"', CHAR(10),

        'destination:', CHAR(10),
        '  systemName: "', ISNULL(r.destinationSystemName, ''), '"', CHAR(10),
        '  systemType: "', ISNULL(r.destinationSystemType, ''), '"', CHAR(10),
        '  objectPattern: "', ISNULL(r.destinationObjectPattern, ''), '"', CHAR(10),
        '  directoryPattern: "', ISNULL(r.destinationDirectoryPattern, ''), '"', CHAR(10),
        '  objectType: "', ISNULL(r.destinationObjectType, ''), '"', CHAR(10),

        'extract:', CHAR(10),
        '  type: "', ISNULL(r.extractType, ''), '"', CHAR(10),
        '  deltaStartDate: "', ISNULL(CONVERT(VARCHAR(30), r.deltaStartDate, 126), ''), '"', CHAR(10),
        '  deltaEndDate: "', ISNULL(CONVERT(VARCHAR(30), r.deltaEndDate, 126), ''), '"', CHAR(10),
        '  deltaDateColumn: "', ISNULL(r.deltaDateColumn, ''), '"', CHAR(10),
        '  deltaFilterCondition: "', ISNULL(r.deltaFilterCondition, ''), '"', CHAR(10),

        'settings:', CHAR(10),
        '  blockFlag: ', CASE WHEN r.flagBlock = 1 THEN 'true' ELSE 'false' END, CHAR(10),
        '  blockSize: "', ISNULL(CAST(r.blockSize AS VARCHAR(30)), ''), '"', CHAR(10),
        '  blockColumn: "', ISNULL(r.blockColumn, ''), '"', CHAR(10),
        '  active: ', CASE WHEN r.flagActive = 1 THEN 'true' ELSE 'false' END, CHAR(10),

        'audit:', CHAR(10),
        '  createDate: "', ISNULL(CONVERT(VARCHAR(30), r.createDate, 126), ''), '"', CHAR(10),
        '  lastModifiedDate: "', ISNULL(CONVERT(VARCHAR(30), r.lastModifiedDate, 126), ''), '"'
    ) AS yaml_definition
FROM ranked r
WHERE r.rn = 1;
GO