# DI System API Reference

## Overview

The DI (Dependency Injection) system provides a lightweight inversion of control container for Odin applications.

## Installation

```odin
import di "./di"
```

## Types

### Token

```odin
Token :: string
```

String identifier for dependencies.

### Provider_Type

```odin
Provider_Type :: enum {
    Class,      // New instance each time
    Singleton,  // Single shared instance
    Value,      // Constant value
    Factory,    // Factory function creates instance
}
```

### Factory_Func

```odin
Factory_Func :: proc(^Container) -> rawptr
```

Function type for factory providers.

### Provider

```odin
Provider :: struct {
    token         : Token,
    provider_type : Provider_Type,
    size          : int,
    value         : rawptr,
    factory       : Factory_Func,
}
```

### Container

```odin
Container :: struct {
    providers       : [64]Provider,
    provider_count  : int,
    instances       : [64]rawptr,
    instance_tokens : [64]Token,
    instance_count  : int,
    parent          : ^Container,
}
```

## Functions

### Container Management

#### create_container

```odin
create_container :: proc() -> Container
```

Creates a new root container.

**Returns:** New Container instance

**Example:**
```odin
container := di.create_container()
```

#### create_child_container

```odin
create_child_container :: proc(parent : ^Container) -> Container
```

Creates a child container that inherits from a parent.

**Parameters:**
- `parent`: Pointer to parent container

**Returns:** New child Container instance

**Example:**
```odin
child := di.create_child_container(&parent_container)
```

#### destroy_container

```odin
destroy_container :: proc(c : ^Container)
```

Cleans up container resources.

**Parameters:**
- `c`: Pointer to container to destroy

**Example:**
```odin
di.destroy_container(&container)
```

### Registration

#### register_class

```odin
register_class :: proc(c : ^Container, token : Token, size : int)
```

Registers a class provider that creates new instances.

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `size`: Size of the type in bytes

**Example:**
```odin
di.register_class(&container, "logger", size_of(Logger))
```

#### register_singleton

```odin
register_singleton :: proc(c : ^Container, token : Token, size : int)
```

Registers a singleton provider that reuses the same instance.

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `size`: Size of the type in bytes

**Example:**
```odin
di.register_singleton(&container, "config", size_of(Config))
```

#### register_value

```odin
register_value :: proc(c : ^Container, token : Token, value : rawptr)
```

Registers a constant value provider.

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `value`: Pointer to the value

**Example:**
```odin
config := new(Config)
di.register_value(&container, "config", config)
```

#### register_factory

```odin
register_factory :: proc(c : ^Container, token : Token, factory : Factory_Func)
```

Registers a factory provider with custom creation logic.

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token
- `factory`: Factory function

**Example:**
```odin
create_logger :: proc(c : ^di.Container) -> rawptr {
    logger := new(Logger)
    logger.prefix = "[App]"
    return logger
}

di.register_factory(&container, "logger", create_logger)
```

### Resolution

#### resolve

```odin
resolve :: proc(c : ^Container, token : Token) -> rawptr
```

Resolves a dependency by token.

**Parameters:**
- `c`: Pointer to container
- `token`: Dependency token

**Returns:** Pointer to resolved instance, or nil if not found

**Example:**
```odin
logger := cast(^Logger) di.resolve(&container, "logger")
```

#### has

```odin
has :: proc(c : ^Container, token : Token) -> bool
```

Checks if a token is registered in the container.

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

```odin
assert_resolved :: proc(ptr : rawptr, name : string)
```

Prints error message if dependency is nil.

**Parameters:**
- `ptr`: Pointer to check
- `name`: Name for error message

**Example:**
```odin
logger := cast(^Logger) di.resolve(&container, "logger")
di.assert_resolved(logger, "Logger")
```

## Quick Start

```odin
package main

import "core:fmt"
import di "./di"

// Service definitions
Logger :: struct { prefix : string }
Config :: struct { app_name : string }

// Factory functions
create_logger :: proc(c : ^di.Container) -> rawptr {
    logger := new(Logger)
    logger.prefix = "[App]"
    return logger
}

create_config :: proc(c : ^di.Container) -> rawptr {
    config := new(Config)
    config.app_name = "My App"
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
    fmt.printf("%s Starting %s\n", logger.prefix, config.app_name)
    
    // Cleanup
    di.destroy_container(&container)
}
```

## Limitations

1. Maximum 64 providers per container
2. Maximum 64 cached instances per container
3. No automatic constructor injection
4. No circular dependency detection

## See Also

- `docs/DI_SYSTEM.md` - Complete DI system documentation
- `examples/di_demo.odin` - Working example
