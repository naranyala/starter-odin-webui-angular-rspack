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
├── run.sh                    # Build and run pipeline script
├── build.sh                  # Legacy build script
├── src/                      # Organized source code
│   ├── core/                 # Core application code
│   ├── lib/                  # Library modules
│   ├── models/               # Data models
│   ├── services/             # Application services
│   └── features/             # Feature modules
├── testing/                  # Test framework
├── tests/                    # Test suites
├── errors/                   # Error handling package
├── di/                       # Dependency Injection system
├── comms/                    # Communication layer
├── utils/                    # Utility modules
├── webui_lib/                # WebUI Odin bindings
├── frontend/                 # Angular application
│   ├── angular.json          # Angular configuration
│   ├── src/                  # Angular source code
│   └── dist/                 # Angular build output
├── examples/                 # Example applications
├── thirdparty/               # Third-party libraries
│   └── webui/                # WebUI library source
├── build/                    # Compiled binaries
├── dist/                     # Distribution package
└── docs/                     # Documentation
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

# Run tests
./run.sh test

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
| `./run.sh test` | Run test suites |
| `./run.sh help` | Show help message |

## Components

### Dependency Injection System

The DI system provides Angular-like dependency injection for Odin backend:

```odin
import di "src/lib/di"

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
import webui "src/lib/webui_lib"

// Create window
window := webui.new_window()

// Bind events
webui.bind(window, "greet", handle_greet)

// Show window
webui.show(window, html_content)

// Wait for events
webui.wait()
```

### Error Handling

Comprehensive error handling system with typed errors and result types:

```odin
import errors "src/lib/errors"

// Create error
err := errors.new(errors.Error_Code.File_Not_Found, "Config missing")

// Return error result
func :: proc() -> errors.Error_Result {
    if something_wrong {
        return errors.result_error(err)
    }
    return errors.result_ok()
}

// Check error
result := func()
if errors.check_result(result) {
    errors.log_error(result.err)
}
```

See `docs/ERROR_HANDLING_GUIDE.md` for complete documentation.

### Utility Modules

Common desktop application utilities:

- **File System**: File/directory operations, path utilities
- **Config**: JSON parsing, configuration management
- **Logger**: Multi-level logging with file rotation
- **Clipboard**: Cross-platform clipboard access
- **Dialogs**: File dialogs, message boxes
- **Window Utils**: Window positioning, multi-monitor support
- **Process**: Process spawning and monitoring
- **System**: System information and environment

See `utils/README.md` for complete documentation.

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
+----------------------------------------------------------+
|                   Angular Frontend                        |
|  +---------------+  +---------------+  +---------------+ |
|  |  Components   |  |  Services     |  |  Comm Service | |
|  +---------------+  +---------------+  +---------------+ |
+----------------------------------------------------------+
                            |
                            | WebUI Bridge
                            | (JavaScript <-> C FFI)
                            v
+----------------------------------------------------------+
|                    Odin Backend                           |
|  +---------------+  +---------------+  +---------------+ |
|  |  Main Handler |  |  DI System    |  |  Comm Layer   | |
|  +---------------+  +---------------+  +---------------+ |
+----------------------------------------------------------+
```

### Dependency Injection Flow

```
+----------------------------------------------------------+
|                   DI Container                            |
|  +----------------------------------------------------+  |
|  |  Providers                                          |  |
|  |  - Logger (Singleton)                               |  |
|  |  - Config (Singleton)                               |  |
|  |  - HttpClient (Factory)                             |  |
|  |  - DataService (Factory)                            |  |
|  +----------------------------------------------------+  |
|  +----------------------------------------------------+  |
|  |  Instances (Cache)                                  |  |
|  +----------------------------------------------------+  |
+----------------------------------------------------------+
```

### Source Code Organization

```
src/
├── core/           # Application entry point and lifecycle
│   └── main.odin   # Main application
│
├── lib/            # Reusable library modules
│   ├── di/         # Dependency Injection
│   ├── comms/      # Communication layer
│   ├── errors/     # Error handling
│   ├── utils/      # Utility modules
│   └── webui_lib/  # WebUI bindings
│
├── models/         # Data models and types
│   └── models.odin # App config, User, State, etc.
│
├── services/       # Application services
│   └── services.odin # App, Config, Logger services
│
└── features/       # Feature modules (application-specific)
```

## Testing

Run the test suite:

```bash
./run.sh test
```

### Test Structure

```
tests/
├── testing/            # Test framework
│   └── testing.odin    # Core testing utilities
│
├── di_tests.odin       # DI system tests (21 cases)
├── errors_tests.odin   # Error handling tests (24 cases)
└── utils_tests.odin    # Utils tests (18 cases)
```

### Writing Tests

```odin
import testing "../testing"

test_example :: proc(tc : ^testing.Test_Case) {
    // Arrange
    value := 42
    
    // Act
    result := value * 2
    
    // Assert
    assert := testing.assert_equal_int(84, result, "Result should be 84")
    if !assert.success {
        tc_fail(tc, assert.message)
    }
}
```

See `tests/README.md` for complete testing documentation.

## Documentation

| Document | Description |
|----------|-------------|
| `docs/DI_SYSTEM.md` | Dependency Injection system guide |
| `docs/COMMUNICATION_APPROACHES.md` | Backend-frontend communication patterns |
| `docs/COMMUNICATION_EXAMPLES.md` | Communication usage examples |
| `docs/BUILD_SYSTEM.md` | Build pipeline documentation |
| `docs/ERROR_HANDLING_GUIDE.md` | Error handling usage guide |
| `docs/ERROR_HANDLING_SUMMARY.md` | Error handling technical summary |
| `docs/WEBUI_INTEGRATION_EVALUATION.md` | WebUI integration evaluation |
| `docs/WEBUI_CIVETWEB_SUMMARY.md` | CivetWeb integration summary |
| `src/README.md` | Source code structure guide |
| `tests/README.md` | Testing framework guide |
| `utils/README.md` | Utilities documentation |

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

### Full Application

```bash
# Build and run main application
./run.sh build
./run.sh run
```

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./run.sh test`
5. Submit a pull request

## Support

For issues and questions:

- Check documentation in `docs/`
- Review examples in `examples/`
- Read source code documentation in `src/README.md`
- Review testing guide in `tests/README.md`
- Open an issue on the repository
