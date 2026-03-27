// Serialization Service - JSON handling for WebUI communication
package services

import "core:encoding/json"
import "core:fmt"
import "core:time"
import "../lib/errors"

// ============================================================================
// API Response Types
// ============================================================================

Api_Response :: struct {
	success    : bool,
	data       : string,  // JSON-encoded data
	error      : string,
	code       : int,
	request_id : string,
	timestamp  : i64,
}

Api_Error :: struct {
	success    : bool,
	error      : string,
	code       : int,
	details    : []string,
	request_id : string,
	timestamp  : i64,
}

// ============================================================================
// Serialization Functions
// ============================================================================

// Serialize any struct to JSON string
serialize :: proc(data : rawptr, type_name : string) -> (string, errors.Error) {
	if data == nil {
		return "", errors.err_invalid_param("Cannot serialize nil pointer")
	}
	
	json_data, json_err := json.marshal(data)
	if json_err != nil {
		return "", errors.err_parse(fmt.Sprintf("JSON marshal error: %v", json_err))
	}
	defer delete(json_data)
	
	return string(json_data), errors.Error{code = errors.Error_Code.None}
}

// Deserialize JSON string to struct
deserialize :: proc(json_str : string, data : rawptr, type_name : string) -> errors.Error {
	if data == nil {
		return errors.err_invalid_param("Cannot deserialize to nil pointer")
	}
	
	if json_str == "" {
		return errors.err_invalid_param("Cannot deserialize empty string")
	}
	
	json_err := json.unmarshal(json_str, data)
	if json_err != nil {
		return errors.err_parse(fmt.Sprintf("JSON unmarshal error: %v", json_err))
	}
	
	return errors.Error{code = errors.Error_Code.None}
}

// ============================================================================
// Response Builder Functions
// ============================================================================

// Create success response with data
create_success_response :: proc(data : rawptr, type_name : string) -> (string, errors.Error) {
	json_data, err := serialize(data, type_name)
	if err.code != errors.Error_Code.None {
		return "", err
	}
	
	response := Api_Response{
		success    = true,
		data       = json_data,
		code       = 200,
		request_id = generate_request_id(),
		timestamp  = time.now().unix(),
	}
	
	response_json, marshal_err := json.marshal(response)
	if marshal_err != nil {
		return "", errors.err_parse(fmt.Sprintf("Failed to marshal response: %v", marshal_err))
	}
	defer delete(response_json)
	
	return string(response_json), errors.Error{code = errors.Error_Code.None}
}

// Create success response with raw JSON data
create_success_response_raw :: proc(json_data : string) -> (string, errors.Error) {
	response := Api_Response{
		success    = true,
		data       = json_data,
		code       = 200,
		request_id = generate_request_id(),
		timestamp  = time.now().unix(),
	}
	
	response_json, marshal_err := json.marshal(response)
	if marshal_err != nil {
		return "", errors.err_parse(fmt.Sprintf("Failed to marshal response: %v", marshal_err))
	}
	defer delete(response_json)
	
	return string(response_json), errors.Error{code = errors.Error_Code.None}
}

// Create error response
create_error_response :: proc(message : string, code : int) -> string {
	return create_error_response_detailed(message, code, nil)
}

// Create error response with details
create_error_response_detailed :: proc(message : string, code : int, details : []string) -> string {
	error := Api_Error{
		success    = false,
		error      = message,
		code       = code,
		details    = details,
		request_id = generate_request_id(),
		timestamp  = time.now().unix(),
	}
	
	error_json, marshal_err := json.marshal(error)
	if marshal_err != nil {
		// Fallback to simple error
		return fmt.Sprintf(`{"success":false,"error":"%s","code":%d}`, message, code)
	}
	defer delete(error_json)
	
	return string(error_json)
}

// Create validation error response
create_validation_error :: proc(field_errors : map[string][]string) -> string {
	details := make([]string, 0)
	for field, messages in field_errors {
		for msg in messages {
			append(&details, fmt.Sprintf("%s: %s", field, msg))
		}
	}
	
	return create_error_response_detailed("Validation failed", 400, details)
}

// Create not found error response
create_not_found_error :: proc(resource : string) -> string {
	return create_error_response(fmt.Sprintf("%s not found", resource), 404)
}

// Create unauthorized error response
create_unauthorized_error :: proc() -> string {
	return create_error_response("Unauthorized", 401)
}

// Create bad request error response
create_bad_request_error :: proc(message : string) -> string {
	return create_error_response(message, 400)
}

