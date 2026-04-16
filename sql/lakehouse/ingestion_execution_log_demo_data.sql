/* =====================================================================================
   Sample rows captured from the current Lakehouse execution log
   ===================================================================================== */

INSERT INTO dbo.ingestion_execution_log
(run_id, config_name, file_name, start_time, end_time, duration_seconds, status, rows_ingested, trigger_type, file_name_new)
VALUES
(7124694610500124674, 'marketinginsights', 'MarketingInsights_2026_04_07_teste.csv', '2026-04-11T20:57:17.944392', '2026-04-11T20:57:17.944392', 32, 'Success', 5000, 'Scheduled', NULL),
(7665126565784584193, 'customer360', 'all_files', '2026-04-04T14:22:42.051512', '2026-04-04T14:22:42.051512', 0, 'Success', 0, 'Scheduled', NULL),
(3837066882519662593, 'logisticsnetwork', 'LogisticsNetwork_2026_04_07_01.csv', '2026-04-07T22:30:12.678083', '2026-04-07T22:30:12.678083', 24, 'Success', 5000, 'Scheduled', NULL),
(2053641430080946178, 'logisticsnetwork', 'LogisticsNetwork_2026_04_11_01.csv', '2026-04-12T18:25:42.869249', '2026-04-12T18:25:42.869249', 34, 'Success', 10000, 'Manual', NULL),
(3882102878793367553, 'customer360', 'Customer360_202_04_04_6.csv', '2026-04-04T17:41:06.073568', '2026-04-04T17:41:06.073568', 0, 'Success', 5000, 'Scheduled', NULL);
