// Clipboard Manager for Desktop Applications
package utils

import "core:fmt"
import "core:c"
import "core:os"
import "core:strings"

// ============================================================================
// Clipboard Format
// ============================================================================

Clipboard_Format :: enum {
    Text,
    HTML,
    RTF,
    Image,
    Files,
    Binary,
}

// ============================================================================
// Linux X11 Implementation
// ============================================================================

// X11 types
X11_Display : opaque
X11_Window : distinct c.uint
X11_Atom : distinct c.ulong
X11_Time : distinct c.ulong

// X11 constants
X11_SELECTION_CLIPBOARD : X11_Atom = 70
X11_SELECTION_PRIMARY : X11_Atom = 9
X11_ATOM_STRING : X11_Atom = 31
X11_ATOM_UTF8_STRING : X11_Atom = 313 // Typical value
X11_PropertyNotify : c.int = 28
X11_SelectionRequest : c.int = 30
X11_SelectionNotify : c.int = 31
X11_CurrentTime : X11_Time = 0

// X11 function types
X11_Open_Display_Proc :: proc "c" (display_name : cstring) -> ^X11_Display
X11_Close_Display_Proc :: proc "c" (^X11_Display) -> c.int
X11_Get_Selection_Owner_Proc :: proc "c" (^X11_Display, X11_Atom) -> X11_Window
X11_Set_Selection_Owner_Proc :: proc "c" (^X11_Display, X11_Window, X11_Atom, X11_Time) -> c.int
X11_Convert_Selection_Proc :: proc "c" (^X11_Display, X11_Window, X11_Atom, X11_Atom, X11_Time) -> c.int
X11_Delete_Property_Proc :: proc "c" (^X11_Display, X11_Window, X11_Atom) -> c.int
X11_Next_Event_Proc :: proc "c" (^X11_Display, ^X11_Event) -> c.int
X11_Flush_Proc :: proc "c" (^X11_Display) -> c.int
X11_Window_Event :: struct {
    type : c.int,
    serial : c.ulong,
    send_event : c.int,
    display : ^X11_Display,
    window : X11_Window,
    requestor : X11_Window,
    selection : X11_Atom,
    target : X11_Atom,
    property : X11_Atom,
    time : X11_Time,
}

X11_Event :: union {
    type : c.int,
    xselection : X11_Window_Event,
    pad : [24]u8,
}

// X11 library handle
x11_lib : c.Handle
x11_open_display : X11_Open_Display_Proc
x11_close_display : X11_Close_Display_Proc
x11_get_selection_owner : X11_Get_Selection_Owner_Proc
x11_set_selection_owner : X11_Set_Selection_Owner_Proc
x11_convert_selection : X11_Convert_Selection_Proc
x11_delete_property : X11_Delete_Property_Proc
x11_next_event : X11_Next_Event_Proc
x11_flush : X11_Flush_Proc

// Clipboard data storage
clipboard_text_data : string
clipboard_has_owner : bool

// Initialize X11 clipboard
clipboard_init_x11 :: proc() -> bool {
    // Try to load X11 library
    x11_lib, ok := c.dlopen("libX11.so.6", c.RTLD_LAZY | c.RTLD_GLOBAL)
    if !ok {
        x11_lib, ok = c.dlopen("libX11.so", c.RTLD_LAZY | c.RTLD_GLOBAL)
        if !ok {
            return false
        }
    }
    
    // Load functions
    x11_open_display = cast(X11_Open_Display_Proc) c.dlsym(x11_lib, "XOpenDisplay")
    x11_close_display = cast(X11_Close_Display_Proc) c.dlsym(x11_lib, "XCloseDisplay")
    x11_get_selection_owner = cast(X11_Get_Selection_Owner_Proc) c.dlsym(x11_lib, "XGetSelectionOwner")
    x11_set_selection_owner = cast(X11_Set_Selection_Owner_Proc) c.dlsym(x11_lib, "XSetSelectionOwner")
    x11_convert_selection = cast(X11_Convert_Selection_Proc) c.dlsym(x11_lib, "XConvertSelection")
    x11_delete_property = cast(X11_Delete_Property_Proc) c.dlsym(x11_lib, "XDeleteProperty")
    x11_next_event = cast(X11_Next_Event_Proc) c.dlsym(x11_lib, "XNextEvent")
    x11_flush = cast(X11_Flush_Proc) c.dlsym(x11_lib, "XFlush")
    
    if x11_open_display == nil {
        c.dlclose(x11_lib)
        return false
    }
    
    return true
}

// Cleanup X11 clipboard
clipboard_cleanup_x11 :: proc() {
    if x11_lib != 0 {
        c.dlclose(x11_lib)
        x11_lib = 0
    }
}

