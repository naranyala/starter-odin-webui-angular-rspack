// Application Services
package services

import "core:fmt"
import "../lib/di"
import "../lib/logger"
import "../models"

// ============================================================================
// Service Base
// ============================================================================

// Base service interface
Service :: struct {
    name : string,
    is_initialized : bool,
}

// Initialize service
service_init :: proc(s : ^Service) {
    s.is_initialized = true
    logger.log_info(fmt.Sprintf("Service initialized: %s", s.name))
}

// Shutdown service
service_shutdown :: proc(s : ^Service) {
    s.is_initialized = false
    logger.log_info(fmt.Sprintf("Service shutdown: %s", s.name))
}

// ============================================================================
// Application Service
// ============================================================================

App_Service :: struct {
    base : Service,
    state : models.App_State,
    container : ^di.Container,
}

// Create app service
app_service_create :: proc() -> ^App_Service {
    s := new(App_Service)
    s.base.name = "AppService"
    s.base.is_initialized = false
    s.state = models.App_State{}
    return s
}

// Initialize app service
app_service_init :: proc(s : ^App_Service, container : ^di.Container) {
    s.container = container
    s.base.is_initialized = true
    s.state.is_initialized = true
    s.state.config = models.default_config()
    logger.log_info("App Service initialized")
}

// Start app service
app_service_start :: proc(s : ^App_Service) {
    if !s.base.is_initialized {
        logger.log_error("App Service not initialized")
        return
    }
    s.state.is_running = true
    logger.log_info("App Service started")
}

// Stop app service
app_service_stop :: proc(s : ^App_Service) {
    s.state.is_running = false
    logger.log_info("App Service stopped")
}

// Destroy app service
app_service_destroy :: proc(s : ^App_Service) {
    app_service_stop(s)
    s.base.is_initialized = false
    delete(s)
}

// Get app state
app_service_get_state :: proc(s : ^App_Service) -> models.App_State {
    return s.state
}

// ============================================================================
// Config Service
// ============================================================================

Config_Service :: struct {
    base : Service,
    config : models.App_Config,
    config_path : string,
}

// Create config service
config_service_create :: proc() -> ^Config_Service {
    s := new(Config_Service)
    s.base.name = "ConfigService"
    s.config = models.default_config()
    return s
}

// Initialize config service
config_service_init :: proc(s : ^Config_Service, path : string) {
    s.config_path = path
    s.base.is_initialized = true
    logger.log_info("Config Service initialized")
}

// Load configuration
config_service_load :: proc(s : ^Config_Service) -> bool {
    if !s.base.is_initialized {
        return false
    }
    // TODO: Load from file
    logger.log_info("Configuration loaded")
    return true
}

// Save configuration
config_service_save :: proc(s : ^Config_Service) -> bool {
    if !s.base.is_initialized {
        return false
    }
    // TODO: Save to file
    logger.log_info("Configuration saved")
    return true
}

// Get config value
config_service_get :: proc(s : ^Config_Service) -> models.App_Config {
    return s.config
}

// Set config value
config_service_set :: proc(s : ^Config_Service, config : models.App_Config) {
    s.config = config
}

// Destroy config service
config_service_destroy :: proc(s : ^Config_Service) {
    config_service_save(s)
    s.base.is_initialized = false
    delete(s)
}

// ============================================================================
// Logger Service
// ============================================================================

Logger_Service :: struct {
    base : Service,
    log_path : string,
    log_level : int,
}

// Create logger service
logger_service_create :: proc() -> ^Logger_Service {
    s := new(Logger_Service)
    s.base.name = "LoggerService"
    s.log_level = 2  // Info
    return s
}

// Initialize logger service
logger_service_init :: proc(s : ^Logger_Service, log_path : string) {
    s.log_path = log_path
    s.base.is_initialized = true
    logger.log_info("Logger Service initialized")
}

// Set log level
logger_service_set_level :: proc(s : ^Logger_Service, level : int) {
    s.log_level = level
}

// Log message
logger_service_log :: proc(s : ^Logger_Service, level : int, message : string) {
    if level >= s.log_level {
        logger.log_info(message)
    }
}

// Destroy logger service
logger_service_destroy :: proc(s : ^Logger_Service) {
    s.base.is_initialized = false
    delete(s)
}

// ============================================================================
// Service Manager
// ============================================================================

Service_Manager :: struct {
    services : [32]^Service,
    service_count : int,
}

// Create service manager
service_manager_create :: proc() -> ^Service_Manager {
    return new(Service_Manager)
}

// Register service
service_manager_register :: proc(mgr : ^Service_Manager, service : ^Service) -> bool {
    if mgr.service_count >= 32 {
        return false
    }
    mgr.services[mgr.service_count] = service
    mgr.service_count += 1
    return true
}

// Initialize all services
service_manager_init_all :: proc(mgr : ^Service_Manager) {
    for i in 0..<mgr.service_count {
        service := mgr.services[i]
        if service != nil {
            service_init(service)
        }
    }
}

// Start all services
service_manager_start_all :: proc(mgr : ^Service_Manager) {
    for i in 0..<mgr.service_count {
        service := mgr.services[i]
        if service != nil {
            logger.log_info(fmt.Sprintf("Starting service: %s", service.name))
        }
    }
}

// Stop all services
service_manager_stop_all :: proc(mgr : ^Service_Manager) {
    for i in 0..<mgr.service_count {
        service := mgr.services[i]
        if service != nil {
            logger.log_info(fmt.Sprintf("Stopping service: %s", service.name))
        }
    }
}

// Shutdown all services
service_manager_shutdown_all :: proc(mgr : ^Service_Manager) {
    for i in 0..<mgr.service_count {
        service := mgr.services[i]
        if service != nil {
            service_shutdown(service)
        }
    }
}

// Destroy service manager
service_manager_destroy :: proc(mgr : ^Service_Manager) {
    service_manager_shutdown_all(mgr)
    delete(mgr)
}
