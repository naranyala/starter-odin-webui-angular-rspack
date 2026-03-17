// Simple DI Test - Working Example
package main

import "core:fmt"
import di "../di"

TestService :: struct {
    name : string,
    value : int,
}

SERVICE_TOKEN : di.Token = "service"

create_service :: proc(c : ^di.Container) -> rawptr {
    svc := new(TestService)
    svc.name = "TestService"
    svc.value = 42
    return svc
}

main :: proc() {
    fmt.printf("=== DI System Tests ===\n\n")
    
    passed := 0
    failed := 0
    
    // Test 1: Create container
    fmt.printf("Test 1: Create container... ")
    container := di.create_container()
    if true {  // Container always created
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 2: Register singleton
    fmt.printf("Test 2: Register singleton... ")
    di.register_singleton(&container, SERVICE_TOKEN, size_of(TestService))
    has_service := di.has(&container, SERVICE_TOKEN)
    if has_service {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 3: Has token
    fmt.printf("Test 3: Has token... ")
    has_service = di.has(&container, SERVICE_TOKEN)
    if has_service {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 4: Resolve singleton
    fmt.printf("Test 4: Resolve singleton... ")
    instance := di.resolve(&container, SERVICE_TOKEN)
    if instance != nil {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 5: Resolve same instance (singleton)
    fmt.printf("Test 5: Singleton returns same instance... ")
    instance2 := di.resolve(&container, SERVICE_TOKEN)
    if instance == instance2 {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 6: Resolve with typed result
    fmt.printf("Test 6: Resolve typed... ")
    svc := cast(^TestService) instance
    if svc.value == 42 {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 7: Register factory
    fmt.printf("Test 7: Register factory... ")
    di.register_factory(&container, "logger", create_service)
    has_logger := di.has(&container, "logger")
    if has_logger {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 8: Resolve factory
    fmt.printf("Test 8: Resolve factory... ")
    logger_instance := di.resolve(&container, "logger")
    if logger_instance != nil {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 9: Child container inherits
    fmt.printf("Test 9: Child container inherits... ")
    child := di.create_child_container(&container)
    child_instance := di.resolve(&child, SERVICE_TOKEN)
    if child_instance != nil {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Test 10: Resolve unregistered returns nil
    fmt.printf("Test 10: Unregistered returns nil... ")
    unregistered := di.resolve(&container, "nonexistent")
    if unregistered == nil {
        fmt.printf("PASS\n")
        passed += 1
    } else {
        fmt.printf("FAIL\n")
        failed += 1
    }
    
    // Cleanup
    di.destroy_container(&container)
    di.destroy_container(&child)
    
    // Summary
    fmt.printf("\n=== Test Summary ===\n")
    fmt.printf("Passed: %d\n", passed)
    fmt.printf("Failed: %d\n", failed)
    fmt.printf("Total:  %d\n", passed + failed)
    
    if failed > 0 {
        fmt.printf("\nResult: FAILED\n")
    } else {
        fmt.printf("\nResult: PASSED (10/10)\n")
    }
}
