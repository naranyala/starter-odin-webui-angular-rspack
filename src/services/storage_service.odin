// Storage Service - Persistent key-value storage - Errors as Values
package services

import "core:fmt"
import "core:os"
import "core:encoding/json"
import "core:hash_map"
import "core:sync"
import "../lib/di"
import "../lib/errors"
import "../lib/events"

Storage_Data :: struct {
	data: hash_map.HashMap(string, string),
}

Storage_Service :: struct {
	file_path: string,
	data:      hash_map.HashMap(string, string),
	logger:    ^Logger,
	event_bus: ^events.Event_Bus,
	modified:  bool,
	mutex:     sync.Mutex,
}

storage_service_create :: proc(inj: ^di.Injector) -> (^Storage_Service, errors.Error) {
	service := new(Storage_Service)
	service.data = hash_map.create_hash_map(string, string, 64)
	
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
	
	service.modified = false
	log_info(service.logger, "StorageService initialized")
	return service, errors.Error{code = errors.Error_Code.None}
}

storage_service_load :: proc(svc: ^Storage_Service, file_path: string) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if file_path == "" {
		return errors.err_invalid_param("File path cannot be empty")
	}
	
	svc.file_path = file_path
	
	if !os.exists(file_path) {
		log_info(svc.logger, fmt.Sprintf("Storage file not found: %s", file_path))
		return errors.err_not_found(fmt.Sprintf("Storage file not found: %s", file_path))
	}
	
	data, ok := os.read_entire_file(file_path)
	if !ok {
		log_info(svc.logger, fmt.Sprintf("Failed to read storage file: %s", file_path))
		return errors.err_io(fmt.Sprintf("Failed to read storage file: %s", file_path))
	}
	defer delete(data)
	
	json_err := json.unmarshal(data, &svc.data)
	if json_err != nil {
		log_info(svc.logger, fmt.Sprintf("Failed to parse storage: %v", json_err))
		return errors.err_parse(fmt.Sprintf("Failed to parse JSON: %v", json_err))
	}
	
	log_info(svc.logger, fmt.Sprintf("Storage loaded: %d entries", hash_map.len(&svc.data)))
	return errors.Error{code = errors.Error_Code.None}
}

storage_service_save :: proc(svc: ^Storage_Service) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if svc.file_path == "" {
		return errors.err_invalid_param("No storage file path set")
	}
	
	data, json_err := json.Marshal(svc.data)
	if json_err != nil {
		log_info(svc.logger, fmt.Sprintf("Failed to marshal storage: %v", json_err))
		return errors.err_parse(fmt.Sprintf("Failed to marshal to JSON: %v", json_err))
	}
	defer delete(data)
	
	ok := os.write_entire_file(svc.file_path, data)
	if !ok {
		log_info(svc.logger, fmt.Sprintf("Failed to write storage file: %s", svc.file_path))
		return errors.err_io(fmt.Sprintf("Failed to write storage file: %s", svc.file_path))
	}
	
	svc.modified = false
	log_info(svc.logger, fmt.Sprintf("Storage saved: %s", svc.file_path))
	return errors.Error{code = errors.Error_Code.None}
}

storage_service_set :: proc(svc: ^Storage_Service, key: string, value: string) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if key == "" {
		return errors.err_invalid_param("Storage key cannot be empty")
	}
	hash_map.put(&svc.data, key, value)
	svc.modified = true
	log_info(svc.logger, fmt.Sprintf("Storage set: %s", key))
	return errors.Error{code = errors.Error_Code.None}
}

storage_service_get :: proc(svc: ^Storage_Service, key: string) -> (string, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if key == "" {
		return "", errors.err_invalid_param("Storage key cannot be empty")
	}
	
	if value, ok := hash_map.get(&svc.data, key); ok {
		return value, errors.Error{code = errors.Error_Code.None}
	}
	
	return "", errors.err_not_found(fmt.Sprintf("Storage key '%s' not found", key))
}

storage_service_delete :: proc(svc: ^Storage_Service, key: string) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if key == "" {
		return errors.err_invalid_param("Storage key cannot be empty")
	}
	
	if _, ok := hash_map.get(&svc.data, key); !ok {
		return errors.err_not_found(fmt.Sprintf("Storage key '%s' not found", key))
	}
	
	hash_map.remove(&svc.data, key)
	svc.modified = true
	log_info(svc.logger, fmt.Sprintf("Storage deleted: %s", key))
	return errors.Error{code = errors.Error_Code.None}
}

storage_service_clear :: proc(svc: ^Storage_Service) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	hash_map.clear(&svc.data)
	svc.modified = true
	log_info(svc.logger, "Storage cleared")
	return errors.Error{code = errors.Error_Code.None}
}

storage_service_keys :: proc(svc: ^Storage_Service) -> ([]string, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	keys := make([]string, 0, hash_map.len(&svc.data))
	for k, _ in svc.data {
		append(&keys, k)
	}
	return keys, errors.Error{code = errors.Error_Code.None}
}

storage_service_size :: proc(svc: ^Storage_Service) -> (int, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	return hash_map.len(&svc.data), errors.Error{code = errors.Error_Code.None}
}

storage_service_is_modified :: proc(svc: ^Storage_Service) -> bool {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	return svc.modified
}

storage_service_destroy :: proc(svc: ^Storage_Service) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if svc.modified {
		// Unlock while saving? storage_service_save will lock again, causing deadlock.
		// We need to unlock before calling save.
		sync.unlock(&svc.mutex)
		save_err := storage_service_save(svc)
		if save_err.code != errors.Error_Code.None {
			// Re-lock before returning? Not needed.
			return save_err
		}
		sync.lock(&svc.mutex)
	}
	hash_map.destroy_hash_map(&svc.data)
	delete(svc)
	return errors.Error{code = errors.Error_Code.None}
}