// Set clipboard text (X11)
clipboard_set_text_x11 :: proc(text : string) -> bool {
    if x11_open_display == nil {
        return false
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return false
    }
    defer x11_close_display(display)
    
    // Store the text data
    clipboard_text_data = text
    clipboard_has_owner = true
    
    // Set ourselves as the selection owner
    root_window : X11_Window = 0 // Default root window
    result := x11_set_selection_owner(display, root_window, X11_SELECTION_CLIPBOARD, X11_CurrentTime)
    
    if result != 0 {
        x11_flush(display)
        return true
    }
    
    return false
}

// Get clipboard text (X11)
clipboard_get_text_x11 :: proc() -> (string, bool) {
    if x11_open_display == nil {
        return "", false
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return "", false
    }
    defer x11_close_display(display)
    
    // For now, return stored data if we own the clipboard
    if clipboard_has_owner {
        return clipboard_text_data, true
    }
    
    // TODO: Implement full X11 clipboard retrieval
    // This requires event loop integration which is complex
    
    return "", false
}

// Clear clipboard (X11)
clipboard_clear_x11 :: proc() -> bool {
    if x11_open_display == nil {
        return false
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return false
    }
    defer x11_close_display(display)
    
    // Set no owner
    result := x11_set_selection_owner(display, 0, X11_SELECTION_CLIPBOARD, X11_CurrentTime)
    clipboard_has_owner = false
    clipboard_text_data = ""
    
    return result != 0
}

// ============================================================================
// Windows Implementation
// ============================================================================

// Windows types (simplified)
HWND : distinct rawptr
HGLOBAL : distinct rawptr
HINSTANCE : distinct rawptr
BOOL : distinct c.int
DWORD : distinct c.ulong
UINT : distinct c.uint
SIZE_T : distinct c.ulong

// Windows constants
CF_TEXT : UINT = 1
CF_UNICODETEXT : UINT = 13
CF_HDROP : UINT = 15
GMEM_MOVEABLE : DWORD = 0x0002
GMEM_ZEROINIT : DWORD = 0x0040
GHND : DWORD = GMEM_MOVEABLE | GMEM_ZEROINIT

// Windows function types
Win_OpenClipboard_Proc :: proc "c" (HWND) -> BOOL
Win_CloseClipboard_Proc :: proc "c" () -> BOOL
Win_EmptyClipboard_Proc :: proc "c" () -> BOOL
Win_GetClipboardData_Proc :: proc "c" (UINT) -> HGLOBAL
Win_SetClipboardData_Proc :: proc "c" (UINT, HGLOBAL) -> HGLOBAL
Win_IsClipboardFormatAvailable_Proc :: proc "c" (UINT) -> BOOL
Win_GlobalLock_Proc :: proc "c" (HGLOBAL) -> rawptr
Win_GlobalUnlock_Proc :: proc "c" (HGLOBAL) -> BOOL
Win_GlobalSize_Proc :: proc "c" (HGLOBAL) -> SIZE_T
Win_GlobalAlloc_Proc :: proc "c" (UINT, SIZE_T) -> HGLOBAL
Win_GlobalFree_Proc :: proc "c" (HGLOBAL) -> HGLOBAL
Win_MultiByteToWideChar_Proc :: proc "c" (UINT, DWORD, cstring, c.int, ^u16, c.int) -> c.int
Win_WideCharToMultiByte_Proc :: proc "c" (UINT, DWORD, ^u16, c.int, cstring, c.int, cstring, ^c.int) -> c.int

// Windows library handle
win_lib : c.Handle
win_open_clipboard : Win_OpenClipboard_Proc
win_close_clipboard : Win_CloseClipboard_Proc
win_empty_clipboard : Win_EmptyClipboard_Proc
win_get_clipboard_data : Win_GetClipboardData_Proc
win_set_clipboard_data : Win_SetClipboardData_Proc
win_is_clipboard_format_available : Win_IsClipboardFormatAvailable_Proc
win_global_lock : Win_GlobalLock_Proc
win_global_unlock : Win_GlobalUnlock_Proc
win_global_size : Win_GlobalSize_Proc
win_global_alloc : Win_GlobalAlloc_Proc
win_global_free : Win_GlobalFree_Proc
win_mb_to_wc : Win_MultiByteToWideChar_Proc
win_wc_to_mb : Win_WideCharToMultiByte_Proc

