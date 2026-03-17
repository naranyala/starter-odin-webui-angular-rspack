// Process Utilities for Desktop Applications
// Process spawning, monitoring, and IPC
package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:sync"
import "core:hash_map"

// ============================================================================
// Process Types
// ============================================================================

Process_State :: enum {
    Created,
    Running,
    Exited,
    Killed,
    Error,
}

Process_Priority :: enum {
    Idle,
    Below_Normal,
    Normal,
    AboveNormal,
    High,
    Realtime,
}

Process_Result :: struct {
    exit_code : i32,
    output : string,
    error_output : string,
    duration : time.Duration,
    state : Process_State,
}

Process_Info :: struct {
    pid : int,
    name : string,
    path : string,
    arguments : []string,
    state : Process_State,
    start_time : time.Time,
    cpu_time : time.Duration,
    memory_usage : i64,
}

// ============================================================================
// Process Handle
// ============================================================================

Process :: struct {
    pid : int,
    handle : rawptr,
    state : Process_State,
    name : string,
    path : string,
    arguments : []string,
    working_dir : string,
    environment : map[string]string,
    stdin_pipe : rawptr,
    stdout_pipe : rawptr,
    stderr_pipe : rawptr,
    output_buffer : []u8,
    error_buffer : []u8,
    start_time : time.Time,
    exit_code : i32,
    mutex : sync.Mutex,
}

// Create process
process_create :: proc() -> ^Process {
    proc := new(Process)
    proc.pid = -1
    proc.state = Process_State.Created
    proc.environment = make(map[string]string)
    proc.output_buffer = make([]u8, 0)
    proc.error_buffer = make([]u8, 0)
    return proc
}

// Set process name
process_set_name :: proc(proc : ^Process, name : string) {
    proc.name = name
}

// Set process path
process_set_path :: proc(proc : ^Process, path : string) {
    proc.path = path
}

// Add argument
process_add_arg :: proc(proc : ^Process, arg : string) {
    append(&proc.arguments, arg)
}

// Add arguments
process_add_args :: proc(proc : ^Process, args : ..string) {
    for arg in args {
        append(&proc.arguments, arg)
    }
}

// Set working directory
process_set_working_dir :: proc(proc : ^Process, dir : string) {
    proc.working_dir = dir
}

// Set environment variable
process_set_env :: proc(proc : ^Process, key : string, value : string) {
    proc.environment[key] = value
}

// Build command line
process_build_command :: proc(proc : ^Process) -> string {
    cmd := proc.path
    for arg in proc.arguments {
        cmd += " " + arg
    }
    return cmd
}

// Start process
process_start :: proc(proc : ^Process) -> bool {
    if proc.path == "" {
        proc.state = Process_State.Error
        return false
    }
    
    cmd := process_build_command(proc)
    
    #if ODIN_OS == .Linux || ODIN_OS == .Darwin
        // POSIX implementation
        proc.state = Process_State.Running
        proc.start_time = time.now()
        
        // Use os.run_command for simple cases
        // For full async support, would need fork/exec
        result := os.run_command(cmd)
        
        proc.exit_code = i32(result.exit_code)
        proc.output_buffer = cast([]u8) result.output
        proc.state = Process_State.Exited
        
        return result.exit_code == 0
        
    #elseif ODIN_OS == .Windows
        // Windows implementation would use CreateProcess
        proc.state = Process_State.Running
        proc.start_time = time.now()
        
        result := os.run_command(cmd)
        
        proc.exit_code = i32(result.exit_code)
        proc.output_buffer = cast([]u8) result.output
        proc.state = Process_State.Exited
        
        return result.exit_code == 0
    #end
}

// Wait for process to complete
process_wait :: proc(proc : ^Process, timeout : time.Duration = 0) -> bool {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    
    if proc.state == Process_State.Exited || proc.state == Process_State.Killed {
        return true
    }
    
    if proc.state != Process_State.Running {
        return false
    }
    
    // For now, just check state
    // Full implementation would use waitpid or WaitForSingleObject
    return true
}

