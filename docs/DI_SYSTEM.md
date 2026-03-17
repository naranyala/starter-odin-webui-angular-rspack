# Dependency Injection System

## Overview

The Dependency Injection (DI) system provides a lightweight, Angular-inspired inversion of control container for Odin applications. It enables loose coupling between components and facilitates testing and maintenance.

## Features

- Token-based dependency registration
- Four provider types: Class, Singleton, Value, Factory
- Parent-child container hierarchy for scoped dependencies
- Thread-safe operations
- Fixed-size storage for predictable memory usage (64 providers/instances max)
- Zero external dependencies
- Error-returning functions for safe operations

## Installation

The DI system is located in the `di/` directory:

```
di/
├── di.odin          # Core DI implementation
└── README.md        # API reference
```

Import in your Odin code:

```odin
import di "src/lib/di"
```

## Core Concepts

### Container

The Container is the central registry that manages dependency creation and lifecycle:

```odin
container := di.create_container()
defer di.destroy_container(&container)
```

### Token

Tokens are string identifiers used to look up dependencies:

```odin
LOGGER_TOKEN : di.Token = "logger"
CONFIG_TOKEN : di.Token = "config"
SERVICE_TOKEN : di.Token = "my_service"
```

### Provider

Providers define how dependencies are created. Four types are available:

1. **Class**: Transient - new instance each resolution
2. **Singleton**: Single instance cached for container lifetime
3. **Value**: Pre-created instance
4. **Factory**: Function that creates instances

## API Reference

### Container Management

```odin
// Create root container
create_container :: proc() -> Container

// Create child container (inherits from parent)
create_child_container :: proc(parent : ^Container) -> Container

// Destroy container and cleanup
destroy_container :: proc(c : ^Container)

// Get container information
get_container_info :: proc(c : ^Container) -> Container_Info

// Validate container configuration
validate_container :: proc(c : ^Container) -> DI_Error_Result
```

### Registration

```odin
// Register as transient (new instance each time)
register_class :: proc(c : ^Container, token : Token, size : int) -> DI_Error_Result

// Register as singleton (one instance, cached)
register_singleton :: proc(c : ^Container, token : Token, size : int) -> DI_Error_Result

// Register pre-created value
register_value :: proc(c : ^Container, token : Token, value : rawptr) -> DI_Error_Result

// Register factory function
register_factory :: proc(c : ^Container, token : Token, factory : Factory_Func) -> DI_Error_Result
```

### Resolution

```odin
// Resolve dependency (returns rawptr)
resolve :: proc(c : ^Container, token : Token) -> rawptr

// Resolve with error handling
resolve_with_error :: proc(c : ^Container, token : Token) -> (rawptr, DI_Error_Result)

// Resolve with type information
resolve_typed :: proc(c : ^Container, token : Token, type_name : string) -> (rawptr, DI_Error_Result)

// Check if token is registered
has :: proc(c : ^Container, token : Token) -> bool
```

### Error Handling

```odin
// Check if registration succeeded
err := di.register_singleton(&container, "token", size_of(MyType))
if err.has_error {
    fmt.printf("Registration failed: %s\n", err.error.message)
    fmt.printf("Details: %s\n", err.error.details)
}

// Check if resolution succeeded
instance, err := di.resolve_with_error(&container, "token")
if err.has_error {
    fmt.printf("Resolution failed: %s\n", err.error.message)
}
```

## Usage Examples

### Basic Singleton

```odin
package main

import "core:fmt"
import di "src/lib/di"

Logger :: struct {
    prefix : string,
}

create_logger :: proc(c : ^di.Container) -> rawptr {
    logger := new(Logger)
    logger.prefix = "[APP]"
    return logger
}

main :: proc() {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    // Register
    di.register_factory(&container, "logger", create_logger)
    
    // Resolve
    logger := cast(^Logger) di.resolve(&container, "logger")
    
    fmt.printf("%s Application started\n", logger.prefix)
}
```

### Multiple Dependencies

```odin
package main

import "core:fmt"
import di "src/lib/di"

Config :: struct {
    app_name : string,
    version : string,
}

Database :: struct {
    connection_string : string,
    config : ^Config,
}

Service :: struct {
    name : string,
    db : ^Database,
}

create_config :: proc(c : ^di.Container) -> rawptr {
    config := new(Config)
    config.app_name = "MyApp"
    config.version = "1.0.0"
    return config
}

create_database :: proc(c : ^di.Container) -> rawptr {
    db := new(Database)
    db.connection_string = "localhost:5432"
    db.config = cast(^Config) di.resolve(c, "config")
    return db
}

create_service :: proc(c : ^di.Container) -> rawptr {
    svc := new(Service)
    svc.name = "MyService"
    svc.db = cast(^Database) di.resolve(c, "database")
    return svc
}

main :: proc() {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    // Register in dependency order
    di.register_factory(&container, "config", create_config)
    di.register_factory(&container, "database", create_database)
    di.register_factory(&container, "service", create_service)
    
    // Resolve root service (dependencies resolved automatically)
    service := cast(^Service) di.resolve(&container, "service")
    
    fmt.printf("Service: %s\n", service.name)
    fmt.printf("Database: %s\n", service.db.connection_string)
    fmt.printf("App: %s v%s\n", service.db.config.app_name, service.db.config.version)
}
```

### Child Containers

