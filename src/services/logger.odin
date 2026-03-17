// Logger Service - Example of a basic service
package services

import "core:fmt"
import "core:time"

Logger :: struct {
	level: Logger_Level,
}

Logger_Level :: enum {
	Debug,
	Info,
	Warn,
	Error,
}

logger_create :: proc() -> ^Logger {
	logger := new(Logger)
	logger.level = .Info
	return logger
}

logger_log :: proc(logger: ^Logger, level: Logger_Level, message: string) {
	if level >= logger.level {
		timestamp := time.now()
		level_str := [...]string{"DEBUG", "INFO", "WARN", "ERROR"}
		fmt.printf("[%s] [%s] %s\n", level_str[level], timestamp, message)
	}
}

log_debug :: proc(logger: ^Logger, message: string) {
	logger_log(logger, .Debug, message)
}

log_info :: proc(logger: ^Logger, message: string) {
	logger_log(logger, .Info, message)
}

log_warn :: proc(logger: ^Logger, message: string) {
	logger_log(logger, .Warn, message)
}

log_error :: proc(logger: ^Logger, message: string) {
	logger_log(logger, .Error, message)
}
