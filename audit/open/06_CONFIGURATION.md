# OPEN - Configuration Audit

## Status: 🟡 OPEN

## Issue

### Hardcoded Values Everywhere
- **Severity**: Low
- **Files**: All services

Services have hardcoded values:

```odin
// Cache service
service.ttl = time.Hour * 1  // Hardcoded!

// Hash maps
hash_map.create_hash_map(string, Cache_Entry, 64)  // Hardcoded size

// Event bus queue
queue.init(&bus.queue, 8)  // Fixed size!
```

## Recommended Fix

1. Create configuration system
2. Allow configurable values
3. Use sensible defaults

```odin
Config :: struct {
    cache_ttl: time.Duration,
    cache_max_entries: int,
    event_queue_size: int,
}
```

## Priority

**LOW** - Flexibility improvement
