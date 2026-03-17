// Application Models and Data Types
package models

// ============================================================================
// Application Types
// ============================================================================

// Application configuration
App_Config :: struct {
    name : string,
    version : string,
    debug_mode : bool,
    log_level : int,
    data_dir : string,
    config_file : string,
}

// User model
User :: struct {
    id : string,
    username : string,
    email : string,
    created_at : u64,
    is_active : bool,
}

// Application state
App_State :: struct {
    is_initialized : bool,
    is_running : bool,
    current_user : ^User,
    config : App_Config,
}

// Result types for operations
Result :: struct {
    success : bool,
    message : string,
    data : rawptr,
}

// ============================================================================
// Common Data Structures
// ============================================================================

// Key-Value pair
KeyValuePair :: struct {
    key : string,
    value : string,
}

// Named item
Named_Item :: struct {
    id : int,
    name : string,
    description : string,
}

// Status with code and message
Status :: struct {
    code : int,
    message : string,
    details : string,
}

// ============================================================================
// Event Types
// ============================================================================

// Application events
App_Event_Type :: enum {
    Initialized,
    Started,
    Stopped,
    Error,
    Config_Loaded,
    User_Login,
    User_Logout,
}

// Application event
App_Event :: struct {
    event_type : App_Event_Type,
    timestamp : u64,
    source : string,
    data : rawptr,
}

// ============================================================================
// Helper Functions
// ============================================================================

// Create default app config
default_config :: proc() -> App_Config {
    return App_Config{
        name = "Odin WebUI App",
        version = "1.0.0",
        debug_mode = false,
        log_level = 2,  // Info
        data_dir = "./data",
        config_file = "./config.json",
    }
}

// Create success result
result_success :: proc(message : string = "Success") -> Result {
    return Result{
        success = true,
        message = message,
        data = nil,
    }
}

// Create error result
result_error :: proc(message : string) -> Result {
    return Result{
        success = false,
        message = message,
        data = nil,
    }
}

// Create status
status_ok :: proc(message : string = "OK") -> Status {
    return Status{
        code = 0,
        message = message,
        details = "",
    }
}

status_error :: proc(code : int, message : string, details : string = "") -> Status {
    return Status{
        code = code,
        message = message,
        details = details,
    }
}
