// Example: Using DI and Event Bus
package main

import "core:fmt"
import "src/lib/di"
import "src/lib/events"
import "src/services"

main :: proc() {
	fmt.println("=== DI + Events Demo ===")

	services.registry_init()
	defer services.registry_shutdown()

	services.registry_register_singleton("Logger", proc(inj: ^di.Injector) -> rawptr {
		return services.logger_create()
	})

	services.registry_register_singleton("UserService", proc(inj: ^di.Injector) -> rawptr {
		return services.user_service_create(inj)
	})

	bus := services.registry_get(events.Event_Bus)
	_ = bus
	logger := services.registry_get(services.Logger)
	_ = logger

	events.on(bus, services.User_Event, events.User_Joined, proc(data: ^services.User_Event) {
		fmt.printf(">> Event: User joined - %s (id=%d)\n", data.name, data.user_id)
	})

	events.on(bus, services.User_Event, events.User_Left, proc(data: ^services.User_Event) {
		fmt.printf(">> Event: User left - %s (id=%d)\n", data.name, data.user_id)
	})

	user_svc := cast(^services.User_Service)services.registry_get_by_name("UserService")

	fmt.println("\n--- Adding users ---")
	services.user_service_add(user_svc, "Alice")
	services.user_service_add(user_svc, "Bob")
	services.user_service_add(user_svc, "Charlie")

	fmt.Println("\n--- Processing events ---")
	events.process_events(bus)

	fmt.Println("\n--- User list ---")
	users := services.user_service_list(user_svc)
	for user in users {
		fmt.printf("  User: %s (id=%d)\n", user.name, user.id)
	}

	fmt.Println("\n--- Removing user ---")
	services.user_service_remove(user_svc, 2)
	events.process_events(bus)

	fmt.Println("\n=== Demo complete ===")
}
