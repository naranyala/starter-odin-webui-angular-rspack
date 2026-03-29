// User Service - Example of DI + Events - Errors as Values
package services

import "core:fmt"
import "core:hash_map"
import "core:sync"
import "../lib/di"
import "../lib/errors"
import "../lib/events"

export User, User_Event

// User model - MUST match frontend User interface
User :: struct {
	id         : int,
	name       : string,
	email      : string,
	role       : string,  // "user", "admin", "manager"
	status     : string,  // "Active", "Inactive", "Pending"
	created_at : string,  // ISO 8601 format
}

// User event for event bus
User_Event :: struct {
	user_id : int,
	name    : string,
}

// User Service with thread-safe operations
User_Service :: struct {
	users     : hash_map.HashMap(int, User),
	next_id   : int,
	logger    : ^Logger,
	event_bus : ^events.Event_Bus,
	mutex     : sync.Mutex,  // Thread safety
}

user_service_create :: proc(inj: ^di.Injector) -> (^User_Service, errors.Error) {
	service := new(User_Service)
	service.users = hash_map.create_hash_map(int, User, 32)
	service.next_id = 1
	
	logger, err := di.inject(inj, Logger)
	if err.code != errors.Error_Code.None {
		return nil, err
	}
	service.logger = logger
	
	event_bus, err := di.inject(inj, events.Event_Bus)
	if err.code != errors.Error_Code.None {
		return nil, err
	}
	service.event_bus = event_bus
	
	log_info(service.logger, "UserService initialized")
	return service, errors.Error{code = errors.Error_Code.None}
}

user_service_add :: proc(svc: ^User_Service, name: string) -> (int, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	
	if name == "" {
		return 0, errors.err_validation("User name cannot be empty")
	}

	id := svc.next_id
	svc.next_id += 1

	user := User{
		id         = id,
		name       = name,
		email      = "",
		role       = "user",
		status     = "Active",
		created_at = "", // Should be set by caller
	}
	hash_map.put(&svc.users, id, user)

	log_info(svc.logger, fmt.Sprintf("User added: %s (id=%d)", name, id))

	// Emit event (lock already released by defer)
	event := User_Event{user_id = id, name = name}
	events.emit_typed(svc.event_bus, User_Event, .User_Joined, event)

	return id, errors.Error{code = errors.Error_Code.None}
}

user_service_remove :: proc(svc: ^User_Service, id: int) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	
	if id <= 0 {
		return errors.err_invalid_param("Invalid user id")
	}

	user, ok := hash_map.get(&svc.users, id)
	if !ok {
		return errors.err_not_found(fmt.Sprintf("User with id %d not found", id))
	}

	hash_map.remove(&svc.users, id)
	log_info(svc.logger, fmt.Sprintf("User removed: %s (id=%d)", user.name, id))

	// Emit event (lock already released by defer)
	event := User_Event{user_id = id, name = user.name}
	events.emit_typed(svc.event_bus, User_Event, .User_Left, event)

	return errors.Error{code = errors.Error_Code.None}
}

user_service_get :: proc(svc: ^User_Service, id: int) -> (User, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	
	if id <= 0 {
		return User{}, errors.err_invalid_param("Invalid user id")
	}

	user, ok := hash_map.get(&svc.users, id)
	if !ok {
		return User{}, errors.err_not_found(fmt.Sprintf("User with id %d not found", id))
	}

	return user, errors.Error{code = errors.Error_Code.None}
}

user_service_list :: proc(svc: ^User_Service) -> ([]User, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	
	users := make([]User, 0, hash_map.len(&svc.users))
	for _, user in svc.users {
		append(&users, user)
	}
	return users, errors.Error{code = errors.Error_Code.None}
}

user_service_update :: proc(svc: ^User_Service, id: int, name: string) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	
	if id <= 0 {
		return errors.err_invalid_param("Invalid user id")
	}
	if name == "" {
		return errors.err_validation("User name cannot be empty")
	}

	user, ok := hash_map.get(&svc.users, id)
	if !ok {
		return errors.err_not_found(fmt.Sprintf("User with id %d not found", id))
	}

	user.name = name
	hash_map.put(&svc.users, id, user)

	log_info(svc.logger, fmt.Sprintf("User updated: %s (id=%d)", name, id))

	return errors.Error{code = errors.Error_Code.None}
}

user_service_count :: proc(svc: ^User_Service) -> (int, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	return hash_map.len(&svc.users), errors.Error{code = errors.Error_Code.None}
}

user_service_destroy :: proc(svc: ^User_Service) -> errors.Error {
	hash_map.destroy_hash_map(&svc.users)
	delete(svc)
	return errors.Error{code = errors.Error_Code.None}
}
