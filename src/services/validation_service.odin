// Input Validation Utility for Odin Backend
// Provides consistent validation across all handlers
package services

import "core:fmt"
import "core:unicode/utf8"
import "../lib/errors"

// ============================================================================
// Validation Result
// ============================================================================

Validation_Error :: struct {
	field   : string,
	message : string,
	code    : string,
}

Validation_Result :: struct {
	valid  : bool,
	errors : []Validation_Error,
}

// ============================================================================
// Validation Functions
// ============================================================================

/**
 * Create a new validation result with no errors
 */
validation_ok :: proc() -> Validation_Result {
	return Validation_Result{valid = true, errors = make([]Validation_Error, 0)}
}

/**
 * Add an error to validation result
 */
validation_add_error :: proc(result: ^Validation_Result, field: string, message: string, code: string = "INVALID") {
	append(&result.errors, Validation_Error{
		field   = field,
		message = message,
		code    = code,
	})
	result.valid = false
}

/**
 * Merge another validation result into this one
 */
validation_merge :: proc(result: ^Validation_Result, other: Validation_Result) {
	if !other.valid {
		for err in other.errors {
			append(&result.errors, err)
		}
		result.valid = false
	}
}

// ============================================================================
// String Validators
// ============================================================================

/**
 * Validate string is not empty
 */
validate_not_empty :: proc(value: string, field: string) -> Validation_Error {
	if value == "" {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s cannot be empty", field),
			code    = "REQUIRED",
		}
	}
	return Validation_Error{}
}

/**
 * Validate string minimum length
 */
validate_min_length :: proc(value: string, min: int, field: string) -> Validation_Error {
	if utf8.string_length(value) < min {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at least %d characters", field, min),
			code    = "MIN_LENGTH",
		}
	}
	return Validation_Error{}
}

/**
 * Validate string maximum length
 */
validate_max_length :: proc(value: string, max: int, field: string) -> Validation_Error {
	if utf8.string_length(value) > max {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at most %d characters", field, max),
			code    = "MAX_LENGTH",
		}
	}
	return Validation_Error{}
}

/**
 * Validate string length range
 */
validate_length :: proc(value: string, min: int, max: int, field: string) -> Validation_Error {
	length := utf8.string_length(value)
	if length < min {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at least %d characters", field, min),
			code    = "MIN_LENGTH",
		}
	}
	if length > max {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at most %d characters", field, max),
			code    = "MAX_LENGTH",
		}
	}
	return Validation_Error{}
}

/**
 * Validate string matches pattern (simple contains check)
 */
validate_contains :: proc(value: string, substr: string, field: string) -> Validation_Error {
	if !utf8.string_contains(value, substr) {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must contain '%s'", field, substr),
			code    = "PATTERN",
		}
	}
	return Validation_Error{}
}

/**
 * Validate email format (basic check)
 */
validate_email :: proc(value: string, field: string) -> Validation_Error {
	if value == "" {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s cannot be empty", field),
			code    = "REQUIRED",
		}
	}
	
	// Basic email validation: must contain @ and .
	has_at := false
	has_dot := false
	for _, ch in value {
		if ch == '@' { has_at = true }
		if ch == '.' { has_dot = true }
	}
	
	if !has_at || !has_dot {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be a valid email address", field),
			code    = "INVALID_EMAIL",
		}
	}
	
	return Validation_Error{}
}

// ============================================================================
// Numeric Validators
// ============================================================================

/**
 * Validate number is positive
 */
validate_positive :: proc(value: int, field: string) -> Validation_Error {
	if value <= 0 {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be positive", field),
			code    = "MUST_BE_POSITIVE",
		}
	}
	return Validation_Error{}
}

/**
 * Validate number is non-negative
 */
validate_non_negative :: proc(value: int, field: string) -> Validation_Error {
	if value < 0 {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s cannot be negative", field),
			code    = "MUST_BE_NON_NEGATIVE",
		}
	}
	return Validation_Error{}
}

/**
 * Validate number in range
 */
validate_range :: proc(value: int, min: int, max: int, field: string) -> Validation_Error {
	if value < min {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at least %d", field, min),
			code    = "MIN_VALUE",
		}
	}
	if value > max {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at most %d", field, max),
			code    = "MAX_VALUE",
		}
	}
	return Validation_Error{}
}

/**
 * Validate float is positive
 */
validate_float_positive :: proc(value: f64, field: string) -> Validation_Error {
	if value <= 0.0 {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be positive", field),
			code    = "MUST_BE_POSITIVE",
		}
	}
	return Validation_Error{}
}

