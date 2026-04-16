# BI4ALL Project — Architecture Overview

## Purpose
This repository documents and version-controls a governance-driven ingestion prototype built for the BI4ALL thesis project.

The objective is to let operational users create and manage ingestion configurations through a controlled interface, while preserving technical governance through SQL and Power Automate.

## High-level architecture
**Power Apps (UI)** → **Power Automate (write actions)** → **SQL governance layer** → **Fabric execution layer / Lakehouse monitoring**

## Core components
### Governance layer
Primary table: `admin.copyDataConfig`

This table stores the metadata that defines ingestion behaviour, including source, destination, extract logic, activation/blocking flags, and audit fields.

### SQL procedures
Stored procedures are used for controlled writes. The current core procedures include:
- `admin.usp_CreateCopyDataConfig_Basic`
- `admin.usp_SetFlagActive`
- `admin.usp_SetFlagBlock`

### Power Automate
Power Automate acts as the write layer between the app and SQL, and also supports YAML export/import.

### Power Apps
The app provides configuration viewing, controlled status changes, creation of new configurations, governance KPIs, and YAML-related actions.

### Execution and monitoring
Execution results are logged in the Lakehouse through `dbo.ingestion_execution_log`, which supports operational KPIs such as total executions, success/failure counts, duration, and last execution time.

## Notes

This documentation reflects the current implemented prototype state and will evolve as new features are added (e.g., expiry logic for blocks).
