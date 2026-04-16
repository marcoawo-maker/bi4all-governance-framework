# Ingestion Pipeline Layer

## Purpose

The ingestion pipeline represents the execution layer of the framework, responsible for processing source files and loading data into Bronze tables within the Lakehouse.

It bridges the gap between governance definitions and actual data ingestion.

---

## Pipeline Architecture

The pipeline follows a structured execution pattern composed of four main stages:

1. File discovery
2. File validation
3. Conditional execution
4. Execution logging

---

## File Discovery

The pipeline retrieves available files from ingestion folders stored in the Lakehouse:

/Files/ingestion/<model>/

A metadata activity is used to enumerate all files available for processing.

---

## File Validation

For each file, the pipeline checks whether it has already been processed.

This is done through a lookup against the ingestion execution log.

Only files that have not been processed proceed to ingestion.

---

## Conditional Execution

The pipeline uses branching logic to handle different scenarios.

### New Files

If the file is new:

* Data is copied into the Bronze layer
* Rows ingested and duration are captured
* A success log entry is created

If ingestion fails:

* A failure log entry is created

---

### Existing Files

If the file was already processed:

* The ingestion is skipped
* A skip log entry is created

---

## Execution Logging

All executions are recorded in:

dbo.ingestion_execution_log

Each record includes:

* configuration name
* file name
* execution status (Success / Failed / Skipped)
* start and end time
* duration
* rows ingested
* trigger type

This ensures full traceability of ingestion activity.

---

## Execution Characteristics

The pipeline guarantees:

* Idempotent processing (no duplicate ingestion)
* Controlled execution through conditional logic
* Operational visibility via logging
* Failure tracking without breaking the pipeline

---

## Current Limitations

At the current stage, the pipeline is file-driven and operates independently from governance tables.

Integration with admin.copyDataConfig is planned as a future enhancement.
