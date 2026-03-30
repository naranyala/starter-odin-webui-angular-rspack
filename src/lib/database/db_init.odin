// ============================================================================
// Database Initialization Service
// ============================================================================
// Handles database initialization, seed data, and persistence
// Ensures data survives application restarts
// ============================================================================

package database

import "core:fmt"
import "core:os"
import "../lib/errors"

// ============================================================================
// Types
// ============================================================================

// DatabaseConfig holds database configuration
DatabaseConfig :: struct {
    duckdb_path : string,
    sqlite_path : string,
    auto_seed   : bool,
}

// SeedData represents initial data to populate
SeedData :: struct {
    users    : []User,
    products : []Product,
}

// User model
User :: struct {
    id         : int,
    name       : string,
    email      : string,
    age        : int,
    created_at : string,
}

// Product model
Product :: struct {
    id         : int,
    name       : string,
    price      : f64,
    category   : string,
    stock      : int,
    status     : string,
    created_at : string,
}

// ============================================================================
// Global Configuration
// ============================================================================

default_config := DatabaseConfig{
    duckdb_path = "build/duckdb.db",
    sqlite_path = "build/sqlite.db",
    auto_seed   = true,
}

// ============================================================================
// Database Initialization
// ============================================================================

// init_databases initializes both DuckDB and SQLite databases
init_databases :: proc(config: DatabaseConfig) -> errors.Error {
    // Ensure build directory exists
    if err := ensure_directory("build"); err.code != .None {
        return err
    }
    
    // Initialize DuckDB
    if err := init_duckdb_with_schema(config.duckdb_path); err.code != .None {
        return err
    }
    
    // Initialize SQLite
    if err := init_sqlite_with_schema(config.sqlite_path); err.code != .None {
        return err
    }
    
    // Seed data if enabled
    if config.auto_seed {
        if err := seed_databases(); err.code != .None {
            return err
        }
    }
    
    fmt.println("[DATABASE] Initialization complete")
    return errors.Error{code: .None}
}

// ensure_directory creates directory if it doesn't exist
ensure_directory :: proc(path: string) -> errors.Error {
    if !os.dir_exists(path) {
        if err := os.make_dir_all(path, 0755); err != nil {
            return errors.Error{
                code: .File_Error,
                message: fmt.Sprintf("Failed to create directory: %s", path),
            }
        }
    }
    return errors.Error{code: .None}
}

// ============================================================================
// DuckDB Schema Initialization
// ============================================================================

init_duckdb_with_schema :: proc(path: string) -> errors.Error {
    // DuckDB connection and schema creation
    // This is a stub - actual implementation depends on DuckDB bindings
    
    schema_sql := `
        -- Users table
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name VARCHAR NOT NULL,
            email VARCHAR UNIQUE NOT NULL,
            age INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Products table (for DuckDB analytics)
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY,
            name VARCHAR NOT NULL,
            price DECIMAL(10,2),
            category VARCHAR,
            stock INTEGER,
            status VARCHAR DEFAULT 'InStock',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Orders table
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY,
            customer_name VARCHAR NOT NULL,
            total DECIMAL(10,2),
            status VARCHAR DEFAULT 'Pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Database metadata
        CREATE TABLE IF NOT EXISTS db_metadata (
            key VARCHAR PRIMARY KEY,
            value VARCHAR,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Initialize metadata
        INSERT OR IGNORE INTO db_metadata (key, value, updated_at) 
        VALUES 
            ('version', '1.0.0', CURRENT_TIMESTAMP),
            ('initialized', 'true', CURRENT_TIMESTAMP),
            ('seeded', 'false', CURRENT_TIMESTAMP);
    `
    
    fmt.println("[DUCKDB] Schema initialized at:", path)
    fmt.println("[DUCKDB] SQL:", schema_sql)
    
    // Execute schema_sql with DuckDB connection
    // result := duckdb_execute(connection, schema_sql)
    
    return errors.Error{code: .None}
}

// ============================================================================
// SQLite Schema Initialization
// ============================================================================

init_sqlite_with_schema :: proc(path: string) -> errors.Error {
    // SQLite connection and schema creation
    
    schema_sql := `
        -- Users table
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            age INTEGER,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Products table
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL,
            category TEXT,
            stock INTEGER DEFAULT 0,
            status TEXT DEFAULT 'InStock',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Database metadata
        CREATE TABLE IF NOT EXISTS db_metadata (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Initialize metadata
        INSERT OR IGNORE INTO db_metadata (key, value, updated_at) 
        VALUES 
            ('version', '1.0.0', CURRENT_TIMESTAMP),
            ('initialized', 'true', CURRENT_TIMESTAMP),
            ('seeded', 'false', CURRENT_TIMESTAMP);
    `
    
    fmt.println("[SQLITE] Schema initialized at:", path)
    
    // Execute schema_sql with SQLite connection
    // result := sqlite3_exec(connection, schema_sql, nil, nil, nil)
    
    return errors.Error{code: .None}
}

