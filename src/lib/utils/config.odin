// Configuration and Settings Manager for Desktop Applications
package utils

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:hash_map"
import "core:os"

// ============================================================================
// JSON Parser (Simplified for Config Files)
// ============================================================================

Json_Value_Type :: enum { Null, Bool, Number, String, Array, Object }

Json_Value :: struct {
    value_type : Json_Value_Type,
    bool_value : bool,
    number_value : f64,
    string_value : string,
    array_value : []Json_Value,
    object_value : map[string]Json_Value,
}

// Parse JSON string (simplified implementation)
json_parse :: proc(text : string) -> (Json_Value, bool) {
    trimmed := strings.trim_space(text)
    if len(trimmed) == 0 {
        return Json_Value{value_type: Json_Value_Type.Null}, false
    }
    
    return json_parse_value(trimmed, 0)
}

json_parse_value :: proc(text : string, pos : int) -> (Json_Value, int) {
    text = strings.trim_left_space(text)
    
    if len(text) == 0 {
        return Json_Value{value_type: Json_Value_Type.Null}, pos
    }
    
    switch text[0] {
    case '{':
        return json_parse_object(text, pos)
    case '[':
        return json_parse_array(text, pos)
    case '"':
        return json_parse_string(text, pos)
    case 't', 'f':
        return json_parse_bool(text, pos)
    case 'n':
        return json_parse_null(text, pos)
    default:
        return json_parse_number(text, pos)
    }
}

json_parse_object :: proc(text : string, pos : int) -> (Json_Value, int) {
    result := Json_Value{value_type: Json_Value_Type.Object}
    result.object_value = make(map[string]Json_Value)
    
    pos += 1 // Skip '{'
    text = strings.trim_left_space(text[pos:])
    pos = 0
    
    if len(text) > 0 && text[0] == '}' {
        return result, pos + 1
    }
    
    for {
        // Parse key
        text = strings.trim_left_space(text)
        if len(text) == 0 || text[0] != '"' {
            break
        }
        
        key, new_pos := json_parse_string_inner(text)
        pos += new_pos
        text = text[new_pos:]
        
        // Skip ':'
        text = strings.trim_left_space(text[1:])
        pos += 1
        
        // Parse value
        value, new_pos := json_parse_value(text, 0)
        pos += new_pos
        text = text[new_pos:]
        
        result.object_value[key] = value
        
        // Check for ',' or '}'
        text = strings.trim_left_space(text)
        if len(text) == 0 {
            break
        }
        
        if text[0] == '}' {
            pos += 1
            break
        } else if text[0] == ',' {
            text = text[1:]
            pos += 1
        } else {
            break
        }
    }
    
    return result, pos
}

json_parse_array :: proc(text : string, pos : int) -> (Json_Value, int) {
    result := Json_Value{value_type: Json_Value_Type.Array}
    result.array_value = make([]Json_Value, 0)
    
    pos += 1 // Skip '['
    text = strings.trim_left_space(text[pos:])
    pos = 0
    
    if len(text) > 0 && text[0] == ']' {
        return result, pos + 1
    }
    
    for {
        text = strings.trim_left_space(text)
        if len(text) == 0 {
            break
        }
        
        value, new_pos := json_parse_value(text, 0)
        pos += new_pos
        text = text[new_pos:]
        
        append(&result.array_value, value)
        
        text = strings.trim_left_space(text)
        if len(text) == 0 {
            break
        }
        
        if text[0] == ']' {
            pos += 1
            break
        } else if text[0] == ',' {
            text = text[1:]
            pos += 1
        } else {
            break
        }
    }
    
    return result, pos
}

json_parse_string :: proc(text : string, pos : int) -> (Json_Value, int) {
    value, new_pos := json_parse_string_inner(text)
    return Json_Value{
        value_type: Json_Value_Type.String,
        string_value: value,
    }, new_pos
}

json_parse_string_inner :: proc(text : string) -> (string, int) {
    if len(text) == 0 || text[0] != '"' {
        return "", 0
    }
    
    pos := 1
    result := ""
    
    for pos < len(text) {
        ch := text[pos]
        if ch == '"' {
            return result, pos + 1
        } else if ch == '\\' && pos + 1 < len(text) {
            pos += 1
            escape_ch := text[pos]
            switch escape_ch {
            case '"': result += "\""
            case '\\': result += "\\"
            case '/': result += "/"
            case 'b': result += "\b"
            case 'f': result += "\f"
            case 'n': result += "\n"
            case 'r': result += "\r"
            case 't': result += "\t"
            default: result += string(escape_ch)
            }
            pos += 1
        } else {
            result += string(ch)
            pos += 1
        }
    }
    
    return result, pos
}

