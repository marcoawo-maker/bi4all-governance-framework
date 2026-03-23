# Ingestion Monitoring

## Purpose
This component represents the monitoring layer for ingestion executions.  
Its role is to provide operational visibility over ingestion activity, complementing the governance layer that defines configurations and rules.

## Current Scope
At the current stage of the project, ingestion execution is still triggered manually for validation purposes.  
To support KPI development and demonstration, a dedicated execution log table was created in the Lakehouse.

This allows the application to display execution-oriented KPIs such as:
- Total Executions
- Successful Executions
- Failed Executions
- Success Rate
- Last Execution Time
- Average Duration

## Storage Location
Execution logs are stored in the Lakehouse, separate from governance tables.

This separation reflects the distinction between:
- **Governance / configuration metadata** → SQL governance layer
- **Operational execution records** → Lakehouse

## Table
The monitoring layer currently uses the following table:

`dbo.ingestion_execution_log`

### Fields
- `run_id`
- `config_name`
- `file_name`
- `start_time`
- `end_time`
- `duration_seconds`
- `status`
- `rows_ingested`
- `trigger_type`

## Demo / Validation Approach
For the current prototype, execution records were inserted in a controlled way to validate the KPI logic and to simulate how the monitoring layer will behave once the ingestion process is fully automated.

This means the KPI panel is already functionally connected to execution records, even though real-time automatic updates are not yet implemented.

## Next Step
The next implementation phase is to automate ingestion execution and automatically write run results into the execution log table, allowing the KPI screen to update dynamically after each run.