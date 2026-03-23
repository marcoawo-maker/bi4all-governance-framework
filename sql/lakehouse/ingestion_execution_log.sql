CREATE TABLE dbo.ingestion_execution_log (
    run_id BIGINT,
    config_name STRING,
    file_name STRING,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_seconds INT,
    status STRING,
    rows_ingested INT,
    trigger_type STRING
);