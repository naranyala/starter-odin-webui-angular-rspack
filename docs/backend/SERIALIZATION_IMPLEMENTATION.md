# Serialization/Deserialization Implementation Guide

## Overview

This guide documents the improved serialization/deserialization system for backend-frontend communication in the Odin WebUI Angular application.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (Angular)                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ApiService                                           │   │
│  │  - JSON serialization of arguments                    │   │
│  │  - Automatic response parsing                         │   │
│  │  - Error handling & retry logic                       │   │
│  │  - Request/Response logging                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↕ webui.js                          │
└─────────────────────────────────────────────────────────────┘
                          ↕ WebUI Bridge
┌─────────────────────────────────────────────────────────────┐
│                     Backend (Odin)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  WebUI Handlers (src/handlers/webui_handlers.odin)   │   │
│  │  - Parse JSON arguments                               │   │
│  │  - Validate input                                     │   │
│  │  - Return standardized responses                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↕                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Serialization Service (services/serialization_service.odin) │
│  │  - JSON marshal/unmarshal                            │   │
│  │  - Response builders                                 │   │
│  │  - Error formatters                                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↕                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  WebUI Helper (services/webui_helper.odin)           │   │
│  │  - Context management                                │   │
│  │  - Request/Response helpers                          │   │
│  │  - Logging utilities                                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Standard Response Format

All API responses follow this standardized format:

```typescript
interface ApiResponse<T> {
  success: boolean;      // true for success, false for error
  data?: T;             // Response data (JSON-encoded on backend)
  error?: string;       // Error message (if success=false)
  code?: number;        // HTTP-style status code
  details?: string[];   // Additional error details
  requestId?: string;   // Unique request identifier
  timestamp?: number;   // Unix timestamp in milliseconds
}
```

### Success Response Example

```json
{
  "success": true,
  "data": "{\"id\":1,\"name\":\"John Doe\",\"email\":\"john@example.com\"}",
  "code": 200,
  "requestId": "req_1711532400_123456",
  "timestamp": 1711532400123
}
```

### Error Response Example

```json
{
  "success": false,
  "error": "Validation failed",
  "code": 400,
  "details": [
    "name: Name is required",
    "email: Invalid email format"
  ],
  "requestId": "req_1711532400_789012",
  "timestamp": 1711532400456
}
```

## Backend Usage (Odin)

### 1. Basic Handler with WebUI Helper

```odin
package main

import webui "./webui_lib"
import services "./services"

handle_get_users :: proc "c" (e : ^webui.Event) {
    // Initialize context
    ctx, err := services.init_context(e)
    if err.code != services.errors.Error_Code.None {
        error_json := services.create_error_response(err.message, 400)
        webui.webui_event_return_string(e, error_json)
        return
    }

    // Get data
    users := get_users_from_database()
    
    // Send success response
    services.ctx_respond_success(&ctx, &users, "[]User")
}
```

### 2. Handler with JSON Parsing

```odin
handle_create_user :: proc "c" (e : ^webui.Event) {
    ctx, err := services.init_context(e)
    if err.code != services.errors.Error_Code.None {
        error_json := services.create_error_response(err.message, 400)
        webui.webui_event_return_string(e, error_json)
        return
    }

    // Parse JSON argument
    var user : User
    deserialize_err := services.deserialize(ctx.args_json, &user, "User")
    
    if deserialize_err.code != services.errors.Error_Code.None {
        services.ctx_respond_error(&ctx, deserialize_err.message, 400)
        return
    }

    // Validate
    if user.name == "" {
        services.ctx_respond_error(&ctx, "Name is required", 400)
        return
    }

    // Save user
    user.id = generate_id()
    user.created_at = services.now_iso()
    save_user(&user)

    // Return created user
    services.ctx_respond_success(&ctx, &user, "User")
}
```

### 3. Getting Arguments

```odin
handle_update_user :: proc "c" (e : ^webui.Event) {
    ctx, _ := services.init_context(e)

    // Get primitive arguments
    user_id := services.ctx_get_int(&ctx, "id", 0)
    name := services.ctx_get_string(&ctx, "name", "")
    active := services.ctx_get_bool(&ctx, "active", true)

    // Get JSON object
    user_json, ok := services.ctx_get_json(&ctx, "user")
    if ok && user_json.type == .Object {
        // Access nested properties
        email_value := user_json.object_value["email"]
        if email_value.type == .String {
            email := email_value.string_value
        }
    }
}
```

