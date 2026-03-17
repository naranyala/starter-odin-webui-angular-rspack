// Cache Service - In-memory caching with TTL support - Errors as Values
package services

import "core:fmt"
import "core:hash_map"
import "core:time"
import "../lib/di"
import "../lib/errors"
import "../lib/events"

Cache_Entry :: struct {
	value:      rawptr,
	expires_at: time.Time,
	created_at: time.Time,
}

Cache_Service :: struct {
	cache:     hash_map.HashMap(string, Cache_Entry),
	logger:    ^Logger,
	event_bus: ^events.Event_Bus,
	ttl:       time.Duration,
}

cache_service_create :: proc(inj: ^di.Injector) -> (^Cache_Service, errors.Error) {
	service := new(Cache_Service)
	service.cache = hash_map.create_hash_map(string, Cache_Entry, 64)
	
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
	
	service.ttl = time.Hour * 1
	log_info(service.logger, "CacheService initialized")
	return service, errors.Error{code = errors.Error_Code.None}
}

cache_service_set :: proc(svc: ^Cache_Service, key: string, value: rawptr) -> errors.Error {
	if key == "" {
		return errors.err_invalid_param("Cache key cannot be empty")
	}
	if value == nil {
		return errors.err_invalid_param("Cache value cannot be nil")
	}
	entry := Cache_Entry{
		value      = value,
		expires_at = time.now() + svc.ttl,
		created_at = time.now(),
	}
	hash_map.put(&svc.cache, key, entry)
	log_info(svc.logger, fmt.Sprintf("Cache set: %s", key))
	return errors.Error{code = errors.Error_Code.None}
}

cache_service_get :: proc(svc: ^Cache_Service, key: string) -> (rawptr, errors.Error) {
	if key == "" {
		return nil, errors.err_invalid_param("Cache key cannot be empty")
	}
	if entry, ok := hash_map.get(&svc.cache, key); ok {
		if time.now() < entry.expires_at {
			return entry.value, errors.Error{code = errors.Error_Code.None}
		}
		hash_map.remove(&svc.cache, key)
		log_info(svc.logger, fmt.Sprintf("Cache expired: %s", key))
		return nil, errors.err_cache("Cache entry expired")
	}
	return nil, errors.err_not_found(fmt.Sprintf("Cache key '%s' not found", key))
}

cache_service_delete :: proc(svc: ^Cache_Service, key: string) -> errors.Error {
	if key == "" {
		return errors.err_invalid_param("Cache key cannot be empty")
	}
	hash_map.remove(&svc.cache, key)
	log_info(svc.logger, fmt.Sprintf("Cache deleted: %s", key))
	return errors.Error{code = errors.Error_Code.None}
}

cache_service_clear :: proc(svc: ^Cache_Service) -> errors.Error {
	hash_map.clear(&svc.cache)
	log_info(svc.logger, "Cache cleared")
	return errors.Error{code = errors.Error_Code.None}
}

cache_service_cleanup :: proc(svc: ^Cache_Service) -> errors.Error {
	now := time.now()
	count := 0
	for key, entry in svc.cache {
		if now >= entry.expires_at {
			hash_map.remove(&svc.cache, key)
			count += 1
		}
	}
	if count > 0 {
		log_info(svc.logger, fmt.Sprintf("Cache cleaned up: %d entries removed", count))
	}
	return errors.Error{code = errors.Error_Code.None}
}

cache_service_size :: proc(svc: ^Cache_Service) -> (int, errors.Error) {
	return hash_map.len(&svc.cache), errors.Error{code = errors.Error_Code.None}
}

cache_service_has :: proc(svc: ^Cache_Service, key: string) -> (bool, errors.Error) {
	if entry, ok := hash_map.get(&svc.cache, key); ok {
		if time.now() < entry.expires_at {
			return true, errors.Error{code = errors.Error_Code.None}
		}
		hash_map.remove(&svc.cache, key)
	}
	return false, errors.Error{code = errors.Error_Code.None}
}

cache_service_destroy :: proc(svc: ^Cache_Service) -> errors.Error {
	hash_map.destroy_hash_map(&svc.cache)
	delete(svc)
	return errors.Error{code = errors.Error_Code.None}
}
