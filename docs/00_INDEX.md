# Documentation Index

## Project Overview

Full-stack desktop application framework combining:
- **Backend**: Odin programming language
- **Frontend**: Angular with Rspack bundler
- **Communication**: WebUI bridge
- **DI System**: Angular-inspired dependency injection

## Directory Structure

```
src/
├── lib/
│   ├── di/              # Dependency Injection
│   │   └── injector.odin
│   ├── errors/          # Error handling
│   │   └── errors.odin
│   ├── events/          # Type-safe event bus
│   │   ├── event_bus.odin
│   │   └── handlers.odin
│   ├── comms/           # Communication layer
│   │   └── comms.odin
│   ├── webui_lib/       # WebUI bindings
│   │   └── webui.odin
│   └── utils/           # Utilities
├── services/            # Application services
│   ├── logger.odin
│   ├── user_service.odin
│   ├── auth_service.odin
│   ├── cache_service.odin
│   ├── storage_service.odin
│   ├── http_service.odin
│   ├── notification_service.odin
│   └── registry.odin
└── models/
    └── models.odin
```

## Core Documentation

| # | Document | Description |
|---|----------|-------------|
| 01 | [01_DI_SYSTEM.md](01_DI_SYSTEM.md) | Dependency Injection system |
| 02 | [02_ERROR_HANDLING_GUIDE.md](02_ERROR_HANDLING_GUIDE.md) | Error handling usage |
| 03 | [03_ERROR_HANDLING_SUMMARY.md](03_ERROR_HANDLING_SUMMARY.md) | Error handling summary |
| 04 | [04_COMMUNICATION_APPROACHES.md](04_COMMUNICATION_APPROACHES.md) | **Communication patterns** |
| 05 | [05_COMMUNICATION_EXAMPLES.md](05_COMMUNICATION_EXAMPLES.md) | **Usage examples** |
| 06 | [06_BUILD_SYSTEM.md](06_BUILD_SYSTEM.md) | Build pipeline |
| 07 | [07_WEBUI_INTEGRATION_EVALUATION.md](07_WEBUI_INTEGRATION_EVALUATION.md) | WebUI details |
| 08 | [08_WEBUI_CIVETWEB_SUMMARY.md](08_WEBUI_CIVETWEB_SUMMARY.md) | CivetWeb info |

---

## Communication Approaches

The project supports 6 communication patterns:

| Approach | Pattern | Best For |
|----------|---------|----------|
| **RPC** | Request-Response | User actions, data fetch |
| **Event Bus** | Publish-Subscribe | Notifications, state sync |
| **Direct Binding** | Element-Handler | UI interactions |
| **Channels** | Full-Duplex Stream | Chat, live updates |
| **Message Queue** | Async Processing | Background tasks |
| **Binary Protocol** | Compact Binary | High-perf data |

See [04_COMMUNICATION_APPROACHES.md](04_COMMUNICATION_APPROACHES.md) for details.

---

## Quick Start

```bash
# Build all components
./run.sh build

# Run the application
./run.sh run

# Development mode
./run.sh dev
```

---

## Key Features

### Dependency Injection
- Token-based service registration
- Provider types: Class, Singleton, Factory, Value
- Errors as values pattern

### Services
- **Logger**: Logging with levels
- **User**: User management
- **Auth**: Authentication & sessions
- **Cache**: In-memory caching with TTL
- **Storage**: Persistent JSON storage
- **Http**: HTTP client
- **Notification**: System notifications

### Error Handling
- 27 error codes
- Error results for explicit propagation
- Error wrapping for context

---

## Build Commands

| Command | Description |
|---------|-------------|
| `./run.sh build` | Build all components |
| `./run.sh run` | Run application |
| `./run.sh dev` | Start dev server |
| `./run.sh clean` | Clean artifacts |
| `./run.sh test` | Run tests |

---

## Version Information

| Component | Version |
|-----------|---------|
| WebUI | 2.5.0-beta.4 |
| CivetWeb | 1.17 |
| Odin | dev-2025-04+ |
