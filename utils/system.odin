// System Information Utility for Desktop Applications
// OS detection, system resources, environment variables
package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:time"

// ============================================================================
// System Types
// ============================================================================

OS_Type :: enum {
    Unknown,
    Windows,
    Linux,
    MacOS,
    BSD,
    Android,
    iOS,
}

OS_Architecture :: enum {
    Unknown,
    X86,
    X64,
    ARM,
    ARM64,
    RISC_V,
}

CPU_Info :: struct {
    model : string,
    vendor : string,
    cores : int,
    threads : int,
    speed_mhz : f64,
    cache_l1 : i64,
    cache_l2 : i64,
    cache_l3 : i64,
    features : []string,
}

Memory_Info :: struct {
    total : i64,
    available : i64,
    used : i64,
    free : i64,
    percent_used : f64,
    swap_total : i64,
    swap_used : i64,
    swap_free : i64,
}

Disk_Info :: struct {
    device : string,
    mount_point : string,
    filesystem : string,
    total : i64,
    used : i64,
    free : i64,
    percent_used : f64,
}

Network_Info :: struct {
    name : string,
    ip_address : string,
    mac_address : string,
    is_up : bool,
    is_loopback : bool,
}

Battery_Info :: struct {
    is_present : bool,
    is_charging : bool,
    percent : f64,
    time_remaining : time.Duration,
    voltage : f64,
    energy_rate : f64,
}

System_Info :: struct {
    hostname : string,
    os_type : OS_Type,
    os_name : string,
    os_version : string,
    os_arch : OS_Architecture,
    kernel_version : string,
    uptime : time.Duration,
    boot_time : time.Time,
    cpu : CPU_Info,
    memory : Memory_Info,
    disks : []Disk_Info,
    network : []Network_Info,
    battery : Battery_Info,
    user : string,
    home_dir : string,
    locale : string,
    timezone : string,
}

// ============================================================================
// OS Detection
// ============================================================================

// Get OS type
system_os_type :: proc() -> OS_Type {
    #if ODIN_OS == .Windows
        return OS_Type.Windows
    #elseif ODIN_OS == .Linux
        return OS_Type.Linux
    #elseif ODIN_OS == .Darwin
        return OS_Type.MacOS
    #elseif ODIN_OS == .BSD
        return OS_Type.BSD
    #else
        return OS_Type.Unknown
    #end
}

// Get OS type name
system_os_type_name :: proc() -> string {
    switch system_os_type() {
    case OS_Type.Windows: return "Windows"
    case OS_Type.Linux: return "Linux"
    case OS_Type.MacOS: return "macOS"
    case OS_Type.BSD: return "BSD"
    case OS_Type.Android: return "Android"
    case OS_Type.iOS: return "iOS"
    case OS_Type.Unknown: return "Unknown"
    }
    return "Unknown"
}

// Get OS architecture
system_os_arch :: proc() -> OS_Architecture {
    #if ODIN_ARCH == .amd64
        return OS_Architecture.X64
    #elseif ODIN_ARCH == .x86
        return OS_Architecture.X86
    #elseif ODIN_ARCH == .arm64
        return OS_Architecture.ARM64
    #elseif ODIN_ARCH == .arm
        return OS_Architecture.ARM
    #elseif ODIN_ARCH == .riscv64
        return OS_Architecture.RISC_V
    #else
        return OS_Architecture.Unknown
    #end
}

// Get OS architecture name
system_os_arch_name :: proc() -> string {
    switch system_os_arch() {
    case OS_Architecture.X86: return "x86"
    case OS_Architecture.X64: return "x64"
    case OS_Architecture.ARM: return "ARM"
    case OS_Architecture.ARM64: return "ARM64"
    case OS_Architecture.RISC_V: return "RISC-V"
    case OS_Architecture.Unknown: return "Unknown"
    }
    return "Unknown"
}

