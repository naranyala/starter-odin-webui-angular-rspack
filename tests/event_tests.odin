// Event Bus Tests
package main

import "core:fmt"
import testing "../testing"
import events "../src/lib/events"
import errors "../src/lib/errors"

// ============================================================================
// Test Helpers
// ============================================================================

received_data: rawptr
handler_called: bool

test_handler :: proc(data: rawptr) {
	received_data = data
	handler_called = true
}

// ============================================================================
// Event Bus Tests
// ============================================================================

test_event_bus_create :: proc(tc: ^testing.Test_Case) {
	bus, err := events.create_event_bus()
	result := testing.assert_false(err.code != errors.Error_Code.None, "Event bus should be created")
	if !result.success { tc_fail(tc, result.message) }
	
	events.destroy_event_bus(&bus)
	tc.message = "Event bus created and destroyed"
}

test_event_bus_subscribe :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	defer events.destroy_event_bus(&bus)
	
	handler_called = false
	err := events.subscribe(&bus, .User_Joined, test_handler)
	result := testing.assert_false(err.code != errors.Error_Code.None, "Subscribe should succeed")
	if !result.success { tc_fail(tc, result.message) }
	
	count := events.subscriber_count(&bus, .User_Joined)
	result = testing.assert_equal_int(1, count, "Should have 1 subscriber")
	if !result.success { tc_fail(tc, result.message) }
}

test_event_bus_unsubscribe :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	defer events.destroy_event_bus(&bus)
	
	events.subscribe(&bus, .User_Joined, test_handler)
	count := events.subscriber_count(&bus, .User_Joined)
	result := testing.assert_equal_int(1, count, "Should have 1 subscriber before unsubscribe")
	if !result.success { tc_fail(tc, result.message) }
	
	events.unsubscribe(&bus, .User_Joined, test_handler)
	count = events.subscriber_count(&bus, .User_Joined)
	result = testing.assert_equal_int(0, count, "Should have 0 subscribers after unsubscribe")
	if !result.success { tc_fail(tc, result.message) }
}

test_event_bus_emit :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	defer events.destroy_event_bus(&bus)
	
	handler_called = false
	events.subscribe(&bus, .Message_Sent, test_handler)
	
	test_data: int = 42
	events.emit(&bus, .Message_Sent, &test_data)
	
	result := testing.assert_true(handler_called, "Handler should be called")
	if !result.success { tc_fail(tc, result.message) }
}

test_event_bus_emit_sync :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	defer events.destroy_event_bus(&bus)
	
	handler_called = false
	events.subscribe(&bus, .Config_Changed, test_handler)
	
	test_data: string = "test_value"
	events.emit_sync(&bus, .Config_Changed, &test_data)
	
	result := testing.assert_true(handler_called, "Sync handler should be called")
	if !result.success { tc_fail(tc, result.message) }
}

test_event_bus_process_events :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	defer events.destroy_event_bus(&bus)
	
	handler_called = false
	events.subscribe(&bus, .Service_Ready, test_handler)
	
	test_data: int = 100
	events.emit(&bus, .Service_Ready, &test_data)
	
	events.process_events(&bus)
	
	result := testing.assert_true(handler_called, "Handler should be called after process_events")
	if !result.success { tc_fail(tc, result.message) }
}

test_event_bus_clear_queue :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	defer events.destroy_event_bus(&bus)
	
	events.emit(&bus, .Login, nil)
	events.emit(&bus, .Logout, nil)
	
	events.clear_queue(&bus)
	events.process_events(&bus)
	
	// No handlers should be called since queue was cleared
	tc.message = "Queue cleared successfully"
}

test_event_bus_multiple_handlers :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	defer events.destroy_event_bus(&bus)
	
	call_count := 0
	
	handler1 :: proc(data: rawptr) {
		call_count += 1
	}
	
	handler2 :: proc(data: rawptr) {
		call_count += 1
	}
	
	events.subscribe(&bus, .Custom, handler1)
	events.subscribe(&bus, .Custom, handler2)
	
	events.emit_sync(&bus, .Custom, nil)
	
	result := testing.assert_equal_int(2, call_count, "Both handlers should be called")
	if !result.success { tc_fail(tc, result.message) }
}

test_event_bus_destroy :: proc(tc: ^testing.Test_Case) {
	bus, _ := events.create_event_bus()
	
	// Should not panic
	events.destroy_event_bus(&bus)
	
	tc.message = "Event bus destroyed without panic"
}

// ============================================================================
// Main Test Runner
// ============================================================================

main :: proc() {
	fmt.printf("===========================================\n")
	fmt.printf("       Event Bus Test Suite\n")
	fmt.printf("===========================================\n")
	
	col := testing.collection_create()
	defer testing.collection_destroy(col)
	
	// Basic tests
	basic_suite := testing.suite_create("Basic Tests", "Basic event bus operations")
	basic_suite.cases = make([]testing.Test_Case, 2)
	basic_suite.cases[0] = testing.case_create("create", "Should create event bus")
	testing.TEST_RUN(test_event_bus_create, &basic_suite.cases[0])
	basic_suite.cases[1] = testing.case_create("destroy", "Should destroy without panic")
	testing.TEST_RUN(test_event_bus_destroy, &basic_suite.cases[1])
	testing.collection_add_suite(col, basic_suite)
	
	// Subscribe tests
	sub_suite := testing.suite_create("Subscribe Tests", "Subscription operations")
	sub_suite.cases = make([]testing.Test_Case, 2)
	sub_suite.cases[0] = testing.case_create("subscribe", "Should subscribe to event")
	testing.TEST_RUN(test_event_bus_subscribe, &sub_suite.cases[0])
	sub_suite.cases[1] = testing.case_create("unsubscribe", "Should unsubscribe from event")
	testing.TEST_RUN(test_event_bus_unsubscribe, &sub_suite.cases[1])
	testing.collection_add_suite(col, sub_suite)
	
	// Emit tests
	emit_suite := testing.suite_create("Emit Tests", "Event emission")
	emit_suite.cases = make([]testing.Test_Case, 3)
	emit_suite.cases[0] = testing.case_create("emit", "Should emit event")
	testing.TEST_RUN(test_event_bus_emit, &emit_suite.cases[0])
	emit_suite.cases[1] = testing.case_create("emit_sync", "Should emit sync event")
	testing.TEST_RUN(test_event_bus_emit_sync, &emit_suite.cases[1])
	emit_suite.cases[2] = testing.case_create("multiple_handlers", "Should call multiple handlers")
	testing.TEST_RUN(test_event_bus_multiple_handlers, &emit_suite.cases[2])
	testing.collection_add_suite(col, emit_suite)
	
	// Queue tests
	queue_suite := testing.suite_create("Queue Tests", "Event queue operations")
	queue_suite.cases = make([]testing.Test_Case, 2)
	queue_suite.cases[0] = testing.case_create("process_events", "Should process queued events")
	testing.TEST_RUN(test_event_bus_process_events, &queue_suite.cases[0])
	queue_suite.cases[1] = testing.case_create("clear_queue", "Should clear event queue")
	testing.TEST_RUN(test_event_bus_clear_queue, &queue_suite.cases[1])
	testing.collection_add_suite(col, queue_suite)
	
	testing.collection_run(col)
	
	if testing.collection_failed(col) > 0 {
		fmt.printf("\nTests FAILED\n")
	} else {
		fmt.printf("\nAll tests PASSED\n")
	}
}
