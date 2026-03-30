# Production DuckDB Integration Guide

**Complete guide for integrating DuckDB with Odin backend and Angular frontend**

---

## Overview

This guide covers **production-ready DuckDB integration** for analytical workloads, providing complete CRUD operations with real-time updates and query building capabilities.

### Use Cases

- **Analytical Queries**: Complex aggregations and data analysis
- **Data Warehousing**: Large-scale data storage and retrieval
- **Real-time Analytics**: Live dashboard updates
- **Query Building**: Dynamic SQL construction and execution

---

## Architecture

```
+------------------+     WebSocket     +------------------+
|  Angular         |◄─────────────────►|  WebUI Bridge    |
|  Frontend        |                   |  (Civetweb)      |
|                  |                   +--------+---------+
|  - DuckDB Demo   |                            |
|  - Query Builder |                            | FFI
|  - Analytics     |                            v
+------------------+                   +------------------+
                                       |  Odin Backend    |
                                       |                  |
                                       |  - DuckDB Svc    |
                                       |  - Handlers      |
                                       |  - Serialization |
                                       +--------+---------+
                                                |
                                                | SQL
                                                v
                                       +------------------+
                                       |  DuckDB          |
                                       |  (Embedded)      |
                                       +------------------+
```

---

## Backend Implementation

### 1. DuckDB Service Structure

```odin
package services

import "core:fmt"
import "core:sync"
import "../lib/webui_lib"

// DuckDB Service
DuckDB_Service :: struct {
    mutex      : sync.Mutex,
    connection : rawptr,  // DuckDB connection
    database   : rawptr,  // DuckDB database
}

// Initialize DuckDB service
init_duckdb_service :: proc() -> (DuckDB_Service, Error) {
    svc := DuckDB_Service{}
    
    // Open database (creates file if not exists)
    db_path := "build/duckdb.db"
    result := duckdb_open(db_path, &svc.database)
    
    if result != DUCKDB_SUCCESS {
        return svc, Error{code: .Database_Error, message: "Failed to open DuckDB"}
    }
    
    // Create connection
    result = duckdb_connect(svc.database, &svc.connection)
    if result != DUCKDB_SUCCESS {
        duckdb_close(svc.database)
        return svc, Error{code: .Database_Error, message: "Failed to connect"}
    }
    
    // Initialize schema
    err := initialize_schema(&svc)
    if err.code != .None {
        return svc, err
    }
    
    return svc, Error{code: .None}
}

// Initialize database schema
initialize_schema :: proc(svc: ^DuckDB_Service) -> Error {
    create_table_sql := `
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name VARCHAR NOT NULL,
            email VARCHAR UNIQUE NOT NULL,
            age INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `
    
    result := duckdb_query(svc.connection, create_table_sql, nil)
    if result != DUCKDB_SUCCESS {
        return Error{code: .Database_Error, message: "Failed to create users table"}
    }
    
    return Error{code: .None}
}
```

### 2. CRUD Operations

#### Create User

```odin
duckdb_create_user :: proc(svc: ^DuckDB_Service, user: ^User) -> (int, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Prepare statement
    var stmt : DuckDB_Statement
    sql := "INSERT INTO users (name, email, age) VALUES (?, ?, ?)"
    
    result := duckdb_prepare(svc.connection, sql, &stmt)
    if result != DUCKDB_SUCCESS {
        return 0, Error{code: .Database_Error, message: "Failed to prepare statement"}
    }
    defer duckdb_destroy_prepare(&stmt)
    
    // Bind parameters
    duckdb_bind_varchar(stmt, 1, user.name)
    duckdb_bind_varchar(stmt, 2, user.email)
    duckdb_bind_int32(stmt, 3, user.age)
    
    // Execute
    result = duckdb_execute_prepared(stmt, nil)
    if result != DUCKDB_SUCCESS {
        return 0, Error{code: .Database_Error, message: "Failed to insert user"}
    }
    
    // Get last inserted ID
    last_id := duckdb_last_insert_rowid(svc.connection)
    
    return int(last_id), Error{code: .None}
}
```

#### Read Users

```odin
duckdb_get_users :: proc(svc: ^DuckDB_Service) -> ([]User, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var result : DuckDB_Result
    sql := "SELECT id, name, email, age, created_at FROM users ORDER BY created_at DESC"
    
    query_result := duckdb_query(svc.connection, sql, &result)
    if query_result != DUCKDB_SUCCESS {
        return nil, Error{code: .Database_Error, message: "Failed to query users"}
    }
    defer duckdb_destroy_result(&result)
    
    row_count := int(duckdb_row_count(&result))
    users := make([]User, row_count)
    
    for i in 0..<row_count {
        users[i].id = int(duckdb_value_int32(&result, 0, i))
        users[i].name = string(duckdb_value_varchar(&result, 1, i))
        users[i].email = string(duckdb_value_varchar(&result, 2, i))
        users[i].age = int(duckdb_value_int32(&result, 3, i))
        users[i].created_at = string(duckdb_value_varchar(&result, 4, i))
    }
    
    return users, Error{code: .None}
}
```