// Get OS version
system_os_version :: proc() -> string {
    #if ODIN_OS == .Windows
        // Windows version from registry or ver command
        result := os.run_command("ver")
        if result.exit_code == 0 {
            return strings.trim_right(result.output, "\n")
        }
        return "Windows"
        
    #elseif ODIN_OS == .Linux
        // Try /etc/os-release
        content, ok := file_read("/etc/os-release")
        if ok {
            lines := strings.split_lines(content)
            for line in lines {
                if strings.has_prefix(line, "PRETTY_NAME=") {
                    value := strings.trim_left(line[len("PRETTY_NAME="):], "=")
                    return strings.trim(value, "\"")
                }
            }
        }
        
        // Fallback to uname
        result := os.run_command("uname -r")
        if result.exit_code == 0 {
            return "Linux " + strings.trim_right(result.output, "\n")
        }
        return "Linux"
        
    #elseif ODIN_OS == .Darwin
        result := os.run_command("sw_vers -productVersion")
        if result.exit_code == 0 {
            return "macOS " + strings.trim_right(result.output, "\n")
        }
        return "macOS"
    #end
    
    return "Unknown"
}

// ============================================================================
// CPU Information
// ============================================================================

// Get CPU info
system_cpu_info :: proc() -> CPU_Info {
    cpu := CPU_Info{}
    
    #if ODIN_OS == .Linux
        // Read /proc/cpuinfo
        content, ok := file_read("/proc/cpuinfo")
        if ok {
            lines := strings.split_lines(content)
            core_count := 0
            
            for line in lines {
                if strings.has_prefix(line, "model name") {
                    parts := strings.split(line, ":")
                    if len(parts) >= 2 {
                        cpu.model = strings.trim_left(parts[1], " \t")
                    }
                } else if strings.has_prefix(line, "vendor_id") {
                    parts := strings.split(line, ":")
                    if len(parts) >= 2 {
                        cpu.vendor = strings.trim_left(parts[1], " \t")
                    }
                } else if strings.has_prefix(line, "cpu MHz") {
                    parts := strings.split(line, ":")
                    if len(parts) >= 2 {
                        cpu.speed_mhz, _ = strconv.parse_f64(strings.trim_left(parts[1], " \t"))
                    }
                } else if strings.has_prefix(line, "processor") {
                    core_count += 1
                }
            }
            
            cpu.cores = core_count
            cpu.threads = core_count // Simplified
        }
        
        // Get cache info
        cache_l1, ok := file_read("/sys/devices/system/cpu/cpu0/cache/index0/size")
        if ok {
            cpu.cache_l1 = _parse_cache_size(cache_l1)
        }
        
    #elseif ODIN_OS == .Windows
        // Windows CPU info via wmic
        result := os.run_command("wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            if len(lines) >= 2 {
                cpu.model = strings.trim_left(lines[1], " ")
            }
        }
        
        result = os.run_command("wmic cpu get NumberOfCores")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            if len(lines) >= 2 {
                cpu.cores, _ = strconv.parse_int(strings.trim_space(lines[1]))
            }
        }
        
        result = os.run_command("wmic cpu get NumberOfLogicalProcessors")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            if len(lines) >= 2 {
                cpu.threads, _ = strconv.parse_int(strings.trim_space(lines[1]))
            }
        }
        
    #elseif ODIN_OS == .Darwin
        // macOS CPU info via sysctl
        result := os.run_command("sysctl -n machdep.cpu.brand_string")
        if result.exit_code == 0 {
            cpu.model = strings.trim_right(result.output, "\n")
        }
        
        result = os.run_command("sysctl -n hw.ncpu")
        if result.exit_code == 0 {
            cpu.threads, _ = strconv.parse_int(strings.trim_right(result.output, "\n"))
        }
        
        result = os.run_command("sysctl -n hw.physicalcpu")
        if result.exit_code == 0 {
            cpu.cores, _ = strconv.parse_int(strings.trim_right(result.output, "\n"))
        }
    #end
    
    return cpu
}

