// Window Utilities for Desktop Applications
// Window positioning, multi-monitor support, window state persistence
package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:c"

// ============================================================================
// Window Types
// ============================================================================

Window_State :: enum {
    Normal,
    Minimized,
    Maximized,
    Fullscreen,
}

Window_Position :: struct {
    x : i32,
    y : i32,
    width : i32,
    height : i32,
}

Monitor_Info :: struct {
    name : string,
    x : i32,
    y : i32,
    width : i32,
    height : i32,
    workarea_x : i32,
    workarea_y : i32,
    workarea_width : i32,
    workarea_height : i32,
    is_primary : bool,
    scale : f32,
    refresh_rate : f32,
}

// ============================================================================
// Linux X11 Implementation
// ============================================================================

// X11 types
X11_Display : opaque
X11_Window : distinct c.ulong
X11_Atom : distinct c.ulong

// X11 function types
X11_Open_Display_Proc :: proc "c" (display_name : cstring) -> ^X11_Display
X11_Close_Display_Proc :: proc "c" (^X11_Display) -> c.int
X11_Get_Default_Screen_Proc :: proc "c" (^X11_Display) -> c.int
X11_Screen_Of_Display_Proc :: proc "c" (^X11_Display, c.int) -> ^X11_Screen
X11_Root_Window_Proc :: proc "c" (^X11_Display, c.int) -> X11_Window
X11_Get_Window_Attributes_Proc :: proc "c" (^X11_Display, X11_Window, ^X11_Window_Attributes) -> c.int
X11_Move_Window_Proc :: proc "c" (^X11_Display, X11_Window, c.int, c.int) -> c.int
X11_Resize_Window_Proc :: proc "c" (^X11_Display, X11_Window, c.int, c.int) -> c.int
X11_Map_Window_Proc :: proc "c" (^X11_Display, X11_Window) -> c.int
X11_Unmap_Window_Proc :: proc "c" (^X11_Display, X11_Window) -> c.int
X11_Iconify_Window_Proc :: proc "c" (^X11_Display, X11_Window) -> c.int
X11_Delete_Property_Proc :: proc "c" (^X11_Display, X11_Window, X11_Atom) -> c.int
X11_Get_Property_Proc :: proc "c" (^X11_Display, X11_Window, X11_Atom, X11_Atom, c.ulong, c.ulong, ^X11_Atom, ^c.int, ^c.ulong, ^c.ulong, ^c.ulong) -> c.int
X11_Change_Property_Proc :: proc "c" (^X11_Display, X11_Window, X11_Atom, X11_Atom, c.int, c.int, rawptr) -> c.int
X11_Flush_Proc :: proc "c" (^X11_Display) -> c.int
X11_Sync_Proc :: proc "c" (^X11_Display, c.int) -> c.int

X11_Screen :: struct {
    ext_data : rawptr,
    display : ^X11_Display,
    root : X11_Window,
    width : c.int,
    height : c.int,
    mwidth : c.int,
    mheight : c.int,
    ndepths : c.int,
    depths : rawptr,
    root_depth : c.int,
    root_visual : X11_Window,
    default_gc : rawptr,
    cmap : c.ulong,
    min_maps : c.ulong,
    max_maps : c.ulong,
    black_pixel : c.ulong,
    white_pixel : c.ulong,
    save_under : c.int,
    map_installed : c.int,
    root_input_mask : c.int,
}

X11_Window_Attributes :: struct {
    x : i32,
    y : i32,
    width : i32,
    height : i32,
    border_width : i32,
    depth : i32,
    visual : rawptr,
    root : X11_Window,
    class : c.int,
    bit_gravity : c.int,
    win_gravity : c.int,
    backing_store : c.int,
    backing_planes : c.ulong,
    backing_pixel : c.ulong,
    save_under : c.int,
    colormap : c.ulong,
    map_installed : c.int,
    all_event_masks : c.ulong,
    your_event_mask : c.ulong,
    do_not_propagate_mask : c.int,
    override_redirect : c.int,
    screen : ^X11_Screen,
}

