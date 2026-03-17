// File System Utilities for Desktop Applications
package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:bufio"
import "core:unicode/utf8"

// ============================================================================
// Path Utilities
// ============================================================================

// Get the directory separator for the current OS
path_separator :: proc() -> rune {
    return os.PATH_SEPARATOR
}

// Join multiple path segments
path_join :: proc(segments : ..string) -> string {
    if len(segments) == 0 {
        return ""
    }
    
    result := segments[0]
    for i in 1..<len(segments) {
        segment := segments[i]
        if segment == "" {
            continue
        }
        
        // Add separator if needed
        if len(result) > 0 && result[len(result)-1] != os.PATH_SEPARATOR {
            if segment[0] != os.PATH_SEPARATOR {
                result = strings.join(result, string(os.PATH_SEPARATOR), segment)
            } else {
                result = strings.join(result, segment)
            }
        } else {
            result = strings.join(result, segment)
        }
    }
    
    return result
}

// Get absolute path from relative path
path_absolute :: proc(path : string) -> string {
    return os.abs_path(path)
}

// Get directory name from path
path_directory :: proc(path : string) -> string {
    result, _ := os.split_path(path)
    return result
}

// Get file name from path
path_filename :: proc(path : string) -> string {
    _, filename := os.split_path(path)
    return filename
}

// Get file extension
path_extension :: proc(path : string) -> string {
    _, filename := os.split_path(path)
    if index := strings.last_index_byte(filename, '.'); index >= 0 {
        return filename[index:]
    }
    return ""
}

// Get file name without extension
path_filename_no_ext :: proc(path : string) -> string {
    _, filename := os.split_path(path)
    if index := strings.last_index_byte(filename, '.'); index >= 0 {
        return filename[:index]
    }
    return filename
}

// Check if path is absolute
path_is_absolute :: proc(path : string) -> bool {
    return os.is_abs(path)
}

// Normalize path (resolve . and ..)
path_normalize :: proc(path : string) -> string {
    return os.norm_path(path)
}

// Get home directory
path_home :: proc() -> string {
    return os.home_dir()
}

// Get current working directory
path_current_dir :: proc() -> string {
    return os.getwd()
}

// Get temp directory
path_temp_dir :: proc() -> string {
    return os.temp_dir()
}

// Get executable directory
path_executable_dir :: proc() -> string {
    return os.executable_dir()
}

// ============================================================================
// File Operations
// ============================================================================

// Read entire file as string
file_read :: proc(path : string) -> (string, bool) {
    f, ok := os.open(path, os.O_RDONLY)
    if !ok {
        return "", false
    }
    defer os.close(f)
    
    info, ok := os.stat(f)
    if !ok {
        return "", false
    }
    
    buffer := make([]u8, info.size)
    n, ok := os.read(f, buffer)
    if !ok {
        return "", false
    }
    
    return string(buffer[:n]), true
}

// Read entire file as bytes
file_read_bytes :: proc(path : string) -> ([]u8, bool) {
    f, ok := os.open(path, os.O_RDONLY)
    if !ok {
        return nil, false
    }
    defer os.close(f)
    
    info, ok := os.stat(f)
    if !ok {
        return nil, false
    }
    
    buffer := make([]u8, info.size)
    n, ok := os.read(f, buffer)
    if !ok {
        return nil, false
    }
    
    return buffer[:n], true
}

// Write string to file
file_write :: proc(path : string, content : string) -> bool {
    f, ok := os.open(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC)
    if !ok {
        return false
    }
    defer os.close(f)
    
    n, ok := os.write(f, cast([]u8)content)
    return ok && n == len(content)
}

// Write bytes to file
file_write_bytes :: proc(path : string, data : []u8) -> bool {
    f, ok := os.open(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC)
    if !ok {
        return false
    }
    defer os.close(f)
    
    n, ok := os.write(f, data)
    return ok && n == len(data)
}

// Append string to file
file_append :: proc(path : string, content : string) -> bool {
    f, ok := os.open(path, os.O_WRONLY|os.O_CREATE|os.O_APPEND)
    if !ok {
        return false
    }
    defer os.close(f)
    
    n, ok := os.write(f, cast([]u8)content)
    return ok && n == len(content)
}

