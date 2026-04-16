# Governance Model

## Purpose
The governance model defines how ingestion configurations can be created and managed while maintaining system integrity.

## Core principles
1. Controlled autonomy
2. Separation of operational and technical responsibilities
3. Traceable configuration management

## Allowed user actions
Through the app, basic users can:
- View ingestion configurations
- Create new ingestion configurations
- Activate or deactivate configurations
- Block or unblock configurations

## Restricted actions
Restricted to technical staff:
- Structural model changes
- Direct SQL manipulation
- Changes to system-generated fields
- Modifications to advanced technical parameters outside the approved flow

## Creation rules
- Model selected from an existing list
- Destination object naming follows the governance convention
- `configId` is system-generated
- Timestamps and related system fields are generated automatically

## Operational flags
### `flagActive`
- `1` = active
- `0` = inactive

### `flagBlock`
Used to temporarily block a configuration without deleting it.

## Enforcement path
**Power Apps → Power Automate → SQL stored procedures**
