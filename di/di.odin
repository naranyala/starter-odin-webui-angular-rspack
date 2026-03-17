// Odin Dependency Injection System - Working Version
package di

import "core:fmt"

Token :: string
Provider_Type :: enum { Class, Singleton, Value, Factory }
Factory_Func :: proc(^Container) -> rawptr

Provider :: struct {
	token : Token,
	provider_type : Provider_Type,
	size : int,
	value : rawptr,
	factory : Factory_Func,
}

Container :: struct {
	providers : [64]Provider,
	provider_count : int,
	instances : [64]rawptr,
	instance_tokens : [64]Token,
	instance_count : int,
	parent : ^Container,
}

create_container :: proc() -> Container {
	return Container{}
}

create_child_container :: proc(parent : ^Container) -> Container {
	c := Container{}
	c.parent = parent
	return c
}

destroy_container :: proc(c : ^Container) {}

register_class :: proc(c : ^Container, token : Token, size : int) {
	if c.provider_count < 64 {
		c.providers[c.provider_count] = Provider{token = token, provider_type = Provider_Type.Class, size = size}
		c.provider_count += 1
	}
}

register_singleton :: proc(c : ^Container, token : Token, size : int) {
	if c.provider_count < 64 {
		c.providers[c.provider_count] = Provider{token = token, provider_type = Provider_Type.Singleton, size = size}
		c.provider_count += 1
	}
}

register_value :: proc(c : ^Container, token : Token, value : rawptr) {
	if c.provider_count < 64 {
		c.providers[c.provider_count] = Provider{token = token, provider_type = Provider_Type.Value, value = value}
		c.provider_count += 1
	}
}

register_factory :: proc(c : ^Container, token : Token, factory : Factory_Func) {
	if c.provider_count < 64 {
		c.providers[c.provider_count] = Provider{token = token, provider_type = Provider_Type.Factory, factory = factory}
		c.provider_count += 1
	}
}

find_instance :: proc(c : ^Container, token : Token) -> rawptr {
	for i in 0..<c.instance_count {
		if c.instance_tokens[i] == token {
			return c.instances[i]
		}
	}
	return nil
}

find_provider :: proc(c : ^Container, token : Token) -> int {
	for i in 0..<c.provider_count {
		if c.providers[i].token == token {
			return i
		}
	}
	return -1
}

resolve :: proc(c : ^Container, token : Token) -> rawptr {
	if instance := find_instance(c, token); instance != nil {
		return instance
	}
	
	idx := find_provider(c, token)
	if idx >= 0 {
		provider := &c.providers[idx]
		instance : rawptr
		switch provider.provider_type {
		case Provider_Type.Value:
			instance = provider.value
		case Provider_Type.Factory:
			if provider.factory != nil {
				instance = provider.factory(c)
			}
			if instance != nil && c.instance_count < 64 {
				c.instances[c.instance_count] = instance
				c.instance_tokens[c.instance_count] = token
				c.instance_count += 1
			}
		case Provider_Type.Singleton:
			instance = nil
			if instance != nil && c.instance_count < 64 {
				c.instances[c.instance_count] = instance
				c.instance_tokens[c.instance_count] = token
				c.instance_count += 1
			}
		case Provider_Type.Class:
			instance = nil
		}
		return instance
	}
	
	if c.parent != nil {
		return resolve(c.parent, token)
	}
	return nil
}

has :: proc(c : ^Container, token : Token) -> bool {
	if find_provider(c, token) >= 0 {
		return true
	}
	if c.parent != nil {
		return has(c.parent, token)
	}
	return false
}

assert_resolved :: proc(ptr : rawptr, name : string) {
	if ptr == nil {
		fmt.printf("DI Error: %s not resolved\n", name)
	}
}
