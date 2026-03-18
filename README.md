# Odin WebUI Angular Rspack

A full-stack desktop application framework combining **Odin** backend, **Angular** frontend with **Rspack** bundler, and **WebUI** bridge for seamless bidirectional communication.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Communication Methods](#communication-methods)
- [Getting Started](#getting-started)
- [Build System](#build-system)
- [Critics and Suggestions](#critics-and-suggestions)
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

- **High Performance**: Odin backend with native code execution
- **Reactive UI**: Angular signals for state management
- **Multiple IPC Patterns**: RPC, Events, Channels, Message Queue
- **Dependency Injection**: Angular-inspired DI system in Odin
- **Dark Theme**: Modern dark gray UI design

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Angular Frontend                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Components  │  │   Services  │  │  Communication Service  │  │
│  │  (Views)    │  │ (Business)  │  │  - RPC Client          │  │
│  │             │  │             │  │  - Event Bus           │  │
│  └─────────────┘  └─────────────┘  │  - Channels            │  │
│                                    │  - Message Queue        │  │
│                                    └───────────┬─────────────┘  │
└───────────────────────────────────────────────┼───────────────────┘
                                                │
                                    WebSocket (ws://)
                                                │
┌───────────────────────────────────────────────┼───────────────────┐
│                      WebUI Library                              │
│  ┌─────────────────┐  ┌─────────────────────────────────────┐  │
│  │  Civetweb WS    │  │  JavaScript Bridge (webui.js)        │  │
│  │  Server         │  │  - call(function, ...args)            │  │
│  │                 │  │  - emit(event, data)                 │  │
│  └────────┬────────┘  └─────────────────────────────────────┘  │
│           │                                                    │
│           │ FFI (Foreign Function Interface)                    │
└───────────┼────────────────────────────────────────────────────┘
            │
┌───────────┼────────────────────────────────────────────────────┐
│           ▼            Odin Backend                            │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Services Layer                            ││
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐   ││
│  │  │ Logger  │ │  User   │ │  Auth   │ │  HTTP Service   │   ││
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘   ││
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐   ││
│  │  │ Storage │ │  Cache  │ │Registry │ │  Notification   │   ││
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘   ││
│  └─────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   Core Infrastructure                        ││
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  ││
│  │  │    DI    │ │  Events  │ │  Errors  │ │  Utilities   │  ││
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

### Root Directory

```
starter-odin-webui-angular-rspack/
├── main.odin                    # Main application entry
├── webui_lib/                   # WebUI Odin bindings
├── src/                         # Backend source code
├── frontend/                    # Angular frontend
├── thirdparty/                  # External dependencies
├── lib/                         # Shared libraries
├── utils/                       # Utility functions
├── comms/                       # Communication layer
├── errors/                      # Error handling
├── di/                          # Dependency injection
├── build/                       # Build output
└── run.sh                       # Build script
```

### Backend (Odin) Structure

```
src/
├── lib/
│   ├── di/
│   │   └── injector.odin          # Dependency injection container
│   ├── errors/
│   │   └── errors.odin            # Error types and handling
│   ├── events/
│   │   ├── event_bus.odin         # Type-safe event bus
│   │   └── handlers.odin           # Event handlers
│   ├── comms/
│   │   └── comms.odin              # Communication primitives
│   ├── webui_lib/
│   │   └── webui.odin             # WebUI FFI bindings
│   └── utils/
│       ├── logger.odin            # Structured logging
│       ├── config.odin           # Configuration management
│       ├── file_system.odin       # File operations
│       ├── clipboard.odin          # Clipboard access
│       ├── dialogs.odin           # System dialogs
│       ├── system.odin             # System info
│       ├── process.odin            # Process management
│       └── window_utils.odin      # Window utilities
│
├── services/
│   ├── logger.odin               # Logging service
│   ├── user_service.odin         # User management
│   ├── auth_service.odin        # Authentication
│   ├── cache_service.odin       # In-memory cache with TTL
│   ├── storage_service.odin     # Persistent JSON storage
│   ├── http_service.odin        # HTTP client
│   ├── notification_service.odin # System notifications
│   ├── registry.odin            # Service registry
│   └── services.odin             # Service exports
│
└── models/
    └── models.odin              # Data models
```

### Frontend (Angular) Structure

```
frontend/src/
├── app/
│   └── services/
│       └── communication.service.ts  # IPC abstraction layer
│
├── core/
│   ├── api.service.ts             # Backend API service
│   ├── webui/
│   │   ├── index.ts              # WebUI module exports
│   │   ├── webui.service.ts     # WebUI integration
│   │   └── webui-demo.component.ts
│   ├── winbox.service.ts         # WinBox window management
│   ├── logger.service.ts         # Client-side logging
│   ├── theme.service.ts          # Theme management
│   ├── storage.service.ts        # Local storage wrapper
│   ├── http.service.ts          # HTTP client wrapper
│   ├── clipboard.service.ts       # Clipboard operations
│   ├── notification.service.ts    # Browser notifications
│   ├── network-monitor.service.ts
│   ├── loading.service.ts        # Loading state management
│   ├── global-error.service.ts   # Global error handler
│   ├── devtools.service.ts       # DevTools integration
│   ├── lucide-icons.provider.ts  # Icon provider
│   └── *.test.ts                 # Unit tests
│
├── views/
│   ├── app.component.ts           # Main app component
│   ├── app.component.html         # Main app template
│   ├── app.component.css          # Main app styles
│   ├── home/
│   ├── auth/
│   ├── devtools/
│   ├── sqlite/
│   └── shared/
│
├── models/
│   ├── card.model.ts
│   ├── log.model.ts
│   └── window.model.ts
│
├── types/
│   └── error.types.ts
│
├── environments/
│   └── environment.ts
│
├── integration/
│   └── *.test.ts                 # Integration tests
│
├── main.ts                       # Bootstrap
├── index.html                    # HTML entry
├── styles.css                    # Global styles
└── winbox-loader.ts              # WinBox script loader
```

### Communication Layer

```
Frontend IPC Services:
├── RpcClientService          # Request-response calls
├── EventBusService           # Pub/sub events
├── ChannelService            # Full-duplex channels
├── MessageQueueService       # Async message queuing
└── BinaryProtocolService     # Binary encoding/decoding

Backend Communication:
├── RPC Handler               # JSON-RPC style calls
├── Event Bus                # Type-safe event system
├── Channel Manager          # Channel state management
└── WebUI Bindings           # Native FFI calls
```

---

## Communication Methods

### 1. WebSocket (Primary - No HTTP)

```
Angular <--WebSocket--> WebUI/Civetweb <--FFI--> Odin
```

**Port**: Auto-assigned or configurable via `webui_set_port()`

**Security**: TLS supported via `webui-2-secure` variant (wss://)

### 2. RPC (Request-Response)

**Frontend:**
```typescript
const result = await webui.call('functionName', arg1, arg2);
```

**Backend:**
```odin
my_handler :: proc "c" (e: ^webui.Event) {
    data := webui.get_string(e)
    webui.return_string(e, "response")
}
```

### 3. Event Bus (Pub/Sub)

**Frontend:**
```typescript
webui.on('event:name', (data) => { /* handle */ });
```

**Backend:**
```odin
events.emit(&bus, .User_Joined, data)
```

### 4. Direct Binding

**HTML:**
```html
<button id="myBtn">Click</button>
```

**Backend:**
```odin
webui.bind(window, "myBtn", my_callback)
```

### 5. Binary Protocol

Custom binary encoding with header format:
- Magic: `0xABCD`
- Version: `1 byte`
- Message type: `1 byte`
- Length: `4 bytes (little-endian)`
- Payload: `variable`

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

# Install frontend dependencies
cd frontend
bun install
cd ..
```

### Build and Run

```bash
# Full build and run
./run.sh

# Build only
./run.sh --build

# Run only (after build)
./run.sh --run

# Show help
./run.sh --help
```

### Frontend Development

```bash
cd frontend

# Development server with hot reload
bun run dev

# Production build
bun run build:rspack

# Run tests
bun test
```

---

## Build System

### Build Flow

```
┌─────────────────┐
│  Frontend Build  │  bun + rspack
└────────┬────────┘
         │ frontend/dist/
         ▼
┌─────────────────┐
│   Copy Assets   │  copy to build/
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Odin Build    │  odin build
└────────┬────────┘
         │ build/app
         ▼
┌─────────────────┐
│ Copy WebUI Lib  │  libwebui-2.so
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Run App       │  LD_LIBRARY_PATH
└─────────────────┘
```

### Output Directories

- `frontend/dist/` - Compiled Angular app
- `build/` - Odin executable and dependencies

---

## Critics and Suggestions

### Strengths

1. **Clean Architecture**: Clear separation between frontend, bridge, and backend
2. **Multiple IPC Patterns**: Flexibility to choose appropriate communication method
3. **Type Safety**: Odin provides memory safety, Angular provides runtime type checking
4. **Performance**: Native Odin backend with WebSocket bridge is lightweight
5. **Modern UI**: Dark theme with Angular signals for reactive updates

### Weaknesses and Suggestions

#### 1. **Duplicate Code Structure**

**Problem**: Backend code exists in multiple locations:
- `src/`
- `utils/`
- `comms/`
- `errors/`
- `di/`

**Suggestion**: Consolidate into single `src/` structure or use a unified module system.

```odin
// Proposed structure
src/
├── core/           # DI, Events, Errors, Utils
├── services/       # Business logic
└── main.odin
```

#### 2. **Incomplete WebUI Bindings**

**Problem**: Only subset of WebUI API is bound:
- Missing: `webui_script()`, `webui_set_profile()`, `webui_set_proxy()`

**Suggestion**: Complete the bindings or document available APIs clearly.

```odin
// Missing bindings to add:
webui_script        :: proc(win: c.size_t, script: cstring, timeout: c.uint, buffer: [^]u8, buffer_len: c.size_t) -> bool ---
webui_set_profile   :: proc(win: c.size_t, name: cstring, path: cstring) ---
```

#### 3. **No Type-Safe IPC Protocol**

**Problem**: Current RPC uses string function names, prone to typos.

**Suggestion**: Generate typed bindings from shared schema.

```typescript
// Current (error-prone)
webui.call('user.authenticate', creds)

// Proposed (type-safe)
import { backend } from './generated/api';
backend.user.authenticate(creds);
```

#### 4. **Missing Error Handling Patterns**

**Problem**: Inconsistent error propagation between services.

**Suggestion**: Standardize error handling with Result type pattern.

```odin
Result :: struct($T: typeid) {
    value: Maybe(T),
    error: Maybe(Error),
}

authenticate :: proc(creds: Credentials) -> Result(User) {
    // Return typed result
}
```

#### 5. **Test Coverage Gaps**

**Problem**: Many tests fail or are missing browser mocks.

**Suggestion**: 
- Use proper mocking libraries (Jest with jsdom)
- Separate unit tests from integration tests
- Add E2E tests with Playwright/Cypress

#### 6. **Configuration Management**

**Problem**: Hardcoded values scattered across code.

**Suggestion**: Centralize configuration.

```odin
// config.odin
Config :: struct {
    webui_port: u16,
    log_level: Log_Level,
    storage_path: string,
}

default_config :: Config {
    .webui_port = 0,  // Auto
    .log_level = .Info,
    .storage_path = "./data",
}
```

#### 7. **Security Considerations**

**Missing**:
- No HTTPS/WSS by default
- No authentication middleware
- No input validation on IPC boundaries

**Suggestions**:
```odin
// Enable TLS
webui_set_tls_certificate(win, cert_path, key_path)

// Add authentication middleware
@middleware(auth_required)
handle_sensitive_data :: proc(e: ^webui.Event) {
    // Validate token before processing
}
```

#### 8. **Documentation Gaps**

**Missing**:
- API documentation for services
- Deployment guide
- Troubleshooting section
- Migration guide

#### 9. **Build System Complexity**

**Problem**: `run.sh` script is custom, not using standard tools.

**Suggestion**: Consider using:
- `just` command runner
- Task automation with `task` (Go)
- Or proper Makefile

#### 10. **Frontend State Management**

**Current**: Component-level signals

**Suggestion for scale**: Consider adding:
- NgRx for global state
- TanStack Query for server state
- Router for navigation

---

## Version Information

| Component | Version | Status |
|-----------|---------|--------|
| WebUI | 2.5.0-beta.4 | Stable |
| Civetweb | 1.17 | Stable |
| Odin | dev-2025-04+ | Cutting Edge |
| Angular | 21.1.5 | Latest |
| Rspack | 1.7.6 | Stable |
| Lucide | (via lucide-angular) | Latest |

---

## License

MIT License - See LICENSE file for details.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure tests pass
5. Submit a pull request

### Code Style

- Odin: Follow `core:fmt` conventions
- TypeScript: Follow Angular style guide
- CSS: BEM naming convention
