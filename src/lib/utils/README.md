# Desktop Application Utilities for Odin

A comprehensive collection of utilities for common desktop application tasks in Odin backend applications.

## Overview

This utilities package provides:

- **File System**: File/directory operations, path utilities, file watching
- **Configuration**: JSON parsing, config management, user settings
- **Logging**: Multi-level logging, file/console output, log rotation
- **Clipboard**: Cross-platform clipboard access
- **Dialogs**: File dialogs, message boxes, progress dialogs
- **Window Utils**: Window positioning, multi-monitor support, state persistence
- **Process**: Process spawning, monitoring, IPC
- **System Info**: OS detection, CPU/memory/disk info, environment variables

## Installation

The utilities are in the `utils/` directory. Import in your Odin code:

```odin
import utils "./utils"
```

## Quick Start

```odin
package main

import "core:fmt"
import utils "./utils"

main :: proc() {
    // Initialize all utilities
    utils.utils_init()
    defer utils.utils_shutdown()
    
    // File operations
    ok := utils.file_write("test.txt", "Hello, World!")
    content, ok := utils.file_read("test.txt")
    fmt.println(content)
    
    // Logging
    utils.log_info("Application started")
    utils.log_debug("Debug information")
    utils.log_error("Error occurred")
    
    // Configuration
    config := utils.config_create()
    utils.config_load(config, "settings.json")
    utils.config_set_string(config, "username", "John")
    utils.config_set_int(config, "volume", 80)
    defer delete(config)
    
    // System info
    fmt.println(utils.system_summary())
    
    // Clipboard
    utils.clipboard_copy("Hello from Odin!")
    text, ok := utils.clipboard_paste()
    
    // Dialogs
    if utils.confirm("Do you want to continue?", "Confirm") {
        utils.alert("Operation confirmed!")
    }
    
    // Process execution
    output, ok := utils.run("ls", "-la")
    fmt.println(output)
}
```

## API Reference

### File System

#### Path Utilities

```odin
// Get path components
dir := utils.path_directory("/home/user/file.txt")  // "/home/user"
name := utils.path_filename("/home/user/file.txt")   // "file.txt"
ext := utils.path_extension("/home/user/file.txt")   // ".txt"
base := utils.path_filename_no_ext("/home/user/file.txt") // "file"

// Join paths
path := utils.path_join("home", "user", "documents") // "home/user/documents"

// Special directories
home := utils.path_home()           // User home directory
cwd := utils.path_current_dir()     // Current working directory
temp := utils.path_temp_dir()       // Temp directory
exe_dir := utils.path_executable_dir() // Executable directory
```

#### File Operations

```odin
// Read/write files
content, ok := utils.file_read("file.txt")
data, ok := utils.file_read_bytes("file.bin")
ok := utils.file_write("file.txt", "content")
ok := utils.file_write_bytes("file.bin", data)
ok := utils.file_append("log.txt", "new line")

// File info
exists := utils.file_exists("file.txt")
size := utils.file_size("file.txt")
mime := utils.file_mime_type("image.png") // "image/png"
is_text := utils.file_is_text("file.txt")

// File operations
ok := utils.file_copy("src.txt", "dst.txt")
ok := utils.file_move("old.txt", "new.txt")
ok := utils.file_delete("file.txt")

// Read/write lines
lines, ok := utils.file_read_lines("file.txt")
ok := utils.file_write_lines("file.txt", lines)
```

#### Directory Operations

```odin
// Create directories
ok := utils.dir_create("new_folder")
ok := utils.dir_create_recursive("a/b/c/d")
ok := utils.dir_ensure("config") // Create if not exists

// Directory info
exists := utils.dir_exists("folder")
entries, ok := utils.dir_list("/home/user")
for entry in entries {
    fmt.printf("%s - %s\n", entry.name, if entry.is_dir then "dir" else "file")
}

// Change directory
ok := utils.dir_set_current("/path/to/dir")
current := utils.dir_current()

// Delete directories
ok := utils.dir_delete("empty_folder")
ok := utils.dir_delete_recursive("folder_with_contents")
```

### Configuration

#### JSON Parsing

```odin
// Parse JSON
value, ok := utils.json_parse(`{"name": "John", "age": 30}`)

// Access values
name := value.object_value["name"].string_value
age := i64(value.object_value["age"].number_value)

// Create JSON
json := utils.Json_Value{
    value_type: utils.Json_Value_Type.Object,
    object_value: make(map[string]utils.Json_Value),
}
json.object_value["name"] = utils.Json_Value{
    value_type: utils.Json_Value_Type.String,
    string_value: "John",
}
json_str := utils.json_stringify(json)

// Read/write JSON files
json, ok := utils.json_read("config.json")
ok := utils.json_write("config.json", json)
```

#### Config Manager

```odin
// Create and load config
config := utils.config_create()
defer delete(config)

utils.config_load(config, "settings.json")

// Get values
name := utils.config_get_string(config, "username", "default")
age := utils.config_get_int(config, "age", 0)
enabled := utils.config_get_bool(config, "enabled", true)
volume := utils.config_get_float(config, "volume", 0.5)

// Set values
utils.config_set_string(config, "username", "John")
utils.config_set_int(config, "age", 30)
utils.config_set_bool(config, "enabled", true)
utils.config_set_float(config, "volume", 0.8)

// Save config
utils.config_save(config)

// Enable auto-save
utils.config_set_auto_save(config, true)
```