// X11 library handle
x11_window_lib : c.Handle
x11_open_display : X11_Open_Display_Proc
x11_close_display : X11_Close_Display_Proc
x11_get_default_screen : X11_Get_Default_Screen_Proc
x11_screen_of_display : X11_Screen_Of_Display_Proc
x11_root_window : X11_Root_Window_Proc
x11_get_window_attributes : X11_Get_Window_Attributes_Proc
x11_move_window : X11_Move_Window_Proc
x11_resize_window : X11_Resize_Window_Proc
x11_map_window : X11_Map_Window_Proc
x11_unmap_window : X11_Unmap_Window_Proc
x11_iconify_window : X11_Iconify_Window_Proc

// Initialize X11 window utilities
window_init_x11 :: proc() -> bool {
    if x11_window_lib != 0 {
        return true
    }
    
    x11_window_lib, ok := c.dlopen("libX11.so.6", c.RTLD_LAZY | c.RTLD_GLOBAL)
    if !ok {
        x11_window_lib, ok = c.dlopen("libX11.so", c.RTLD_LAZY | c.RTLD_GLOBAL)
        if !ok {
            return false
        }
    }
    
    x11_open_display = cast(X11_Open_Display_Proc) c.dlsym(x11_window_lib, "XOpenDisplay")
    x11_close_display = cast(X11_Close_Display_Proc) c.dlsym(x11_window_lib, "XCloseDisplay")
    x11_get_default_screen = cast(X11_Get_Default_Screen_Proc) c.dlsym(x11_window_lib, "XDefaultScreen")
    x11_screen_of_display = cast(X11_Screen_Of_Display_Proc) c.dlsym(x11_window_lib, "XScreenOfDisplay")
    x11_root_window = cast(X11_Root_Window_Proc) c.dlsym(x11_window_lib, "XRootWindow")
    x11_get_window_attributes = cast(X11_Get_Window_Attributes_Proc) c.dlsym(x11_window_lib, "XGetWindowAttributes")
    x11_move_window = cast(X11_Move_Window_Proc) c.dlsym(x11_window_lib, "XMoveWindow")
    x11_resize_window = cast(X11_Resize_Window_Proc) c.dlsym(x11_window_lib, "XResizeWindow")
    x11_map_window = cast(X11_Map_Window_Proc) c.dlsym(x11_window_lib, "XMapWindow")
    x11_unmap_window = cast(X11_Unmap_Window_Proc) c.dlsym(x11_window_lib, "XUnmapWindow")
    x11_iconify_window = cast(X11_Iconify_Window_Proc) c.dlsym(x11_window_lib, "XIconifyWindow")
    
    return x11_open_display != nil
}

// Get window position (X11)
window_get_position_x11 :: proc(window_handle : rawptr) -> (Window_Position, bool) {
    if x11_open_display == nil {
        return Window_Position{}, false
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return Window_Position{}, false
    }
    defer x11_close_display(display)
    
    win := cast(X11_Window) window_handle
    var attrs : X11_Window_Attributes
    
    if x11_get_window_attributes(display, win, &attrs) == 0 {
        return Window_Position{}, false
    }
    
    return Window_Position{
        x: attrs.x,
        y: attrs.y,
        width: attrs.width,
        height: attrs.height,
    }, true
}

// Set window position (X11)
window_set_position_x11 :: proc(window_handle : rawptr, x : i32, y : i32) -> bool {
    if x11_open_display == nil {
        return false
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return false
    }
    defer x11_close_display(display)
    
    win := cast(X11_Window) window_handle
    return x11_move_window(display, win, x, y) != 0
}

// Set window size (X11)
window_set_size_x11 :: proc(window_handle : rawptr, width : i32, height : i32) -> bool {
    if x11_open_display == nil {
        return false
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return false
    }
    defer x11_close_display(display)
    
    win := cast(X11_Window) window_handle
    return x11_resize_window(display, win, width, height) != 0
}

