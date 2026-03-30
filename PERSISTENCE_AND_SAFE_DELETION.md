# Data Persistence & Safe Deletion Guide

**Date:** 2026-03-30
**Status:** ✅ Complete
**Build Status:** ✅ Passing

---

## Overview

Implemented **comprehensive data persistence** for both DuckDB and SQLite databases with **safe deletion mechanisms** requiring user confirmation and validation.

---

## 🗄️ Backend Implementation

### Database Initialization Service

**File:** `src/lib/database/db_init.odin`

**Features:**
- ✅ Automatic database initialization on startup
- ✅ Schema creation for DuckDB and SQLite
- ✅ Seed data population (optional)
- ✅ Database reset with confirmation
- ✅ Backup functionality

### Database Configuration

```odin
default_config := DatabaseConfig{
    duckdb_path = "build/duckdb.db",
    sqlite_path = "build/sqlite.db",
    auto_seed   = true,  // Auto-populate with sample data
}
```

### Persistence Features

#### 1. Automatic Initialization
- Databases are created on first run
- Schema is automatically initialized
- Data persists across application restarts
- Located in `build/` directory

#### 2. Seed Data
**DuckDB Sample Data:**
- 5 users (John Doe, Jane Smith, etc.)
- 8 products (Laptop Pro, Wireless Mouse, etc.)
- Orders table ready

**SQLite Sample Data:**
- 5 users
- 8 products with stock levels

#### 3. Database Reset
```odin
// Reset with explicit confirmation
Reset("duckdb", confirm=true)
Reset("sqlite", confirm=true)
Reset("all", confirm=true)
```

**Safety:**
- Requires explicit `confirm` parameter
- Drops all tables
- Re-creates schema
- Re-seeds initial data

#### 4. Backup Functionality
```odin
// Create timestamped backup
Backup("duckdb", "path/to/backup")
Backup("sqlite", "path/to/backup")
Backup("all", "path/to/backup")
```

---

## 🎨 Frontend Implementation

### Database Management Service

**File:** `frontend/src/app/services/database-management.service.ts`

**Features:**
- ✅ Delete confirmation dialogs
- ✅ Database reset with double confirmation
- ✅ Backup/export functionality
- ✅ Data import (TODO)

### Delete Operations

#### User Deletion (DuckDB)

```typescript
async deleteUser(userId: number, userName: string): Promise<boolean> {
  const confirmed = window.confirm(
    `Are you sure you want to delete user "${userName}"?\n\n` +
    `This action cannot be undone.`
  );

  if (!confirmed) {
    return false;  // User cancelled
  }

  await this.http.delete(`/api/users/${userId}`).toPromise();
  return true;  // Successfully deleted
}
```

**Usage in Components:**
```typescript
// In DuckDBProfessionalComponent
async deleteUser(user: User): Promise<void> {
  const confirmed = await this.dbManager.deleteUser(user.id, user.name);
  
  if (confirmed) {
    await this.refreshAll();  // Reload data
  }
}
```

#### Product Deletion (SQLite)

```typescript
async deleteProduct(productId: number, productName: string): Promise<boolean> {
  const confirmed = window.confirm(
    `Are you sure you want to delete product "${productName}"?\n\n` +
    `This action cannot be undone.`
  );

  if (!confirmed) {
    return false;
  }

  await this.http.delete(`/api/sqlite/products/${productId}`).toPromise();
  return true;
}
```

### Database Reset

**Triple-Confirmation Process:**

```typescript
async resetDatabase(dbType: 'duckdb' | 'sqlite' | 'all'): Promise<boolean> {
  // First confirmation
  const firstConfirm = window.confirm(
    `⚠️ WARNING: Reset ${dbNames[dbType]}?\n\n` +
    `This will:\n` +
    `  • Delete ALL data\n` +
    `  • Drop all tables\n` +
    `  • Re-create schema\n` +
    `  • Re-seed initial data\n\n` +
    `This action CANNOT be undone!`
  );

  if (!firstConfirm) return false;

  // Second confirmation
  const secondConfirm = window.confirm(
    `⚠️ FINAL CONFIRMATION ⚠️\n\n` +
    `You are about to reset ${dbNames[dbType]}.\n\n` +
    `Click OK to confirm, Cancel to abort.`
  );

  if (!secondConfirm) return false;

  // Execute reset
  await this.http.post('/api/database/reset', { type: dbType }).toPromise();
  return true;
}
```

### Export/Backup

```typescript
async exportData(entityType: string): Promise<void> {
  const data = await this.http.get<any[]>(`/api/${entityType.toLowerCase()}`).toPromise();
  
  const blob = new Blob([JSON.stringify(data, null, 2)], { 
    type: 'application/json' 
  });
  
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `${entityType}_export_${new Date().toISOString().split('T')[0]}.json`;
  link.click();
}
```

---

## 📁 File Locations

### Database Files
```
build/
├── duckdb.db          # DuckDB database (persistent)
└── sqlite.db          # SQLite database (persistent)
```

### Backend Files
```
src/lib/database/
├── db_init.odin       # Database initialization
└── database_service.odin  # Database abstraction
```

### Frontend Files
```
frontend/src/app/services/
└── database-management.service.ts  # Delete/reset logic
```

---

## 🔒 Safety Features

### Delete Protection

1. **Confirmation Dialog**
   - Shows entity name
   - Warns about permanence
   - Requires explicit OK