// Check if file exists
file_exists :: proc(path : string) -> bool {
    _, ok := os.stat(path)
    return ok
}

// Delete file
file_delete :: proc(path : string) -> bool {
    return os.remove(path)
}

// Copy file
file_copy :: proc(src : string, dst : string) -> bool {
    data, ok := file_read_bytes(src)
    if !ok {
        return false
    }
    return file_write_bytes(dst, data)
}

// Move/rename file
file_move :: proc(src : string, dst : string) -> bool {
    return os.rename(src, dst)
}

// Get file size
file_size :: proc(path : string) -> i64 {
    f, ok := os.open(path, os.O_RDONLY)
    if !ok {
        return -1
    }
    defer os.close(f)
    
    info, ok := os.stat(f)
    if !ok {
        return -1
    }
    
    return info.size
}

// Get file modification time
file_modified_time :: proc(path : string) -> os.File_Time {
    f, ok := os.open(path, os.O_RDONLY)
    if !ok {
        return os.File_Time{seconds: 0}
    }
    defer os.close(f)
    
    info, ok := os.stat(f)
    if !ok {
        return os.File_Time{seconds: 0}
    }
    
    return info.modified
}

// ============================================================================
// Directory Operations
// ============================================================================

// Create directory (and parents if needed)
dir_create :: proc(path : string) -> bool {
    return os.mkdir(path)
}

// Create directory with all parent directories
dir_create_recursive :: proc(path : string) -> bool {
    // Try to create directly first
    if os.mkdir(path) {
        return true
    }
    
    // Split path and create each level
    parts := strings.split(path, string(os.PATH_SEPARATOR))
    current := ""
    
    for part in parts {
        if part == "" {
            continue
        }
        
        if current == "" {
            current = string(os.PATH_SEPARATOR) + part
        } else {
            current = current + string(os.PATH_SEPARATOR) + part
        }
        
        if !os.mkdir(current) {
            // Directory might already exist, continue
            if _, ok := os.stat(current); !ok {
                return false
            }
        }
    }
    
    return true
}

// Check if directory exists
dir_exists :: proc(path : string) -> bool {
    f, ok := os.stat(path)
    if !ok {
        return false
    }
    return f.is_dir
}

// Delete empty directory
dir_delete :: proc(path : string) -> bool {
    return os.rmdir(path)
}

// Delete directory recursively
dir_delete_recursive :: proc(path : string) -> bool {
    entries, ok := dir_list(path)
    if !ok {
        return false
    }
    
    for entry in entries {
        full_path := path_join(path, entry.name)
        if entry.is_dir {
            if !dir_delete_recursive(full_path) {
                return false
            }
        } else {
            if !file_delete(full_path) {
                return false
            }
        }
    }
    
    return os.rmdir(path)
}

// List directory contents
Dir_Entry :: struct {
    name : string,
    is_dir : bool,
    size : i64,
}

dir_list :: proc(path : string) -> ([]Dir_Entry, bool) {
    dir, ok := os.open_dir(path)
    if !ok {
        return nil, false
    }
    defer os.close_dir(dir)
    
    entries := make([]Dir_Entry, 0)
    
    for {
        info, ok := os.read_dir_entry(dir)
        if !ok {
            break
        }
        
        entry := Dir_Entry{
            name = info.name,
            is_dir = info.is_dir,
            size = info.size,
        }
        append(&entries, entry)
    }
    
    return entries, true
}

// Get current working directory
dir_current :: proc() -> string {
    return os.getwd()
}

// Change current working directory
dir_set_current :: proc(path : string) -> bool {
    return os.chdir(path)
}

// ============================================================================
// File Watcher (Simplified - Platform-specific implementation needed)
// ============================================================================

File_Watch_Event :: enum { Created, Modified, Deleted, Renamed }

File_Watch_Callback :: proc "c" (path : string, event : File_Watch_Event)

File_Watcher :: struct {
    paths : []string,
    callback : File_Watch_Callback,
    is_watching : bool,
}

// Create file watcher
watcher_create :: proc() -> ^File_Watcher {
    watcher := new(File_Watcher)
    watcher.paths = make([]string, 0)
    watcher.is_watching = false
    return watcher
}

