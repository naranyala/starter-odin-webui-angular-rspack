# Error Handling Summary

## Overview

This document summarizes the "errors as values" pattern implementation across the codebase.

## File Structure

```
src/lib/errors/
└── errors.odin    # Core error handling package (~120 lines)
```

## Error Type

```odin
Error :: struct {
    code:     Error_Code,
    message:  string,
    details:  string,
    severity: Error_Severity,
    timestamp: time.Time,
}
```

## Error Code Categories

| Range | Category |
|-------|----------|
| 0-99 | General (None, Unknown, Internal, Timeout) |
| 100-199 | Parameter (Invalid_Parameter, Null_Argument) |
| 200-299 | Resource (Not_Found, Already_Exists) |
| 300-399 | I/O (IO_Error, File_Error, Network_Error) |
| 400-499 | Parse (Parse_Error) |
| 500-599 | Validation (Validation_Error) |
| 900-999 | DI (DI_Error) |
| 1000+ | Domain (Auth_Error, Cache_Error, Storage_Error) |

## Key Functions

### Error Creation

```odin
new(code, message) -> Error
new_detailed(code, message, details) -> Error
err_none() -> Error
err_unknown(message) -> Error
err_not_found(message) -> Error
err_invalid_param(message) -> Error
err_io(message) -> Error
// ... and more
```

### Error Checking

```odin
check(err) -> bool
is_ok(err) -> bool
```

### Error Logging

```odin
log_error(err)
log_warning(err)
error_string(err) -> string
```

## Implementation in DI

All DI functions return `(T, Error)`:

```odin
// Container
create_injector() -> (Injector, Error)
destroy_injector(^Injector) -> Error

// Registration
register(^Injector, Token, Provider) -> Error
register_singleton(^Injector, Token, int, Factory_Proc) -> Error
register_value(^Injector, Token, rawptr) -> Error
register_factory(^Injector, Token, Factory_Proc) -> Error

// Resolution
resolve(^Injector, Token) -> (rawptr, Error)
inject(^Injector, $T) -> (^T, Error)
has(^Injector, Token) -> (bool, Error)
```

## Implementation in Services

All services follow the factory pattern with errors:

```odin
// Factory signature
xxx_service_create :: proc(inj: ^di.Injector) -> (^Xxx_Service, errors.Error)

// Method signatures
xxx_service_method :: proc(svc: ^Xxx_Service, ...) -> (Result, errors.Error)
```

### Example Services

| Service | File | Methods |
|---------|------|---------|
| Logger | `src/services/logger.odin` | `logger_create()` |
| User | `src/services/user_service.odin` | `add`, `remove`, `get`, `update` |
| Auth | `src/services/auth_service.odin` | `register`, `login`, `logout`, `verify` |
| Cache | `src/services/cache_service.odin` | `set`, `get`, `delete`, `clear` |
| Storage | `src/services/storage_service.odin` | `load`, `save`, `set`, `get` |
| Http | `src/services/http_service.odin` | `get`, `post`, `request` |
| Notification | `src/services/notification_service.odin` | `notify`, `mark_read`, `clear` |

## Implementation in Event System

```odin
create_event_bus() -> (Event_Bus, Error)
destroy_event_bus(^Event_Bus) -> Error
subscribe(^Event_Bus, Event_Type, callback) -> Error
emit(^Event_Bus, Event_Type, rawptr) -> Error
```

## Usage Pattern

```odin
// Initialize
inj, err := di.create_injector()
if err.code != errors.Error_Code.None {
    return err
}

// Register
err = di.register_singleton(&inj, "logger", size_of(Logger), create_logger)
if err.code != errors.Error_Code.None {
    return err
}

// Resolve
logger, err := di.inject(inj, Logger)
if err.code != errors.Error_Code.None {
    return err
}

// Use service
err = cache_service_set(svc, "key", value)
if err.code != errors.Error_Code.None {
    return err
}
```

## Migration Checklist

For each function:

- [ ] Update return signature to `(T, Error)`
- [ ] Add parameter validation
- [ ] Return appropriate error codes
- [ ] Update callers to check errors

## See Also

- [01_DI_SYSTEM.md](01_DI_SYSTEM.md) - DI system
- [02_ERROR_HANDLING_GUIDE.md](02_ERROR_HANDLING_GUIDE.md) - Usage guide
- [src/lib/errors/errors.odin](../src/lib/errors/errors.odin) - Implementation
