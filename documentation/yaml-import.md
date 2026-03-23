# YAML Import

## Purpose
The YAML import functionality allows users to create new ingestion configurations from a structured YAML definition.

This complements the YAML export feature, enabling a bidirectional workflow:
- Export configurations from governance into YAML
- Recreate configurations from YAML into governance

## Current Scope
The current implementation supports:
- parsing YAML input
- validating basic structure
- creating new ingestion configurations in governance tables

The import process is designed to:
- create new entries only
- avoid modifying existing configurations

## Integration
The YAML import feature is implemented through a Power Automate flow connected to the application.

The flow:
1. receives YAML input from the UI
2. parses key fields (pipeline, source, destination, extract, settings)
3. maps values to governance table fields
4. inserts a new configuration into the system

## Validation
Basic validation is applied during import, including:
- required fields presence
- structural consistency
- prevention of duplicate configuration creation (based on simplified rules)

## Role in Architecture
YAML import enables:
- portability of configurations
- easier sharing between environments
- alignment with version control practices (e.g. Git)

## Next Step
Future improvements may include:
- stronger validation rules
- schema enforcement
- integration with automated orchestration pipelines