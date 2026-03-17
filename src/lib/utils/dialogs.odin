// Dialog System for Desktop Applications
// File dialogs, message boxes, and progress dialogs
package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:c"

// ============================================================================
// Dialog Types
// ============================================================================

Dialog_Button :: enum {
    OK,
    Cancel,
    Yes,
    No,
    Abort,
    Retry,
    Ignore,
    Close,
    Help,
    TryAgain,
    Continue,
}

Dialog_Style :: enum {
    Info,
    Warning,
    Error,
    Question,
    Plain,
}

File_Dialog_Mode :: enum {
    Open,
    Save,
    Open_Multiple,
    Select_Folder,
}

// ============================================================================
// File Filter
// ============================================================================

File_Filter :: struct {
    name : string,
    patterns : []string,
}

// Create file filter
file_filter_create :: proc(name : string, patterns : ..string) -> File_Filter {
    filter := File_Filter{name: name}
    filter.patterns = make([]string, 0)
    for pattern in patterns {
        append(&filter.patterns, pattern)
    }
    return filter
}

// Convert filter to dialog string
file_filter_to_string :: proc(filter : File_Filter) -> string {
    if len(filter.patterns) == 0 {
        return filter.name + " (*." + ")|*."
    }
    
    pattern_str := strings.join_all(filter.patterns, ";")
    return fmt.Sprintf("%s (%s)|%s", filter.name, pattern_str, pattern_str)
}

// Common file filters
file_filter_all_files :: proc() -> File_Filter {
    return file_filter_create("All Files", "*")
}

file_filter_text_files :: proc() -> File_Filter {
    return file_filter_create("Text Files", "*.txt", "*.log", "*.md")
}

