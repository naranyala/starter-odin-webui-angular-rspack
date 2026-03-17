// Desktop Utilities Example
// Demonstrates all utility functions
package main

import "core:fmt"
import "core:time"
import utils "./utils"

main :: proc() {
    fmt.println("===========================================")
    fmt.println("  Odin Desktop Utilities Example")
    fmt.println("===========================================")
    fmt.println()
    
    // Initialize utilities
    utils.utils_init()
    defer utils.utils_shutdown()
    
    // =========================================================================
    // File System Examples
    // =========================================================================
    fmt.println("=== File System Examples ===")
    
    // Path utilities
    fmt.println("\nPath Utilities:")
    fmt.printf("  Home: %s\n", utils.path_home())
    fmt.printf("  Current: %s\n", utils.path_current_dir())
    fmt.printf("  Temp: %s\n", utils.path_temp_dir())
    
    path := utils.path_join(utils.path_temp_dir(), "test.txt")
    fmt.printf("  Joined path: %s\n", path)
    fmt.printf("  Directory: %s\n", utils.path_directory(path))
    fmt.printf("  Filename: %s\n", utils.path_filename(path))
    fmt.printf("  Extension: %s\n", utils.path_extension(path))
    
    // File operations
    fmt.println("\nFile Operations:")
    test_file := utils.path_join(utils.path_temp_dir(), "odin_test.txt")
    
    ok := utils.file_write(test_file, "Hello from Odin Utilities!\nLine 2\nLine 3")
    fmt.printf("  Write file: %v\n", ok)
    
    content, ok := utils.file_read(test_file)
    fmt.printf("  Read file: %v\n", ok)
    if ok {
        fmt.printf("  Content:\n%s\n", content)
    }
    
    fmt.printf("  File exists: %v\n", utils.file_exists(test_file))
    fmt.printf("  File size: %d bytes\n", utils.file_size(test_file))
    fmt.printf("  MIME type: %s\n", utils.file_mime_type(test_file))
    
    lines, ok := utils.file_read_lines(test_file)
    if ok {
        fmt.printf("  Lines: %d\n", len(lines))
    }
    
    // Directory operations
    fmt.println("\nDirectory Operations:")
    test_dir := utils.path_join(utils.path_temp_dir(), "odin_test_dir")
    ok = utils.dir_create(test_dir)
    fmt.printf("  Create dir: %v\n", ok)
    fmt.printf("  Dir exists: %v\n", utils.dir_exists(test_dir))
    
    entries, ok := utils.dir_list(utils.path_home())
    if ok {
        fmt.printf("  Home dir entries (first 5):\n")
        count := 0
        for entry in entries {
            if count >= 5 {
                break
            }
            fmt.printf("    %s (%s)\n", entry.name, if entry.is_dir then "dir" else "file")
            count += 1
        }
    }
    
    // Cleanup
    utils.file_delete(test_file)
    utils.dir_delete(test_dir)
    
    // =========================================================================
    // Configuration Examples
    // =========================================================================
    fmt.println("\n=== Configuration Examples ===")
    
    // JSON parsing
    fmt.println("\nJSON Parsing:")
    json_str := `{"name": "John", "age": 30, "active": true, "scores": [1, 2, 3]}`
    json, ok := utils.json_parse(json_str)
    if ok {
        name := json.object_value["name"].string_value
        age := i64(json.object_value["age"].number_value)
        active := json.object_value["active"].bool_value
        fmt.printf("  Parsed: name=%s, age=%d, active=%v\n", name, age, active)
        
        // Stringify back
        output := utils.json_stringify(json)
        fmt.printf("  Stringified: %s\n", output)
    }
    
    // Config manager
    fmt.println("\nConfig Manager:")
    config := utils.config_create()
    defer delete(config)
    
    utils.config_set_string(config, "username", "Developer")
    utils.config_set_int(config, "volume", 75)
    utils.config_set_bool(config, "notifications", true)
    utils.config_set_float(config, "brightness", 0.8)
    
    fmt.printf("  Username: %s\n", utils.config_get_string(config, "username", ""))
    fmt.printf("  Volume: %d\n", utils.config_get_int(config, "volume", 0))
    fmt.printf("  Notifications: %v\n", utils.config_get_bool(config, "notifications", false))
    fmt.printf("  Brightness: %.2f\n", utils.config_get_float(config, "brightness", 0))
    fmt.printf("  Has key: %v\n", utils.config_has(config, "volume"))
    
    // =========================================================================
    // Logging Examples
    // =========================================================================
    fmt.println("\n=== Logging Examples ===")
    
    utils.log_info("Application started")
    utils.log_debug("Debug information")
    utils.log_warn("Warning message")
    utils.log_error("Error occurred")
    utils.log_infof("Formatted: %d + %d = %d", 2, 3, 5)
    
    // =========================================================================
    // Clipboard Examples
    // =========================================================================
    fmt.println("\n=== Clipboard Examples ===")
    
    test_text := "Hello from Odin Utilities!"
    ok = utils.clipboard_copy(test_text)
    fmt.printf("  Copy to clipboard: %v\n", ok)
    
    has_text := utils.clipboard_has_text()
    fmt.printf("  Has text: %v\n", has_text)
    
    pasted, ok := utils.clipboard_paste()
    if ok {
        fmt.printf("  Pasted: %s\n", pasted)
    }
    
    // =========================================================================
    // Dialog Examples (Non-blocking demos)
    // =========================================================================
    fmt.println("\n=== Dialog Examples ===")
    
    // File filters
    fmt.println("  File Filters:")
    fmt.printf("    Text: %s\n", utils.file_filter_to_string(utils.file_filter_text_files()))
    fmt.printf("    Images: %s\n", utils.file_filter_to_string(utils.file_filter_image_files()))
    fmt.printf("    All: %s\n", utils.file_filter_to_string(utils.file_filter_all_files()))
    
    // Note: Actual dialogs would be shown in a GUI application
    fmt.println("  (Dialogs would appear in a GUI application)")
    
    // =========================================================================
    // Window Examples
    // =========================================================================
    fmt.println("\n=== Window Examples ===")
    
    screen_w, screen_h := utils.window_get_screen_size()
    fmt.printf("  Screen size: %d x %d\n", screen_w, screen_h)
    
    monitors := utils.window_get_monitors()
    fmt.printf("  Monitors: %d\n", len(monitors))
    for i, monitor in monitors {
        fmt.printf("    Monitor %d: %d x %d%s\n", 
            i, monitor.width, monitor.height, 
            if monitor.is_primary then " (primary)" else "")
    }
    
    // =========================================================================
    // Process Examples
    // =========================================================================
    fmt.println("\n=== Process Examples ===")
    
    // Run commands
    fmt.println("  Running commands:")
    
    output, ok := utils.run("echo", "Hello from process!")
    if ok {
        fmt.printf("    echo: %s\n", utils.strings.trim_right(output, "\n"))
    }
    
    #if ODIN_OS != .Windows
        output, ok = utils.run("uname", "-a")
        if ok {
            fmt.printf("    uname: %s\n", utils.strings.trim_right(output, "\n"))
        }
    #else
        output, ok = utils.run("ver")
        if ok {
            fmt.printf("    ver: %s\n", utils.strings.trim_right(output, "\n"))
        }
    #end
    
    // Check command existence
    fmt.printf("  Command 'git' exists: %v\n", utils.command_exists("git"))
    fmt.printf("  Command 'python' exists: %v\n", utils.command_exists("python"))
    
    // Process info
    fmt.printf("  Current PID: %d\n", utils.process_current_pid())
    fmt.printf("  Current process: %s\n", utils.process_current_name())
    
    // =========================================================================
    // System Information Examples
    // =========================================================================
    fmt.println("\n=== System Information Examples ===")
    
    // OS info
    fmt.println("  OS Information:")
    fmt.printf("    Type: %s\n", utils.system_os_type_name())
    fmt.printf("    Architecture: %s\n", utils.system_os_arch_name())
    fmt.printf("    Version: %s\n", utils.system_os_version())
    fmt.printf("    Hostname: %s\n", utils.system_hostname())
    
    // CPU info
    cpu := utils.system_cpu_info()
    fmt.println("  CPU:")
    fmt.printf("    Model: %s\n", cpu.model)
    fmt.printf("    Cores: %d\n", cpu.cores)
    fmt.printf("    Threads: %d\n", cpu.threads)
    
    // Memory info
    mem := utils.system_memory_info()
    fmt.println("  Memory:")
    fmt.printf("    Total: %s\n", utils.system_format_size(mem.total))
    fmt.printf("    Used: %s (%.1f%%)\n", 
        utils.system_format_size(mem.used), mem.percent_used)
    fmt.printf("    Available: %s\n", utils.system_format_size(mem.available))
    
    // Disk info
    fmt.println("  Disk Usage:")
    disks := utils.system_disk_info()
    for disk in disks {
        fmt.printf("    %s: %s / %s (%.1f%%)\n",
            disk.mount_point,
            utils.system_format_size(disk.used),
            utils.system_format_size(disk.total),
            disk.percent_used)
    }
    
    // Network info
    fmt.println("  Network Interfaces:")
    interfaces := utils.system_network_info()
    for iface in interfaces {
        status := ""
        if !iface.is_up {
            status = " (down)"
        }
        fmt.printf("    %s: %s%s\n", iface.name, iface.ip_address, status)
    }
    
    // Battery info
    battery := utils.system_battery_info()
    if battery.is_present {
        fmt.println("  Battery:")
        fmt.printf("    Level: %.0f%%\n", battery.percent)
        fmt.printf("    Status: %s\n", if battery.is_charging then "Charging" else "Discharging")
    } else {
        fmt.println("  Battery: Not present")
    }
    
    // Environment
    fmt.println("  Environment:")
    fmt.printf("    User: %s\n", utils.system_user())
    fmt.printf("    Home: %s\n", utils.system_home_dir())
    fmt.printf("    Locale: %s\n", utils.system_locale())
    fmt.printf("    Timezone: %s\n", utils.system_timezone())
    
    // System summary
    fmt.println("\n  System Summary:")
    fmt.println(utils.system_summary())
    
    // =========================================================================
    // Application Helper Example
    // =========================================================================
    fmt.println("\n=== Application Helper Example ===")
    
    app := utils.app_create("ExampleApp", "1.0.0")
    defer utils.app_destroy(app)
    
    fmt.printf("  App: %s v%s\n", app.config.name, app.config.version)
    fmt.printf("  Runtime: %v\n", utils.app_runtime(app))
    
    // Use settings
    utils.settings_set_string(app.settings, "theme", "dark")
    theme := utils.settings_get_string(app.settings, "theme", "light")
    fmt.printf("  Theme setting: %s\n", theme)
    
    // =========================================================================
    // Summary
    // =========================================================================
    fmt.println("\n===========================================")
    fmt.println("  Example Complete!")
    fmt.println("===========================================")
}
