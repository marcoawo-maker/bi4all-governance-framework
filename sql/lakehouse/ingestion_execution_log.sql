/* =====================================================================================
   Lakehouse execution log — current structure captured from Fabric
   ===================================================================================== */

CREATE TABLE dbo.ingestion_execution_log (
    run_id BIGINT,
    config_name VARCHAR(100),
    file_name VARCHAR(100),
    start_time DATETIME2,
    end_time DATETIME2,
    duration_seconds INT,
    status VARCHAR(20),
    rows_ingested INT,
    trigger_type VARCHAR(20),
    file_name_new VARCHAR(500)
);
