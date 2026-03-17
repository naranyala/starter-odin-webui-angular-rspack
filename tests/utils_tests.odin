// Utils Package Tests
package main

import "core:fmt"
import "core:os"
import testing "../testing"
import utils "../src/lib/utils"

// ============================================================================
// File System Tests
// ============================================================================

test_file_write_read :: proc(tc : ^testing.Test_Case) {
    test_path := utils.path_join(utils.path_temp_dir(), "odin_test_file.txt")
    test_content := "Hello, Odin Tests!"
    
    // Write file
    ok := utils.file_write(test_path, test_content)
    result := testing.assert_true(ok, "File write should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    // Read file
    content, ok := utils.file_read(test_path)
    result = testing.assert_true(ok, "File read should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(test_content, content, "File content should match")
    if !result.success { tc_fail(tc, result.message) }
    
    // Cleanup
    utils.file_delete(test_path)
}

test_file_exists :: proc(tc : ^testing.Test_Case) {
    test_path := utils.path_join(utils.path_temp_dir(), "odin_exists_test.txt")
    
    // File should not exist
    exists := utils.file_exists(test_path)
    result := testing.assert_false(exists, "File should not exist initially")
    if !result.success { tc_fail(tc, result.message) }
    
    // Create file
    utils.file_write(test_path, "test")
    
    // File should exist now
    exists = utils.file_exists(test_path)
    result = testing.assert_true(exists, "File should exist after creation")
    if !result.success { tc_fail(tc, result.message) }
    
    // Cleanup
    utils.file_delete(test_path)
}

test_file_copy :: proc(tc : ^testing.Test_Case) {
    src_path := utils.path_join(utils.path_temp_dir(), "odin_copy_src.txt")
    dst_path := utils.path_join(utils.path_temp_dir(), "odin_copy_dst.txt")
    content := "Copy test content"
    
    // Create source file
    utils.file_write(src_path, content)
    
    // Copy file
    ok := utils.file_copy(src_path, dst_path)
    result := testing.assert_true(ok, "File copy should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    // Verify copy
    copied_content, ok := utils.file_read(dst_path)
    result = testing.assert_true(ok, "Read copied file should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(content, copied_content, "Copied content should match")
    if !result.success { tc_fail(tc, result.message) }
    
    // Cleanup
    utils.file_delete(src_path)
    utils.file_delete(dst_path)
}

test_path_operations :: proc(tc : ^testing.Test_Case) {
    // Test path_join
    path := utils.path_join("home", "user", "documents")
    result := testing.assert_true(len(path) > 0, "path_join should return non-empty string")
    if !result.success { tc_fail(tc, result.message) }
    
    // Test path_directory
    dir := utils.path_directory("/home/user/file.txt")
    result = testing.assert_true(len(dir) > 0, "path_directory should return non-empty string")
    if !result.success { tc_fail(tc, result.message) }
    
    // Test path_filename
    filename := utils.path_filename("/home/user/file.txt")
    result = testing.assert_equal_int("file.txt", filename, "Filename should match")
    if !result.success { tc_fail(tc, result.message) }
    
    // Test path_extension
    ext := utils.path_extension("/home/user/file.txt")
    result = testing.assert_equal_int(".txt", ext, "Extension should match")
    if !result.success { tc_fail(tc, result.message) }
    
    // Test path_home
    home := utils.path_home()
    result = testing.assert_true(len(home) > 0, "Home directory should not be empty")
    if !result.success { tc_fail(tc, result.message) }
}

test_dir_operations :: proc(tc : ^testing.Test_Case) {
    test_dir := utils.path_join(utils.path_temp_dir(), "odin_test_dir")
    
    // Create directory
    ok := utils.dir_create(test_dir)
    result := testing.assert_true(ok, "Directory creation should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    // Directory should exist
    exists := utils.dir_exists(test_dir)
    result = testing.assert_true(exists, "Directory should exist after creation")
    if !result.success { tc_fail(tc, result.message) }
    
    // Delete directory
    ok = utils.dir_delete(test_dir)
    result = testing.assert_true(ok, "Directory deletion should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    // Directory should not exist
    exists = utils.dir_exists(test_dir)
    result = testing.assert_false(exists, "Directory should not exist after deletion")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Config Tests
// ============================================================================

test_json_parse_object :: proc(tc : ^testing.Test_Case) {
    json_str := `{"name": "John", "age": 30}`
    
    value, ok := utils.json_parse(json_str)
    result := testing.assert_true(ok, "JSON parse should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(utils.Json_Value_Type.Object, value.value_type, "Should parse as object")
    if !result.success { tc_fail(tc, result.message) }
}

test_json_parse_array :: proc(tc : ^testing.Test_Case) {
    json_str := `[1, 2, 3, 4, 5]`
    
    value, ok := utils.json_parse(json_str)
    result := testing.assert_true(ok, "JSON array parse should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(utils.Json_Value_Type.Array, value.value_type, "Should parse as array")
    if !result.success { tc_fail(tc, result.message) }
}

test_json_parse_string :: proc(tc : ^testing.Test_Case) {
    json_str := `"Hello, World!"`
    
    value, ok := utils.json_parse(json_str)
    result := testing.assert_true(ok, "JSON string parse should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int(utils.Json_Value_Type.String, value.value_type, "Should parse as string")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_equal_int("Hello, World!", value.string_value, "String value should match")
    if !result.success { tc_fail(tc, result.message) }
}

test_json_parse_bool :: proc(tc : ^testing.Test_Case) {
    // Test true
    value, ok := utils.json_parse("true")
    result := testing.assert_true(ok, "JSON bool true parse should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_true(value.bool_value, "Should parse as true")
    if !result.success { tc_fail(tc, result.message) }
    
    // Test false
    value, ok = utils.json_parse("false")
    result = testing.assert_true(ok, "JSON bool false parse should succeed")
    if !result.success { tc_fail(tc, result.message) }
    
    result = testing.assert_false(value.bool_value, "Should parse as false")
    if !result.success { tc_fail(tc, result.message) }
}

test_config_operations :: proc(tc : ^testing.Test_Case) {
    config := utils.config_create()
    defer delete(config)
    
    // Set values
    utils.config_set_string(config, "name", "TestApp")
    utils.config_set_int(config, "version", 1)
    utils.config_set_bool(config, "enabled", true)
    utils.config_set_float(config, "ratio", 0.75)
    
    // Get values
    name := utils.config_get_string(config, "name", "")
    result := testing.assert_equal_int("TestApp", name, "String value should match")
    if !result.success { tc_fail(tc, result.message) }
    
    version := utils.config_get_int(config, "version", 0)
    result = testing.assert_equal_int(1, version, "Int value should match")
    if !result.success { tc_fail(tc, result.message) }
    
    enabled := utils.config_get_bool(config, "enabled", false)
    result = testing.assert_true(enabled, "Bool value should match")
    if !result.success { tc_fail(tc, result.message) }
    
    ratio := utils.config_get_float(config, "ratio", 0.0)
    result = testing.assert_equal_int(0.75, ratio, "Float value should match")
    if !result.success { tc_fail(tc, result.message) }
}

test_config_has :: proc(tc : ^testing.Test_Case) {
    config := utils.config_create()
    defer delete(config)
    
    // Should not have key initially
    has := utils.config_has(config, "nonexistent")
    result := testing.assert_false(has, "Should not have nonexistent key")
    if !result.success { tc_fail(tc, result.message) }
    
    // Set value
    utils.config_set_string(config, "test_key", "test_value")
    
    // Should have key now
    has = utils.config_has(config, "test_key")
    result = testing.assert_true(has, "Should have test_key")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Logger Tests
// ============================================================================

test_logger_create :: proc(tc : ^testing.Test_Case) {
    logger := utils.logger_create()
    defer utils.logger_destroy(logger)
    
    result := testing.assert_not_nil(logger, "Logger should not be nil")
    if !result.success { tc_fail(tc, result.message) }
}

test_logger_level :: proc(tc : ^testing.Test_Case) {
    logger := utils.logger_create()
    defer utils.logger_destroy(logger)
    
    // Set level
    utils.logger_set_level(logger, utils.Log_Level.Debug)
    
    // Get level
    level := utils.logger_get_level(logger)
    result := testing.assert_equal_int(utils.Log_Level.Debug, level, "Logger level should match")
    if !result.success { tc_fail(tc, result.message) }
}

test_log_level_parse :: proc(tc : ^testing.Test_Case) {
    // Test various level strings
    level := utils.log_level_parse("DEBUG")
    result := testing.assert_equal_int(utils.Log_Level.Debug, level, "Should parse DEBUG")
    if !result.success { tc_fail(tc, result.message) }
    
    level = utils.log_level_parse("INFO")
    result = testing.assert_equal_int(utils.Log_Level.Info, level, "Should parse INFO")
    if !result.success { tc_fail(tc, result.message) }
    
    level = utils.log_level_parse("ERROR")
    result = testing.assert_equal_int(utils.Log_Level.Error, level, "Should parse ERROR")
    if !result.success { tc_fail(tc, result.message) }
    
    level = utils.log_level_parse("unknown")
    result = testing.assert_equal_int(utils.Log_Level.Info, level, "Should default to INFO")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// System Info Tests
// ============================================================================

test_system_os_type :: proc(tc : ^testing.Test_Case) {
    os_type := utils.system_os_type()
    result := testing.assert_true(os_type != utils.OS_Type.Unknown, "OS type should be detected")
    if !result.success { tc_fail(tc, result.message) }
    
    os_name := utils.system_os_type_name()
    result = testing.assert_true(len(os_name) > 0, "OS name should not be empty")
    if !result.success { tc_fail(tc, result.message) }
}

test_system_cpu_cores :: proc(tc : ^testing.Test_Case) {
    cores := utils.system_cpu_cores()
    result := testing.assert_true(cores >= 1, "Should have at least 1 CPU core")
    if !result.success { tc_fail(tc, result.message) }
}

test_system_hostname :: proc(tc : ^testing.Test_Case) {
    hostname := utils.system_hostname()
    result := testing.assert_true(len(hostname) > 0, "Hostname should not be empty")
    if !result.success { tc_fail(tc, result.message) }
}

test_system_format_size :: proc(tc : ^testing.Test_Case) {
    // Test bytes
    size := utils.system_format_size(100)
    result := testing.assert_true(len(size) > 0, "Format size should return non-empty string")
    if !result.success { tc_fail(tc, result.message) }
    
    // Test KB
    size = utils.system_format_size(1024)
    result = testing.assert_true(len(size) > 0, "Format KB should return non-empty string")
    if !result.success { tc_fail(tc, result.message) }
    
    // Test MB
    size = utils.system_format_size(1024 * 1024)
    result = testing.assert_true(len(size) > 0, "Format MB should return non-empty string")
    if !result.success { tc_fail(tc, result.message) }
}

// ============================================================================
// Main Test Runner
// ============================================================================

main :: proc() {
    fmt.printf("===========================================\n")
    fmt.printf("       Utils Package Test Suite\n")
    fmt.printf("===========================================\n")
    
    col := testing.collection_create()
    defer testing.collection_destroy(col)
    
    // File system tests
    file_suite := testing.suite_create(
        "File System Tests",
        "Tests for file system operations")
    file_suite.cases = make([]testing.Test_Case, 5)
    file_suite.cases[0] = testing.case_create("file_write_read", "Write and read file")
    testing.TEST_RUN(test_file_write_read, &file_suite.cases[0])
    file_suite.cases[1] = testing.case_create("file_exists", "Check file existence")
    testing.TEST_RUN(test_file_exists, &file_suite.cases[1])
    file_suite.cases[2] = testing.case_create("file_copy", "Copy file")
    testing.TEST_RUN(test_file_copy, &file_suite.cases[2])
    file_suite.cases[3] = testing.case_create("path_operations", "Path operations")
    testing.TEST_RUN(test_path_operations, &file_suite.cases[3])
    file_suite.cases[4] = testing.case_create("dir_operations", "Directory operations")
    testing.TEST_RUN(test_dir_operations, &file_suite.cases[4])
    testing.collection_add_suite(col, file_suite)
    
    // Config tests
    config_suite := testing.suite_create(
        "Config Tests",
        "Tests for configuration management")
    config_suite.cases = make([]testing.Test_Case, 6)
    config_suite.cases[0] = testing.case_create("json_parse_object", "Parse JSON object")
    testing.TEST_RUN(test_json_parse_object, &config_suite.cases[0])
    config_suite.cases[1] = testing.case_create("json_parse_array", "Parse JSON array")
    testing.TEST_RUN(test_json_parse_array, &config_suite.cases[1])
    config_suite.cases[2] = testing.case_create("json_parse_string", "Parse JSON string")
    testing.TEST_RUN(test_json_parse_string, &config_suite.cases[2])
    config_suite.cases[3] = testing.case_create("json_parse_bool", "Parse JSON bool")
    testing.TEST_RUN(test_json_parse_bool, &config_suite.cases[3])
    config_suite.cases[4] = testing.case_create("config_operations", "Config get/set operations")
    testing.TEST_RUN(test_config_operations, &config_suite.cases[4])
    config_suite.cases[5] = testing.case_create("config_has", "Config has key")
    testing.TEST_RUN(test_config_has, &config_suite.cases[5])
    testing.collection_add_suite(col, config_suite)
    
    // Logger tests
    logger_suite := testing.suite_create(
        "Logger Tests",
        "Tests for logging system")
    logger_suite.cases = make([]testing.Test_Case, 3)
    logger_suite.cases[0] = testing.case_create("logger_create", "Create logger")
    testing.TEST_RUN(test_logger_create, &logger_suite.cases[0])
    logger_suite.cases[1] = testing.case_create("logger_level", "Logger level")
    testing.TEST_RUN(test_logger_level, &logger_suite.cases[1])
    logger_suite.cases[2] = testing.case_create("log_level_parse", "Parse log level")
    testing.TEST_RUN(test_log_level_parse, &logger_suite.cases[2])
    testing.collection_add_suite(col, logger_suite)
    
    // System info tests
    system_suite := testing.suite_create(
        "System Info Tests",
        "Tests for system information")
    system_suite.cases = make([]testing.Test_Case, 4)
    system_suite.cases[0] = testing.case_create("system_os_type", "Detect OS type")
    testing.TEST_RUN(test_system_os_type, &system_suite.cases[0])
    system_suite.cases[1] = testing.case_create("system_cpu_cores", "Get CPU cores")
    testing.TEST_RUN(test_system_cpu_cores, &system_suite.cases[1])
    system_suite.cases[2] = testing.case_create("system_hostname", "Get hostname")
    testing.TEST_RUN(test_system_hostname, &system_suite.cases[2])
    system_suite.cases[3] = testing.case_create("system_format_size", "Format size")
    testing.TEST_RUN(test_system_format_size, &system_suite.cases[3])
    testing.collection_add_suite(col, system_suite)
    
    // Run all tests
    testing.collection_run(col)
    
    if testing.collection_failed(col) > 0 {
        fmt.printf("\nTests FAILED\n")
    } else {
        fmt.printf("\nAll tests PASSED\n")
    }
}
