# Dependency Injection System

## Overview

The Dependency Injection (DI) system provides a lightweight, Angular-inspired inversion of control container for Odin applications. It enables loose coupling between components and facilitates testing and maintenance.

## Features

- Token-based dependency registration
- Four provider types: Class, Singleton, Value, Factory
- Parent-child container hierarchy for scoped dependencies
- Thread-safe operations
- Fixed-size storage for predictable memory usage
- Zero external dependencies

## Installation

The DI system is located in the `di/` directory:

```
di/
├── di.odin          # Core DI implementation
└── README.md        # API reference
```

Import in your Odin code:

```odin
import di "./di"
```

## Core Concepts

### Container

The Container is the central registry that manages dependency creation and lifecycle:

```odin
container := di.create_container()
```

### Token

Tokens are string identifiers used to look up dependencies:

```odin
LOGGER_TOKEN : di.Token = "logger"
CONFIG_TOKEN : di.Token = "config"
```

### Provider Types

#### Class Provider

Creates a new instance each time the dependency is resolved:

```odin
di.register_class(&container, TOKEN, size_of(MyType))
```

#### Singleton Provider

Creates one instance that is reused for all requests:

```odin
di.register_singleton(&container, TOKEN, size_of(MyType))
```

#### Value Provider

Returns a pre-created constant value:

```odin
my_value := new(MyType)
di.register_value(&container, TOKEN, my_value)
```

#### Factory Provider

Uses a factory function to create instances with custom logic:

```odin
create_service :: proc(c : ^di.Container) -> rawptr {
    service := new(MyService)
    // Custom initialization
    return service
}

di.register_factory(&container, TOKEN, create_service)
```

## API Reference

### Container Functions

#### create_container

Creates a new root container.

```odin
create_container :: proc() -> Container
```

**Returns:** New Container instance

**Example:**
```odin
container := di.create_container()
```

#### create_child_container

Creates a child container that inherits from a parent.

```odin
create_child_container :: proc(parent : ^Container) -> Container
```

**Parameters:**
- `parent`: Pointer to parent container

**Returns:** New child Container instance

**Example:**
```odin
child := di.create_child_container(&parent_container)
```

#### destroy_container

Cleans up container resources.

```odin
destroy_container :: proc(c : ^Container)
```

**Parameters:**
- `c`: Pointer to container to destroy

**Example:**
```odin
di.destroy_container(&container)
```

### Registration Functions

#### register_class

Registers a class provider that creates new instances.

```odin
register_class :: proc(c : ^Container, token : Token, size : int)
```

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `size`: Size of the type in bytes

**Example:**
```odin
di.register_class(&container, "logger", size_of(Logger))
```

#### register_singleton

Registers a singleton provider that reuses the same instance.

```odin
register_singleton :: proc(c : ^Container, token : Token, size : int)
```

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `size`: Size of the type in bytes

**Example:**
```odin
di.register_singleton(&container, "config", size_of(Config))
```

#### register_value

Registers a constant value provider.

```odin
register_value :: proc(c : ^Container, token : Token, value : rawptr)
```

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `value`: Pointer to the value

**Example:**
```odin
config := new(Config)
config.app_name = "My App"
di.register_value(&container, "config", config)
```

#### register_factory

Registers a factory provider with custom creation logic.

```odin
register_factory :: proc(c : ^Container, token : Token, factory : Factory_Func)
```

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `factory`: Factory function

**Factory Function Signature:**
```odin
Factory_Func :: proc(^Container) -> rawptr
```

**Example:**
```odin
create_logger :: proc(c : ^di.Container) -> rawptr {
    logger := new(Logger)
    logger.prefix = "[App]"
    return logger
}

di.register_factory(&container, "logger", create_logger)
```

### Resolution Functions

#### resolve

Resolves a dependency by token.

```odin
resolve :: proc(c : ^Container, token : Token) -> rawptr
```

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token

**Returns:** Pointer to resolved instance, or nil if not found

**Example:**
```odin
logger := cast(^Logger) di.resolve(&container, "logger")
```

#### has

Checks if a token is registered in the container.

```odin
has :: proc(c : ^Container, token : Token) -> bool
```

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token

**Returns:** true if token is registered

**Example:**
```odin
if di.has(&container, "logger") {
    fmt.println("Logger is registered")
}
```

#### assert_resolved

Panics with error message if dependency is nil.

```odin
assert_resolved :: proc(ptr : rawptr, name : string)
```

**Parameters:**
- `ptr`: Pointer to check
- `name`: Name for error message

**Example:**
```odin
logger := cast(^Logger) di.resolve(&container, "logger")
di.assert_resolved(logger, "Logger")
```

## Usage Examples

### Basic Setup

