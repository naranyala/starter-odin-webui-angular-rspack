# Production SQLite Integration Guide

**Complete guide for integrating SQLite with Odin backend and Angular frontend**

---

## Overview

This guide covers **production-ready SQLite integration** for transactional workloads, providing complete CRUD operations with a lightweight, embedded database solution.

### Use Cases

- **Transactional Operations**: ACID-compliant data modifications
- **Embedded Storage**: Zero-configuration database
- **Mobile/Desktop Apps**: Local data persistence
- **Lightweight Applications**: Minimal footprint deployments

---

## Architecture

```
+------------------+     WebSocket     +------------------+
|  Angular         |◄─────────────────►|  WebUI Bridge    |
|  Frontend        |                   |  (Civetweb)      |
|                  |                   +--------+---------+
|  - SQLite CRUD   |                            |
|  - User Mgmt     |                            | FFI
|                  |                            v
+------------------+                   +------------------+
                                       |  Odin Backend    |
                                       |                  |
                                       |  - SQLite Svc    |
                                       |  - Handlers      |
                                       |  - Serialization |
                                       +--------+---------+
                                                |
                                                | SQL
                                                v
                                       +------------------+
                                       |  SQLite          |
                                       |  (Embedded)      |
                                       +------------------+
```

---

## Backend Implementation

### 1. SQLite Service Structure

```odin
package services

import "core:fmt"
import "core:sync"
import "../lib/webui_lib"

// SQLite Service
SQLite_Service :: struct {
    mutex      : sync.Mutex,
    database   : rawptr,  // SQLite database handle
}

// Initialize SQLite service
init_sqlite_service :: proc() -> (SQLite_Service, Error) {
    svc := SQLite_Service{}
    
    // Open database (creates file if not exists)
    db_path := "build/sqlite.db"
    result := sqlite3_open(db_path, &svc.database)
    
    if result != SQLITE_OK {
        err_msg := sqlite3_errmsg(svc.database)
        return svc, Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to open SQLite: %s", err_msg)
        }
    }
    
    // Enable foreign keys
    sqlite3_exec(svc.database, "PRAGMA foreign_keys = ON", nil, nil, nil)
    
    // Initialize schema
    err := initialize_schema(&svc)
    if err.code != .None {
        return svc, err
    }
    
    return svc, Error{code: .None}
}

// Initialize database schema
initialize_schema :: proc(svc: ^SQLite_Service) -> Error {
    create_table_sql := `
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            age INTEGER,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `
    
    var err_msg : cstring
    result := sqlite3_exec(svc.database, create_table_sql, nil, nil, &err_msg)
    
    if result != SQLITE_OK {
        return Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to create table: %s", err_msg)
        }
    }
    
    return Error{code: .None}
}

// Cleanup SQLite service
cleanup_sqlite_service :: proc(svc: ^SQLite_Service) {
    if svc.database != nil {
        sqlite3_close(svc.database)
        svc.database = nil
    }
}
```

### 2. CRUD Operations

#### Create User

```odin
sqlite_create_user :: proc(svc: ^SQLite_Service, user: ^User) -> (int, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var stmt : rawptr
    sql := "INSERT INTO users (name, email, age) VALUES (?, ?, ?)"
    
    result := sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    if result != SQLITE_OK {
        err_msg := sqlite3_errmsg(svc.database)
        return 0, Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to prepare statement: %s", err_msg)
        }
    }
    defer sqlite3_finalize(stmt)
    
    // Bind parameters
    sqlite3_bind_text(stmt, 1, user.name, -1, SQLITE_TRANSIENT)
    sqlite3_bind_text(stmt, 2, user.email, -1, SQLITE_TRANSIENT)
    sqlite3_bind_int(stmt, 3, int32(user.age))
    
    // Execute
    result = sqlite3_step(stmt)
    if result != SQLITE_DONE {
        err_msg := sqlite3_errmsg(svc.database)
        return 0, Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to insert user: %s", err_msg)
        }
    }
    
    // Get last inserted ID
    last_id := sqlite3_last_insert_rowid(svc.database)
    
    return int(last_id), Error{code: .None}
}
```

#### Read Users

