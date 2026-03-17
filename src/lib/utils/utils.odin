// Desktop Application Utilities for Odin Backend
// Common utilities for file system, config, logging, clipboard, dialogs, windows, processes, and system info
package utils

// Import all utility sub-packages
import "core:fmt"
import "core:os"
import "core:time"

// ============================================================================
// Package Information
// ============================================================================

utils_version :: "1.0.0"
utils_name :: "Odin Desktop Utilities"

// ============================================================================
// Initialization
// ============================================================================

// Initialize all utility systems
utils_init :: proc() {
    // Initialize logger
    logger_init()
    
    // Initialize clipboard
    clipboard_init()
    
    // Initialize dialog manager
    dialog_init()
    
    // Initialize window manager
    window_mgr_init()
    
    // Initialize process manager
    process_mgr_init()
    
    // Initialize background runner
    background_runner_init()
    
    log_info("Desktop utilities initialized", "utils")
}

// Shutdown all utility systems
utils_shutdown :: proc() {
    log_info("Shutting down desktop utilities", "utils")
    
    // Cleanup process manager
    process_mgr_kill_all()
    
    // Shutdown clipboard
    clipboard_shutdown()
    
    // Shutdown logger
    logger_shutdown()
}

// ============================================================================
// Re-exported Types and Functions
// ============================================================================

// --- From file_system.odin ---
// Path utilities
path_separator :: path_separator
path_join :: path_join
path_absolute :: path_absolute
path_directory :: path_directory
path_filename :: path_filename
path_extension :: path_extension
path_filename_no_ext :: path_filename_no_ext
path_is_absolute :: path_is_absolute
path_normalize :: path_normalize
path_home :: path_home
path_current_dir :: path_current_dir
path_temp_dir :: path_temp_dir
path_executable_dir :: path_executable_dir

// File operations
file_read :: file_read
file_read_bytes :: file_read_bytes
file_write :: file_write
file_write_bytes :: file_write_bytes
file_append :: file_append
file_exists :: file_exists
file_delete :: file_delete
file_copy :: file_copy
file_move :: file_move
file_size :: file_size
file_modified_time :: file_modified_time
file_mime_type :: file_mime_type
file_is_text :: file_is_text
file_read_lines :: file_read_lines
file_write_lines :: file_write_lines
file_unique_name :: file_unique_name

// Directory operations
dir_create :: dir_create
dir_create_recursive :: dir_create_recursive
dir_exists :: dir_exists
dir_delete :: dir_delete
dir_delete_recursive :: dir_delete_recursive
dir_list :: dir_list
dir_current :: dir_current
dir_set_current :: dir_set_current
dir_ensure :: dir_ensure

// File watcher
File_Watcher :: File_Watcher
File_Watch_Event :: File_Watch_Event
File_Watch_Callback :: File_Watch_Callback
watcher_create :: watcher_create
watcher_add :: watcher_add
watcher_remove :: watcher_remove
watcher_set_callback :: watcher_set_callback
watcher_start :: watcher_start
watcher_stop :: watcher_stop
watcher_destroy :: watcher_destroy

// --- From config.odin ---
// JSON types
Json_Value :: Json_Value
Json_Value_Type :: Json_Value_Type

// Config manager
Config_Manager :: Config_Manager
Config_Change_Callback :: Config_Change_Callback
config_create :: config_create
config_load :: config_load
config_save :: config_save
config_save_as :: config_save_as
config_get :: config_get
config_get_string :: config_get_string
config_get_int :: config_get_int
config_get_float :: config_get_float
config_get_bool :: config_get_bool
config_set :: config_set
config_set_string :: config_set_string
config_set_int :: config_set_int
config_set_float :: config_set_float
config_set_bool :: config_set_bool
config_has :: config_has
config_remove :: config_remove
config_keys :: config_keys
config_clear :: config_clear
config_set_auto_save :: config_set_auto_save
config_set_on_change :: config_set_on_change
config_is_dirty :: config_is_dirty

