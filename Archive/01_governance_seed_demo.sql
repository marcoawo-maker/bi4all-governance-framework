/* =====================================================================================
   BI4ALL Governance Seed Demo — FABRIC SAFE — FULL REPLACE (Stage 2)
   -------------------------------------------------------------------------------------
   - DELETEs in safe order (replace mode)
   - Inserts demo config + dependencies + dates + inferred members + execution logs
   - Deterministic "random" (Fabric-safe) for repeatable demos
   ===================================================================================== */

SET NOCOUNT ON;

------------------------------------------------------------
-- 1) RESET DATA (SAFE REPLACE MODE)
------------------------------------------------------------
DELETE FROM log.copyDataLog;
DELETE FROM admin.processDependencyConfig;
DELETE FROM admin.silverGoldDependency;
DELETE FROM admin.silverGoldConfig;
DELETE FROM admin.inferredMembersConfig;
DELETE FROM admin.processDatesConfig;
DELETE FROM temp.copyDataConfig;
DELETE FROM admin.copyDataConfig;

------------------------------------------------------------
-- 2) INSERT Bronze (admin.copyDataConfig)
------------------------------------------------------------
INSERT INTO admin.copyDataConfig
(
    configId, model,
    sourceSystemName, sourceSystemType, sourceLocationName,
    sourceObjectName, sourceSelectColumns, sourceKeyColumns,
    destinationSystemName, destinationSystemType,
    destinationObjectPattern, destinationDirectoryPattern,
    destinationObjectType, extractType,
    deltaStartDate, deltaEndDate, deltaDateColumn, deltaFilterCondition,
    flagBlock, blockSize, blockColumn,
    flagActive, createDate, lastModifiedDate
)
SELECT
    ABS(CHECKSUM(NEWID()))                                   AS configId,
    CAST(v.model AS VARCHAR(256))                            AS model,
    CAST('ERP' AS VARCHAR(256))                              AS sourceSystemName,
    CAST('SQL' AS VARCHAR(256))                              AS sourceSystemType,
    CAST('SourceServer' AS VARCHAR(256))                     AS sourceLocationName,
    CAST('src_' + v.model AS VARCHAR(256))                   AS sourceObjectName,
    NULL                                                     AS sourceSelectColumns,
    CAST('id' AS VARCHAR(256))                               AS sourceKeyColumns,
    CAST('DataLake' AS VARCHAR(256))                         AS destinationSystemName,
    CAST('Delta' AS VARCHAR(256))                            AS destinationSystemType,
    CAST('brz_' + v.model AS VARCHAR(64))                    AS destinationObjectPattern,
    CAST('/bronze/' + v.model AS VARCHAR(2048))              AS destinationDirectoryPattern,
    CAST('Table' AS VARCHAR(256))                            AS destinationObjectType,
    CAST('FULL' AS VARCHAR(64))                              AS extractType,
    NULL, NULL, NULL, NULL,
    CAST(0 AS BIT), NULL, NULL,
    CAST(1 AS BIT),
    SYSDATETIME(),
    NULL
FROM (VALUES
    (CAST('SalesDW'            AS VARCHAR(256))),
    (CAST('FinanceMart'        AS VARCHAR(256))),
    (CAST('CRM_Analytics'      AS VARCHAR(256))),
    (CAST('SupplyChainHub'     AS VARCHAR(256))),
    (CAST('MarketingInsights'  AS VARCHAR(256))),
    (CAST('HR_Workforce'       AS VARCHAR(256))),
    (CAST('InventoryCore'      AS VARCHAR(256))),
    (CAST('RiskCompliance'     AS VARCHAR(256))),
    (CAST('FraudDetection'     AS VARCHAR(256))),
    (CAST('Customer360'        AS VARCHAR(256))),
    (CAST('PricingEngine'      AS VARCHAR(256))),
    (CAST('DigitalEngagement'  AS VARCHAR(256))),
    (CAST('RetailOps'          AS VARCHAR(256))),
    (CAST('EcommerceMart'      AS VARCHAR(256))),
    (CAST('PaymentsHub'        AS VARCHAR(256))),
    (CAST('LoansAnalytics'     AS VARCHAR(256))),
    (CAST('ProcurementBI'      AS VARCHAR(256))),
    (CAST('LogisticsNetwork'   AS VARCHAR(256))),
    (CAST('VendorPerformance'  AS VARCHAR(256))),
    (CAST('ProductLifecycle'   AS VARCHAR(256))),
    (CAST('ForecastingLab'     AS VARCHAR(256))),
    (CAST('ExecutiveDashboard' AS VARCHAR(256)))
) v(model);

