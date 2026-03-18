# Odin WebUI Angular Rspack

A full-stack desktop application framework combining Odin backend, Angular frontend with Rspack bundler, and WebUI bridge for seamless communication.

## Overview

This project demonstrates a modern desktop application architecture featuring:
- High-performance Odin backend with dependency injection
- Angular frontend with Rspack module bundling
- WebUI bridge for bidirectional communication
- Comprehensive service architecture and event system

## Architecture

```
Angular Frontend <-> WebUI Bridge <-> Odin Backend
```

### Core Components

1. **Frontend Layer**
   - Angular application with standalone components
   - Rspack for optimized bundling
   - WebUI JavaScript bridge for backend communication

2. **Communication Bridge**
   - WebUI library providing RPC, event bus, and binding mechanisms
   - Bidirectional data flow between frontend and backend

3. **Backend Layer**
   - Odin programming language for performance and safety
   - Dependency injection container
   - Modular service architecture
   - Type-safe event system

## Key Features

### Communication Patterns

The framework supports multiple communication approaches:

- **RPC (Remote Procedure Call)**: Request-response pattern for user actions and data operations
- **Event Bus**: Publish-subscribe pattern for notifications and state synchronization
- **Direct Binding**: DOM element to backend function binding for UI interactions
- **Channels**: Full-duplex streaming for real-time applications
- **Message Queue**: Asynchronous processing for background tasks
- **Binary Protocol**: Compact binary encoding for high-performance data transfer

### Dependency Injection

Angular-inspired DI system with:
- Token-based service registration
- Multiple provider types (Class, Singleton, Factory, Value)
- Error handling through explicit error returns
- Service lifecycle management

### Service Architecture

Pre-built services for common functionality:
- Logger: Structured logging with multiple levels
- User: Authentication and user management
- Auth: Session handling and security
- Cache: In-memory storage with TTL support
- Storage: Persistent JSON storage
- Http: HTTP client for external API communication
- Notification: System notification handling

## Getting Started

### Prerequisites

- Odin compiler (dev-2025-04+)
- Node.js (v18+)
- Bun.sh (for frontend tooling)
- C compiler (for WebUI bridge)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd starter-odin-webui-angular-rspack
   ```

2. Install frontend dependencies:
   ```bash
   cd frontend
   bun install
   cd ..
   ```

### Development Workflow

```bash
# Build all components
./run.sh build

# Run the application
./run.sh run

# Development mode with file watching
./run.sh dev

# Clean build artifacts
./run.sh clean
```

## Project Structure

```
src/
├── lib/
│   ├── di/              # Dependency injection container
│   ├── errors/          # Error handling system
│   ├── events/          # Type-safe event bus
│   ├── comms/           # Communication layer (RPC, events, channels)
│   ├── webui_lib/       # WebUI FFI bindings
│   └── utils/           # Utility functions
├── services/            # Application services
│   ├── logger.odin
│   ├── user_service.odin
│   ├── auth_service.odin
│   ├── cache_service.odin
│   ├── storage_service.odin
│   ├── http_service.odin
│   └── notification_service.odin
├── models/              # Data models
└── ...                  # Additional modules
```

Frontend:
```
frontend/
├── src/
│   ├── app/             # Application components
│   └── core/            # Core services (WebUI, WinBox, etc.)
└── ...                  # Angular configuration files
```

## Communication Examples

### RPC Call

**Frontend (TypeScript):**
```typescript
const result = await webui.call('user.authenticate', {
  username: 'john.doe',
  password: 'secure123'
});
if (result.success) {
  console.log('Authenticated:', result.data);
}
```

**Backend (Odin):**
```odin
handle_authenticate :: proc "c" (e: ^webui.Event) {
  params := webui.event_get_object(e)
  // Validate credentials...
  if valid {
    webui.event_return_object(e, `{"token":"xyz789","user_id":123}`)
  } else {
    webui.event_return_error(e, "Invalid credentials")
  }
}
```

### Event Subscription

**Frontend (TypeScript):**
```typescript
webui.on('notification.new', (data) => {
  showNotification(data.title, data.message);
});
```

**Backend (Odin):**
```odin
events.emit_typed(&bus, Notification_Event, .Notification_Created, &notification_data)
```

## Build System

The project uses a combination of:
- **Odin compiler** for backend code
- **Bun + Rspack** for frontend bundling
- **Custom build scripts** in `run.sh`

Build targets include:
- Development builds with source maps
- Production optimized builds
- Clean artifact removal
- Test execution

## Documentation

Detailed documentation is available in the `docs/` directory:
- `01_DI_SYSTEM.md`: Dependency injection deep dive
- `02_ERROR_HANDLING_GUIDE.md`: Error handling patterns
- `04_COMMUNICATION_APPROACHES.md`: Communication pattern comparison
- `05_COMMUNICATION_EXAMPLES.md`: Practical usage examples
- `06_BUILD_SYSTEM.md`: Build pipeline details
- `07_WEBUI_INTEGRATION_EVALUATION.md`: WebUI integration specifics
- `08_WEBUI_CIVETWEB_SUMMARY.md`: Web server information

## Version Information

| Component   | Version/Status       |
|-------------|----------------------|
| WebUI       | 2.5.0-beta.4         |
| CivetWeb    | 1.17                 |
| Odin        | dev-2025-04+         |
| Angular     | 21.1.5               |
| Rspack      | 1.7.6                |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.