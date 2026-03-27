// WebUI Helper - Simplified WebUI event handling with JSON serialization
package services

import "core:fmt"
import webui "../lib/webui_lib"
import "../lib/errors"

// ============================================================================
// WebUI Handler Types
// ============================================================================

WebUI_Handler :: proc "c" (^webui.Event)

WebUI_Json_Handler :: proc "c" (^webui.Event) -> string

// ============================================================================
// Request Context
// ============================================================================

WebUI_Context :: struct {
	event      : ^webui.Event,
	window     : webui.Window,
	args       : map[string]json.Value,
	args_json  : string,
	request_id : string,
}

// ============================================================================
// Helper Functions
// ============================================================================

// Initialize context from WebUI event
init_context :: proc(e : ^webui.Event) -> (WebUI_Context, errors.Error) {
	ctx := WebUI_Context{
		event  = e,
		window = e.window,
	}
	
	// Get args JSON (first argument)
	arg_count := webui.webui_get_count(e)
	if arg_count > 0 {
		ctx.args_json = webui.webui_get_string(e)
	}
	
	// Parse arguments
	if ctx.args_json != "" {
		parsed, err := parse_request_args(ctx.args_json)
		if err.code != errors.Error_Code.None {
			return ctx, err
		}
		ctx.args = parsed
	}
	
	return ctx, errors.Error{code = errors.Error_Code.None}
}

// Get string argument
ctx_get_string :: proc(ctx : ^WebUI_Context, name : string, default : string) -> string {
	return get_string_arg(ctx.args, name, default)
}

// Get int argument
ctx_get_int :: proc(ctx : ^WebUI_Context, name : string, default : int) -> int {
	return get_int_arg(ctx.args, name, default)
}

// Get bool argument
ctx_get_bool :: proc(ctx : ^WebUI_Context, name : string, default : bool) -> bool {
	return get_bool_arg(ctx.args, name, default)
}

// Get nested JSON value
ctx_get_json :: proc(ctx : ^WebUI_Context, name : string) -> (json.Value, bool) {
	value, ok := ctx.args[name]
	return value, ok
}

// ============================================================================
// Response Functions
// ============================================================================

// Send success response with data
ctx_respond_success :: proc(ctx : ^WebUI_Context, data : rawptr, type_name : string) -> errors.Error {
	response_json, err := create_success_response(data, type_name)
	if err.code != errors.Error_Code.None {
		return err
	}
	
	webui.webui_event_return_string(ctx.event, response_json)
	return errors.Error{code = errors.Error_Code.None}
}

// Send success response with raw JSON
ctx_respond_success_raw :: proc(ctx : ^WebUI_Context, json_data : string) -> errors.Error {
	response_json, err := create_success_response_raw(json_data)
	if err.code != errors.Error_Code.None {
		return err
	}
	
	webui.webui_event_return_string(ctx.event, response_json)
	return errors.Error{code = errors.Error_Code.None}
}

// Send error response
ctx_respond_error :: proc(ctx : ^WebUI_Context, message : string, code : int) -> errors.Error {
	error_json := create_error_response(message, code)
	webui.webui_event_return_string(ctx.event, error_json)
	return errors.Error{code = errors.Error_Code.None}
}

// Send error response with details
ctx_respond_error_detailed :: proc(ctx : ^WebUI_Context, message : string, code : int, details : []string) -> errors.Error {
	error_json := create_error_response_detailed(message, code, details)
	webui.webui_event_return_string(ctx.event, error_json)
	return errors.Error{code = errors.Error_Code.None}
}

// Send validation error
ctx_respond_validation_error :: proc(ctx : ^WebUI_Context, field_errors : map[string][]string) -> errors.Error {
	error_json := create_validation_error(field_errors)
	webui.webui_event_return_string(ctx.event, error_json)
	return errors.Error{code = errors.Error_Code.None}
}

// ============================================================================
// Wrapper for JSON Handlers
// ============================================================================

// Wrap a JSON handler to handle errors and responses
wrap_json_handler :: proc(handler : WebUI_Json_Handler) -> WebUI_Handler {
	return proc "c" (e : ^webui.Event) {
		// Initialize context
		ctx, err := init_context(e)
		if err.code != errors.Error_Code.None {
			error_json := create_error_response(err.message, 400)
			webui.webui_event_return_string(e, error_json)
			return
		}
		
		// Call handler
		result := handler(e)
		
		// Send result
		if result == "" {
			error_json := create_error_response("Handler returned empty response", 500)
			webui.webui_event_return_string(e, error_json)
		} else {
			webui.webui_event_return_string(e, result)
		}
	}
}

// ============================================================================
// Simple Handler Helpers
// ============================================================================

// Create simple string return handler
create_string_handler :: proc(handler : proc "c" (^webui.Event) -> string) -> WebUI_Handler {
	return proc "c" (e : ^webui.Event) {
		result := handler(e)
		webui.webui_event_return_string(e, result)
	}
}

// Create handler that returns JSON string
create_json_handler :: proc(handler : proc "c" (^webui.Event) -> (string, errors.Error)) -> WebUI_Handler {
	return proc "c" (e : ^webui.Event) {
		result, err := handler(e)
		if err.code != errors.Error_Code.None {
			error_json := create_error_response(err.message, 500)
			webui.webui_event_return_string(e, error_json)
			return
		}
		
		response_json, resp_err := create_success_response_raw(result)
		if resp_err.code != errors.Error_Code.None {
			error_json := create_error_response(resp_err.message, 500)
			webui.webui_event_return_string(e, error_json)
			return
		}
		
		webui.webui_event_return_string(e, response_json)
	}
}

// ============================================================================
// Logging Helper
// ============================================================================

// Log incoming request
log_request :: proc(ctx : ^WebUI_Context, handler_name : string) {
	fmt.printf("[WebUI] Request: %s (request_id=%s)\n", handler_name, ctx.request_id)
	if ctx.args_json != "" {
		fmt.printf("[WebUI] Args: %s\n", ctx.args_json)
	}
}

// Log outgoing response
log_response :: proc(ctx : ^WebUI_Context, handler_name : string, success : bool) {
	status := "OK"
	if !success {
		status = "ERROR"
	}
	fmt.printf("[WebUI] Response: %s - %s (request_id=%s)\n", handler_name, status, ctx.request_id)
}