```odin
package main

import "core:fmt"
import di "./di"

// Service definitions
Logger :: struct {
    prefix : string,
}

Config :: struct {
    app_name : string,
    version : string,
}

// Factory functions
create_logger :: proc(c : ^di.Container) -> rawptr {
    logger := new(Logger)
    logger.prefix = "[App]"
    return logger
}

create_config :: proc(c : ^di.Container) -> rawptr {
    config := new(Config)
    config.app_name = "My Application"
    config.version = "1.0.0"
    return config
}

// Tokens
LOGGER : di.Token = "logger"
CONFIG : di.Token = "config"

main :: proc() {
    // Create container
    container := di.create_container()
    
    // Register services
    di.register_factory(&container, LOGGER, create_logger)
    di.register_factory(&container, CONFIG, create_config)
    
    // Resolve dependencies
    logger := cast(^Logger) di.resolve(&container, LOGGER)
    config := cast(^Config) di.resolve(&container, CONFIG)
    
    // Use services
    fmt.printf("%s Starting %s v%s\n", 
        logger.prefix, config.app_name, config.version)
    
    // Cleanup
    di.destroy_container(&container)
}
```

### Factory with Dependencies

```odin
HttpClient :: struct {
    base_url : string,
}

DataService :: struct {
    http : ^HttpClient,
    logger : ^Logger,
}

// Global container for factory access
global_container : di.Container

create_http :: proc(c : ^di.Container) -> rawptr {
    client := new(HttpClient)
    client.base_url = "http://api.example.com"
    return client
}

create_data_service :: proc(c : ^di.Container) -> rawptr {
    service := new(DataService)
    
    // Resolve dependencies from container
    service.http = cast(^HttpClient) di.resolve(c, "http")
    service.logger = cast(^Logger) di.resolve(c, "logger")
    
    return service
}

main :: proc() {
    container := di.create_container()
    global_container = container
    
    di.register_factory(&container, "http", create_http)
    di.register_factory(&container, "data", create_data_service)
    
    data_service := cast(^DataService) di.resolve(&container, "data")
    // data_service.http and data_service.logger are now injected
}
```

### Hierarchical Containers

```odin
// Root container with shared services
root := di.create_container()
di.register_singleton(&root, "logger", size_of(Logger))
di.register_singleton(&root, "config", size_of(Config))

// Child container with feature-specific overrides
feature := di.create_child_container(&root)

// Override logger for this feature
feature_logger := new(Logger)
feature_logger.prefix = "[Feature]"
di.register_value(&feature, "logger", feature_logger)

// Resolves to feature's logger
feature_log := cast(^Logger) di.resolve(&feature, "logger")

// Resolves to root's config (inherited)
root_config := cast(^Config) di.resolve(&feature, "config")
```

## Best Practices

### 1. Register Dependencies at Startup

Set up your DI container during application initialization:

```odin
main :: proc() {
    container := di.create_container()
    
    // Register all services
    setup_services(&container)
    
    // Run application
    run_app(&container)
    
    // Cleanup
    di.destroy_container(&container)
}
```

### 2. Use Singletons for Stateless Services

Services without mutable state should be singletons:

```odin
// Good: Logger is stateless
di.register_singleton(&container, "logger", size_of(Logger))

// Good: Config is typically read-only
di.register_singleton(&container, "config", size_of(Config))
```

### 3. Use Factories for Services with Dependencies

When a service depends on other services, use a factory:

```odin
create_user_service :: proc(c : ^di.Container) -> rawptr {
    service := new(UserService)
    service.db = cast(^Database) di.resolve(c, "database")
    service.logger = cast(^Logger) di.resolve(c, "logger")
    return service
}
```

### 4. Use Child Containers for Feature Modules

Isolate feature-specific dependencies:

```odin
// Create container for feature module
auth_container := di.create_child_container(&root_container)

// Register auth-specific services
di.register_factory(&auth_container, "auth_service", create_auth_service)

// Auth services can still access root services
```

### 5. Assert Dependencies

Use assert_resolved to catch missing dependencies early:

```odin
db := cast(^Database) di.resolve(&container, "database")
di.assert_resolved(db, "Database")
```

## Limitations

1. **Fixed Capacity**: Maximum 64 providers and 64 instances per container
2. **No Automatic Constructor Injection**: Dependencies must be resolved manually in factories
3. **No Runtime Type Information**: Type sizes must be provided explicitly
4. **No Circular Dependency Detection**: Circular dependencies will cause nil returns

## Comparison with Angular DI

| Feature | Angular | Odin DI |
|---------|---------|---------|
| Token System | InjectionToken | String Token |
| Provider Types | Class, Value, Factory | Class, Value, Factory, Singleton |
| Hierarchical Injectors | Yes | Yes |
| Lazy Loading | Yes | Manual |
| Circular Detection | Yes | No |
| Type Safety | Compile-time | Runtime casting |

## Troubleshooting

### Dependency Returns Nil

Check that:
1. The token matches exactly (case-sensitive)
2. The provider was registered before resolution
3. For factories, the factory function is not nil

### Memory Leaks

Ensure:
1. destroy_container is called when done
2. Singleton instances are properly managed
3. Factory functions do not create orphaned allocations

### Stack Overflow

Check for:
1. Circular dependencies between services
2. Infinite recursion in factory functions

## See Also

- `examples/di_demo.odin` - Complete working example
- `docs/COMMUNICATION_EXAMPLES.md` - Using DI with communication layer
- `main_di.odin` - WebUI application with DI integration