json_parse_number :: proc(text : string, pos : int) -> (Json_Value, int) {
    num_str := ""
    i := 0
    
    // Handle negative
    if i < len(text) && text[i] == '-' {
        num_str += string(text[i])
        i += 1
    }
    
    // Parse digits
    for i < len(text) && (text[i] >= '0' && text[i] <= '9') {
        num_str += string(text[i])
        i += 1
    }
    
    // Parse decimal
    if i < len(text) && text[i] == '.' {
        num_str += string(text[i])
        i += 1
        for i < len(text) && (text[i] >= '0' && text[i] <= '9') {
            num_str += string(text[i])
            i += 1
        }
    }
    
    // Parse exponent
    if i < len(text) && (text[i] == 'e' || text[i] == 'E') {
        num_str += string(text[i])
        i += 1
        if i < len(text) && (text[i] == '+' || text[i] == '-') {
            num_str += string(text[i])
            i += 1
        }
        for i < len(text) && (text[i] >= '0' && text[i] <= '9') {
            num_str += string(text[i])
            i += 1
        }
    }
    
    value, ok := strconv.parse_f64(num_str)
    if !ok {
        value = 0.0
    }
    
    return Json_Value{
        value_type: Json_Value_Type.Number,
        number_value: value,
    }, i
}

json_parse_bool :: proc(text : string, pos : int) -> (Json_Value, int) {
    if strings.has_prefix(text, "true") {
        return Json_Value{
            value_type: Json_Value_Type.Bool,
            bool_value: true,
        }, 4
    } else if strings.has_prefix(text, "false") {
        return Json_Value{
            value_type: Json_Value_Type.Bool,
            bool_value: false,
        }, 5
    }
    return Json_Value{value_type: Json_Value_Type.Null}, 0
}

json_parse_null :: proc(text : string, pos : int) -> (Json_Value, int) {
    if strings.has_prefix(text, "null") {
        return Json_Value{value_type: Json_Value_Type.Null}, 4
    }
    return Json_Value{value_type: Json_Value_Type.Null}, 0
}

// Serialize JSON value to string
json_stringify :: proc(value : Json_Value) -> string {
    switch value.value_type {
    case Json_Value_Type.Null:
        return "null"
    case Json_Value_Type.Bool:
        return if value.bool_value then "true" else "false"
    case Json_Value_Type.Number:
        return strconv.format_f64(value.number_value, 'g', -1, 0)
    case Json_Value_Type.String:
        return json_escape_string(value.string_value)
    case Json_Value_Type.Array:
        result := "["
        for i, item in value.array_value {
            if i > 0 {
                result += ","
            }
            result += json_stringify(item)
        }
        result += "]"
        return result
    case Json_Value_Type.Object:
        result := "{"
        first := true
        for key, val in value.object_value {
            if !first {
                result += ","
            }
            result += json_escape_string(key)
            result += ":"
            result += json_stringify(val)
            first = false
        }
        result += "}"
        return result
    }
    return "null"
}

json_escape_string :: proc(s : string) -> string {
    result := "\""
    for ch in s {
        switch ch {
        case '"': result += "\\\""
        case '\\': result += "\\\\"
        case '\b': result += "\\b"
        case '\f': result += "\\f"
        case '\n': result += "\\n"
        case '\r': result += "\\r"
        case '\t': result += "\\t"
        default:
            if ch < 0x20 {
                result += fmt.Sprintf("\\u%04x", ch)
            } else {
                result += string(ch)
            }
        }
    }
    result += "\""
    return result
}

// ============================================================================
// Config Manager
// ============================================================================

Config_Change_Callback :: proc "c" (key : string, old_value : Json_Value, new_value : Json_Value)

Config_Manager :: struct {
    data : map[string]Json_Value,
    file_path : string,
    auto_save : bool,
    on_change : Config_Change_Callback,
    is_dirty : bool,
}

// Create config manager
config_create :: proc() -> ^Config_Manager {
    cfg := new(Config_Manager)
    cfg.data = make(map[string]Json_Value)
    cfg.auto_save = true
    cfg.is_dirty = false
    return cfg
}

// Load config from file
config_load :: proc(cfg : ^Config_Manager, path : string) -> bool {
    content, ok := file_read(path)
    if !ok {
        return false
    }
    
    root, ok := json_parse(content)
    if !ok {
        return false
    }
    
    cfg.file_path = path
    
    // Flatten object into data map
    if root.value_type == Json_Value_Type.Object {
        for key, value in root.object_value {
            cfg.data[key] = value
        }
    }
    
    cfg.is_dirty = false
    return true
}

