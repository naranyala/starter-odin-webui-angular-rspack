// Logger Utility for Desktop Applications
package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:sync"

// ============================================================================
// Log Levels
// ============================================================================

Log_Level :: enum {
    Trace,
    Debug,
    Info,
    Warn,
    Error,
    Fatal,
    Off,
}

// Get log level name
log_level_name :: proc(level : Log_Level) -> string {
    switch level {
    case Log_Level.Trace: return "TRACE"
    case Log_Level.Debug: return "DEBUG"
    case Log_Level.Info: return "INFO"
    case Log_Level.Warn: return "WARN"
    case Log_Level.Error: return "ERROR"
    case Log_Level.Fatal: return "FATAL"
    case Log_Level.Off: return "OFF"
    }
    return "UNKNOWN"
}

// Parse log level from string
log_level_parse :: proc(s : string) -> Log_Level {
    s = strings.to_upper(s)
    switch s {
    case "TRACE": return Log_Level.Trace
    case "DEBUG": return Log_Level.Debug
    case "INFO": return Log_Level.Info
    case "WARN", "WARNING": return Log_Level.Warn
    case "ERROR": return Log_Level.Error
    case "FATAL": return Log_Level.Fatal
    case "OFF": return Log_Level.Off
    }
    return Log_Level.Info
}

// ============================================================================
// Log Entry
// ============================================================================

Log_Entry :: struct {
    timestamp : time.Time,
    level : Log_Level,
    message : string,
    source : string,
    thread_id : u64,
}

// ============================================================================
// Log Writer Interface
// ============================================================================

Log_Writer :: struct {
    write : proc "c" (^Log_Writer, string),
    flush : proc "c" (^Log_Writer),
    close : proc "c" (^Log_Writer),
    user_data : rawptr,
}

// ============================================================================
// Console Writer
// ============================================================================

console_writer_write :: proc "c" (writer : ^Log_Writer, message : string) {
    fmt.print(message)
}

console_writer_flush :: proc "c" (writer : ^Log_Writer) {
    // Console doesn't need flush
}

console_writer_close :: proc "c" (writer : ^Log_Writer) {
    // Nothing to close
}

console_writer_create :: proc() -> Log_Writer {
    return Log_Writer{
        write: console_writer_write,
        flush: console_writer_flush,
        close: console_writer_close,
        user_data: nil,
    }
}

// ============================================================================
// File Writer
// ============================================================================

File_Writer_Data :: struct {
    file : os.File,
    path : string,
    max_size : i64,
    current_size : i64,
    rotation_count : i32,
}

file_writer_write :: proc "c" (writer : ^Log_Writer, message : string) {
    data := cast(^File_Writer_Data) writer.user_data
    if data == nil {
        return
    }
    
    // Check if rotation needed
    if data.max_size > 0 && data.current_size >= data.max_size {
        file_writer_rotate(writer)
    }
    
    bytes := cast([]u8) message
    n, ok := os.write(data.file, bytes)
    if ok {
        data.current_size += i64(n)
    }
}

file_writer_flush :: proc "c" (writer : ^Log_Writer) {
    data := cast(^File_Writer_Data) writer.user_data
    if data != nil {
        os.sync(data.file)
    }
}

file_writer_close :: proc "c" (writer : ^Log_Writer) {
    data := cast(^File_Writer_Data) writer.user_data
    if data != nil {
        os.close(data.file)
        delete(data)
    }
}

file_writer_rotate :: proc "c" (writer : ^Log_Writer) {
    data := cast(^File_Writer_Data) writer.user_data
    if data == nil {
        return
    }
    
    // Close current file
    os.close(data.file)
    
    // Rotate files
    for i in 1..<data.rotation_count {
        old_path := fmt.Sprintf("%s.%d", data.path, data.rotation_count - i)
        new_path := fmt.Sprintf("%s.%d", data.path, data.rotation_count - i + 1)
        if file_exists(old_path) {
            file_move(old_path, new_path)
        }
    }
    
    // Move current to .1
    if file_exists(data.path) {
        rotate_path := fmt.Sprintf("%s.1", data.path)
        file_move(data.path, rotate_path)
    }
    
    // Open new file
    f, ok := os.open(data.path, os.O_WRONLY|os.O_CREATE|os.O_APPEND)
    if ok {
        data.file = f
        data.current_size = 0
    }
}

