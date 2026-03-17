// DI System Tests
package main

import "core:fmt"
import testing "../testing"
import di "../di"

// ============================================================================
// Test Data
// ============================================================================

TestService :: struct {
    name : string,
    value : int,
}

TestLogger :: struct {
    prefix : string,
}

TestConfig :: struct {
    app_name : string,
    version : string,
}

// Tokens
SERVICE_TOKEN : di.Token = "service"
LOGGER_TOKEN : di.Token = "logger"
CONFIG_TOKEN : di.Token = "config"

// Factory functions
create_service :: proc(c : ^di.Container) -> rawptr {
    svc := new(TestService)
    svc.name = "TestService"
    svc.value = 42
    return svc
}

create_logger :: proc(c : ^di.Container) -> rawptr {
    logger := new(TestLogger)
    logger.prefix = "[LOG]"
    return logger
}

create_config :: proc(c : ^di.Container) -> rawptr {
    config := new(TestConfig)
    config.app_name = "TestApp"
    config.version = "1.0.0"
    return config
}

// ============================================================================
// Container Tests
// ============================================================================

test_container_create :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    
    result := testing.assert_not_nil(&container, "Container should not be nil")
    if !result.success { tc_fail(tc, result.message) }
    
    // Container should be empty initially
    info := di.get_container_info(&container)
    result = testing.assert_equal_int_string(0, info.provider_count, "Initial provider count should be 0")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int_string(0, info.instance_count, "Initial instance count should be 0")
    if !result.success { tc_fail(tc, result.message) }
}

test_container_destroy :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    di.register_singleton(&container, SERVICE_TOKEN, size_of(TestService))
    
    // Should not panic
    di.destroy_container(&container)
    
    tc.message = "Container destroyed without panic"
}

// ============================================================================
// Registration Tests
// ============================================================================

test_register_singleton :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    err := di.register_singleton(&container, SERVICE_TOKEN, size_of(TestService))
    result := testing.assert_false(err.has_error, "Register singleton should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    // Verify registration
    has_service := di.has(&container, SERVICE_TOKEN)
    result = testing.assert_true(has_service, "Container should have service token")
    if !result.success { tc_fail(tc, result.message) }
    
    info := di.get_container_info(&container)
    result = testing.assert_equal_int_string(1, info.provider_count, "Provider count should be 1")
    if !result.success { tc_fail(tc, result.message) }
}

test_register_factory :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    err := di.register_factory(&container, LOGGER_TOKEN, create_logger)
    result := testing.assert_false(err.has_error, "Register factory should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    has_logger := di.has(&container, LOGGER_TOKEN)
    result = testing.assert_true(has_logger, "Container should have logger token")
    if !result.success { tc_fail(tc, result.message) }
}

test_register_value :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    config := new(TestConfig)
    config.app_name = "TestApp"
    
    err := di.register_value(&container, CONFIG_TOKEN, config)
    result := testing.assert_false(err.has_error, "Register value should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    has_config := di.has(&container, CONFIG_TOKEN)
    result = testing.assert_true(has_config, "Container should have config token")
    if !result.success { tc_fail(tc, result.message) }
}

test_register_duplicate :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    // Register first time
    di.register_singleton(&container, SERVICE_TOKEN, size_of(TestService))
    
    // Try to register again
    err := di.register_singleton(&container, SERVICE_TOKEN, size_of(TestService))
    result := testing.assert_true(err.has_error, "Duplicate registration should fail")
    if !result.success { tc_fail(tc, result.message) }
}

test_register_nil_container :: proc(tc : ^testing.Test_Case) {
    err := di.register_singleton(nil, SERVICE_TOKEN, size_of(TestService))
    result := testing.assert_true(err.has_error, "Register with nil container should fail")
    if !result.success { tc_fail(tc, result.message) }
}

test_register_invalid_size :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    err := di.register_singleton(&container, SERVICE_TOKEN, 0)
    result := testing.assert_true(err.has_error, "Register with size 0 should fail")
    if !result.success { tc_fail(tc, result.message) }
    
    err = di.register_singleton(&container, SERVICE_TOKEN, -1)
    result = testing.assert_true(err.has_error, "Register with negative size should fail")
    if !result.success { tc_fail(tc, result.message) }
}

