// Typed Event Handler Helpers - Errors as Values
package events

import "core:fmt"
import "../errors"

Event_Handler_Typed :: struct($T: typeid) {
	callback: proc(data: ^T),
}

subscribe_typed :: proc(bus: ^Event_Bus, $T: typeid, event_type: Event_Type, callback: proc(data: ^T)) -> errors.Error {
	wrapper := proc(data: rawptr) {
		callback(cast(^T)data)
	}
	return subscribe(bus, event_type, wrapper)
}

emit_typed :: proc(bus: ^Event_Bus, $T: typeid, event_type: Event_Type, data: T) -> errors.Error {
	return emit(bus, event_type, &data)
}

on :: proc(bus: ^Event_Bus, $T: typeid, event_type: Event_Type, callback: proc(data: ^T)) -> errors.Error {
	return subscribe_typed(bus, T, event_type, callback)
}
