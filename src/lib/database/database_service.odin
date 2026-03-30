// ============================================================================
// Database Service - Unified Database Abstraction Layer
// ============================================================================
// Provides a unified interface for DuckDB and SQLite operations
// Supports transaction management, connection pooling, and query execution
// ============================================================================

package database

import "core:sync"
import "core:fmt"
import "../lib/errors"

// ============================================================================
// Types and Constants
// ============================================================================

// DatabaseType represents the type of database
DatabaseType :: enum {
    DuckDB,
    SQLite,
}

// QueryResult represents the result of a database query
QueryResult :: struct {
    rows_affected : int,
    last_insert_id : i64,
    data          : rawptr,  // Opaque pointer to result data
    error         : errors.Error,
}

// Transaction isolation levels
Transaction_Isolation :: enum {
    Read_Uncommitted,
    Read_Committed,
    Repeatable_Read,
    Serializable,
}

// Transaction options
Transaction_Options :: struct {
    isolation_level : Transaction_Isolation,
    read_only       : bool,
    timeout_ms      : int,
}

// ============================================================================
// Database Connection Interface
// ============================================================================

// Database_Connection defines the interface for database operations
Database_Connection :: struct {
    mutex           : sync.Mutex,
    db_type         : DatabaseType,
    connection      : rawptr,
    database        : rawptr,
    is_connected    : bool,
    in_transaction  : bool,
    connection_string : string,
}

// ============================================================================
// Connection Management
// ============================================================================

// init_connection initializes a database connection
init_connection :: proc(db_type: DatabaseType, connection_string: string) -> (Database_Connection, errors.Error) {
    conn := Database_Connection{
        db_type = db_type,
        connection_string = connection_string,
        is_connected = false,
        in_transaction = false,
    }
    
    switch db_type {
    case .DuckDB:
        return init_duckdb_connection(&conn, connection_string)
    case .SQLite:
        return init_sqlite_connection(&conn, connection_string)
    }
    
    return conn, errors.Error{code: .Invalid_Argument, message: "Unknown database type"}
}

// close_connection closes the database connection
close_connection :: proc(conn: ^Database_Connection) -> errors.Error {
    sync.lock(&conn.mutex)
    defer sync.unlock(&conn.mutex)
    
    if !conn.is_connected {
        return errors.Error{code: .None}
    }
    
    if conn.in_transaction {
        rollback_transaction(conn)
    }
    
    switch conn.db_type {
    case .DuckDB:
        return close_duckdb_connection(conn)
    case .SQLite:
        return close_sqlite_connection(conn)
    }
    
    return errors.Error{code: .None}
}

// ============================================================================
// Query Execution
// ============================================================================

// execute_query executes a SQL query and returns the result
execute_query :: proc(conn: ^Database_Connection, sql: string, params: ..any) -> QueryResult {
    sync.lock(&conn.mutex)
    defer sync.unlock(&conn.mutex)
    
    if !conn.is_connected {
        return QueryResult{error = errors.Error{code: .Connection_Error, message: "Not connected to database"}}
    }
    
    // Validate SQL (prevent injection)
    if !is_safe_query(sql) {
        return QueryResult{error = errors.Error{code: .Security_Error, message: "Unsafe query detected"}}
    }
    
    switch conn.db_type {
    case .DuckDB:
        return execute_duckdb_query(conn, sql, params..)
    case .SQLite:
        return execute_sqlite_query(conn, sql, params..)
    }
    
    return QueryResult{error = errors.Error{code: .Invalid_Argument, message: "Unknown database type"}}
}

// execute_prepared executes a prepared statement with parameters
execute_prepared :: proc(conn: ^Database_Connection, sql: string, params: ..any) -> QueryResult {
    sync.lock(&conn.mutex)
    defer sync.unlock(&conn.mutex)
    
    if !conn.is_connected {
        return QueryResult{error = errors.Error{code: .Connection_Error, message: "Not connected to database"}}
    }
    
    switch conn.db_type {
    case .DuckDB:
        return execute_duckdb_prepared(conn, sql, params..)
    case .SQLite:
        return execute_sqlite_prepared(conn, sql, params..)
    }
    
    return QueryResult{error = errors.Error{code: .Invalid_Argument, message: "Unknown database type"}}
}

// ============================================================================
// Transaction Management
// ============================================================================

// begin_transaction starts a new transaction
begin_transaction :: proc(conn: ^Database_Connection, options: Transaction_Options) -> errors.Error {
    sync.lock(&conn.mutex)
    defer sync.unlock(&conn.mutex)
    
    if !conn.is_connected {
        return errors.Error{code: .Connection_Error, message: "Not connected to database"}
    }
    
    if conn.in_transaction {
        return errors.Error{code: .Invalid_State, message: "Already in transaction"}
    }
    
    var sql: string
    switch options.isolation_level {
    case .Read_Uncommitted: sql = "BEGIN TRANSACTION"
    case .Read_Committed: sql = "BEGIN TRANSACTION"
    case .Repeatable_Read: sql = "BEGIN TRANSACTION"
    case .Serializable: sql = "BEGIN TRANSACTION"
    }
    
    if options.read_only {
        sql = "BEGIN TRANSACTION READ ONLY"
    }
    
    switch conn.db_type {
    case .DuckDB:
        return begin_duckdb_transaction(conn, options)
    case .SQLite:
        return begin_sqlite_transaction(conn, options)
    }
    
    return errors.Error{code: .Invalid_Argument, message: "Unknown database type"}
}

