// Testing Framework for Odin Backend
package testing

import "core:fmt"
import "core:time"

// Test Result enum
Test_Result :: enum {
    Passed,
    Failed,
    Skipped,
    Panicked,
}

// Test Case struct
Test_Case :: struct {
    name : string,
    description : string,
    result : Test_Result,
    message : string,
    duration : time.Duration,
}

// Test Suite struct
Test_Suite :: struct {
    name : string,
    description : string,
    cases : []Test_Case,
    passed : int,
    failed : int,
    skipped : int,
    panicked : int,
    total_duration : time.Duration,
}

// Test Runner struct
Test_Runner :: struct {
    suites : []Test_Suite,
    verbose : bool,
    stop_on_failure : bool,
}

// Assertion Result struct
Assertion_Result :: struct {
    success : bool,
    message : string,
}

// Create test runner
runner_create :: proc() -> ^Test_Runner {
    runner := new(Test_Runner)
    runner.suites = make([]Test_Suite, 0)
    runner.verbose = false
    runner.stop_on_failure = false
    return runner
}

// Create test suite
suite_create :: proc(name : string, description : string = "") -> Test_Suite {
    return Test_Suite{
        name = name,
        description = description,
        cases = make([]Test_Case, 0),
        passed = 0,
        failed = 0,
        skipped = 0,
        panicked = 0,
    }
}

// Run test suite
runner_run_suite :: proc(runner : ^Test_Runner, suite : ^Test_Suite) {
    fmt.printf("\n")
    fmt.printf("Running suite: %s\n", suite.name)
    if suite.description != "" {
        fmt.printf("  %s\n", suite.description)
    }
    fmt.printf("  Cases: %d\n", len(suite.cases))
    fmt.printf("\n")
    
    for i in 0..<len(suite.cases) {
        tc := &suite.cases[i]
        
        status_icon := "✓"
        if tc.result == Test_Result.Failed {
            status_icon = "✗"
        } else if tc.result == Test_Result.Skipped {
            status_icon = "○"
        } else if tc.result == Test_Result.Panicked {
            status_icon = "!"
        }
        
        fmt.printf("  %s %s", status_icon, tc.name)
        if tc.duration > 0 {
            fmt.printf(" (%dms)", tc.duration / time.Millisecond)
        }
        fmt.printf("\n")
        
        if tc.message != "" && (tc.result == Test_Result.Failed || tc.result == Test_Result.Panicked || runner.verbose) {
            fmt.printf("    %s\n", tc.message)
        }
        
        switch tc.result {
        case Test_Result.Passed:
            suite.passed += 1
        case Test_Result.Failed:
            suite.failed += 1
        case Test_Result.Skipped:
            suite.skipped += 1
        case Test_Result.Panicked:
            suite.panicked += 1
        }
        
        suite.total_duration += tc.duration
        
        if runner.stop_on_failure && tc.result == Test_Result.Failed {
            break
        }
    }
    
    append(&runner.suites, suite^)
}

// Print test results
runner_print_results :: proc(runner : ^Test_Runner) {
    total_passed := 0
    total_failed := 0
    total_skipped := 0
    total_panicked := 0
    total_duration : time.Duration = 0
    
    fmt.printf("\n")
    fmt.printf("===========================================\n")
    fmt.printf("           Test Results Summary\n")
    fmt.printf("===========================================\n")
    fmt.printf("\n")
    
    for suite in runner.suites {
        total_passed += suite.passed
        total_failed += suite.failed
        total_skipped += suite.skipped
        total_panicked += suite.panicked
        total_duration += suite.total_duration
        
        status := "PASS"
        if suite.failed > 0 || suite.panicked > 0 {
            status = "FAIL"
        }
        
        fmt.printf("Suite: %s [%s]\n", suite.name, status)
        fmt.printf("  Passed:   %d\n", suite.passed)
        fmt.printf("  Failed:   %d\n", suite.failed)
        fmt.printf("  Skipped:  %d\n", suite.skipped)
        fmt.printf("  Panicked: %d\n", suite.panicked)
        fmt.printf("  Duration: %dms\n", suite.total_duration / time.Millisecond)
        fmt.printf("\n")
    }
    
    fmt.printf("===========================================\n")
    fmt.printf("              Overall Summary\n")
    fmt.printf("===========================================\n")
    fmt.printf("Total Passed:   %d\n", total_passed)
    fmt.printf("Total Failed:   %d\n", total_failed)
    fmt.printf("Total Skipped:  %d\n", total_skipped)
    fmt.printf("Total Panicked: %d\n", total_panicked)
    fmt.printf("Total Duration: %dms\n", total_duration / time.Millisecond)
    fmt.printf("\n")
    
    if total_failed > 0 || total_panicked > 0 {
        fmt.printf("Result: FAILED\n")
    } else {
        fmt.printf("Result: PASSED\n")
    }
    fmt.printf("===========================================\n")
}