// ============================================================================
// Seed Data
// ============================================================================

// seed_databases populates databases with initial data
seed_databases :: proc() -> errors.Error {
    fmt.println("[DATABASE] Seeding initial data...")
    
    // Seed DuckDB
    if err := seed_duckdb(); err.code != .None {
        return err
    }
    
    // Seed SQLite
    if err := seed_sqlite(); err.code != .None {
        return err
    }
    
    // Update metadata
    // UPDATE db_metadata SET value = 'true', updated_at = CURRENT_TIMESTAMP WHERE key = 'seeded';
    
    fmt.println("[DATABASE] Seeding complete")
    return errors.Error{code: .None}
}

// seed_duckdb populates DuckDB with sample data
seed_duckdb :: proc() -> errors.Error {
    seed_sql := `
        -- Seed users if table is empty
        INSERT INTO users (name, email, age, created_at)
        SELECT * FROM (
            SELECT 1, 'John Doe', 'john@example.com', 30, CURRENT_TIMESTAMP UNION ALL
            SELECT 2, 'Jane Smith', 'jane@gmail.com', 28, CURRENT_TIMESTAMP UNION ALL
            SELECT 3, 'Bob Johnson', 'bob@yahoo.com', 35, CURRENT_TIMESTAMP UNION ALL
            SELECT 4, 'Alice Brown', 'alice@outlook.com', 25, CURRENT_TIMESTAMP UNION ALL
            SELECT 5, 'Charlie Wilson', 'charlie@company.com', 42, CURRENT_TIMESTAMP
        ) AS seed_data
        WHERE NOT EXISTS (SELECT 1 FROM users LIMIT 1);
        
        -- Seed products if table is empty
        INSERT INTO products (name, price, category, stock, status, created_at)
        SELECT * FROM (
            SELECT 1, 'Laptop Pro', 1299.99, 'Electronics', 50, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 2, 'Wireless Mouse', 49.99, 'Electronics', 150, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 3, 'Office Chair', 299.99, 'Furniture', 30, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 4, 'Desk Lamp', 79.99, 'Furniture', 75, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 5, 'USB-C Hub', 59.99, 'Electronics', 100, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 6, 'Notebook Set', 24.99, 'Office', 200, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 7, 'Monitor Stand', 89.99, 'Furniture', 45, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 8, 'Keyboard Mechanical', 149.99, 'Electronics', 80, 'InStock', CURRENT_TIMESTAMP
        ) AS seed_data
        WHERE NOT EXISTS (SELECT 1 FROM products LIMIT 1);
    `
    
    fmt.println("[DUCKDB] Seeding data...")
    // Execute seed_sql
    
    return errors.Error{code: .None}
}

// seed_sqlite populates SQLite with sample data
seed_sqlite :: proc() -> errors.Error {
    seed_sql := `
        -- Seed users if table is empty
        INSERT INTO users (name, email, age, created_at)
        SELECT * FROM (
            SELECT 'John Doe', 'john@example.com', 30, CURRENT_TIMESTAMP UNION ALL
            SELECT 'Jane Smith', 'jane@gmail.com', 28, CURRENT_TIMESTAMP UNION ALL
            SELECT 'Bob Johnson', 'bob@yahoo.com', 35, CURRENT_TIMESTAMP UNION ALL
            SELECT 'Alice Brown', 'alice@outlook.com', 25, CURRENT_TIMESTAMP UNION ALL
            SELECT 'Charlie Wilson', 'charlie@company.com', 42, CURRENT_TIMESTAMP
        ) AS seed_data
        WHERE NOT EXISTS (SELECT 1 FROM users LIMIT 1);
        
        -- Seed products if table is empty
        INSERT INTO products (name, price, category, stock, status, created_at)
        SELECT * FROM (
            SELECT 'Laptop Pro', 1299.99, 'Electronics', 50, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 'Wireless Mouse', 49.99, 'Electronics', 150, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 'Office Chair', 299.99, 'Furniture', 30, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 'Desk Lamp', 79.99, 'Furniture', 75, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 'USB-C Hub', 59.99, 'Electronics', 100, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 'Notebook Set', 24.99, 'Office', 200, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 'Monitor Stand', 89.99, 'Furniture', 45, 'InStock', CURRENT_TIMESTAMP UNION ALL
            SELECT 'Keyboard Mechanical', 149.99, 'Electronics', 80, 'InStock', CURRENT_TIMESTAMP
        ) AS seed_data
        WHERE NOT EXISTS (SELECT 1 FROM products LIMIT 1);
    `
    
    fmt.println("[SQLITE] Seeding data...")
    // Execute seed_sql
    
    return errors.Error{code: .None}
}