// Save config to file
config_save :: proc(cfg : ^Config_Manager) -> bool {
    if cfg.file_path == "" {
        return false
    }
    
    root := Json_Value{
        value_type: Json_Value_Type.Object,
        object_value: make(map[string]Json_Value),
    }
    
    for key, value in cfg.data {
        root.object_value[key] = value
    }
    
    json_str := json_stringify(root)
    ok := file_write(cfg.file_path, json_str)
    if ok {
        cfg.is_dirty = false
    }
    return ok
}

// Save config to specific file
config_save_as :: proc(cfg : ^Config_Manager, path : string) -> bool {
    cfg.file_path = path
    return config_save(cfg)
}

// Get value by key
config_get :: proc(cfg : ^Config_Manager, key : string) -> (Json_Value, bool) {
    value, ok := cfg.data[key]
    return value, ok
}

// Get string value
config_get_string :: proc(cfg : ^Config_Manager, key : string, default_value : string) -> string {
    value, ok := cfg.data[key]
    if !ok || value.value_type != Json_Value_Type.String {
        return default_value
    }
    return value.string_value
}

// Get int value
config_get_int :: proc(cfg : ^Config_Manager, key : string, default_value : i64) -> i64 {
    value, ok := cfg.data[key]
    if !ok || value.value_type != Json_Value_Type.Number {
        return default_value
    }
    return i64(value.number_value)
}

// Get float value
config_get_float :: proc(cfg : ^Config_Manager, key : string, default_value : f64) -> f64 {
    value, ok := cfg.data[key]
    if !ok || value.value_type != Json_Value_Type.Number {
        return default_value
    }
    return value.number_value
}

// Get bool value
config_get_bool :: proc(cfg : ^Config_Manager, key : string, default_value : bool) -> bool {
    value, ok := cfg.data[key]
    if !ok || value.value_type != Json_Value_Type.Bool {
        return default_value
    }
    return value.bool_value
}

// Set value
config_set :: proc(cfg : ^Config_Manager, key : string, value : Json_Value) {
    old_value, exists := cfg.data[key]
    cfg.data[key] = value
    cfg.is_dirty = true
    
    if cfg.on_change != nil && exists {
        cfg.on_change(key, old_value, value)
    }
    
    if cfg.auto_save && cfg.file_path != "" {
        config_save(cfg)
    }
}

// Set string value
config_set_string :: proc(cfg : ^Config_Manager, key : string, value : string) {
    config_set(cfg, key, Json_Value{
        value_type: Json_Value_Type.String,
        string_value: value,
    })
}

// Set int value
config_set_int :: proc(cfg : ^Config_Manager, key : string, value : i64) {
    config_set(cfg, key, Json_Value{
        value_type: Json_Value_Type.Number,
        number_value: f64(value),
    })
}

// Set float value
config_set_float :: proc(cfg : ^Config_Manager, key : string, value : f64) {
    config_set(cfg, key, Json_Value{
        value_type: Json_Value_Type.Number,
        number_value: value,
    })
}

// Set bool value
config_set_bool :: proc(cfg : ^Config_Manager, key : string, value : bool) {
    config_set(cfg, key, Json_Value{
        value_type: Json_Value_Type.Bool,
        bool_value: value,
    })
}

// Check if key exists
config_has :: proc(cfg : ^Config_Manager, key : string) -> bool {
    _, ok := cfg.data[key]
    return ok
}

// Remove key
config_remove :: proc(cfg : ^Config_Manager, key : string) {
    _ = hash_map.remove(&cfg.data, key)
    cfg.is_dirty = true
}

// Get all keys
config_keys :: proc(cfg : ^Config_Manager) -> []string {
    keys := make([]string, 0)
    for key, _ in cfg.data {
        append(&keys, key)
    }
    return keys
}

// Clear all config
config_clear :: proc(cfg : ^Config_Manager) {
    cfg.data = make(map[string]Json_Value)
    cfg.is_dirty = true
}

// Enable/disable auto-save
config_set_auto_save :: proc(cfg : ^Config_Manager, enable : bool) {
    cfg.auto_save = enable
}

// Set change callback
config_set_on_change :: proc(cfg : ^Config_Manager, callback : Config_Change_Callback) {
    cfg.on_change = callback
}