// Assert true
assert_true :: proc(condition : bool, message : string = "") -> Assertion_Result {
    if condition {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = "Expected condition to be true"
    }
    return Assertion_Result{success = false, message = msg}
}

// Assert false
assert_false :: proc(condition : bool, message : string = "") -> Assertion_Result {
    if !condition {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = "Expected condition to be false"
    }
    return Assertion_Result{success = false, message = msg}
}

// Assert equal for int
assert_equal_int :: proc(expected : int, actual : int, message : string = "") -> Assertion_Result {
    if expected == actual {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = fmt.Sprintf("Expected %d, got %d", expected, actual)
    }
    return Assertion_Result{success = false, message = msg}
}

// Assert equal for string
assert_equal_string :: proc(expected : string, actual : string, message : string = "") -> Assertion_Result {
    if expected == actual {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = fmt.Sprintf("Expected '%s', got '%s'", expected, actual)
    }
    return Assertion_Result{success = false, message = msg}
}

// Assert equal for bool
assert_equal_bool :: proc(expected : bool, actual : bool, message : string = "") -> Assertion_Result {
    if expected == actual {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = fmt.Sprintf("Expected %v, got %v", expected, actual)
    }
    return Assertion_Result{success = false, message = msg}
}

// Assert equal for f32
assert_equal_f32 :: proc(expected : f32, actual : f32, message : string = "") -> Assertion_Result {
    diff := expected - actual
    if diff < 0 {
        diff = -diff
    }
    if diff < 0.001 {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = fmt.Sprintf("Expected %.3f, got %.3f", expected, actual)
    }
    return Assertion_Result{success = false, message = msg}
}

// Assert nil
assert_nil :: proc(value : rawptr, message : string = "") -> Assertion_Result {
    if value == nil {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = fmt.Sprintf("Expected nil, got %v", value)
    }
    return Assertion_Result{success = false, message = msg}
}

// Assert not nil
assert_not_nil :: proc(value : rawptr, message : string = "") -> Assertion_Result {
    if value != nil {
        return Assertion_Result{success = true, message = ""}
    }
    msg := message
    if msg == "" {
        msg = "Expected non-nil value"
    }
    return Assertion_Result{success = false, message = msg}
}

// Create test case
case_create :: proc(name : string, description : string = "") -> Test_Case {
    return Test_Case{
        name = name,
        description = description,
        result = Test_Result.Passed,
    }
}

// Mark test as failed
case_fail :: proc(tc : ^Test_Case, message : string) {
    tc.result = Test_Result.Failed
    tc.message = message
}

// Mark test as skipped
case_skip :: proc(tc : ^Test_Case, reason : string = "") {
    tc.result = Test_Result.Skipped
    tc.message = reason
}

// Run test function
TEST_RUN :: proc(test_proc : proc(^Test_Case), tc : ^Test_Case) {
    start_time := time.now()
    test_proc(tc)
    tc.duration = time.now() - start_time
}

// Test Collection
Test_Collection :: struct {
    suites : []Test_Suite,
}

// Create test collection
collection_create :: proc() -> ^Test_Collection {
    col := new(Test_Collection)
    col.suites = make([]Test_Suite, 0)
    return col
}

// Add suite to collection
collection_add_suite :: proc(col : ^Test_Collection, suite : Test_Suite) {
    append(&col.suites, suite)
}

// Run all tests in collection
collection_run :: proc(col : ^Test_Collection) {
    runner := runner_create()
    
    for i in 0..<len(col.suites) {
        suite := &col.suites[i]
        runner_run_suite(runner, suite)
    }
    
    runner_print_results(runner)
    
    delete(runner)
}

// Get total test count
collection_total :: proc(col : ^Test_Collection) -> int {
    total := 0
    for suite in col.suites {
        total += len(suite.cases)
    }
    return total
}

// Get pass count
collection_passed :: proc(col : ^Test_Collection) -> int {
    total := 0
    for suite in col.suites {
        total += suite.passed
    }
    return total
}

// Get fail count
collection_failed :: proc(col : ^Test_Collection) -> int {
    total := 0
    for suite in col.suites {
        total += suite.failed
    }
    return total
}