// Kill process
process_kill :: proc(proc : ^Process) -> bool {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    
    if proc.state != Process_State.Running {
        return false
    }
    
    #if ODIN_OS == .Linux || ODIN_OS == .Darwin
        // Send SIGTERM
        cmd := fmt.Sprintf("kill %d", proc.pid)
        result := os.run_command(cmd)
        if result.exit_code == 0 {
            proc.state = Process_State.Killed
            return true
        }
    #elseif ODIN_OS == .Windows
        // Use taskkill
        cmd := fmt.Sprintf("taskkill /PID %d", proc.pid)
        result := os.run_command(cmd)
        if result.exit_code == 0 {
            proc.state = Process_State.Killed
            return true
        }
    #end
    
    return false
}

// Force kill process
process_kill_force :: proc(proc : ^Process) -> bool {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    
    if proc.state != Process_State.Running {
        return false
    }
    
    #if ODIN_OS == .Linux || ODIN_OS == .Darwin
        // Send SIGKILL
        cmd := fmt.Sprintf("kill -9 %d", proc.pid)
        result := os.run_command(cmd)
        if result.exit_code == 0 {
            proc.state = Process_State.Killed
            return true
        }
    #elseif ODIN_OS == .Windows
        // Use taskkill /F
        cmd := fmt.Sprintf("taskkill /F /PID %d", proc.pid)
        result := os.run_command(cmd)
        if result.exit_code == 0 {
            proc.state = Process_State.Killed
            return true
        }
    #end
    
    return false
}

// Get process output
process_get_output :: proc(proc : ^Process) -> string {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    return string(proc.output_buffer)
}

// Get process error output
process_get_error :: proc(proc : ^Process) -> string {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    return string(proc.error_buffer)
}

// Get exit code
process_get_exit_code :: proc(proc : ^Process) -> i32 {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    return proc.exit_code
}

// Get process state
process_get_state :: proc(proc : ^Process) -> Process_State {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    return proc.state
}

// Get process duration
process_get_duration :: proc(proc : ^Process) -> time.Duration {
    sync.lock(&proc.mutex)
    defer sync.unlock(&proc.mutex)
    
    if proc.start_time.seconds == 0 {
        return 0
    }
    
    end_time := time.now()
    if proc.state == Process_State.Exited || proc.state == Process_State.Killed {
        // Use exit time (simplified)
        end_time = proc.start_time
    }
    
    return end_time - proc.start_time
}

// Destroy process
process_destroy :: proc(proc : ^Process) {
    if proc.state == Process_State.Running {
        process_kill(proc)
    }
    delete(proc)
}

// ============================================================================
// Process Manager
// ============================================================================

Process_Manager :: struct {
    processes : hash_map.HashMap(int, ^Process),
    mutex : sync.Mutex,
}

process_manager : Process_Manager

// Initialize process manager
process_mgr_init :: proc() {
    process_manager.processes = hash_map.create_hash_map(int, ^Process, 32)
}

// Register process
process_mgr_register :: proc(proc : ^Process) -> int {
    sync.lock(&process_manager.mutex)
    defer sync.unlock(&process_manager.mutex)
    
    pid := proc.pid
    if pid <= 0 {
        pid = len(process_manager.processes) + 1
        proc.pid = pid
    }
    
    hash_map.put(&process_manager.processes, pid, proc)
    return pid
}

// Unregister process
process_mgr_unregister :: proc(pid : int) {
    sync.lock(&process_manager.mutex)
    defer sync.unlock(&process_manager.mutex)
    
    _ = hash_map.remove(&process_manager.processes, pid)
}

// Get process by PID
process_mgr_get :: proc(pid : int) -> ^Process {
    sync.lock(&process_manager.mutex)
    defer sync.unlock(&process_manager.mutex)
    
    proc, ok := hash_map.get(&process_manager.processes, pid)
    if ok {
        return proc
    }
    return nil
}

// Get all processes
process_mgr_get_all :: proc() -> []^Process {
    sync.lock(&process_manager.mutex)
    defer sync.unlock(&process_manager.mutex)
    
    procs := make([]^Process, 0)
    for _, proc in process_manager.processes {
        append(&procs, proc)
    }
    return procs
}

