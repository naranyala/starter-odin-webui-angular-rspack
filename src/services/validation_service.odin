// ============================================================================
// Validation Service - Comprehensive Input Validation
// ============================================================================
// Provides input validation, sanitization, and SQL injection prevention
// ============================================================================

package services

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"
import "../lib/errors"

// ============================================================================
// Types
// ============================================================================

// Validation result
Validation_Result :: struct {
    valid   : bool,
    errors  : []Validation_Error,
}

// Validation error
Validation_Error :: struct {
    field   : string,
    code    : string,
    message : string,
}

// Validator function type
Validator :: proc(value: string) -> errors.Error

// ============================================================================
// String Validators
// ============================================================================

// validate_not_empty checks if string is not empty
validate_not_empty :: proc(value: string) -> errors.Error {
    if strings.trim_space(value) == "" {
        return errors.Error{
            code: .Validation_Error,
            message: "Field cannot be empty",
        }
    }
    return errors.Error{code: .None}
}

// validate_min_length checks minimum length
validate_min_length :: proc(value: string, min: int) -> errors.Error {
    if utf8.string_length(value) < min {
        return errors.Error{
            code: .Validation_Error,
            message: fmt.Sprintf("Minimum length is %d characters", min),
        }
    }
    return errors.Error{code: .None}
}

// validate_max_length checks maximum length
validate_max_length :: proc(value: string, max: int) -> errors.Error {
    if utf8.string_length(value) > max {
        return errors.Error{
            code: .Validation_Error,
            message: fmt.Sprintf("Maximum length is %d characters", max),
        }
    }
    return errors.Error{code: .None}
}

// validate_email checks if string is valid email format
validate_email :: proc(value: string) -> errors.Error {
    if err := validate_not_empty(value); err.code != .None {
        return err
    }
    
    // Basic email validation
    if !strings.contains(value, "@") {
        return errors.Error{
            code: .Validation_Error,
            message: "Invalid email format",
        }
    }
    
    parts := strings.split(value, "@")
    if len(parts) != 2 {
        return errors.Error{
            code: .Validation_Error,
            message: "Invalid email format",
        }
    }
    
    local_part := parts[0]
    domain_part := parts[1]
    
    if local_part == "" || domain_part == "" {
        return errors.Error{
            code: .Validation_Error,
            message: "Invalid email format",
        }
    }
    
    if !strings.contains(domain_part, ".") {
        return errors.Error{
            code: .Validation_Error,
            message: "Invalid email domain",
        }
    }
    
    return errors.Error{code: .None}
}

