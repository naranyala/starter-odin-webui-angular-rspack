# Architectural Decision Record (ADR) - CRUD Integration

**Date:** 2026-03-30
**Status:** Implemented
**Impact:** Production-ready DuckDB and SQLite CRUD integration

---

## Overview

This document explains the **rationale behind the CRUD-focused architecture** for the Odin WebUI Angular Rspack project. The documentation has been reorganized to focus on production-ready database integration patterns.

---

## Decision 1: Dual Database Support (DuckDB + SQLite)

### **Context**

Modern desktop applications require different database solutions for different use cases:
- **Analytical workloads**: Complex queries, aggregations, data warehousing
- **Transactional workloads**: ACID compliance, simple CRUD, embedded storage

### **Problem**

1. Single database solutions force compromises
2. Different use cases have different requirements
3. Developers need clear guidance on which database to use

### **Decision**

**Support both DuckDB and SQLite with dedicated integration guides and components.**

### **Implementation**

**Backend:**
- `duckdb_service.odin` - DuckDB operations
- `sqlite_service.odin` - SQLite operations
- Shared validation and serialization utilities

**Frontend:**
- `DuckdbDemoComponent` - Advanced analytics interface
- `SqliteCrudComponent` - Simple CRUD interface
- Shared services and utilities

**Documentation:**
- Separate integration guides for each database
- Component-specific guides
- Comparison matrix for decision-making

### **Consequences**

**Positive:**
- ✅ Developers can choose the right tool for the job
- ✅ Clear separation of concerns
- ✅ Production-ready patterns for both use cases
- ✅ Comprehensive documentation

**Negative:**
- ⚠️ Slightly larger codebase
- ⚠️ Need to maintain two sets of integration code

---

## Decision 2: Documentation Focused on CRUD Operations

### **Context**

Previous documentation covered general topics (DI, error handling, communication) that distracted from the core value proposition: **production-ready CRUD integration**.

### **Problem**

1. Developers couldn't quickly find CRUD implementation guides
2. General documentation diluted the focus
3. Too many abstract concepts, not enough concrete examples

### **Decision**

**Reorganize documentation to focus exclusively on DuckDB and SQLite CRUD integration.**

### **Implementation**

**Removed:**
- General DI system documentation
- Abstract error handling guides
- Communication pattern documentation
- Build system documentation
- Serialization evaluation documents

**Created:**
- `docs/backend/duckdb-integration.md` - Complete DuckDB guide
- `docs/backend/sqlite-integration.md` - Complete SQLite guide
- `docs/frontend/duckdb-components.md` - DuckDB UI components
- `docs/frontend/sqlite-components.md` - SQLite UI components
- `docs/guides/crud-operations-guide.md` - End-to-end tutorial

### **Consequences**

**Positive:**
- ✅ Clear focus on production CRUD operations
- ✅ Developers can implement CRUD in hours, not days
- ✅ Reduced documentation maintenance burden
- ✅ Better signal-to-noise ratio

**Negative:**
- ⚠️ Some general topics no longer documented (available in code comments)

---

## Decision 3: Component-Based Frontend Architecture

### **Context**

Angular components should be reusable, testable, and follow consistent patterns.

### **Problem**

1. Inconsistent component patterns across codebase
2. Mixed concerns (business logic in templates)
3. Hard to test and maintain

### **Decision**

**Implement signal-based, service-driven component architecture.**

### **Implementation**

**Pattern:**
```typescript
@Component({...})
export class CrudComponent {
  private readonly service = inject(Service);
  private readonly logger = inject(LoggerService);
  
  // Signal-based state
  data = signal<T[]>([]);
  isLoading = signal(false);
  
  // CRUD operations
  async load() { ... }
  async create(item: T) { ... }
  async update(item: T) { ... }
  async delete(id: number) { ... }
}
```

**Features:**
- Angular signals for reactive state
- Dependency injection for services
- Consistent error handling
- Loading states
- Validation

### **Consequences**

**Positive:**
- ✅ Consistent patterns across components
- ✅ Easy to test and maintain
- ✅ Reactive UI updates
- ✅ Clear separation of concerns

**Negative:**
- ⚠️ Requires understanding of Angular signals

---

## Decision 4: Thread-Safe Backend Services

### **Context**

Odin backend services handle concurrent requests from the frontend via WebUI.

### **Problem**

1. Race conditions possible with concurrent database operations
2. Data corruption risk without proper synchronization
3. Production deployments require thread safety

### **Decision**

**All database services must use mutex protection for thread safety.**

### **Implementation**

```odin
Database_Service :: struct {
    mutex    : sync.Mutex,
    database : rawptr,
}

crud_operation :: proc(svc: ^Database_Service) -> Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Database operations here
    // Thread-safe by design
}
```

### **Consequences**

**Positive:**
- ✅ Prevents race conditions
- ✅ Production-ready for concurrent workloads
- ✅ Consistent with best practices