------------------------------------------------------------
-- 3) Mirror into temp.copyDataConfig
------------------------------------------------------------
INSERT INTO temp.copyDataConfig
SELECT *
FROM admin.copyDataConfig;

------------------------------------------------------------
-- 4) INSERT Silver (admin.silverGoldConfig)  [model is VARCHAR(200)]
------------------------------------------------------------
INSERT INTO admin.silverGoldConfig
(
    model, sourceSystemName, sourceLocationName, sourceDirectoryPattern,
    objectName, keyColumns, partitionColumns,
    extractType, loadType,
    destinationObjectPattern, destinationDatabase,
    notebookName, layer, flagActive
)
SELECT
    CAST(c.model AS VARCHAR(200))                            AS model,
    CAST('DataLake' AS VARCHAR(200))                         AS sourceSystemName,
    CAST('/bronze' AS VARCHAR(200))                          AS sourceLocationName,
    CAST('/bronze/' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(1000)) AS sourceDirectoryPattern,
    CAST('slv_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200))      AS objectName,
    CAST('id' AS VARCHAR(200))                               AS keyColumns,
    NULL                                                     AS partitionColumns,
    CAST('DELTA' AS VARCHAR(50))                             AS extractType,
    CAST('INCREMENTAL' AS VARCHAR(50))                       AS loadType,
    CAST('slv_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200))      AS destinationObjectPattern,
    CAST('Warehouse' AS VARCHAR(200))                        AS destinationDatabase,
    CAST('notebook_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)) AS notebookName,
    CAST('Silver' AS VARCHAR(200))                           AS layer,
    CAST(1 AS BIT)                                           AS flagActive
FROM admin.copyDataConfig c;

------------------------------------------------------------
-- 5) INSERT Gold (admin.silverGoldConfig)
------------------------------------------------------------
INSERT INTO admin.silverGoldConfig
(
    model, sourceSystemName, sourceLocationName, sourceDirectoryPattern,
    objectName, keyColumns, partitionColumns,
    extractType, loadType,
    destinationObjectPattern, destinationDatabase,
    notebookName, layer, flagActive
)
SELECT
    CAST(c.model AS VARCHAR(200))                            AS model,
    CAST('Warehouse' AS VARCHAR(200))                        AS sourceSystemName,
    CAST('/silver' AS VARCHAR(200))                          AS sourceLocationName,
    CAST('/silver/' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(1000)) AS sourceDirectoryPattern,
    CAST('gld_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200))      AS objectName,
    CAST('id' AS VARCHAR(200))                               AS keyColumns,
    NULL                                                     AS partitionColumns,
    CAST('DELTA' AS VARCHAR(50))                             AS extractType,
    CAST('INCREMENTAL' AS VARCHAR(50))                       AS loadType,
    CAST('gld_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200))      AS destinationObjectPattern,
    CAST('Warehouse' AS VARCHAR(200))                        AS destinationDatabase,
    CAST('notebook_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)) AS notebookName,
    CAST('Gold' AS VARCHAR(200))                             AS layer,
    CAST(1 AS BIT)                                           AS flagActive
FROM admin.copyDataConfig c;

------------------------------------------------------------
-- 6) Dependencies (admin.processDependencyConfig) [model is VARCHAR(100)]
------------------------------------------------------------

-- Bronze -> Silver
INSERT INTO admin.processDependencyConfig
(
    model, parentProcess, childProcess, isActive, createdOn, createdBy
)
SELECT
    CAST(c.model AS VARCHAR(100))                               AS model,
    CAST('brz_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)) AS parentProcess,
    CAST('slv_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)) AS childProcess,
    CAST(1 AS BIT)                                              AS isActive,
    SYSDATETIME()                                               AS createdOn,
    CAST('system' AS VARCHAR(100))                              AS createdBy
FROM admin.copyDataConfig c;

-- Silver -> Gold (exclude 2 to simulate "incomplete" chains; may not count as orphans in current view)
INSERT INTO admin.processDependencyConfig
(
    model, parentProcess, childProcess, isActive, createdOn, createdBy
)
SELECT
    CAST(c.model AS VARCHAR(100))                               AS model,
    CAST('slv_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)) AS parentProcess,
    CAST('gld_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)) AS childProcess,
    CAST(1 AS BIT)                                              AS isActive,
    SYSDATETIME()                                               AS createdOn,
    CAST('system' AS VARCHAR(100))                              AS createdBy
FROM admin.copyDataConfig c
WHERE c.model NOT IN ('ForecastingLab','ExecutiveDashboard');

------------------------------------------------------------
-- 7) Process Dates (admin.processDatesConfig) — deterministic
------------------------------------------------------------
INSERT INTO admin.processDatesConfig
(
    model, tableName, scope, fullProcess, dateType,
    filterColumn, dateColumnFormat, dateUnit, date
)
SELECT
    CAST(c.model AS VARCHAR(200))                                   AS model,
    CAST('brz_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200))     AS tableName,
    CAST('Daily' AS VARCHAR(200))                                   AS scope,
    CAST(1 AS BIT)                                                  AS fullProcess,
    CAST('Rolling' AS VARCHAR(100))                                 AS dateType,
    CAST('load_date' AS VARCHAR(200))                               AS filterColumn,
    CAST('yyyyMMdd' AS VARCHAR(200))                                AS dateColumnFormat,
    CAST(1 AS INT)                                                  AS dateUnit,
    CAST(DATEADD(DAY, -(ABS(CHECKSUM(c.model)) % 30), GETDATE()) AS DATETIME2(0)) AS date
FROM admin.copyDataConfig c;

------------------------------------------------------------
-- 8) Inferred Members
------------------------------------------------------------
INSERT INTO admin.inferredMembersConfig
VALUES
('String','Unknown','-1'),
('String','Not Avail','-2'),
('Numeric','0','-3');

------------------------------------------------------------
-- 9) Execution Logs (Fabric-safe deterministic mix)
------------------------------------------------------------
;WITH processes AS (
    SELECT CAST(model AS VARCHAR(256)) AS model,
           CAST(destinationObjectPattern AS VARCHAR(200)) AS processName
    FROM admin.copyDataConfig
    UNION ALL
    SELECT CAST(model AS VARCHAR(256)) AS model,
           CAST(objectName AS VARCHAR(200)) AS processName
    FROM admin.silverGoldConfig
),
numbers AS (
    SELECT n FROM (VALUES
        (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
        (11),(12),(13),(14),(15),(16),(17),(18),(19),(20)
    ) v(n)
)
INSERT INTO log.copyDataLog
(
    model, destinationPath, sourceLocationName, objectName,
    status, startDate, row_count, sourceReadCommand, endDate, duration
)
SELECT
    p.model,
    CAST('/path/' + p.processName AS VARCHAR(600)) AS destinationPath,
    CAST('Server01' AS VARCHAR(200))               AS sourceLocationName,
    CAST(p.processName AS VARCHAR(200))            AS objectName,
    CAST(CASE
        WHEN rnd < 700 THEN 'SUCCESS'
        WHEN rnd < 850 THEN 'SKIPPED'
        WHEN rnd < 950 THEN 'FAILED'
        ELSE 'RUNNING'
    END AS VARCHAR(200)) AS status,
    CAST(DATEADD(DAY, -(rnd % 30), GETDATE()) AS DATETIME2(3)) AS startDate,
    CAST((rnd * 7919) % 100000 AS INT)         AS row_count,
    CAST('SELECT * FROM src' AS VARCHAR(4000))  AS sourceReadCommand,
    CAST(
        DATEADD(MINUTE, (rnd % 60),
            DATEADD(DAY, -(rnd % 30), GETDATE())
        ) AS DATETIME2(3)
    ) AS endDate,
    CAST(rnd % 300 AS INT) AS duration
FROM processes p
CROSS JOIN numbers n
CROSS APPLY (
    SELECT ABS(CHECKSUM(CONCAT(p.model,'|',p.processName,'|',CAST(n.n AS VARCHAR(10))))) % 1000 AS rnd
) r;