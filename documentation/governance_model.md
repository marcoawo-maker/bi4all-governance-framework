# Governance Model

## Purpose

The governance model defines how ingestion configurations can be created and managed while maintaining system integrity and preventing uncontrolled changes to technical parameters.

The goal is to balance **user autonomy** with **technical control**.

---

## Governance Principles

The governance design follows three main principles:

1. **Controlled autonomy**
2. **Separation of technical and operational responsibilities**
3. **Traceable configuration management**

Users should be able to perform operational tasks without requiring database access, while deeper technical changes remain restricted.

---

## User Capabilities

Basic users are allowed to perform the following actions through the Power Apps interface:

- View ingestion configurations
- Create new ingestion configurations
- Activate or deactivate configurations
- Block or unblock configurations

These actions allow users to manage ingestion processes operationally without requiring technical intervention.

---

## Restricted Actions

Certain actions are intentionally restricted to technical staff.

These include:

- Modification of advanced configuration parameters
- Structural changes to ingestion models
- Changes to system-generated fields
- Direct database manipulation

These restrictions prevent accidental misconfiguration of ingestion pipelines.

---

## Configuration Creation Rules

When creating a new configuration, the following rules apply:

- The **model** must be selected from an existing list (no free-text creation).
- The **destinationObjectPattern** must follow the defined naming convention:

brz_<Model>_<Suffix>


- The suffix must be **alphanumeric** and limited to approximately **15 characters**.
- The **configId** is generated automatically by the system.
- System fields such as timestamps are automatically populated.

---

## Status Control

Two main governance flags are used to control ingestion behavior:

### flagActive

Determines whether the ingestion configuration is active.

Values:

- `1` = active
- `0` = inactive

---

### flagBlocked

Allows temporary blocking of configurations without deleting them.

This enables operational control when issues occur with a data source or ingestion process.

---

## Architecture Enforcement

All write operations follow this path:

Power Apps → Power Automate → SQL Stored Procedures


This architecture ensures that:

- users cannot directly manipulate SQL
- all changes follow controlled procedures
- governance rules are consistently applied