**Negative:**
- ⚠️ Minimal performance overhead (mutex locking)

---

## Decision 5: Prepared Statements for All Queries

### **Context**

SQL injection is a critical security vulnerability in database applications.

### **Problem**

1. String concatenation for SQL queries is vulnerable
2. Manual escaping is error-prone
3. Security audits require parameterized queries

### **Decision**

**All SQL queries must use prepared statements with parameter binding.**

### **Implementation**

```odin
// ✅ Good: Prepared statement
var stmt : SQLite_Statement
sql := "INSERT INTO users (name, email) VALUES (?, ?)"
sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
sqlite3_bind_text(stmt, 1, user.name, -1, SQLITE_TRANSIENT)
sqlite3_bind_text(stmt, 2, user.email, -1, SQLITE_TRANSIENT)

// ❌ Bad: String concatenation
sql := fmt.Sprintf("INSERT INTO users (name, email) VALUES ('%s', '%s')", user.name, user.email)
```

### **Consequences**

**Positive:**
- ✅ Prevents SQL injection attacks
- ✅ Better performance (statement reuse)
- ✅ Type-safe parameter binding

**Negative:**
- ⚠️ Slightly more verbose code

---

## Decision 6: Unified Error Handling Pattern

### **Context**

Consistent error handling across backend and frontend improves debugging and user experience.

### **Problem**

1. Inconsistent error formats
2. Missing error context
3. Poor user feedback

### **Decision**

**Implement structured error handling with codes, messages, and HTTP-like status codes.**

### **Implementation**

**Backend:**
```odin
Error :: struct {
    code    : Error_Code,
    message : string,
}

Error_Code :: enum {
    None,
    Database_Error,
    Validation_Error,
    Security_Error,
    Not_Found,
}
```

**Frontend:**
```typescript
try {
  const result = await this.api.callOrThrow('operation', [params]);
} catch (error) {
  this.logger.error('Operation failed', error);
  // Show user-friendly message
}
```

### **Consequences**

**Positive:**
- ✅ Consistent error handling
- ✅ Better debugging
- ✅ Clear user feedback

**Negative:**
- ⚠️ Requires discipline to maintain

---

## Decision 7: Real-Time Statistics Display

### **Context**

Users need immediate feedback on data state (total users, today's count, etc.).

### **Problem**

1. Separate API calls for stats and data
2. Inconsistent statistics
3. Poor user experience

### **Decision**

**Provide dedicated statistics endpoints that run alongside CRUD operations.**

### **Implementation**

**Backend:**
```odin
duckdb_get_user_stats :: proc(svc: ^DuckDB_Service) -> (UserStats, Error) {
    // Total users
    total_sql := "SELECT COUNT(*) FROM users"
    
    // Today's count
    today_sql := "SELECT COUNT(*) FROM users WHERE DATE(created_at) = DATE('now')"
    
    // Unique domains
    domains_sql := "SELECT COUNT(DISTINCT SUBSTR(email, INSTR(email, '@') + 1)) FROM users"
    
    return stats, Error{code: .None}
}
```

**Frontend:**
```typescript
async loadUsers(): Promise<void> {
  const [users, stats] = await Promise.all([
    this.api.callOrThrow<User[]>('getUsers'),
    this.api.callOrThrow<UserStats>('getUserStats'),
  ]);
  this.users.set(users);
  this.stats.set(stats);
}
```

### **Consequences**

**Positive:**
- ✅ Real-time statistics
- ✅ Better user experience
- ✅ Efficient (parallel loading)

**Negative:**
- ⚠️ Additional database queries

---

## Summary of Decisions

| # | Decision | Impact | Status |
|---|----------|--------|--------|
| 1 | Dual Database Support | HIGH | ✅ Implemented |
| 2 | CRUD-Focused Documentation | HIGH | ✅ Implemented |
| 3 | Component-Based Frontend | MEDIUM | ✅ Implemented |
| 4 | Thread-Safe Backend | HIGH | ✅ Implemented |
| 5 | Prepared Statements | HIGH | ✅ Implemented |
| 6 | Unified Error Handling | MEDIUM | ✅ Implemented |
| 7 | Real-Time Statistics | MEDIUM | ✅ Implemented |

---

## Lessons Learned

1. **Focus on the core value** - CRUD operations are the primary use case
2. **Documentation drives adoption** - Clear guides reduce onboarding time
3. **Thread safety is non-negotiable** - Add mutexes from the start
4. **Security first** - Prepared statements prevent vulnerabilities
5. **Consistent patterns** - Make components predictable and testable

---

## References

- [DuckDB Integration Guide](./docs/backend/duckdb-integration.md)
- [SQLite Integration Guide](./docs/backend/sqlite-integration.md)
- [CRUD Operations Guide](./docs/guides/crud-operations-guide.md)
- [Quick Start](./QUICKSTART.md)

---

**Approved by:** Development Team
**Date:** 2026-03-30
**Next Review:** 2026-06-30