// Add path to watch
watcher_add :: proc(watcher : ^File_Watcher, path : string) {
    append(&watcher.paths, path)
}

// Remove path from watch
watcher_remove :: proc(watcher : ^File_Watcher, path : string) {
    for i, p in watcher.paths {
        if p == path {
            watcher.paths = remove(watcher.paths, i)
            break
        }
    }
}

// Set callback for watch events
watcher_set_callback :: proc(watcher : ^File_Watcher, callback : File_Watch_Callback) {
    watcher.callback = callback
}

// Start watching (placeholder - requires platform-specific implementation)
watcher_start :: proc(watcher : ^File_Watcher) {
    watcher.is_watching = true
    // TODO: Implement platform-specific file watching
    // - Linux: inotify
    // - Windows: ReadDirectoryChangesW
    // - macOS: FSEvents
}

// Stop watching
watcher_stop :: proc(watcher : ^File_Watcher) {
    watcher.is_watching = false
}

// Destroy watcher
watcher_destroy :: proc(watcher : ^File_Watcher) {
    watcher_stop(watcher)
    delete(watcher)
}

// ============================================================================
// File Type Detection
// ============================================================================

// Get MIME type based on extension
file_mime_type :: proc(path : string) -> string {
    ext := strings.to_lower(path_extension(path))
    
    switch ext {
    case ".txt": return "text/plain"
    case ".html", ".htm": return "text/html"
    case ".css": return "text/css"
    case ".js": return "application/javascript"
    case ".json": return "application/json"
    case ".xml": return "application/xml"
    case ".pdf": return "application/pdf"
    case ".png": return "image/png"
    case ".jpg", ".jpeg": return "image/jpeg"
    case ".gif": return "image/gif"
    case ".svg": return "image/svg+xml"
    case ".ico": return "image/x-icon"
    case ".webp": return "image/webp"
    case ".mp3": return "audio/mpeg"
    case ".wav": return "audio/wav"
    case ".mp4": return "video/mp4"
    case ".webm": return "video/webm"
    case ".zip": return "application/zip"
    case ".tar": return "application/x-tar"
    case ".gz": return "application/gzip"
    case ".exe": return "application/x-executable"
    case ".dll", ".so", ".dylib": return "application/x-sharedlib"
    case ".odin": return "text/x-odin"
    case ".go": return "text/x-go"
    case ".c", ".h": return "text/x-c"
    case ".cpp", ".hpp": return "text/x-c++"
    case ".rs": return "text/x-rust"
    case ".py": return "text/x-python"
    case ".java": return "text/x-java"
    case ".ts", ".tsx": return "text/x-typescript"
    case ".md": return "text/markdown"
    case ".csv": return "text/csv"
    default: return "application/octet-stream"
    }
}

// Check if file is text file
file_is_text :: proc(path : string) -> bool {
    mime := file_mime_type(path)
    return strings.has_prefix(mime, "text/") || 
           strings.has_prefix(mime, "application/json") ||
           strings.has_prefix(mime, "application/xml")
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Ensure directory exists, create if needed
dir_ensure :: proc(path : string) -> bool {
    if dir_exists(path) {
        return true
    }
    return dir_create_recursive(path)
}

// Get unique filename (add number suffix if exists)
file_unique_name :: proc(base_path : string) -> string {
    dir, filename := os.split_path(base_path)
    name, ext := "", ""
    
    if index := strings.last_index_byte(filename, '.'); index >= 0 {
        name = filename[:index]
        ext = filename[index:]
    } else {
        name = filename
        ext = ""
    }
    
    if !file_exists(base_path) {
        return base_path
    }
    
    counter := 1
    for {
        new_filename := fmt.Sprintf("%s_%d%s", name, counter, ext)
        new_path := path_join(dir, new_filename)
        if !file_exists(new_path) {
            return new_path
        }
        counter += 1
    }
}

// Read lines from file
file_read_lines :: proc(path : string) -> ([]string, bool) {
    content, ok := file_read(path)
    if !ok {
        return nil, false
    }
    
    lines := strings.split_lines(content)
    return lines, true
}

// Write lines to file
file_write_lines :: proc(path : string, lines : []string) -> bool {
    content := strings.join_all(lines, "\n")
    return file_write(path, content)
}