// Initialize Windows clipboard
clipboard_init_windows :: proc() -> bool {
    win_lib, ok := c.dlopen("user32.dll", c.RTLD_LAZY)
    if !ok {
        return false
    }
    
    win_open_clipboard = cast(Win_OpenClipboard_Proc) c.dlsym(win_lib, "OpenClipboard")
    win_close_clipboard = cast(Win_CloseClipboard_Proc) c.dlsym(win_lib, "CloseClipboard")
    win_empty_clipboard = cast(Win_EmptyClipboard_Proc) c.dlsym(win_lib, "EmptyClipboard")
    win_get_clipboard_data = cast(Win_GetClipboardData_Proc) c.dlsym(win_lib, "GetClipboardData")
    win_set_clipboard_data = cast(Win_SetClipboardData_Proc) c.dlsym(win_lib, "SetClipboardData")
    win_is_clipboard_format_available = cast(Win_IsClipboardFormatAvailable_Proc) c.dlsym(win_lib, "IsClipboardFormatAvailable")
    win_global_lock = cast(Win_GlobalLock_Proc) c.dlsym(win_lib, "GlobalLock")
    win_global_unlock = cast(Win_GlobalUnlock_Proc) c.dlsym(win_lib, "GlobalUnlock")
    win_global_size = cast(Win_GlobalSize_Proc) c.dlsym(win_lib, "GlobalSize")
    win_global_alloc = cast(Win_GlobalAlloc_Proc) c.dlsym(win_lib, "GlobalAlloc")
    win_global_free = cast(Win_GlobalFree_Proc) c.dlsym(win_lib, "GlobalFree")
    
    // kernel32 for memory functions
    kernel_lib, ok := c.dlopen("kernel32.dll", c.RTLD_LAZY)
    if ok {
        win_mb_to_wc = cast(Win_MultiByteToWideChar_Proc) c.dlsym(kernel_lib, "MultiByteToWideChar")
        win_wc_to_mb = cast(Win_WideCharToMultiByte_Proc) c.dlsym(kernel_lib, "WideCharToMultiByte")
    }
    
    return win_open_clipboard != nil
}

// Cleanup Windows clipboard
clipboard_cleanup_windows :: proc() {
    if win_lib != 0 {
        c.dlclose(win_lib)
        win_lib = 0
    }
}

// Set clipboard text (Windows)
clipboard_set_text_windows :: proc(text : string) -> bool {
    if win_open_clipboard == nil {
        return false
    }
    
    if !win_open_clipboard(0) {
        return false
    }
    defer win_close_clipboard()
    
    if !win_empty_clipboard() {
        return false
    }
    
    // Convert to UTF-16
    utf16_len := win_mb_to_wc(65001, 0, text, len(text), nil, 0)
    if utf16_len <= 0 {
        return false
    }
    
    utf16_buf := make([]u16, utf16_len + 1)
    win_mb_to_wc(65001, 0, text, len(text), utf16_buf, utf16_len + 1)
    utf16_buf[utf16_len] = 0
    
    // Allocate global memory
    mem_size := (utf16_len + 1) * 2
    h_mem := win_global_alloc(GHND, mem_size)
    if h_mem == nil {
        return false
    }
    
    // Copy data
    locked := win_global_lock(h_mem)
    if locked == nil {
        win_global_free(h_mem)
        return false
    }
    
    copy(cast([^]u16) locked, utf16_buf)
    win_global_unlock(h_mem)
    
    // Set clipboard data
    if win_set_clipboard_data(CF_UNICODETEXT, h_mem) == nil {
        win_global_free(h_mem)
        return false
    }
    
    return true
}

// Get clipboard text (Windows)
clipboard_get_text_windows :: proc() -> (string, bool) {
    if win_open_clipboard == nil {
        return "", false
    }
    
    if !win_open_clipboard(0) {
        return "", false
    }
    defer win_close_clipboard()
    
    if !win_is_clipboard_format_available(CF_UNICODETEXT) {
        return "", false
    }
    
    h_mem := win_get_clipboard_data(CF_UNICODETEXT)
    if h_mem == nil {
        return "", false
    }
    
    locked := win_global_lock(h_mem)
    if locked == nil {
        return "", false
    }
    defer win_global_unlock(h_mem)
    
    utf16_ptr := cast(^u16) locked
    utf16_len := 0
    for utf16_ptr[utf16_len] != 0 {
        utf16_len += 1
    }
    
    utf16_slice := utf16_ptr[:utf16_len]
    
    // Convert from UTF-16
    mb_len := win_wc_to_mb(65001, 0, utf16_slice, utf16_len, nil, 0, nil, nil)
    if mb_len <= 0 {
        return "", false
    }
    
    mb_buf := make([]u8, mb_len + 1)
    win_wc_to_mb(65001, 0, utf16_slice, utf16_len, cast(cstring) mb_buf, mb_len + 1, nil, nil)
    
    return string(mb_buf[:mb_len]), true
}

// Clear clipboard (Windows)
clipboard_clear_windows :: proc() -> bool {
    if win_open_clipboard == nil {
        return false
    }
    
    if !win_open_clipboard(0) {
        return false
    }
    defer win_close_clipboard()
    
    return win_empty_clipboard()
}