// Settings manager
Settings_Manager :: Settings_Manager
settings_create :: settings_create
settings_get :: settings_get
settings_get_string :: settings_get_string
settings_get_int :: settings_get_int
settings_get_bool :: settings_get_bool
settings_set :: settings_set
settings_set_string :: settings_set_string
settings_set_int :: settings_set_int
settings_set_bool :: settings_set_bool
settings_save :: settings_save
settings_reset :: settings_reset
settings_destroy :: settings_destroy

// JSON helpers
json_parse :: json_parse
json_stringify :: json_stringify
json_read :: json_read
json_write :: json_write
json_get_nested :: json_get_nested

// --- From logger.odin ---
// Log types
Log_Level :: Log_Level
Log_Entry :: Log_Entry
Log_Writer :: Log_Writer
Logger :: Logger
Log_Context :: Log_Context
Log_Format_Flags :: Log_Format_Flags

// Logger functions
logger_create :: logger_create
logger_destroy :: logger_destroy
logger_set_level :: logger_set_level
logger_get_level :: logger_get_level
logger_set_source :: logger_set_source
logger_add_writer :: logger_add_writer
logger_add_file :: logger_add_file
logger_flush :: logger_flush

// Logging functions
logger_trace :: logger_trace
logger_debug :: logger_debug
logger_info :: logger_info
logger_warn :: logger_warn
logger_error :: logger_error
logger_fatal :: logger_fatal
logger_tracef :: logger_tracef
logger_debugf :: logger_debugf
logger_infof :: logger_infof
logger_warnf :: logger_warnf
logger_errorf :: logger_errorf
logger_fatalf :: logger_fatalf

// Global logging
log_trace :: log_trace
log_debug :: log_debug
log_info :: log_info
log_warn :: log_warn
log_error :: log_error
log_fatal :: log_fatal
log_tracef :: log_tracef
log_debugf :: log_debugf
log_infof :: log_infof
log_warnf :: log_warnf
log_errorf :: log_errorf
log_fatalf :: log_fatalf
logger_init :: logger_init
logger_shutdown :: logger_shutdown
logger_set_global_level :: logger_set_global_level
logger_setup_file :: logger_setup_file
logger_setup_console :: logger_setup_console
log_startup :: log_startup
log_shutdown :: log_shutdown

// --- From clipboard.odin ---
// Clipboard functions
clipboard_init :: clipboard_init
clipboard_shutdown :: clipboard_shutdown
clipboard_set_text :: clipboard_set_text
clipboard_get_text :: clipboard_get_text
clipboard_clear :: clipboard_clear
clipboard_has_text :: clipboard_has_text
clipboard_copy :: clipboard_copy
clipboard_paste :: clipboard_paste
clipboard_cut :: clipboard_cut

// --- From dialogs.odin ---
// Dialog types
Dialog_Button :: Dialog_Button
Dialog_Style :: Dialog_Style
File_Dialog_Mode :: File_Dialog_Mode
File_Filter :: File_Filter
File_Dialog_Result :: File_Dialog_Result
Progress_Dialog :: Progress_Dialog

// File dialogs
dialog_file :: dialog_file
dialog_open_file :: dialog_open_file
dialog_save_file :: dialog_save_file
dialog_open_files :: dialog_open_files
dialog_select_folder :: dialog_select_folder

// Message dialogs
dialog_message :: dialog_message
dialog_info :: dialog_info
dialog_warning :: dialog_warning
dialog_error :: dialog_error
dialog_question :: dialog_question
dialog_ok_cancel :: dialog_ok_cancel

// Progress dialogs
progress_dialog_create :: progress_dialog_create
progress_dialog_show :: progress_dialog_show
progress_dialog_update :: progress_dialog_update
progress_dialog_close :: progress_dialog_close

// Convenience functions
pick_file :: pick_file
pick_folder :: pick_folder
pick_save_file :: pick_save_file
alert :: alert
confirm :: confirm

// File filters
file_filter_all_files :: file_filter_all_files
file_filter_text_files :: file_filter_text_files
file_filter_image_files :: file_filter_image_files
file_filter_json_files :: file_filter_json_files
file_filter_xml_files :: file_filter_xml_files
file_filter_odin_files :: file_filter_odin_files
file_filter_source_files :: file_filter_source_files
file_filter_create :: file_filter_create

