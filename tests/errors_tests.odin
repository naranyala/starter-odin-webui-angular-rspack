// Error Handling Tests
package main

import "core:fmt"
import testing "../testing"
import errors "../errors"

// ============================================================================
// Error Creation Tests
// ============================================================================

test_error_new :: proc(tc : ^testing.Test_Case) {
    err := errors.new(errors.Error_Code.Unknown, "Test error message")
    
    result := testing.assert_true(errors.check(err), "Error should be checked")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(errors.Error_Code.Unknown, err.code, "Error code should match")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int("Test error message", err.message, "Error message should match")
    if !result.success { tc_fail(tc, result.message) }
}

test_error_new_detailed :: proc(tc : ^testing.Test_Case) {
    err := errors.new_detailed(errors.Error_Code.File_Read_Error, "Failed to read", "Permission denied")
    
    result := testing.assert_equal_int("Failed to read", err.message, "Message should match")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int("Permission denied", err.details, "Details should match")
    if !result.success { tc_fail(tc, result.message) }
}

test_error_none :: proc(tc : ^testing.Test_Case) {
    err := errors.err_none()
    
    result := testing.assert_false(errors.check(err), "None error should not be checked")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(errors.Error_Code.None, err.code, "Code should be None")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Error Result Tests
// ============================================================================

test_error_result_ok :: proc(tc : ^testing.Test_Case) {
    result := errors.result_ok()
    
    check := testing.assert_false(result.has_error, "Result should not have error")
    testing.TEST_ASSERT(check, case)
}

test_error_result_error :: proc(tc : ^testing.Test_Case) {
    err := errors.new(errors.Error_Code.Internal, "Test error")
    result := errors.result_error(err)
    
    check := testing.assert_true(result.has_error, "Result should have error")
    testing.TEST_ASSERT(check, case)
    
    check = testing.assert_equal_int(errors.Error_Code.Internal, result.err.code, "Error code should match")
    testing.TEST_ASSERT(check, case)
}

test_check_result :: proc(tc : ^testing.Test_Case) {
    ok_result := errors.result_ok()
    result := testing.assert_false(errors.check_result(ok_result), "OK result should not have error")
    if !result.success { tc_fail(tc, result.message) }
    
    err_result := errors.result_error(errors.err_internal("error"))
    result = testing.assert_true(errors.check_result(err_result), "Error result should have error")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Convenience Error Tests
// ============================================================================

test_err_unknown :: proc(tc : ^testing.Test_Case) {
    err := errors.err_unknown("Something unknown happened")
    
    result := testing.assert_equal_int(errors.Error_Code.Unknown, err.code, "Code should be Unknown")
    if !result.success { tc_fail(tc, result.message) }
}

test_err_internal :: proc(tc : ^testing.Test_Case) {
    err := errors.err_internal("Internal error occurred")
    
    result := testing.assert_equal_int(errors.Error_Code.Internal, err.code, "Code should be Internal")
    if !result.success { tc_fail(tc, result.message) }
}

test_err_timeout :: proc(tc : ^testing.Test_Case) {
    err := errors.err_timeout("Operation timed out")
    
    result := testing.assert_equal_int(errors.Error_Code.Timeout, err.code, "Code should be Timeout")
    if !result.success { tc_fail(tc, result.message) }
}

test_err_not_found :: proc(tc : ^testing.Test_Case) {
    err := errors.err_not_found("Resource not found")
    
    result := testing.assert_equal_int(errors.Error_Code.Not_Found, err.code, "Code should be Not_Found")
    if !result.success { tc_fail(tc, result.message) }
}

test_err_invalid_param :: proc(tc : ^testing.Test_Case) {
    err := errors.err_invalid_param("Invalid parameter")
    
    result := testing.assert_equal_int(errors.Error_Code.Invalid_Parameter, err.code, "Code should be Invalid_Parameter")
    if !result.success { tc_fail(tc, result.message) }
}

test_err_io :: proc(tc : ^testing.Test_Case) {
    err := errors.err_io("IO error occurred")
    
    result := testing.assert_equal_int(errors.Error_Code.IO_Error, err.code, "Code should be IO_Error")
    if !result.success { tc_fail(tc, result.message) }
}

test_err_not_implemented :: proc(tc : ^testing.Test_Case) {
    err := errors.err_not_implemented()
    
    result := testing.assert_equal_int(errors.Error_Code.Not_Implemented, err.code, "Code should be Not_Implemented")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int("Not implemented", err.message, "Message should match")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Error Formatting Tests
// ============================================================================

test_error_string :: proc(tc : ^testing.Test_Case) {
    err := errors.new(errors.Error_Code.File_Not_Found, "File not found")
    str := errors.error_string(&err)
    
    result := testing.assert_true(len(str) > 0, "Error string should not be empty")
    if !result.success { tc_fail(tc, result.message) }
}

test_error_string_nil :: proc(tc : ^testing.Test_Case) {
    str := errors.error_string(nil)
    
    result := testing.assert_equal_int("nil", str, "Nil error should return 'nil'")
    if !result.success { tc_fail(tc, result.message) }
}

test_error_log_string :: proc(tc : ^testing.Test_Case) {
    err := errors.new(errors.Error_Code.Network_Error, "Network error")
    str := errors.error_log_string(&err)
    
    result := testing.assert_true(len(str) > 0, "Log string should not be empty")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Error Severity Tests
// ============================================================================

test_error_severity :: proc(tc : ^testing.Test_Case) {
    // Default severity should be Error
    err := errors.new(errors.Error_Code.Unknown, "Test")
    result := testing.assert_equal_int(errors.Error_Severity.Error, err.severity, "Default severity should be Error")
    if !result.success { tc_fail(tc, result.message) }
}

test_error_critical :: proc(tc : ^testing.Test_Case) {
    err := errors.new_critical(errors.Error_Code.Resource_Exhausted, "Out of memory")
    
    result := testing.assert_equal_int(errors.Error_Severity.Critical, err.severity, "Severity should be Critical")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_false(err.recoverable, "Critical error should not be recoverable")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Error Collection Tests
// ============================================================================

test_collection_create :: proc(tc : ^testing.Test_Case) {
    col := errors.collection_create(10)
    defer errors.collection_destroy(col)
    
    result := testing.assert_not_nil(col, "Collection should not be nil")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_false(errors.collection_has_errors(col), "New collection should have no errors")
    if !result.success { tc_fail(tc, result.message) }
}

test_collection_add :: proc(tc : ^testing.Test_Case) {
    col := errors.collection_create(10)
    defer errors.collection_destroy(col)
    
    err1 := errors.err_internal("Error 1")
    errors.collection_add(col, err1)
    
    result := testing.assert_true(errors.collection_has_errors(col), "Collection should have errors")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(1, errors.collection_count(col), "Count should be 1")
    if !result.success { tc_fail(tc, result.message) }
}

test_collection_multiple :: proc(tc : ^testing.Test_Case) {
    col := errors.collection_create(10)
    defer errors.collection_destroy(col)
    
    errors.collection_add(col, errors.err_internal("Error 1"))
    errors.collection_add(col, errors.err_timeout("Error 2"))
    errors.collection_add(col, errors.err_not_found("Error 3"))
    
    result := testing.assert_equal_int(3, errors.collection_count(col), "Count should be 3")
    if !result.success { tc_fail(tc, result.message) }
    
    first := errors.collection_first(col)
    result = testing.assert_equal_int(errors.Error_Code.Internal, first.code, "First error should be Internal")
    if !result.success { tc_fail(tc, result.message) }
}

test_collection_max :: proc(tc : ^testing.Test_Case) {
    col := errors.collection_create(2)
    defer errors.collection_destroy(col)
    
    errors.collection_add(col, errors.err_internal("Error 1"))
    errors.collection_add(col, errors.err_timeout("Error 2"))
    errors.collection_add(col, errors.err_not_found("Error 3"))  // Should be ignored
    
    result := testing.assert_equal_int(2, errors.collection_count(col), "Count should be max (2)")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Try Pattern Tests
// ============================================================================

test_try_execute_success :: proc(tc : ^testing.Test_Case) {
    operation :: proc() -> errors.Error {
        return errors.err_none()
    }
    
    result := errors.try_execute(operation)
    
    check := testing.assert_true(result.success, "Try should succeed")
    testing.TEST_ASSERT(check, case)
}

test_try_execute_failure :: proc(tc : ^testing.Test_Case) {
    operation :: proc() -> errors.Error {
        return errors.err_internal("Operation failed")
    }
    
    result := errors.try_execute(operation)
    
    check := testing.assert_false(result.success, "Try should fail")
    testing.TEST_ASSERT(check, case)
    
    check = testing.assert_equal_int(errors.Error_Code.Internal, result.err.code, "Error code should match")
    testing.TEST_ASSERT(check, case)
}

// ============================================================================
// Error Wrapping Tests
// ============================================================================

test_error_wrap :: proc(tc : ^testing.Test_Case) {
    inner := errors.err_file_not_found("config.json")
    wrapped := errors.wrap(inner, "Loading config")
    
    result := testing.assert_equal_int(errors.Error_Code.File_Not_Found, wrapped.code, "Wrapped error code should match")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_not_nil(wrapped.cause, "Wrapped error should have cause")
    if !result.success { tc_fail(tc, result.message) }
}

test_error_unwrap :: proc(tc : ^testing.Test_Case) {
    inner := errors.err_internal("Root cause")
    middle := errors.wrap(inner, "Middle layer")
    outer := errors.wrap(middle, "Outer layer")
    
    root := errors.unwrap(&outer)
    
    result := testing.assert_equal_int(errors.Error_Code.Internal, root.code, "Root cause code should match")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Main Test Runner
// ============================================================================

main :: proc() {
    fmt.printf("===========================================\n")
    fmt.printf("     Error Handling Test Suite\n")
    fmt.printf("===========================================\n")
    
    col := testing.collection_create()
    defer testing.collection_destroy(col)
    
    // Error creation tests
    create_suite := testing.suite_create(
        "Error Creation Tests",
        "Tests for error creation functions")
    create_suite.cases = make([]testing.Test_Case, 3)
    create_suite.cases[0] = testing.case_create("error_new", "Create basic error")
    testing.TEST_RUN(test_error_new, &create_suite.cases[0])
    create_suite.cases[1] = testing.case_create("error_new_detailed", "Create error with details")
    testing.TEST_RUN(test_error_new_detailed, &create_suite.cases[1])
    create_suite.cases[2] = testing.case_create("error_none", "Create none error")
    testing.TEST_RUN(test_error_none, &create_suite.cases[2])
    testing.collection_add_suite(col, create_suite)
    
    // Error result tests
    result_suite := testing.suite_create(
        "Error Result Tests",
        "Tests for error result type")
    result_suite.cases = make([]testing.Test_Case, 3)
    result_suite.cases[0] = testing.case_create("result_ok", "Create OK result")
    testing.TEST_RUN(test_error_result_ok, &result_suite.cases[0])
    result_suite.cases[1] = testing.case_create("result_error", "Create error result")
    testing.TEST_RUN(test_error_result_error, &result_suite.cases[1])
    result_suite.cases[2] = testing.case_create("check_result", "Check result")
    testing.TEST_RUN(test_check_result, &result_suite.cases[2])
    testing.collection_add_suite(col, result_suite)
    
    // Convenience error tests
    convenience_suite := testing.suite_create(
        "Convenience Error Tests",
        "Tests for convenience error functions")
    convenience_suite.cases = make([]testing.Test_Case, 7)
    convenience_suite.cases[0] = testing.case_create("err_unknown", "Create unknown error")
    testing.TEST_RUN(test_err_unknown, &convenience_suite.cases[0])
    convenience_suite.cases[1] = testing.case_create("err_internal", "Create internal error")
    testing.TEST_RUN(test_err_internal, &convenience_suite.cases[1])
    convenience_suite.cases[2] = testing.case_create("err_timeout", "Create timeout error")
    testing.TEST_RUN(test_err_timeout, &convenience_suite.cases[2])
    convenience_suite.cases[3] = testing.case_create("err_not_found", "Create not found error")
    testing.TEST_RUN(test_err_not_found, &convenience_suite.cases[3])
    convenience_suite.cases[4] = testing.case_create("err_invalid_param", "Create invalid param error")
    testing.TEST_RUN(test_err_invalid_param, &convenience_suite.cases[4])
    convenience_suite.cases[5] = testing.case_create("err_io", "Create IO error")
    testing.TEST_RUN(test_err_io, &convenience_suite.cases[5])
    convenience_suite.cases[6] = testing.case_create("err_not_implemented", "Create not implemented error")
    testing.TEST_RUN(test_err_not_implemented, &convenience_suite.cases[6])
    testing.collection_add_suite(col, convenience_suite)
    
    // Error formatting tests
    format_suite := testing.suite_create(
        "Error Formatting Tests",
        "Tests for error formatting functions")
    format_suite.cases = make([]testing.Test_Case, 3)
    format_suite.cases[0] = testing.case_create("error_string", "Format error string")
    testing.TEST_RUN(test_error_string, &format_suite.cases[0])
    format_suite.cases[1] = testing.case_create("error_string_nil", "Format nil error")
    testing.TEST_RUN(test_error_string_nil, &format_suite.cases[1])
    format_suite.cases[2] = testing.case_create("error_log_string", "Format log string")
    testing.TEST_RUN(test_error_log_string, &format_suite.cases[2])
    testing.collection_add_suite(col, format_suite)
    
    // Error severity tests
    severity_suite := testing.suite_create(
        "Error Severity Tests",
        "Tests for error severity")
    severity_suite.cases = make([]testing.Test_Case, 2)
    severity_suite.cases[0] = testing.case_create("error_severity", "Default severity")
    testing.TEST_RUN(test_error_severity, &severity_suite.cases[0])
    severity_suite.cases[1] = testing.case_create("error_critical", "Critical severity")
    testing.TEST_RUN(test_error_critical, &severity_suite.cases[1])
    testing.collection_add_suite(col, severity_suite)
    
    // Error collection tests
    collection_suite := testing.suite_create(
        "Error Collection Tests",
        "Tests for error collection")
    collection_suite.cases = make([]testing.Test_Case, 4)
    collection_suite.cases[0] = testing.case_create("collection_create", "Create collection")
    testing.TEST_RUN(test_collection_create, &collection_suite.cases[0])
    collection_suite.cases[1] = testing.case_create("collection_add", "Add to collection")
    testing.TEST_RUN(test_collection_add, &collection_suite.cases[1])
    collection_suite.cases[2] = testing.case_create("collection_multiple", "Multiple errors")
    testing.TEST_RUN(test_collection_multiple, &collection_suite.cases[2])
    collection_suite.cases[3] = testing.case_create("collection_max", "Max capacity")
    testing.TEST_RUN(test_collection_max, &collection_suite.cases[3])
    testing.collection_add_suite(col, collection_suite)
    
    // Try pattern tests
    try_suite := testing.suite_create(
        "Try Pattern Tests",
        "Tests for try pattern")
    try_suite.cases = make([]testing.Test_Case, 2)
    try_suite.cases[0] = testing.case_create("try_execute_success", "Try success")
    testing.TEST_RUN(test_try_execute_success, &try_suite.cases[0])
    try_suite.cases[1] = testing.case_create("try_execute_failure", "Try failure")
    testing.TEST_RUN(test_try_execute_failure, &try_suite.cases[1])
    testing.collection_add_suite(col, try_suite)
    
    // Error wrapping tests
    wrap_suite := testing.suite_create(
        "Error Wrapping Tests",
        "Tests for error wrapping")
    wrap_suite.cases = make([]testing.Test_Case, 2)
    wrap_suite.cases[0] = testing.case_create("error_wrap", "Wrap error")
    testing.TEST_RUN(test_error_wrap, &wrap_suite.cases[0])
    wrap_suite.cases[1] = testing.case_create("error_unwrap", "Unwrap error")
    testing.TEST_RUN(test_error_unwrap, &wrap_suite.cases[1])
    testing.collection_add_suite(col, wrap_suite)
    
    // Run all tests
    testing.collection_run(col)
    
    if testing.collection_failed(col) > 0 {
        fmt.printf("\nTests FAILED\n")
    } else {
        fmt.printf("\nAll tests PASSED\n")
    }
}