// Kill all processes
process_mgr_kill_all :: proc() {
    sync.lock(&process_manager.mutex)
    defer sync.unlock(&process_manager.mutex)
    
    for _, proc in process_manager.processes {
        process_kill(proc)
    }
}

// Cleanup exited processes
process_mgr_cleanup :: proc() {
    sync.lock(&process_manager.mutex)
    defer sync.unlock(&process_manager.mutex)
    
    to_remove := make([]int, 0)
    for pid, proc in process_manager.processes {
        if proc.state == Process_State.Exited || proc.state == Process_State.Killed {
            append(&to_remove, pid)
        }
    }
    
    for pid in to_remove {
        _ = hash_map.remove(&process_manager.processes, pid)
    }
}

// ============================================================================
// Process Execution (Synchronous)
// ============================================================================

// Execute command and wait for result
process_execute :: proc(command : string, args : ..string) -> Process_Result {
    start_time := time.now()
    
    // Build full command
    full_cmd := command
    for arg in args {
        full_cmd += " " + arg
    }
    
    // Execute
    result := os.run_command(full_cmd)
    
    end_time := time.now()
    
    state := Process_State.Exited
    if result.exit_code != 0 {
        state = Process_State.Error
    }
    
    return Process_Result{
        exit_code: i32(result.exit_code),
        output: result.output,
        error_output: result.error,
        duration: end_time - start_time,
        state: state,
    }
}

// Execute command with shell
process_execute_shell :: proc(shell_command : string) -> Process_Result {
    start_time := time.now()
    
    #if ODIN_OS == .Windows
        result := os.run_command(fmt.Sprintf("cmd /c \"%s\"", shell_command))
    #else
        result := os.run_command(fmt.Sprintf("sh -c \"%s\"", shell_command))
    #end
    
    end_time := time.now()
    
    state := Process_State.Exited
    if result.exit_code != 0 {
        state = Process_State.Error
    }
    
    return Process_Result{
        exit_code: i32(result.exit_code),
        output: result.output,
        error_output: result.error,
        duration: end_time - start_time,
        state: state,
    }
}

// ============================================================================
// Process Information
// ============================================================================

// Get current process ID
process_current_pid :: proc() -> int {
    return os.getpid()
}

// Get current process name
process_current_name :: proc() -> string {
    // Get executable path and extract name
    exe_path := os.executable_path()
    _, name := os.split_path(exe_path)
    return name
}

// Get process info by PID
process_get_info :: proc(pid : int) -> (Process_Info, bool) {
    #if ODIN_OS == .Linux
        // Read from /proc
        stat_path := fmt.Sprintf("/proc/%d/stat", pid)
        content, ok := file_read(stat_path)
        if !ok {
            return Process_Info{}, false
        }
        
        // Parse stat file (simplified)
        info := Process_Info{
            pid: pid,
            name: "unknown",
            state: Process_State.Running,
        }
        
        // Extract name from between parentheses
        if start := strings.index_byte(content, '('); start >= 0 {
            if end := strings.last_index_byte(content, ')'); end > start {
                info.name = content[start+1 : end]
            }
        }
        
        return info, true
        
    #elseif ODIN_OS == .Windows
        // Would use Windows API
        return Process_Info{pid: pid}, false
        
    #elseif ODIN_OS == .Darwin
        // Use sysctl or ps command
        cmd := fmt.Sprintf("ps -p %d -o comm=", pid)
        result := os.run_command(cmd)
        if result.exit_code == 0 {
            return Process_Info{
                pid: pid,
                name: strings.trim_right(result.output, "\n"),
                state: Process_State.Running,
            }, true
        }
        return Process_Info{}, false
    #end
    
    return Process_Info{}, false
}