### 4. Error Handling

```odin
// Simple error
services.ctx_respond_error(&ctx, "User not found", 404)

// Error with details
details := []string{"User ID must be positive", "Provided: -1"}
services.ctx_respond_error_detailed(&ctx, "Invalid user ID", 400, details)

// Validation errors
field_errors := make(map[string][]string)
append(&field_errors["name"], "Name is required")
append(&field_errors["email"], "Invalid email format")
services.ctx_respond_validation_error(&ctx, field_errors)
```

### 5. Registering Handlers

```odin
register_handlers :: proc(win : webui.Window) {
    webui.bind(win, "getUsers", handle_get_users)
    webui.bind(win, "createUser", handle_create_user)
    webui.bind(win, "updateUser", handle_update_user)
    webui.bind(win, "deleteUser", handle_delete_user)
    webui.bind(win, "getUserStats", handle_get_user_stats)
}
```

## Frontend Usage (TypeScript/Angular)

### 1. Basic API Call

```typescript
import { ApiService } from './core/api.service';

@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly api = inject(ApiService);

  async getUsers(): Promise<User[]> {
    const response = await this.api.callOrThrow<User[]>('getUsers');
    return response;
  }

  async createUser(user: Partial<User>): Promise<User> {
    const response = await this.api.callOrThrow<User>('createUser', [user]);
    return response;
  }
}
```

### 2. With Error Handling

```typescript
async saveUser(user: Partial<User>): Promise<void> {
  try {
    const response = await this.api.call<User>('createUser', [user]);
    
    if (response.success) {
      this.logger.info('User created', response.data);
    } else {
      this.logger.error('Create failed', response.error);
    }
  } catch (error) {
    this.logger.error('API error', error);
    throw error;
  }
}
```

### 3. With Retry Logic

```typescript
async getUserWithRetry(id: number): Promise<User> {
  const response = await this.api.callWithRetry<User>(
    'getUser',
    [{ id }],
    3,  // retries
    1000  // delay ms
  );
  
  if (!response.success) {
    throw new Error(response.error);
  }
  
  return response.data!;
}
```

### 4. Parallel Calls

```typescript
async loadDashboard(): Promise<void> {
  const results = await this.api.callAll<{
    getUsers: User[];
    getProducts: Product[];
    getOrders: Order[];
  }>([
    { function: 'getUsers' },
    { function: 'getProducts' },
    { function: 'getOrders' },
  ]);

  this.users.set(results.getUsers.data || []);
  this.products.set(results.getProducts.data || []);
  this.orders.set(results.getOrders.data || []);
}
```

### 5. Using Signals

```typescript
@Component({
  selector: 'app-users',
  template: `
    @if (api.isLoading()) {
      <div>Loading...</div>
    } @else if (api.error$()) {
      <div>Error: {{ api.error$() }}</div>
    } @else {
      <div>{{ users().length }} users</div>
    }
  `,
})
export class UsersComponent {
  readonly api = inject(ApiService);
  users = signal<User[]>([]);

  async ngOnInit() {
    const response = await this.api.callOrThrow<User[]>('getUsers');
    this.users.set(response);
  }
}
```

## Data Type Mapping

### Backend (Odin) → Frontend (TypeScript)

| Odin Type | JSON Type | TypeScript Type |
|-----------|-----------|-----------------|
| `int` | number | `number` |
| `f64` | number | `number` |
| `bool` | boolean | `boolean` |
| `string` | string | `string` |
| `[]T` | array | `T[]` |
| `struct { ... }` | object | `{ ... }` |
| `map[string]T` | object | `Record<string, T>` |
| `time.Time` | string (ISO) | `string` (ISO 8601) |

### Date/Time Handling

**Backend (Odin):**
```odin
// Get current time as ISO string
iso_date := services.now_iso()  // "2026-03-27T10:30:00Z"

// Parse ISO string
time_val, err := services.parse_iso_date("2026-03-27T10:30:00Z")
```

**Frontend (TypeScript):**
```typescript
// Send date
const payload = {
  created_at: new Date().toISOString(),
};

// Receive date
const date = new Date(response.created_at);
```

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 200 | OK | Success |
| 400 | Bad Request | Invalid arguments or validation failed |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 408 | Request Timeout | Request timed out |
| 409 | Conflict | Resource conflict |
| 500 | Internal Server Error | Server-side error |

