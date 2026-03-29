// Service Registry - Angular-style module - Errors as Values
package services

import "core:fmt"
import "core:hash_map"
import "core:sync"
import "../lib/di"
import "../lib/errors"
import "../lib/events"

Service_Registry :: struct {
	injector:   di.Injector,
	event_bus:  events.Event_Bus,
	logger:     ^Logger,
	registered: hash_map.HashMap(string, bool),
	mutex:      sync.Mutex,
}

registry: Service_Registry

registry_init :: proc() -> errors.Error {
	sync.lock(&registry.mutex)
	defer sync.unlock(&registry.mutex)
	inj, err := di.create_injector()
	if err.code != errors.Error_Code.None {
		return err
	}
	registry.injector = inj
	
	bus, err := events.create_event_bus()
	if err.code != errors.Error_Code.None {
		return err
	}
	registry.event_bus = bus
	
	registry.registered = hash_map.create_hash_map(string, bool, 32)
	
	hash_map.put(&registry.registered, "Event_Bus", true)
	
	err = di.register_value(&registry.injector, "Event_Bus", &registry.event_bus)
	if err.code != errors.Error_Code.None {
		return err
	}
	
	registry.logger = logger_create()
	err = di.register_value(&registry.injector, "Logger", registry.logger)
	if err.code != errors.Error_Code.None {
		return err
	}
	
	log_info(registry.logger, "Service Registry initialized")
	return errors.Error{code = errors.Error_Code.None}
}

registry_register_singleton :: proc(name: string, factory: di.Factory_Proc) -> errors.Error {
	sync.lock(&registry.mutex)
	defer sync.unlock(&registry.mutex)
	if name == "" {
		return errors.err_invalid_param("Service name cannot be empty")
	}
	
	err := di.register_singleton(&registry.injector, name, 0, factory)
	if err.code != errors.Error_Code.None {
		return err
	}
	
	hash_map.put(&registry.registered, name, true)
	log_info(registry.logger, fmt.Sprintf("Registered singleton: %s", name))
	
	return errors.Error{code = errors.Error_Code.None}
}

registry_get :: proc($T: typeid) -> (^T, errors.Error) {
	sync.lock(&registry.mutex)
	defer sync.unlock(&registry.mutex)
	return di.inject(&registry.injector, T)
}

registry_get_by_name :: proc(name: string) -> (rawptr, errors.Error) {
	sync.lock(&registry.mutex)
	defer sync.unlock(&registry.mutex)
	if name == "" {
		return nil, errors.err_invalid_param("Service name cannot be empty")
	}
	return di.resolve(&registry.injector, name)
}

registry_has :: proc(name: string) -> (bool, errors.Error) {
	sync.lock(&registry.mutex)
	defer sync.unlock(&registry.mutex)
	if name == "" {
		return false, errors.err_invalid_param("Service name cannot be empty")
	}
	return di.has(&registry.injector, name)
}

registry_start :: proc() -> errors.Error {
	log_info(registry.logger, "Starting services...")
	
	events.emit(&registry.event_bus, .Service_Ready, nil)
	log_info(registry.logger, "All services started")
	
	return errors.Error{code = errors.Error_Code.None}
}

registry_shutdown :: proc() -> errors.Error {
	log_info(registry.logger, "Shutting down services...")
	
	events.emit(&registry.event_bus, .Service_Stopped, nil)
	destroy_event_bus(&registry.event_bus)
	
	err := di.destroy_injector(&registry.injector)
	if err.code != errors.Error_Code.None {
		return err
	}
	
	log_info(registry.logger, "Shutdown complete")
	return errors.Error{code = errors.Error_Code.None}
}
