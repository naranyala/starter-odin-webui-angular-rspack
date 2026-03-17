# Source Code Structure

This document describes the organized source code structure for the Odin WebUI Angular application.

## Directory Structure

```
src/
├── core/               # Core application code
│   ├── main.odin       # Main entry point
│   └── di_demo.odin    # DI demonstration
│
├── lib/                # Library modules
│   ├── di/             # Dependency Injection system
│   │   ├── di.odin     # DI implementation
│   │   └── README.md   # DI documentation
│   │
│   ├── comms/          # Communication layer
│   │   └── comms.odin  # RPC, Events, Channels
│   │
│   ├── errors/         # Error handling
│   │   └── errors.odin # Error types and utilities
│   │
│   ├── utils/          # Utility modules
│   │   ├── file_system.odin   # File operations
│   │   ├── config.odin        # Configuration management
│   │   ├── logger.odin        # Logging system
│   │   ├── clipboard.odin     # Clipboard access
│   │   ├── dialogs.odin       # System dialogs
│   │   ├── window_utils.odin  # Window management
│   │   ├── process.odin       # Process management
│   │   ├── system.odin        # System information
│   │   └── utils.odin         # Main utils module
│   │
│   └── webui_lib/      # WebUI library bindings
│       └── webui.odin  # WebUI Odin bindings
│
├── models/             # Data models and types
│   └── models.odin     # Application data structures
│
├── services/           # Application services
│   └── services.odin   # Service layer implementation
│
└── features/           # Feature modules (application-specific)
    └── .gitkeep        # Placeholder for feature modules
```

## Module Descriptions

### `src/core/` - Core Application

Contains the main application entry point and core initialization logic.

**Files:**
- `main.odin` - Application entry point, lifecycle management
- `di_demo.odin` - Dependency injection demonstration

**Usage:**
```odin
// This is where the application starts
// Contains main() procedure
```

### `src/lib/` - Library Modules

Reusable library code that can be used across applications.

#### `di/` - Dependency Injection

Angular-style dependency injection for Odin.

**Features:**
- Singleton, Factory, Class, Value providers
- Child containers for scoped dependencies
- Type-safe resolution

**Example:**
```odin
import di "src/lib/di"

container := di.create_container()
di.register_singleton(&container, "logger", size_of(Logger))
logger := cast(^Logger) di.resolve(&container, "logger")
```

#### `comms/` - Communication Layer

Backend-frontend communication patterns.

**Features:**
- RPC (Request-Response)
- Event Bus (Publish-Subscribe)
- Channels (Full-Duplex)
- Message Queue

**Example:**
```odin
import comms "src/lib/comms"

comms.comms_init()
comms.comms_rpc("methodName", handler_proc)
comms.comms_on("eventName", event_handler)
```

#### `errors/` - Error Handling

Comprehensive error handling system.

**Features:**
- Error codes (20+ predefined)
- Error severity levels
- Error result types
- Error collection

**Example:**
```odin
import errors "src/lib/errors"

result := some_operation()
if errors.check_result(result) {
    errors.log_error(result.err)
}
```

#### `utils/` - Utility Modules

Common desktop application utilities.

**Modules:**
- `file_system` - File/directory operations
- `config` - JSON parsing, configuration management
- `logger` - Multi-level logging
- `clipboard` - Cross-platform clipboard
- `dialogs` - File/message dialogs
- `window_utils` - Window positioning
- `process` - Process management
- `system` - System information

**Example:**
```odin
import utils "src/lib/utils"

// File operations
content, ok := utils.file_read("config.json")

// Logging
utils.log_info("Application started")

// System info
fmt.println(utils.system_summary())
```

#### `webui_lib/` - WebUI Bindings

Odin bindings for the WebUI library.

**Features:**
- Window management
- Event binding
- JavaScript execution
- Data exchange

**Example:**
```odin
import webui "src/lib/webui_lib"

window := webui.new_window()
webui.bind(window, "eventName", handler_proc)
webui.show(window, html_content)
webui.wait()
```

### `src/models/` - Data Models

Application data structures and types.

**Types:**
- `App_Config` - Application configuration
- `User` - User model
- `App_State` - Application state
- `Result` - Operation result
- `Status` - Status with code/message
- `App_Event` - Application events

**Example:**
```odin
import models "src/models"

config := models.default_config()
state := models.App_State{
    is_initialized = true,
    config = config,
}
```

### `src/services/` - Application Services

Service layer for application business logic.

**Services:**
- `App_Service` - Main application service
- `Config_Service` - Configuration management
- `Logger_Service` - Logging service
- `Service_Manager` - Service lifecycle management

**Example:**
```odin
import services "src/services"

mgr := services.service_manager_create()
app_svc := services.app_service_create()
services.app_service_init(app_svc, container)
services.service_manager_register(mgr, app_svc)
```

### `src/features/` - Feature Modules

Application-specific feature modules (to be implemented).

**Purpose:**
- Organize feature-specific code
- Separate business logic from core
- Enable modular development

## Import Paths

When importing modules in your code:

```odin
// Core modules (relative to src/core)
import "../lib/di"
import "../lib/comms"
import "../models"
import "../services"

// Or from outside src directory
import "src/lib/di"
import "src/models"
import "src/services"
```

## Build Configuration

### Building from src directory

```bash
# Build main application
odin build src/core -out:build/app -file

# Build with specific entry point
odin build src/core/main.odin -out:build/app
```

### Using odin build with package path

```bash
# Build entire src as package
odin build src -out:build/app
```

## Best Practices

### 1. Module Organization

- Put reusable code in `lib/`
- Put application logic in `services/`
- Put data types in `models/`
- Put feature-specific code in `features/`

### 2. Import Conventions

```odin
// Use relative imports within src
import "../lib/di"
import "../models"

// Use absolute imports from outside
import "src/lib/di"
```

### 3. Service Pattern

```odin
// Create service
svc := my_service_create()

// Initialize
my_service_init(svc, dependencies)

// Use
my_service_do_something(svc)

// Cleanup
my_service_destroy(svc)
```

### 4. Error Handling

```odin
import errors "src/lib/errors"

// Check errors
err := some_operation()
if errors.check(err) {
    errors.log_error(err)
    return errors.result_error(err)
}

// Return results
return errors.result_ok()
```

## Migration Guide

### From Old Structure

| Old Location | New Location |
|-------------|--------------|
| `main.odin` | `src/core/main.odin` |
| `di/di.odin` | `src/lib/di/di.odin` |
| `comms/comms.odin` | `src/lib/comms/comms.odin` |
| `utils/*.odin` | `src/lib/utils/*.odin` |
| `webui_lib/webui.odin` | `src/lib/webui_lib/webui.odin` |
| `errors/errors.odin` | `src/lib/errors/errors.odin` |

### Update Import Paths

**Before:**
```odin
import di "./di"
import comms "./comms"
import utils "./utils"
```

**After:**
```odin
import di "src/lib/di"
import comms "src/lib/comms"
import utils "src/lib/utils"
```

## Future Enhancements

### Planned Additions

1. **More Services**
   - `Auth_Service` - Authentication
   - `Data_Service` - Data access layer
   - `Http_Service` - HTTP client

2. **More Features**
   - `user_management/` - User management feature
   - `settings/` - Settings feature
   - `dashboard/` - Dashboard feature

3. **More Models**
   - Domain-specific models
   - DTOs for API communication
   - Validation schemas

## Support

For questions about the structure:
- Check this README
- Review example code in `src/core/di_demo.odin`
- See documentation in `docs/`