// Check if config has unsaved changes
config_is_dirty :: proc(cfg : ^Config_Manager) -> bool {
    return cfg.is_dirty
}

// ============================================================================
// Settings Manager (User Preferences)
// ============================================================================

Settings_Scope :: enum { User, Application, System }

Settings_Manager :: struct {
    user_config : ^Config_Manager,
    app_config : ^Config_Manager,
    app_name : string,
}

// Create settings manager
settings_create :: proc(app_name : string) -> ^Settings_Manager {
    mgr := new(Settings_Manager)
    mgr.app_name = app_name
    mgr.user_config = config_create()
    mgr.app_config = config_create()
    
    // Load user config from home directory
    home := os.home_dir()
    user_config_path := fmt.Sprintf("%s/.%s/settings.json", home, app_name)
    config_load(mgr.user_config, user_config_path)
    
    // Load app config from executable directory
    exe_dir := os.executable_dir()
    app_config_path := fmt.Sprintf("%s/settings.json", exe_dir)
    config_load(mgr.app_config, app_config_path)
    
    return mgr
}

// Get value (user config takes precedence)
settings_get :: proc(mgr : ^Settings_Manager, key : string) -> (Json_Value, bool) {
    if value, ok := config_get(mgr.user_config, key); ok {
        return value, true
    }
    return config_get(mgr.app_config, key)
}

// Get string setting
settings_get_string :: proc(mgr : ^Settings_Manager, key : string, default_value : string) -> string {
    if value, ok := mgr.user_config.data[key]; ok && value.value_type == Json_Value_Type.String {
        return value.string_value
    }
    return config_get_string(mgr.app_config, key, default_value)
}

// Get int setting
settings_get_int :: proc(mgr : ^Settings_Manager, key : string, default_value : i64) -> i64 {
    if value, ok := mgr.user_config.data[key]; ok && value.value_type == Json_Value_Type.Number {
        return i64(value.number_value)
    }
    return config_get_int(mgr.app_config, key, default_value)
}

// Get bool setting
settings_get_bool :: proc(mgr : ^Settings_Manager, key : string, default_value : bool) -> bool {
    if value, ok := mgr.user_config.data[key]; ok && value.value_type == Json_Value_Type.Bool {
        return value.bool_value
    }
    return config_get_bool(mgr.app_config, key, default_value)
}

// Set user setting
settings_set :: proc(mgr : ^Settings_Manager, key : string, value : Json_Value) {
    config_set(mgr.user_config, key, value)
}

// Set string setting
settings_set_string :: proc(mgr : ^Settings_Manager, key : string, value : string) {
    config_set_string(mgr.user_config, key, value)
}

// Set int setting
settings_set_int :: proc(mgr : ^Settings_Manager, key : string, value : i64) {
    config_set_int(mgr.user_config, key, value)
}

// Set bool setting
settings_set_bool :: proc(mgr : ^Settings_Manager, key : string, value : bool) {
    config_set_bool(mgr.user_config, key, value)
}

// Save all settings
settings_save :: proc(mgr : ^Settings_Manager) -> bool {
    // Save user config
    home := os.home_dir()
    config_dir := fmt.Sprintf("%s/.%s", home, mgr.app_name)
    dir_ensure(config_dir)
    
    user_config_path := fmt.Sprintf("%s/settings.json", config_dir)
    return config_save_as(mgr.user_config, user_config_path)
}

// Reset user settings to defaults
settings_reset :: proc(mgr : ^Settings_Manager) {
    config_clear(mgr.user_config)
    settings_save(mgr)
}

// Destroy settings manager
settings_destroy :: proc(mgr : ^Settings_Manager) {
    settings_save(mgr)
    delete(mgr)
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Read JSON file
json_read :: proc(path : string) -> (Json_Value, bool) {
    content, ok := file_read(path)
    if !ok {
        return Json_Value{value_type: Json_Value_Type.Null}, false
    }
    return json_parse(content)
}

// Write JSON file
json_write :: proc(path : string, value : Json_Value) -> bool {
    json_str := json_stringify(value)
    return file_write(path, json_str)
}

// Get nested value from JSON object
json_get_nested :: proc(root : Json_Value, path : ..string) -> (Json_Value, bool) {
    current := root
    for i, key in path {
        if current.value_type != Json_Value_Type.Object {
            return Json_Value{value_type: Json_Value_Type.Null}, false
        }
        
        value, ok := current.object_value[key]
        if !ok {
            return Json_Value{value_type: Json_Value_Type.Null}, false
        }
        current = value
    }
    return current, true
}