```odin
sqlite_get_users :: proc(svc: ^SQLite_Service) -> ([]User, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var stmt : rawptr
    sql := "SELECT id, name, email, age, created_at FROM users ORDER BY created_at DESC"
    
    result := sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    if result != SQLITE_OK {
        err_msg := sqlite3_errmsg(svc.database)
        return nil, Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to prepare statement: %s", err_msg)
        }
    }
    defer sqlite3_finalize(stmt)
    
    users := make([]User, 0)
    
    for sqlite3_step(stmt) == SQLITE_ROW {
        user := User{}
        user.id = int(sqlite3_column_int(stmt, 0))
        user.name = string(sqlite3_column_text(stmt, 1))
        user.email = string(sqlite3_column_text(stmt, 2))
        user.age = int(sqlite3_column_int(stmt, 3))
        user.created_at = string(sqlite3_column_text(stmt, 4))
        
        users = append(users, user)
    }
    
    return users, Error{code: .None}
}
```

#### Update User

```odin
sqlite_update_user :: proc(svc: ^SQLite_Service, user: ^User) -> Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var stmt : rawptr
    sql := "UPDATE users SET name = ?, email = ?, age = ? WHERE id = ?"
    
    result := sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    if result != SQLITE_OK {
        err_msg := sqlite3_errmsg(svc.database)
        return Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to prepare statement: %s", err_msg)
        }
    }
    defer sqlite3_finalize(stmt)
    
    // Bind parameters
    sqlite3_bind_text(stmt, 1, user.name, -1, SQLITE_TRANSIENT)
    sqlite3_bind_text(stmt, 2, user.email, -1, SQLITE_TRANSIENT)
    sqlite3_bind_int(stmt, 3, int32(user.age))
    sqlite3_bind_int(stmt, 4, int32(user.id))
    
    // Execute
    result = sqlite3_step(stmt)
    if result != SQLITE_DONE {
        err_msg := sqlite3_errmsg(svc.database)
        return Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to update user: %s", err_msg)
        }
    }
    
    return Error{code: .None}
}
```

#### Delete User

```odin
sqlite_delete_user :: proc(svc: ^SQLite_Service, user_id: int) -> Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var stmt : rawptr
    sql := "DELETE FROM users WHERE id = ?"
    
    result := sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    if result != SQLITE_OK {
        err_msg := sqlite3_errmsg(svc.database)
        return Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to prepare statement: %s", err_msg)
        }
    }
    defer sqlite3_finalize(stmt)
    
    // Bind parameter
    sqlite3_bind_int(stmt, 1, int32(user_id))
    
    // Execute
    result = sqlite3_step(stmt)
    if result != SQLITE_DONE {
        err_msg := sqlite3_errmsg(svc.database)
        return Error{
            code: .Database_Error,
            message: fmt.Sprintf("Failed to delete user: %s", err_msg)
        }
    }
    
    return Error{code: .None}
}
```

### 3. Analytics Functions

```odin
sqlite_get_user_stats :: proc(svc: ^SQLite_Service) -> (UserStats, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    stats := UserStats{}
    var stmt : rawptr
    
    // Total users
    sql := "SELECT COUNT(*) FROM users"
    sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    sqlite3_step(stmt)
    stats.total_users = int(sqlite3_column_int(stmt, 0))
    sqlite3_finalize(stmt)
    
    // Users created today
    sql = "SELECT COUNT(*) FROM users WHERE DATE(created_at) = DATE('now')"
    sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    sqlite3_step(stmt)
    stats.today_count = int(sqlite3_column_int(stmt, 0))
    sqlite3_finalize(stmt)
    
    // Unique email domains
    sql = "SELECT COUNT(DISTINCT SUBSTR(email, INSTR(email, '@') + 1)) FROM users"
    sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    sqlite3_step(stmt)
    stats.unique_domains = int(sqlite3_column_int(stmt, 0))
    sqlite3_finalize(stmt)
    
    return stats, Error{code: .None}
}
```

---

## WebUI Handlers

### Handler Registration

```odin
package main

import services "../services"

init_sqlite_handlers :: proc() {
    // CRUD operations
    webui.bind(window, "sqlite:getUsers", handle_sqlite_get_users)
    webui.bind(window, "sqlite:createUser", handle_sqlite_create_user)
    webui.bind(window, "sqlite:updateUser", handle_sqlite_update_user)
    webui.bind(window, "sqlite:deleteUser", handle_sqlite_delete_user)
    
    // Analytics
    webui.bind(window, "sqlite:getUserStats", handle_sqlite_get_user_stats)
}
```

