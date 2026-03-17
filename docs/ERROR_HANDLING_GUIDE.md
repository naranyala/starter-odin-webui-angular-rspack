# Error Handling Guide

## Overview

This project now includes a comprehensive, multi-layered error handling system that provides:

- **Structured error codes** for precise error identification
- **Error results** for explicit error propagation
- **Error wrapping** for context preservation
- **Error collection** for aggregating multiple errors
- **Statistics tracking** for monitoring error rates

## Package Structure

```
errors/              # Core error handling package
di/                  # DI system with error handling
comms/               # Communication layer with error handling
utils/               # Utility modules with error handling
```

## Core Error Package (`errors/`)

### Error Codes

The system defines standardized error codes organized by category:

```odin
import errors "./errors"

// General errors (0-99)
errors.Error_Code.None           // No error
errors.Error_Code.Unknown        // Unknown error
errors.Error_Code.Internal       // Internal error
errors.Error_Code.Timeout        // Operation timed out

// Parameter errors (100-199)
errors.Error_Code.Invalid_Parameter
errors.Error_Code.Null_Argument
errors.Error_Code.Empty_Argument

// Resource errors (200-299)
errors.Error_Code.Not_Found
errors.Error_Code.Already_Exists
errors.Error_Code.Access_Denied

// I/O errors (300-399)
errors.Error_Code.File_Not_Found
errors.Error_Code.File_Read_Error
errors.Error_Code.File_Write_Error

// Communication errors (1000-1099)
errors.Error_Code.RPC_Error
errors.Error_Code.RPC_Method_Not_Found
errors.Error_Code.RPC_Timeout

// DI errors (900-999)
errors.Error_Code.DI_Error
errors.Error_Code.DI_Not_Registered
errors.Error_Code.DI_Resolution_Failed
```

### Creating Errors

```odin
import errors "./errors"

// Create simple error
err := errors.new(errors.Error_Code.Invalid_Parameter, "Invalid username")

// Create error with details
err := errors.new_detailed(
    errors.Error_Code.File_Read_Error,
    "Failed to read config",
    "Permission denied: /etc/app/config.json")

// Create error with cause
cause := errors.err_file_not_found("/path/to/file")
err := errors.new_with_cause(errors.Error_Code.IO_Error, "Config load failed", cause)

// Create critical/fatal errors
err := errors.new_critical(errors.Error_Code.Resource_Exhausted, "Out of memory")
err := errors.new_fatal(errors.Error_Code.Internal, "Unrecoverable system state")
```

### Convenience Functions

```odin
// General errors
err := errors.err_unknown("Something went wrong")
err := errors.err_timeout("Operation took too long")
err := errors.err_cancelled("Operation was cancelled")

// Parameter errors
err := errors.err_invalid_param("username", "Must be at least 3 characters")
err := errors.err_null_argument("callback")
err := errors.err_empty_argument("email")

// Resource errors
err := errors.err_not_found("user_123")
err := errors.err_already_exists("admin@example.com")
err := errors.err_access_denied("/admin/settings")

// I/O errors
err := errors.err_file_not_found("/path/to/file.txt")
err := errors.err_file_read("/path/to/file.txt", "Permission denied")
err := errors.err_file_write("/path/to/file.txt", "Disk full")

// Network errors
err := errors.err_connection_failed("api.example.com")
err := errors.err_connection_timeout("api.example.com")

// Validation errors
err := errors.err_required_field("email")
err := errors.err_invalid_value("age", "-5", "Must be positive")
```

### Error Results

Use `Error_Result` for explicit error propagation:

```odin
// Function signature with error result
my_function :: proc() -> (T, errors.Error_Result) {
    if something_wrong {
        return zero(T), errors.result_error(errors.err_invalid_state("..."))
    }
    return value, errors.result_ok()
}

// Usage
result, err := my_function()
if errors.check_result(err) {
    fmt.printf("Error: %s\n", errors.error_string(&err.error))
    return
}
// Use result
```

### Error Formatting

```odin
err := errors.err_file_not_found("/path/to/file")

// Simple string
str := errors.error_string(&err)
// Output: "[File_Not_Found] File not found: /path/to/file"

// For logging
log_str := errors.error_log_string(&err)
// Output: "[ERROR][File_Not_Found] File not found: /path/to/file"

// Stack trace
trace := errors.error_stack_trace(&err)
// Output: Full error details with timestamp and location
```

### Error Wrapping

