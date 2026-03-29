// Application Services - Errors as Values Pattern
package services

import "core:fmt"
import "core:sync"
import "../lib/di"
import "../lib/errors"
import "../lib/logger"
import "../models"

Service :: struct {
	name:          string,
	is_initialized: bool,
}

service_init :: proc(s: ^Service) -> errors.Error {
	s.is_initialized = true
	logger.log_info(fmt.Sprintf("Service initialized: %s", s.name))
	return errors.Error{code = errors.Error_Code.None}
}

service_shutdown :: proc(s: ^Service) -> errors.Error {
	s.is_initialized = false
	logger.log_info(fmt.Sprintf("Service shutdown: %s", s.name))
	return errors.Error{code = errors.Error_Code.None}
}

service_is_initialized :: proc(s: ^Service) -> bool {
	return s.is_initialized
}

App_Service :: struct {
	base:     Service,
	state:    models.App_State,
	container: ^di.Container,
}

app_service_create :: proc() -> (^App_Service, errors.Error) {
	s := new(App_Service)
	s.base.name = "AppService"
	s.base.is_initialized = false
	s.state = models.App_State{}
	return s, errors.Error{code = errors.Error_Code.None}
}

app_service_init :: proc(s: ^App_Service, container: ^di.Container) -> errors.Error {
	s.container = container
	s.base.is_initialized = true
	s.state.is_initialized = true
	s.state.config = models.default_config()
	logger.log_info("App Service initialized")
	return errors.Error{code = errors.Error_Code.None}
}

app_service_start :: proc(s: ^App_Service) -> errors.Error {
	if !s.base.is_initialized {
		return errors.err_internal("App Service not initialized")
	}
	s.state.is_running = true
	logger.log_info("App Service started")
	return errors.Error{code = errors.Error_Code.None}
}

app_service_stop :: proc(s: ^App_Service) -> errors.Error {
	s.state.is_running = false
	logger.log_info("App Service stopped")
	return errors.Error{code = errors.Error_Code.None}
}

app_service_destroy :: proc(s: ^App_Service) -> errors.Error {
	stop_err := app_service_stop(s)
	if stop_err.code != errors.Error_Code.None {
		return stop_err
	}
	s.base.is_initialized = false
	delete(s)
	return errors.Error{code = errors.Error_Code.None}
}

app_service_get_state :: proc(s: ^App_Service) -> (models.App_State, errors.Error) {
	return s.state, errors.Error{code = errors.Error_Code.None}
}

Config_Service :: struct {
	base:       Service,
	config:     models.App_Config,
	config_path: string,
}

config_service_create :: proc() -> (^Config_Service, errors.Error) {
	s := new(Config_Service)
	s.base.name = "ConfigService"
	s.config = models.default_config()
	return s, errors.Error{code = errors.Error_Code.None}
}

config_service_init :: proc(s: ^Config_Service, path: string) -> errors.Error {
	if path == "" {
		return errors.err_invalid_param("Config path cannot be empty")
	}
	s.config_path = path
	s.base.is_initialized = true
	logger.log_info("Config Service initialized")
	return errors.Error{code = errors.Error_Code.None}
}

config_service_load :: proc(s: ^Config_Service) -> errors.Error {
	if !s.base.is_initialized {
		return errors.err_internal("Config Service not initialized")
	}
	logger.log_info("Configuration loaded")
	return errors.Error{code = errors.Error_Code.None}
}

config_service_save :: proc(s: ^Config_Service) -> errors.Error {
	if !s.base.is_initialized {
		return errors.err_internal("Config Service not initialized")
	}
	logger.log_info("Configuration saved")
	return errors.Error{code = errors.Error_Code.None}
}

config_service_get :: proc(s: ^Config_Service) -> (models.App_Config, errors.Error) {
	return s.config, errors.Error{code = errors.Error_Code.None}
}

config_service_set :: proc(s: ^Config_Service, config: models.App_Config) -> errors.Error {
	s.config = config
	return errors.Error{code = errors.Error_Code.None}
}

