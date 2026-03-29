# Odin WebUI Angular Rspack

A full-stack desktop application framework combining Odin backend, Angular frontend with Rspack bundler, and WebUI bridge for seamless bidirectional communication.

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
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Getting Started](#getting-started)
- [Build System](#build-system)
- [Documentation](#documentation)
- [Development](#development)
- [Version Information](#version-information)

---

## Overview

This project demonstrates a modern desktop application architecture featuring:

| Layer | Technology | Purpose |
|-------|------------|---------|
| Backend | Odin | High-performance system programming |
| Bridge | WebUI | Bidirectional IPC via WebSocket |
| Frontend | Angular 21 | Reactive UI framework |
| Bundler | Rspack | Fast web application bundler |

### Key Features

- High Performance: Odin backend with native code execution
- Reactive UI: Angular signals for state management
- Multiple IPC Patterns: RPC, Events, Channels, Message Queue
- Dependency Injection: Angular-inspired DI system in Odin
- Dark Theme: Modern dark gray UI design
- CRUD-Ready Demos: Full database operation examples

---

## Architecture

```
+------------------------------------------------------------------+
|                      Angular Frontend                             |
|  +----------------+  +----------------+  +---------------------+  |
|  |  Components    |  |   Services     |  | Communication Svc   |  |
|  |  (Views)       |  | (Business)     |  | - RPC Client        |  |
|  |                |  |                |  | - Event Bus         |  |
|  +----------------+  +----------------+  | - Channels          |  |
|                                          | - Message Queue     |  |
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
|                    Services Layer                                |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
|  |  Logger   | |   User    | |   Auth    | |  HTTP Service   |   |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
|  |  Storage  | |   Cache   | | Registry  | |  Notification   |   |
|  +-----------+ +-----------+ +-----------+ +-----------------+   |
+------------------------------------------------------------------+
|                 Core Infrastructure                              |
|  +------------+ +------------+ +------------+ +--------------+   |
|  |     DI     | |   Events   | |   Errors   | |  Utilities   |   |
|  +------------+ +------------+ +------------+ +--------------+   |
+------------------------------------------------------------------+
```

---

## Project Structure

```
starter-odin-webui-angular-rspack/
├── frontend/                    # Angular frontend (primary)
│   ├── src/
│   │   ├── core/               # Core services
│   │   ├── app/                # App services
│   │   ├── views/              # Components and views
│   │   ├── models/             # Type definitions
│   │   └── documentation/      # Documentation viewer
│   ├── tests/                  # E2E tests
│   └── docs/                   # Frontend documentation
│
├── src/                        # Odin backend
│   ├── core/                   # Main entry point
│   ├── lib/                    # Core libraries
│   │   ├── di/                 # Dependency injection
│   │   ├── errors/             # Error handling
│   │   ├── events/             # Event bus
│   │   └── utils/              # Utilities
│   ├── services/               # Business logic
│   ├── handlers/               # WebUI handlers
│   └── models/                 # Data models
│
├── build/                      # Build output
├── docs/                       # Consolidated documentation
│   ├── backend/                # Backend docs
│   ├── frontend/               # Frontend docs
│   ├── guides/                 # User guides
│   └── architecture/           # Architecture docs
│
├── lib/                        # Native libraries
├── tests/                      # Backend tests
├── examples/                   # Example code
├── audit/                      # Code audit findings
│
├── Makefile                    # Build automation
├── run.sh                      # Build/run script
├── README.md                   # This file
├── QUICKSTART.md               # Quick setup guide
├── CHANGELOG.md                # Version history
└── ARCHITECTURAL_DECISIONS.md  # Architecture decisions
```

---

## Technology Stack

### Backend

| Technology | Version | Purpose |
|------------|---------|---------|
| Odin | dev-2025-04+ | System programming language |
| WebUI | 2.5.0-beta.4 | Browser UI bridge |
| Civetweb | 1.17 | Embedded WebSocket server |

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| Angular | 21.1.5 | UI framework |
| Rspack | 1.7.6 | Rust-based bundler |
| Bun | 1.3+ | Package manager/runtime |
| Biome | 2.4.2 | Linter/formatter |
| Playwright | 1.42.0 | E2E testing |
| ngx-markdown | 21.1.0 | Markdown rendering |
| Lucide Angular | 0.577.0 | Icon library |

### Development Tools

| Tool | Purpose |
|------|---------|
| Make | Build automation |
| Biome | Linting and formatting |
| Playwright | E2E testing |
| Rspack | Fast bundling with HMR |

---

## Features

### Core Features

- **Full-Stack Architecture**: Odin backend with Angular frontend
- **WebSocket Communication**: Bidirectional IPC via WebUI bridge
- **Dependency Injection**: Type-safe DI in both frontend and backend
- **Event-Driven**: Pub/sub event bus for decoupled communication
- **Thread-Safe**: Mutex-protected operations in backend services

### Frontend Features

- **Signal-Based State**: Modern Angular signals for reactive state
- **Documentation Viewer**: Built-in markdown documentation system
- **CRUD-Ready Demos**: Full database operation examples
- **Dark Theme**: Professional dark gray UI design
- **Responsive Design**: Mobile-first with adaptive layouts

### Backend Features

- **Error Handling**: Errors as values pattern (no exceptions)
- **Service Architecture**: Modular service-based design
- **In-Memory Storage**: Hash map-based data storage
- **Session Management**: Token-based authentication
- **Logging**: Structured logging with levels

### Demo Features

- **DuckDB CRUD**: Full Create, Read, Update, Delete operations
- **SQLite Integration**: Database persistence examples
- **WebSocket Demo**: Real-time communication examples
- **Data Tables**: Reusable data table components
- **Query Builder**: SQL query execution with results viewer

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
make metrics     # Show project statistics
```

For detailed commands, see the [Makefile](Makefile).

---

## Build System

### Build Flow

```
+------------------+
|  Frontend Build  |  bun + rspack
+--------+---------+
         | frontend/dist/
         v
+------------------+
|   Copy Assets    |  copy to build/
+--------+---------+
         |
         v
+------------------+
|   Odin Build     |  odin build
+--------+---------+
         | build/app
         v
+------------------+
| Copy WebUI Lib   |  libwebui-2.so
+--------+---------+
         |
         v
+------------------+
|   Run App        |  LD_LIBRARY_PATH
+------------------+
```

### Output Directories

- `frontend/dist/` - Compiled Angular app
- `build/` - Odin executable and dependencies

---

## Documentation

### Quick References

| Document | Purpose |
|----------|---------|
| [QUICKSTART.md](QUICKSTART.md) | 5-minute setup guide |
| [DX_SUMMARY.md](DX_SUMMARY.md) | Developer experience summary |
| [DX_IMPROVEMENT_PLAN.md](DX_IMPROVEMENT_PLAN.md) | DX improvement roadmap |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [ARCHITECTURAL_DECISIONS.md](ARCHITECTURAL_DECISIONS.md) | Architecture decisions |

### Full Documentation

Located in `docs/` directory:

- `docs/backend/` - Backend documentation
- `docs/frontend/` - Frontend documentation
- `docs/guides/` - User guides and tutorials
- `docs/architecture/` - Architecture documentation

### In-App Documentation

Access documentation directly in the application:
1. Open Dashboard
2. Click "All Docs" in Documentation section
3. Browse sections and topics

---

## Development

### Project Status

| Metric | Status | Notes |
|--------|--------|-------|
| Build | Passing | ~18 seconds |
| Bundle Size | 920 KB | Initial total |
| Test Coverage | Moderate | E2E + unit tests |
| Documentation | Complete | In-app + markdown |

### Recent Changes

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

**Latest Release (Unreleased)**
- Frontend consolidation (merged alt88/alt99 features)
- Documentation system integration
- CRUD-ready demo components
- Thread-safe DI implementation
- Enhanced build script with verification

### Known Issues

See `audit/open/` directory for open audit findings.

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

---

## Testing

### Frontend Tests

```bash
# Unit tests
cd frontend && bun test

# E2E tests
cd frontend && bunx playwright test

# With coverage
cd frontend && bun test --coverage
```

### Backend Tests

```bash
cd tests && odin build *.odin
./di_test
```

---

## Version Information

| Component | Version | Status |
|-----------|---------|--------|
| WebUI | 2.5.0-beta.4 | Stable |
| Civetweb | 1.17 | Stable |
| Odin | dev-2025-04+ | Cutting Edge |
| Angular | 21.1.5 | Latest |
| Rspack | 1.7.6 | Stable |

---

## License

MIT License - See LICENSE file for details.

---

## Support

- **Documentation**: `docs/` directory or in-app viewer
- **Issues**: Check `audit/open/` for known issues
- **Architecture**: See `ARCHITECTURAL_DECISIONS.md`

---

**Last Updated:** 2026-03-29
**Build Status:** Passing
**Development Status:** Active
