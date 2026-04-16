# Ingestion Pipeline

## Purpose
This component represents the execution layer of the prototype.

## Current scope
The prototype has progressed beyond purely manual validation. The project includes real execution logging and supports manual and scheduled ingestion scenarios in Fabric.

## Current validation points
- File ingestion from Lakehouse folders
- Loading into Bronze tables
- Execution logging into `dbo.ingestion_execution_log`
- Operational KPI support from real logs

## Demo data domains
Examples include:
- sales
- customer360
- ecommercemart
- inventorycore
- logisticsnetwork
- marketinginsights

## Output examples
- `brz_sales_transactions`
- `brz_customer360`
- `brz_ecommercemart`