```odin
package main

import "core:fmt"
import di "src/lib/di"

main :: proc() {
    // Parent container with shared services
    parent := di.create_container()
    defer di.destroy_container(&parent)
    
    di.register_singleton(&parent, "logger", size_of(Logger))
    di.register_value(&parent, "config", config_instance)
    
    // Child container with scoped services
    child := di.create_child_container(&parent)
    defer di.destroy_container(&child)
    
    di.register_factory(&child, "request_handler", create_handler)
    
    // Child can resolve parent's services
    logger := cast(^Logger) di.resolve(&child, "logger")  // From parent
    handler := cast(^Handler) di.resolve(&child, "request_handler")  // From child
}
```

### Error Handling

```odin
package main

import "core:fmt"
import di "src/lib/di"

main :: proc() {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    // Check registration errors
    err := di.register_singleton(&container, "service", 0)  // Invalid size
    if err.has_error {
        fmt.printf("Registration failed: %s\n", err.error.message)
        fmt.Printf("Details: %s\n", err.error.details)
        return
    }
    
    // Check resolution errors
    instance, err := di.resolve_with_error(&container, "nonexistent")
    if err.has_error {
        fmt.Printf("Resolution failed: %s\n", err.error.message)
        return
    }
    
    // Use instance
    service := cast(^Service) instance
    service.do_something()
}
```

## Container Info

Get statistics about container usage:

```odin
info := di.get_container_info(&container)

fmt.Printf("Providers: %d/%d (%.1f%%)\n", 
    info.provider_count, 
    info.max_providers, 
    info.provider_usage_percent)

fmt.Printf("Instances: %d/%d (%.1f%%)\n",
    info.instance_count,
    info.max_instances,
    info.instance_usage_percent)

fmt.Printf("Has Parent: %v\n", info.has_parent)
```

## Error Codes

| Code | Value | Description |
|------|-------|-------------|
| None | 0 | No error |
| Container_Full | 1001 | Provider or instance limit reached |
| Not_Registered | 1002 | Token not found in container |
| Resolution_Failed | 1003 | Factory returned nil or other resolution error |
| Circular_Dependency | 1004 | Circular dependency detected |
| Invalid_Factory | 1005 | Nil factory or invalid size |
| Instance_Full | 1006 | Instance cache is full |

## Best Practices

### 1. Register in Dependency Order

Register dependencies before dependents:

```odin
// Good
di.register_factory(&container, "config", create_config)
di.register_factory(&container, "database", create_database)  // Needs config
di.register_factory(&container, "service", create_service)    // Needs database

// Bad - may fail if dependencies not resolved
di.register_factory(&container, "service", create_service)
di.register_factory(&container, "database", create_database)
di.register_factory(&container, "config", create_config)
```

### 2. Use defer for Cleanup

```odin
container := di.create_container()
defer di.destroy_container(&container)

// Container automatically cleaned up when function returns
```

### 3. Check Errors in Production

```odin
// Production code - always check errors
err := di.register_singleton(&container, "service", size_of(Service))
if err.has_error {
    log_error("Failed to register service", err.error.message)
    return err
}
```

### 4. Use Child Containers for Scoping

```odin
// Request-scoped services
handle_request :: proc() {
    request_container := di.create_child_container(&global_container)
    defer di.destroy_container(&request_container)
    
    di.register_factory(&request_container, "request", create_request)
    
    // Request services cleaned up automatically
}
```

### 5. Prefer Factory for Complex Dependencies

```odin
// Good - factory can handle complex initialization
create_database :: proc(c : ^di.Container) -> rawptr {
    db := new(Database)
    db.config = cast(^Config) di.resolve(c, "config")
    db.logger = cast(^Logger) di.resolve(c, "logger")
    
    if !db.connect() {
        return nil  // Signal failure
    }
    
    return db
}

// Register
di.register_factory(&container, "database", create_database)
```

## Limitations

- Maximum 64 providers per container
- Maximum 64 cached instances per container
- No automatic circular dependency detection
- No automatic lifecycle management beyond singleton caching
- Factory functions must return rawptr

## Performance Considerations

- Resolution is O(n) where n is number of providers
- Singleton caching avoids repeated factory calls
- Child containers add minimal overhead
- Fixed-size arrays avoid dynamic allocation

## Testing

```odin
import testing "src/testing"
import di "src/lib/di"

test_di_registration :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    err := di.register_singleton(&container, "test", size_of(TestType))
    
    if err.has_error {
        tc_fail(tc, err.error.message)
    }
    
    has := di.has(&container, "test")
    if !has {
        tc_fail(tc, "Token should be registered")
    }
}
```

## Troubleshooting

### Resolution Returns Nil

Check:
1. Token is registered correctly
2. Factory function is not nil
3. Factory function returns non-nil value
4. Size parameter is correct for class/singleton

### Registration Fails

Check:
1. Container is not nil
2. Token is not already registered
3. Size is greater than zero
4. Container has not reached capacity (64)

### Circular Dependency

Restructure dependencies:
```odin
// Bad: A needs B, B needs A
// Good: Extract shared interface or use setter injection
```

## See Also

- `di/README.md` - API reference
- `examples/di_demo.odin` - Working example
- `docs/ERROR_HANDLING_GUIDE.md` - Error handling patterns
- `tests/di_tests.odin` - Test suite
