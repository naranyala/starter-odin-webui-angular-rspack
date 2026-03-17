# OPEN - Registry Lifecycle Audit

## Status: 🟡 OPEN

## Issue

### No Automatic Service Cleanup
- **Severity**: Medium
- **File**: `src/services/registry.odin`
- **Issue**: Services have destroy functions but they're not called automatically on shutdown

## Current Behavior

```odin
registry_shutdown :: proc() -> errors.Error {
    events.emit(&registry.event_bus, .Service_Stopped, nil)
    destroy_event_bus(&registry.event_bus)
    err := di.destroy_injector(&registry.injector)
    // Missing: Call service destroy functions!
    return err
}
```

## Recommended Fix

1. Track services in registry
2. Call destroy functions on shutdown:
```odin
for name, destroy_fn in registry.destroy_callbacks {
    destroy_fn()
}
```

## Priority

**MEDIUM** - Can cause memory leaks