### Handler Implementations

```odin
handle_sqlite_get_users :: proc "c" (e : ^webui.Event) {
    ctx, err := services.init_context(e)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    users, err := services.sqlite_get_users(&sqlite_service)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    // Serialize to JSON
    json := serialize_users(users)
    services.ctx_respond_success_raw(&ctx, json)
}

handle_sqlite_create_user :: proc "c" (e : ^webui.Event) {
    ctx, err := services.init_context(e)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    // Parse user from JSON
    user_json := webui.webui_event_get_string(e)
    user := deserialize_user(user_json)
    
    // Validate
    if user.name == "" || user.email == "" {
        services.ctx_respond_error(&ctx, "Name and email required")
        return
    }
    
    // Create user
    id, err := services.sqlite_create_user(&sqlite_service, &user)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    services.ctx_respond_success(&ctx, fmt.Sprintf(`{"id":%d}`, id))
}

handle_sqlite_update_user :: proc "c" (e : ^webui.Event) {
    ctx, err := services.init_context(e)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    // Parse user from JSON
    user_json := webui.webui_event_get_string(e)
    user := deserialize_user(user_json)
    
    // Update user
    err = services.sqlite_update_user(&sqlite_service, &user)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    services.ctx_respond_success(&ctx, `{"success":true}`)
}

handle_sqlite_delete_user :: proc "c" (e : ^webui.Event) {
    ctx, err := services.init_context(e)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    // Get user ID
    user_id_str := webui.webui_event_get_string(e)
    user_id := atoi(user_id_str)
    
    // Delete user
    err = services.sqlite_delete_user(&sqlite_service, user_id)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    services.ctx_respond_success(&ctx, `{"success":true}`)
}
```

---

## Frontend Integration

### Angular Service

```typescript
import { Injectable, inject } from '@angular/core';
import { ApiService } from '../core/api.service';
import { LoggerService } from '../core/logger.service';

export interface User {
  id: number;
  name: string;
  email: string;
  age: number;
  created_at: string;
}

export interface UserStats {
  total_users: number;
  today_count: number;
  unique_domains: number;
}

@Injectable({
  providedIn: 'root'
})
export class SQLiteService {
  private readonly api = inject(ApiService);
  private readonly logger = inject(LoggerService);

  async getUsers(): Promise<User[]> {
    return await this.api.callOrThrow<User[]>('sqlite:getUsers');
  }

  async createUser(user: Partial<User>): Promise<{ id: number }> {
    return await this.api.callOrThrow('sqlite:createUser', [user]);
  }

  async updateUser(user: User): Promise<void> {
    await this.api.callOrThrow('sqlite:updateUser', [user]);
  }

  async deleteUser(userId: number): Promise<void> {
    await this.api.callOrThrow('sqlite:deleteUser', [userId]);
  }

  async getUserStats(): Promise<UserStats> {
    return await this.api.callOrThrow<UserStats>('sqlite:getUserStats');
  }
}
```

### Angular Component

See [SQLite Components Guide](../frontend/sqlite-components.md) for complete component implementations.

---

## Production Considerations

### 1. Transaction Support

```odin
sqlite_transaction :: proc(svc: ^SQLite_Service, callback: proc(^SQLite_Service) -> Error) -> Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Begin transaction
    result := sqlite3_exec(svc.database, "BEGIN TRANSACTION", nil, nil, nil)
    if result != SQLITE_OK {
        return Error{code: .Database_Error, message: "Failed to begin transaction"}
    }
    
    // Execute callback
    err := callback(svc)
    
    if err.code != .None {
        // Rollback on error
        sqlite3_exec(svc.database, "ROLLBACK", nil, nil, nil)
        return err
    }
    
    // Commit transaction
    result = sqlite3_exec(svc.database, "COMMIT", nil, nil, nil)
    if result != SQLITE_OK {
        return Error{code: .Database_Error, message: "Failed to commit transaction"}
    }
    
    return Error{code: .None}
}

// Usage example
err := sqlite_transaction(&sqlite_service, proc(svc: ^SQLite_Service) -> Error {
    // Multiple operations here
    _, err = sqlite_create_user(svc, &user1)
    if err.code != .None { return err }
    
    _, err = sqlite_create_user(svc, &user2)
    if err.code != .None { return err }
    
    return Error{code: .None}
})
```

