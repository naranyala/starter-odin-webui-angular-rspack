// Error Handling Package for Odin Backend - Errors as Values Pattern
package errors

import "core:fmt"
import "core:time"

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
	Auth_Error,
	Cache_Error,
	Storage_Error,
}

Error_Severity :: enum {
	Info,
	Warning,
	Error,
	Critical,
}

Error :: struct {
	code:     Error_Code,
	message:  string,
	details:  string,
	severity: Error_Severity,
	timestamp: time.Time,
}

Error_Result :: struct {
	err: Error,
	ok:  bool,
}

new :: proc(code: Error_Code, message: string) -> Error {
	return Error{
		code     = code,
		message  = message,
		severity = Error_Severity.Error,
		timestamp = time.now(),
	}
}

new_detailed :: proc(code: Error_Code, message: string, details: string) -> Error {
	err := new(code, message)
	err.details = details
	return err
}

result :: proc(err: Error) -> (rawptr, Error) {
	return nil, err
}

ok :: proc() -> (rawptr, Error) {
	return nil, Error{code = Error_Code.None}
}

from_error :: proc(err: Error) -> (rawptr, Error) {
	return nil, err
}

ok_bool :: proc() -> (bool, Error) {
	return true, Error{code = Error_Code.None}
}

from_bool :: proc(ok: bool, code: Error_Code, message: string) -> (bool, Error) {
	if ok {
		return true, Error{code = Error_Code.None}
	}
	return false, new(code, message)
}

ok_int :: proc() -> (int, Error) {
	return 0, Error{code = Error_Code.None}
}

from_int :: proc(val: int, err: Error) -> (int, Error) {
	return val, err
}

check :: proc(err: Error) -> bool {
	return err.code != Error_Code.None
}

is_ok :: proc(err: Error) -> bool {
	return err.code == Error_Code.None
}

error_string :: proc(err: ^Error) -> string {
	if err == nil {
		return "nil"
	}
	if err.details != "" {
		return fmt.Sprintf("%s: %s", err.message, err.details)
	}
	return err.message
}

log_error :: proc(err: Error) {
	fmt.printf("[ERROR] %s\n", err.message)
	if err.details != "" {
		fmt.printf("  Details: %s\n", err.details)
	}
}

log_warning :: proc(err: Error) {
	fmt.printf("[WARN] %s\n", err.message)
}

err_none :: proc() -> Error { return Error{code = Error_Code.None} }

err_unknown :: proc(message: string) -> Error { return new(Error_Code.Unknown, message) }
err_internal :: proc(message: string) -> Error { return new(Error_Code.Internal, message) }
err_timeout :: proc(message: string) -> Error { return new(Error_Code.Timeout, message) }
err_not_found :: proc(message: string) -> Error { return new(Error_Code.Not_Found, message) }
err_invalid_param :: proc(message: string) -> Error { return new(Error_Code.Invalid_Parameter, message) }
err_io :: proc(message: string) -> Error { return new(Error_Code.IO_Error, message) }
err_file :: proc(message: string) -> Error { return new(Error_Code.File_Error, message) }
err_network :: proc(message: string) -> Error { return new(Error_Code.Network_Error, message) }
err_parse :: proc(message: string) -> Error { return new(Error_Code.Parse_Error, message) }
err_validation :: proc(message: string) -> Error { return new(Error_Code.Validation_Error, message) }
err_not_implemented :: proc() -> Error { return new(Error_Code.Not_Implemented, "Not implemented") }
err_di :: proc(message: string) -> Error { return new(Error_Code.DI_Error, message) }
err_comms :: proc(message: string) -> Error { return new(Error_Code.Comms_Error, message) }
err_rpc :: proc(message: string) -> Error { return new(Error_Code.RPC_Error, message) }
err_auth :: proc(message: string) -> Error { return new(Error_Code.Auth_Error, message) }
err_cache :: proc(message: string) -> Error { return new(Error_Code.Cache_Error, message) }
err_storage :: proc(message: string) -> Error { return new(Error_Code.Storage_Error, message) }