// --- From window_utils.odin ---
// Window types
Window_State :: Window_State
Window_Position :: Window_Position
Monitor_Info :: Monitor_Info

// Window functions
window_get_position :: window_get_position
window_set_position :: window_set_position
window_set_size :: window_set_size
window_set_bounds :: window_set_bounds
window_get_screen_size :: window_get_screen_size
window_center :: window_center
window_center_on_monitor :: window_center_on_monitor
window_minimize :: window_minimize
window_maximize :: window_maximize
window_restore :: window_restore
window_get_monitors :: window_get_monitors
window_get_primary_monitor :: window_get_primary_monitor
window_get_monitor_at :: window_get_monitor_at
window_state_save :: window_state_save
window_state_load :: window_state_load
window_state_restore :: window_state_restore

// Convenience functions
window_center_standard :: window_center_standard
window_set_top_left :: window_set_top_left
window_set_bottom_right :: window_set_bottom_right
window_make_square :: window_make_square
window_set_aspect_ratio :: window_set_aspect_ratio

// --- From process.odin ---
// Process types
Process_State :: Process_State
Process_Priority :: Process_Priority
Process_Result :: Process_Result
Process_Info :: Process_Info
Process :: Process
Background_Task :: Background_Task

// Process functions
process_create :: process_create
process_set_name :: process_set_name
process_set_path :: process_set_path
process_add_arg :: process_add_arg
process_add_args :: process_add_args
process_set_working_dir :: process_set_working_dir
process_set_env :: process_set_env
process_start :: process_start
process_wait :: process_wait
process_kill :: process_kill
process_kill_force :: process_kill_force
process_get_output :: process_get_output
process_get_error :: process_get_error
process_get_exit_code :: process_get_exit_code
process_get_state :: process_get_state
process_get_duration :: process_get_duration
process_destroy :: process_destroy

// Process execution
process_execute :: process_execute
process_execute_shell :: process_execute_shell

// Process info
process_current_pid :: process_current_pid
process_current_name :: process_current_name
process_get_info :: process_get_info
process_is_running :: process_is_running
process_list :: process_list
process_set_priority :: process_set_priority
process_get_priority :: process_get_priority

// Background runner
background_runner_init :: background_runner_init
background_runner_start :: background_runner_start
background_runner_status :: background_runner_status
background_runner_result :: background_runner_result
background_runner_cancel :: background_runner_cancel
background_runner_remove :: background_runner_remove
background_runner_cleanup :: background_runner_cleanup

// Convenience functions
run :: run
run_shell :: run_shell
spawn :: spawn
command_exists :: command_exists
run_lines :: run_lines

// --- From system.odin ---
// System types
OS_Type :: OS_Type
OS_Architecture :: OS_Architecture
CPU_Info :: CPU_Info
Memory_Info :: Memory_Info
Disk_Info :: Disk_Info
Network_Info :: Network_Info
Battery_Info :: Battery_Info
System_Info :: System_Info

// System functions
system_os_type :: system_os_type
system_os_type_name :: system_os_type_name
system_os_arch :: system_os_arch
system_os_arch_name :: system_os_arch_name
system_os_version :: system_os_version
system_cpu_info :: system_cpu_info
system_cpu_cores :: system_cpu_cores
system_memory_info :: system_memory_info
system_memory_percent :: system_memory_percent
system_disk_info :: system_disk_info
system_disk_info_for_path :: system_disk_info_for_path
system_network_info :: system_network_info
system_battery_info :: system_battery_info
system_hostname :: system_hostname
system_uptime :: system_uptime
system_user :: system_user
system_locale :: system_locale
system_timezone :: system_timezone
system_info :: system_info

// Environment
system_env :: system_env
system_set_env :: system_set_env
system_env_all :: system_env_all
system_env_exists :: system_env_exists

// Convenience functions
system_format_size :: system_format_size
system_summary :: system_summary
system_on_battery :: system_on_battery
system_low_memory :: system_low_memory
system_low_disk :: system_low_disk

// ============================================================================
// Application Helper
// ============================================================================

App_Config :: struct {
    name : string,
    version : string,
    author : string,
    log_file : string,
    log_level : Log_Level,
    config_file : string,
}

