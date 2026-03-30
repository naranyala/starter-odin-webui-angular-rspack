// ============================================================================
// CRUD Service - Generic CRUD Operations
// ============================================================================
// Provides type-safe CRUD operations for any entity type
// Supports validation, auditing, and event publishing
// ============================================================================

package crud

import "core:fmt"
import "core:sync"
import "../lib/errors"
import "../lib/events"
import "../lib/database"

// ============================================================================
// Types and Constants
// ============================================================================

// Entity is the base interface for all entities
Entity :: interface {
    get_id() -> int,
    set_id(int),
}

// CRUD Operations
CRUD_Operation :: enum {
    Create,
    Read,
    Update,
    Delete,
}

// Audit log entry
Audit_Entry :: struct {
    operation   : CRUD_Operation,
    entity_type : string,
    entity_id   : int,
    timestamp   : i64,
    user_id     : int,
    details     : string,
}

// CRUD Event data
CRUD_Event :: struct {
    operation   : CRUD_Operation,
    entity_type : string,
    entity_id   : int,
    data        : rawptr,
    timestamp   : i64,
}

// ============================================================================
// CRUD Service
// ============================================================================

// CRUD_Service provides generic CRUD operations
CRUD_Service :: struct {
    mutex           : sync.Mutex,
    db_connection   : ^database.Database_Connection,
    event_bus       : ^events.Event_Bus,
    audit_enabled   : bool,
    audit_log       : []Audit_Entry,
}

// init_crud_service initializes a CRUD service
init_crud_service :: proc(db: ^database.Database_Connection, event_bus: ^events.Event_Bus) -> CRUD_Service {
    return CRUD_Service{
        db_connection = db,
        event_bus = event_bus,
        audit_enabled = true,
        audit_log = make([]Audit_Entry, 0),
    }
}

// ============================================================================
// Generic CRUD Operations
// ============================================================================

// create inserts a new entity into the database
create :: proc(svc: ^CRUD_Service, entity: Entity, table_name: string) -> (int, errors.Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Validate entity
    if err := validate_entity(entity); err.code != .None {
        return 0, err
    }
    
    // Build INSERT query
    sql := fmt.Sprintf("INSERT INTO %s (...) VALUES (...)", table_name)
    
    // Execute query
    result := database.execute_prepared(svc.db_connection, sql)
    
    if result.error.code != .None {
        return 0, result.error
    }
    
    // Audit
    if svc.audit_enabled {
        svc.log_audit(.Create, table_name, int(result.last_insert_id), "Entity created")
    }
    
    // Publish event
    svc.publish_event(.Create, table_name, int(result.last_insert_id), entity)
    
    return int(result.last_insert_id), errors.Error{code: .None}
}

// get_by_id retrieves an entity by its ID
get_by_id :: proc(svc: ^CRUD_Service, id: int, table_name: string) -> (rawptr, errors.Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Build SELECT query
    sql := fmt.Sprintf("SELECT * FROM %s WHERE id = ?", table_name)
    
    // Execute query
    result := database.execute_prepared(svc.db_connection, sql, id)
    
    if result.error.code != .None {
        return nil, result.error
    }
    
    // Audit
    if svc.audit_enabled {
        svc.log_audit(.Read, table_name, id, "Entity retrieved")
    }
    
    return result.data, errors.Error{code: .None}
}

// get_all retrieves all entities from the table
get_all :: proc(svc: ^CRUD_Service, table_name: string, order_by: string = "id") -> ([]rawptr, errors.Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Build SELECT query
    sql := fmt.Sprintf("SELECT * FROM %s ORDER BY %s", table_name, order_by)
    
    // Execute query
    result := database.execute_query(svc.db_connection, sql)
    
    if result.error.code != .None {
        return nil, result.error
    }
    
    // Audit
    if svc.audit_enabled {
        svc.log_audit(.Read, table_name, 0, "All entities retrieved")
    }
    
    return convert_result_to_entities(result.data), errors.Error{code: .None}
}

// update modifies an existing entity
update :: proc(svc: ^CRUD_Service, entity: Entity, table_name: string) -> errors.Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    entity_id := entity.get_id()
    
    // Validate entity
    if err := validate_entity(entity); err.code != .None {
        return err
    }
    
    // Build UPDATE query
    sql := fmt.Sprintf("UPDATE %s SET ... WHERE id = ?", table_name)
    
    // Execute query
    result := database.execute_prepared(svc.db_connection, sql, entity_id)
    
    if result.error.code != .None {
        return result.error
    }
    
    // Audit
    if svc.audit_enabled {
        svc.log_audit(.Update, table_name, entity_id, "Entity updated")
    }
    
    // Publish event
    svc.publish_event(.Update, table_name, entity_id, entity)
    
    return errors.Error{code: .None}
}

