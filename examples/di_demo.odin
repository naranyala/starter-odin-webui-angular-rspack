// DI System Demo - Working Version
package main

import "core:fmt"
import di "../di"

Logger :: struct { prefix : string }
Config :: struct { app_name : string, version : string }

create_logger :: proc(c : ^di.Container) -> rawptr {
	logger := new(Logger)
	logger.prefix = "[DI]"
	return logger
}

create_config :: proc(c : ^di.Container) -> rawptr {
	config := new(Config)
	config.app_name = "Odin App"
	config.version = "1.0"
	return config
}

LOGGER : di.Token = "logger"
CONFIG : di.Token = "config"

main :: proc() {
	fmt.printf("=== Odin DI Demo ===\n\n")
	
	container := di.create_container()
	
	fmt.printf("Registering services...\n")
	di.register_factory(&container, LOGGER, create_logger)
	di.register_factory(&container, CONFIG, create_config)
	
	fmt.printf("Resolving services...\n")
	logger := cast(^Logger) di.resolve(&container, LOGGER)
	config := cast(^Config) di.resolve(&container, CONFIG)
	
	di.assert_resolved(logger, "Logger")
	di.assert_resolved(config, "Config")
	
	fmt.printf("\nUsing services:\n")
	fmt.printf("%s App started\n", logger.prefix)
	fmt.printf("App: %s v%s\n", config.app_name, config.version)
	
	fmt.printf("\n=== Complete ===\n")
	di.destroy_container(&container)
}
