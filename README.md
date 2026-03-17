# Odin WebUI Angular Rspack

A full-stack desktop application framework combining:
- **Backend**: Odin programming language
- **Frontend**: Angular with Rspack bundler
- **Communication**: WebUI bridge for backend-frontend communication
- **DI System**: Angular-inspired dependency injection

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Backend-Frontend Communication](#backend-frontend-communication)
3. [Dependency Injection System](#dependency-injection-system)
4. [Services](#services)
5. [Event System](#event-system)
6. [Quick Start](#quick-start)
7. [Build & Run](#build--run)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Angular Frontend                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Components + Services + WebUI JavaScript Bridge         │    │
│  └─────────────────────────────────────────────────────────┘    │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ HTTP/WebSocket (WebUI Bridge)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WebUI Core (C)                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  - Window Management  - Event Routing  - RPC Handling    │    │
│  └─────────────────────────────────────────────────────────┘    │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ FFI (Foreign Function Interface)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Odin Backend                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  DI Container │ Services │ Events │ Comms │ Utils         │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Backend-Frontend Communication

This project supports multiple communication patterns:

### 1. RPC (Remote Procedure Call)

**Pattern**: Request-Response  
**Use Case**: User actions, data fetching, form submissions

Frontend calls backend functions and waits for response:

```typescript
// Frontend (Angular)
const result = await webui.call('user.login', { username: 'john', password: 'pass' });
```

```odin
// Backend (Odin)
handle_login :: proc "c" (e: ^webui.Event) {
    params := webui.event_get_string(e)
    // Process...
    webui.event_return_string(e, `{"token":"abc123"}`)
}
```

**File**: `src/lib/comms/comms.odin` - RPC section

---

### 2. Event Bus (Publish-Subscribe)

**Pattern**: Fire-and-forget, one-to-many  
**Use Case**: Notifications, state sync, system events

```typescript
// Frontend
webui.on('user.joined', (data) => console.log(data));
```

```odin
// Backend
events.emit(&bus, .User_Joined, &event_data)
```

**File**: `src/lib/events/event_bus.odin`

---

### 3. Direct Binding

**Pattern**: Element-to-handler  
**Use Case**: UI interactions, button clicks

```html
<!-- Frontend HTML -->
<button id="myButton">Click Me</button>
```

```odin
// Backend
webui.bind(window, "myButton", handle_click)
```

---

### 4. Channels (Full-Duplex)

**Pattern**: Bidirectional streaming  
**Use Case**: Chat, live updates, real-time apps

```typescript
// Frontend
channel.send('chat', { message: 'Hello!' });
channel.on('chat', (msg) => console.log(msg));
```

```odin
// Backend
channel_send("chat", `{"sender":"user","text":"Hello!"}`)
```

**File**: `src/lib/comms/comms.odin` - Channel section

---

### 5. Message Queue

**Pattern**: Asynchronous processing  
**Use Case**: Background tasks, batch processing

```odin
// Backend
queue_push(Message{ type: "export", payload: data })
// Worker processes async
```

**File**: `src/lib/comms/comms.odin` - Queue section

---

### 6. Binary Protocol

**Pattern**: Compact binary format  
**Use Case**: High-performance data transfer

```odin
// Backend
buffer := binary_encode(msg_type, payload)
```

**File**: `src/lib/comms/comms.odin` - Binary section

---

## Communication Comparison

| Approach | Latency | Complexity | Real-time | Best For |
|----------|---------|------------|-----------|----------|
| RPC | Low | Low | No | User actions |
| Event Bus | Low | Medium | Yes | Notifications |
| Direct Binding | Low | Low | No | UI clicks |
| Channels | Very Low | Medium | Yes | Chat, live updates |
| Message Queue | Medium | High | No | Background tasks |
| Binary | Very Low | Medium | Yes | High-perf data |

---

## Communication Files

```
src/lib/
├── webui_lib/
│   └── webui.odin          # WebUI FFI bindings
├── events/
│   ├── event_bus.odin      # Type-safe event system
│   └── handlers.odin       # Typed event helpers
└── comms/
    └── comms.odin          # Unified communication layer
        ├── RPC System
        ├── Event Bus
        ├── Channels
        ├── Message Queue
        └── Binary Protocol
```

---

## Dependency Injection System

The DI system provides Angular-inspired dependency injection with "errors as values" pattern.

### Core Concepts

```odin
// Provider Types
Provider_Type :: enum {
    Class,      // New instance each time
    Singleton,  // Cached instance
    Factory,    // Custom creation function
    Value,      // Pre-existing value
}

// Create injector
inj, err := di.create_injector()

// Register service
di.register_singleton(&inj, "logger", size_of(Logger), create_logger)

// Resolve service
logger, err := di.inject(inj, Logger)
```

### Files

| File | Description |
|------|-------------|
| `src/lib/di/injector.odin` | Core DI container |

---

## Services

Pre-built services for common functionality:

| Service | Description |
|---------|-------------|
| **Logger** | Logging with levels |
| **User** | User management |
| **Auth** | Authentication & sessions |
| **Cache** | In-memory caching with TTL |
| **Storage** | Persistent JSON storage |
| **Http** | HTTP client |
| **Notification** | System notifications |

### Usage

```odin
// Register service
registry_register_singleton("Cache_Service", cache_service_create)

// Get service
cache_svc, err := registry_get(Cache_Service)

// Use service
err = cache_service_set(cache_svc, "key", value)
```

---

## Event System

Type-safe event bus for decoupled communication:

```odin
// Create event bus
bus, err := events.create_event_bus()

// Subscribe
events.on(&bus, User_Event, .User_Joined, handler)

// Emit
events.emit_typed(&bus, User_Event, .User_Joined, event)

// Process queue
events.process_events(&bus)
```

---

## Quick Start

### 1. Create a Service

```odin
package myapp

import "src/lib/di"
import "src/lib/errors"
import "src/services"

My_Service :: struct {
    logger: ^services.Logger,
}

my_service_create :: proc(inj: ^di.Injector) -> (^My_Service, errors.Error) {
    svc := new(My_Service)
    logger, err := di.inject(inj, services.Logger)
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    svc.logger = logger
    return svc, errors.Error{code: errors.Error_Code.None}
}
```

### 2. Register in Main

```odin
package main

import "src/services"

main :: proc() {
    // Initialize
    err := services.registry_init()
    if err.code != errors.Error_Code.None {
        return
    }

    // Register services
    services.registry_register_singleton("My_Service", my_service_create)

    // Start
    services.registry_start()
    
    // ... app logic ...
    
    // Shutdown
    services.registry_shutdown()
}
```

### 3. Use in Component

```typescript
// Angular
@Component({...})
export class MyComponent {
    async onSubmit() {
        const result = await webui.call('my.action', { data: 'value' });
    }
}
```

---

## Build & Run

```bash
# Build all components
./run.sh build

# Run the application
./run.sh run

# Development mode
./run.sh dev

# Clean
./run.sh clean
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/01_DI_SYSTEM.md](docs/01_DI_SYSTEM.md) | Dependency Injection |
| [docs/02_ERROR_HANDLING_GUIDE.md](docs/02_ERROR_HANDLING_GUIDE.md) | Error handling |
| [docs/04_COMMUNICATION_APPROACHES.md](docs/04_COMMUNICATION_APPROACHES.md) | Communication patterns |
| [docs/05_COMMUNICATION_EXAMPLES.md](docs/05_COMMUNICATION_EXAMPLES.md) | Usage examples |

---

## Version Information

| Component | Version |
|-----------|---------|
| WebUI | 2.5.0-beta.4 |
| CivetWeb | 1.17 |
| Odin | dev-2025-04+ |