#### Settings Manager (User Preferences)

```odin
// Create settings manager
settings := utils.settings_create("MyApp")
defer utils.settings_destroy(settings)

// Get settings (user config takes precedence over app config)
theme := utils.settings_get_string(settings, "theme", "dark")
language := utils.settings_get_string(settings, "language", "en")

// Set user settings
utils.settings_set_string(settings, "theme", "light")
utils.settings_set_bool(settings, "notifications", true)

// Save settings
utils.settings_save(settings)

// Reset to defaults
utils.settings_reset(settings)
```

### Logging

#### Basic Logging

```odin
// Initialize logger
utils.logger_init()
defer utils.logger_shutdown()

// Set log level
utils.logger_set_global_level(utils.Log_Level.Debug)

// Log messages
utils.log_trace("Trace message")
utils.log_debug("Debug message")
utils.log_info("Info message")
utils.log_warn("Warning message")
utils.log_error("Error message")
utils.log_fatal("Fatal message")

// Formatted logging
utils.log_infof("User %s logged in from %s", username, ip)
utils.log_errorf("Failed to load config: %s", error_msg)
```

#### File Logging

```odin
// Setup file logging with rotation
utils.logger_setup_file("app.log", utils.Log_Level.Info)
utils.logger_add_file("app.log", 10_485_760, 5) // 10MB, 5 rotations
```

#### Custom Logger

```odin
// Create custom logger
logger := utils.logger_create()
defer utils.logger_destroy(logger)

utils.logger_set_level(logger, utils.Log_Level.Debug)
utils.logger_set_source(logger, "MyModule")

// Add file writer
writer := utils.file_writer_create("module.log")
utils.logger_add_writer(logger, writer)

// Log with custom logger
utils.logger_info(logger, "Module initialized")
utils.logger_debugf(logger, "Value: %d", value)
```

### Clipboard

```odin
// Initialize clipboard
utils.clipboard_init()
defer utils.clipboard_shutdown()

// Copy text
ok := utils.clipboard_copy("Hello, World!")

// Paste text
text, ok := utils.clipboard_paste()

// Check if clipboard has text
has_text := utils.clipboard_has_text()

// Clear clipboard
ok := utils.clipboard_clear()
```

### Dialogs

#### File Dialogs

```odin
// Open file
result := utils.dialog_open_file("Open File", {utils.file_filter_text_files()}, "")
if result.success {
    fmt.printf("Selected: %s\n", result.paths[0])
}

// Save file
result := utils.dialog_save_file("Save File", {utils.file_filter_all_files()}, "untitled.txt")
if result.success {
    fmt.printf("Save to: %s\n", result.paths[0])
}

// Open multiple files
result := utils.dialog_open_files("Open Files", nil, "")
for path in result.paths {
    fmt.printf("File: %s\n", path)
}

// Select folder
result := utils.dialog_select_folder("Select Folder", "")
if result.success {
    fmt.printf("Folder: %s\n", result.paths[0])
}

// Quick pickers
path, ok := utils.pick_file("Open File", {utils.file_filter_image_files()})
folder, ok := utils.pick_folder("Select Folder")
save_path, ok := utils.pick_save_file("Save", "default.txt")
```

#### Message Boxes

```odin
// Info message
utils.dialog_info("Information", "Operation completed successfully!")

// Warning
utils.dialog_warning("Warning", "This action cannot be undone!")

// Error
utils.dialog_error("Error", "Failed to save file!")

// Question
if utils.dialog_question("Confirm", "Do you want to continue?") == utils.Dialog_Button.Yes {
    // User clicked Yes
}

// OK/Cancel
if utils.dialog_ok_cancel("Confirm", "Save changes before closing?") == utils.Dialog_Button.OK {
    // User clicked OK
}

// Custom buttons
buttons := {utils.Dialog_Button.Yes, utils.Dialog_Button.No, utils.Dialog_Button.Cancel}
result := utils.dialog_message(utils.Dialog_Style.Question, "Title", "Message", buttons)
```

#### Progress Dialogs

```odin
// Create progress dialog
progress := utils.progress_dialog_create("Processing", "Please wait...")

// Show dialog
utils.progress_dialog_show(progress)

// Update progress
for i in 0..<100 {
    // Do work...
    utils.progress_dialog_update(progress, f32(i), fmt.Sprintf("Processing item %d", i))
}

// Close dialog
utils.progress_dialog_close(progress)
```

### Window Utilities