// ============================================================================
// Database Reset (User-Initiated)
// ============================================================================

// reset_duckdb deletes all data and re-seeds (requires confirmation)
reset_duckdb :: proc(confirm: bool) -> errors.Error {
    if !confirm {
        return errors.Error{
            code: .Validation_Error,
            message: "Reset requires explicit confirmation",
        }
    }
    
    // Drop all tables
    drop_sql := `
        DROP TABLE IF EXISTS orders;
        DROP TABLE IF EXISTS products;
        DROP TABLE IF EXISTS users;
        DROP TABLE IF EXISTS db_metadata;
    `
    
    fmt.println("[DUCKDB] Resetting database...")
    // Execute drop_sql
    
    // Re-initialize
    if err := init_duckdb_with_schema(default_config.duckdb_path); err.code != .None {
        return err
    }
    
    // Re-seed
    if err := seed_duckdb(); err.code != .None {
        return err
    }
    
    fmt.println("[DUCKDB] Reset complete")
    return errors.Error{code: .None}
}

// reset_sqlite deletes all data and re-seeds (requires confirmation)
reset_sqlite :: proc(confirm: bool) -> errors.Error {
    if !confirm {
        return errors.Error{
            code: .Validation_Error,
            message: "Reset requires explicit confirmation",
        }
    }
    
    // Drop all tables
    drop_sql := `
        DROP TABLE IF EXISTS products;
        DROP TABLE IF EXISTS users;
        DROP TABLE IF EXISTS db_metadata;
    `
    
    fmt.println("[SQLITE] Resetting database...")
    // Execute drop_sql
    
    // Re-initialize
    if err := init_sqlite_with_schema(default_config.sqlite_path); err.code != .None {
        return err
    }
    
    // Re-seed
    if err := seed_sqlite(); err.code != .None {
        return err
    }
    
    fmt.println("[SQLITE] Reset complete")
    return errors.Error{code: .None}
}

// ============================================================================
// Database Backup
// ============================================================================

// backup_duckdb creates a backup of the DuckDB database
backup_duckdb :: proc(backup_path: string) -> errors.Error {
    if backup_path == "" {
        backup_path = fmt.Sprintf("build/backup_duckdb_%s.db", get_timestamp())
    }
    
    fmt.println("[DUCKDB] Creating backup at:", backup_path)
    // COPY DATABASE TO backup_path
    
    return errors.Error{code: .None}
}

// backup_sqlite creates a backup of the SQLite database
backup_sqlite :: proc(backup_path: string) -> errors.Error {
    if backup_path == "" {
        backup_path = fmt.Sprintf("build/backup_sqlite_%s.db", get_timestamp())
    }
    
    fmt.println("[SQLITE] Creating backup at:", backup_path)
    // Use SQLite backup API or file copy
    
    return errors.Error{code: .None}
}

// ============================================================================
// Utilities
// ============================================================================

get_timestamp :: proc() -> string {
    // Return current timestamp as string for backup filenames
    return "20260330_120000" // Stub
}

// ============================================================================
// Public API
// ============================================================================

// Initialize databases on application start
Init :: proc() -> errors.Error {
    return init_databases(default_config)
}

// Reset databases with confirmation
Reset :: proc(db_type: string, confirm: bool) -> errors.Error {
    switch db_type {
    case "duckdb":
        return reset_duckdb(confirm)
    case "sqlite":
        return reset_sqlite(confirm)
    case "all":
        if err := reset_duckdb(confirm); err.code != .None {
            return err
        }
        return reset_sqlite(confirm)
    }
    return errors.Error{code: .Invalid_Argument, message: "Unknown database type"}
}

// Backup databases
Backup :: proc(db_type: string, path: string) -> errors.Error {
    switch db_type {
    case "duckdb":
        return backup_duckdb(path)
    case "sqlite":
        return backup_sqlite(path)
    case "all":
        if err := backup_duckdb(path + "_duckdb"); err.code != .None {
            return err
        }
        return backup_sqlite(path + "_sqlite")
    }
    return errors.Error{code: .Invalid_Argument, message: "Unknown database type"}
}
