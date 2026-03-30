# Refactored Architecture Guide

**Production-Ready Structure for Long-Term Maintainability**

**Date:** 2026-03-30
**Status:** ✅ Implemented

---

## Overview

This document describes the **refactored architecture** designed for long-term maintainability, scalability, and developer experience. The refactoring focuses on:

1. **Modular Backend** - Clean separation of concerns
2. **Reusable Frontend Components** - DRY principle
3. **Type Safety** - End-to-end type consistency
4. **Error Handling** - Comprehensive error management
5. **Documentation** - Clear, maintainable docs

---

## Backend Architecture

### New Structure

```
src/
├── lib/                      # Core libraries
│   ├── database/             # NEW: Database abstraction layer
│   │   ├── database_service.odin
│   │   ├── duckdb_impl.odin
│   │   └── sqlite_impl.odin
│   ├── crud/                 # NEW: Generic CRUD operations
│   │   └── crud_service.odin
│   ├── di/                   # Dependency injection
│   ├── events/               # Event bus
│   ├── errors/               # Error handling
│   ├── utils/                # Utilities
│   └── webui_lib/            # WebUI bindings
│
├── services/                 # Business logic services
│   ├── user_service.odin
│   ├── product_service.odin
│   ├── order_service.odin
│   └── auth_service.odin
│
├── handlers/                 # WebUI event handlers
│   ├── user_handlers.odin
│   ├── product_handlers.odin
│   └── query_handlers.odin
│
├── models/                   # Data models
│   ├── user.odin
│   ├── product.odin
│   └── order.odin
│
└── core/                     # Application core
    └── main.odin
```

### Database Abstraction Layer

**File:** `src/lib/database/database_service.odin`

Provides a unified interface for DuckDB and SQLite:

```odin
// Unified connection management
conn := database.init_connection(.DuckDB, "build/duckdb.db")
defer database.close_connection(&conn)

// Type-safe queries
result := database.execute_prepared(&conn, "SELECT * FROM users WHERE id = ?", user_id)

// Transaction support
database.begin_transaction(&conn, .{isolation_level = .Read_Committed})
// ... operations
database.commit_transaction(&conn)
```

**Benefits:**
- ✅ Single interface for multiple databases
- ✅ Easy to switch between DuckDB/SQLite
- ✅ Built-in SQL injection prevention
- ✅ Transaction management
- ✅ Connection pooling ready

### CRUD Service Layer

**File:** `src/lib/crud/crud_service.odin`

Generic CRUD operations for any entity:

```odin
// Initialize CRUD service
crud_svc := crud.init_crud_service(&db_conn, &event_bus)

// Type-safe CRUD operations
user_id, err := crud.create(&crud_svc, &user, "users")
user, err := crud.get_by_id(&crud_svc, user_id, "users")
err := crud.update(&crud_svc, &user, "users")
err := crud.delete(&crud_svc, user_id, "users")

// Query operations
count, err := crud.count(&crud_svc, "users", "age > 25")
exists, err := crud.exists(&crud_svc, user_id, "users")
```

**Benefits:**
- ✅ DRY - No repeated CRUD code
- ✅ Built-in audit logging
- ✅ Event publishing
- ✅ Validation hooks
- ✅ Consistent error handling

### Service Layer Pattern

Each business entity has a dedicated service:

```odin
// src/services/user_service.odin
User_Service :: struct {
    crud        : ^crud.CRUD_Service,
    validator   : ^validation.Validator,
}

user_service_create :: proc(svc: ^User_Service, user: ^User) -> (int, errors.Error) {
    // Business logic
    if err := svc.validator.validate(user); err.code != .None {
        return 0, err
    }
    
    // CRUD operation
    return crud.create(&svc.crud, user, "users")
}
```

---

## Frontend Architecture

### New Structure

```
frontend/src/
├── app/
│   ├── shared/               # Shared components
│   │   ├── components/       # Reusable UI components
│   │   │   ├── card.component.ts
│   │   │   ├── button.component.ts
│   │   │   ├── data-table.component.ts
│   │   │   └── index.ts
│   │   ├── directives/       # Custom directives
│   │   └── pipes/            # Custom pipes
│   │
│   ├── features/             # Feature modules
│   │   ├── crud/             # CRUD features
│   │   │   ├── duckdb-crud-refined.component.ts
│   │   │   ├── sqlite-crud-refined.component.ts
│   │   │   └── index.ts
│   │   ├── auth/             # Authentication
│   │   └── analytics/        # Analytics
│   │
│   └── core/                 # Core services (existing)
│
├── views/                    # Legacy views (being migrated)
│   ├── demo/
│   ├── duckdb/
│   └── sqlite/
│
└── models/                   # Type definitions
```