// Parse cache size string
_parse_cache_size :: proc(s : string) -> i64 {
    s = strings.trim_space(s)
    if strings.has_suffix(s, "K") {
        val, _ := strconv.parse_int(strings.trim_suffix(s, "K"))
        return val * 1024
    } else if strings.has_suffix(s, "M") {
        val, _ := strconv.parse_int(strings.trim_suffix(s, "M"))
        return val * 1024 * 1024
    } else if strings.has_suffix(s, "G") {
        val, _ := strconv.parse_int(strings.trim_suffix(s, "G"))
        return val * 1024 * 1024 * 1024
    }
    val, _ := strconv.parse_int(s)
    return val
}

// Get CPU core count
system_cpu_cores :: proc() -> int {
    cpu := system_cpu_info()
    if cpu.cores > 0 {
        return cpu.cores
    }
    
    // Fallback
    #if ODIN_OS == .Linux
        content, ok := file_read("/proc/cpuinfo")
        if ok {
            count := 0
            for line in strings.split_lines(content) {
                if strings.has_prefix(line, "processor") {
                    count += 1
                }
            }
            return count
        }
    #end
    
    return 1
}

// ============================================================================
// Memory Information
// ============================================================================

// Get memory info
system_memory_info :: proc() -> Memory_Info {
    mem := Memory_Info{}
    
    #if ODIN_OS == .Linux
        // Read /proc/meminfo
        content, ok := file_read("/proc/meminfo")
        if ok {
            lines := strings.split_lines(content)
            for line in lines {
                parts := strings.fields(line)
                if len(parts) >= 2 {
                    value, _ := strconv.parse_int(parts[1])
                    value *= 1024 // Convert from KB to bytes
                    
                    switch parts[0] {
                    case "MemTotal:": mem.total = value
                    case "MemFree:": mem.free = value
                    case "MemAvailable:": mem.available = value
                    case "SwapTotal:": mem.swap_total = value
                    case "SwapFree:": mem.swap_free = value
                    }
                }
            }
            
            mem.used = mem.total - mem.available
            if mem.total > 0 {
                mem.percent_used = f64(mem.used) / f64(mem.total) * 100
            }
            
            mem.swap_used = mem.swap_total - mem.swap_free
        }
        
    #elseif ODIN_OS == .Windows
        // Windows memory info via wmic
        result := os.run_command("wmic OS get FreePhysicalMemory,TotalVisibleMemorySize")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            if len(lines) >= 2 {
                parts := strings.fields(lines[1])
                if len(parts) >= 2 {
                    free, _ := strconv.parse_int(parts[0])
                    total, _ := strconv.parse_int(parts[1])
                    mem.free = free * 1024
                    mem.total = total * 1024
                    mem.used = mem.total - mem.free
                    mem.percent_used = f64(mem.used) / f64(mem.total) * 100
                }
            }
        }
        
    #elseif ODIN_OS == .Darwin
        // macOS memory info via sysctl
        result := os.run_command("sysctl -n hw.memsize")
        if result.exit_code == 0 {
            mem.total, _ = strconv.parse_int(strings.trim_right(result.output, "\n"))
        }
        
        // Get VM stats
        result = os.run_command("vm_stat")
        if result.exit_code == 0 {
            // Parse vm_stat output (page-based)
            lines := strings.split_lines(result.output)
            page_size := 4096 // Default page size
            
            for line in lines {
                if strings.contains(line, "free") {
                    parts := strings.split(line, ":")
                    if len(parts) >= 2 {
                        pages, _ := strconv.parse_int(strings.trim_left(parts[1], " ."))
                        mem.free = pages * page_size
                    }
                }
            }
            
            mem.used = mem.total - mem.free
            if mem.total > 0 {
                mem.percent_used = f64(mem.used) / f64(mem.total) * 100
            }
        }
    #end
    
    return mem
}

// Get memory usage percentage
system_memory_percent :: proc() -> f64 {
    mem := system_memory_info()
    return mem.percent_used
}

// ============================================================================
// Disk Information
// ============================================================================

