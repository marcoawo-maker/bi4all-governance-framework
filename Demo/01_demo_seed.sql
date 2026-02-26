/* =====================================================================================
   BI4ALL Governance Demo Seed — Fabric-safe (FULL REPLACE)
   Resets tables + inserts demo configs, deps, dates, inferred members, and logs
   ===================================================================================== */

SET NOCOUNT ON;

-- Reset data (safe order)
DELETE FROM log.copyDataLog;
DELETE FROM admin.processDependencyConfig;
DELETE FROM admin.silverGoldDependency;
DELETE FROM admin.silverGoldConfig;
DELETE FROM admin.inferredMembersConfig;
DELETE FROM admin.processDatesConfig;
DELETE FROM temp.dispatchSelection;
DELETE FROM temp.copyDataConfig;
DELETE FROM admin.copyDataConfig;

-- Bronze configs
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

-- Mirror into temp.copyDataConfig
INSERT INTO temp.copyDataConfig
SELECT * FROM admin.copyDataConfig;

-- Silver config
INSERT INTO admin.silverGoldConfig
(
    model, sourceSystemName, sourceLocationName, sourceDirectoryPattern,
    objectName, keyColumns, partitionColumns,
    extractType, loadType,
    destinationObjectPattern, destinationDatabase,
    notebookName, layer, flagActive
)
SELECT
    CAST(c.model AS VARCHAR(200)),
    CAST('DataLake' AS VARCHAR(200)),
    CAST('/bronze' AS VARCHAR(200)),
    CAST('/bronze/' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(1000)),
    CAST('slv_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)),
    CAST('id' AS VARCHAR(200)),
    NULL,
    CAST('DELTA' AS VARCHAR(50)),
    CAST('INCREMENTAL' AS VARCHAR(50)),
    CAST('slv_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)),
    CAST('Warehouse' AS VARCHAR(200)),
    CAST('notebook_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)),
    CAST('Silver' AS VARCHAR(200)),
    CAST(1 AS BIT)
FROM admin.copyDataConfig c;

-- Gold config
INSERT INTO admin.silverGoldConfig
(
    model, sourceSystemName, sourceLocationName, sourceDirectoryPattern,
    objectName, keyColumns, partitionColumns,
    extractType, loadType,
    destinationObjectPattern, destinationDatabase,
    notebookName, layer, flagActive
)
SELECT
    CAST(c.model AS VARCHAR(200)),
    CAST('Warehouse' AS VARCHAR(200)),
    CAST('/silver' AS VARCHAR(200)),
    CAST('/silver/' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(1000)),
    CAST('gld_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)),
    CAST('id' AS VARCHAR(200)),
    NULL,
    CAST('DELTA' AS VARCHAR(50)),
    CAST('INCREMENTAL' AS VARCHAR(50)),
    CAST('gld_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)),
    CAST('Warehouse' AS VARCHAR(200)),
    CAST('notebook_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)),
    CAST('Gold' AS VARCHAR(200)),
    CAST(1 AS BIT)
FROM admin.copyDataConfig c;

-- Dependencies: Bronze -> Silver (all)
INSERT INTO admin.processDependencyConfig
(
    model, parentProcess, childProcess, isActive, createdOn, createdBy
)
SELECT
    CAST(c.model AS VARCHAR(100)),
    CAST('brz_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)),
    CAST('slv_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)),
    CAST(1 AS BIT),
    SYSDATETIME(),
    CAST('system' AS VARCHAR(100))
FROM admin.copyDataConfig c;

-- Dependencies: Silver -> Gold (exclude 2 to simulate incomplete chains)
INSERT INTO admin.processDependencyConfig
(
    model, parentProcess, childProcess, isActive, createdOn, createdBy
)
SELECT
    CAST(c.model AS VARCHAR(100)),
    CAST('slv_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)),
    CAST('gld_' + CAST(c.model AS VARCHAR(100)) AS VARCHAR(200)),
    CAST(1 AS BIT),
    SYSDATETIME(),
    CAST('system' AS VARCHAR(100))
FROM admin.copyDataConfig c
WHERE c.model NOT IN ('ForecastingLab','ExecutiveDashboard');

-- Process Dates (deterministic)
INSERT INTO admin.processDatesConfig
(
    model, tableName, scope, fullProcess, dateType,
    filterColumn, dateColumnFormat, dateUnit, date
)
SELECT
    CAST(c.model AS VARCHAR(200)),
    CAST('brz_' + CAST(c.model AS VARCHAR(200)) AS VARCHAR(200)),
    CAST('Daily' AS VARCHAR(200)),
    CAST(1 AS BIT),
    CAST('Rolling' AS VARCHAR(100)),
    CAST('load_date' AS VARCHAR(200)),
    CAST('yyyyMMdd' AS VARCHAR(200)),
    CAST(1 AS INT),
    CAST(DATEADD(DAY, -(ABS(CHECKSUM(c.model)) % 30), GETDATE()) AS DATETIME2(0))
FROM admin.copyDataConfig c;

-- Inferred Members
INSERT INTO admin.inferredMembersConfig VALUES
('String','Unknown','-1'),
('String','Not Avail','-2'),
('Numeric','0','-3');

-- Execution logs (deterministic mix)
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
    CAST('/path/' + p.processName AS VARCHAR(600)),
    CAST('Server01' AS VARCHAR(200)),
    CAST(p.processName AS VARCHAR(200)),
    CAST(CASE
        WHEN rnd < 700 THEN 'SUCCESS'
        WHEN rnd < 850 THEN 'SKIPPED'
        WHEN rnd < 950 THEN 'FAILED'
        ELSE 'RUNNING'
    END AS VARCHAR(200)),
    CAST(DATEADD(DAY, -(rnd % 30), GETDATE()) AS DATETIME2(3)),
    CAST((rnd * 7919) % 100000 AS INT),
    CAST('SELECT * FROM src' AS VARCHAR(4000)),
    CAST(
        DATEADD(MINUTE, (rnd % 60),
            DATEADD(DAY, -(rnd % 30), GETDATE())
        ) AS DATETIME2(3)
    ),
    CAST(rnd % 300 AS INT)
FROM processes p
CROSS JOIN numbers n
CROSS APPLY (
    SELECT ABS(CHECKSUM(CONCAT(p.model,'|',p.processName,'|',CAST(n.n AS VARCHAR(10))))) % 1000 AS rnd
) r;