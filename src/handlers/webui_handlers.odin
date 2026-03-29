// Example Handler 1: Using WebUI Helper (Recommended)
// This file demonstrates how to use the serialization service
package main

import "core:fmt"
import "core:time"
import webui "../lib/webui_lib"
import services "./services"

// ============================================================================
// Example User Type - MUST match frontend User interface
// ============================================================================

User :: struct {
	id         : int,
	name       : string,
	email      : string,
	role       : string,  // "User", "Admin", "Manager"
	status     : string,  // "Active", "Inactive", "Pending"
	created_at : string,  // ISO 8601 format string
}

// ============================================================================
// Product Type - MUST match frontend Product interface
// ============================================================================

Product :: struct {
	id         : int,
	name       : string,
	price      : f64,
	category   : string,
	status     : string,  // "Available", "OutOfStock", "Discontinued"
	created_at : string,  // ISO 8601 format string
}

// ============================================================================
// Order Type - MUST match frontend Order interface
// ============================================================================

Order :: struct {
	id            : int,
	customer_name : string,
	total         : f64,
	status        : string,  // "Pending", "Processing", "Shipped", "Delivered", "Cancelled"
	created_at    : string,  // ISO 8601 format string
}

// ============================================================================
// Stats Type
// ============================================================================

Dashboard_Stats :: struct {
	total_users    : int,
	total_products : int,
	total_orders   : int,
	total_revenue  : f64,
	active_users   : int,
	pending_orders : int,
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
// Get Products Handler
// ============================================================================

handle_get_products :: proc "c" (e : ^webui.Event) {
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	services.log_request(&ctx, "getProducts")

	products := get_example_products()
	
	products_json := "["
	for i, product in products {
		if i > 0 {
			products_json += ","
		}
		product_json, _ := services.serialize(&product, "Product")
		products_json += product_json
	}
	products_json += "]"

	services.ctx_respond_success_raw(&ctx, products_json)
	services.log_response(&ctx, "getProducts", true)
}

// ============================================================================
// Get Orders Handler
// ============================================================================

handle_get_orders :: proc "c" (e : ^webui.Event) {
	ctx, err := services.init_context(e)
	if err.code != services.errors.Error_Code.None {
		error_json := services.create_error_response(err.message, 400)
		webui.webui_event_return_string(e, error_json)
		return
	}

	services.log_request(&ctx, "getOrders")

	orders := get_example_orders()
	
	orders_json := "["
	for i, order in orders {
		if i > 0 {
			orders_json += ","
		}
		order_json, _ := services.serialize(&order, "Order")
		orders_json += order_json
	}
	orders_json += "]"

	services.ctx_respond_success_raw(&ctx, orders_json)
	services.log_response(&ctx, "getOrders", true)
}

// ============================================================================
// Example Handler 2: Create User with JSON Parsing and Validation
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

	// Validate user using validation service
	validation := services.validate_user(user.name, user.email, "")
	if !validation.valid {
		error_json := services.create_validation_error_response(validation)
		webui.webui_event_return_string(e, error_json)
		services.log_response(&ctx, "createUser", false)
		return
	}

	// Set default values
	user.id = 1  // In real app, generate unique ID
	user.status = "Active"
	user.created_at = services.now_iso()

	// Save user (example - replace with actual persistence)
	services.log_info(&ctx, fmt.Sprintf("Creating user: %s (%s)", user.name, user.email))

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

/**
 * Get current ISO 8601 timestamp
 */
now_iso :: proc() -> string {
	return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.utc(time.now()))
}

get_example_users :: proc() -> []User {
	users := make([]User, 0)
	now := now_iso()

	append(&users, User{
		id         = 1,
		name       = "John Doe",
		email      = "john@example.com",
		role       = "Admin",
		status     = "Active",
		created_at = now,
	})

	append(&users, User{
		id         = 2,
		name       = "Jane Smith",
		email      = "jane@example.com",
		role       = "User",
		status     = "Active",
		created_at = now,
	})

	append(&users, User{
		id         = 3,
		name       = "Bob Johnson",
		email      = "bob@example.com",
		role       = "Manager",
		status     = "Inactive",
		created_at = now,
	})

	return users
}

get_example_products :: proc() -> []Product {
	products := make([]Product, 0)
	now := now_iso()

	append(&products, Product{
		id         = 1,
		name       = "Laptop Pro",
		price      = 1299.99,
		category   = "Electronics",
		status     = "Available",
		created_at = now,
	})

	append(&products, Product{
		id         = 2,
		name       = "Wireless Mouse",
		price      = 29.99,
		category   = "Accessories",
		status     = "Available",
		created_at = now,
	})

	append(&products, Product{
		id         = 3,
		name       = "Mechanical Keyboard",
		price      = 89.99,
		category   = "Accessories",
		status     = "OutOfStock",
		created_at = now,
	})

	return products
}

get_example_orders :: proc() -> []Order {
	orders := make([]Order, 0)
	now := now_iso()

	append(&orders, Order{
		id            = 1,
		customer_name = "John Doe",
		total         = 1329.98,
		status        = "Delivered",
		created_at    = now,
	})

	append(&orders, Order{
		id            = 2,
		customer_name = "Jane Smith",
		total         = 29.99,
		status        = "Processing",
		created_at    = now,
	})

	append(&orders, Order{
		id            = 3,
		customer_name = "Bob Johnson",
		total         = 89.99,
		status        = "Pending",
		created_at    = now,
	})

	return orders
}

// ============================================================================
// Register Handlers
// ============================================================================

register_webui_handlers :: proc(win : webui.Window) {
	webui.bind(win, "getUsers", handle_get_users)
	webui.bind(win, "getProducts", handle_get_products)
	webui.bind(win, "getOrders", handle_get_orders)
	webui.bind(win, "createUser", handle_create_user)
	webui.bind(win, "updateUser", handle_update_user)
	webui.bind(win, "deleteUser", handle_delete_user)
	webui.bind(win, "getUserStats", handle_get_user_stats)
	webui.bind(win, "echo", handle_echo)
	webui.bind(win, "validationTest", handle_validation_test)
	
	fmt.println("[WebUI] Handlers registered with JSON serialization")
}