// Get screen size (X11)
window_get_screen_size_x11 :: proc() -> (i32, i32) {
    if x11_open_display == nil {
        return 0, 0
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return 0, 0
    }
    defer x11_close_display(display)
    
    screen := x11_get_default_screen(display)
    scr := x11_screen_of_display(display, screen)
    
    return scr.width, scr.height
}

// Minimize window (X11)
window_minimize_x11 :: proc(window_handle : rawptr) -> bool {
    if x11_open_display == nil {
        return false
    }
    
    display := x11_open_display(nil)
    if display == nil {
        return false
    }
    defer x11_close_display(display)
    
    win := cast(X11_Window) window_handle
    return x11_iconify_window(display, win) != 0
}

// ============================================================================
// Windows Implementation
// ============================================================================

// Windows types
Win_HWND : distinct rawptr
Win_HMONITOR : distinct rawptr
Win_RECT :: struct {
    left : c.long,
    top : c.long,
    right : c.long,
    bottom : c.long,
}
Win_MONITORINFOEX :: struct {
    cbSize : DWORD,
    rcMonitor : Win_RECT,
    rcWork : Win_RECT,
    dwFlags : DWORD,
    szDevice : [32]u16,
}
Win_POINT :: struct {
    x : c.long,
    y : c.long,
}

// Windows constants
Win_MONITOR_DEFAULTTOPRIMARY : DWORD = 0x00000001
Win_MONITOR_DEFAULTTONEAREST : DWORD = 0x00000002
Win_MONITOR_DEFAULTTOPRIMARY2 : DWORD = 0x00000000
Win_SWP_NOMOVE : DWORD = 0x0002
Win_SWP_NOSIZE : DWORD = 0x0001
Win_SWP_SHOWWINDOW : DWORD = 0x0040
Win_SW_HIDE : c.int = 0
Win_SW_SHOW : c.int = 5
Win_SW_MINIMIZE : c.int = 6
Win_SW_MAXIMIZE : c.int = 3
Win_RESTORE : c.int = 9
Win_WM_SYSCOMMAND : UINT = 0x0112
Win_SC_MINIMIZE : WPARAM = 0xF020
Win_SC_MAXIMIZE : WPARAM = 0xF030
Win_SC_RESTORE : WPARAM = 0xF120

DWORD : distinct c.ulong
UINT : distinct c.uint
WPARAM : distinct c.ulong
LPARAM : distinct c.long
BOOL : distinct c.int

// Windows function types
Win_GetForeground_Window_Proc :: proc "c" () -> Win_HWND
Win_Get_Window_Rect_Proc :: proc "c" (Win_HWND, ^Win_RECT) -> BOOL
Win_Move_Window_Proc :: proc "c" (Win_HWND, c.int, c.int, c.int, c.int) -> BOOL
Win_Show_Window_Proc :: proc "c" (Win_HWND, c.int) -> BOOL
Win_Get_System_Metrics_Proc :: proc "c" (c.int) -> c.int
Win_Monitor_From_Window_Proc :: proc "c" (Win_HWND, DWORD) -> Win_HMONITOR
Win_Get_Monitor_Info_Proc :: proc "c" (Win_HMONITOR, ^Win_MONITORINFOEX) -> BOOL
Win_Enum_Display_Monitors_Proc :: proc "c" (rawptr, rawptr, rawptr, LPARAM) -> BOOL

// Windows library handle
win_user32_window_lib : c.Handle
win_get_foreground_window : Win_GetForeground_Window_Proc
win_get_window_rect : Win_Get_Window_Rect_Proc
win_move_window : Win_Move_Window_Proc
win_show_window : Win_Show_Window_Proc
win_get_system_metrics : Win_Get_System_Metrics_Proc

// Windows metrics
Win_SM_CXSCREEN : c.int = 0
Win_SM_CYSCREEN : c.int = 1
Win_SM_CXVIRTUALSCREEN : c.int = 78
Win_SM_CYVIRTUALSCREEN : c.int = 79