// commit_transaction commits the current transaction
commit_transaction :: proc(conn: ^Database_Connection) -> errors.Error {
    if !conn.in_transaction {
        return errors.Error{code: .Invalid_State, message: "No transaction in progress"}
    }
    
    switch conn.db_type {
    case .DuckDB:
        return commit_duckdb_transaction(conn)
    case .SQLite:
        return commit_sqlite_transaction(conn)
    }
    
    return errors.Error{code: .Invalid_Argument, message: "Unknown database type"}
}

// rollback_transaction rolls back the current transaction
rollback_transaction :: proc(conn: ^Database_Connection) -> errors.Error {
    if !conn.in_transaction {
        return errors.Error{code: .Invalid_State, message: "No transaction in progress"}
    }
    
    switch conn.db_type {
    case .DuckDB:
        return rollback_duckdb_transaction(conn)
    case .SQLite:
        return rollback_sqlite_transaction(conn)
    }
    
    return errors.Error{code: .Invalid_Argument, message: "Unknown database type"}
}

// ============================================================================
// Helper Functions
// ============================================================================

// is_safe_query validates that a SQL query is safe to execute
is_safe_query :: proc(sql: string) -> bool {
    if sql == "" {
        return false
    }
    
    upper_sql := string_to_upper(sql)
    
    // Block dangerous operations
    dangerous_patterns := []string{
        "DROP DATABASE",
        "DROP TABLE IF EXISTS users",
        "TRUNCATE",
        "DELETE FROM users WHERE 1=1",
        "EXEC ",
        "XP_",
        "SP_",
    }
    
    for pattern in dangerous_patterns {
        if contains(upper_sql, pattern) {
            return false
        }
    }
    
    return true
}

// string_to_upper converts a string to uppercase
string_to_upper :: proc(s: string) -> string {
    result := make([]u8, len(s))
    for i, c in s {
        if c >= 'a' && c <= 'z' {
            result[i] = c - 'a' + 'A'
        } else {
            result[i] = c
        }
    }
    return string(result)
}

// contains checks if a string contains a substring
contains :: proc(haystack: string, needle: string) -> bool {
    return len(haystack) >= len(needle) && index_of(haystack, needle) >= 0
}

// index_of returns the index of a substring
index_of :: proc(haystack: string, needle: string) -> int {
    if len(needle) == 0 {
        return 0
    }
    if len(needle) > len(haystack) {
        return -1
    }
    
    for i in 0..(len(haystack) - len(needle) + 1) {
        match := true
        for j in 0..<len(needle) {
            if haystack[i+j] != needle[j] {
                match = false
                break
            }
        }
        if match {
            return i
        }
    }
    return -1
}

// ============================================================================
// DuckDB Implementation - Delegated to duckdb_impl.odin
// ============================================================================
// Note: Actual implementation is in duckdb_impl.odin
// The following are forward declarations
// ============================================================================

init_duckdb_connection :: proc(conn: ^Database_Connection, connection_string: string) -> (Database_Connection, errors.Error)
close_duckdb_connection :: proc(conn: ^Database_Connection) -> errors.Error
execute_duckdb_query :: proc(conn: ^Database_Connection, sql: string, params: ..any) -> QueryResult
execute_duckdb_prepared :: proc(conn: ^Database_Connection, sql: string, params: ..any) -> QueryResult
begin_duckdb_transaction :: proc(conn: ^Database_Connection, options: Transaction_Options) -> errors.Error
commit_duckdb_transaction :: proc(conn: ^Database_Connection) -> errors.Error
rollback_duckdb_transaction :: proc(conn: ^Database_Connection) -> errors.Error

// ============================================================================
// SQLite Implementation - Delegated to sqlite_impl.odin
// ============================================================================
// Note: Actual implementation is in sqlite_impl.odin
// The following are forward declarations
// ============================================================================

init_sqlite_connection :: proc(conn: ^Database_Connection, connection_string: string) -> (Database_Connection, errors.Error)
close_sqlite_connection :: proc(conn: ^Database_Connection) -> errors.Error
execute_sqlite_query :: proc(conn: ^Database_Connection, sql: string, params: ..any) -> QueryResult
execute_sqlite_prepared :: proc(conn: ^Database_Connection, sql: string, params: ..any) -> QueryResult
begin_sqlite_transaction :: proc(conn: ^Database_Connection, options: Transaction_Options) -> errors.Error
commit_sqlite_transaction :: proc(conn: ^Database_Connection) -> errors.Error
rollback_sqlite_transaction :: proc(conn: ^Database_Connection) -> errors.Error