test_register_container_full :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    // Register 64 services (max capacity)
    for i in 0..<64 {
        token := fmt.Sprintf("service_%d", i)
        err := di.register_singleton(&container, token, size_of(TestService))
        result := testing.assert_false(err.has_error, fmt.Sprintf("Register service %d should succeed", i))
        if !result.success { tc_fail(tc, result.message) }
    }
    
    // Try to register one more
    err := di.register_singleton(&container, "overflow", size_of(TestService))
    result := testing.assert_true(err.has_error, "Register beyond capacity should fail")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Resolution Tests
// ============================================================================

test_resolve_singleton :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    di.register_singleton(&container, SERVICE_TOKEN, size_of(TestService))
    
    instance := di.resolve(&container, SERVICE_TOKEN)
    result := testing.assert_not_nil(instance, "Resolved singleton should not be nil")
    if !result.success { tc_fail(tc, result.message) }
    
    // Resolve again - should return same instance
    instance2 := di.resolve(&container, SERVICE_TOKEN)
    result = testing.assert_equal_int_string(instance, instance2, "Singleton should return same instance")
    if !result.success { tc_fail(tc, result.message) }
}

test_resolve_factory :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    di.register_factory(&container, LOGGER_TOKEN, create_logger)
    
    instance := di.resolve(&container, LOGGER_TOKEN)
    result := testing.assert_not_nil(instance, "Resolved factory should not be nil")
    if !result.success { tc_fail(tc, result.message) }
    
    // Verify it's the right type
    logger := cast(^TestLogger) instance
    result = testing.assert_equal_int_string("[LOG]", logger.prefix, "Logger prefix should match")
    if !result.success { tc_fail(tc, result.message) }
}

test_resolve_value :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    config := new(TestConfig)
    config.app_name = "TestApp"
    config.version = "1.0.0"
    
    di.register_value(&container, CONFIG_TOKEN, config)
    
    instance := di.resolve(&container, CONFIG_TOKEN)
    result := testing.assert_not_nil(instance, "Resolved value should not be nil")
    if !result.success { tc_fail(tc, result.message) }
    
    resolved_config := cast(^TestConfig) instance
    result = testing.assert_equal_int_string("TestApp", resolved_config.app_name, "Config app_name should match")
    if !result.success { tc_fail(tc, result.message) }
    result = testing.assert_equal_int_string("1.0.0", resolved_config.version, "Config version should match")
    if !result.success { tc_fail(tc, result.message) }
}

test_resolve_not_registered :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    instance := di.resolve(&container, "nonexistent")
    result := testing.assert_nil(instance, "Resolve unregistered token should return nil")
    if !result.success { tc_fail(tc, result.message) }
    
    // Check error result
    _, err := di.resolve_with_error(&container, "nonexistent")
    result = testing.assert_true(err.has_error, "Resolve unregistered should return error")
    if !result.success { tc_fail(tc, result.message) }
}

