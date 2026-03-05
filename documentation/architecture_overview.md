# BI4All Project — Architecture Overview

## Purpose

This repository contains a governance-driven prototype that supports the creation and controlled management of ingestion configurations through a lightweight user interface (Power Apps) backed by SQL and Power Automate.

The objective is to enable operational autonomy for basic users (create + activate/deactivate + block/unblock) while keeping technical configuration changes restricted.

---

## High-level Architecture

**Power Apps (UI)** → **Power Automate (write actions)** → **SQL (governance tables + stored procedures)**

- **Power Apps** provides screens to view, create, and manage ingestion configurations.
- **Power Automate** executes controlled write operations to SQL (instead of direct write from the app).
- **SQL** stores governance configuration and enforces consistent structure via stored procedures.

---

## Core Components

### 1) Governance Table (SQL)

Primary table:

- `admin.copyDataConfig`

Purpose:

- Store the ingestion configuration metadata that drives the ingestion framework.

Examples of stored values:

- model and source definitions
- destination naming patterns
- extract type (Full vs Incremental)
- activation and blocking flags
- system-generated identifiers and timestamps

---

### 2) Stored Procedures (SQL)

The database logic is encapsulated in stored procedures so that write operations are consistent and auditable.

Implemented procedures include:

- **Toggle procedure**
  - Updates status fields such as `flagActive` and/or `flagBlocked` for an existing configuration.
- **Create procedure**
  - Creates a new configuration row with controlled defaults and system-generated values.

---

### 3) Power Automate Flows

Power Automate is used as the write layer between Power Apps and SQL.

Implemented flows include:

- **Toggle configuration flow**
  - Receives the config identifier and the target status values from the app.
  - Calls the toggle stored procedure in SQL.
- **Create configuration flow**
  - Receives validated user inputs from the create screen.
  - Calls the create stored procedure in SQL.

---

### 4) Power Apps Application

The Power Apps UI provides:

- a configuration list/consultation experience (with filtering)
- controlled editing of specific fields (status toggles)
- a create experience with validation
- a minimalistic KPI screen for governance visibility

The UI is designed to expose all relevant fields for viewing, while restricting edits to approved fields only.

---

## Governance Rules Implemented

### Create rules (basic users)

- Users can create new ingestion configurations **only under existing models** (model selected from a dropdown, not free text).
- `destinationObjectPattern` follows a controlled naming pattern:
  - `brz_<Model>_` + user-provided **alphanumeric suffix** (max ~15 chars).
- `configId` is system-generated.
- Advanced/technical settings remain restricted.

---

## Notes

This documentation reflects the current implemented prototype state and will evolve as new features are added (e.g., expiry logic for blocks).