App_Context :: struct {
    config : App_Config,
    settings : ^Settings_Manager,
    logger : ^Logger,
    start_time : time.Time,
}

// Create application context
app_create :: proc(name : string, version : string) -> ^App_Context {
    ctx := new(App_Context)
    ctx.config.name = name
    ctx.config.version = version
    ctx.config.log_file = fmt.Sprintf("%s.log", name)
    ctx.config.log_level = Log_Level.Info
    ctx.config.config_file = fmt.Sprintf("%s.json", name)
    ctx.start_time = time.now()
    
    // Initialize utilities
    utils_init()
    
    // Setup logging
    logger_setup_file(ctx.config.log_file, ctx.config.log_level)
    log_startup(name, version)
    
    // Create settings manager
    ctx.settings = settings_create(name)
    
    return ctx
}

// Destroy application context
app_destroy :: proc(ctx : ^App_Context) {
    if ctx != nil {
        log_shutdown()
        settings_destroy(ctx.settings)
        delete(ctx)
    }
}

// Get application runtime
app_runtime :: proc(ctx : ^App_Context) -> time.Duration {
    return time.now() - ctx.start_time
}

// ============================================================================
// Quick Start Helpers
// ============================================================================

// Quick file operations
read_text_file :: proc(path : string) -> (string, bool) {
    return file_read(path)
}

write_text_file :: proc(path : string, content : string) -> bool {
    return file_write(path, content)
}

append_text_file :: proc(path : string, content : string) -> bool {
    return file_append(path, content)
}

// Quick config operations
read_json_config :: proc(path : string) -> (Json_Value, bool) {
    return json_read(path)
}

write_json_config :: proc(path : string, value : Json_Value) -> bool {
    return json_write(path, value)
}

// Quick system info
get_os_name :: proc() -> string {
    return system_os_type_name()
}

get_cpu_cores :: proc() -> int {
    return system_cpu_cores()
}

get_memory_usage :: proc() -> f64 {
    return system_memory_percent()
}

get_disk_usage :: proc(path : string) -> f64 {
    disk, ok := system_disk_info_for_path(path)
    if !ok {
        return 0
    }
    return disk.percent_used
}

// Quick logging
debug_log :: proc(message : string) {
    log_debug(message, "")
}

info_log :: proc(message : string) {
    log_info(message, "")
}

error_log :: proc(message : string) {
    log_error(message, "")
}

// ============================================================================
// Integration with DI System
// ============================================================================

// Register utilities with DI container (if using di package)
utils_register_di :: proc(container : ^di.Container) {
    // Register config manager as singleton
    // di.register_singleton(container, "config_manager", size_of(Config_Manager))
    
    // Register logger as singleton
    // di.register_singleton(container, "logger", size_of(Logger))
    
    // Register settings manager as singleton
    // di.register_singleton(container, "settings", size_of(Settings_Manager))
    
    log_info("Utilities registered with DI system", "utils")
}

// ============================================================================
// Integration with Comms System
// ============================================================================

// Register utility RPC handlers (if using comms package)
utils_register_comms :: proc() {
    // File system RPCs
    // comms_rpc("file.read", handle_file_read)
    // comms_rpc("file.write", handle_file_write)
    // comms_rpc("file.exists", handle_file_exists)
    
    // Config RPCs
    // comms_rpc("config.get", handle_config_get)
    // comms_rpc("config.set", handle_config_set)
    
    // System RPCs
    // comms_rpc("system.info", handle_system_info)
    // comms_rpc("system.memory", handle_system_memory)
    // comms_rpc("system.disk", handle_system_disk)
    
    // Clipboard RPCs
    // comms_rpc("clipboard.copy", handle_clipboard_copy)
    // comms_rpc("clipboard.paste", handle_clipboard_paste)
    
    // Dialog RPCs
    // comms_rpc("dialog.openFile", handle_dialog_open_file)
    // comms_rpc("dialog.saveFile", handle_dialog_save_file)
    // comms_rpc("dialog.message", handle_dialog_message)
    
    log_info("Utility RPC handlers registered", "utils")
}