// ============================================================================
// Request Parsing Functions
// ============================================================================

// Parse request arguments from WebUI event
// Expects JSON array: [arg1, arg2, ...]
parse_request_args :: proc(args_json : string) -> (map[string]json.Value, errors.Error) {
	if args_json == "" {
		return nil, errors.Error{code = errors.Error_Code.None}  // No args is OK
	}
	
	var root json.Value
	json_err := json.unmarshal(args_json, &root)
	if json_err != nil {
		return nil, errors.err_parse(fmt.Sprintf("Failed to parse args: %v", json_err))
	}
	
	// If it's an array, convert to map by index
	if root.type == .Array {
		result := make(map[string]json.Value)
		for i, value in root.array_value {
			result[fmt.Sprintf("arg%d", i)] = value
		}
		return result, errors.Error{code = errors.Error_Code.None}
	}
	
	// If it's an object, return as-is
	if root.type == .Object {
		return root.object_value, errors.Error{code = errors.Error_Code.None}
	}
	
	return nil, errors.err_invalid_param("Expected array or object")
}

// Get string argument from parsed args
get_string_arg :: proc(args : map[string]json.Value, name : string, default : string) -> string {
	if value, ok := args[name]; ok && value.type == .String {
		return value.string_value
	}
	return default
}

// Get int argument from parsed args
get_int_arg :: proc(args : map[string]json.Value, name : string, default : int) -> int {
	if value, ok := args[name]; ok && value.type == .Number {
		return int(value.number_value)
	}
	return default
}

// Get bool argument from parsed args
get_bool_arg :: proc(args : map[string]json.Value, name : string, default : bool) -> bool {
	if value, ok := args[name]; ok && value.type == .Bool {
		return value.bool_value
	}
	return default
}

// ============================================================================
// Utility Functions
// ============================================================================

// Generate unique request ID
generate_request_id :: proc() -> string {
	// Simple request ID: "req_" + timestamp + random
	now := time.now().unix()
	random := rand_int(0, 999999)
	return fmt.Sprintf("req_%d_%d", now, random)
}

// Simple random number generator (for request IDs)
rand_int :: proc(min : int, max : int) -> int {
	// Simple LCG-based random (good enough for request IDs)
	static seed : i64 = 0
	if seed == 0 {
		seed = time.now().unix()
	}
	seed = (seed * 1103515245 + 12345) % (1 << 31)
	return min + int(seed) % (max - min + 1)
}

// Check if JSON string is valid
is_valid_json :: proc(json_str : string) -> bool {
	if json_str == "" {
		return false
	}
	
	var value json.Value
	json_err := json.unmarshal(json_str, &value)
	return json_err == nil
}

// Pretty print JSON
pretty_print_json :: proc(json_str : string) -> (string, errors.Error) {
	if !is_valid_json(json_str) {
		return "", errors.err_invalid_param("Invalid JSON")
	}
	
	var value json.Value
	json_err := json.unmarshal(json_str, &value)
	if json_err != nil {
		return "", errors.err_parse(fmt.Sprintf("JSON error: %v", json_err))
	}
	
	pretty_json, marshal_err := json.marshal_indent(value, "  ")
	if marshal_err != nil {
		return "", errors.err_parse(fmt.Sprintf("Marshal error: %v", marshal_err))
	}
	defer delete(pretty_json)
	
	return string(pretty_json), errors.Error{code = errors.Error_Code.None}
}

// ============================================================================
// Date/Time Helpers
// ============================================================================

// Parse ISO 8601 date string
parse_iso_date :: proc(iso_string : string) -> (time.Time, errors.Error) {
	if iso_string == "" {
		return time.Time{}, errors.err_invalid_param("Empty date string")
	}
	
	// Try common ISO 8601 formats
	formats := []string{
		"2006-01-02T15:04:05Z07:00",
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
		"2006-01-02",
	}
	
	for format in formats {
		t, err := time.parse(format, iso_string)
		if err == nil {
			return t, errors.Error{code = errors.Error_Code.None}
		}
	}
	
	return time.Time{}, errors.err_parse(fmt.Sprintf("Invalid date format: %s", iso_string))
}

// Format time to ISO 8601 string
format_iso_date :: proc(t : time.Time) -> string {
	return t.format("2006-01-02T15:04:05Z07:00")
}

// Get current timestamp as ISO string
now_iso :: proc() -> string {
	return format_iso_date(time.now())
}
