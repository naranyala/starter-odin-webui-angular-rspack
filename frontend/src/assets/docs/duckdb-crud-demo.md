# 🦆 DuckDB CRUD Demo

**Full-featured database operations demonstration with checklist tracking.**

---

## 📋 Feature Checklist

### ✅ Available Features

- [x] **Create Table** - Create new DuckDB tables with custom schema
- [x] **Read Data** - Query and view table data with SQL
- [x] **Update Data** - Modify existing records with UPDATE queries
- [x] **Delete Data** - Remove records with DELETE queries
- [x] **SQL Editor** - Write and execute custom SQL queries
- [x] **Results Viewer** - View query results in tabular format
- [x] **Query Timing** - Track query execution duration
- [x] **Error Handling** - Display query errors with details

### 🔜 Coming Soon

- [ ] **Query History** - Track and reuse previous queries
- [ ] **Export Data** - Export query results to CSV/JSON
- [ ] **Saved Queries** - Save frequently used queries
- [ ] **Query Parameters** - Parameterized queries support

### 📋 Planned Features

- [ ] **Import Data** - Import data from CSV/JSON files
- [ ] **Visual Query Builder** - Build queries with drag-and-drop
- [ ] **Schema Designer** - Visual table schema editor
- [ ] **Data Visualization** - Charts and graphs from query results
- [ ] **Query Optimization** - Query performance suggestions

---

## 🚀 Quick Start

### **Step 1: Create a Table**

1. Click **"New Table"** button
2. Enter table name (e.g., `users`)
3. Enter columns (comma-separated, e.g., `id, name, email, role`)
4. Click **"Create Table"**

### **Step 2: View Table Data**

1. Click on any table card
2. Query auto-fills: `SELECT * FROM users LIMIT 100`
3. Click **"Run Query"**
4. View results in the table below

### **Step 3: Execute Custom Query**

1. Type SQL in the query editor
2. Example: `SELECT name, email FROM users WHERE role = 'Admin'`
3. Click **"Run Query"**
4. Results appear with row count and duration

### **Step 4: Modify Data**

```sql
-- Update example
UPDATE users SET role = 'Admin' WHERE id = 1;

-- Delete example  
DELETE FROM users WHERE id = 5;

-- Insert example
INSERT INTO users (name, email, role) VALUES ('New User', 'new@example.com', 'User');
```

---

## 📖 Usage Guide

### **Tables Panel**

The left panel shows all available tables:

| Element | Description |
|---------|-------------|
| Table Name | Click to select table |
| Row Count | Number of records |
| Columns | Table schema preview |
| Edit Button | Modify table structure |
| Delete Button | Remove table |

### **Query Panel**

The right panel for SQL operations:

| Element | Description |
|---------|-------------|
| SQL Editor | Write SQL queries |
| Run Button | Execute current query |
| Clear Button | Reset editor and results |
| Results Table | Query output display |
| Duration | Query execution time |

---

## 🔧 API Reference

### **Backend Functions**

```typescript
// Get all tables
const tables = await api.callOrThrow<DuckDBTable[]>('duckdb.getTables');

// Create new table
await api.callOrThrow('duckdb.createTable', [
  'users',
  ['id', 'name', 'email', 'role']
]);

// Execute query
const results = await api.callOrThrow<any[]>('duckdb.executeQuery', [
  'SELECT * FROM users LIMIT 10'
]);

// Delete table
await api.callOrThrow('duckdb.deleteTable', [tableId]);
```

### **Data Types**

```typescript
interface DuckDBTable {
  id: number;
  name: string;
  rows: number;
  columns: string[];
  createdAt: string;
}

interface DuckDBQuery {
  id: number;
  sql: string;
  description: string;
  lastRun?: string;
  duration?: number;
}
```

---

## 📝 Example Queries

### **Basic SELECT**
```sql
SELECT * FROM users;
SELECT name, email FROM users;
SELECT * FROM users LIMIT 10;
```

### **WHERE Clause**
```sql
SELECT * FROM users WHERE role = 'Admin';
SELECT * FROM products WHERE price > 100;
SELECT * FROM orders WHERE status = 'Pending';
```

