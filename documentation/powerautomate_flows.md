# Power Automate Flows

## Purpose

Power Automate acts as the execution layer between the Power Apps interface and the SQL governance database.

Instead of allowing direct database writes from the application, Power Automate ensures that all modifications follow controlled procedures.

---

## Architectural Role

The system follows this interaction pattern:

Power Apps → Power Automate → SQL Stored Procedures

This architecture ensures:

- controlled write operations
- centralized execution logic
- reduced risk of accidental data manipulation
- consistent enforcement of governance rules

---

## Implemented Flows

### Toggle Configuration Flow

This flow is responsible for updating configuration status fields.

It is triggered when a user changes the state of a configuration from the Power Apps interface.

Inputs include:

- configId
- flagActive
- flagBlocked

The flow then calls the SQL stored procedure responsible for updating the configuration record.

---

### Create Configuration Flow

This flow is triggered when a user submits the **Create Configuration** form in the Power Apps interface.

The flow receives validated user input and calls the SQL stored procedure responsible for inserting a new configuration.

Inputs include:

- model
- source system information
- destination object pattern
- extract type
- activation status

System fields such as `configId` and timestamps are generated within SQL.

---

## Design Considerations

Using Power Automate as the write layer provides several benefits:

- avoids direct database manipulation from Power Apps
- allows validation before execution
- simplifies future integration with additional automation
- improves maintainability of the governance framework

## YAML Import Flow

A new Power Automate flow was implemented to support YAML import functionality.

### Purpose
This flow allows users to create new ingestion configurations directly from a YAML definition provided through the application UI.

### Process
The flow performs the following steps:

1. Receives YAML input from the Power Apps interface  
2. Parses key sections of the YAML structure, including:
   - pipeline
   - source
   - destination
   - extract
   - settings  
3. Maps extracted values to the corresponding governance table fields  
4. Executes an insert operation to create a new ingestion configuration  

### Behaviour
- The flow is designed to create new configurations only  
- Existing configurations are not modified  
- Basic validation is applied to ensure required fields are present  

### Role in the System
This flow extends the governance layer by enabling configuration portability and faster onboarding of new ingestion definitions, supporting a more scalable and flexible architecture.
