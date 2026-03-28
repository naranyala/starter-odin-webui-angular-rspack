// Example WebUI Handlers with proper JSON serialization
// This file demonstrates how to use the serialization service
package main

import "core:fmt"
import webui "../lib/webui_lib"
import services "./services"

// ============================================================================
// Example User Type
// ============================================================================

User :: struct {
	id         : int,
	name       : string,
	email      : string,
	age        : int,
	status     : string,
	created_at : string,
}

// ============================================================================
// Example Handler 1: Using WebUI Helper (Recommended)
// ============================================================================

handle_get_users :: proc "c" (e : ^webui.Event) {
	// Initialize context
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	// Log request
	services.log_request(&ctx, "getUsers")

	// Get users from service (example - replace with actual data access)
	users := get_example_users()
	
	// Convert to JSON array
	users_json := "["
	for i, user in users {
		if i > 0 {
			users_json += ","
		}
		user_json, _ := services.serialize(&user, "User")
		users_json += user_json
	}
	users_json += "]"

	// Send success response
	services.ctx_respond_success_raw(&ctx, users_json)
	services.log_response(&ctx, "getUsers", true)
}

// ============================================================================
// Example Handler 2: Create User with JSON Parsing
// ============================================================================

handle_create_user :: proc "c" (e : ^webui.Event) {
	// Initialize context
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	services.log_request(&ctx, "createUser")

	// Parse user from JSON
	var user : User
	deserialize_err := services.deserialize(ctx.args_json, &user, "User")
	
	if deserialize_err.code != services.errors.Error_Code.None {
		services.ctx_respond_error(&ctx, deserialize_err.message, 400)
		services.log_response(&ctx, "createUser", false)
		return
	}

	// Validate user
	if user.name == "" {
		services.ctx_respond_error(&ctx, "Name is required", 400)
		services.log_response(&ctx, "createUser", false)
		return
	}

	if user.email == "" {
		services.ctx_respond_error(&ctx, "Email is required", 400)
		services.log_response(&ctx, "createUser", false)
		return
	}

	// Set default values
	user.id = 1  // In real app, generate unique ID
	user.status = "active"
	user.created_at = services.now_iso()

	// Save user (example - replace with actual persistence)
	fmt.printf("Creating user: %s (%s)\n", user.name, user.email)

	// Return created user
	response_json, _ := services.create_success_response(&user, "User")
	webui.webui_event_return_string(e, response_json)
	
	services.log_response(&ctx, "createUser", true)
}

// ============================================================================
// Example Handler 3: Update User
// ============================================================================

handle_update_user :: proc "c" (e : ^webui.Event) {
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	services.log_request(&ctx, "updateUser")

	// Get user ID from args
	user_id := services.ctx_get_int(&ctx, "id", 0)
	if user_id <= 0 {
		services.ctx_respond_error(&ctx, "Invalid user ID", 400)
		services.log_response(&ctx, "updateUser", false)
		return
	}

	// Get user data from args
	user_json_value, ok := services.ctx_get_json(&ctx, "user")
	if !ok || user_json_value.type != .Object {
		services.ctx_respond_error(&ctx, "User data required", 400)
		services.log_response(&ctx, "updateUser", false)
		return
	}

	// In real app: fetch user, update fields, save
	fmt.printf("Updating user %d\n", user_id)

	// Return success
	response_json, _ := services.create_success_response_raw(`{"success":true,"message":"User updated"}`)
	webui.webui_event_return_string(e, response_json)
	
	services.log_response(&ctx, "updateUser", true)
}

// ============================================================================
// Example Handler 4: Delete User
// ============================================================================

handle_delete_user :: proc "c" (e : ^webui.Event) {
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	services.log_request(&ctx, "deleteUser")

	// Get user ID
	user_id := services.ctx_get_int(&ctx, "id", 0)
	if user_id <= 0 {
		services.ctx_respond_error(&ctx, "Invalid user ID", 400)
		services.log_response(&ctx, "deleteUser", false)
		return
	}

	// In real app: delete user from database
	fmt.printf("Deleting user %d\n", user_id)

	// Return success
	response_json, _ := services.create_success_response_raw(`{"success":true,"message":"User deleted"}`)
	webui.webui_event_return_string(e, response_json)
	
	services.log_response(&ctx, "deleteUser", true)
}

// ============================================================================
// Example Handler 5: Get User Stats
// ============================================================================

handle_get_user_stats :: proc "c" (e : ^webui.Event) {
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	services.log_request(&ctx, "getUserStats")

	// Calculate stats (example)
	stats := User_Stats{
		total_users    = 15,
		today_count    = 3,
		unique_domains = 8,
	}

	// Return stats
	response_json, _ := services.create_success_response(&stats, "User_Stats")
	webui.webui_event_return_string(e, response_json)
	
	services.log_response(&ctx, "getUserStats", true)
}

// ============================================================================
// Example Handler 6: Echo (for testing)
// ============================================================================

handle_echo :: proc "c" (e : ^webui.Event) {
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	services.log_request(&ctx, "echo")

	// Echo back the arguments
	echo_response := fmt.Sprintf(`{"received":%s,"timestamp":"%s"}`, ctx.args_json, services.now_iso())
	
	services.ctx_respond_success_raw(&ctx, echo_response)
	services.log_response(&ctx, "echo", true)
}

// ============================================================================
// Example Handler 7: Validation Error Demo
// ============================================================================

handle_validation_test :: proc "c" (e : ^webui.Event) {
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	// Create validation errors for demo
	field_errors := make(map[string][]string)
	append(&field_errors["name"], "Name is required")
	append(&field_errors["email"], "Invalid email format")
	append(&field_errors["age"], "Age must be between 1 and 150")

	error_json := services.create_validation_error(field_errors)
	webui.webui_event_return_string(e, error_json)
}

// ============================================================================
// Helper Functions
// ============================================================================

User_Stats :: struct {
	total_users    : int,
	today_count    : int,
	unique_domains : int,
}

get_example_users :: proc() -> []User {
	users := make([]User, 0)
	
	append(&users, User{
		id         = 1,
		name       = "John Doe",
		email      = "john@example.com",
		age        = 30,
		status     = "active",
		created_at = "2026-01-15T10:30:00Z",
	})
	
	append(&users, User{
		id         = 2,
		name       = "Jane Smith",
		email      = "jane@example.com",
		age        = 25,
		status     = "active",
		created_at = "2026-02-20T14:45:00Z",
	})
	
	append(&users, User{
		id         = 3,
		name       = "Bob Johnson",
		email      = "bob@example.com",
		age        = 35,
		status     = "inactive",
		created_at = "2026-03-10T09:15:00Z",
	})
	
	return users
}

// ============================================================================
// Register Handlers
// ============================================================================

register_webui_handlers :: proc(win : webui.Window) {
	webui.bind(win, "getUsers", handle_get_users)
	webui.bind(win, "createUser", handle_create_user)
	webui.bind(win, "updateUser", handle_update_user)
	webui.bind(win, "deleteUser", handle_delete_user)
	webui.bind(win, "getUserStats", handle_get_user_stats)
	webui.bind(win, "echo", handle_echo)
	webui.bind(win, "validationTest", handle_validation_test)
	
	fmt.println("[WebUI] Handlers registered with JSON serialization")
}