```odin
// Wrap error with context
inner_err := errors.err_file_not_found("/config.json")
wrapped_err := errors.wrap(inner_err, "Loading application config")

// Output: "[File_Not_Found] Loading application config: File not found: /config.json"

// Unwrap to root cause
root := errors.unwrap(&wrapped_err)

// Get all causes
causes := errors.get_all_causes(&wrapped_err)
```

### Error Collection

Aggregate multiple errors:

```odin
// Create collection
col := errors.collection_create(100)
defer errors.collection_destroy(col)

// Add errors
errors.collection_add(col, errors.err_file_read("a.txt", "reason 1"))
errors.collection_add(col, errors.err_file_read("b.txt", "reason 2"))

// Check for errors
if errors.collection_has_errors(col) {
    fmt.printf("Had %d errors:\n", errors.collection_count(col))
    fmt.printf("%s\n", errors.collection_string(col))
}
```

## DI System Error Handling

### Registration with Errors

```odin
import di "./di"

container := di.create_container()

// Register with error checking
err := di.register_singleton(&container, "logger", size_of(Logger))
if err.has_error {
    fmt.printf("Failed to register logger: %s\n", err.error.message)
}

// Register factory with error
factory_with_error :: proc(c : ^di.Container) -> (rawptr, di.DI_Error_Result) {
    // Factory logic
    if something_wrong {
        return nil, di.di_error_result(di.DI_Error_Code.Invalid_Factory, "Init failed")
    }
    return instance, di.di_error_ok()
}

err = di.register_factory_with_error(&container, "service", factory_with_error)
```

### Resolution with Errors

```odin
// Resolve with error handling
instance, err := di.resolve_with_error(&container, "logger")
if err.has_error {
    di.report_resolution_error(err, "logger")
    return
}

// Typed resolution
instance, err := di.resolve_typed(&container, "logger", "Logger")
if err.has_error {
    // Handle error
}

// Validate container
err = di.validate_container(&container)
if err.has_error {
    fmt.printf("Container validation failed: %s\n", err.error.message)
}
```

### Container Info

```odin
// Get container statistics
info := di.get_container_info(&container)
fmt.printf("Providers: %d/%d (%.1f%%)\n", 
    info.provider_count, info.max_providers, info.provider_usage_percent)

// Print container info
di.print_container_info(&container)
```

## Communication Layer Error Handling

### RPC Error Handling

```odin
import comms "./comms"

// Initialize with error checking
err := comms.comms_init()
if err.has_error {
    fmt.printf("Comms init failed: %s\n", err.error.message)
}

// Register RPC handler with error
rpc_handler :: proc "c" (e : ^webui.Event) -> (string, comms.Comms_Error_Result) {
    data := webui.event_get_string(e)
    
    if data == "" {
        return "", comms.comms_error_result(
            comms.Comms_Error_Code.Invalid_Request,
            "Empty data received")
    }
    
    // Process data
    result := process_data(data)
    
    return result, comms.comms_error_ok()
}

err = comms.rpc_register_with_error("processData", rpc_handler)
```

### Event Bus Error Handling

```odin
// Subscribe with error-handling handler
event_handler :: proc "c" (win : webui.Window, data : string) -> comms.Comms_Error_Result {
    if data == "" {
        return comms.comms_error_result(
            comms.Comms_Error_Code.Invalid_Request,
            "Empty event data")
    }
    
    handle_event(data)
    return comms.comms_error_ok()
}

err := comms.event_bus_on_with_error("user.login", event_handler)

// Publish with error checking
err = comms.event_bus_emit("user.login", "{\"user\":\"john\"}")
if err.has_error {
    fmt.printf("Event failed: %s\n", err.error.message)
}

// Get event statistics
count, errs := comms.event_bus_get_stats("user.login")
fmt.printf("Events: %d, Errors: %d\n", count, errs)
```

### Channel Error Handling

```odin
// Create channel
err := comms.channel_create("chat")
if err.has_error {
    // Handle error
}

// Send to channel
err = comms.channel_send("chat", "Hello!")
if err.has_error {
    // Handle error
}

// Get channel statistics
msg_count, err_count, stat_err := comms.channel_get_stats("chat")
if stat_err.has_error {
    // Handle error
}
```

### Comms Statistics

```odin
// Get overall comms statistics
stats := comms.comms_get_stats()
fmt.printf("%s\n", stats)

// Output:
// === Comms Statistics ===
// Total Errors: 5
// RPC Enabled: true
// Events Enabled: true
// Channels Enabled: false
```

## Best Practices

### 1. Always Check Errors