```odin
// Get window position
pos, ok := utils.window_get_position(window_handle)

// Set window position
ok := utils.window_set_position(window_handle, 100, 100)

// Set window size
ok := utils.window_set_size(window_handle, 800, 600)

// Center window
screen_w, screen_h := utils.window_get_screen_size()
ok := utils.window_center(window_handle, 800, 600)

// Window state
utils.window_minimize(window_handle)
utils.window_maximize(window_handle)
utils.window_restore(window_handle)

// Multi-monitor
monitors := utils.window_get_monitors()
primary := utils.window_get_primary_monitor()
monitor := utils.window_get_monitor_at(1920, 0)

// Save/restore window state
utils.window_state_save(config, "main_window", pos, utils.Window_State_Normal)
pos, state := utils.window_state_load(config, "main_window")
utils.window_state_restore(window_handle, config, "main_window")
```

### Process Utilities

```odin
// Execute command
result := utils.process_execute("ls", "-la")
fmt.printf("Output: %s\n", result.output)
fmt.printf("Exit code: %d\n", result.exit_code)

// Execute shell command
result := utils.process_execute_shell("echo Hello && date")

// Convenience functions
output, ok := utils.run("git", "status")
ok := utils.spawn("notepad", "file.txt")
exists := utils.command_exists("python")

// Process management
proc := utils.process_create()
utils.process_set_path(proc, "/path/to/executable")
utils.process_add_arg(proc, "--flag")
utils.process_add_args(proc, "arg1", "arg2")
utils.process_set_working_dir(proc, "/working/dir")

ok := utils.process_start(proc)
ok := utils.process_wait(proc, 10 * time_second)
exit_code := utils.process_get_exit_code(proc)
output := utils.process_get_output(proc)

utils.process_kill(proc)
utils.process_destroy(proc)

// Background tasks
utils.background_runner_init()
ok := utils.background_runner_start("task1", "long_running_command", "--arg")

// Check status
state := utils.background_runner_status("task1")
if state == utils.Process_State_Exited {
    result, ok := utils.background_runner_result("task1")
    utils.background_runner_remove("task1")
}
```

### System Information

```odin
// Get full system info
info := utils.system_info()
fmt.printf("OS: %s %s\n", info.os_name, info.os_version)
fmt.printf("CPU: %s (%d cores)\n", info.cpu.model, info.cpu.cores)
fmt.printf("Memory: %s / %s\n", 
    utils.system_format_size(info.memory.used),
    utils.system_format_size(info.memory.total))

// Quick queries
os_name := utils.system_os_type_name() // "Linux", "Windows", "macOS"
os_arch := utils.system_os_arch_name() // "x64", "ARM64"
cores := utils.system_cpu_cores()
mem_percent := utils.system_memory_percent()
hostname := utils.system_hostname()
user := utils.system_user()
uptime := utils.system_uptime()

// Disk info
disks := utils.system_disk_info()
for disk in disks {
    fmt.printf("%s: %s / %s (%.1f%%)\n",
        disk.mount_point,
        utils.system_format_size(disk.used),
        utils.system_format_size(disk.total),
        disk.percent_used)
}

// Network info
interfaces := utils.system_network_info()
for iface in interfaces {
    fmt.printf("%s: %s (%s)\n", iface.name, iface.ip_address, iface.mac_address)
}

// Battery info
battery := utils.system_battery_info()
if battery.is_present {
    fmt.printf("Battery: %.0f%% %s\n", 
        battery.percent,
        if battery.is_charging then "(charging)" else "")
}

// Environment variables
value := utils.system_env("PATH")
utils.system_set_env("MY_VAR", "value")
all_env := utils.system_env_all()

// System checks
on_battery := utils.system_on_battery()
low_mem := utils.system_low_memory(90.0) // 90% threshold
low_disk := utils.system_low_disk("/", 90.0)

// System summary
fmt.println(utils.system_summary())
```

## Application Helper

```odin
// Create application context
app := utils.app_create("MyApp", "1.0.0")
defer utils.app_destroy(app)

// Access components
settings := app.settings
runtime := utils.app_runtime(app)
```

## Integration

### With DI System

```odin
import di "./di"
import utils "./utils"

main :: proc() {
    container := di.create_container()
    
    // Register utilities
    utils.utils_register_di(&container)
    
    // Resolve and use
    config := cast(^utils.Config_Manager) di.resolve(&container, "config_manager")
}
```

### With Comms Layer

```odin
import comms "./comms"
import utils "./utils"

main :: proc() {
    // Initialize comms
    comms.comms_init()
    
    // Register utility RPC handlers
    utils.utils_register_comms()
}
```

## Platform Support

| Feature | Linux | Windows | macOS |
|---------|-------|---------|-------|
| File System | ✅ | ✅ | ✅ |
| Config/JSON | ✅ | ✅ | ✅ |
| Logging | ✅ | ✅ | ✅ |
| Clipboard | ⚠️ (X11) | ⚠️ | ⚠️ (osascript) |
| File Dialogs | ⚠️ (zenity) | 🔜 | ⚠️ (osascript) |
| Message Boxes | ⚠️ (zenity) | ✅ | ⚠️ (osascript) |
| Window Utils | ⚠️ (X11) | ✅ | ⚠️ (osascript) |
| Process | ✅ | ✅ | ✅ |
| System Info | ✅ | ✅ | ✅ |

✅ = Full support, ⚠️ = Partial/limited support, 🔜 = Coming soon

## License

MIT License