### Shared Component Library

#### Card Component

**File:** `app/shared/components/card.component.ts`

```typescript
<app-card
  [elevated]="true"
  [bordered]="false"
  [clickable]="false"
>
  <div card-header>Header Content</div>
  Main Content
  <div card-footer>Footer Content</div>
</app-card>
```

**Features:**
- ✅ Multiple variants (elevated, bordered, compact)
- ✅ Optional header/footer
- ✅ Clickable mode
- ✅ Content projection

#### Button Component

**File:** `app/shared/components/button.component.ts`

```typescript
<app-button
  variant="primary"
  size="large"
  icon="➕"
  [loading]="isLoading"
  [fullWidth]="true"
  (clicked)="onClick()"
>
  Save User
</app-button>
```

**Variants:**
- `primary` - Main actions
- `secondary` - Secondary actions
- `success` - Positive actions
- `danger` - Destructive actions
- `warning` - Warning actions
- `info` - Informational
- `ghost` - Minimal styling

**Features:**
- ✅ Loading state
- ✅ Icon support
- ✅ Disabled state
- ✅ Full width option
- ✅ Three sizes

#### Data Table Component

**File:** `app/shared/components/data-table.component.ts`

```typescript
<app-data-table
  [data]="users"
  [columns]="columns"
  [actions]="actions"
  [pagination]="true"
  [pageSize]="25"
  searchPlaceholder="Search users..."
  (rowClick)="onRowClick($event)"
/>
```

**Features:**
- ✅ Sorting (click headers)
- ✅ Pagination
- ✅ Search/filter
- ✅ Custom actions
- ✅ Custom cell templates
- ✅ Column piping (date, currency, etc.)
- ✅ Row selection
- ✅ Empty state

### Feature Components

Refactored CRUD components use shared components:

```typescript
@Component({...})
export class DuckDBCrudRefinedComponent {
  // Use shared components
  // Consistent styling
  // Better maintainability
}
```

**Benefits:**
- ✅ Consistent UI/UX
- ✅ Less code duplication
- ✅ Easier to maintain
- ✅ Better testing

---

## Error Handling

### Backend Errors

```odin
// Structured error types
Error :: struct {
    code    : Error_Code,
    message : string,
    details : string,
}

Error_Code :: enum {
    None,
    Validation_Error,
    Database_Error,
    Security_Error,
    Not_Found,
    Internal_Error,
}

// Usage
if err.code != .None {
    logger.error("Operation failed: %s", err.message)
    return nil, err
}
```

### Frontend Errors

```typescript
// Global error handler
@Injectable({providedIn: 'root'})
export class GlobalErrorHandler implements ErrorHandler {
  handleError(error: any): void {
    // Log error
    // Show user-friendly message
    // Send to monitoring
  }
}

// Error service
@Injectable({providedIn: 'root'})
export class ErrorService {
  showError(message: string): void {
    // Display toast/notification
  }
  
  handleApiError(error: any): void {
    // Parse error
    // Show appropriate message
  }
}
```

---

## Type Safety

### Shared Types

**Backend (Odin):**
```odin
User :: struct {
    id         : int,
    name       : string,
    email      : string,
    age        : int,
    created_at : string,
}
```

**Frontend (TypeScript):**
```typescript
export interface User {
  id: number;
  name: string;
  email: string;
  age: number;
  created_at: string;
}
```

**Benefits:**
- ✅ Compile-time type checking
- ✅ Autocomplete in IDE
- ✅ Refactoring safety
- ✅ API contract validation

---

## Best Practices

### Backend

1. **Use CRUD Service**
   ```odin
   // ✅ Good
   crud.create(&svc, entity, "table_name")
   
   // ❌ Bad
   database.execute_query(&conn, "INSERT INTO ...")
   ```

2. **Always Use Prepared Statements**
   ```odin
   // ✅ Good
   database.execute_prepared(&conn, "SELECT * FROM users WHERE id = ?", id)
   
   // ❌ Bad
   database.execute_query(&conn, fmt.Sprintf("SELECT * FROM users WHERE id = %d", id))
   ```

