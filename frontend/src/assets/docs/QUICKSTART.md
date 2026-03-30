# ⚡ Quick Start Guide - DuckDB & SQLite CRUD

**Get your CRUD application running in 5 minutes!**

---

## 🚀 First Time Setup

### **1. Prerequisites Check**

```bash
# Verify Odin compiler
odin version

# Verify Bun (or Node.js)
bun --version

# Verify C compiler (for WebUI)
gcc --version
```

**Missing something?**
- Odin: https://odin-lang.org/docs/install/
- Bun: https://bun.sh/
- GCC: `sudo apt install build-essential` (Linux)

---

## **2. Install Dependencies**

```bash
# One command install
make install

# Or manually
cd frontend && bun install
```

**Time:** ~30 seconds (with Bun)

---

## **3. Start Development**

```bash
# Start development server
make dev

# Access the application
# Open http://localhost:4200
```

**You should see:**
- Dashboard with DuckDB and SQLite CRUD demos
- User management interface
- Query builder for DuckDB

---

## 🎯 CRUD Demo Access

### **DuckDB CRUD Demo**
- **Location**: Dashboard → DuckDB Demo
- **Features**: User management, query builder, analytics
- **Backend**: Odin + DuckDB
- **Use Case**: Analytical queries, data warehousing

### **SQLite CRUD Demo**
- **Location**: Dashboard → SQLite Demo
- **Features**: User management, lightweight operations
- **Backend**: Odin + SQLite
- **Use Case**: Transactional operations, embedded storage

---

## 📝 Common Commands

### **Development**
```bash
make dev          # Start everything
make build        # Build everything
make clean        # Clean build artifacts
```

### **Testing**
```bash
make test         # Run all tests
cd frontend && bun test         # Frontend unit tests
cd frontend && bunx playwright test  # E2E tests
```

### **Database Operations**
```bash
# DuckDB operations are available via:
# - UI: DuckDB Demo → Query Builder
# - Backend: src/services/duckdb_service.odin

# SQLite operations are available via:
# - UI: SQLite Demo
# - Backend: src/services/sqlite_service.odin
```

---

## 🏗️ Project Structure for CRUD

```
project/
├── frontend/src/views/
│   ├── duckdb/              # DuckDB CRUD components
│   │   ├── duckdb-demo.component.ts
│   │   ├── duckdb-users.component.ts
│   │   ├── duckdb-products.component.ts
│   │   └── duckdb-orders.component.ts
│   └── sqlite/              # SQLite CRUD components
│       └── sqlite.component.ts
│
├── src/
│   ├── services/            # Backend services
│   │   ├── duckdb_service.odin
│   │   ├── sqlite_service.odin
│   │   └── user_service.odin
│   └── handlers/            # WebUI handlers
│       └── webui_handlers.odin
│
├── docs/
│   ├── backend/             # Backend integration guides
│   │   ├── duckdb-integration.md
│   │   └── sqlite-integration.md
│   ├── frontend/            # Frontend component guides
│   │   ├── duckdb-components.md
│   │   └── sqlite-components.md
│   └── guides/              # CRUD tutorials
│       └── crud-operations-guide.md
│
└── Makefile                 # Build commands
```

---

## 🎓 Next Steps

### **1. Read CRUD Documentation**
- [DuckDB Integration Guide](docs/backend/duckdb-integration.md) - Backend setup
- [SQLite Integration Guide](docs/backend/sqlite-integration.md) - Backend setup
- [CRUD Operations Guide](docs/guides/crud-operations-guide.md) - Complete tutorial

### **2. Explore the Code**
- Frontend: `frontend/src/views/duckdb/` and `frontend/src/views/sqlite/`
- Backend: `src/services/duckdb_service.odin` and `src/services/sqlite_service.odin`

### **3. Start Developing**
- Modify existing CRUD components
- Add new database tables
- Create custom queries

---

## 🛠️ VSCode Setup

### **Required Extensions**
```bash
# Install from VSCode Extensions panel:
# - Biome (biomejs.biome)
# - Angular Language Service (Angular.ng-template)
```

### **Settings**
Already configured in `.vscode/settings.json`:
- ✅ Format on save
- ✅ Organize imports on save
- ✅ Exclude build artifacts from search

---

## 🐛 Troubleshooting

### **"Module not found"**
```bash
make clean
make install
```

### **"Port 4200 already in use"**
```bash
# Kill process on port 4200
lsof -ti:4200 | xargs kill -9
```

### **"Database not found"**
```bash
# DuckDB/SQLite databases are created automatically
# Check build/ directory for database files
ls build/*.db
```

### **"WebUI library not found"**
```bash
# Rebuild
make clean
make build
```

---

## 📞 Need Help?

- **DuckDB Guide**: [docs/backend/duckdb-integration.md](docs/backend/duckdb-integration.md)
- **SQLite Guide**: [docs/backend/sqlite-integration.md](docs/backend/sqlite-integration.md)
- **CRUD Tutorial**: [docs/guides/crud-operations-guide.md](docs/guides/crud-operations-guide.md)
- **Architecture**: [ARCHITECTURAL_DECISIONS.md](ARCHITECTURAL_DECISIONS.md)

---

**Happy Coding!** 🚀