#### Update User

```odin
duckdb_update_user :: proc(svc: ^DuckDB_Service, user: ^User) -> Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var stmt : DuckDB_Statement
    sql := "UPDATE users SET name = ?, email = ?, age = ? WHERE id = ?"
    
    result := duckdb_prepare(svc.connection, sql, &stmt)
    if result != DUCKDB_SUCCESS {
        return Error{code: .Database_Error, message: "Failed to prepare statement"}
    }
    defer duckdb_destroy_prepare(&stmt)
    
    // Bind parameters
    duckdb_bind_varchar(stmt, 1, user.name)
    duckdb_bind_varchar(stmt, 2, user.email)
    duckdb_bind_int32(stmt, 3, user.age)
    duckdb_bind_int32(stmt, 4, user.id)
    
    // Execute
    result = duckdb_execute_prepared(stmt, nil)
    if result != DUCKDB_SUCCESS {
        return Error{code: .Database_Error, message: "Failed to update user"}
    }
    
    return Error{code: .None}
}
```

#### Delete User

```odin
duckdb_delete_user :: proc(svc: ^DuckDB_Service, user_id: int) -> Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var stmt : DuckDB_Statement
    sql := "DELETE FROM users WHERE id = ?"
    
    result := duckdb_prepare(svc.connection, sql, &stmt)
    if result != DUCKDB_SUCCESS {
        return Error{code: .Database_Error, message: "Failed to prepare statement"}
    }
    defer duckdb_destroy_prepare(&stmt)
    
    // Bind parameter
    duckdb_bind_int32(stmt, 1, int32(user_id))
    
    // Execute
    result = duckdb_execute_prepared(stmt, nil)
    if result != DUCKDB_SUCCESS {
        return Error{code: .Database_Error, message: "Failed to delete user"}
    }
    
    return Error{code: .None}
}
```

### 3. Query Builder Support

```odin
duckdb_execute_query :: proc(svc: ^DuckDB_Service, sql: string) -> (string, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Validate SQL (prevent DROP, TRUNCATE, etc.)
    if !is_safe_query(sql) {
        return "", Error{code: .Security_Error, message: "Unsafe query detected"}
    }
    
    var result : DuckDB_Result
    query_result := duckdb_query(svc.connection, sql, &result)
    
    if query_result != DUCKDB_SUCCESS {
        return "", Error{code: .Database_Error, message: "Query execution failed"}
    }
    defer duckdb_destroy_result(&result)
    
    // Convert result to JSON
    json_result := result_to_json(&result)
    
    return json_result, Error{code: .None}
}

// Validate SQL query for safety
is_safe_query :: proc(sql: string) -> bool {
    upper_sql := string_to_upper(sql)
    
    // Block dangerous operations
    dangerous := []string{"DROP", "TRUNCATE", "DELETE FROM users WHERE 1=1"}
    
    for pattern in dangerous {
        if contains(upper_sql, pattern) {
            return false
        }
    }
    
    return true
}
```

### 4. Analytics Functions

```odin
duckdb_get_user_stats :: proc(svc: ^DuckDB_Service) -> (UserStats, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    stats := UserStats{}
    
    // Total users
    total_sql := "SELECT COUNT(*) FROM users"
    var total_result : DuckDB_Result
    duckdb_query(svc.connection, total_sql, &total_result)
    stats.total_users = int(duckdb_value_int32(&total_result, 0, 0))
    duckdb_destroy_result(&total_result)
    
    // Users created today
    today_sql := "SELECT COUNT(*) FROM users WHERE DATE(created_at) = DATE('now')"
    var today_result : DuckDB_Result
    duckdb_query(svc.connection, today_sql, &today_result)
    stats.today_count = int(duckdb_value_int32(&today_result, 0, 0))
    duckdb_destroy_result(&today_result)
    
    // Unique email domains
    domains_sql := "SELECT COUNT(DISTINCT SUBSTR(email, INSTR(email, '@') + 1)) FROM users"
    var domains_result : DuckDB_Result
    duckdb_query(svc.connection, domains_sql, &domains_result)
    stats.unique_domains = int(duckdb_value_int32(&domains_result, 0, 0))
    duckdb_destroy_result(&domains_result)
    
    return stats, Error{code: .None}
}
```

---

## WebUI Handlers

### Handler Registration