// Check if process is running
process_is_running :: proc(pid : int) -> bool {
    #if ODIN_OS == .Linux
        return file_exists(fmt.Sprintf("/proc/%d", pid))
    #elseif ODIN_OS == .Windows
        cmd := fmt.Sprintf("tasklist /FI \"PID eq %d\" /NH", pid)
        result := os.run_command(cmd)
        return strings.contains(result.output, fmt.Sprintf("%d", pid))
    #elseif ODIN_OS == .Darwin
        cmd := fmt.Sprintf("ps -p %d", pid)
        result := os.run_command(cmd)
        return result.exit_code == 0
    #end
    return false
}

// List all processes
process_list :: proc() -> []Process_Info {
    infos := make([]Process_Info, 0)
    
    #if ODIN_OS == .Linux
        // Read /proc directory
        entries, ok := dir_list("/proc")
        if !ok {
            return infos
        }
        
        for entry in entries {
            if entry.is_dir {
                pid, ok := strconv.parse_int(entry.name)
                if ok && pid > 0 {
                    if info, ok := process_get_info(pid); ok {
                        append(&infos, info)
                    }
                }
            }
        }
        
    #elseif ODIN_OS == .Windows
        // Use tasklist
        result := os.run_command("tasklist /FO CSV")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            for line in lines[1:] { // Skip header
                // Parse CSV (simplified)
                info := Process_Info{
                    pid: 0,
                    state: Process_State.Running,
                }
                append(&infos, info)
            }
        }
        
    #elseif ODIN_OS == .Darwin
        // Use ps
        result := os.run_command("ps -eo pid,comm")
        if result.exit_code == 0 {
            lines := strings.split_lines(result.output)
            for line in lines[1:] { // Skip header
                parts := strings.fields(line)
                if len(parts) >= 2 {
                    pid, ok := strconv.parse_int(parts[0])
                    if ok {
                        info := Process_Info{
                            pid: pid,
                            name: parts[1],
                            state: Process_State.Running,
                        }
                        append(&infos, info)
                    }
                }
            }
        }
    #end
    
    return infos
}

// ============================================================================
// Process Priority
// ============================================================================

// Set process priority
process_set_priority :: proc(pid : int, priority : Process_Priority) -> bool {
    #if ODIN_OS == .Linux || ODIN_OS == .Darwin
        // Use nice/renice
        nice_value := 0
        switch priority {
        case Process_Priority.Idle: nice_value = 19
        case Process_Priority.BelowNormal: nice_value = 10
        case Process_Priority.Normal: nice_value = 0
        case Process_Priority.AboveNormal: nice_value = -10
        case Process_Priority.High: nice_value = -15
        case Process_Priority.Realtime: nice_value = -20
        }
        
        cmd := fmt.Sprintf("renice %d -p %d", nice_value, pid)
        result := os.run_command(cmd)
        return result.exit_code == 0
        
    #elseif ODIN_OS == .Windows
        // Would use SetPriorityClass
        return false
    #end
    
    return false
}

// Get process priority
process_get_priority :: proc(pid : int) -> Process_Priority {
    #if ODIN_OS == .Linux || ODIN_OS == .Darwin
        cmd := fmt.Sprintf("ps -p %d -o nice=", pid)
        result := os.run_command(cmd)
        if result.exit_code == 0 {
            nice, ok := strconv.parse_int(strings.trim_space(result.output))
            if ok {
                if nice >= 15 { return Process_Priority.Idle }
                if nice >= 5 { return Process_Priority.BelowNormal }
                if nice <= -16 { return Process_Priority.Realtime }
                if nice <= -10 { return Process_Priority.High }
                if nice < 0 { return Process_Priority.AboveNormal }
                return Process_Priority.Normal
            }
        }
    #end
    
    return Process_Priority.Normal
}

// ============================================================================
// Background Process Runner
// ============================================================================

Background_Task :: struct {
    id : string,
    command : string,
    args : []string,
    process : ^Process,
    on_complete : proc "c" (^Background_Task, Process_Result),
    on_error : proc "c" (^Background_Task, string),
    user_data : rawptr,
}

Background_Runner :: struct {
    tasks : hash_map.HashMap(string, ^Background_Task),
    worker_running : bool,
    mutex : sync.Mutex,
}

background_runner : Background_Runner