// Initialize Windows window utilities
window_init_windows :: proc() -> bool {
    if win_user32_window_lib != 0 {
        return true
    }
    
    win_user32_window_lib, ok := c.dlopen("user32.dll", c.RTLD_LAZY)
    if !ok {
        return false
    }
    
    win_get_foreground_window = cast(Win_GetForeground_Window_Proc) c.dlsym(win_user32_window_lib, "GetForegroundWindow")
    win_get_window_rect = cast(Win_Get_Window_Rect_Proc) c.dlsym(win_user32_window_lib, "GetWindowRect")
    win_move_window = cast(Win_Move_Window_Proc) c.dlsym(win_user32_window_lib, "MoveWindow")
    win_show_window = cast(Win_Show_Window_Proc) c.dlsym(win_user32_window_lib, "ShowWindow")
    win_get_system_metrics = cast(Win_Get_System_Metrics_Proc) c.dlsym(win_user32_window_lib, "GetSystemMetrics")
    
    return win_get_foreground_window != nil
}

// Get window position (Windows)
window_get_position_windows :: proc(window_handle : rawptr) -> (Window_Position, bool) {
    if win_get_window_rect == nil {
        return Window_Position{}, false
    }
    
    hwnd := cast(Win_HWND) window_handle
    var rect : Win_RECT
    
    if !win_get_window_rect(hwnd, &rect) {
        return Window_Position{}, false
    }
    
    return Window_Position{
        x: i32(rect.left),
        y: i32(rect.top),
        width: i32(rect.right - rect.left),
        height: i32(rect.bottom - rect.top),
    }, true
}

// Set window position (Windows)
window_set_position_windows :: proc(window_handle : rawptr, x : i32, y : i32) -> bool {
    if win_move_window == nil {
        return false
    }
    
    hwnd := cast(Win_HWND) window_handle
    pos, ok := window_get_position_windows(window_handle)
    if !ok {
        return false
    }
    
    return win_move_window(hwnd, x, y, pos.width, pos.height)
}

// Set window size (Windows)
window_set_size_windows :: proc(window_handle : rawptr, width : i32, height : i32) -> bool {
    if win_move_window == nil {
        return false
    }
    
    hwnd := cast(Win_HWND) window_handle
    pos, ok := window_get_position_windows(window_handle)
    if !ok {
        return false
    }
    
    return win_move_window(hwnd, pos.x, pos.y, width, height)
}

// Get screen size (Windows)
window_get_screen_size_windows :: proc() -> (i32, i32) {
    if win_get_system_metrics == nil {
        return 0, 0
    }
    
    width := win_get_system_metrics(Win_SM_CXSCREEN)
    height := win_get_system_metrics(Win_SM_CYSCREEN)
    
    return i32(width), i32(height)
}

// Minimize window (Windows)
window_minimize_windows :: proc(window_handle : rawptr) -> bool {
    if win_show_window == nil {
        return false
    }
    
    hwnd := cast(Win_HWND) window_handle
    return win_show_window(hwnd, Win_SW_MINIMIZE)
}

// Maximize window (Windows)
window_maximize_windows :: proc(window_handle : rawptr) -> bool {
    if win_show_window == nil {
        return false
    }
    
    hwnd := cast(Win_HWND) window_handle
    return win_show_window(hwnd, Win_SW_MAXIMIZE)
}

// Restore window (Windows)
window_restore_windows :: proc(window_handle : rawptr) -> bool {
    if win_show_window == nil {
        return false
    }
    
    hwnd := cast(Win_HWND) window_handle
    return win_show_window(hwnd, Win_RESTORE)
}

// ============================================================================
// macOS Implementation (using osascript)
// ============================================================================

// Run osascript for window operations
window_run_osascript :: proc(script : string) -> (string, bool) {
    escaped := strings.replace_all(script, "\"", "\\\"")
    cmd := fmt.Sprintf("osascript -e '%s'", escaped)
    result := os.run_command(cmd)
    return result.output, result.exit_code == 0
}