file_writer_create :: proc(path : string, max_size : i64 = 10_485_760, rotation_count : i32 = 5) -> Log_Writer {
    data := new(File_Writer_Data)
    data.path = path
    data.max_size = max_size
    data.rotation_count = rotation_count
    data.current_size = 0
    
    // Get current file size
    if file_exists(path) {
        data.current_size = file_size(path)
    }
    
    // Open file
    f, ok := os.open(path, os.O_WRONLY|os.O_CREATE|os.O_APPEND)
    if !ok {
        // Try to create directory
        dir := path_directory(path)
        if dir_ensure(dir) {
            f, ok = os.open(path, os.O_WRONLY|os.O_CREATE|os.O_APPEND)
        }
    }
    
    if ok {
        data.file = f
    } else {
        data.file = os.STDOUT
    }
    
    return Log_Writer{
        write: file_writer_write,
        flush: file_writer_flush,
        close: file_writer_close,
        user_data: cast(rawptr) data,
    }
}

// ============================================================================
// Logger
// ============================================================================

Log_Format_Flags :: bit_set :: enum {
    Timestamp,
    Level,
    Source,
    Thread,
    Color,
    Caller,
}

Logger :: struct {
    level : Log_Level,
    format_flags : Log_Format_Flags,
    writers : []Log_Writer,
    mutex : sync.Mutex,
    source : string,
    buffer : []u8,
}

// Create logger
logger_create :: proc() -> ^Logger {
    log := new(Logger)
    log.level = Log_Level.Info
    log.format_flags = {Log_Format_Flags.Timestamp, Log_Format_Flags.Level, Log_Format_Flags.Thread}
    log.writers = make([]Log_Writer, 0)
    log.buffer = make([]u8, 0, 4096)
    
    // Add console writer by default
    append(&log.writers, console_writer_create())
    
    return log
}

// Destroy logger
logger_destroy :: proc(log : ^Logger) {
    for writer in log.writers {
        if writer.close != nil {
            writer.close(&writer)
        }
    }
    delete(log)
}

// Set log level
logger_set_level :: proc(log : ^Logger, level : Log_Level) {
    log.level = level
}

// Get log level
logger_get_level :: proc(log : ^Logger) -> Log_Level {
    return log.level
}

// Set source name
logger_set_source :: proc(log : ^Logger, source : string) {
    log.source = source
}

// Add writer
logger_add_writer :: proc(log : ^Logger, writer : Log_Writer) {
    append(&log.writers, writer)
}

// Format log message
logger_format :: proc(log : ^Logger, entry : ^Log_Entry) -> string {
    result := ""
    
    // Color start
    if {Log_Format_Flags.Color} in log.format_flags {
        result += logger_get_color(entry.level)
    }
    
    // Timestamp
    if {Log_Format_Flags.Timestamp} in log.format_flags {
        time_str := time.format(entry.timestamp, "2006-01-02 15:04:05.000")
        result += fmt.Sprintf("[%s] ", time_str)
    }
    
    // Level
    if {Log_Format_Flags.Level} in log.format_flags {
        result += fmt.Sprintf("[%s] ", log_level_name(entry.level))
    }
    
    // Source
    if {Log_Format_Flags.Source} in log.format_flags && entry.source != "" {
        result += fmt.Sprintf("[%s] ", entry.source)
    }
    
    // Thread
    if {Log_Format_Flags.Thread} in log.format_flags {
        result += fmt.Sprintf("[T:%d] ", entry.thread_id)
    }
    
    // Message
    result += entry.message
    
    // Color end
    if {Log_Format_Flags.Color} in log.format_flags {
        result += logger_get_color_reset()
    }
    
    result += "\n"
    return result
}