## Best Practices

### Backend

1. **Always use context initialization:**
   ```odin
   ctx, err := services.init_context(e)
   if err.code != services.errors.Error_Code.None {
       // Handle error
   }
   ```

2. **Validate all input:**
   ```odin
   if user.name == "" {
       services.ctx_respond_error(&ctx, "Name is required", 400)
       return
   }
   ```

3. **Use standardized responses:**
   ```odin
   services.ctx_respond_success(&ctx, &data, "DataType")
   ```

4. **Log requests and responses:**
   ```odin
   services.log_request(&ctx, "handlerName")
   services.log_response(&ctx, "handlerName", true)
   ```

### Frontend

1. **Use ApiService methods:**
   ```typescript
   // Good
   const response = await this.api.callOrThrow<T>('function', [args]);
   
   // Bad - direct webui call
   const result = await webui.function(args);
   ```

2. **Handle errors properly:**
   ```typescript
   try {
     const response = await this.api.call<T>('function', [args]);
     if (!response.success) {
       this.handleError(response.error);
     }
   } catch (error) {
     this.handleError(error);
   }
   ```

3. **Use retry for flaky operations:**
   ```typescript
   const response = await this.api.callWithRetry('function', [args], 3, 1000);
   ```

4. **Enable logging in development:**
   ```typescript
   const response = await this.api.call('function', [args], {
     logRequest: true,
     logResponse: true,
   });
   ```

## Testing

### Backend Test Example

```odin
test_serialization :: proc() {
    user := User{
        id = 1,
        name = "Test User",
        email = "test@example.com",
    }
    
    // Serialize
    json_str, err := services.serialize(&user, "User")
    assert(err.code == services.errors.Error_Code.None)
    
    // Deserialize
    var user2 : User
    deserialize_err := services.deserialize(json_str, &user2, "User")
    assert(deserialize_err.code == services.errors.Error_Code.None)
    assert(user.id == user2.id)
    assert(user.name == user2.name)
}
```

### Frontend Test Example

```typescript
describe('ApiService', () => {
  it('should serialize and deserialize objects', async () => {
    const user = { name: 'Test', email: 'test@example.com' };
    
    // Mock backend function
    (window as any).testFunc = (...args: unknown[]) => {
      expect(args[0]).toContain('"name":"Test"');
      window.dispatchEvent(new CustomEvent('testFunc_response', {
        detail: { success: true, data: JSON.stringify(user) }
      }));
    };
    
    const response = await service.call('testFunc', [user]);
    expect(response.success).toBe(true);
    expect(response.data).toEqual(user);
  });
});
```

## Migration Guide

### From Old to New System

**Before:**
```odin
handle_get_users :: proc "c" (e : ^webui.Event) {
    users_json := get_users_json()
    webui.webui_event_return_string(e, users_json)
}
```

**After:**
```odin
handle_get_users :: proc "c" (e : ^webui.Event) {
    ctx, _ := services.init_context(e)
    users := get_users()
    services.ctx_respond_success(&ctx, &users, "[]User")
}
```

**Before (Frontend):**
```typescript
const users = await webui.getUsers();
```

**After (Frontend):**
```typescript
const response = await this.api.callOrThrow<User[]>('getUsers');
```

## Files Reference

### Backend
- `src/services/serialization_service.odin` - Core serialization
- `src/services/webui_helper.odin` - WebUI helpers
- `src/handlers/webui_handlers.odin` - Example handlers

### Frontend
- `frontend/src/core/api.service.ts` - Enhanced API service
- `frontend/src/app/services/data-transform/` - Data transformation

### WebUI Bridge
- `thirdparty/webui/bridge/webui.js` - JavaScript bridge
- `frontend/dist/browser/webui.js` - Deployed bridge

## Troubleshooting

### Issue: "Backend function not found"
**Solution:** Ensure handler is registered with `webui.bind()`

### Issue: "JSON parse error"
**Solution:** Check that backend returns valid JSON, use `services.is_valid_json()`

### Issue: "Request timeout"
**Solution:** Increase timeout in options or optimize backend handler

### Issue: "Type mismatch in response"
**Solution:** Ensure backend type matches frontend interface

## Support

For issues or questions:
1. Check the example handlers in `src/handlers/webui_handlers.odin`
2. Review the serialization service API
3. Enable request/response logging for debugging