// Get disk info for all mounts
system_disk_info :: proc() -> []Disk_Info {
    disks := make([]Disk_Info, 0)
    
    #if ODIN_OS == .Linux || ODIN_OS == .Darwin
        // Use df command
        result := os.run_command("df -k")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            
            // Skip header
            for line in lines[1:] {
                parts := strings.fields(line)
                if len(parts) >= 6 {
                    disk := Disk_Info{
                        device: parts[0],
                        total: 0,
                        used: 0,
                        free: 0,
                        mount_point: parts[5],
                    }
                    
                    total, _ := strconv.parse_int(parts[1])
                    used, _ := strconv.parse_int(parts[2])
                    free, _ := strconv.parse_int(parts[3])
                    
                    disk.total = total * 1024
                    disk.used = used * 1024
                    disk.free = free * 1024
                    
                    if disk.total > 0 {
                        disk.percent_used = f64(disk.used) / f64(disk.total) * 100
                    }
                    
                    append(&disks, disk)
                }
            }
        }
        
    #elseif ODIN_OS == .Windows
        // Windows disk info via wmic
        result := os.run_command("wmic logicaldisk get DeviceID,Size,FreeSpace,FileSystem")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            
            for line in lines[1:] {
                parts := strings.fields(line)
                if len(parts) >= 4 {
                    disk := Disk_Info{
                        device: parts[0],
                        mount_point: parts[0],
                        filesystem: parts[3],
                    }
                    
                    disk.total, _ = strconv.parse_int(parts[1])
                    disk.free, _ = strconv.parse_int(parts[2])
                    disk.used = disk.total - disk.free
                    
                    if disk.total > 0 {
                        disk.percent_used = f64(disk.used) / f64(disk.total) * 100
                    }
                    
                    append(&disks, disk)
                }
            }
        }
    #end
    
    return disks
}

// Get disk info for specific path
system_disk_info_for_path :: proc(path : string) -> (Disk_Info, bool) {
    disks := system_disk_info()
    
    for disk in disks {
        if strings.has_prefix(path, disk.mount_point) {
            return disk, true
        }
    }
    
    return Disk_Info{}, false
}

// ============================================================================
// Network Information
// ============================================================================

// Get network interfaces
system_network_info :: proc() -> []Network_Info {
    interfaces := make([]Network_Info, 0)
    
    #if ODIN_OS == .Linux
        // Get interface names
        result := os.run_command("ip -o link show | awk -F': ' '{print $2}'")
        if result.exit_code == 0 {
            names := strings.split_lines(strings.trim_right(result.output, "\n"))
            
            for name in names {
                name = strings.trim_space(name)
                if name == "" {
                    continue
                }
                
                iface := Network_Info{
                    name: name,
                    is_up: true,
                    is_loopback: name == "lo",
                }
                
                // Get IP address
                ip_result := os.run_command(fmt.Sprintf("ip -4 addr show %s | grep inet | awk '{print $2}' | cut -d/ -f1", name))
                if ip_result.exit_code == 0 && len(ip_result.output) > 0 {
                    iface.ip_address = strings.trim_right(ip_result.output, "\n")
                }
                
                // Get MAC address
                mac_result := os.run_command(fmt.Sprintf("cat /sys/class/net/%s/address", name))
                if mac_result.exit_code == 0 && len(mac_result.output) > 0 {
                    iface.mac_address = strings.trim_right(mac_result.output, "\n")
                }
                
                append(&interfaces, iface)
            }
        }
        
    #elseif ODIN_OS == .Windows
        // Windows network info via ipconfig
        result := os.run_command("ipconfig /all")
        if result.exit_code == 0 {
            // Parse ipconfig output (simplified)
            iface := Network_Info{
                name: "Ethernet",
                is_up: true,
            }
            
            // Get IP
            ip_result := os.run_command("ipconfig | findstr IPv4")
            if ip_result.exit_code == 0 {
                parts := strings.split(ip_result.output, ":")
                if len(parts) >= 2 {
                    iface.ip_address = strings.trim_left(parts[1], " ")
                }
            }
            
            append(&interfaces, iface)
        }
        
    #elseif ODIN_OS == .Darwin
        // macOS network info via ifconfig
        result := os.run_command("ifconfig -l")
        if result.exit_code == 0 {
            names := strings.fields(result.output)
            
            for name in names {
                iface := Network_Info{
                    name: name,
                    is_up: true,
                    is_loopback: name == "lo0",
                }
                
                // Get IP
                ip_result := os.run_command(fmt.Sprintf("ipconfig getifaddr %s", name))
                if ip_result.exit_code == 0 && len(ip_result.output) > 0 {
                    iface.ip_address = strings.trim_right(ip_result.output, "\n")
                }
                
                append(&interfaces, iface)
            }
        }
    #end
    
    return interfaces
}

