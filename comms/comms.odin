// Communication Layer - RPC + Event Bus Implementation
package comms

import "core:fmt"
import "core:strings"
import "core:c"
import "core:hash_map"
import webui "../webui_lib"

// ============================================================================
// RPC System
// ============================================================================

Rpc_Request :: struct {
	id     : i64,
	method : string,
	params : string,
}

Rpc_Response :: struct {
	id     : i64,
	result : string,
	error  : string,
}

Rpc_Handler :: proc "c" (^webui.Event) -> string

Rpc_Registry :: struct {
	handlers : hash_map.HashMap(string, Rpc_Handler),
}

rpc_registry : Rpc_Registry

// Initialize RPC system
rpc_init :: proc() {
	rpc_registry.handlers = hash_map.create_hash_map(string, Rpc_Handler, 32)
}

// Register RPC method
rpc_register :: proc(method : string, handler : Rpc_Handler) {
	hash_map.put(&rpc_registry.handlers, method, handler)
}

// Handle RPC call from frontend
rpc_handle_call :: proc "c" (e : ^webui.Event) {
	request_json := webui.webui_get_string(e)
	
	// Parse request (simplified - use proper JSON parser in production)
	request := Rpc_Request{}
	// TODO: Parse JSON to extract id, method, params
	
	// Find handler
	handler, ok := hash_map.get(&rpc_registry.handlers, request.method)
	
	response := Rpc_Response{
		id = request.id,
	}
	
	if ok && handler != nil {
		// Call handler
		result := handler(e)
		response.result = result
	} else {
		response.error = fmt.Sprintf("Method not found: %s", request.method)
	}
	
	// Send response back to frontend
	response_json := fmt.Sprintf(
		`{"id":%d,"result":"%s","error":"%s"}`,
		response.id, response.result, response.error)
	
	script := fmt.Sprintf("window.rpcClient.handleResponse(%s)", response_json)
	webui.webui_run(e.window, script)
}

// Call RPC from backend (for internal use)
rpc_call :: proc(method : string, params : string) -> string {
	// Internal RPC call
	return ""
}

// ============================================================================
// Event Bus System
// ============================================================================

Event_Handler :: proc "c" (win : webui.Window, data : string)

Event_Bus :: struct {
	subscribers : hash_map.HashMap(string, []Event_Handler),
}

event_bus : Event_Bus

// Initialize event bus
event_bus_init :: proc() {
	event_bus.subscribers = hash_map.create_hash_map(string, []Event_Handler, 32)
}

// Subscribe to event
event_bus_on :: proc(topic : string, handler : Event_Handler) {
	handlers, ok := hash_map.get(&event_bus.subscribers, topic)
	if !ok {
		handlers = make([]Event_Handler, 0)
	}
	append(&handlers, handler)
	hash_map.put(&event_bus.subscribers, topic, handlers)
}

// Unsubscribe from event
event_bus_off :: proc(topic : string, handler : Event_Handler) {
	handlers, ok := hash_map.get(&event_bus.subscribers, topic)
	if ok {
		for i, h in handlers {
			if h == handler {
				handlers = remove(handlers, i)
				break
			}
		}
		hash_map.put(&event_bus.subscribers, topic, handlers)
	}
}

// Publish event to all subscribers
event_bus_emit :: proc(topic : string, data : string) {
	handlers, ok := hash_map.get(&event_bus.subscribers, topic)
	if ok {
		for handler in handlers {
			handler(my_window, data)
		}
	}
	
	// Also emit to frontend
	script := fmt.Sprintf(
		"window.eventBus.onEvent('%s', %s)", topic, data)
	webui.webui_run(my_window, script)
}

// Handle event subscription from frontend
event_bus_handle_subscribe :: proc "c" (e : ^webui.Event) {
	topic := webui.webui_get_string(e)
	fmt.printf("Frontend subscribed to: %s\n", topic)
}

// Handle event publish from frontend
event_bus_handle_publish :: proc "c" (e : ^webui.Event) {
	// Parse topic and data from message
	// Emit to backend subscribers
}

// ============================================================================
// Channel System (Full-Duplex)
// ============================================================================

Channel_Handler :: proc "c" (win : webui.Window, data : string)

Channel :: struct {
	name : string,
	handlers : []Channel_Handler,
}

Channel_Manager :: struct {
	channels : hash_map.HashMap(string, Channel),
}

channel_manager : Channel_Manager

// Initialize channel manager
channel_init :: proc() {
	channel_manager.channels = hash_map.create_hash_map(string, Channel, 16)
}

