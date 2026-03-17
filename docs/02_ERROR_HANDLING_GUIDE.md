# Error Handling Guide

## Overview

The project uses "errors as values" pattern throughout the codebase. All functions that can fail return an Error value alongside the result.

## File Structure

```
src/lib/errors/
└── errors.odin    # Core error handling package
```

## Error Codes

```odin
Error_Code :: enum int {
    None = 0,
    Unknown,
    Internal,
    Invalid_State,
    Timeout,
    Not_Found,
    Already_Exists,
    Invalid_Parameter,
    IO_Error,
    File_Error,
    Network_Error,
    Parse_Error,
    Validation_Error,
    Not_Implemented,
    DI_Error,
    Comms_Error,
    RPC_Error,
    Auth_Error,
    Cache_Error,
    Storage_Error,
}
```

## Creating Errors

```odin
// Simple error
err := errors.new(errors.Error_Code.Invalid_Parameter, "Invalid username")

// Error with details
err := errors.new_detailed(
    errors.Error_Code.File_Read_Error,
    "Failed to read config",
    "Permission denied: /etc/app/config.json")
```

## Convenience Functions

```odin
// General errors
err := errors.err_unknown("Something went wrong")
err := errors.err_timeout("Operation took too long")

// Parameter errors
err := errors.err_invalid_param("Username cannot be empty")
err := errors.err_not_found("User not found")

// I/O errors
err := errors.err_io("Read failed")
err := errors.err_file("File not found")

// Domain-specific errors
err := errors.err_auth("Invalid credentials")
err := errors.err_cache("Cache entry expired")
err := errors.err_storage("Storage save failed")
```

## Checking Errors

```odin
// Check if error exists
if err.code != errors.Error_Code.None {
    // handle error
}

// Or use helper
if errors.check(err) {
    // handle error
}

if errors.is_ok(err) {
    // success
}
```

## Pattern: Function with Error Return

```odin
// Function signature
my_function :: proc() -> (T, errors.Error) {
    if something_wrong {
        return zero(T), errors.err_invalid_state("...")
    }
    return value, errors.Error{code: errors.Error_Code.None}
}

// Usage
result, err := my_function()
if err.code != errors.Error_Code.None {
    fmt.printf("Error: %s\n", err.message)
    return
}
// Use result
```

## Pattern: Service Methods

```odin
// Service method
cache_service_get :: proc(svc: ^Cache_Service, key: string) -> (rawptr, errors.Error) {
    if key == "" {
        return nil, errors.err_invalid_param("Cache key cannot be empty")
    }

    if entry, ok := hash_map.get(&svc.cache, key); ok {
        if time.now() < entry.expires_at {
            return entry.value, errors.Error{code: errors.Error_Code.None}
        }
    }

    return nil, errors.err_not_found(fmt.Sprintf("Cache key '%s' not found", key))
}

// Usage
value, err := cache_service_get(svc, "my_key")
if err.code != errors.Error_Code.None {
    // handle - key not found or expired
}
```

## Error Logging

```odin
// Log error
errors.log_error(err)

// Log warning
errors.log_warning(err)

// Get error string
str := errors.error_string(&err)
```

## Best Practices

### 1. Always Check Errors

```odin
// Bad - ignore errors
di.register_singleton(&inj, "logger", size_of(Logger))

// Good - check errors
err := di.register_singleton(&inj, "logger", size_of(Logger))
if err.code != errors.Error_Code.None {
    return err
}
```

### 2. Provide Context

```odin
// Bad - generic error
return errors.err_io("Read failed")

// Good - specific context
return errors.err_file(fmt.Sprintf("Failed to read config: %s", path))
```

### 3. Validate Input

```odin
my_operation :: proc(svc: ^Service, key: string) -> errors.Error {
    if key == "" {
        return errors.err_invalid_param("Key cannot be empty")
    }
    // proceed with operation
}
```

### 4. Propagate with Context

```odin
// Inner operation fails
err := load_config()
if err.code != errors.Error_Code.None {
    // Wrap with context
    return errors.new_detailed(
        err.code,
        "Application startup failed",
        err.message)
}
```

## Error Handling in Services

All services follow this pattern:

```odin
service_create :: proc(inj: ^di.Injector) -> (^Service, errors.Error) {
    svc := new(Service)

    // Inject dependencies - check each error
    logger, err := di.inject(inj, Logger)
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    svc.logger = logger

    event_bus, err := di.inject(inj, events.Event_Bus)
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    svc.event_bus = event_bus

    return svc, errors.Error{code: errors.Error_Code.None}
}
```

## See Also

- [01_DI_SYSTEM.md](01_DI_SYSTEM.md) - DI system
- [03_ERROR_HANDLING_SUMMARY.md](03_ERROR_HANDLING_SUMMARY.md) - Technical summary
- [src/lib/errors/errors.odin](../src/lib/errors/errors.odin) - Implementation