// ============================================================================
// macOS Implementation (using osascript)
// ============================================================================

// Set clipboard text (macOS)
clipboard_set_text_macos :: proc(text : string) -> bool {
    // Escape text for AppleScript
    escaped := strings.replace_all(text, "\"", "\\\"")
    script := fmt.Sprintf("do shell script \"echo -n '%s' | pbcopy\"", escaped)
    
    cmd := fmt.Sprintf("osascript -e '%s'", script)
    result := os.run_command(cmd)
    return result.exit_code == 0
}

// Get clipboard text (macOS)
clipboard_get_text_macos :: proc() -> (string, bool) {
    cmd := "osascript -e 'do shell script \"pbpaste\"'"
    result := os.run_command(cmd)
    if result.exit_code != 0 {
        return "", false
    }
    return strings.trim_right(result.output, "\n"), true
}

// Clear clipboard (macOS)
clipboard_clear_macos :: proc() -> bool {
    cmd := "osascript -e 'do shell script \"echo -n | pbcopy\"'"
    result := os.run_command(cmd)
    return result.exit_code == 0
}

// ============================================================================
// Cross-Platform Clipboard Manager
// ============================================================================

Clipboard_Platform :: enum { Unknown, Linux, Windows, MacOS }

Clipboard_Manager :: struct {
    platform : Clipboard_Platform,
    initialized : bool,
}

clipboard_mgr : Clipboard_Manager

// Initialize clipboard manager
clipboard_init :: proc() -> bool {
    if clipboard_mgr.initialized {
        return true
    }
    
    // Detect platform
    #if ODIN_OS == .Linux
        clipboard_mgr.platform = Clipboard_Platform.Linux
        clipboard_mgr.initialized = clipboard_init_x11()
    #elseif ODIN_OS == .Windows
        clipboard_mgr.platform = Clipboard_Platform.Windows
        clipboard_mgr.initialized = clipboard_init_windows()
    #elseif ODIN_OS == .Darwin
        clipboard_mgr.platform = Clipboard_Platform.MacOS
        clipboard_mgr.initialized = true
    #else
        clipboard_mgr.platform = Clipboard_Platform.Unknown
        clipboard_mgr.initialized = false
    #end
    
    return clipboard_mgr.initialized
}

// Shutdown clipboard manager
clipboard_shutdown :: proc() {
    switch clipboard_mgr.platform {
    case Clipboard_Platform.Linux:
        clipboard_cleanup_x11()
    case Clipboard_Platform.Windows:
        clipboard_cleanup_windows()
    }
    clipboard_mgr.initialized = false
}

// Set clipboard text
clipboard_set_text :: proc(text : string) -> bool {
    if !clipboard_mgr.initialized {
        if !clipboard_init() {
            return false
        }
    }
    
    switch clipboard_mgr.platform {
    case Clipboard_Platform.Linux:
        return clipboard_set_text_x11(text)
    case Clipboard_Platform.Windows:
        return clipboard_set_text_windows(text)
    case Clipboard_Platform.MacOS:
        return clipboard_set_text_macos(text)
    }
    return false
}

// Get clipboard text
clipboard_get_text :: proc() -> (string, bool) {
    if !clipboard_mgr.initialized {
        if !clipboard_init() {
            return "", false
        }
    }
    
    switch clipboard_mgr.platform {
    case Clipboard_Platform.Linux:
        return clipboard_get_text_x11()
    case Clipboard_Platform.Windows:
        return clipboard_get_text_windows()
    case Clipboard_Platform.MacOS:
        return clipboard_get_text_macos()
    }
    return "", false
}

// Clear clipboard
clipboard_clear :: proc() -> bool {
    if !clipboard_mgr.initialized {
        if !clipboard_init() {
            return false
        }
    }
    
    switch clipboard_mgr.platform {
    case Clipboard_Platform.Linux:
        return clipboard_clear_x11()
    case Clipboard_Platform.Windows:
        return clipboard_clear_windows()
    case Clipboard_Platform.MacOS:
        return clipboard_clear_macos()
    }
    return false
}

// Check if text is available
clipboard_has_text :: proc() -> bool {
    _, ok := clipboard_get_text()
    return ok
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Copy text to clipboard
clipboard_copy :: proc(text : string) -> bool {
    return clipboard_set_text(text)
}

// Paste text from clipboard
clipboard_paste :: proc() -> (string, bool) {
    return clipboard_get_text()
}

// Cut (copy and clear)
clipboard_cut :: proc() -> (string, bool) {
    text, ok := clipboard_get_text()
    if ok {
        clipboard_clear()
    }
    return text, ok
}
