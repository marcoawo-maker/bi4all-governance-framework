# Power Apps Interface

## Purpose

The Power Apps application provides a user interface that allows non-technical users to interact with ingestion governance configurations without requiring direct access to SQL databases.

The application focuses on simplicity, controlled edits, and operational autonomy.

---

## Application Structure

The application contains four main functional areas:

1. Configuration Viewer
2. Configuration Creation
3. KPI Dashboard
4. YAML Management

Each component serves a specific role within the governance and execution framework.

---

## Configuration Viewer

The main screen of the application allows users to browse and review existing ingestion configurations.

Features include:

* Model filtering
* Configuration list display
* Status visibility (Active / Blocked)
* Sorting by last modified date

### Search Functionality

The viewer includes dynamic search capabilities based on:

* model
* destination object pattern
* source object name

The search is currently case-sensitive, enabling controlled filtering across configurations.

---

## Status Controls

Users are allowed to modify operational status fields.

### flagActive

Controls whether a configuration is currently active.

* `1` → Active
* `0` → Inactive

Inactive configurations remain stored but are excluded from execution.

---

### flagBlock

Used to block a configuration when operational issues occur.

Blocking prevents execution without removing configuration metadata.

---

## Configuration Creation Screen

Users can create new ingestion configurations through a controlled form.

To maintain governance consistency, several rules are enforced:

* The **model** must be selected from an existing list
* The **destinationObjectPattern** must follow a predefined naming convention

Example:

brz_<Model>_<Suffix>

* The suffix must be alphanumeric and limited in length

### Real-Time Preview

The interface provides a preview of:

* ingestion name
* target table
* destination folder

System fields such as `configId` and timestamps are automatically generated.

---

## KPI Dashboard

The application includes a KPI screen combining governance and execution monitoring.

### Governance KPIs

* Total Configurations
* Active Configurations
* Inactive Configurations
* Blocked Configurations
* Extract Type Distribution (Full vs Incremental)
* Configurations Created in the Last 7 Days

---

### Execution KPIs

* Total Executions
* Successful Executions
* Failed Executions
* Success Rate
* Last Execution Time
* Average Duration
* Rows Ingested
* Skipped Executions

These KPIs are powered by ingestion execution logs stored in the Lakehouse.

---

## YAML Management

The application supports YAML-based configuration handling.

### Export

Users can select a configuration and generate its YAML representation.

This enables:

* portability
* version control integration
* reproducibility

---

### Import

Users can paste YAML definitions to create new configurations.

Validation ensures:

* no duplicate configurations
* compliance with governance rules

YAML import creates new configurations and does not modify existing ones.

---

## Design Principles

The Power Apps interface was designed following three key principles:

1. Simplicity
2. Controlled edits
3. Operational autonomy

Users can perform governance tasks while technical complexity remains restricted.

---

## Architectural Alignment

The application separates two core layers:

* Governance layer → configuration definition and control
* Execution layer → ingestion runs and operational monitoring

This separation ensures scalability, maintainability, and alignment with modern data platform design.
