# Ingestion Pipeline

## Purpose
This component represents the ingestion execution layer of the project.

Its role is to take source CSV files and load them into Bronze tables in the Lakehouse, validating that governed ingestion configurations can be executed in practice.

## Current Scope
At the current stage, the ingestion pipeline is executed manually.

This was sufficient to validate:
- file ingestion from demo source folders
- loading into Bronze tables
- successful creation of ingested output tables in the Lakehouse
- the basis for future operational monitoring

## Demo Data
The current prototype uses a set of demo CSV files stored in the Lakehouse under ingestion folders.

These files were created to simulate multiple ingestion scenarios across different business domains.

Examples include:
- sales
- customer360
- ecommercemart
- inventorycore
- logisticsnetwork
- marketinginsights

## Output
Successful runs load data into Bronze tables in the Lakehouse, including examples such as:
- `brz_sales_transactions`
- `brz_customer360`
- `brz_ecommercemart`

## Execution Mode
Execution is currently manual and intended for controlled validation.

This allows the project to demonstrate:
- ingestion feasibility
- table creation and loading
- the transition from governance definition to execution

## Next Step
The next implementation step is to automate the pipeline execution process and connect it to the broader orchestration layer, so ingestion runs can be triggered automatically from governed configurations and reflected in monitoring KPIs.