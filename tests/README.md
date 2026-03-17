# Backend Test Suite

Comprehensive test suite for the Odin WebUI Angular backend.

## Test Structure

```
tests/
├── testing/              # Test framework
│   └── testing.odin      # Core testing utilities
│
├── di_tests.odin         # DI system tests
├── errors_tests.odin     # Error handling tests
└── utils_tests.odin      # Utils package tests
```

## Running Tests

### Run All Tests

```bash
./run.sh test
```

### Run Individual Test Suites

```bash
# DI System Tests
odin run tests/di_tests.odin -file

# Error Handling Tests
odin run tests/errors_tests.odin -file

# Utils Tests
odin run tests/utils_tests.odin -file
```

## Test Framework

The testing framework (`testing/testing.odin`) provides:

### Assertions

```odin
import testing "../testing"

// Boolean assertions
testing.assert_true(condition, "Message")
testing.assert_false(condition, "Message")

// Equality assertions
testing.assert_equal(expected, actual, "Message")
testing.assert_not_equal(expected, actual, "Message")

// Nil assertions
testing.assert_nil(value, "Message")
testing.assert_not_nil(value, "Message")
```

### Test Cases

```odin
test_example :: proc(case : ^testing.Test_Case) {
    // Arrange
    value := 42
    
    // Act
    result := value * 2
    
    // Assert
    testing.TEST_ASSERT(
        testing.assert_equal(84, result, "Result should be 84"),
        case)
}
```

### Test Suites

```odin
suite := testing.suite_create(
    "Suite Name",
    "Suite description")

suite.cases = make([]testing.Test_Case, 2)
suite.cases[0] = testing.case_create("test_name", "Test description")
testing.TEST_RUN(test_example, &suite.cases[0])
```

### Test Runner

```odin
col := testing.collection_create()
defer testing.collection_destroy(col)

testing.collection_add_suite(col, suite)
testing.collection_run(col)
```

## Test Coverage

### DI System Tests (`di_tests.odin`)

| Category | Tests |
|----------|-------|
| Container | create, destroy |
| Registration | singleton, factory, value, duplicate, nil container, invalid size, full |
| Resolution | singleton, factory, value, not registered, nil container |
| Child Containers | inherit, override |
| Validation | valid, nil container |
| Info | container info |

**Total: 21 test cases**

### Error Handling Tests (`errors_tests.odin`)

| Category | Tests |
|----------|-------|
| Creation | new, new_detailed, none |
| Results | ok, error, check |
| Convenience | unknown, internal, timeout, not_found, invalid_param, io, not_implemented |
| Formatting | string, nil, log_string |
| Severity | default, critical |
| Collection | create, add, multiple, max |
| Try Pattern | success, failure |
| Wrapping | wrap, unwrap |

**Total: 24 test cases**

### Utils Tests (`utils_tests.odin`)

| Category | Tests |
|----------|-------|
| File System | write_read, exists, copy, path_ops, dir_ops |
| Config | parse_object, parse_array, parse_string, parse_bool, operations, has |
| Logger | create, level, level_parse |
| System Info | os_type, cpu_cores, hostname, format_size |

**Total: 18 test cases**

## Writing New Tests

### 1. Create Test File

```odin
// tests/my_feature_tests.odin
package main

import "core:fmt"
import testing "../testing"
import myfeature "../src/lib/myfeature"

test_feature_works :: proc(case : ^testing.Test_Case) {
    result := myfeature.do_something()
    
    testing.TEST_ASSERT(
        testing.assert_true(result, "Feature should work"),
        case)
}

main :: proc() {
    col := testing.collection_create()
    defer testing.collection_destroy(col)
    
    suite := testing.suite_create(
        "My Feature Tests",
        "Tests for my feature")
    
    suite.cases = make([]testing.Test_Case, 1)
    suite.cases[0] = testing.case_create("feature_works", "Feature should work")
    testing.TEST_RUN(test_feature_works, &suite.cases[0])
    
    testing.collection_add_suite(col, suite)
    testing.collection_run(col)
}
```