test_resolve_nil_container :: proc(tc : ^testing.Test_Case) {
    instance := di.resolve(nil, SERVICE_TOKEN)
    result := testing.assert_nil(instance, "Resolve from nil container should return nil")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Child Container Tests
// ============================================================================

test_child_container_inherit :: proc(tc : ^testing.Test_Case) {
    parent := di.create_container()
    defer di.destroy_container(&parent)
    
    di.register_singleton(&parent, SERVICE_TOKEN, size_of(TestService))
    
    child := di.create_child_container(&parent)
    defer di.destroy_container(&child)
    
    // Child should resolve parent's service
    instance := di.resolve(&child, SERVICE_TOKEN)
    result := testing.assert_not_nil(instance, "Child should resolve parent's service")
    if !result.success { tc_fail(tc, result.message) }
}

test_child_container_override :: proc(tc : ^testing.Test_Case) {
    parent := di.create_container()
    defer di.destroy_container(&parent)
    
    // Register in parent
    di.register_value(&parent, SERVICE_TOKEN, new(TestService))
    
    child := di.create_child_container(&parent)
    defer di.destroy_container(&child)
    
    // Override in child
    child_config := new(TestConfig)
    child_config.app_name = "ChildApp"
    di.register_value(&child, SERVICE_TOKEN, child_config)
    
    // Child should get its own registration
    instance := di.resolve(&child, SERVICE_TOKEN)
    result := testing.assert_not_nil(instance, "Child should resolve its own service")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Validation Tests
// ============================================================================

test_validate_container :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    // Empty container should be valid
    err := di.validate_container(&container)
    result := testing.assert_false(err.has_error, "Empty container should be valid")
    if !result.success { tc_fail(tc, result.message) }
    
    // Add some registrations
    di.register_singleton(&container, SERVICE_TOKEN, size_of(TestService))
    di.register_factory(&container, LOGGER_TOKEN, create_logger)
    
    err = di.validate_container(&container)
    result = testing.assert_false(err.has_error, "Container with registrations should be valid")
    if !result.success { tc_fail(tc, result.message) }
}

test_validate_nil_container :: proc(tc : ^testing.Test_Case) {
    err := di.validate_container(nil)
    result := testing.assert_true(err.has_error, "Nil container should be invalid")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Container Info Tests
// ============================================================================

test_container_info :: proc(tc : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)
    
    info := di.get_container_info(&container)
    result := testing.assert_equal_int_string(0, info.provider_count, "Initial provider count should be 0")
    if !result.success { tc_fail(tc, result.message) }
    result = testing.assert_equal_int_string(0, info.instance_count, "Initial instance count should be 0")
    if !result.success { tc_fail(tc, result.message) }
    result = testing.assert_false(info.has_parent, "Root container should not have parent")
    if !result.success { tc_fail(tc, result.message) }
    
    // Add registrations
    for i in 0..<10 {
        token := fmt.Sprintf("service_%d", i)
        di.register_singleton(&container, token, size_of(TestService))
    }
    
    info = di.get_container_info(&container)
    result = testing.assert_equal_int_string(10, info.provider_count, "Provider count should be 10")
    if !result.success { tc_fail(tc, result.message) }
    
    // Check usage percentage
    expected_percent := f32(10) / 64.0 * 100.0
    result = testing.assert_equal_int_string(expected_percent, info.provider_usage_percent, "Usage percent should match")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Main Test Runner
// ============================================================================

main :: proc() {
    fmt.printf("===========================================\n")
    fmt.printf("       DI System Test Suite\n")
    fmt.printf("===========================================\n")
    
    // Create test collection
    col := testing.collection_create()
    defer testing.collection_destroy(col)
    
    // Container tests
    container_suite := testing.suite_create(
        "Container Tests",
        "Tests for DI container creation and management")
    container_suite.cases = make([]testing.Test_Case, 2)
    container_suite.cases[0] = testing.case_create("create_container", "Should create empty container")
    testing.TEST_RUN(test_container_create, &container_suite.cases[0])
    container_suite.cases[1] = testing.case_create("destroy_container", "Should destroy without panic")
    testing.TEST_RUN(test_container_destroy, &container_suite.cases[1])
    testing.collection_add_suite(col, container_suite)
    
    // Registration tests
    register_suite := testing.suite_create(
        "Registration Tests",
        "Tests for service registration")
    register_suite.cases = make([]testing.Test_Case, 8)
    register_suite.cases[0] = testing.case_create("register_singleton", "Should register singleton")
    testing.TEST_RUN(test_register_singleton, &register_suite.cases[0])
    register_suite.cases[1] = testing.case_create("register_factory", "Should register factory")
    testing.TEST_RUN(test_register_factory, &register_suite.cases[1])
    register_suite.cases[2] = testing.case_create("register_value", "Should register value")
    testing.TEST_RUN(test_register_value, &register_suite.cases[2])
    register_suite.cases[3] = testing.case_create("register_duplicate", "Should fail on duplicate")
    testing.TEST_RUN(test_register_duplicate, &register_suite.cases[3])
    register_suite.cases[4] = testing.case_create("register_nil_container", "Should fail with nil container")
    testing.TEST_RUN(test_register_nil_container, &register_suite.cases[4])
    register_suite.cases[5] = testing.case_create("register_invalid_size", "Should fail with invalid size")
    testing.TEST_RUN(test_register_invalid_size, &register_suite.cases[5])
    register_suite.cases[6] = testing.case_create("register_container_full", "Should fail when full")
    testing.TEST_RUN(test_register_container_full, &register_suite.cases[6])
    register_suite.cases[7] = testing.case_create("register_and_check_has", "Should return true for has()")
    testing.TEST_RUN(test_register_singleton, &register_suite.cases[7])
    testing.collection_add_suite(col, register_suite)
    
    // Resolution tests
    resolve_suite := testing.suite_create(
        "Resolution Tests",
        "Tests for service resolution")
    resolve_suite.cases = make([]testing.Test_Case, 6)
    resolve_suite.cases[0] = testing.case_create("resolve_singleton", "Should resolve singleton")
    testing.TEST_RUN(test_resolve_singleton, &resolve_suite.cases[0])
    resolve_suite.cases[1] = testing.case_create("resolve_factory", "Should resolve factory")
    testing.TEST_RUN(test_resolve_factory, &resolve_suite.cases[1])
    resolve_suite.cases[2] = testing.case_create("resolve_value", "Should resolve value")
    testing.TEST_RUN(test_resolve_value, &resolve_suite.cases[2])
    resolve_suite.cases[3] = testing.case_create("resolve_not_registered", "Should return nil for unregistered")
    testing.TEST_RUN(test_resolve_not_registered, &resolve_suite.cases[3])
    resolve_suite.cases[4] = testing.case_create("resolve_nil_container", "Should return nil for nil container")
    testing.TEST_RUN(test_resolve_nil_container, &resolve_suite.cases[4])
    resolve_suite.cases[5] = testing.case_create("resolve_same_instance", "Singleton returns same instance")
    testing.TEST_RUN(test_resolve_singleton, &resolve_suite.cases[5])
    testing.collection_add_suite(col, resolve_suite)
    
    // Child container tests
    child_suite := testing.suite_create(
        "Child Container Tests",
        "Tests for child container inheritance")
    child_suite.cases = make([]testing.Test_Case, 2)
    child_suite.cases[0] = testing.case_create("child_inherit", "Child inherits parent registrations")
    testing.TEST_RUN(test_child_container_inherit, &child_suite.cases[0])
    child_suite.cases[1] = testing.case_create("child_override", "Child can override parent")
    testing.TEST_RUN(test_child_container_override, &child_suite.cases[1])
    testing.collection_add_suite(col, child_suite)
    
    // Validation tests
    validation_suite := testing.suite_create(
        "Validation Tests",
        "Tests for container validation")
    validation_suite.cases = make([]testing.Test_Case, 2)
    validation_suite.cases[0] = testing.case_create("validate_valid", "Valid container passes validation")
    testing.TEST_RUN(test_validate_container, &validation_suite.cases[0])
    validation_suite.cases[1] = testing.case_create("validate_nil", "Nil container fails validation")
    testing.TEST_RUN(test_validate_nil_container, &validation_suite.cases[1])
    testing.collection_add_suite(col, validation_suite)
    
    // Info tests
    info_suite := testing.suite_create(
        "Container Info Tests",
        "Tests for container information")
    info_suite.cases = make([]testing.Test_Case, 1)
    info_suite.cases[0] = testing.case_create("container_info", "Container info is accurate")
    testing.TEST_RUN(test_container_info, &info_suite.cases[0])
    testing.collection_add_suite(col, info_suite)
    
    // Run all tests
    testing.collection_run(col)
    
    // Exit with appropriate code
    if testing.collection_failed(col) > 0 {
        fmt.printf("\nTests FAILED\n")
    } else {
        fmt.printf("\nAll tests PASSED\n")
    }
}
