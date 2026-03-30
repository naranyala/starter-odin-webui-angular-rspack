# Complete CRUD Operations Guide

**End-to-end tutorial for implementing Create, Read, Update, Delete operations with DuckDB and SQLite**

---

## Overview

This guide provides a **complete walkthrough** of implementing production-ready CRUD operations using DuckDB and SQLite databases with an Odin backend and Angular frontend.

### What You'll Learn

- Setting up database connections
- Implementing CRUD operations in Odin
- Creating Angular components
- Handling errors and validation
- Best practices for production

---

## Prerequisites

- Odin compiler installed
- Bun or Node.js installed
- Basic knowledge of TypeScript and Odin
- Project setup complete (see [Quick Start](../../QUICKSTART.md))

---

## Part 1: Database Setup

### Step 1: Choose Your Database

| Database | Best For | File Location |
|----------|----------|---------------|
| **DuckDB** | Analytics, complex queries | `build/duckdb.db` |
| **SQLite** | Transactions, simple operations | `build/sqlite.db` |

### Step 2: Initialize Database Service

#### DuckDB Service

```odin
package services

import "core:sync"

DuckDB_Service :: struct {
    mutex      : sync.Mutex,
    connection : rawptr,
    database   : rawptr,
}

init_duckdb_service :: proc() -> (DuckDB_Service, Error) {
    svc := DuckDB_Service{}
    
    // Open database
    db_path := "build/duckdb.db"
    result := duckdb_open(db_path, &svc.database)
    
    if result != DUCKDB_SUCCESS {
        return svc, Error{code: .Database_Error, message: "Failed to open DuckDB"}
    }
    
    // Create connection
    result = duckdb_connect(svc.database, &svc.connection)
    
    // Initialize schema
    initialize_schema(&svc)
    
    return svc, Error{code: .None}
}

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
        return Error{code: .Database_Error, message: "Failed to create table"}
    }
    
    return Error{code: .None}
}
```

#### SQLite Service

```odin
package services

import "core:sync"

SQLite_Service :: struct {
    mutex      : sync.Mutex,
    database   : rawptr,
}

init_sqlite_service :: proc() -> (SQLite_Service, Error) {
    svc := SQLite_Service{}
    
    // Open database
    db_path := "build/sqlite.db"
    result := sqlite3_open(db_path, &svc.database)
    
    if result != SQLITE_OK {
        return svc, Error{code: .Database_Error, message: "Failed to open SQLite"}
    }
    
    // Initialize schema
    initialize_schema(&svc)
    
    return svc, Error{code: .None}
}

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
        return Error{code: .Database_Error, message: "Failed to create table"}
    }
    
    return Error{code: .None}
}
```

---

## Part 2: Backend CRUD Operations

### Create Operation

#### DuckDB - Create User

```odin
duckdb_create_user :: proc(svc: ^DuckDB_Service, user: ^User) -> (int, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
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
    
    last_id := duckdb_last_insert_rowid(svc.connection)
    return int(last_id), Error{code: .None}
}
```

#### SQLite - Create User

```odin
sqlite_create_user :: proc(svc: ^SQLite_Service, user: ^User) -> (int, Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    var stmt : rawptr
    sql := "INSERT INTO users (name, email, age) VALUES (?, ?, ?)"
    
    result := sqlite3_prepare_v2(svc.database, sql, -1, &stmt, nil)
    if result != SQLITE_OK {
        return 0, Error{code: .Database_Error, message: "Failed to prepare statement"}
    }
    defer sqlite3_finalize(stmt)
    
    // Bind parameters
    sqlite3_bind_text(stmt, 1, user.name, -1, SQLITE_TRANSIENT)
    sqlite3_bind_text(stmt, 2, user.email, -1, SQLITE_TRANSIENT)
    sqlite3_bind_int(stmt, 3, int32(user.age))
    
    // Execute
    result = sqlite3_step(stmt)
    if result != SQLITE_DONE {
        return 0, Error{code: .Database_Error, message: "Failed to insert user"}
    }
    
    last_id := sqlite3_last_insert_rowid(svc.database)
    return int(last_id), Error{code: .None}
}
```

