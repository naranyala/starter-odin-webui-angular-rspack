# Odin WebUI Angular Rspack

A complete full-stack application framework combining Odin backend with Angular frontend through WebUI bridge.

## Project Overview

This project provides a complete development environment for building desktop applications using:

- **Backend**: Odin programming language with WebUI library
- **Frontend**: Angular with Rspack bundler
- **Communication**: WebUI bridge for backend-frontend communication
- **Build System**: Automated build pipeline for all components

## Directory Structure

```
odin-webui-angular-rspack/
├── main.odin                 # Main Odin application entry point
├── main_di.odin              # Odin application with DI system
├── run.sh                    # Build and run pipeline script
├── build.sh                  # Legacy build script
├── webui_lib/
│   └── webui.odin           # WebUI Odin bindings
├── di/
│   ├── di.odin              # Dependency Injection system
│   └── README.md            # DI documentation
├── comms/
│   └── comms.odin           # Communication layer (RPC, Events, Channels)
├── frontend/
│   ├── angular.json         # Angular configuration
│   ├── src/                 # Angular source code
│   └── dist/                # Angular build output
├── examples/
│   ├── di_demo.odin         # DI system demonstration
│   └── minimal/             # Minimal example application
├── thirdparty/
│   └── webui/               # WebUI library source
├── build/                   # Compiled binaries
├── dist/                    # Distribution package
└── docs/                    # Documentation
    ├── COMMUNICATION_APPROACHES.md
    ├── COMMUNICATION_EXAMPLES.md
    ├── DI_SYSTEM.md
    └── BUILD_SYSTEM.md
```

## Quick Start

### Prerequisites

- Odin compiler (dev-2025-04 or later)
- Bun or Node.js for Angular build
- GCC/Clang for WebUI library compilation
- Make build system

### Build and Run

```bash
# Build all components
./run.sh build

# Run the application
./run.sh run

# Development mode (Angular dev server)
./run.sh dev

# Clean build artifacts
./run.sh clean
```

### Build Commands

| Command | Description |
|---------|-------------|
| `./run.sh` or `./run.sh build` | Build all components |
| `./run.sh run` | Run built application |
| `./run.sh dev` | Start Angular dev server |
| `./run.sh clean` | Remove build artifacts |
| `./run.sh test` | Run tests |
| `./run.sh help` | Show help message |

## Components

### Dependency Injection System

The DI system provides Angular-like dependency injection for Odin backend:

```odin
import di "./di"

// Create container
container := di.create_container()

// Register services
di.register_singleton(&container, "logger", size_of(Logger))
di.register_factory(&container, "service", create_service)

// Resolve dependencies
logger := cast(^Logger) di.resolve(&container, "logger")
```

See `docs/DI_SYSTEM.md` for complete documentation.

### Communication Layer

Multiple communication patterns between backend and frontend:

- **RPC**: Request-response pattern for method calls
- **Event Bus**: Publish-subscribe for decoupled communication
- **Channels**: Full-duplex communication
- **Message Queue**: Async message processing

See `docs/COMMUNICATION_APPROACHES.md` for comparison and `docs/COMMUNICATION_EXAMPLES.md` for usage examples.

### WebUI Integration

WebUI library provides the bridge between Odin backend and web frontend:

```odin
import webui "./webui_lib"

// Create window
window := webui.new_window()

// Bind events
webui.bind(window, "greet", handle_greet)

// Show window
webui.show(window, html_content)

// Wait for events
webui.wait()
```

## Build System

The build pipeline (`run.sh`) handles:

1. **WebUI Library**: Compiles static and dynamic libraries
2. **Angular Frontend**: Builds production bundle with Rspack
3. **Odin Backend**: Compiles Odin application with proper linking
4. **Distribution**: Creates deployable package

### Build Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `VERBOSE` | 0 | Enable verbose output |
| `DEBUG` | 0 | Build in debug mode |
| `RELEASE` | 1 | Build in release mode |

### Build Output

```
build/
├── odin-webui-app      # Main application binary
├── di_demo             # DI demonstration
└── build.log           # Build log

dist/
├── odin-webui-app      # Application binary
├── frontend/           # Angular build output
├── lib/                # Shared libraries
└── README.txt          # Distribution readme
```

## Architecture

### Application Flow

```
┌─────────────────────────────────────────────────────────┐
│                   Angular Frontend                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │  Components │  │  Services   │  │  Comm Services  │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
                            │
                            │ WebUI Bridge
                            │ (JavaScript ↔ C FFI)
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Odin Backend                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │   Main      │  │  DI System  │  │  Comm Layer     │ │
│  │  Handler    │  │  Container  │  │  (RPC/Events)   │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Dependency Injection Flow

```
┌─────────────────────────────────────────────────────────┐
│                   DI Container                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Providers                                        │   │
│  │  - Logger (Singleton)                             │   │
│  │  - Config (Singleton)                             │   │
│  │  - HttpClient (Factory)                           │   │
│  │  - DataService (Factory)                          │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Instances (Cache)                                │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Documentation

| Document | Description |
|----------|-------------|
| `docs/DI_SYSTEM.md` | Dependency Injection system guide |
| `docs/COMMUNICATION_APPROACHES.md` | Backend-frontend communication patterns |
| `docs/COMMUNICATION_EXAMPLES.md` | Communication usage examples |
| `docs/BUILD_SYSTEM.md` | Build pipeline documentation |
| `di/README.md` | DI system API reference |

## Examples

### DI Demo

```bash
# Run DI demonstration
./build/di_demo
```

Output:
```
=== Odin DI Demo ===

Registering services...
Resolving services...

Using services:
[DI] App started
App: Odin App v1.0

=== Complete ===
```

### Minimal Example

```bash
# Build and run minimal example
odin build examples/minimal -out:build/minimal -file
./build/minimal
```

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Support

For issues and questions:
- Check documentation in `docs/`
- Review examples in `examples/`
- Open an issue on the repository