```odin
// Bad: Ignore errors
di.register_singleton(&container, "logger", size_of(Logger))

// Good: Check errors
err := di.register_singleton(&container, "logger", size_of(Logger))
if err.has_error {
    log_error("Failed to register logger", err.error.message)
    return err
}
```

### 2. Provide Context

```odin
// Bad: Generic error
return errors.err_io("Read failed")

// Good: Specific context
return errors.err_file_read("/config/app.json", "Permission denied")
```

### 3. Wrap Errors

```odin
// Bad: Lose context
err := load_config()
if errors.check(err) {
    return errors.err_internal("Config failed")
}

// Good: Preserve and add context
err := load_config()
if errors.check(err) {
    return errors.wrap(err, "Application initialization")
}
```

### 4. Use Error Results for Critical Operations

```odin
// For operations where errors must be handled
save_user :: proc(user : User) -> errors.Error_Result {
    if user.email == "" {
        return errors.result_error(errors.err_required_field("email"))
    }
    
    err := db.save(user)
    if errors.check(err) {
        return errors.result_error(errors.wrap(err, "Save user"))
    }
    
    return errors.result_ok()
}

// Usage
err := save_user(user)
if errors.check_result(err) {
    // Must handle this error
    show_error(err.error.message)
}
```

### 5. Track Error Statistics

```odin
// Monitor error rates in production
rpc_calls, rpc_errors := comms.rpc_get_stats("user.login")
if rpc_errors > 0 {
    error_rate := f64(rpc_errors) / f64(rpc_calls) * 100
    if error_rate > 5.0 {
        alert("High error rate on user.login: %.1f%%", error_rate)
    }
}
```

### 6. Log Errors Appropriately

```odin
// Use appropriate severity
if err.code == errors.Error_Code.Validation_Error {
    log_warn("Validation: %s", err.message)
} else if err.code == errors.Error_Code.File_Not_Found {
    log_error("File missing: %s", err.details)
} else if err.severity == errors.Error_Severity.Critical {
    log_critical("System error: %s", errors.error_stack_trace(&err))
}
```

## Error Handling Patterns

### Try Pattern

```odin
// Execute with error handling
result := errors.try_execute(proc() -> errors.Error {
    return some_operation()
})

if !result.success {
    handle_error(result.error)
}

// Execute with recovery
result := errors.try_recover(
    proc() -> errors.Error {
        return risky_operation()
    },
    proc(err : errors.Error) {
        // Recovery logic
        log_error("Recovered from:", err.message)
    }
)
```

### Validation Pattern

```odin
validate_user :: proc(user : User) -> errors.Error_Result {
    col := errors.collection_create(10)
    defer errors.collection_destroy(col)
    
    if user.name == "" {
        errors.collection_add(col, errors.err_required_field("name"))
    }
    
    if user.email == "" {
        errors.collection_add(col, errors.err_required_field("email"))
    } else if !is_valid_email(user.email) {
        errors.collection_add(col, errors.err_invalid_value("email", user.email, "Invalid format"))
    }
    
    if errors.collection_has_errors(col) {
        return errors.result_error(errors.collection_first(col))
    }
    
    return errors.result_ok()
}
```

### Resource Management Pattern

```odin
process_file :: proc(path : string) -> errors.Error_Result {
    // Check file exists
    if !file_exists(path) {
        return errors.result_error(errors.err_file_not_found(path))
    }
    
    // Read file
    content, ok := file_read(path)
    if !ok {
        return errors.result_error(errors.err_file_read(path, "Read failed"))
    }
    
    // Process
    err := process_content(content)
    if errors.check(err) {
        return errors.result_error(errors.wrap(err, fmt.Sprintf("Process file: %s", path)))
    }
    
    return errors.result_ok()
}
```

## Migration Guide

### From Old Style to New Error Handling

**Before:**
```odin
// Old style - no error return
register_service :: proc(container : ^di.Container) {
    di.register_singleton(container, "logger", size_of(Logger))
}
```

**After:**
```odin
// New style - explicit error handling
register_service :: proc(container : ^di.Container) -> errors.Error_Result {
    err := di.register_singleton(container, "logger", size_of(Logger))
    if err.has_error {
        return errors.result_error(di.di_to_error(err.error))
    }
    return errors.result_ok()
}
```

## Summary

The enhanced error handling system provides:

1. **Structured error codes** - Precise error identification
2. **Error results** - Explicit error propagation
3. **Error wrapping** - Context preservation
4. **Statistics tracking** - Production monitoring
5. **Error collections** - Multiple error aggregation
6. **Severity levels** - Appropriate logging

Use these tools to build robust, maintainable applications that handle errors gracefully and provide clear diagnostics for debugging.