### 2. Error Handling

- Always use mutex locks for thread safety
- Return structured errors with codes
- Log all database errors
- Handle SQLITE_BUSY and SQLITE_LOCKED gracefully

### 3. Performance Optimization

- Use prepared statements for repeated queries
- Batch operations in transactions
- Create indexes on frequently queried columns
- Use WAL (Write-Ahead Logging) mode for better concurrency

```odin
// Enable WAL mode
sqlite3_exec(svc.database, "PRAGMA journal_mode = WAL", nil, nil, nil)

// Create indexes
sqlite3_exec(svc.database, "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)", nil, nil, nil)
sqlite3_exec(svc.database, "CREATE INDEX IF NOT EXISTS idx_users_created ON users(created_at)", nil, nil, nil)
```

### 4. Security

- Use parameterized queries (prevent SQL injection)
- Validate all input data
- Implement access control
- Encrypt sensitive data if needed

---

## Testing

### Unit Tests

```odin
test_sqlite_create_user :: proc() -> bool {
    svc := init_test_service()
    defer cleanup_test_service(&svc)
    
    user := User{
        name: "Test User",
        email: "test@example.com",
        age: 30
    }
    
    id, err := sqlite_create_user(&svc, &user)
    
    if err.code != .None {
        return false
    }
    
    if id <= 0 {
        return false
    }
    
    return true
}

test_sqlite_transaction :: proc() -> bool {
    svc := init_test_service()
    defer cleanup_test_service(&svc)
    
    success := true
    
    err := sqlite_transaction(&svc, proc(s: ^SQLite_Service) -> Error {
        _, e := sqlite_create_user(s, &user1)
        if e.code != .None { return e }
        
        _, e = sqlite_create_user(s, &user2)
        if e.code != .None { return e }
        
        return Error{code: .None}
    })
    
    if err.code != .None {
        success = false
    }
    
    return success
}
```

### Integration Tests

```typescript
describe('SQLiteService', () => {
  it('should create and retrieve a user', async () => {
    const user = { name: 'Test', email: 'test@example.com', age: 30 };
    const result = await service.createUser(user);
    expect(result.id).toBeDefined();
    
    const users = await service.getUsers();
    expect(users.length).toBeGreaterThan(0);
  });

  it('should update a user', async () => {
    const user = await service.createUser({ 
      name: 'Test', 
      email: 'test@example.com', 
      age: 30 
    });
    
    await service.updateUser({ ...user, name: 'Updated' });
    
    const users = await service.getUsers();
    expect(users.find(u => u.id === user.id)?.name).toBe('Updated');
  });
});
```

---

## Troubleshooting

### Common Issues

**1. Database locked**
```odin
// Enable busy timeout
sqlite3_busy_timeout(svc.database, 5000)  // 5 seconds
```

**2. Database file not found**
```bash
# Ensure build/ directory exists
mkdir -p build
# Database will be created automatically
```

**3. Transaction rollback**
```odin
// Always check for errors in transaction
err := sqlite_transaction(&svc, proc(svc: ^SQLite_Service) -> Error {
    // Your operations
})
if err.code != .None {
    // Transaction was rolled back
}
```

---

## DuckDB vs SQLite

| Feature | DuckDB | SQLite |
|---------|--------|--------|
| **Best For** | Analytics | Transactions |
| **Storage** | Columnar | Row-based |
| **Performance** | OLAP queries | OLTP operations |
| **Concurrency** | Read-heavy | Read-write |
| **File Size** | Larger | Smaller |
| **Memory** | Higher | Lower |

### When to Use Each

**Use DuckDB when:**
- Running complex analytical queries
- Processing large datasets
- Need columnar storage benefits
- Building data warehouses

**Use SQLite when:**
- Building transactional applications
- Need ACID compliance
- Require minimal footprint
- Embedded/local storage needed

---

## Resources

- [SQLite Official Documentation](https://www.sqlite.org/docs.html)
- [SQLite Odin Bindings](https://github.com/sqlite/sqlite)
- [Frontend Components](../frontend/sqlite-components.md)
- [CRUD Operations Guide](../guides/crud-operations-guide.md)
- [DuckDB Integration](./duckdb-integration.md)

---

**Last Updated:** 2026-03-30
**Status:** Production Ready