// ============================================================================
// Battery Information
// ============================================================================

// Get battery info
system_battery_info :: proc() -> Battery_Info {
    battery := Battery_Info{}
    
    #if ODIN_OS == .Linux
        // Read from /sys/class/power_supply
        battery_path := "/sys/class/power_supply/BAT0"
        
        if file_exists(battery_path + "/present") {
            content, ok := file_read(battery_path + "/present")
            if ok && strings.trim_space(content) == "1" {
                battery.is_present = true
            }
        }
        
        if battery.is_present {
            // Status
            content, ok := file_read(battery_path + "/status")
            if ok {
                battery.is_charging = strings.contains(strings.to_lower(content), "charging")
            }
            
            // Capacity
            content, ok = file_read(battery_path + "/capacity")
            if ok {
                battery.percent, _ = strconv.parse_f64(strings.trim_space(content))
            }
            
            // Time remaining
            content, ok = file_read(battery_path + "/time_to_empty_now")
            if ok {
                seconds, _ := strconv.parse_int(strings.trim_space(content))
                battery.time_remaining = time.Duration(seconds) * time.Second
            }
        }
        
    #elseif ODIN_OS == .Darwin
        // macOS battery info via pmset
        result := os.run_command("pmset -g batt")
        if result.exit_code == 0 {
            output := result.output
            
            if strings.contains(output, "No") {
                battery.is_present = false
            } else {
                battery.is_present = true
                battery.is_charging = strings.contains(output, "charging")
                
                // Parse percentage
                if index := strings.index_byte(output, '%'); index >= 0 {
                    // Find start of number
                    start := index - 1
                    for start >= 0 && output[start] >= '0' && output[start] <= '9' {
                        start -= 1
                    }
                    start += 1
                    
                    pct_str := output[start:index]
                    battery.percent, _ = strconv.parse_f64(pct_str)
                }
            }
        }
        
    #elseif ODIN_OS == .Windows
        // Windows battery info via powercfg
        result := os.run_command("powercfg /batteryreport")
        if result.exit_code == 0 {
            battery.is_present = true
            // Would need to parse HTML report for detailed info
        }
    #end
    
    return battery
}

// ============================================================================
// System Information
// ============================================================================

// Get hostname
system_hostname :: proc() -> string {
    return os.hostname()
}

// Get uptime
system_uptime :: proc() -> time.Duration {
    #if ODIN_OS == .Linux
        content, ok := file_read("/proc/uptime")
        if ok {
            parts := strings.fields(content)
            if len(parts) >= 1 {
                seconds, _ := strconv.parse_f64(parts[0])
                return time.Duration(seconds) * time.Second
            }
        }
    #elseif ODIN_OS == .Darwin
        result := os.run_command("sysctl -n kern.boottime")
        if result.exit_code == 0 {
            // Parse boot time
            // Simplified
        }
    #end
    
    return 0
}

// Get current user
system_user :: proc() -> string {
    user := os.getenv("USER")
    if user == "" {
        user = os.getenv("USERNAME") // Windows
    }
    return user
}

// Get locale
system_locale :: proc() -> string {
    locale := os.getenv("LANG")
    if locale == "" {
        locale = os.getenv("LC_ALL")
    }
    if locale == "" {
        locale = "en_US.UTF-8"
    }
    return locale
}