3. **Thread Safety**
   ```odin
   sync.lock(&svc.mutex)
   defer sync.unlock(&svc.mutex)
   ```

4. **Error Handling**
   ```odin
   if err.code != .None {
       return nil, err
   }
   ```

### Frontend

1. **Use Shared Components**
   ```typescript
   // ✅ Good
   <app-button variant="primary">Save</app-button>
   
   // ❌ Bad
   <button class="btn btn-primary">Save</button>
   ```

2. **Signal-Based State**
   ```typescript
   // ✅ Good
   users = signal<User[]>([]);
   users.set(newUsers);
   
   // ❌ Bad
   users: User[] = [];
   this.users = newUsers;
   ```

3. **Dependency Injection**
   ```typescript
   // ✅ Good
   private readonly service = inject(Service);
   
   // ❌ Bad
   private service = new Service();
   ```

4. **Error Handling**
   ```typescript
   try {
     await this.service.operation();
   } catch (error) {
     this.errorService.handleApiError(error);
   }
   ```

---

## Migration Guide

### Backend Migration

1. **Move existing code to new structure**
   ```bash
   # Move database code
   mv src/services/duckdb_service.odin src/lib/database/
   
   # Move CRUD operations
   mv src/handlers/*_handlers.odin src/services/
   ```

2. **Update imports**
   ```odin
   // Old
   import "../services/duckdb_service"
   
   // New
   import "../lib/database"
   ```

3. **Refactor to use CRUD service**
   ```odin
   // Replace direct SQL with CRUD operations
   crud.create(&svc, &user, "users")
   ```

### Frontend Migration

1. **Create shared components**
   ```bash
   mkdir -p app/shared/components
   ```

2. **Migrate existing components**
   ```typescript
   // Replace custom buttons with shared component
   // Replace custom tables with data-table component
   ```

3. **Update imports**
   ```typescript
   // Old
   import { ButtonComponent } from '../button.component';
   
   // New
   import { ButtonComponent } from '../../app/shared/components';
   ```

---

## Testing Strategy

### Backend Tests

```odin
test_crud_create_user :: proc() -> bool {
    svc := init_test_service()
    defer cleanup_test_service(&svc)
    
    user := User{name = "Test", email = "test@example.com"}
    id, err := crud.create(&svc.crud, &user, "users")
    
    return err.code == .None && id > 0
}
```

### Frontend Tests

```typescript
describe('DuckDBCrudRefinedComponent', () => {
  it('should create user', async () => {
    component.editingUser.set({ name: 'Test', email: 'test@example.com', age: 30 });
    await component.saveUser();
    expect(apiService.callOrThrow).toHaveBeenCalledWith('createUser', [...]);
  });
});
```

---

## Performance Considerations

### Backend

1. **Connection Pooling**
   ```odin
   pool := database.create_connection_pool(.DuckDB, 10)
   ```

2. **Prepared Statement Caching**
   ```odin
   stmt := database.get_prepared_statement(&conn, "SELECT * FROM users WHERE id = ?")
   ```

3. **Batch Operations**
   ```odin
   crud.create_batch(&svc, users, "users")
   ```

### Frontend

1. **OnPush Change Detection**
   ```typescript
   @Component({
     changeDetection: ChangeDetectionStrategy.OnPush
   })
   ```

2. **TrackBy in ngFor**
   ```typescript
   @for (item of items; track item.id) {
     <div>{{ item.name }}</div>
   }
   ```

3. **Lazy Loading**
   ```typescript
   const routes = [
     { path: 'crud', loadChildren: () => import('./crud/crud.routes') }
   ];
   ```

---

## Monitoring & Observability

### Logging

```odin
// Structured logging
log_info(&ctx, "User created", .{user_id = id, email = user.email})
```

### Metrics

```odin
// Track operation duration
start := time.now()
// ... operation
duration := time.since(start)
metrics.record("crud.create.duration", duration)
```

### Error Tracking

```typescript
// Send errors to monitoring
this.errorTracker.track(error, {
  context: 'DuckDBCrudComponent',
  action: 'saveUser'
});
```

---

## Resources

- [Database Service](../src/lib/database/database_service.odin)
- [CRUD Service](../src/lib/crud/crud_service.odin)
- [Shared Components](../frontend/src/app/shared/components/)
- [Feature Components](../frontend/src/app/features/)

---

**Last Updated:** 2026-03-30
**Status:** Production Ready
