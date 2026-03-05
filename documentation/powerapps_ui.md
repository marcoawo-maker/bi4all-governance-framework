# Power Apps Interface

## Purpose

The Power Apps application provides a user interface that allows non-technical users to interact with ingestion governance configurations without requiring direct access to SQL databases.

The application focuses on simplicity, controlled edits, and operational autonomy.

---

## Application Structure

The application contains three main functional areas:

1. Configuration Viewer
2. Configuration Creation
3. Governance KPI Dashboard

Each component serves a specific governance purpose.

---

## Configuration Viewer

The main screen of the application allows users to browse and review existing ingestion configurations.

Features include:

- Model filtering
- Configuration list display
- Status visibility (Active / Blocked)

Users can quickly inspect configuration properties without needing database access.

---

## Status Controls

Users are allowed to modify operational status fields.

Two primary controls are available:

### flagActive

Controls whether a configuration is currently active.

Values:

- `1` → Active
- `0` → Inactive

This allows users to temporarily disable ingestion processes.

---

### flagBlocked

Used to block a configuration when operational issues occur.

Blocking allows administrators to prevent ingestion execution without removing configuration metadata.

---

## Configuration Creation Screen

Users can create new ingestion configurations through a simplified form.

To maintain governance consistency, several rules are enforced:

- The **model** must be selected from an existing list.
- The **destinationObjectPattern** must follow a predefined naming convention.

Example:

brz_<Model>_<Suffix>


The suffix must be alphanumeric and limited in length.

System fields such as `configId` and timestamps are automatically generated.

---

## KPI Dashboard

The application includes a minimalistic KPI screen designed to provide governance visibility.

Displayed indicators include:

- Total Configurations
- Active Configurations
- Inactive Configurations
- Blocked Configurations
- Extract Type Distribution (Full vs Incremental)
- Configurations Created in the Last 7 Days

The goal is to provide a quick overview of ingestion governance health.

---

## Design Principles

The Power Apps interface was designed following three key principles:

1. Simplicity
2. Controlled edits
3. Operational autonomy

Users can perform common governance tasks while deeper technical modifications remain restricted to technical staff.