// Get timezone
system_timezone :: proc() -> string {
    #if ODIN_OS == .Linux
        // Read /etc/timezone or symlink
        content, ok := file_read("/etc/timezone")
        if ok {
            return strings.trim_right(content, "\n")
        }
        
        // Try symlink
        link, ok := os.readlink("/etc/localtime")
        if ok {
            // Extract timezone from path
            if index := strings.last_index(link, "/zoneinfo/"); index >= 0 {
                return link[index+len("/zoneinfo/"):]
            }
        }
    #end
    
    return "UTC"
}

// Get full system info
system_info :: proc() -> System_Info {
    info := System_Info{}
    
    info.hostname = system_hostname()
    info.os_type = system_os_type()
    info.os_name = system_os_type_name()
    info.os_version = system_os_version()
    info.os_arch = system_os_arch()
    info.cpu = system_cpu_info()
    info.memory = system_memory_info()
    info.disks = system_disk_info()
    info.network = system_network_info()
    info.battery = system_battery_info()
    info.user = system_user()
    info.home_dir = os.home_dir()
    info.locale = system_locale()
    info.timezone = system_timezone()
    info.uptime = system_uptime()
    
    return info
}

// ============================================================================
// Environment Variables
// ============================================================================

// Get environment variable
system_env :: proc(name : string) -> string {
    return os.getenv(name)
}

// Set environment variable
system_set_env :: proc(name : string, value : string) -> bool {
    return os.setenv(name, value)
}

// Get all environment variables
system_env_all :: proc() -> map[string]string {
    env := make(map[string]string)
    
    #if ODIN_OS == .Linux || ODIN_OS == .Darwin
        result := os.run_command("env")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            for line in lines {
                if index := strings.index_byte(line, '='); index >= 0 {
                    key := line[:index]
                    value := line[index+1:]
                    env[key] = value
                }
            }
        }
    #elseif ODIN_OS == .Windows
        result := os.run_command("set")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            for line in lines {
                if index := strings.index_byte(line, '='); index >= 0 {
                    key := line[:index]
                    value := line[index+1:]
                    env[key] = value
                }
            }
        }
    #end
    
    return env
}

// Check if environment variable exists
system_env_exists :: proc(name : string) -> bool {
    val := os.getenv(name)
    return val != ""
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Get human-readable size
system_format_size :: proc(bytes : i64) -> string {
    if bytes < 1024 {
        return fmt.Sprintf("%d B", bytes)
    } else if bytes < 1024 * 1024 {
        return fmt.Sprintf("%.2f KB", f64(bytes) / 1024)
    } else if bytes < 1024 * 1024 * 1024 {
        return fmt.Sprintf("%.2f MB", f64(bytes) / (1024 * 1024))
    } else if bytes < 1024 * 1024 * 1024 * 1024 {
        return fmt.Sprintf("%.2f GB", f64(bytes) / (1024 * 1024 * 1024))
    } else {
        return fmt.Sprintf("%.2f TB", f64(bytes) / (1024 * 1024 * 1024 * 1024))
    }
}

// Get system summary
system_summary :: proc() -> string {
    info := system_info()
    
    return fmt.Sprintf(
        "%s %s (%s)\nCPU: %s (%d cores)\nMemory: %s / %s (%.1f%%)\nUser: %s@%s",
        info.os_name,
        info.os_version,
        info.os_arch_name(),
        info.cpu.model,
        info.cpu.cores,
        system_format_size(info.memory.used),
        system_format_size(info.memory.total),
        info.memory.percent_used,
        info.user,
        info.hostname,
    )
}

// Check if running on battery
system_on_battery :: proc() -> bool {
    battery := system_battery_info()
    return battery.is_present && !battery.is_charging
}

// Check if system is low on memory
system_low_memory :: proc(threshold_percent : f64 = 90.0) -> bool {
    return system_memory_percent() > threshold_percent
}

// Check if system is low on disk space
system_low_disk :: proc(path : string, threshold_percent : f64 = 90.0) -> bool {
    disk, ok := system_disk_info_for_path(path)
    if !ok {
        return false
    }
    return disk.percent_used > threshold_percent
}
