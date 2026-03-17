// Error Handling Package for Odin Backend - Simplified Version
package errors

import "core:fmt"
import "core:time"

// Error codes
Error_Code :: enum int {
    None = 0,
    Unknown,
    Internal,
    Invalid_State,
    Timeout,
    Not_Found,
    Already_Exists,
    Invalid_Parameter,
    IO_Error,
    File_Error,
    Network_Error,
    Parse_Error,
    Validation_Error,
    Not_Implemented,
    DI_Error,
    Comms_Error,
    RPC_Error,
}

// Error severity
Error_Severity :: enum {
    Info,
    Warning,
    Error,
    Critical,
}

// Error type
Error :: struct {
    code : Error_Code,
    message : string,
    details : string,
    severity : Error_Severity,
    timestamp : time.Time,
}

// Error result for function returns
Error_Result :: struct {
    err : Error,
    has_error : bool,
}

// Create error
new :: proc(code : Error_Code, message : string) -> Error {
    return Error{
        code = code,
        message = message,
        severity = Error_Severity.Error,
        timestamp = time.now(),
    }
}

// Create error with details
new_detailed :: proc(code : Error_Code, message : string, details : string) -> Error {
    err := new(code, message)
    err.details = details
    return err
}

// Create error result with error
result_error :: proc(err : Error) -> Error_Result {
    return Error_Result{err = err, has_error = true}
}

// Create success result
result_ok :: proc() -> Error_Result {
    return Error_Result{has_error = false}
}

// Check if error exists
check :: proc(err : Error) -> bool {
    return err.code != Error_Code.None
}

// Check error result
check_result :: proc(result : Error_Result) -> bool {
    return result.has_error
}

// Format error as string
error_string :: proc(err : ^Error) -> string {
    if err == nil {
        return "nil"
    }
    if err.details != "" {
        return err.message
    }
    return err.message
}

// Log error
log_error :: proc(err : Error) {
    fmt.printf("[ERROR] %s\n", err.message)
    if err.details != "" {
        fmt.printf("  Details: %s\n", err.details)
    }
}

// Convenience error creators
err_unknown :: proc(message : string) -> Error { return new(Error_Code.Unknown, message) }
err_internal :: proc(message : string) -> Error { return new(Error_Code.Internal, message) }
err_timeout :: proc(message : string) -> Error { return new(Error_Code.Timeout, message) }
err_not_found :: proc(message : string) -> Error { return new(Error_Code.Not_Found, message) }
err_invalid_param :: proc(message : string) -> Error { return new(Error_Code.Invalid_Parameter, message) }
err_io :: proc(message : string) -> Error { return new(Error_Code.IO_Error, message) }
err_not_implemented :: proc() -> Error { return new(Error_Code.Not_Implemented, "Not implemented") }
err_di :: proc(message : string) -> Error { return new(Error_Code.DI_Error, message) }
err_comms :: proc(message : string) -> Error { return new(Error_Code.Comms_Error, message) }
err_rpc :: proc(message : string) -> Error { return new(Error_Code.RPC_Error, message) }

// None error (success)
err_none :: proc() -> Error { return Error{code = Error_Code.None} }
