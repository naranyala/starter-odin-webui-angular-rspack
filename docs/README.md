# Documentation Index

**Production-Ready DuckDB & SQLite CRUD Integration**

---

## Quick Start

1. **Setup**: See [QUICKSTART.md](../../QUICKSTART.md)
2. **CRUD Tutorial**: Start with [CRUD Operations Guide](./guides/crud-operations-guide.md)
3. **Backend**: Read [DuckDB](./backend/duckdb-integration.md) or [SQLite](./backend/sqlite-integration.md) guide
4. **Frontend**: Read [DuckDB Components](./frontend/duckdb-components.md) or [SQLite Components](./frontend/sqlite-components.md)

---

## Documentation Structure

```
docs/
├── backend/              # Backend integration guides
│   ├── duckdb-integration.md
│   └── sqlite-integration.md
├── frontend/             # Frontend component guides
│   ├── duckdb-components.md
│   └── sqlite-components.md
└── guides/               # Tutorials and how-tos
    └── crud-operations-guide.md
```

---

## Backend Integration

### DuckDB Integration
**File:** [backend/duckdb-integration.md](./backend/duckdb-integration.md)

Complete guide for integrating DuckDB with Odin backend:
- Database setup and initialization
- CRUD operations (Create, Read, Update, Delete)
- Query builder support
- Analytics functions
- WebUI handlers
- Frontend integration
- Production considerations
- Testing strategies

**Best for:** Analytical queries, data warehousing, complex aggregations

---

### SQLite Integration
**File:** [backend/sqlite-integration.md](./backend/sqlite-integration.md)

Complete guide for integrating SQLite with Odin backend:
- Database setup and initialization
- CRUD operations (Create, Read, Update, Delete)
- Transaction support
- Analytics functions
- WebUI handlers
- Frontend integration
- Production considerations
- Testing strategies

**Best for:** Transactional operations, lightweight storage, embedded deployments

---

## Frontend Components

### DuckDB Components
**File:** [frontend/duckdb-components.md](./frontend/duckdb-components.md)

Angular components for DuckDB CRUD operations:
- `DuckdbDemoComponent` - Main interface with tabs
- `DuckdbUsersComponent` - User management table
- `DuckdbProductsComponent` - Product catalog
- `DuckdbOrdersComponent` - Order management
- `DuckdbAnalyticsComponent` - Data analytics dashboard
- Service integration
- Best practices
- Testing

**Features:** Query builder, analytics, advanced filtering

---

### SQLite Components
**File:** [frontend/sqlite-components.md](./frontend/sqlite-components.md)

Angular components for SQLite CRUD operations:
- `SqliteCrudComponent` - Main CRUD interface
- User management with create, read, update, delete
- Real-time statistics display
- Search and filter functionality
- Service integration
- Best practices
- Testing

**Features:** Simple CRUD, transactional operations, lightweight UI

---

## Guides & Tutorials

### CRUD Operations Guide
**File:** [guides/crud-operations-guide.md](./guides/crud-operations-guide.md)

End-to-end tutorial for implementing CRUD operations:
- Part 1: Database Setup
- Part 2: Backend CRUD Operations
- Part 3: WebUI Handlers
- Part 4: Frontend Implementation
- Part 5: Testing
- Best Practices
- Troubleshooting

**Start here if:** You're new to the project or need a complete walkthrough

---

## Comparison: DuckDB vs SQLite

| Feature | DuckDB | SQLite |
|---------|--------|--------|
| **Best For** | Analytics | Transactions |
| **Storage** | Columnar | Row-based |
| **Performance** | OLAP queries | OLTP operations |
| **Concurrency** | Read-heavy | Read-write |
| **Query Builder** | Yes | No |
| **Analytics** | Advanced | Basic |
| **File Size** | Larger | Smaller |

### When to Use Each

**Use DuckDB when:**
- Running complex analytical queries
- Processing large datasets
- Need columnar storage benefits
- Building data warehouses
- Need query builder functionality

**Use SQLite when:**
- Building transactional applications
- Need ACID compliance
- Require minimal footprint
- Embedded/local storage needed
- Simple CRUD operations sufficient

---

## Additional Resources

### Project Documentation
- [README](../../README.md) - Project overview
- [QUICKSTART](../../QUICKSTART.md) - 5-minute setup guide
- [ARCHITECTURAL_DECISIONS](../../ARCHITECTURAL_DECISIONS.md) - Architecture decisions
- [CHANGELOG](../../CHANGELOG.md) - Version history

### External Resources
- [DuckDB Official Documentation](https://duckdb.org/docs/)
- [SQLite Official Documentation](https://www.sqlite.org/docs.html)
- [Odin Language](https://odin-lang.org/)
- [Angular Documentation](https://angular.dev/)
- [WebUI Documentation](https://webui.me/docs/)

---

## Getting Help

1. **Check the CRUD guide** - Most questions answered in [crud-operations-guide.md](./guides/crud-operations-guide.md)
2. **Review backend guides** - [duckdb-integration.md](./backend/duckdb-integration.md) or [sqlite-integration.md](./backend/sqlite-integration.md)
3. **Check frontend guides** - [duckdb-components.md](./frontend/duckdb-components.md) or [sqlite-components.md](./frontend/sqlite-components.md)
4. **Review examples** - Look at existing components in `frontend/src/views/`

---

**Last Updated:** 2026-03-30
**Documentation Status:** CRUD-Focused