file_filter_image_files :: proc() -> File_Filter {
    return file_filter_create("Image Files", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.webp", "*.svg")
}

file_filter_json_files :: proc() -> File_Filter {
    return file_filter_create("JSON Files", "*.json")
}

file_filter_xml_files :: proc() -> File_Filter {
    return file_filter_create("XML Files", "*.xml")
}

file_filter_odin_files :: proc() -> File_Filter {
    return file_filter_create("Odin Files", "*.odin")
}

file_filter_source_files :: proc() -> File_Filter {
    return file_filter_create("Source Files", "*.odin", "*.c", "*.cpp", "*.h", "*.hpp", "*.go", "*.rs", "*.py", "*.js", "*.ts")
}

// ============================================================================
// File Dialog Result
// ============================================================================

File_Dialog_Result :: struct {
    success : bool,
    paths : []string,
    selected_filter : int,
    error_message : string,
}

// ============================================================================
// Linux Implementation (using zenity/xdialog/kdialog)
// ============================================================================

// Run zenity command
dialog_run_zenity :: proc(args : ..string) -> (string, bool) {
    cmd := "zenity"
    for arg in args {
        cmd += " " + arg
    }
    
    result := os.run_command(cmd)
    return result.output, result.exit_code == 0
}

// File dialog (Linux)
dialog_file_linux :: proc(mode : File_Dialog_Mode, title : string, filters : []File_Filter, default_path : string) -> File_Dialog_Result {
    result := File_Dialog_Result{}
    result.paths = make([]string, 0)
    
    args := make([]string, 0)
    
    // Mode
    switch mode {
    case File_Dialog_Mode.Open:
        append(&args, "--file-selection")
    case File_Dialog_Mode.Save:
        append(&args, "--file-selection", "--save")
    case File_Dialog_Mode.Open_Multiple:
        append(&args, "--file-selection", "--multiple")
    case File_Dialog_Mode.Select_Folder:
        append(&args, "--file-selection", "--directory")
    }
    
    // Title
    if title != "" {
        append(&args, fmt.Sprintf("--title=%s", title))
    }
    
    // Default path
    if default_path != "" {
        append(&args, fmt.Sprintf("--filename=%s", default_path))
    }
    
    // Filters
    if len(filters) > 0 {
        for filter in filters {
            pattern_str := strings.join_all(filter.patterns, " ")
            append(&args, fmt.Sprintf("--file-filter=%s | %s", pattern_str, filter.name))
        }
    }
    
    output, ok := dialog_run_zenity(args)
    if !ok {
        result.success = false
        return result
    }
    
    // Parse output (pipe-separated for multiple files)
    output = strings.trim_right(output, "\n")
    paths := strings.split(output, "|")
    
    for path in paths {
        path = strings.trim_space(path)
        if path != "" {
            append(&result.paths, path)
        }
    }
    
    result.success = len(result.paths) > 0
    return result
}

// Message box (Linux)
dialog_message_linux :: proc(style : Dialog_Style, title : string, message : string, buttons : []Dialog_Button) -> Dialog_Button {
    args := make([]string, 0)
    append(&args, "--title", title)
    append(&args, fmt.Sprintf("--text=%s", message))
    
    switch style {
    case Dialog_Style.Info:
        append(&args, "--info")
    case Dialog_Style.Warning:
        append(&args, "--warning")
    case Dialog_Style.Error:
        append(&args, "--error")
    case Dialog_Style.Question:
        append(&args, "--question")
    case Dialog_Style.Plain:
        append(&args, "--info")
    }
    
    output, ok := dialog_run_zenity(args)
    
    if style == Dialog_Style.Question {
        if ok {
            return Dialog_Button.Yes
        } else {
            return Dialog_Button.No
        }
    }
    
    if ok {
        return Dialog_Button.OK
    } else {
        return Dialog_Button.Cancel
    }
}

// ============================================================================
// Windows Implementation
// ============================================================================

// Windows types
Win_HWND : distinct rawptr
Win_HINSTANCE : distinct rawptr
Win_LPCSTR : distinct cstring
Win_LPCTSTR : distinct rawptr

// Windows constants
Win_MB_OK : UINT = 0x00000000
Win_MB_OKCANCEL : UINT = 0x00000001
Win_MB_YESNO : UINT = 0x00000004
Win_MB_YESNOCANCEL : UINT = 0x00000003
Win_MB_ICONINFORMATION : UINT = 0x00000040
Win_MB_ICONWARNING : UINT = 0x00000030
Win_MB_ICONERROR : UINT = 0x00000010
Win_MB_ICONQUESTION : UINT = 0x00000020
Win_IDOK : c.int = 1
Win_IDCANCEL : c.int = 2
Win_IDYES : c.int = 6
Win_IDNO : c.int = 7

Win_OFN_EXPLORER : DWORD = 0x00080000
Win_OFN_FILEMUSTEXIST : DWORD = 0x00001000
Win_OFN_CREATEPROMPT : DWORD = 0x00002000
Win_OFN_SAVEASOVERRIDE : DWORD = 0x00000200
Win_OFN_OVERWRITEPROMPT : DWORD = 0x00000002
Win_OFN_ALLOWMULTISELECT : DWORD = 0x00000200
Win_OFN_NOCHANGEDIR : DWORD = 0x00000008

Win_CC_RGBINIT : DWORD = 0x00000001

// Windows function types
Win_MessageBox_Proc :: proc "c" (Win_HWND, cstring, cstring, UINT) -> c.int

// Windows library handle
win_user32_lib : c.Handle
win_message_box : Win_MessageBox_Proc

// Initialize Windows dialogs
dialog_init_windows :: proc() -> bool {
    if win_user32_lib != 0 {
        return true
    }
    
    win_user32_lib, ok := c.dlopen("user32.dll", c.RTLD_LAZY)
    if !ok {
        return false
    }
    
    win_message_box = cast(Win_MessageBox_Proc) c.dlsym(win_user32_lib, "MessageBoxA")
    return win_message_box != nil
}

// Message box (Windows)
dialog_message_windows :: proc(style : Dialog_Style, title : string, message : string, buttons : []Dialog_Button) -> Dialog_Button {
    if !dialog_init_windows() {
        return Dialog_Button.OK
    }
    
    style_flags : UINT = 0
    
    // Button flags
    if len(buttons) == 0 || (len(buttons) == 1 && buttons[0] == Dialog_Button.OK) {
        style_flags |= Win_MB_OK
    } else {
        has_yes := false
        has_no := false
        has_cancel := false
        
        for btn in buttons {
            switch btn {
            case Dialog_Button.Yes: has_yes = true
            case Dialog_Button.No: has_no = true
            case Dialog_Button.Cancel: has_cancel = true
            }
        }
        
        if has_yes && has_no && has_cancel {
            style_flags |= Win_MB_YESNOCANCEL
        } else if has_yes && has_no {
            style_flags |= Win_MB_YESNO
        } else {
            style_flags |= Win_MB_OKCANCEL
        }
    }
    
    // Icon flags
    switch style {
    case Dialog_Style.Info:
        style_flags |= Win_MB_ICONINFORMATION
    case Dialog_Style.Warning:
        style_flags |= Win_MB_ICONWARNING
    case Dialog_Style.Error:
        style_flags |= Win_MB_ICONERROR
    case Dialog_Style.Question:
        style_flags |= Win_MB_ICONQUESTION
    }
    
    result := win_message_box(0, message, title, style_flags)
    
    switch result {
    case Win_IDOK: return Dialog_Button.OK
    case Win_IDCANCEL: return Dialog_Button.Cancel
    case Win_IDYES: return Dialog_Button.Yes
    case Win_IDNO: return Dialog_Button.No
    }
    
    return Dialog_Button.OK
}

// ============================================================================
// macOS Implementation (using osascript)
// ============================================================================

// Run osascript command
dialog_run_osascript :: proc(script : string) -> (string, bool) {
    escaped := strings.replace_all(script, "\"", "\\\"")
    cmd := fmt.Sprintf("osascript -e '%s'", escaped)
    result := os.run_command(cmd)
    return result.output, result.exit_code == 0
}

// File dialog (macOS)
dialog_file_macos :: proc(mode : File_Dialog_Mode, title : string, filters : []File_Filter, default_path : string) -> File_Dialog_Result {
    result := File_Dialog_Result{}
    result.paths = make([]string, 0)
    
    script := ""
    
    switch mode {
    case File_Dialog_Mode.Open:
        script = fmt.Sprintf(`choose file with prompt "%s"`, title)
    case File_Dialog_Mode.Save:
        script = fmt.Sprintf(`choose file name with prompt "%s"`, title)
    case File_Dialog_Mode.Open_Multiple:
        script = fmt.Sprintf(`choose file with prompt "%s" with multiple selections allowed`, title)
    case File_Dialog_Mode.Select_Folder:
        script = fmt.Sprintf(`choose folder with prompt "%s"`, title)
    }
    
    if default_path != "" {
        script += fmt.Sprintf(` default location "%s"`, default_path)
    }
    
    output, ok := dialog_run_osascript(script)
    if !ok {
        result.success = false
        return result
    }
    
    // Parse output (AppleScript returns file paths)
    output = strings.trim_right(output, "\n")
    lines := strings.split_lines(output)
    
    for line in lines {
        line = strings.trim_space(line)
        if line != "" && !strings.has_prefix(line, "file ") {
            // Convert HFS path to POSIX path if needed
            append(&result.paths, line)
        }
    }
    
    result.success = len(result.paths) > 0
    return result
}

// Message box (macOS)
dialog_message_macos :: proc(style : Dialog_Style, title : string, message : string, buttons : []Dialog_Button) -> Dialog_Button {
    script := fmt.Sprintf(`display dialog "%s"`, message)
    script += fmt.Sprintf(` with title "%s"`, title)
    
    switch style {
    case Dialog_Style.Info:
        script += ` with icon note`
    case Dialog_Style.Warning:
        script += ` with icon caution`
    case Dialog_Style.Error:
        script += ` with icon stop`
    case Dialog_Style.Question:
        script += ` with icon note`
    }
    
    // Buttons
    if len(buttons) > 0 {
        btn_str := " buttons {"
        for i, btn in buttons {
            if i > 0 {
                btn_str += ", "
            }
            btn_name := ""
            switch btn {
            case Dialog_Button.OK: btn_name = "OK"
            case Dialog_Button.Cancel: btn_name = "Cancel"
            case Dialog_Button.Yes: btn_name = "Yes"
            case Dialog_Button.No: btn_name = "No"
            default: btn_name = "OK"
            }
            btn_str += fmt.Sprintf(`"%s"`, btn_name)
        }
        btn_str += "}"
        script += btn_str
    }
    
    script += ` with text buttons`
    
    output, ok := dialog_run_osascript(script)
    if !ok {
        return Dialog_Button.Cancel
    }
    
    // Parse result
    if strings.contains(output, "button returned:Yes") || strings.contains(output, "button returned:OK") {
        return Dialog_Button.OK
    } else if strings.contains(output, "button returned:No") {
        return Dialog_Button.No
    } else if strings.contains(output, "button returned:Cancel") {
        return Dialog_Button.Cancel
    }
    
    return Dialog_Button.OK
}

// ============================================================================
// Cross-Platform Dialog Manager
// ============================================================================

Dialog_Platform :: enum { Unknown, Linux, Windows, MacOS }

Dialog_Manager :: struct {
    platform : Dialog_Platform,
    initialized : bool,
}

dialog_mgr : Dialog_Manager

// Initialize dialog manager
dialog_init :: proc() -> bool {
    if dialog_mgr.initialized {
        return true
    }
    
    // Detect platform
    #if ODIN_OS == .Linux
        dialog_mgr.platform = Dialog_Platform.Linux
        dialog_mgr.initialized = true
    #elseif ODIN_OS == .Windows
        dialog_mgr.platform = Dialog_Platform.Windows
        dialog_mgr.initialized = dialog_init_windows()
    #elseif ODIN_OS == .Darwin
        dialog_mgr.platform = Dialog_Platform.MacOS
        dialog_mgr.initialized = true
    #else
        dialog_mgr.platform = Dialog_Platform.Unknown
        dialog_mgr.initialized = false
    #end
    
    return dialog_mgr.initialized
}

// ============================================================================
// File Dialog
// ============================================================================

// Show file dialog
dialog_file :: proc(
    mode : File_Dialog_Mode = File_Dialog_Mode.Open,
    title : string = "",
    filters : []File_Filter = nil,
    default_path : string = "",
) -> File_Dialog_Result {
    if !dialog_mgr.initialized {
        dialog_init()
    }
    
    switch dialog_mgr.platform {
    case Dialog_Platform.Linux:
        return dialog_file_linux(mode, title, filters, default_path)
    case Dialog_Platform.Windows:
        // TODO: Windows file dialog using COM
        return File_Dialog_Result{success: false}
    case Dialog_Platform.MacOS:
        return dialog_file_macos(mode, title, filters, default_path)
    }
    
    return File_Dialog_Result{success: false}
}

// Show open file dialog
dialog_open_file :: proc(
    title : string = "Open File",
    filters : []File_Filter = nil,
    default_path : string = "",
) -> File_Dialog_Result {
    return dialog_file(File_Dialog_Mode.Open, title, filters, default_path)
}

// Show save file dialog
dialog_save_file :: proc(
    title : string = "Save File",
    filters : []File_Filter = nil,
    default_path : string = "",
) -> File_Dialog_Result {
    return dialog_file(File_Dialog_Mode.Save, title, filters, default_path)
}

// Show open multiple files dialog
dialog_open_files :: proc(
    title : string = "Open Files",
    filters : []File_Filter = nil,
    default_path : string = "",
) -> File_Dialog_Result {
    return dialog_file(File_Dialog_Mode.Open_Multiple, title, filters, default_path)
}

// Show select folder dialog
dialog_select_folder :: proc(
    title : string = "Select Folder",
    default_path : string = "",
) -> File_Dialog_Result {
    return dialog_file(File_Dialog_Mode.Select_Folder, title, nil, default_path)
}

// ============================================================================
// Message Box
// ============================================================================

// Show message box
dialog_message :: proc(
    style : Dialog_Style = Dialog_Style.Info,
    title : string = "Message",
    message : string = "",
    buttons : []Dialog_Button = nil,
) -> Dialog_Button {
    if !dialog_mgr.initialized {
        dialog_init()
    }
    
    switch dialog_mgr.platform {
    case Dialog_Platform.Linux:
        return dialog_message_linux(style, title, message, buttons)
    case Dialog_Platform.Windows:
        return dialog_message_windows(style, title, message, buttons)
    case Dialog_Platform.MacOS:
        return dialog_message_macos(style, title, message, buttons)
    }
    
    return Dialog_Button.OK
}

// Show info message
dialog_info :: proc(title : string = "Information", message : string = "") -> Dialog_Button {
    return dialog_message(Dialog_Style.Info, title, message, {Dialog_Button.OK})
}

// Show warning message
dialog_warning :: proc(title : string = "Warning", message : string = "") -> Dialog_Button {
    return dialog_message(Dialog_Style.Warning, title, message, {Dialog_Button.OK})
}

// Show error message
dialog_error :: proc(title : string = "Error", message : string = "") -> Dialog_Button {
    return dialog_message(Dialog_Style.Error, title, message, {Dialog_Button.OK})
}

// Show question (Yes/No)
dialog_question :: proc(title : string = "Question", message : string = "") -> Dialog_Button {
    return dialog_message(Dialog_Style.Question, title, message, {Dialog_Button.Yes, Dialog_Button.No})
}

// Show OK/Cancel dialog
dialog_ok_cancel :: proc(title : string = "Confirm", message : string = "") -> Dialog_Button {
    return dialog_message(Dialog_Style.Plain, title, message, {Dialog_Button.OK, Dialog_Button.Cancel})
}

// ============================================================================
// Progress Dialog (using zenity on Linux, osascript on macOS)
// ============================================================================

Progress_Dialog :: struct {
    title : string,
    message : string,
    percentage : f32,
    is_running : bool,
    pulse : bool,
}

// Create progress dialog
progress_dialog_create :: proc(title : string = "Progress", message : string = "") -> ^Progress_Dialog {
    dlg := new(Progress_Dialog)
    dlg.title = title
    dlg.message = message
    dlg.percentage = 0.0
    dlg.is_running = false
    dlg.pulse = false
    return dlg
}

// Show progress dialog (Linux)
progress_dialog_show_linux :: proc(dlg : ^Progress_Dialog) -> bool {
    // Start zenity progress in background
    args := make([]string, 0)
    append(&args, "--progress")
    append(&args, fmt.Sprintf("--title=%s", dlg.title))
    append(&args, fmt.Sprintf("--text=%s", dlg.message))
    append(&args, "--percentage=0")
    append(&args, "--auto-close")
    
    cmd := "zenity"
    for arg in args {
        cmd += " " + arg
    }
    
    // Run in background
    _ = os.run_command(cmd + " &")
    dlg.is_running = true
    return true
}

// Update progress dialog (Linux)
progress_dialog_update_linux :: proc(dlg : ^Progress_Dialog, percentage : f32, message : string = "") -> bool {
    // This requires IPC which is complex - simplified version
    dlg.percentage = percentage
    if message != "" {
        dlg.message = message
    }
    return true
}

// Close progress dialog (Linux)
progress_dialog_close_linux :: proc(dlg : ^Progress_Dialog) {
    // Kill zenity process
    _ = os.run_command("pkill -f 'zenity --progress'")
    dlg.is_running = false
    delete(dlg)
}

// Show progress dialog
progress_dialog_show :: proc(dlg : ^Progress_Dialog) -> bool {
    #if ODIN_OS == .Linux
        return progress_dialog_show_linux(dlg)
    #elseif ODIN_OS == .Darwin
        // macOS doesn't have a simple progress dialog
        dlg.is_running = true
        return true
    #else
        dlg.is_running = true
        return true
    #end
}

// Update progress
progress_dialog_update :: proc(dlg : ^Progress_Dialog, percentage : f32, message : string = "") {
    dlg.percentage = percentage
    if message != "" {
        dlg.message = message
    }
    
    #if ODIN_OS == .Linux
        progress_dialog_update_linux(dlg, percentage, message)
    #end
}

// Close progress dialog
progress_dialog_close :: proc(dlg : ^Progress_Dialog) {
    #if ODIN_OS == .Linux
        progress_dialog_close_linux(dlg)
    #else
        dlg.is_running = false
        delete(dlg)
    #end
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Quick file picker
pick_file :: proc(
    title : string = "Open File",
    filters : []File_Filter = nil,
) -> (string, bool) {
    result := dialog_open_file(title, filters, "")
    if result.success && len(result.paths) > 0 {
        return result.paths[0], true
    }
    return "", false
}

// Quick folder picker
pick_folder :: proc(title : string = "Select Folder") -> (string, bool) {
    result := dialog_select_folder(title, "")
    if result.success && len(result.paths) > 0 {
        return result.paths[0], true
    }
    return "", false
}

// Quick save picker
pick_save_file :: proc(
    title : string = "Save File",
    default_name : string = "",
) -> (string, bool) {
    result := dialog_save_file(title, nil, default_name)
    if result.success && len(result.paths) > 0 {
        return result.paths[0], true
    }
    return "", false
}

// Simple alert
alert :: proc(message : string, title : string = "Alert") {
    dialog_info(title, message)
}

// Simple confirm
confirm :: proc(message : string, title : string = "Confirm") -> bool {
    return dialog_question(title, message) == Dialog_Button.Yes
}