logger_get_color :: proc(level : Log_Level) -> string {
    switch level {
    case Log_Level.Trace: return "\x1b[90m"  // Bright Black
    case Log_Level.Debug: return "\x1b[36m"  // Cyan
    case Log_Level.Info: return "\x1b[32m"   // Green
    case Log_Level.Warn: return "\x1b[33m"   // Yellow
    case Log_Level.Error: return "\x1b[31m"  // Red
    case Log_Level.Fatal: return "\x1b[35m"  // Magenta
    }
    return ""
}

logger_get_color_reset :: proc() -> string {
    return "\x1b[0m"
}

// Internal log function
logger_log_internal :: proc(log : ^Logger, level : Log_Level, message : string, source : string) {
    if level < log.level {
        return
    }
    
    entry := Log_Entry{
        timestamp: time.now(),
        level: level,
        message: message,
        source: if source != "" then source else log.source,
        thread_id: 0, // TODO: Get actual thread ID
    }
    
    sync.lock(&log.mutex)
    defer sync.unlock(&log.mutex)
    
    formatted := logger_format(log, &entry)
    
    for writer in log.writers {
        if writer.write != nil {
            writer.write(&writer, formatted)
        }
    }
}

// Log functions
logger_trace :: proc(log : ^Logger, message : string, source : string = "") {
    logger_log_internal(log, Log_Level.Trace, message, source)
}

logger_debug :: proc(log : ^Logger, message : string, source : string = "") {
    logger_log_internal(log, Log_Level.Debug, message, source)
}

logger_info :: proc(log : ^Logger, message : string, source : string = "") {
    logger_log_internal(log, Log_Level.Info, message, source)
}

logger_warn :: proc(log : ^Logger, message : string, source : string = "") {
    logger_log_internal(log, Log_Level.Warn, message, source)
}

logger_error :: proc(log : ^Logger, message : string, source : string = "") {
    logger_log_internal(log, Log_Level.Error, message, source)
}

logger_fatal :: proc(log : ^Logger, message : string, source : string = "") {
    logger_log_internal(log, Log_Level.Fatal, message, source)
}

// Formatted log functions
logger_tracef :: proc(log : ^Logger, format : string, args : ..) {
    logger_trace(log, fmt.sprintf(format, args), "")
}

logger_debugf :: proc(log : ^Logger, format : string, args : ..) {
    logger_debug(log, fmt.sprintf(format, args), "")
}

logger_infof :: proc(log : ^Logger, format : string, args : ..) {
    logger_info(log, fmt.sprintf(format, args), "")
}

logger_warnf :: proc(log : ^Logger, format : string, args : ..) {
    logger_warn(log, fmt.sprintf(format, args), "")
}

logger_errorf :: proc(log : ^Logger, format : string, args : ..) {
    logger_error(log, fmt.sprintf(format, args), "")
}

logger_fatalf :: proc(log : ^Logger, format : string, args : ..) {
    logger_fatal(log, fmt.sprintf(format, args), "")
}

// Flush all writers
logger_flush :: proc(log : ^Logger) {
    sync.lock(&log.mutex)
    defer sync.unlock(&log.mutex)
    
    for writer in log.writers {
        if writer.flush != nil {
            writer.flush(&writer)
        }
    }
}

// ============================================================================
// Global Logger
// ============================================================================

global_logger : ^Logger

// Initialize global logger
logger_init :: proc() {
    global_logger = logger_create()
}

// Shutdown global logger
logger_shutdown :: proc() {
    if global_logger != nil {
        logger_flush(global_logger)
        logger_destroy(global_logger)
        global_logger = nil
    }
}

// Get global logger
logger_get_global :: proc() -> ^Logger {
    if global_logger == nil {
        logger_init()
    }
    return global_logger
}

// Set global logger level
logger_set_global_level :: proc(level : Log_Level) {
    logger_set_level(logger_get_global(), level)
}

// Global log functions
log_trace :: proc(message : string, source : string = "") {
    logger_trace(logger_get_global(), message, source)
}

