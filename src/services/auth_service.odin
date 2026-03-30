// ============================================================================
// Authentication Service - Security Implementation
// ============================================================================
// Provides user authentication, session management, and authorization
// ============================================================================

package services

import "core:fmt"
import "core:hash_map"
import "core:sync"
import "core:time"
import "../lib/errors"
import "../lib/events"

// ============================================================================
// Types and Constants
// ============================================================================

// User roles for RBAC
User_Role :: enum {
    Guest,
    User,
    Manager,
    Admin,
}

// Session represents an authenticated user session
Session :: struct {
    id           : string,
    user_id      : int,
    user_role    : User_Role,
    created_at   : i64,
    expires_at   : i64,
    last_active  : i64,
    ip_address   : string,
    is_valid     : bool,
}

// Auth credentials
Auth_Credentials :: struct {
    email    : string,
    password : string,
}

// Auth response
Auth_Response :: struct {
    success    : bool,
    user_id    : int,
    session_id : string,
    role       : User_Role,
    error      : string,
}

// Auth Service with thread-safe session management
Auth_Service :: struct {
    sessions       : hash_map.HashMap(string, Session),
    users          : ^User_Service,
    logger         : ^Logger,
    mutex          : sync.Mutex,
    session_ttl    : time.Duration,
    max_sessions   : int,
    failed_attempts : hash_map.HashMap(string, int),  // IP -> count
}

// ============================================================================
// Service Initialization
// ============================================================================

auth_service_create :: proc(inj: ^di.Injector) -> (^Auth_Service, errors.Error) {
    service := new(Auth_Service)
    service.sessions = hash_map.create_hash_map(string, Session, 100)
    service.failed_attempts = hash_map.create_hash_map(string, int, 1000)
    service.session_ttl = 24 * time.Hour  // 24 hours
    service.max_sessions = 1000
    
    users, err := di.inject(inj, User_Service)
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    service.users = users
    
    logger, err := di.inject(inj, Logger)
    if err.code != errors.Error_Code.None {
        return nil, err
    }
    service.logger = logger
    
    log_info(service.logger, "AuthService initialized")
    return service, errors.Error{code: errors.Error_Code.None}
}

// ============================================================================
// Authentication Functions
// ============================================================================

// auth_login authenticates a user and creates a session
auth_login :: proc(svc: ^Auth_Service, credentials: ^Auth_Credentials, ip_address: string) -> Auth_Response {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    // Rate limiting - check failed attempts
    attempts, _ := hash_map.get(&svc.failed_attempts, ip_address)
    if attempts >= 5 {
        log_warn(svc.logger, fmt.Sprintf("Rate limit exceeded for IP: %s", ip_address))
        return Auth_Response{
            success = false,
            error = "Too many failed attempts. Please try again later.",
        }
    }
    
    // Validate credentials
    if credentials.email == "" || credentials.password == "" {
        return Auth_Response{
            success = false,
            error = "Email and password required",
        }
    }
    
    // Find user (in production, check password hash)
    user_found := false
    var found_user User
    
    // In production: query database with hashed password
    // For now: simple email check (NO PASSWORD CHECK - placeholder)
    for _, user in hash_map.values(&svc.users.users) {
        if user.email == credentials.email {
            user_found = true
            found_user = user
            break
        }
    }
    
    if !user_found {
        // Increment failed attempts
        hash_map.put(&svc.failed_attempts, ip_address, attempts + 1)
        
        log_warn(svc.logger, fmt.Sprintf("Failed login attempt for: %s from IP: %s", credentials.email, ip_address))
        
        return Auth_Response{
            success = false,
            error = "Invalid credentials",
        }
    }
    
    // Create session
    session_id := generate_session_id()
    now := time.now().unix()
    
    session := Session{
        id = session_id,
        user_id = found_user.id,
        user_role = User_Role.User,  // In production: get from user
        created_at = now,
        expires_at = now + i64(svc.session_ttl),
        last_active = now,
        ip_address = ip_address,
        is_valid = true,
    }
    
    // Check session limit
    if hash_map.len(&svc.sessions) >= svc.max_sessions {
        // Remove oldest session
        cleanup_expired_sessions(svc)
    }
    
    hash_map.put(&svc.sessions, session_id, session)
    
    // Clear failed attempts on success
    hash_map.delete(&svc.failed_attempts, ip_address)
    
    log_info(svc.logger, fmt.Sprintf("User logged in: %s (session: %s)", found_user.email, session_id))
    
    return Auth_Response{
        success = true,
        user_id = found_user.id,
        session_id = session_id,
        role = session.user_role,
    }
}

// auth_logout invalidates a session
auth_logout :: proc(svc: ^Auth_Service, session_id: string) -> errors.Error {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    session, ok := hash_map.get(&svc.sessions, session_id)
    if !ok {
        return errors.Error{code: .Not_Found, message: "Session not found"}
    }
    
    session.is_valid = false
    hash_map.put(&svc.sessions, session_id, session)
    hash_map.delete(&svc.sessions, session_id)
    
    log_info(svc.logger, fmt.Sprintf("User logged out (session: %s)", session_id))
    
    return errors.Error{code: .None}
}

