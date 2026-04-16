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
    ('SalesDW'),('FinanceMart'),('CRM_Analytics'),('SupplyChainHub'),
    ('MarketingInsights'),('HR_Workforce'),('InventoryCore'),
    ('RiskCompliance'),('FraudDetection'),('Customer360'),
    ('PricingEngine'),('DigitalEngagement'),('RetailOps'),
    ('EcommerceMart'),('PaymentsHub'),('LoansAnalytics'),
    ('ProcurementBI'),('LogisticsNetwork'),('VendorPerformance'),
    ('ProductLifecycle'),('ForecastingLab'),('ExecutiveDashboard')
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
    c.model,
    'DataLake',
    '/bronze',
    '/bronze/' + c.model,
    'slv_' + c.model,
    'id',
    NULL,
    'DELTA',
    'INCREMENTAL',
    'slv_' + c.model,
    'Warehouse',
    'notebook_' + c.model,
    'Silver',
    1
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
    c.model,
    'Warehouse',
    '/silver',
    '/silver/' + c.model,
    'gld_' + c.model,
    'id',
    NULL,
    'DELTA',
    'INCREMENTAL',
    'gld_' + c.model,
    'Warehouse',
    'notebook_' + c.model,
    'Gold',
    1
FROM admin.copyDataConfig c;

-- Dependencies: Bronze -> Silver
INSERT INTO admin.processDependencyConfig
(model, parentProcess, childProcess, isActive, createdOn, createdBy)
SELECT
    c.model,
    'brz_' + c.model,
    'slv_' + c.model,
    1,
    SYSDATETIME(),
    'system'
FROM admin.copyDataConfig c;

-- Dependencies: Silver -> Gold (exclude 2)
INSERT INTO admin.processDependencyConfig
(model, parentProcess, childProcess, isActive, createdOn, createdBy)
SELECT
    c.model,
    'slv_' + c.model,
    'gld_' + c.model,
    1,
    SYSDATETIME(),
    'system'
FROM admin.copyDataConfig c
WHERE c.model NOT IN ('ForecastingLab','ExecutiveDashboard');

-- Process Dates
INSERT INTO admin.processDatesConfig
(model, tableName, scope, fullProcess, dateType, filterColumn, dateColumnFormat, dateUnit, date)
SELECT
    c.model,
    'brz_' + c.model,
    'Daily',
    1,
    'Rolling',
    'load_date',
    'yyyyMMdd',
    1,
    DATEADD(DAY, -(ABS(CHECKSUM(c.model)) % 30), GETDATE())
FROM admin.copyDataConfig c;

-- Inferred Members
INSERT INTO admin.inferredMembersConfig VALUES
('String','Unknown','-1'),
('String','Not Avail','-2'),
('Numeric','0','-3');

-- Execution logs
;WITH processes AS (
    SELECT model, destinationObjectPattern AS processName FROM admin.copyDataConfig
    UNION ALL
    SELECT model, objectName FROM admin.silverGoldConfig
),
numbers AS (
    SELECT n FROM (VALUES
        (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
        (11),(12),(13),(14),(15),(16),(17),(18),(19),(20)
    ) v(n)
)
INSERT INTO log.copyDataLog
(model, destinationPath, sourceLocationName, objectName, status, startDate, row_count, sourceReadCommand, endDate, duration)
SELECT
    p.model,
    '/path/' + p.processName,
    'Server01',
    p.processName,
    CASE
        WHEN rnd < 700 THEN 'SUCCESS'
        WHEN rnd < 850 THEN 'SKIPPED'
        WHEN rnd < 950 THEN 'FAILED'
        ELSE 'RUNNING'
    END,
    DATEADD(DAY, -(rnd % 30), GETDATE()),
    (rnd * 7919) % 100000,
    'SELECT * FROM src',
    DATEADD(MINUTE, (rnd % 60), DATEADD(DAY, -(rnd % 30), GETDATE())),
    rnd % 300
FROM processes p
CROSS JOIN numbers n
CROSS APPLY (
    SELECT ABS(CHECKSUM(CONCAT(p.model,'|',p.processName,'|',CAST(n.n AS VARCHAR(10))))) % 1000 AS rnd
) r;