config_service_destroy :: proc(s: ^Config_Service) -> errors.Error {
	save_err := config_service_save(s)
	if save_err.code != errors.Error_Code.None {
		return save_err
	}
	s.base.is_initialized = false
	delete(s)
	return errors.Error{code = errors.Error_Code.None}
}

Logger_Service :: struct {
	base:      Service,
	log_path:  string,
	log_level: int,
	mutex:     sync.Mutex,
}

logger_service_create :: proc() -> (^Logger_Service, errors.Error) {
	s := new(Logger_Service)
	s.base.name = "LoggerService"
	s.log_level = 2
	return s, errors.Error{code = errors.Error_Code.None}
}

logger_service_init :: proc(s: ^Logger_Service, log_path: string) -> errors.Error {
	sync.lock(&s.mutex)
	defer sync.unlock(&s.mutex)
	s.log_path = log_path
	s.base.is_initialized = true
	logger.log_info("Logger Service initialized")
	return errors.Error{code = errors.Error_Code.None}
}

logger_service_set_level :: proc(s: ^Logger_Service, level: int) -> errors.Error {
	sync.lock(&s.mutex)
	defer sync.unlock(&s.mutex)
	s.log_level = level
	return errors.Error{code = errors.Error_Code.None}
}

logger_service_log :: proc(s: ^Logger_Service, level: int, message: string) -> errors.Error {
	sync.lock(&s.mutex)
	defer sync.unlock(&s.mutex)
	if level >= s.log_level {
		logger.log_info(message)
	}
	return errors.Error{code = errors.Error_Code.None}
}

logger_service_destroy :: proc(s: ^Logger_Service) -> errors.Error {
	s.base.is_initialized = false
	delete(s)
	return errors.Error{code = errors.Error_Code.None}
}

Service_Manager :: struct {
	services:     [32]^Service,
	service_count: int,
}

service_manager_create :: proc() -> (^Service_Manager, errors.Error) {
	return new(Service_Manager), errors.Error{code = errors.Error_Code.None}
}

service_manager_register :: proc(mgr: ^Service_Manager, service: ^Service) -> errors.Error {
	if mgr.service_count >= 32 {
		return errors.err_internal("Service manager full")
	}
	if service == nil {
		return errors.err_invalid_param("Service cannot be nil")
	}
	mgr.services[mgr.service_count] = service
	mgr.service_count += 1
	return errors.Error{code = errors.Error_Code.None}
}

service_manager_init_all :: proc(mgr: ^Service_Manager) -> errors.Error {
	for i in 0..<mgr.service_count {
		service := mgr.services[i]
		if service != nil {
			err := service_init(service)
			if err.code != errors.Error_Code.None {
				return err
			}
		}
	}
	return errors.Error{code = errors.Error_Code.None}
}

service_manager_start_all :: proc(mgr: ^Service_Manager) -> errors.Error {
	for i in 0..<mgr.service_count {
		service := mgr.services[i]
		if service != nil {
			logger.log_info(fmt.Sprintf("Starting service: %s", service.name))
		}
	}
	return errors.Error{code = errors.Error_Code.None}
}

service_manager_stop_all :: proc(mgr: ^Service_Manager) -> errors.Error {
	for i in 0..<mgr.service_count {
		service := mgr.services[i]
		if service != nil {
			logger.log_info(fmt.Sprintf("Stopping service: %s", service.name))
		}
	}
	return errors.Error{code = errors.Error_Code.None}
}

service_manager_shutdown_all :: proc(mgr: ^Service_Manager) -> errors.Error {
	for i in 0..<mgr.service_count {
		service := mgr.services[i]
		if service != nil {
			err := service_shutdown(service)
			if err.code != errors.Error_Code.None {
				return err
			}
		}
	}
	return errors.Error{code = errors.Error_Code.None}
}

service_manager_destroy :: proc(mgr: ^Service_Manager) -> errors.Error {
	shutdown_err := service_manager_shutdown_all(mgr)
	if shutdown_err.code != errors.Error_Code.None {
		return shutdown_err
	}
	delete(mgr)
	return errors.Error{code = errors.Error_Code.None}
}

service_manager_count :: proc(mgr: ^Service_Manager) -> int {
	return mgr.service_count
}
