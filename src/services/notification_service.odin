// Notification Service - System notifications and alerts - Errors as Values
package services

import "core:fmt"
import "core:hash_map"
import "core:time"
import "../lib/di"
import "../lib/errors"
import "../lib/events"

Notification_Type :: enum {
	Info,
	Success,
	Warning,
	Error,
}

Notification :: struct {
	id:         int,
	title:      string,
	message:    string,
	notif_type: Notification_Type,
	timestamp:  time.Time,
	read:       bool,
	dismissed:  bool,
}

Notification_Callback :: proc(notification: ^Notification)

Notification_Service :: struct {
	notifications: hash_map.HashMap(int, Notification),
	logger:         ^Logger,
	event_bus:      ^events.Event_Bus,
	next_id:        int,
	callbacks:      hash_map.HashMap(string, Notification_Callback),
}

notification_service_create :: proc(inj: ^di.Injector) -> (^Notification_Service, errors.Error) {
	service := new(Notification_Service)
	service.notifications = hash_map.create_hash_map(int, Notification, 32)
	service.callbacks = hash_map.create_hash_map(string, Notification_Callback, 16)
	
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
	
	service.next_id = 1
	log_info(service.logger, "NotificationService initialized")
	return service, errors.Error{code = errors.Error_Code.None}
}

notification_service_notify :: proc(svc: ^Notification_Service, title: string, message: string, notif_type: Notification_Type) -> (int, errors.Error) {
	if title == "" {
		return 0, errors.err_validation("Notification title cannot be empty")
	}
	if message == "" {
		return 0, errors.err_validation("Notification message cannot be empty")
	}
	
	id := svc.next_id
	svc.next_id += 1
	
	notification := Notification{
		id         = id,
		title      = title,
		message    = message,
		notif_type = notif_type,
		timestamp  = time.now(),
		read       = false,
		dismissed  = false,
	}
	hash_map.put(&svc.notifications, id, notification)
	
	log_info(svc.logger, fmt.Sprintf("Notification: [%s] %s", notif_type, title))
	
	for _, callback in svc.callbacks {
		callback(&notification)
	}
	
	return id, errors.Error{code = errors.Error_Code.None}
}

notification_service_info :: proc(svc: ^Notification_Service, title: string, message: string) -> (int, errors.Error) {
	return notification_service_notify(svc, title, message, .Info)
}

notification_service_success :: proc(svc: ^Notification_Service, title: string, message: string) -> (int, errors.Error) {
	return notification_service_notify(svc, title, message, .Success)
}

notification_service_warning :: proc(svc: ^Notification_Service, title: string, message: string) -> (int, errors.Error) {
	return notification_service_notify(svc, title, message, .Warning)
}

notification_service_error :: proc(svc: ^Notification_Service, title: string, message: string) -> (int, errors.Error) {
	return notification_service_notify(svc, title, message, .Error)
}

notification_service_mark_read :: proc(svc: ^Notification_Service, id: int) -> errors.Error {
	if id <= 0 {
		return errors.err_invalid_param("Invalid notification id")
	}
	
	notif, ok := hash_map.get(&svc.notifications, id)
	if !ok {
		return errors.err_not_found(fmt.Sprintf("Notification with id %d not found", id))
	}
	
	notif.read = true
	hash_map.put(&svc.notifications, id, notif)
	
	return errors.Error{code = errors.Error_Code.None}
}

notification_service_dismiss :: proc(svc: ^Notification_Service, id: int) -> errors.Error {
	if id <= 0 {
		return errors.err_invalid_param("Invalid notification id")
	}
	
	notif, ok := hash_map.get(&svc.notifications, id)
	if !ok {
		return errors.err_not_found(fmt.Sprintf("Notification with id %d not found", id))
	}
	
	notif.dismissed = true
	hash_map.put(&svc.notifications, id, notif)
	
	return errors.Error{code = errors.Error_Code.None}
}

notification_service_get :: proc(svc: ^Notification_Service, id: int) -> (Notification, errors.Error) {
	if id <= 0 {
		return Notification{}, errors.err_invalid_param("Invalid notification id")
	}
	
	notif, ok := hash_map.get(&svc.notifications, id)
	if !ok {
		return Notification{}, errors.err_not_found(fmt.Sprintf("Notification with id %d not found", id))
	}
	
	return notif, errors.Error{code = errors.Error_Code.None}
}

notification_service_clear :: proc(svc: ^Notification_Service) -> errors.Error {
	hash_map.clear(&svc.notifications)
	log_info(svc.logger, "Notifications cleared")
	return errors.Error{code = errors.Error_Code.None}
}

notification_service_get_unread :: proc(svc: ^Notification_Service) -> ([]Notification, errors.Error) {
	unread := make([]Notification, 0)
	for _, notif in svc.notifications {
		if !notif.read && !notif.dismissed {
			append(&unread, notif)
		}
	}
	return unread, errors.Error{code = errors.Error_Code.None}
}

notification_service_subscribe :: proc(svc: ^Notification_Service, name: string, callback: Notification_Callback) -> errors.Error {
	if name == "" {
		return errors.err_invalid_param("Subscription name cannot be empty")
	}
	
	hash_map.put(&svc.callbacks, name, callback)
	log_info(svc.logger, fmt.Sprintf("Subscribed to notifications: %s", name))
	
	return errors.Error{code = errors.Error_Code.None}
}

notification_service_unsubscribe :: proc(svc: ^Notification_Service, name: string) -> errors.Error {
	if name == "" {
		return errors.err_invalid_param("Subscription name cannot be empty")
	}
	
	if _, ok := hash_map.get(&svc.callbacks, name); !ok {
		return errors.err_not_found(fmt.Sprintf("Subscription '%s' not found", name))
	}
	
	hash_map.remove(&svc.callbacks, name)
	log_info(svc.logger, fmt.Sprintf("Unsubscribed from notifications: %s", name))
	
	return errors.Error{code = errors.Error_Code.None}
}

notification_service_count :: proc(svc: ^Notification_Service) -> (int, errors.Error) {
	return hash_map.len(&svc.notifications), errors.Error{code = errors.Error_Code.None}
}

notification_service_destroy :: proc(svc: ^Notification_Service) -> errors.Error {
	hash_map.destroy_hash_map(&svc.notifications)
	hash_map.destroy_hash_map(&svc.callbacks)
	delete(svc)
	return errors.Error{code = errors.Error_Code.None}
}
