# Odin WebUI Angular Rspack - Production DuckDB & SQLite CRUD

A production-ready full-stack desktop application framework with **complete DuckDB and SQLite CRUD integration**, featuring Odin backend, Angular 21 frontend with Rspack bundler, and WebUI bridge for seamless bidirectional communication.

## Quick Start

```bash
# Install dependencies
make install

# Start development server
make dev

# Open http://localhost:4200
```

For detailed setup instructions, see [QUICKSTART.md](QUICKSTART.md).

---

## Table of Contents

- [Quick Start](#quick-start)
- [Overview](#overview)
- [Architecture](#architecture)
- [CRUD Features](#crud-features)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Development](#development)

---

## Overview

This project provides a **production-ready CRUD integration** for DuckDB and SQLite databases with a modern desktop application architecture:

| Layer | Technology | Purpose |
|-------|------------|---------|
| Backend | Odin | High-performance system programming |
| Database | DuckDB / SQLite | Analytical & transactional data storage |
| Bridge | WebUI | Bidirectional IPC via WebSocket |
| Frontend | Angular 21 | Reactive UI framework with CRUD components |
| Bundler | Rspack | Fast web application bundler |

### Key Features

- **Production-Ready CRUD**: Complete Create, Read, Update, Delete operations
- **Dual Database Support**: DuckDB for analytics, SQLite for transactions
- **Real-time Updates**: WebSocket-based live data synchronization
- **Query Builder**: Visual SQL query construction and execution
- **Type-Safe**: End-to-end TypeScript/Odin type consistency
- **Thread-Safe**: Mutex-protected backend operations

---

## Architecture

```
+------------------------------------------------------------------+
|                      Angular Frontend                             |
|  +----------------+  +----------------+  +---------------------+  |
|  |  CRUD          |  |   Database     |  | Communication Svc   |  |
|  |  Components    |  |   Services     |  | - RPC Client        |  |
|  | - DuckDB Demo  |  | - DuckDB Svc   |  | - Event Bus         |  |
|  | - SQLite Demo  |  | - SQLite Svc   |  | - Channels          |  |
|  +----------------+  +----------------+  | - Message Queue     |  |
|                                          +----------+----------+  |
+------------------------------------------------------------------+
                                                   |
                                       WebSocket (ws://)
                                                   |
+------------------------------------------------------------------+
|                      WebUI Library                               |
|  +-----------------+  +---------------------------------------+  |
|  |  Civetweb WS    |  |  JavaScript Bridge (webui.js)         |  |
|  |  Server         |  |  - call(function, ...args)            |  |
|  |                 |  |  - emit(event, data)                  |  |
|  +--------+--------+  +---------------------------------------+  |
|           |                                                     |
|           | FFI (Foreign Function Interface)                    |
+-----------+-----------------------------------------------------+
            |
+-----------+-----------------------------------------------------+
            v            Odin Backend                             |
+------------------------------------------------------------------+
|                    Database Services Layer                       |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
|  |  DuckDB   | |  SQLite   | |   User    | |  Validation     |   |
|  |  Service  | |  Service  | |  Service  | |  Service        |   |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
|  |  Logger   | |   Auth    | | Registry  | |  Error Handler  |   |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
+------------------------------------------------------------------+
|                 Core Infrastructure                              |
|  +------------+ +------------+ +------------+ +--------------+   |
|  |     DI     | |   Events   | |   Errors   | |  Utilities   |   |
|  +------------+ +------------+ +------------+ +--------------+   |
+------------------------------------------------------------------+
```

---

## CRUD Features

### DuckDB Integration

**Purpose**: Analytical queries, data warehousing, complex aggregations

**Features**:
- ✅ **Create**: Add users with validation
- ✅ **Read**: List users with search/filter, load statistics
- ✅ **Update**: Edit user information
- ✅ **Delete**: Remove users with confirmation
- ✅ **Query Builder**: Visual SQL construction
- ✅ **Analytics**: Total users, daily counts, email domain analysis

**Components**:
- `DuckdbDemoComponent` - Main DuckDB CRUD interface
- `DuckdbUsersComponent` - User management table
- `DuckdbProductsComponent` - Product catalog
- `DuckdbOrdersComponent` - Order management
- `DuckdbAnalyticsComponent` - Data analytics dashboard

### SQLite Integration

**Purpose**: Transactional operations, lightweight storage, embedded deployments

**Features**:
- ✅ **Create**: Add users with validation
- ✅ **Read**: List users with search/filter, load statistics
- ✅ **Update**: Edit user information
- ✅ **Delete**: Remove users with confirmation
- ✅ **Lightweight**: Minimal footprint, zero configuration

**Components**:
- `SqliteCrudComponent` - Main SQLite CRUD interface

---

## Technology Stack

### Backend

| Technology | Version | Purpose |
|------------|---------|---------|
| Odin | dev-2025-04+ | System programming language |
| WebUI | 2.5.0-beta.4 | Browser UI bridge |
| Civetweb | 1.17 | Embedded WebSocket server |
| DuckDB | Latest | Analytical database |
| SQLite | Latest | Transactional database |

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| Angular | 21.1.5 | UI framework |
| Rspack | 1.7.6 | Rust-based bundler |
| Bun | 1.3+ | Package manager/runtime |
| Biome | 2.4.2 | Linter/formatter |
| Playwright | 1.42.0 | E2E testing |
| Lucide Angular | 0.577.0 | Icon library |

---

## Getting Started

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Odin | dev-2025-04+ | Backend compilation |
| Bun | 1.3+ | Frontend tooling |
| C Compiler | GCC/Clang | WebUI bridge |

### Installation

```bash
# Clone repository
git clone <repo-url>
cd starter-odin-webui-angular-rspack

# Install dependencies
make install

# Start development
make dev
```

### Build Commands

```bash
make install     # Install all dependencies
make dev         # Start development server
make build       # Build everything
make test        # Run all tests
make clean       # Clean build artifacts
make lint        # Lint and fix issues
```

---

## Documentation

### CRUD Integration Guides

| Document | Purpose |
|----------|---------|
| [docs/backend/duckdb-integration.md](docs/backend/duckdb-integration.md) | Production DuckDB backend setup |
| [docs/backend/sqlite-integration.md](docs/backend/sqlite-integration.md) | Production SQLite backend setup |
| [docs/frontend/duckdb-components.md](docs/frontend/duckdb-components.md) | DuckDB Angular components |
| [docs/frontend/sqlite-components.md](docs/frontend/sqlite-components.md) | SQLite Angular components |
| [docs/guides/crud-operations-guide.md](docs/guides/crud-operations-guide.md) | Complete CRUD operations tutorial |

### Quick References

| Document | Purpose |
|----------|---------|
| [QUICKSTART.md](QUICKSTART.md) | 5-minute setup guide |
| [ARCHITECTURAL_DECISIONS.md](ARCHITECTURAL_DECISIONS.md) | CRUD architecture decisions |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

### Full Documentation

Located in `docs/` directory:

- `docs/backend/` - Backend database integration
- `docs/frontend/` - Frontend CRUD components
- `docs/guides/` - User guides and tutorials
- `docs/api/` - API reference

---

## Development

### Project Structure

```
starter-odin-webui-angular-rspack/
├── frontend/                    # Angular frontend
│   └── src/
│       ├── core/               # Core services (API, Logger)
│       ├── views/
│       │   ├── duckdb/         # DuckDB CRUD components
│       │   ├── sqlite/         # SQLite CRUD components
│       │   └── shared/         # Shared components (DataTable)
│       └── models/             # Type definitions
│
├── src/                        # Odin backend
│   ├── core/                   # Main entry point
│   ├── lib/                    # Core libraries (DI, Events)
│   ├── services/               # Database services
│   │   ├── duckdb_service.odin
│   │   ├── sqlite_service.odin
│   │   └── user_service.odin
│   └── handlers/               # WebUI handlers
│
├── docs/                       # Documentation
│   ├── backend/                # Backend integration guides
│   ├── frontend/               # Frontend component guides
│   └── guides/                 # CRUD tutorials
│
├── build/                      # Build output
├── Makefile                    # Build automation
└── README.md                   # This file
```

### Testing

```bash
# Frontend tests
cd frontend && bun test

# E2E tests
cd frontend && bunx playwright test

# Backend tests
cd tests && odin build *.odin
```

---

## Version Information

| Component | Version | Status |
|-----------|---------|--------|
| WebUI | 2.5.0-beta.4 | Stable |
| DuckDB | Latest | Production Ready |
| SQLite | Latest | Production Ready |
| Odin | dev-2025-04+ | Cutting Edge |
| Angular | 21.1.5 | Latest |
| Rspack | 1.7.6 | Stable |

---

## Support

- **CRUD Documentation**: `docs/backend/` and `docs/frontend/`
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Architecture**: [ARCHITECTURAL_DECISIONS.md](ARCHITECTURAL_DECISIONS.md)

---

**Last Updated:** 2026-03-30
**Build Status:** Passing
**CRUD Status:** Production Ready