// Initialize background runner
background_runner_init :: proc() {
    background_runner.tasks = hash_map.create_hash_map(string, ^Background_Task, 16)
    background_runner.worker_running = false
}

// Start background task
background_runner_start :: proc(id : string, command : string, args : ..string) -> bool {
    sync.lock(&background_runner.mutex)
    defer sync.unlock(&background_runner.mutex)
    
    // Check if task already exists
    if _, ok := hash_map.get(&background_runner.tasks, id); ok {
        return false
    }
    
    task := new(Background_Task)
    task.id = id
    task.command = command
    task.args = make([]string, 0)
    for arg in args {
        append(&task.args, arg)
    }
    
    // Create and start process
    task.process = process_create()
    process_set_path(task.process, command)
    for arg in task.args {
        process_add_arg(task.process, arg)
    }
    
    if !process_start(task.process) {
        delete(task)
        return false
    }
    
    hash_map.put(&background_runner.tasks, id, task)
    return true
}

// Check task status
background_runner_status :: proc(id : string) -> Process_State {
    sync.lock(&background_runner.mutex)
    defer sync.unlock(&background_runner.mutex)
    
    task, ok := hash_map.get(&background_runner.tasks, id)
    if !ok {
        return Process_State.Error
    }
    
    return process_get_state(task.process)
}

// Get task result
background_runner_result :: proc(id : string) -> (Process_Result, bool) {
    sync.lock(&background_runner.mutex)
    defer sync.unlock(&background_runner.mutex)
    
    task, ok := hash_map.get(&background_runner.tasks, id)
    if !ok {
        return Process_Result{}, false
    }
    
    result := Process_Result{
        exit_code: process_get_exit_code(task.process),
        output: process_get_output(task.process),
        state: process_get_state(task.process),
        duration: process_get_duration(task.process),
    }
    
    return result, true
}

// Cancel task
background_runner_cancel :: proc(id : string) -> bool {
    sync.lock(&background_runner.mutex)
    defer sync.unlock(&background_runner.mutex)
    
    task, ok := hash_map.get(&background_runner.tasks, id)
    if !ok {
        return false
    }
    
    return process_kill(task.process)
}

// Remove completed task
background_runner_remove :: proc(id : string) {
    sync.lock(&background_runner.mutex)
    defer sync.unlock(&background_runner.mutex)
    
    task, ok := hash_map.get(&background_runner.tasks, id)
    if !ok {
        return
    }
    
    process_destroy(task.process)
    delete(task)
    _ = hash_map.remove(&background_runner.tasks, id)
}

// Cleanup all completed tasks
background_runner_cleanup :: proc() {
    sync.lock(&background_runner.mutex)
    defer sync.unlock(&background_runner.mutex)
    
    to_remove := make([]string, 0)
    for id, task in background_runner.tasks {
        state := process_get_state(task.process)
        if state == Process_State.Exited || state == Process_State.Killed {
            append(&to_remove, id)
        }
    }
    
    for id in to_remove {
        background_runner_remove(id)
    }
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Run command and get output
run :: proc(command : string, args : ..string) -> (string, bool) {
    result := process_execute(command, args)
    return result.output, result.exit_code == 0
}

// Run command in shell
run_shell :: proc(shell_command : string) -> (string, bool) {
    result := process_execute_shell(shell_command)
    return result.output, result.exit_code == 0
}

// Run command and ignore output
spawn :: proc(command : string, args : ..string) -> bool {
    result := process_execute(command, args)
    return result.exit_code == 0
}

// Check if command exists
command_exists :: proc(command : string) -> bool {
    #if ODIN_OS == .Windows
        result := os.run_command(fmt.Sprintf("where %s", command))
        return result.exit_code == 0 && len(strings.trim_space(result.output)) > 0
    #else
        result := os.run_command(fmt.Sprintf("which %s", command))
        return result.exit_code == 0 && len(strings.trim_space(result.output)) > 0
    #end
}

// Get command output lines
run_lines :: proc(command : string, args : ..string) -> []string {
    output, ok := run(command, args)
    if !ok {
        return make([]string, 0)
    }
    return strings.split_lines(strings.trim_right(output, "\n"))
}
