# Odin WebUI Angular Rspack - Production Database Integration

A full-stack desktop application framework combining Odin backend, Angular 21 frontend with Rspack bundler, and WebUI bridge for seamless bidirectional communication. Features production-ready DuckDB and SQLite database integration with complete CRUD operations.

## Quick Start

```bash
# Install dependencies
make install

# Start development server
make dev

# Open http://localhost:4200
```

For detailed setup instructions, see QUICKSTART.md.

---

## Table of Contents

- Quick Start
- Overview
- Architecture
- Database Options
- Technology Stack
- Getting Started
- Documentation
- Development

---

## Overview

This project provides a production-ready full-stack application architecture with dual database support:

| Layer | Technology | Purpose |
|-------|------------|---------|
| Backend | Odin | High-performance system programming |
| Database | DuckDB / SQLite | Analytical and transactional data storage |
| Bridge | WebUI | Bidirectional IPC via WebSocket |
| Frontend | Angular 21 | Reactive UI framework with CRUD components |
| Bundler | Rspack | Fast web application bundler |

### Key Features

- Dual Database Support: DuckDB for analytics, SQLite for transactions
- Complete CRUD Operations: Create, Read, Update, Delete for both databases
- Real-time Updates: WebSocket-based live data synchronization
- Query Builder: Visual SQL query construction and execution
- Type-Safe: End-to-end TypeScript and Odin type consistency
- Thread-Safe: Mutex-protected backend operations
- Data Visualization: Vega-Lite charts for analytics

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
|  | - Charts       |  | - Analytics    |  | - Message Queue     |  |
|  +----------------+  +----------------+  +----------+----------+  |
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

## Database Options

### DuckDB - Analytical Database

**Purpose:** Online Analytical Processing (OLAP), complex queries, data warehousing

**Use Cases:**
- Complex analytical queries
- Large dataset processing
- Data warehousing and business intelligence
- Real-time analytics dashboards
- Columnar storage benefits

**Features:**
- Columnar vectorized execution
- SQL-92 compliance
- ACID compliance
- In-memory and persistent storage
- Query optimization
- Built-in aggregation functions

**Example Operations:**
```sql
-- Complex aggregation
SELECT 
    DATE_TRUNC('month', created_at) AS month,
    COUNT(*) AS user_count,
    AVG(age) AS avg_age
FROM users
GROUP BY 1
ORDER BY 1;

-- Join operations
SELECT u.name, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id;
```

**Frontend Components:**
- DuckdbProfessionalComponent - Complete CRUD with analytics
- DuckdbUsersComponent - User management table
- DuckdbProductsComponent - Product catalog
- DuckdbOrdersComponent - Order management
- DuckdbAnalyticsComponent - Data analytics dashboard

---

### SQLite - Transactional Database

**Purpose:** Online Transaction Processing (OLTP), embedded storage, lightweight operations

**Use Cases:**
- Transactional operations
- Embedded local storage
- Mobile and desktop applications
- Lightweight deployments
- Zero-configuration database

**Features:**
- Row-based storage
- Full ACID compliance
- Serverless architecture
- Self-contained library
- Cross-platform compatibility
- Minimal footprint

**Example Operations:**
```sql
-- Transactional insert
INSERT INTO products (name, price, category, stock)
VALUES ('New Product', 29.99, 'Electronics', 100);

-- Update with transaction
BEGIN TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE id = 123;
INSERT INTO orders (product_id, quantity) VALUES (123, 1);
COMMIT;
```

**Frontend Components:**
- SqliteProfessionalComponent - Complete CRUD interface
- SqliteCrudComponent - Simplified CRUD operations

---

### Database Comparison

| Feature | DuckDB | SQLite |
|---------|--------|--------|
| Storage Type | Columnar | Row-based |
| Best For | OLAP / Analytics | OLTP / Transactions |
| Query Performance | Complex aggregations | Simple lookups |
| Concurrency | Read-heavy | Read-write |
| Memory Usage | Higher | Lower |
| File Size | Larger | Smaller |
| Indexing | Limited | Comprehensive |
| Foreign Keys | Limited | Full support |
| Triggers | No | Yes |

### When to Use Each

**Choose DuckDB when:**
- Running complex analytical queries
- Processing large datasets (millions of rows)
- Need columnar storage benefits
- Building data warehouses or BI dashboards
- Performing statistical analysis

**Choose SQLite when:**
- Building transactional applications
- Need full ACID compliance
- Require minimal footprint
- Embedded or local storage needed
- Simple CRUD operations sufficient

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
| Vega | 6.2.0 | Data visualization |
| Vega-Lite | 6.4.2 | Chart grammar |
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

### Database Integration Guides

| Document | Purpose |
|----------|---------|
| docs/backend/duckdb-integration.md | Production DuckDB backend setup |
| docs/backend/sqlite-integration.md | Production SQLite backend setup |
| docs/frontend/duckdb-components.md | DuckDB Angular components |
| docs/frontend/sqlite-components.md | SQLite Angular components |
| docs/guides/crud-operations-guide.md | Complete CRUD operations tutorial |

### Quick References

| Document | Purpose |
|----------|---------|
| QUICKSTART.md | 5-minute setup guide |
| ARCHITECTURAL_DECISIONS.md | Architecture decisions |
| CHANGELOG.md | Version history |
| SECURITY_AUDIT.md | Security audit report |

### Full Documentation

Located in docs/ directory:

- docs/backend/ - Backend database integration
- docs/frontend/ - Frontend component guides
- docs/guides/ - User guides and tutorials
- docs/api/ - API reference

---

## Development

### Project Structure

```
starter-odin-webui-angular-rspack/
├── frontend/                    # Angular frontend
│   └── src/
│       ├── core/               # Core services (API, Logger)
│       ├── app/
│       │   ├── services/       # Application services
│       │   ├── features/       # Feature modules
│       │   └── shared/         # Shared components
│       ├── views/
│       │   ├── duckdb/         # DuckDB CRUD components
│       │   ├── sqlite/         # SQLite CRUD components
│       │   ├── charts/         # Vega charts components
│       │   └── demo/           # Demo components
│       └── models/             # Type definitions
│
├── src/                        # Odin backend
│   ├── core/                   # Main entry point
│   ├── lib/                    # Core libraries
│   │   ├── database/           # Database abstraction layer
│   │   ├── crud/               # Generic CRUD operations
│   │   ├── di/                 # Dependency injection
│   │   └── events/             # Event bus
│   ├── services/               # Business logic services
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

## API Endpoints

### DuckDB Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| getUsers | GET | Retrieve all users |
| getUserStats | GET | Get user statistics |
| createUser | POST | Create new user |
| updateUser | PUT | Update existing user |
| deleteUser | DELETE | Delete user |
| executeQuery | POST | Execute custom SQL query |

### SQLite Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| sqlite:getProducts | GET | Retrieve all products |
| sqlite:getProductStats | GET | Get product statistics |
| sqlite:createProduct | POST | Create new product |
| sqlite:updateProduct | PUT | Update existing product |
| sqlite:deleteProduct | DELETE | Delete product |

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

- Database Documentation: docs/backend/ and docs/frontend/
- Quick Start: QUICKSTART.md
- Architecture: ARCHITECTURAL_DECISIONS.md
- Security: SECURITY_AUDIT.md

---

Last Updated: 2026-03-30
Build Status: Passing
Database Status: Production Ready