log_debug :: proc(message : string, source : string = "") {
    logger_debug(logger_get_global(), message, source)
}

log_info :: proc(message : string, source : string = "") {
    logger_info(logger_get_global(), message, source)
}

log_warn :: proc(message : string, source : string = "") {
    logger_warn(logger_get_global(), message, source)
}

log_error :: proc(message : string, source : string = "") {
    logger_error(logger_get_global(), message, source)
}

log_fatal :: proc(message : string, source : string = "") {
    logger_fatal(logger_get_global(), message, source)
}

// Global formatted log functions
log_tracef :: proc(format : string, args : ..) {
    logger_tracef(logger_get_global(), format, args)
}

log_debugf :: proc(format : string, args : ..) {
    logger_debugf(logger_get_global(), format, args)
}

log_infof :: proc(format : string, args : ..) {
    logger_infof(logger_get_global(), format, args)
}

log_warnf :: proc(format : string, args : ..) {
    logger_warnf(logger_get_global(), format, args)
}

log_errorf :: proc(format : string, args : ..) {
    logger_errorf(logger_get_global(), format, args)
}

log_fatalf :: proc(format : string, args : ..) {
    logger_fatalf(logger_get_global(), format, args)
}

// Add file writer to global logger
logger_add_file :: proc(path : string, max_size : i64 = 10_485_760, rotation_count : i32 = 5) {
    writer := file_writer_create(path, max_size, rotation_count)
    logger_add_writer(logger_get_global(), writer)
}

// ============================================================================
// Logging Context (for structured logging)
// ============================================================================

Log_Context :: struct {
    logger : ^Logger,
    source : string,
    fields : map[string]string,
}

// Create log context
log_context_create :: proc(logger : ^Logger, source : string) -> ^Log_Context {
    ctx := new(Log_Context)
    ctx.logger = logger
    ctx.source = source
    ctx.fields = make(map[string]string)
    return ctx
}

// Add field to context
log_context_field :: proc(ctx : ^Log_Context, key : string, value : string) {
    ctx.fields[key] = value
}

// Build message with context fields
log_context_build_message :: proc(ctx : ^Log_Context, message : string) -> string {
    if len(ctx.fields) == 0 {
        return message
    }
    
    result := message + " {"
    first := true
    for key, value in ctx.fields {
        if !first {
            result += ", "
        }
        result += fmt.Sprintf("%s=%s", key, value)
        first = false
    }
    result += "}"
    return result
}

// Log with context
log_context_info :: proc(ctx : ^Log_Context, message : string) {
    logger_info(ctx.logger, log_context_build_message(ctx, message), ctx.source)
}

log_context_error :: proc(ctx : ^Log_Context, message : string) {
    logger_error(ctx.logger, log_context_build_message(ctx, message), ctx.source)
}

log_context_debug :: proc(ctx : ^Log_Context, message : string) {
    logger_debug(ctx.logger, log_context_build_message(ctx, message), ctx.source)
}

// Destroy context
log_context_destroy :: proc(ctx : ^Log_Context) {
    delete(ctx)
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Quick setup for file logging
logger_setup_file :: proc(log_path : string, level : Log_Level = Log_Level.Info) {
    logger_init()
    logger_set_global_level(level)
    logger_add_file(log_path)
}

// Quick setup for console logging
logger_setup_console :: proc(level : Log_Level = Log_Level.Info) {
    logger_init()
    logger_set_global_level(level)
}

// Log application startup
log_startup :: proc(app_name : string, version : string) {
    log_info("===========================================", "startup")
    log_info(fmt.Sprintf("%s v%s", app_name, version), "startup")
    log_info("===========================================", "startup")
}

// Log application shutdown
log_shutdown :: proc() {
    log_info("Application shutting down", "shutdown")
    logger_shutdown()
}

// Log function entry (for debugging)
log_enter :: proc(func_name : string) {
    log_debugf("Entering %s", func_name)
}

// Log function exit (for debugging)
log_exit :: proc(func_name : string) {
    log_debugf("Exiting %s", func_name)
}