// delete removes an entity from the database
delete :: proc(svc: ^CRUD_Service, id: int, table_name: string) -> errors.Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Build DELETE query
    sql := fmt.Sprintf("DELETE FROM %s WHERE id = ?", table_name)
    
    // Execute query
    result := database.execute_prepared(svc.db_connection, sql, id)
    
    if result.error.code != .None {
        return result.error
    }
    
    // Audit
    if svc.audit_enabled {
        svc.log_audit(.Delete, table_name, id, "Entity deleted")
    }
    
    // Publish event
    svc.publish_event(.Delete, table_name, id, nil)
    
    return errors.Error{code: .None}
}

// ============================================================================
// Query Operations
// ============================================================================

// query executes a custom query with parameters
query :: proc(svc: ^CRUD_Service, sql: string, params: ..any) -> (QueryResult, errors.Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    result := database.execute_prepared(svc.db_connection, sql, params..)
    
    if result.error.code != .None {
        return QueryResult{}, result.error
    }
    
    return QueryResult{
        rows_affected = result.rows_affected,
        data = result.data,
    }, errors.Error{code: .None}
}

// count returns the count of entities in a table
count :: proc(svc: ^CRUD_Service, table_name: string, where_clause: string = "") -> (int, errors.Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    sql := fmt.Sprintf("SELECT COUNT(*) FROM %s", table_name)
    if where_clause != "" {
        sql += fmt.Sprintf(" WHERE %s", where_clause)
    }
    
    result := database.execute_query(svc.db_connection, sql)
    
    if result.error.code != .None {
        return 0, result.error
    }
    
    return extract_count(result.data), errors.Error{code: .None}
}

// exists checks if an entity exists
exists :: proc(svc: ^CRUD_Service, id: int, table_name: string) -> (bool, errors.Error) {
    count, err := count(svc, table_name, fmt.Sprintf("id = %d", id))
    if err.code != .None {
        return false, err
    }
    
    return count > 0, errors.Error{code: .None}
}

// ============================================================================
// Audit Functions
// ============================================================================

// log_audit logs an audit entry
log_audit :: proc(svc: ^CRUD_Service, operation: CRUD_Operation, entity_type: string, entity_id: int, details: string) {
    entry := Audit_Entry{
        operation = operation,
        entity_type = entity_type,
        entity_id = entity_id,
        timestamp = get_timestamp(),
        user_id = 0,  // TODO: Get from context
        details = details,
    }
    
    svc.audit_log = append(svc.audit_log, entry)
    
    // Keep only last 1000 entries
    if len(svc.audit_log) > 1000 {
        svc.audit_log = svc.audit_log[1:]
    }
}

// get_audit_log returns the audit log
get_audit_log :: proc(svc: ^CRUD_Service) -> []Audit_Entry {
    return svc.audit_log
}

// clear_audit_log clears the audit log
clear_audit_log :: proc(svc: ^CRUD_Service) {
    svc.audit_log = make([]Audit_Entry, 0)
}

// ============================================================================
// Event Publishing
// ============================================================================

// publish_event publishes a CRUD event
publish_event :: proc(svc: ^CRUD_Service, operation: CRUD_Operation, entity_type: string, entity_id: int, data: rawptr) {
    if svc.event_bus == nil {
        return
    }
    
    event := CRUD_Event{
        operation = operation,
        entity_type = entity_type,
        entity_id = entity_id,
        data = data,
        timestamp = get_timestamp(),
    }
    
    event_name := fmt.Sprintf("crud:%s:%s", operation, entity_type)
    events.publish(svc.event_bus, event_name, &event)
}

// ============================================================================
// Helper Functions
// ============================================================================

// validate_entity validates an entity before CRUD operations
validate_entity :: proc(entity: Entity) -> errors.Error {
    // TODO: Implement validation
    return errors.Error{code: .None}
}

// convert_result_to_entities converts query result to entity slice
convert_result_to_entities :: proc(data: rawptr) -> []rawptr {
    // TODO: Implement conversion
    return make([]rawptr, 0)
}

// extract_count extracts count from query result
extract_count :: proc(data: rawptr) -> int {
    // TODO: Implement extraction
    return 0
}

// get_timestamp returns current timestamp
get_timestamp :: proc() -> i64 {
    return 0  // TODO: Implement timestamp
}

// ============================================================================
// Query Result Type
// ============================================================================

QueryResult :: struct {
    rows_affected : int,
    data          : rawptr,
}