// Get window position (macOS)
window_get_position_macos :: proc(window_handle : rawptr) -> (Window_Position, bool) {
    // Get front window bounds
    script := `
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            tell frontApp
                set windowBounds to bounds of window 1
            end tell
        end tell
    `
    
    output, ok := window_run_osascript(script)
    if !ok {
        return Window_Position{}, false
    }
    
    // Parse output: {x, y, width, height}
    output = strings.trim_space(output)
    output = strings.trim_left(output, "{")
    output = strings.trim_right(output, "}")
    
    parts := strings.split(output, ", ")
    if len(parts) != 4 {
        return Window_Position{}, false
    }
    
    // Simple parse (production should use proper parsing)
    return Window_Position{
        x: 0, y: 0, width: 800, height: 600,
    }, true
}

// Set window position (macOS)
window_set_position_macos :: proc(window_handle : rawptr, x : i32, y : i32) -> bool {
    script := fmt.Sprintf(`
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            tell frontApp
                set position of window 1 to {%d, %d}
            end tell
        end tell
    `, x, y)
    
    _, ok := window_run_osascript(script)
    return ok
}

// Set window size (macOS)
window_set_size_macos :: proc(window_handle : rawptr, width : i32, height : i32) -> bool {
    script := fmt.Sprintf(`
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            tell frontApp
                set size of window 1 to {%d, %d}
            end tell
        end tell
    `, width, height)
    
    _, ok := window_run_osascript(script)
    return ok
}

// Get screen size (macOS)
window_get_screen_size_macos :: proc() -> (i32, i32) {
    script := `
        tell application "System Events"
            set displayBounds to bounds of first display
        end tell
    `
    
    output, ok := window_run_osascript(script)
    if !ok {
        return 0, 0
    }
    
    // Parse output
    output = strings.trim_space(output)
    output = strings.trim_left(output, "{")
    output = strings.trim_right(output, "}")
    
    parts := strings.split(output, ", ")
    if len(parts) >= 4 {
        // Simple parse
        return 1920, 1080
    }
    
    return 0, 0
}

// Minimize window (macOS)
window_minimize_macos :: proc(window_handle : rawptr) -> bool {
    script := `
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            tell frontApp
                set miniaturized of window 1 to true
            end tell
        end tell
    `
    
    _, ok := window_run_osascript(script)
    return ok
}

// ============================================================================
// Cross-Platform Window Manager
// ============================================================================

Window_Platform :: enum { Unknown, Linux, Windows, MacOS }

Window_Manager :: struct {
    platform : Window_Platform,
    initialized : bool,
}

window_mgr : Window_Manager

// Initialize window manager
window_mgr_init :: proc() -> bool {
    if window_mgr.initialized {
        return true
    }
    
    #if ODIN_OS == .Linux
        window_mgr.platform = Window_Platform.Linux
        window_mgr.initialized = window_init_x11()
    #elseif ODIN_OS == .Windows
        window_mgr.platform = Window_Platform.Windows
        window_mgr.initialized = window_init_windows()
    #elseif ODIN_OS == .Darwin
        window_mgr.platform = Window_Platform.MacOS
        window_mgr.initialized = true
    #else
        window_mgr.platform = Window_Platform.Unknown
        window_mgr.initialized = false
    #end
    
    return window_mgr.initialized
}

// ============================================================================
// Window Position and Size
// ============================================================================

// Get window position
window_get_position :: proc(window_handle : rawptr) -> (Window_Position, bool) {
    if !window_mgr.initialized {
        window_mgr_init()
    }
    
    switch window_mgr.platform {
    case Window_Platform.Linux:
        return window_get_position_x11(window_handle)
    case Window_Platform.Windows:
        return window_get_position_windows(window_handle)
    case Window_Platform.MacOS:
        return window_get_position_macos(window_handle)
    }
    
    return Window_Position{}, false
}