### 2. Add to run.sh

Add your test to the `run_tests()` function in `run.sh`:

```bash
if [ -f "$SCRIPT_DIR/tests/my_feature_tests.odin" ]; then
    print_info "Running My Feature tests..."
    cd "$SCRIPT_DIR/tests"
    
    if odin run my_feature_tests.odin -file; then
        print_step "My Feature tests passed"
        ((tests_passed++))
    else
        print_error "My Feature tests failed"
        ((tests_failed++))
        test_failed=1
    fi
    
    cd "$SCRIPT_DIR"
fi
```

## Test Output

```
===========================================
       DI System Test Suite
===========================================

Running suite: Container Tests
  Cases: 2

  ✓ create_container (2ms)
  ✓ destroy_container

Running suite: Registration Tests
  Cases: 8

  ✓ register_singleton
  ✓ register_factory
  ...

===========================================
           Test Results Summary
===========================================

Suite: Container Tests [PASS]
  Passed:   2
  Failed:   0
  Skipped:  0
  Panicked: 0
  Duration: 3ms

...

===========================================
              Overall Summary
===========================================
Total Passed:   21
Total Failed:   0
Total Skipped:  0
Total Panicked: 0
Total Duration: 45ms

Result: PASSED
===========================================
```

## Best Practices

### 1. Test Naming

```odin
// Good: Clear and descriptive
test_register_singleton :: proc(case : ^testing.Test_Case)
test_resolve_not_registered :: proc(case : ^testing.Test_Case)

// Bad: Vague
test1 :: proc(case : ^testing.Test_Case)
test_stuff :: proc(case : ^testing.Test_Case)
```

### 2. Test Structure (AAA Pattern)

```odin
test_example :: proc(case : ^testing.Test_Case) {
    // Arrange - Set up test data
    container := di.create_container()
    
    // Act - Execute the code being tested
    err := di.register_singleton(&container, "token", 10)
    
    // Assert - Verify the result
    result := testing.assert_false(err.has_error, "Should succeed")
    testing.TEST_ASSERT(result, case)
}
```

### 3. One Assertion Per Test

```odin
// Good: Focused test
test_register_success :: proc(case : ^testing.Test_Case) {
    err := di.register_singleton(&container, "token", 10)
    result := testing.assert_false(err.has_error, "Should succeed")
    testing.TEST_ASSERT(result, case)
}

// Bad: Multiple concerns
test_register_and_resolve :: proc(case : ^testing.Test_Case) {
    // Too many assertions
}
```

### 4. Cleanup Resources

```odin
test_with_resource :: proc(case : ^testing.Test_Case) {
    container := di.create_container()
    defer di.destroy_container(&container)  // Ensure cleanup
    
    // Test code...
}
```

### 5. Use Descriptive Messages

```odin
// Good: Clear message
result := testing.assert_equal(
    expected, 
    actual, 
    fmt.Sprintf("Value should be %d, got %d", expected, actual))

// Bad: Unclear message
result := testing.assert_equal(expected, actual, "Wrong")
```

## Continuous Integration

Add tests to your CI pipeline:

```yaml
# Example GitHub Actions
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Odin
        run: |
          # Install Odin compiler
      - name: Run Tests
        run: ./run.sh test
```

## Troubleshooting

### Test Won't Compile

1. Check import paths are correct
2. Ensure all dependencies are available
3. Verify Odin version compatibility

### Test Fails Unexpectedly

1. Check test isolation (no shared state)
2. Verify test data is properly initialized
3. Look for timing-dependent issues

### Memory Leaks

1. Use `defer` for cleanup
2. Check for unclosed resources
3. Run with memory profiler if available

## Contributing

When adding new features:

1. Write tests first (TDD)
2. Ensure all existing tests pass
3. Maintain >80% code coverage
4. Document test cases

## Support

For questions about testing:
- Check this README
- Review existing test examples
- See testing framework documentation
