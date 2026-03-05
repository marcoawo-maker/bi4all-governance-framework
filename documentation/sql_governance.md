# SQL Governance Layer

## Purpose

The SQL governance layer stores the ingestion configuration metadata that drives the ingestion framework.

Instead of hardcoding ingestion logic in pipelines, the framework uses configuration records stored in SQL tables. This allows ingestion behaviour to be managed dynamically through metadata.

---

## Main Governance Table

Primary table:

admin.copyDataConfig

This table stores the configuration parameters used to define ingestion behaviour.

Typical fields include:

- configId
- model
- sourceSystemName
- sourceObjectName
- destinationObjectPattern
- extractType
- flagActive
- flagBlocked
- createDate
- lastModifiedDate

These fields define how data is extracted and where it is written.

---

## Configuration Identification

Each configuration is uniquely identified using:

configId

This value is automatically generated when a new configuration is created.

The identifier is used by:

- Power Apps
- Power Automate
- SQL procedures

to reference specific ingestion configurations.

---

## Status Flags

Two governance flags control operational behaviour.

### flagActive

Determines whether the ingestion configuration is active.

Values:

- 1 → Active
- 0 → Inactive

Inactive configurations remain stored but are not executed.

---

### flagBlocked

Used to temporarily block ingestion execution.

This allows operational issues to be handled without deleting configuration metadata.

---

## Stored Procedures

Write operations are handled through SQL stored procedures.

These procedures ensure that configuration updates follow defined governance rules.

Typical procedures include:

Toggle procedure  
Updates configuration status fields.

Create procedure  
Creates new ingestion configurations with system-generated identifiers and timestamps.

---

## Governance Advantages

Using a SQL-based governance layer provides several benefits:

- centralized configuration management
- metadata-driven ingestion logic
- controlled modification through procedures
- easier auditing of configuration changes