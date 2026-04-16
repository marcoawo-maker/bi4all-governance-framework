# Ingestion Monitoring

## Purpose
This component represents the monitoring layer for ingestion executions and complements the governance layer.

## Current scope
The project now stores real execution records in the Lakehouse execution log and uses them to support operational KPIs.

## Storage location
Execution logs are stored in the Lakehouse, separately from the governance tables.

## Table
`dbo.ingestion_execution_log`

## Current fields
- `run_id`
- `config_name`
- `file_name`
- `start_time`
- `end_time`
- `duration_seconds`
- `status`
- `rows_ingested`
- `trigger_type`
- `file_name_new`

## KPI usage
The KPI layer can use this table to show:
- Total executions
- Successful executions
- Failed executions
- Success rate
- Last execution time
- Average duration
