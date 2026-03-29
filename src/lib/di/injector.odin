// Dependency Injection System - Errors as Values Pattern
// Thread-safe implementation with mutex protection
package di

import "core:fmt"
import "core:hash_map"
import "core:sync"

Token :: string

Provider_Type :: enum {
	Class,
	Singleton,
	Factory,
	Value,
}

Factory_Proc :: proc(injector: ^Injector) -> (rawptr, Error)

Provider :: struct {
	token:        Token,
	provider_type: Provider_Type,
	size:         int,
	value:        rawptr,
	factory:      Factory_Proc,
}

Injectable :: struct {
	token: Token,
}

// Injector with thread-safe mutex
Injector :: struct {
	providers: hash_map.HashMap(Token, Provider),
	instances: hash_map.HashMap(Token, rawptr),
	parent:    ^Injector,
	mutex:     sync.Mutex,
}

create_injector :: proc() -> (Injector, Error) {
	injector := Injector{}
	injector.providers = hash_map.create_hash_map(Token, Provider, 64)
	injector.instances = hash_map.create_hash_map(Token, rawptr, 64)
	return injector, Error{code = Error_Code.None}
}

destroy_injector :: proc(inj: ^Injector) -> Error {
	sync.lock(&inj.mutex)
	defer sync.unlock(&inj.mutex)
	
	for key, val in inj.instances {
		if val != nil {
			delete(val)
		}
	}
	hash_map.destroy_hash_map(&inj.providers)
	hash_map.destroy_hash_map(&inj.instances)
	return Error{code = Error_Code.None}
}

register :: proc(inj: ^Injector, token: Token, provider: Provider) -> Error {
	sync.lock(&inj.mutex)
	defer sync.unlock(&inj.mutex)
	hash_map.put(&inj.providers, token, provider)
	return Error{code = Error_Code.None}
}

register_class :: proc(inj: ^Injector, token: Token, factory: Factory_Proc) -> Error {
	return register(inj, token, Provider{
		token         = token,
		provider_type = .Class,
		factory       = factory,
	})
}

register_singleton :: proc(inj: ^Injector, token: Token, size: int, factory: Factory_Proc) -> Error {
	return register(inj, token, Provider{
		token         = token,
		provider_type = .Singleton,
		size          = size,
		factory       = factory,
	})
}

register_value :: proc(inj: ^Injector, token: Token, value: rawptr) -> Error {
	return register(inj, token, Provider{
		token         = token,
		provider_type = .Value,
		value         = value,
	})
}

register_factory :: proc(inj: ^Injector, token: Token, factory: Factory_Proc) -> Error {
	return register(inj, token, Provider{
		token         = token,
		provider_type = .Factory,
		factory       = factory,
	})
}

resolve :: proc(inj: ^Injector, token: Token) -> (rawptr, Error) {
	sync.lock(&inj.mutex)
	defer sync.unlock(&inj.mutex)

	if val, ok := hash_map.get(&inj.instances, token); ok {
		return val, Error{code = Error_Code.None}
	}

	if provider, ok := hash_map.get(&inj.providers, token); ok {
		instance, err := create_instance(inj, &provider)
		if err.code != Error_Code.None {
			return nil, err
		}
		if instance != nil && provider.provider_type == .Singleton {
			hash_map.put(&inj.instances, token, instance)
		}
		return instance, Error{code = Error_Code.None}
	}

	if inj.parent != nil {
		return resolve(inj.parent, token)
	}

	return nil, err_not_found(fmt.Sprintf("Token '%s' not found in injector", token))
}

resolve_or_panic :: proc(inj: ^Injector, token: Token) -> rawptr {
	instance, err := resolve(inj, token)
	if err.code != Error_Code.None {
		fmt.printf("[DI] Error: Failed to resolve '%s': %s\n", token, err.message)
	}
	return instance
}

create_instance :: proc(inj: ^Injector, provider: ^Provider) -> (rawptr, Error) {
	switch provider.provider_type {
	case .Value:
		return provider.value, Error{code = Error_Code.None}
	case .Factory:
		if provider.factory != nil {
			return provider.factory(inj)
		}
		return nil, err_di("Factory procedure is nil")
	case .Singleton:
		if provider.factory != nil {
			return provider.factory(inj)
		}
		return nil, err_di("Singleton factory procedure is nil")
	case .Class:
		if provider.factory != nil {
			return provider.factory(inj)
		}
		return nil, err_di("Class factory procedure is required")
	}
	return nil, err_internal("Unknown provider type")
}

has :: proc(inj: ^Injector, token: Token) -> (bool, Error) {
	sync.lock(&inj.mutex)
	defer sync.unlock(&inj.mutex)
	if _, ok := hash_map.get(&inj.providers, token); ok {
		return true, Error{code = Error_Code.None}
	}
	if inj.parent != nil {
		return has(inj.parent, token)
	}
	return false, Error{code = Error_Code.None}
}

inject :: proc(inj: ^Injector, $T: typeid) -> (^T, Error) {
	instance, err := resolve(inj, typeid_name(T))
	if err.code != Error_Code.None {
		return nil, err_di(fmt.Sprintf("Cannot inject %s: %s", typeid_name(T), err.message))
	}
	return cast(^T)instance, Error{code = Error_Code.None}
}

inject_or_create :: proc(inj: ^Injector, $T: typeid) -> (^T, Error) {
	instance, err := resolve(inj, typeid_name(T))
	if err.code == Error_Code.None && instance != nil {
		return cast(^T)instance, Error{code = Error_Code.None}
	}

	sync.lock(&inj.mutex)
	defer sync.unlock(&inj.mutex)
	// Double-check after acquiring lock
	if val, ok := hash_map.get(&inj.instances, typeid_name(T)); ok {
		return cast(^T)val, Error{code = Error_Code.None}
	}
	new_instance := new(T)
	hash_map.put(&inj.instances, typeid_name(T), new_instance)
	return new_instance, Error{code = Error_Code.None}
}

typeid_name :: proc($T: typeid) -> string {
	return string(typeid_of(T).name)
}

inject_many :: proc(inj: ^Injector, $T: typeid, $U: typeid) -> (^T, ^U, Error) {
	t, err_t := inject(inj, T)
	u, err_u := inject(inj, U)
	if err_t.code != Error_Code.None {
		return nil, nil, err_t
	}
	if err_u.code != Error_Code.None {
		return nil, nil, err_u
	}
	return t, u, Error{code = Error_Code.None}
}

inject_three :: proc(inj: ^Injector, $T: typeid, $U: typeid, $V: typeid) -> (^T, ^U, ^V, Error) {
	t, err_t := inject(inj, T)
	u, err_u := inject(inj, U)
	v, err_v := inject(inj, V)
	if err_t.code != Error_Code.None {
		return nil, nil, nil, err_t
	}
	if err_u.code != Error_Code.None {
		return nil, nil, nil, err_u
	}
	if err_v.code != Error_Code.None {
		return nil, nil, nil, err_v
	}
	return t, u, v, Error{code = Error_Code.None}
}