### Read Operation

#### Get All Users

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

### Update Operation

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

### Delete Operation

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

---

## Part 3: WebUI Handlers

### Handler Registration

```odin
package main

import services "../services"

init_crud_handlers :: proc() {
    // DuckDB handlers
    webui.bind(window, "getUsers", handle_get_users)
    webui.bind(window, "createUser", handle_create_user)
    webui.bind(window, "updateUser", handle_update_user)
    webui.bind(window, "deleteUser", handle_delete_user)
    webui.bind(window, "getUserStats", handle_get_user_stats)
    
    // SQLite handlers (with prefix to avoid conflicts)
    webui.bind(window, "sqlite:getUsers", handle_sqlite_get_users)
    webui.bind(window, "sqlite:createUser", handle_sqlite_create_user)
    webui.bind(window, "sqlite:updateUser", handle_sqlite_update_user)
    webui.bind(window, "sqlite:deleteUser", handle_sqlite_delete_user)
}
```

### Handler Implementation Example

```odin
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
```

---

## Part 4: Frontend Implementation

### Angular Service

```typescript
import { Injectable, inject } from '@angular/core';
import { ApiService } from '../core/api.service';

export interface User {
  id: number;
  name: string;
  email: string;
  age: number;
  created_at: string;
}

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private readonly api = inject(ApiService);

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
}
```

### Angular Component

```typescript
import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserService, User } from './user.service';

@Component({
  selector: 'app-user-crud',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="crud-container">
      <h1>User Management</h1>
      
      <!-- Create Form -->
      <form (ngSubmit)="createUser()">
        <input [(ngModel)]="newUser.name" name="name" placeholder="Name" required />
        <input [(ngModel)]="newUser.email" name="email" placeholder="Email" required />
        <input [(ngModel)]="newUser.age" name="age" type="number" placeholder="Age" required />
        <button type="submit" [disabled]="isLoading()">Create User</button>
      </form>
      
      <!-- User List -->
      <div class="user-list">
        @for (user of users(); track user.id) {
          <div class="user-item">
            <span>{{ user.name }} - {{ user.email }}</span>
            <button (click)="deleteUser(user.id)">Delete</button>
          </div>
        }
      </div>
    </div>
  `
})
export class UserCrudComponent implements OnInit {
  private readonly userService = inject(UserService);
  
  users = signal<User[]>([]);
  newUser = signal<Partial<User>>({ name: '', email: '', age: 25 });
  isLoading = signal(false);

  async ngOnInit(): Promise<void> {
    await this.loadUsers();
  }

  async loadUsers(): Promise<void> {
    this.isLoading.set(true);
    try {
      const users = await this.userService.getUsers();
      this.users.set(users);
    } finally {
      this.isLoading.set(false);
    }
  }

  async createUser(): Promise<void> {
    if (!this.newUser().name || !this.newUser().email) {
      return;
    }

    this.isLoading.set(true);
    try {
      await this.userService.createUser(this.newUser());
      this.newUser.set({ name: '', email: '', age: 25 });
      await this.loadUsers();
    } finally {
      this.isLoading.set(false);
    }
  }