```odin
package main

import services "../services"

init_duckdb_handlers :: proc() {
    // CRUD operations
    webui.bind(window, "getUsers", handle_get_users)
    webui.bind(window, "createUser", handle_create_user)
    webui.bind(window, "updateUser", handle_update_user)
    webui.bind(window, "deleteUser", handle_delete_user)
    
    // Analytics
    webui.bind(window, "getUserStats", handle_get_user_stats)
    
    // Query builder
    webui.bind(window, "executeQuery", handle_execute_query)
}
```

### Handler Implementations

```odin
handle_get_users :: proc "c" (e : ^webui.Event) {
    ctx, err := services.init_context(e)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    users, err := services.duckdb_get_users(&duckdb_service)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    // Serialize to JSON
    json := serialize_users(users)
    services.ctx_respond_success_raw(&ctx, json)
}

handle_create_user :: proc "c" (e : ^webui.Event) {
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
    id, err := services.duckdb_create_user(&duckdb_service, &user)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    services.ctx_respond_success(&ctx, fmt.Sprintf(`{"id":%d}`, id))
}

handle_execute_query :: proc "c" (e : ^webui.Event) {
    ctx, err := services.init_context(e)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    // Get SQL query
    sql := webui.webui_event_get_string(e)
    
    // Execute query
    result, err := services.duckdb_execute_query(&duckdb_service, sql)
    if err.code != .None {
        services.ctx_respond_error(&ctx, err.message)
        return
    }
    
    services.ctx_respond_success_raw(&ctx, result)
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
export class DuckDBService {
  private readonly api = inject(ApiService);
  private readonly logger = inject(LoggerService);

  async getUsers(): Promise<User[]> {
    return await this.api.callOrThrow<User[]>('getUsers');
  }

  async createUser(user: Partial<User>): Promise<{ id: number }> {
    return await this.api.callOrThrow('createUser', [user]);
  }

  async updateUser(user: User): Promise<void> {
    await this.api.callOrThrow('updateUser', [user]);
  }

  async deleteUser(userId: number): Promise<void> {
    await this.api.callOrThrow('deleteUser', [userId]);
  }

  async getUserStats(): Promise<UserStats> {
    return await this.api.callOrThrow<UserStats>('getUserStats');
  }

  async executeQuery(sql: string): Promise<any> {
    return await this.api.callOrThrow('executeQuery', [sql]);
  }
}
```

### Angular Component

See [DuckDB Components Guide](../frontend/duckdb-components.md) for complete component implementations.

---

## Production Considerations

### 1. Connection Pooling

```odin
// For high-concurrency scenarios
Connection_Pool :: struct {
    connections : []DuckDB_Connection,
    mutex       : sync.Mutex,
    available   : []int,
}
```

### 2. Error Handling

- Always use mutex locks for thread safety
- Return structured errors with codes
- Log all database errors
- Implement retry logic for transient failures

### 3. Performance Optimization

- Use prepared statements for repeated queries
- Batch insert operations when possible
- Index frequently queried columns
- Use DuckDB's columnar storage for analytics

### 4. Security

- Validate all SQL queries (prevent injection)
- Use parameterized queries
- Implement row-level security if needed
- Audit all database operations

---

## Testing

### Unit Tests

```odin
test_duckdb_create_user :: proc() -> bool {
    svc := init_test_service()
    defer cleanup_test_service(&svc)
    
    user := User{
        name: "Test User",
        email: "test@example.com",
        age: 30
    }
    
    id, err := duckdb_create_user(&svc, &user)
    
    if err.code != .None {
        return false
    }
    
    if id <= 0 {
        return false
    }
    
    return true
}
```

### Integration Tests

```typescript
describe('DuckDBService', () => {
  it('should create and retrieve a user', async () => {
    const user = { name: 'Test', email: 'test@example.com', age: 30 };
    const result = await service.createUser(user);
    expect(result.id).toBeDefined();
    
    const users = await service.getUsers();
    expect(users.length).toBeGreaterThan(0);
  });
});
```

---

## Troubleshooting

### Common Issues

**1. Database file not found**
```bash
# Ensure build/ directory exists
mkdir -p build
# Database will be created automatically
```

**2. Lock contention**
```odin
// Use read-write locks for read-heavy workloads
mutex : sync.RW_Mutex
```

**3. Memory issues**
```odin
// Always destroy results
defer duckdb_destroy_result(&result)
```

---

## Resources

- [DuckDB Official Documentation](https://duckdb.org/docs/)
- [DuckDB Odin Bindings](https://github.com/duckdb/duckdb)
- [Frontend Components](../frontend/duckdb-components.md)
- [CRUD Operations Guide](../guides/crud-operations-guide.md)

---

**Last Updated:** 2026-03-30
**Status:** Production Ready
