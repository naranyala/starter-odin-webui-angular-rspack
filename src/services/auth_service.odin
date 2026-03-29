// Auth Service - Authentication and session management - Errors as Values
package services

import "core:fmt"
import "core:hash_map"
import "core:time"
import "core:sync"
import "../lib/di"
import "../lib/errors"
import "../lib/events"

// Session struct for token management
Session :: struct {
	token      : string,
	user_id    : int,
	expires_at : time.Time,
}

// Credentials for login/register
Credentials :: struct {
	username : string,
	password : string,
}

// Auth_User - Internal authentication user (extends base User with password)
// Base User fields: id, name, email, role, status, created_at
// Auth adds: password for authentication
Auth_User :: struct {
	id         : int,
	name       : string,  // Matches frontend User.name
	email      : string,
	password   : string,  // Auth-specific field
	role       : string,  // "user", "admin", "manager"
	status     : string,  // "Active", "Inactive", "Pending"
	created_at : string,  // ISO 8601 format string (matches frontend)
}

// Auth event types
Auth_Event_Type :: enum {
	Login,
	Logout,
	Session_Expired,
	Registration,
}

// Auth event data
Auth_Event :: struct {
	event_type : Auth_Event_Type,
	user_id    : int,
	token      : string,
}

Auth_Service :: struct {
	users:    hash_map.HashMap(string, Auth_User),
	sessions: hash_map.HashMap(string, Session),
	logger:   ^Logger,
	event_bus: ^events.Event_Bus,
	next_id:  int,
	mutex:    sync.Mutex,
}

auth_service_create :: proc(inj: ^di.Injector) -> (^Auth_Service, errors.Error) {
	service := new(Auth_Service)
	service.users = hash_map.create_hash_map(string, Auth_User, 32)
	service.sessions = hash_map.create_hash_map(string, Session, 64)
	
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
	log_info(service.logger, "AuthService initialized")
	return service, errors.Error{code = errors.Error_Code.None}
}

auth_service_register :: proc(svc: ^Auth_Service, name: string, password: string, email: string) -> (int, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if name == "" {
		return 0, errors.err_validation("Name cannot be empty")
	}
	if password == "" {
		return 0, errors.err_validation("Password cannot be empty")
	}
	if email == "" {
		return 0, errors.err_validation("Email cannot be empty")
	}

	if _, ok := hash_map.get(&svc.users, name); ok {
		return 0, errors.err_validation(fmt.Sprintf("User '%s' already exists", name))
	}

	id := svc.next_id
	svc.next_id += 1

	user := Auth_User{
		id         = id,
		name       = name,
		password   = password,
		email      = email,
		role       = "user",
		status     = "Active",
		created_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.utc(time.now())),
	}
	hash_map.put(&svc.users, name, user)

	log_info(svc.logger, fmt.Sprintf("User registered: %s (id=%d)", name, id))

	// Emit event without holding lock to avoid deadlock
	sync.unlock(&svc.mutex)
	event := Auth_Event{event_type = .Registration, user_id = id, token = ""}
	events.emit_typed(svc.event_bus, Auth_Event, .Registration, event)
	sync.lock(&svc.mutex)

	return id, errors.Error{code = errors.Error_Code.None}
}

auth_service_login :: proc(svc: ^Auth_Service, name: string, password: string) -> (string, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if name == "" {
		return "", errors.err_validation("Name cannot be empty")
	}
	if password == "" {
		return "", errors.err_validation("Password cannot be empty")
	}

	user, ok := hash_map.get(&svc.users, name)
	if !ok {
		log_info(svc.logger, fmt.Sprintf("Login failed: user '%s' not found", name))
		return "", errors.err_auth("Invalid credentials")
	}

	if user.password != password {
		log_info(svc.logger, fmt.Sprintf("Login failed: wrong password for user '%s'", name))
		return "", errors.err_auth("Invalid credentials")
	}

	token := fmt.Sprintf("token_%d_%d", user.id, time.now()._nanos)
	session := Session{
		token      = token,
		user_id    = user.id,
		expires_at = time.now() + time.Hour * 24,
	}
	hash_map.put(&svc.sessions, token, session)

	log_info(svc.logger, fmt.Sprintf("User logged in: %s", name))

	// Emit event without holding lock
	sync.unlock(&svc.mutex)
	event := Auth_Event{event_type = .Login, user_id = user.id, token = token}
	events.emit_typed(svc.event_bus, Auth_Event, .Login, event)
	sync.lock(&svc.mutex)

	return token, errors.Error{code = errors.Error_Code.None}
}

auth_service_logout :: proc(svc: ^Auth_Service, token: string) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if token == "" {
		return errors.err_invalid_param("Token cannot be empty")
	}
	
	session, ok := hash_map.get(&svc.sessions, token)
	if !ok {
		return errors.err_not_found("Session not found")
	}
	
	hash_map.remove(&svc.sessions, token)
	log_info(svc.logger, fmt.Sprintf("User logged out: %d", session.user_id))
	
	// Emit event without holding lock
	sync.unlock(&svc.mutex)
	event := Auth_Event{event_type = .Logout, user_id = session.user_id, token = token}
	events.emit_typed(svc.event_bus, Auth_Event, .Logout, event)
	sync.lock(&svc.mutex)
	
	return errors.Error{code = errors.Error_Code.None}
}

auth_service_verify :: proc(svc: ^Auth_Service, token: string) -> (int, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	if token == "" {
		return 0, errors.err_invalid_param("Token cannot be empty")
	}
	
	session, ok := hash_map.get(&svc.sessions, token)
	if !ok {
		return 0, errors.err_not_found("Session not found or expired")
	}
	
	if time.now() >= session.expires_at {
		hash_map.remove(&svc.sessions, token)
		log_info(svc.logger, fmt.Sprintf("Session expired for user: %d", session.user_id))
		
		// Emit event without holding lock
		sync.unlock(&svc.mutex)
		event := Auth_Event{event_type = .Session_Expired, user_id = session.user_id, token = token}
		events.emit_typed(svc.event_bus, Auth_Event, .Session_Expired, event)
		sync.lock(&svc.mutex)
		
		return 0, errors.err_auth("Session expired")
	}
	
	return session.user_id, errors.Error{code = errors.Error_Code.None}
}

auth_service_get_user :: proc(svc: ^Auth_Service, user_id: int) -> (Auth_User, errors.Error) {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	for _, user in svc.users {
		if user.id == user_id {
			return user, errors.Error{code = errors.Error_Code.None}
		}
	}
	return Auth_User{}, errors.err_not_found(fmt.Sprintf("User with id %d not found", user_id))
}

auth_service_cleanup :: proc(svc: ^Auth_Service) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	now := time.now()
	count := 0
	for token, session in svc.sessions {
		if now >= session.expires_at {
			hash_map.remove(&svc.sessions, token)
			count += 1
		}
	}
	if count > 0 {
		log_info(svc.logger, fmt.Sprintf("Cleaned up %d expired sessions", count))
	}
	return errors.Error{code = errors.Error_Code.None}
}

auth_service_session_count :: proc(svc: ^Auth_Service) -> int {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	return hash_map.len(&svc.sessions)
}

auth_service_user_count :: proc(svc: ^Auth_Service) -> int {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	return hash_map.len(&svc.users)
}

auth_service_destroy :: proc(svc: ^Auth_Service) -> errors.Error {
	sync.lock(&svc.mutex)
	defer sync.unlock(&svc.mutex)
	hash_map.destroy_hash_map(&svc.users)
	hash_map.destroy_hash_map(&svc.sessions)
	delete(svc)
	return errors.Error{code = errors.Error_Code.None}
}