// Create channel
channel_create :: proc(name : string) {
	channel := Channel{
		name = name,
		handlers = make([]Channel_Handler, 0),
	}
	hash_map.put(&channel_manager.channels, name, channel)
}

// Subscribe to channel
channel_on :: proc(name : string, handler : Channel_Handler) {
	channel, ok := hash_map.get(&channel_manager.channels, name)
	if ok {
		append(&channel.handlers, handler)
		hash_map.put(&channel_manager.channels, name, channel)
	}
}

// Send to channel
channel_send :: proc(name : string, data : string) {
	channel, ok := hash_map.get(&channel_manager.channels, name)
	if ok {
		for handler in channel.handlers {
			handler(my_window, data)
		}
	}
	
	// Forward to frontend
	script := fmt.Sprintf(
		"window.channelManager.onMessage('%s', %s)", name, data)
	webui.webui_run(my_window, script)
}

// ============================================================================
// Message Queue System
// ============================================================================

Message :: struct {
	id          : string,
	type        : string,
	payload     : string,
	timestamp   : i64,
	priority    : i32,
	reply_to    : string,
	correlation : string,
}

Message_Queue :: struct {
	messages : []Message,
}

message_queue : Message_Queue

// Initialize message queue
queue_init :: proc() {
	message_queue.messages = make([]Message, 0)
}

// Push message to queue
queue_push :: proc(msg : Message) {
	append(&message_queue.messages, msg)
}

// Pop message from queue
queue_pop :: proc() -> Message {
	if len(message_queue.messages) == 0 {
		return Message{}
	}
	msg := message_queue.messages[0]
	message_queue.messages = message_queue.messages[1..]
	return msg
}

// Process queue
queue_process :: proc() {
	for len(message_queue.messages) > 0 {
		msg := queue_pop()
		// Process message
		fmt.printf("Processing message: %s\n", msg.type)
	}
}

// ============================================================================
// Binary Protocol Helpers
// ============================================================================

BINARY_MAGIC : u16 = 0xABCD

Binary_Header :: struct {
	magic    : u16,
	version  : u8,
	msg_type : u8,
	length   : u32,
}

// Encode binary message
binary_encode :: proc(msg_type : u8, payload : []u8) -> []u8 {
	buffer := make([]u8, 8 + len(payload))
	
	// Magic
	buffer[0] = 0xAB
	buffer[1] = 0xCD
	
	// Version and type
	buffer[2] = 1  // version
	buffer[3] = msg_type
	
	// Length
	*cast(^u32, &buffer[4]) = cast(u32)len(payload)
	
	// Payload
	copy(buffer[8..], payload)
	
	return buffer
}

// Decode binary message
binary_decode :: proc(data : []u8) -> (u8, []u8) {
	if len(data) < 8 || data[0] != 0xAB || data[1] != 0xCD {
		return 0, nil
	}
	
	msg_type := data[3]
	length := *cast(^u32, &data[4])
	payload := data[8 : 8+length]
	
	return msg_type, payload
}

// ============================================================================
// Unified Communication Manager
// ============================================================================

Comms_Config :: struct {
	enable_rpc : bool,
	enable_events : bool,
	enable_channels : bool,
	enable_queue : bool,
	enable_binary : bool,
}

Comms_Manager :: struct {
	config : Comms_Config,
}

comms : Comms_Manager

// Initialize all communication systems
comms_init :: proc() {
	comms = Comms_Manager{
		config = Comms_Config{
			enable_rpc = true,
			enable_events = true,
			enable_channels = false,
			enable_queue = false,
			enable_binary = false,
		},
	}
	
	// Initialize subsystems
	rpc_init()
	event_bus_init()
	channel_init()
	queue_init()
	
	// Register built-in handlers
	event_bus_on("system.ready", on_system_ready)
}

// System ready handler
on_system_ready :: proc "c" (win : webui.Window, data : string) {
	fmt.println("System ready event received")
}

// Send message using configured protocol
comms_send :: proc(topic : string, data : string) {
	if comms.config.enable_events {
		event_bus_emit(topic, data)
	}
}

// Register RPC handler
comms_rpc :: proc(method : string, handler : Rpc_Handler) {
	if comms.config.enable_rpc {
		rpc_register(method, handler)
	}
}

// Subscribe to event
comms_on :: proc(topic : string, handler : Event_Handler) {
	if comms.config.enable_events {
		event_bus_on(topic, handler)
	}
}

// Create channel
comms_channel :: proc(name : string) {
	if comms.config.enable_channels {
		channel_create(name)
	}
}