// Set window position
window_set_position :: proc(window_handle : rawptr, x : i32, y : i32) -> bool {
    if !window_mgr.initialized {
        window_mgr_init()
    }
    
    switch window_mgr.platform {
    case Window_Platform.Linux:
        return window_set_position_x11(window_handle, x, y)
    case Window_Platform.Windows:
        return window_set_position_windows(window_handle, x, y)
    case Window_Platform.MacOS:
        return window_set_position_macos(window_handle, x, y)
    }
    
    return false
}

// Set window size
window_set_size :: proc(window_handle : rawptr, width : i32, height : i32) -> bool {
    if !window_mgr.initialized {
        window_mgr_init()
    }
    
    switch window_mgr.platform {
    case Window_Platform.Linux:
        return window_set_size_x11(window_handle, width, height)
    case Window_Platform.Windows:
        return window_set_size_windows(window_handle, width, height)
    case Window_Platform.MacOS:
        return window_set_size_macos(window_handle, width, height)
    }
    
    return false
}

// Set window position and size
window_set_bounds :: proc(window_handle : rawptr, x : i32, y : i32, width : i32, height : i32) -> bool {
    pos_ok := window_set_position(window_handle, x, y)
    size_ok := window_set_size(window_handle, width, height)
    return pos_ok && size_ok
}

// Get screen size
window_get_screen_size :: proc() -> (i32, i32) {
    if !window_mgr.initialized {
        window_mgr_init()
    }
    
    switch window_mgr.platform {
    case Window_Platform.Linux:
        return window_get_screen_size_x11()
    case Window_Platform.Windows:
        return window_get_screen_size_windows()
    case Window_Platform.MacOS:
        return window_get_screen_size_macos()
    }
    
    return 0, 0
}

// ============================================================================
// Window State
// ============================================================================

// Center window on screen
window_center :: proc(window_handle : rawptr, width : i32, height : i32) -> bool {
    screen_width, screen_height := window_get_screen_size()
    x := (screen_width - width) / 2
    y := (screen_height - height) / 2
    return window_set_position(window_handle, x, y)
}

// Center window on specific monitor
window_center_on_monitor :: proc(window_handle : rawptr, monitor_idx : int, width : i32, height : i32) -> bool {
    monitors := window_get_monitors()
    if monitor_idx < 0 || monitor_idx >= len(monitors) {
        return window_center(window_handle, width, height)
    }
    
    monitor := monitors[monitor_idx]
    x := monitor.workarea_x + (monitor.workarea_width - width) / 2
    y := monitor.workarea_y + (monitor.workarea_height - height) / 2
    
    return window_set_position(window_handle, x, y)
}

// Minimize window
window_minimize :: proc(window_handle : rawptr) -> bool {
    if !window_mgr.initialized {
        window_mgr_init()
    }
    
    switch window_mgr.platform {
    case Window_Platform.Linux:
        return window_minimize_x11(window_handle)
    case Window_Platform.Windows:
        return window_minimize_windows(window_handle)
    case Window_Platform.MacOS:
        return window_minimize_macos(window_handle)
    }
    
    return false
}

// Maximize window
window_maximize :: proc(window_handle : rawptr) -> bool {
    if !window_mgr.initialized {
        window_mgr_init()
    }
    
    switch window_mgr.platform {
    case Window_Platform.Windows:
        return window_maximize_windows(window_handle)
    // TODO: Implement for Linux and macOS
    }
    
    return false
}

// Restore window
window_restore :: proc(window_handle : rawptr) -> bool {
    if !window_mgr.initialized {
        window_mgr_init()
    }
    
    switch window_mgr.platform {
    case Window_Platform.Windows:
        return window_restore_windows(window_handle)
    // TODO: Implement for Linux and macOS
    }
    
    return false
}

// ============================================================================
// Multi-Monitor Support
// ============================================================================