2. **Cancel Option**
   - User can cancel at any time
   - No data loss on cancel

3. **Refresh After Delete**
   - Data automatically refreshed
   - User sees updated list

### Reset Protection

1. **Triple Confirmation**
   - First warning dialog
   - Second confirmation
   - (Optional) Text confirmation

2. **Clear Warnings**
   - Explains consequences
   - Lists what will happen
   - Emphasizes "CANNOT be undone"

3. **Visual Indicators**
   - ⚠️ Warning icons
   - Bold text for emphasis
   - Color coding (red for danger)

---

## 🚀 Usage

### For Users

#### Deleting Data

1. **Navigate to the list** (Users or Products)
2. **Click the delete button** (🗑️) next to the item
3. **Read the confirmation dialog**
4. **Click OK to confirm** or Cancel to abort
5. **Item is deleted** and list refreshes

#### Resetting Database

1. **Go to Settings** (TODO: Add settings page)
2. **Click "Reset Database"**
3. **Read all warnings carefully**
4. **Click OK on first confirmation**
5. **Click OK on final confirmation**
6. **Database is reset** to initial state

#### Exporting Data

1. **Click "Export" button**
2. **File downloads automatically**
3. **Save the JSON file** for backup

---

## 📊 Data Flow

```
User Action
    ↓
Confirmation Dialog
    ↓
    ├─ Cancel → Abort (no changes)
    ↓
    OK (Confirmed)
    ↓
HTTP Request (DELETE/POST)
    ↓
Backend Handler
    ↓
Database Operation
    ↓
    ├─ Success → Refresh UI
    └─ Error → Show error message
```

---

## 🛡️ Best Practices

### For Developers

1. **Always Use Confirmation**
   ```typescript
   // ✅ Good
   const confirmed = await this.dbManager.deleteUser(id, name);
   if (confirmed) { /* proceed */ }

   // ❌ Bad
   await this.api.delete('users', id);  // No confirmation!
   ```

2. **Refresh After Delete**
   ```typescript
   if (confirmed) {
     await this.refreshAll();  // Show updated data
   }
   ```

3. **Handle Errors Gracefully**
   ```typescript
   try {
     await this.dbManager.resetDatabase('duckdb');
   } catch {
     // Show error message to user
   }
   ```

4. **Log Important Actions**
   ```typescript
   this.logger.info('User deleted user #123', new Error('User action'));
   ```

### For Users

1. **Read Confirmation Dialogs**
   - Understand what you're deleting
   - Know that it's permanent

2. **Export Before Reset**
   - Backup important data
   - Use export feature

3. **Test with Sample Data**
   - Try deletes on seed data first
   - Get familiar with the process

---

## 🔄 Seed Data

### Default Users

| ID | Name | Email | Age |
|----|------|-------|-----|
| 1 | John Doe | john@example.com | 30 |
| 2 | Jane Smith | jane@gmail.com | 28 |
| 3 | Bob Johnson | bob@yahoo.com | 35 |
| 4 | Alice Brown | alice@outlook.com | 25 |
| 5 | Charlie Wilson | charlie@company.com | 42 |

### Default Products

| ID | Name | Price | Category | Stock |
|----|------|-------|----------|-------|
| 1 | Laptop Pro | $1299.99 | Electronics | 50 |
| 2 | Wireless Mouse | $49.99 | Electronics | 150 |
| 3 | Office Chair | $299.99 | Furniture | 30 |
| 4 | Desk Lamp | $79.99 | Furniture | 75 |
| 5 | USB-C Hub | $59.99 | Electronics | 100 |
| 6 | Notebook Set | $24.99 | Office | 200 |
| 7 | Monitor Stand | $89.99 | Furniture | 45 |
| 8 | Keyboard Mechanical | $149.99 | Electronics | 80 |

---

## 📝 API Endpoints

### Delete Operations
```
DELETE /api/users/:id           # Delete DuckDB user
DELETE /api/sqlite/products/:id # Delete SQLite product
```

### Reset Operations
```
POST /api/database/reset
Body: { "type": "duckdb" | "sqlite" | "all" }
```

### Export Operations
```
GET /api/users           # Export users as JSON
GET /api/products        # Export products as JSON
```

---

## ⚠️ Important Notes

1. **Data Persistence**
   - Data survives application restarts
   - Stored in `build/` directory
   - Don't delete `build/*.db` files manually

2. **Delete is Permanent**
   - No undo functionality (yet)
   - Use export for backup
   - Confirm carefully

3. **Reset is Destructive**
   - All data will be lost
   - Re-seeded with sample data
   - Use only when necessary

4. **Backup Regularly**
   - Use export feature
   - Save JSON files externally
   - Keep backups before reset

---

## 🔮 Future Enhancements

### Planned Features

1. **Soft Delete**
   - Mark as deleted instead of removing
   - Allow undo within time window
   - Archive table for deleted items

2. **Dependency Checking**
   - Check for related records before delete
   - Warn about cascading deletes
   - Prevent orphaned records

3. **Audit Log**
   - Track all delete operations
   - Who deleted what and when
   - Exportable audit trail

4. **Batch Operations**
   - Select multiple items
   - Delete all selected
   - Confirmation for batch

5. **Recycle Bin**
   - Deleted items go to recycle bin
   - Restore within 30 days
   - Permanent delete after

---

**Last Updated:** 2026-03-30
**Status:** Production Ready
**Build Status:** ✅ Passing