/**
 * Validate float in range
 */
validate_float_range :: proc(value: f64, min: f64, max: f64, field: string) -> Validation_Error {
	if value < min {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at least %g", field, min),
			code    = "MIN_VALUE",
		}
	}
	if value > max {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s must be at most %g", field, max),
			code    = "MAX_VALUE",
		}
	}
	return Validation_Error{}
}

// ============================================================================
// Object Validators
// ============================================================================

/**
 * Validate required field exists (not empty string)
 */
validate_required_string :: proc(value: string, field: string, result: ^Validation_Result) {
	err := validate_not_empty(value, field)
	if err.field != "" {
		append(&result.errors, err)
		result.valid = false
	}
}

/**
 * Validate required field exists (not nil)
 */
validate_required_ptr :: proc(value: rawptr, field: string, result: ^Validation_Result) {
	if value == nil {
		append(&result.errors, Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s is required", field),
			code    = "REQUIRED",
		})
		result.valid = false
	}
}

// ============================================================================
// Validation Helpers for Common Objects
// ============================================================================

/**
 * Validate User object
 */
validate_user :: proc(name: string, email: string, password: string = "") -> Validation_Result {
	result := validation_ok()
	
	// Validate name
	name_err := validate_length(name, 1, 100, "name")
	if name_err.field != "" {
		validation_add_error(&result, name_err.field, name_err.message, name_err.code)
	}
	
	// Validate email
	email_err := validate_email(email, "email")
	if email_err.field != "" {
		validation_add_error(&result, email_err.field, email_err.message, email_err.code)
	}
	
	// Validate password if provided
	if password != "" {
		pass_err := validate_min_length(password, 6, "password")
		if pass_err.field != "" {
			validation_add_error(&result, pass_err.field, pass_err.message, pass_err.code)
		}
	}
	
	return result
}

/**
 * Validate Product object
 */
validate_product :: proc(name: string, price: f64, category: string) -> Validation_Result {
	result := validation_ok()
	
	// Validate name
	name_err := validate_length(name, 1, 200, "name")
	if name_err.field != "" {
		validation_add_error(&result, name_err.field, name_err.message, name_err.code)
	}
	
	// Validate price
	price_err := validate_float_positive(price, "price")
	if price_err.field != "" {
		validation_add_error(&result, price_err.field, price_err.message, price_err.code)
	}
	
	// Validate category
	cat_err := validate_not_empty(category, "category")
	if cat_err.field != "" {
		validation_add_error(&result, cat_err.field, cat_err.message, cat_err.code)
	}
	
	return result
}

/**
 * Validate Order object
 */
validate_order :: proc(customer_name: string, total: f64) -> Validation_Result {
	result := validation_ok()
	
	// Validate customer name
	name_err := validate_length(customer_name, 1, 200, "customer_name")
	if name_err.field != "" {
		validation_add_error(&result, name_err.field, name_err.message, name_err.code)
	}
	
	// Validate total
	total_err := validate_float_non_negative(total, "total")
	if total_err.field != "" {
		validation_add_error(&result, total_err.field, total_err.message, total_err.code)
	}
	
	return result
}

/**
 * Validate float is non-negative
 */
validate_float_non_negative :: proc(value: f64, field: string) -> Validation_Error {
	if value < 0.0 {
		return Validation_Error{
			field   = field,
			message = fmt.Sprintf("%s cannot be negative", field),
			code    = "MUST_BE_NON_NEGATIVE",
		}
	}
	return Validation_Error{}
}

// ============================================================================
// Error Response Creation
// ============================================================================

/**
 * Create validation error JSON response
 */
validation_to_json :: proc(result: Validation_Result) -> string {
	if result.valid {
		return `{"valid":true,"errors":[]}`
	}
	
	json := `{"valid":false,"errors":[`
	for i, err in result.errors {
		if i > 0 {
			json += ","
		}
		json += fmt.Sprintf(`{"field":"%s","message":"%s","code":"%s"}`, 
			err.field, err.message, err.code)
	}
	json += "]}"
	
	return json
}

/**
 * Create error response from validation result
 */
create_validation_error_response :: proc(result: Validation_Result) -> string {
	if result.valid {
		return ""
	}
	
	// Create field errors map
	json := `{"success":false,"error":"Validation failed","validation_errors":[`
	for i, err in result.errors {
		if i > 0 {
			json += ","
		}
		json += fmt.Sprintf(`{"field":"%s","message":"%s","code":"%s"}`, 
			err.field, err.message, err.code)
	}
	json += "]}"
	
	return json
}
