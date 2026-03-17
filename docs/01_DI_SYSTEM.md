# Dependency Injection System

## Overview

The Dependency Injection (DI) system provides an Angular-inspired inversion of control container for Odin applications with "errors as values" pattern.

## File Structure

```
src/lib/di/
├── injector.odin    # Main DI container implementation
└── di.odin         # Simplified version (legacy)
```

## Features

- Token-based dependency registration
- Four provider types: Class, Singleton, Factory, Value
- Parent-child injector hierarchy
- Errors as values throughout API
- Zero external dependencies

## Core Types

```odin
Provider_Type :: enum {
    Class,      // New instance each time
    Singleton,  // Cached instance
    Factory,    // Custom creation function
    Value,      // Pre-existing value
}

Token :: string

Factory_Proc :: proc(injector: ^Injector) -> (rawptr, Error)

Provider :: struct {
    token:        Token,
    provider_type: Provider_Type,
    size:         int,
    value:        rawptr,
    factory:      Factory_Proc,
}

Injector :: struct {
    providers: hash_map.HashMap(Token, Provider),
    instances: hash_map.HashMap(Token, rawptr),
    parent:    ^Injector,
}
```

## API Reference

### Injector Management

```odin
// Create a new injector
create_injector :: proc() -> (Injector, Error)

// Destroy injector and cleanup
destroy_injector :: proc(inj: ^Injector) -> Error
```

### Registration

```odin
// Register a class (new instance each time)
register_class :: proc(inj: ^Injector, token: Token, size: int) -> Error

// Register a singleton
register_singleton :: proc(inj: ^Injector, token: Token, size: int, factory: Factory_Proc) -> Error

// Register a pre-existing value
register_value :: proc(inj: ^Injector, token: Token, value: rawptr) -> Error

// Register a factory function
register_factory :: proc(inj: ^Injector, token: Token, factory: Factory_Proc) -> Error
```

### Resolution

```odin
// Resolve a service by token
resolve :: proc(inj: ^Injector, token: Token) -> (rawptr, Error)

// Check if token is registered
has :: proc(inj: ^Injector, token: Token) -> (bool, Error)

// Type-safe injection
inject :: proc(inj: ^Injector, $T: typeid) -> (^T, Error)

// Inject or create if not exists
inject_or_create :: proc(inj: ^Injector, $T: typeid) -> (^T, Error)

// Inject multiple dependencies
inject_many :: proc(inj: ^Injector, $T: typeid, $U: typeid) -> (^T, ^U, Error)
inject_three :: proc(inj: ^Injector, $T: typeid, $U: typeid, $V: typeid) -> (^T, ^U, ^V, Error)
```

## Usage Examples

### Basic Service

```odin
package main

import "core:fmt"
import "src/lib/di"
import "src/lib/errors"

Logger :: struct {
    prefix: string,
}

create_logger :: proc(inj: ^di.Injector) -> (rawptr, errors.Error) {
    logger := new(Logger)
    logger.prefix = "[APP]"
    return logger, errors.Error{code: errors.Error_Code.None}
}

main :: proc() {
    inj, err := di.create_injector()
    if err.code != errors.Error_Code.None {
        return
    }
    defer di.destroy_injector(&inj)

    // Register
    di.register_singleton(&inj, "logger", size_of(Logger), create_logger)

    // Resolve
    logger, err := di.resolve(&inj, "logger")
    if err.code != errors.Error_Code.None {
        return
    }

    casted := cast(^Logger)logger
    fmt.printf("%s Application started\n", casted.prefix)
}
```

### Multiple Dependencies

```odin
Config :: struct {
    app_name: string,
    version:  string,
}

Database :: struct {
    connection_string: string,
}

Service :: struct {
    name: string,
    db:   ^Database,
}

create_config :: proc(inj: ^di.Injector) -> (rawptr, errors.Error) {
    config := new(Config)
    config.app_name = "MyApp"
    config.version = "1.0.0"
    return config, errors.Error{code: errors.Error_Code.None}
}

create_database :: proc(inj: ^di.Injector) -> (rawptr, errors.Error) {
    db := new(Database)
    db.connection_string = "localhost:5432"
    return db, errors.Error{code: errors.Error_Code.None}
}

create_service :: proc(inj: ^di.Injector) -> (rawptr, errors.Error) {
    svc := new(Service)
    svc.name = "MyService"

    db, err := di.resolve(inj, "database")
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    svc.db = cast(^Database)db

    return svc, errors.Error{code: errors.Error_Code.None}
}
```

### Using Services with DI

Services follow the factory pattern:

```odin
// In services/user_service.odin
user_service_create :: proc(inj: ^di.Injector) -> (^User_Service, errors.Error) {
    service := new(User_Service)

    // Inject dependencies
    logger, err := di.inject(inj, Logger)
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    service.logger = logger

    event_bus, err := di.inject(inj, events.Event_Bus)
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    service.event_bus = event_bus

    return service, errors.Error{code: errors.Error_Code.None}
}
```

## Best Practices

### 1. Register in Dependency Order

```odin
// Good - register base dependencies first
di.register_factory(&inj, "config", create_config)
di.register_factory(&inj, "database", create_database)
di.register_factory(&inj, "service", create_service)
```

### 2. Always Check Errors

```odin
// Good - check errors
inj, err := di.create_injector()
if err.code != errors.Error_Code.None {
    return err
}
```

### 3. Use Type-Safe Injection

```odin
// Good - use typed injection
logger, err := di.inject(inj, Logger)
if err.code != errors.Error_Code.None {
    return err
}
```

## Available Services

| Service | Factory | Description |
|---------|---------|-------------|
| Logger | `logger_create()` | Logging service |
| User | `user_service_create()` | User management |
| Auth | `auth_service_create()` | Authentication & sessions |
| Cache | `cache_service_create()` | In-memory caching |
| Storage | `storage_service_create()` | Persistent storage |
| Http | `http_service_create()` | HTTP client |
| Notification | `notification_service_create()` | Notifications |

## See Also

- [README.md](../README.md) - Main documentation
- [02_ERROR_HANDLING_GUIDE.md](02_ERROR_HANDLING_GUIDE.md) - Error handling
- [src/services/](src/services/) - Service implementations