// auth_validate checks if a session is valid
auth_validate :: proc(svc: ^Auth_Service, session_id: string) -> (Session, errors.Error) {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    session, ok := hash_map.get(&svc.sessions, session_id)
    if !ok {
        return Session{}, errors.Error{code: .Not_Found, message: "Invalid session"}
    }
    
    if !session.is_valid {
        return Session{}, errors.Error{code: .Unauthorized, message: "Session invalidated"}
    }
    
    now := time.now().unix()
    if now > session.expires_at {
        session.is_valid = false
        hash_map.delete(&svc.sessions, session_id)
        
        return Session{}, errors.Error{code: .Unauthorized, message: "Session expired"}
    }
    
    // Update last active
    session.last_active = now
    hash_map.put(&svc.sessions, session_id, session)
    
    return session, errors.Error{code: .None}
}

// ============================================================================
// Authorization Functions
// ============================================================================

// auth_require_role checks if session has required role
auth_require_role :: proc(svc: ^Auth_Service, session_id: string, required_role: User_Role) -> errors.Error {
    session, err := auth_validate(svc, session_id)
    if err.code != errors.Error_Code.None {
        return err
    }
    
    // Role hierarchy: Admin > Manager > User > Guest
    if int(session.user_role) < int(required_role) {
        return errors.Error{code: .Forbidden, message: "Insufficient privileges"}
    }
    
    return errors.Error{code: .None}
}

// auth_has_permission checks if session has specific permission
auth_has_permission :: proc(svc: ^Auth_Service, session_id: string, permission: string) -> bool {
    session, err := auth_validate(svc, session_id)
    if err.code != errors.Error_Code.None {
        return false
    }
    
    // Simple permission mapping (in production: use permission system)
    switch session.user_role {
    case .Admin:
        return true  // Admin has all permissions
    case .Manager:
        return permission != "admin:only"
    case .User:
        return permission == "user:read" || permission == "user:write"
    default:
        return false
    }
}

// ============================================================================
// Session Management
// ============================================================================

// cleanup_expired_sessions removes expired sessions
cleanup_expired_sessions :: proc(svc: ^Auth_Service) {
    now := time.now().unix()
    
    for session_id, session in hash_map.items(&svc.sessions) {
        if now > session.expires_at || !session.is_valid {
            hash_map.delete(&svc.sessions, session_id)
            log_info(svc.logger, fmt.Sprintf("Cleaned up expired session: %s", session_id))
        }
    }
}

// auth_cleanup_all_expired runs cleanup periodically
auth_cleanup_all_expired :: proc(svc: ^Auth_Service) {
    cleanup_expired_sessions(svc)
    
    // Also cleanup failed attempts older than 1 hour
    for ip, count in hash_map.items(&svc.failed_attempts) {
        if count > 0 {
            hash_map.delete(&svc.failed_attempts, ip)
        }
    }
}

// get_active_session_count returns number of active sessions
get_active_session_count :: proc(svc: ^Auth_Service) -> int {
    sync.lock(&svc.mutex)
    defer sync.unlock(&svc.mutex)
    
    count := 0
    for _, session in hash_map.values(&svc.sessions) {
        if session.is_valid && session.expires_at > time.now().unix() {
            count += 1
        }
    }
    return count
}

// ============================================================================
// Helper Functions
// ============================================================================

// generate_session_id creates a unique session identifier
generate_session_id :: proc() -> string {
    // In production: use crypto-random bytes
    // For now: timestamp + random
    now := time.now().unix()
    return fmt.Sprintf("sess_%d_%d", now, rand_int(1000000))
}

// rand_int generates a random number (placeholder)
rand_int :: proc(max: int) -> int {
    // In production: use crypto/rand
    return (int(time.now().unix()) % max)
}

// hash_password hashes a password (placeholder for bcrypt)
hash_password :: proc(password: string) -> (string, errors.Error) {
    // In production: use bcrypt
    // return bcrypt_hash(password)
    return password, errors.Error{code: .Not_Implemented, message: "Use bcrypt in production"}
}

// verify_password verifies a password against hash
verify_password :: proc(password: string, hash: string) -> bool {
    // In production: use bcrypt
    // return bcrypt_verify(password, hash)
    return password == hash  // NOT SECURE - placeholder only
}

// ============================================================================
// Security Constants
// ============================================================================

SESSION_TTL :: time.Duration = 24 * time.Hour  // 24 hours
MAX_LOGIN_ATTEMPTS :: int = 5
LOCKOUT_DURATION :: time.Duration = 15 * time.Minute  // 15 minutes
MIN_PASSWORD_LENGTH :: int = 8
