# BI4All Ingestion Governance Prototype

## Overview

This repository contains a prototype governance framework designed to manage ingestion configurations through a metadata-driven approach.

The project was developed as part of a Master's thesis in **Business Intelligence and Analytics**, in collaboration with **BI4All**.

The objective is to allow operational users to create and manage ingestion configurations while maintaining technical governance and system integrity.

---

## Architecture

The system follows a layered architecture:

Power Apps → Power Automate → SQL Governance Tables

- **Power Apps** provides the user interface for configuration management.
- **Power Automate** executes controlled write operations.
- **SQL** stores ingestion configuration metadata and enforces governance rules.

---

## Repository Structure

documentation/
Project documentation and architecture descriptions

sql/
Governance tables and stored procedures

powerapps/
Power Apps implementation artifacts

powerbi/
Analytical dashboards and reporting components

yaml/
Configuration templates and orchestration definitions


---

## Key Components

### Governance Layer

The governance model allows users to:

- create ingestion configurations
- activate or deactivate pipelines
- block configurations when operational issues occur

Technical parameters remain restricted to technical staff.

---

### Metadata-Driven Design

Instead of embedding ingestion logic directly in pipelines, ingestion behaviour is controlled through configuration records stored in SQL.

This allows ingestion processes to be modified without changing pipeline code.

---

## Project Purpose

The goal of this prototype is to demonstrate how governance mechanisms can be integrated into modern data platforms to enable:

- operational autonomy
- controlled configuration management
- metadata-driven ingestion
- scalable governance frameworks

Power Apps
     ↓
Power Automate
     ↓
SQL Governance Tables
     ↓
Ingestion Pipelines