  async deleteUser(userId: number): Promise<void> {
    if (!confirm('Delete this user?')) {
      return;
    }

    this.isLoading.set(true);
    try {
      await this.userService.deleteUser(userId);
      await this.loadUsers();
    } finally {
      this.isLoading.set(false);
    }
  }
}
```

---

## Part 5: Testing

### Backend Tests

```odin
test_crud_operations :: proc() -> bool {
    svc := init_duckdb_service()
    defer cleanup_duckdb_service(&svc)
    
    // Test Create
    user := User{
        name: "Test User",
        email: "test@example.com",
        age: 30
    }
    
    id, err := duckdb_create_user(&svc, &user)
    if err.code != .None || id <= 0 {
        return false
    }
    
    // Test Read
    users, err := duckdb_get_users(&svc)
    if err.code != .None || len(users) == 0 {
        return false
    }
    
    // Test Update
    user.id = id
    user.name = "Updated User"
    err = duckdb_update_user(&svc, &user)
    if err.code != .None {
        return false
    }
    
    // Test Delete
    err = duckdb_delete_user(&svc, id)
    if err.code != .None {
        return false
    }
    
    return true
}
```

### Frontend Tests

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserCrudComponent } from './user-crud.component';
import { UserService } from './user.service';

describe('UserCrudComponent', () => {
  let component: UserCrudComponent;
  let fixture: ComponentFixture<UserCrudComponent>;
  let userService: jasmine.SpyObj<UserService>;

  beforeEach(async () => {
    const serviceSpy = jasmine.createSpyObj('UserService', ['getUsers', 'createUser', 'deleteUser']);
    
    await TestBed.configureTestingModule({
      imports: [UserCrudComponent],
      providers: [{ provide: UserService, useValue: serviceSpy }]
    }).compileComponents();

    fixture = TestBed.createComponent(UserCrudComponent);
    component = fixture.componentInstance;
    userService = TestBed.inject(UserService) as jasmine.SpyObj<UserService>;
  });

  it('should create component', () => {
    expect(component).toBeTruthy();
  });

  it('should load users on init', async () => {
    userService.getUsers.and.resolveTo([
      { id: 1, name: 'Test', email: 'test@example.com', age: 30, created_at: '' }
    ]);
    
    component.ngOnInit();
    await fixture.whenStable();
    
    expect(component.users().length).toBe(1);
  });

  it('should create user', async () => {
    userService.createUser.and.resolveTo({ id: 1 });
    userService.getUsers.and.resolveTo([]);
    
    component.newUser.set({ name: 'Test', email: 'test@example.com', age: 30 });
    await component.createUser();
    
    expect(userService.createUser).toHaveBeenCalled();
  });
});
```

---

## Best Practices

### 1. Thread Safety

```odin
// Always lock mutex for database operations
sync.lock(&svc.mutex)
defer sync.unlock(&svc.mutex)
```

### 2. Error Handling

```typescript
try {
  const result = await this.api.callOrThrow('operation', [params]);
} catch (error) {
  this.logger.error('Operation failed', error);
  // Show user-friendly message
}
```

### 3. Validation

```odin
// Backend validation
if user.name == "" || user.email == "" {
    return Error{code: .Validation_Error, message: "Name and email required"}
}
```

```typescript
// Frontend validation
if (!this.newUser().name || !this.newUser().email) {
  this.logger.warn('Validation failed');
  return;
}
```

### 4. Prepared Statements

```odin
// Always use prepared statements to prevent SQL injection
var stmt : DuckDB_Statement
duckdb_prepare(svc.connection, sql, &stmt)
duckdb_bind_varchar(stmt, 1, user.name)
```

### 5. Resource Cleanup

```odin
// Always destroy prepared statements and results
defer duckdb_destroy_prepare(&stmt)
defer duckdb_destroy_result(&result)
```

---

## Troubleshooting

### Common Issues

**1. Database locked**
```odin
// Enable busy timeout for SQLite
sqlite3_busy_timeout(svc.database, 5000)
```

**2. Type mismatch between frontend/backend**
```typescript
// Ensure TypeScript interface matches Odin struct
// Frontend: created_at: string
// Backend: created_at: string (ISO 8601)
```

**3. Event not firing**
```odin
// Check WebUI binding
webui.bind(window, "myFunction", handle_my_function)
```

---

## Next Steps

- Read [DuckDB Integration Guide](../backend/duckdb-integration.md) for advanced features
- Read [SQLite Integration Guide](../backend/sqlite-integration.md) for transaction support
- Explore [DuckDB Components](../frontend/duckdb-components.md) for UI examples
- Explore [SQLite Components](../frontend/sqlite-components.md) for UI examples

---

**Last Updated:** 2026-03-30
**Status:** Production Ready
