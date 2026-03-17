# OPEN - Models Audit

## Status: 🟡 OPEN

## Issue

### Duplicate User Models
- **Severity**: Medium
- **Files**: Multiple

User struct defined in multiple places with different fields:

```odin
// src/models/models.odin
User :: struct {
    id: string,
    username: string,
    email: string,
    created_at: u64,
    is_active: bool,
}

// src/services/user_service.odin
User :: struct {
    id: int,
    name: string,
}

// src/services/auth_service.odin
Auth_User :: struct {
    id: int,
    username: string,
    password: string,
    email: string,
    role: string,
}
```

## Recommended Fix

1. Keep single authoritative User in `src/models/models.odin`
2. Update all services to import from models
3. Use consistent types (e.g., `id: int` vs `id: string`)

## Priority

**MEDIUM** - Causes confusion but not blocking
