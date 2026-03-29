# Project Documentation

Consolidated documentation for the Odin WebUI Angular Rspack project.

## 📁 Documentation Structure

```
docs/
├── backend/           # Backend (Odin) documentation
├── frontend/          # Frontend (Angular) documentation
├── api/               # API documentation
├── guides/            # User and developer guides
└── architecture/      # Architecture documentation
```

## 🚀 Quick Start

### For Developers
1. **Backend**: See [`docs/backend/`](docs/backend/)
2. **Frontend**: See [`docs/frontend/`](docs/frontend/)
3. **API**: See [`docs/api/`](docs/api/)

### For Users
1. **Getting Started**: See [`docs/guides/`](docs/guides/)

## 📋 Key Documents

### Backend
- [DI System](docs/backend/01_DI_SYSTEM.md) - Dependency injection system
- [Error Handling](docs/backend/02_ERROR_HANDLING_GUIDE.md) - Error handling patterns
- [Communication](docs/backend/04_COMMUNICATION_APPROACHES.md) - Backend communication patterns
- [Build System](docs/backend/06_BUILD_SYSTEM.md) - Build system documentation

### Frontend
- [Frontend README](docs/frontend/00-README.md) - Frontend overview
- [Testing Guide](docs/frontend/04-TESTING_GUIDE.md) - Frontend testing
- [Data Transform Services](docs/guides/ANGULAR_DATA_TRANSFORM_SERVICES.md) - Data transformation utilities

### Architecture
- [WebUI Integration](docs/guides/README_WEBUI_INTEGRATION.md) - WebUI bridge documentation
- [Enterprise Readiness](docs/guides/ENTERPRISE_READINESS_AUDIT.md) - Enterprise audit

## 🔧 Development

### Build Commands
```bash
# Build everything
./run.sh --build

# Build frontend only
cd frontend && npm run build

# Build backend only
odin build . -out:build/app
```

### Test Commands
```bash
# Frontend tests
cd frontend && npm test

# E2E tests
cd frontend && npm run test:e2e

# Backend tests
cd tests && odin build *.odin
```

## 📝 Documentation Guidelines

When adding new documentation:
1. Place in appropriate subdirectory
2. Use markdown format
3. Include in this index
4. Update relevant README files

## 🗑️ Deprecated Locations

The following documentation locations are deprecated and will be removed:
- `frontend/docs/` → Moved to `docs/frontend/`
- `frontend/src/assets/docs/` → Moved to `docs/guides/`
- `frontend-alt88/docs/` → Will be removed
- `frontend-alt99/docs/` → Will be removed
- `di/README.md` → Moved to `docs/backend/`
- `utils/README.md` → Moved to `docs/backend/`

---

**Last Updated:** 2026-03-29
**Status:** Documentation consolidation in progress
