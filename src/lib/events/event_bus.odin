// Type-Safe Event Bus System - Errors as Values
package events

import "core:fmt"
import "core:hash_map"
import "core:container/queue"
import "core:sync"
import "../errors"

Event_Type :: enum {
	User_Joined,
	User_Left,
	Message_Sent,
	Config_Changed,
	Service_Ready,
	Service_Stopped,
	Registration,
	Login,
	Logout,
	Session_Expired,
	Custom,
}

Event_Data :: struct {
	event_type: Event_Type,
	data:      rawptr,
}

Event_Handler :: struct {
	event_type: Event_Type,
	callback:   proc(data: rawptr),
}

Event_Bus :: struct {
	subscribers: hash_map.HashMap(Event_Type, []proc(data: rawptr)),
	queue:      queue.Queue(Event_Data),
	dispatcher: ^Event_Dispatcher,
	mutex:      sync.Mutex,
}

Event_Dispatcher :: struct {
	bus: ^Event_Bus,
}

create_event_bus :: proc() -> (Event_Bus, errors.Error) {
	bus := Event_Bus{}
	bus.subscribers = hash_map.create_hash_map(Event_Type, []proc(data: rawptr), 32)
	queue.init(&bus.queue, 8)
	return bus, errors.Error{code = errors.Error_Code.None}
}

destroy_event_bus :: proc(bus: ^Event_Bus) -> errors.Error {
	sync.lock(&bus.mutex)
	defer sync.unlock(&bus.mutex)
	for key, handlers in bus.subscribers {
		delete(handlers)
	}
	hash_map.destroy_hash_map(&bus.subscribers)
	queue.destroy(&bus.queue)
	return errors.Error{code = errors.Error_Code.None}
}

subscribe :: proc(bus: ^Event_Bus, event_type: Event_Type, callback: proc(data: rawptr)) -> errors.Error {
	sync.lock(&bus.mutex)
	defer sync.unlock(&bus.mutex)
	handlers, ok := hash_map.get(&bus.subscribers, event_type)
	if !ok {
		handlers = make([]proc(data: rawptr), 0)
	}
	append(&handlers, callback)
	hash_map.put(&bus.subscribers, event_type, handlers)
	return errors.Error{code = errors.Error_Code.None}
}

unsubscribe :: proc(bus: ^Event_Bus, event_type: Event_Type, callback: proc(data: rawptr)) -> errors.Error {
	sync.lock(&bus.mutex)
	defer sync.unlock(&bus.mutex)
	handlers_ptr, ok := hash_map.get(&bus.subscribers, event_type)
	if ok && len(handlers_ptr) > 0 {
		handlers := handlers_ptr
		found := false
		new_handlers := make([]proc(data: rawptr), 0, len(handlers) - 1)
		for h in handlers {
			if !found && h == callback {
				found = true
				continue
			}
			append(&new_handlers, h)
		}
		if found {
			delete(handlers)
			if len(new_handlers) > 0 {
				hash_map.put(&bus.subscribers, event_type, new_handlers)
			} else {
				hash_map.remove(&bus.subscribers, event_type)
			}
		}
	}
	return errors.Error{code = errors.Error_Code.None}
}

emit :: proc(bus: ^Event_Bus, event_type: Event_Type, data: rawptr) -> errors.Error {
	sync.lock(&bus.mutex)
	defer sync.unlock(&bus.mutex)
	event := Event_Data{
		event_type = event_type,
		data       = data,
	}
	queue.push(&bus.queue, event)
	return errors.Error{code = errors.Error_Code.None}
}

emit_sync :: proc(bus: ^Event_Bus, event_type: Event_Type, data: rawptr) -> errors.Error {
	sync.lock(&bus.mutex)
	handlers, ok := hash_map.get(&bus.subscribers, event_type)
	var handlers_copy: []proc(data: rawptr)
	if ok {
		handlers_copy = make([]proc(data: rawptr), len(handlers))
		copy(handlers_copy, handlers)
	}
	sync.unlock(&bus.mutex)
	if ok {
		for callback in handlers_copy {
			callback(data)
		}
		delete(handlers_copy)
	}
	return errors.Error{code = errors.Error_Code.None}
}

process_events :: proc(bus: ^Event_Bus) -> errors.Error {
	sync.lock(&bus.mutex)
	// Pop all events into local slice
	events := make([]Event_Data, 0, queue.len(&bus.queue))
	for queue.len(&bus.queue) > 0 {
		event := queue.pop(&bus.queue)
		append(&events, event)
	}
	sync.unlock(&bus.mutex)
	// Emit each event without holding lock
	for event in events {
		emit_sync(bus, event.event_type, event.data)
	}
	delete(events)
	return errors.Error{code = errors.Error_Code.None}
}

clear_queue :: proc(bus: ^Event_Bus) -> errors.Error {
	sync.lock(&bus.mutex)
	defer sync.unlock(&bus.mutex)
	queue.clear(&bus.queue)
	return errors.Error{code = errors.Error_Code.None}
}

subscriber_count :: proc(bus: ^Event_Bus, event_type: Event_Type) -> int {
	sync.lock(&bus.mutex)
	defer sync.unlock(&bus.mutex)
	if handlers, ok := hash_map.get(&bus.subscribers, event_type); ok {
		return len(handlers)
	}
	return 0
}