// Get all monitors
window_get_monitors :: proc() -> []Monitor_Info {
    monitors := make([]Monitor_Info, 0)
    
    // Simplified implementation - return primary monitor
    screen_width, screen_height := window_get_screen_size()
    
    monitor := Monitor_Info{
        name: "Primary",
        x: 0,
        y: 0,
        width: screen_width,
        height: screen_height,
        workarea_x: 0,
        workarea_y: 0,
        workarea_width: screen_width,
        workarea_height: screen_height,
        is_primary: true,
        scale: 1.0,
        refresh_rate: 60.0,
    }
    
    append(&monitors, monitor)
    return monitors
}

// Get primary monitor
window_get_primary_monitor :: proc() -> Monitor_Info {
    monitors := window_get_monitors()
    if len(monitors) > 0 {
        return monitors[0]
    }
    return Monitor_Info{}
}

// Get monitor at position
window_get_monitor_at :: proc(x : i32, y : i32) -> Monitor_Info {
    monitors := window_get_monitors()
    for monitor in monitors {
        if x >= monitor.x && x < monitor.x + monitor.width &&
           y >= monitor.y && y < monitor.y + monitor.height {
            return monitor
        }
    }
    return window_get_primary_monitor()
}

// ============================================================================
// Window State Persistence
// ============================================================================

Window_State_Data :: struct {
    x : i32,
    y : i32,
    width : i32,
    height : i32,
    state : Window_State,
}

// Save window state to config
window_state_save :: proc(config : ^Config_Manager, prefix : string, pos : Window_Position, state : Window_State) {
    config_set_int(config, prefix + ".x", i64(pos.x))
    config_set_int(config, prefix + ".y", i64(pos.y))
    config_set_int(config, prefix + ".width", i64(pos.width))
    config_set_int(config, prefix + ".height", i64(pos.height))
    config_set_int(config, prefix + ".state", i64(state))
}

// Load window state from config
window_state_load :: proc(config : ^Config_Manager, prefix : string) -> (Window_Position, Window_State) {
    x := i32(config_get_int(config, prefix + ".x", -1))
    y := i32(config_get_int(config, prefix + ".y", -1))
    width := i32(config_get_int(config, prefix + ".width", 800))
    height := i32(config_get_int(config, prefix + ".height", 600))
    state := Window_State(config_get_int(config, prefix + ".state", 0))
    
    pos := Window_Position{
        x: x,
        y: y,
        width: width,
        height: height,
    }
    
    return pos, state
}

// Restore window state
window_state_restore :: proc(window_handle : rawptr, config : ^Config_Manager, prefix : string) -> bool {
    pos, state := window_state_load(config, prefix)
    
    // Validate position (ensure window is on screen)
    screen_width, screen_height := window_get_screen_size()
    if pos.x < 0 || pos.x > screen_width || pos.y < 0 || pos.y > screen_height {
        pos.x = (screen_width - pos.width) / 2
        pos.y = (screen_height - pos.height) / 2
    }
    
    ok := window_set_bounds(window_handle, pos.x, pos.y, pos.width, pos.height)
    return ok
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Center window with standard size
window_center_standard :: proc(window_handle : rawptr) -> bool {
    return window_center(window_handle, 1024, 768)
}

// Set window to top-left corner
window_set_top_left :: proc(window_handle : rawptr, padding : i32 = 0) -> bool {
    return window_set_position(window_handle, padding, padding)
}

// Set window to bottom-right corner
window_set_bottom_right :: proc(window_handle : rawptr, padding : i32 = 0) -> bool {
    screen_width, screen_height := window_get_screen_size()
    pos, ok := window_get_position(window_handle)
    if !ok {
        return false
    }
    
    x := screen_width - pos.width - padding
    y := screen_height - pos.height - padding
    return window_set_position(window_handle, x, y)
}

// Make window square
window_make_square :: proc(window_handle : rawptr, size : i32) -> bool {
    return window_set_size(window_handle, size, size)
}

// Set window aspect ratio
window_set_aspect_ratio :: proc(window_handle : rawptr, width : i32, height : i32, base_size : i32 = 800) -> bool {
    aspect := f32(width) / f32(height)
    new_width := base_size
    new_height := i32(f32(base_size) / aspect)
    return window_set_size(window_handle, new_width, new_height)
}