### **JOINs**
```sql
SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id;
```

### **Aggregations**
```sql
SELECT role, COUNT(*) as count
FROM users
GROUP BY role;

SELECT AVG(price) as avg_price
FROM products;
```

### **Subqueries**
```sql
SELECT * FROM users
WHERE id IN (SELECT user_id FROM orders WHERE total > 100);
```

---

## ✅ Testing Checklist

### **CRUD Operations**

- [ ] Create table with single column
- [ ] Create table with multiple columns
- [ ] Read data from table
- [ ] Update single record
- [ ] Update multiple records
- [ ] Delete single record
- [ ] Delete multiple records
- [ ] Delete entire table

### **SQL Features**

- [ ] SELECT with all columns
- [ ] SELECT with specific columns
- [ ] WHERE with equality
- [ ] WHERE with comparison operators
- [ ] WHERE with LIKE
- [ ] ORDER BY ascending
- [ ] ORDER BY descending
- [ ] LIMIT results
- [ ] GROUP BY with aggregates
- [ ] JOIN between tables

### **Error Handling**

- [ ] Invalid table name
- [ ] Invalid column name
- [ ] Syntax error in SQL
- [ ] Permission denied
- [ ] Table not found
- [ ] Connection error

### **UI Features**

- [ ] Table list displays correctly
- [ ] Query results show row count
- [ ] Query duration displays
- [ ] Error messages are clear
- [ ] Loading states work
- [ ] Refresh updates data
- [ ] Modal dialogs work
- [ ] Responsive on mobile

---

## 🎯 Best Practices

### **1. Use LIMIT for Large Tables**
```sql
-- Good
SELECT * FROM users LIMIT 100;

-- Bad (might be slow)
SELECT * FROM users;
```

### **2. Select Only Needed Columns**
```sql
-- Good
SELECT name, email FROM users;

-- Bad (unnecessary data)
SELECT * FROM users;
```

### **3. Use Parameterized Queries**
```typescript
// In production, use parameters to prevent SQL injection
await api.callOrThrow('duckdb.executeQuery', [
  'SELECT * FROM users WHERE id = ?',
  [userId]
]);
```

### **4. Handle Errors Gracefully**
```typescript
try {
  const results = await executeQuery(sql);
} catch (error) {
  // Show user-friendly error
  showError('Query failed. Please check your SQL syntax.');
}
```

---

## 🐛 Troubleshooting

### **"Table not found"**
- Check table name spelling
- Refresh table list
- Verify table was created successfully

### **"Syntax error"**
- Check SQL syntax
- Ensure table/column names are correct
- Look for missing commas or quotes

### **"Query timeout"**
- Add LIMIT to reduce result size
- Check for missing WHERE clauses
- Optimize query with indexes

### **No results showing**
- Verify table has data
- Check WHERE clause conditions
- Try SELECT * without filters

---

## 📊 Performance Tips

| Tip | Impact |
|-----|--------|
| Use LIMIT | High |
| Select specific columns | Medium |
| Add WHERE clauses | High |
| Use indexes | High |
| Avoid SELECT * | Medium |
| Batch operations | Medium |

---

## 🔗 Related Documentation

- [SQLite CRUD Demo](./sqlite-crud-demo.md)
- [WebSocket Demo](./websocket-demo.md)
- [Data Transform Services](./data-transform-services.md)
- [API Patterns](./api-patterns.md)

---

## 📈 Progress Tracking

| Milestone | Status | Date |
|-----------|--------|------|
| Basic CRUD | ✅ Complete | 2026-03-29 |
| SQL Editor | ✅ Complete | 2026-03-29 |
| Results Viewer | ✅ Complete | 2026-03-29 |
| Query History | 🔜 In Progress | - |
| Export/Import | 📋 Planned | - |
| Visual Builder | 📋 Planned | - |

---

**Last Updated:** 2026-03-29  
**Status:** ✅ Production Ready  
**Demo Access:** Dashboard → Thirdparty Demos → 🦆 DuckDB