// validate_username checks if string is valid username
validate_username :: proc(value: string) -> errors.Error {
    if err := validate_not_empty(value); err.code != .None {
        return err
    }
    
    if err := validate_min_length(value, 3); err.code != .None {
        return err
    }
    
    if err := validate_max_length(value, 30); err.code != .None {
        return err
    }
    
    // Only alphanumeric and underscore
    for _, c in value {
        if !((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || 
             (c >= '0' && c <= '9') || c == '_') {
            return errors.Error{
                code: .Validation_Error,
                message: "Username can only contain letters, numbers, and underscores",
            }
        }
    }
    
    return errors.Error{code: .None}
}

// validate_password checks password strength
validate_password :: proc(value: string) -> errors.Error {
    if err := validate_not_empty(value); err.code != .None {
        return err
    }
    
    if err := validate_min_length(value, 8); err.code != .None {
        return err
    }
    
    // Check for uppercase
    has_upper := false
    has_lower := false
    has_digit := false
    
    for _, c in value {
        if c >= 'A' && c <= 'Z' {
            has_upper = true
        } else if c >= 'a' && c <= 'z' {
            has_lower = true
        } else if c >= '0' && c <= '9' {
            has_digit = true
        }
    }
    
    if !has_upper || !has_lower || !has_digit {
        return errors.Error{
            code: .Validation_Error,
            message: "Password must contain uppercase, lowercase, and numbers",
        }
    }
    
    return errors.Error{code: .None}
}

// ============================================================================
// Numeric Validators
// ============================================================================

// validate_positive_int checks if value is positive integer
validate_positive_int :: proc(value: int) -> errors.Error {
    if value <= 0 {
        return errors.Error{
            code: .Validation_Error,
            message: "Value must be positive",
        }
    }
    return errors.Error{code: .None}
}

// validate_range_int checks if value is in range
validate_range_int :: proc(value: int, min: int, max: int) -> errors.Error {
    if value < min || value > max {
        return errors.Error{
            code: .Validation_Error,
            message: fmt.Sprintf("Value must be between %d and %d", min, max),
        }
    }
    return errors.Error{code: .None}
}

// ============================================================================
// SQL Injection Prevention
// ============================================================================

// is_safe_sql checks if SQL query is safe (no injection)
is_safe_sql :: proc(sql: string) -> bool {
    if sql == "" {
        return false
    }
    
    upper_sql := strings.to_upper(sql)
    
    // Dangerous patterns
    dangerous_patterns := []string{
        "--",           // SQL comment
        ";",            // Statement terminator
        "/*",           // Block comment start
        "*/",           // Block comment end
        "XP_",          // SQL Server extended procedures
        "EXEC ",        // Execute
        "EXECUTE ",     // Execute
        "DROP ",        // Drop table
        "DELETE FROM ", // Delete (without WHERE)
        "TRUNCATE ",    // Truncate table
        "ALTER ",       // Alter table
        "CREATE ",      // Create (in query context)
        "UNION ",       // Union injection
        "OR 1=1",       // Always true
        "OR '1'='1'",   // Always true
        "OR \"1\"=\"1\"", // Always true
        "AND 1=1",      // Always true
        "WAITFOR ",     // Time-based injection
        "BENCHMARK(",   // MySQL benchmark
        "SLEEP(",       // Sleep injection
    }
    
    for pattern in dangerous_patterns {
        if strings.contains(upper_sql, pattern) {
            return false
        }
    }
    
    // Check for multiple statements
    if strings.count(sql, ";") > 1 {
        return false
    }
    
    return true
}

// sanitize_sql_input removes dangerous characters from input
sanitize_sql_input :: proc(input: string) -> string {
    // Remove dangerous characters
    dangerous_chars := []string{"'", "\"", ";", "--", "/*", "*/"}
    
    result := input
    for char in dangerous_chars {
        result = strings.replace_all(result, char, "")
    }
    
    return result
}

// validate_user_input validates user input for SQL injection
validate_user_input :: proc(input: string) -> errors.Error {
    if !is_safe_sql(input) {
        return errors.Error{
            code: .Security_Error,
            message: "Potentially dangerous input detected",
        }
    }
    return errors.Error{code: .None}
}

// ============================================================================
// XSS Prevention
// ============================================================================

// sanitize_html removes HTML tags from input
sanitize_html :: proc(input: string) -> string {
    // Remove HTML tags
    result := ""
    in_tag := false
    
    for _, c in input {
        if c == '<' {
            in_tag = true
        } else if c == '>' {
            in_tag = false
        } else if !in_tag {
            result += string(c)
        }
    }
    
    return result
}

// encode_html encodes special characters for HTML output
encode_html :: proc(input: string) -> string {
    result := input
    result = strings.replace_all(result, "&", "&amp;")
    result = strings.replace_all(result, "<", "&lt;")
    result = strings.replace_all(result, ">", "&gt;")
    result = strings.replace_all(result, "\"", "&quot;")
    result = strings.replace_all(result, "'", "&#x27;")
    return result
}

// validate_no_xss checks for XSS patterns
validate_no_xss :: proc(input: string) -> errors.Error {
    upper_input := strings.to_upper(input)
    
    xss_patterns := []string{
        "<SCRIPT",
        "JAVASCRIPT:",
        "ONERROR=",
        "ONLOAD=",
        "ONCLICK=",
        "ONMOUSE",
        "ALERT(",
        "CONFIRM(",
        "PROMPT(",
        "DOCUMENT.COOKIE",
        "DOCUMENT.WRITE",
        "EVAL(",
    }
    
    for pattern in xss_patterns {
        if strings.contains(upper_input, pattern) {
            return errors.Error{
                code: .Security_Error,
                message: "Potentially dangerous XSS pattern detected",
            }
        }
    }
    
    return errors.Error{code: .None}
}

// ============================================================================
// User Validation
// ============================================================================

// validate_user validates a complete user object
validate_user :: proc(name: string, email: string, age: int) -> Validation_Result {
    errors := make([]Validation_Error, 0)
    
    // Validate name
    if err := validate_not_empty(name); err.code != .None {
        errors = append(errors, Validation_Error{
            field: "name",
            code: "required",
            message: "Name is required",
        })
    } else if err := validate_max_length(name, 100); err.code != .None {
        errors = append(errors, Validation_Error{
            field: "name",
            code: "max_length",
            message: "Name cannot exceed 100 characters",
        })
    }
    
    // Validate email
    if err := validate_email(email); err.code != .None {
        errors = append(errors, Validation_Error{
            field: "email",
            code: "invalid",
            message: err.message,
        })
    }
    
    // Validate age
    if err := validate_range_int(age, 1, 150); err.code != .None {
        errors = append(errors, Validation_Error{
            field: "age",
            code: "invalid",
            message: "Age must be between 1 and 150",
        })
    }
    
    return Validation_Result{
        valid = len(errors) == 0,
        errors = errors,
    }
}

// validate_product validates a product object
validate_product :: proc(name: string, price: f64, stock: int) -> Validation_Result {
    errors := make([]Validation_Error, 0)
    
    // Validate name
    if err := validate_not_empty(name); err.code != .None {
        errors = append(errors, Validation_Error{
            field: "name",
            code: "required",
            message: "Product name is required",
        })
    } else if err := validate_max_length(name, 200); err.code != .None {
        errors = append(errors, Validation_Error{
            field: "name",
            code: "max_length",
            message: "Product name cannot exceed 200 characters",
        })
    }
    
    // Validate price
    if price < 0 {
        errors = append(errors, Validation_Error{
            field: "price",
            code: "invalid",
            message: "Price cannot be negative",
        })
    }
    
    // Validate stock
    if stock < 0 {
        errors = append(errors, Validation_Error{
            field: "stock",
            code: "invalid",
            message: "Stock cannot be negative",
        })
    }
    
    return Validation_Result{
        valid = len(errors) == 0,
        errors = errors,
    }
}

// ============================================================================
// Validation Helpers
// ============================================================================

// validation_errors_to_string converts validation errors to readable string
validation_errors_to_string :: proc(result: Validation_Result) -> string {
    if result.valid {
        return "Validation passed"
    }
    
    message := "Validation failed: "
    for i, err in result.errors {
        if i > 0 {
            message += "; "
        }
        message += fmt.Sprintf("%s: %s", err.field, err.message)
    }
    
    return message
}

// has_validation_errors checks if validation result has errors
has_validation_errors :: proc(result: Validation_Result) -> bool {
    return !result.valid
}

// ============================================================================
// Security Constants
// ============================================================================

MAX_INPUT_LENGTH :: int = 10000
MAX_EMAIL_LENGTH :: int = 255
MAX_NAME_LENGTH :: int = 100
MIN_PASSWORD_LENGTH :: int = 8
MAX_PASSWORD_LENGTH :: int = 128
