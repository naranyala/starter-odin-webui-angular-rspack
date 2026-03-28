package webui

import "core:c"
import "core:mem"

// WebUI Library - Odin Bindings
// https://webui.me
WEBUI_VERSION :: "2.5.0-beta.4"
WEBUI_MAX_IDS :: u16
WEBUI_MAX_ARG :: 16

Event_Type :: enum c.int {
	Disconnected = 0,
	Connected    = 1,
	Mouse_Click  = 2,
	Navigation   = 3,
	Callback     = 4,
}

Browser :: enum c.int {
	No_Browser = 0, Any = 1, Chrome = 2, Firefox = 3, Edge = 4,
	Safari = 5, Chromium = 6, Opera = 7, Brave = 8, Vivaldi = 9,
	Epic = 10, Yandex = 11, Chromium_Based = 12,
}

Runtime :: enum c.int { None = 0, Deno = 1, NodeJS = 2 }
Config :: enum c.int { Show_Wait_Connection = 0 }

Event :: struct {
	window : c.size_t, event_type : Event_Type, element : cstring,
	event_number : c.size_t, bind_id : c.size_t,
}

Event_Callback :: proc "c" (^Event)
File_Handler_Proc :: proc "c" (file_name : cstring, length : c.int) -> cstring
Window :: c.size_t
Bind_ID :: c.size_t

foreign import webui "system:webui-2"

foreign webui {
	webui_new_window          :: proc "c" () -> c.size_t ---
	webui_new_window_id       :: proc "c" (win_id : c.size_t) ---
	webui_get_new_window_id   :: proc "c" () -> c.size_t ---
	webui_show                :: proc "c" (win : c.size_t, content : cstring) -> bool ---
	webui_show_browser        :: proc "c" (win : c.size_t, content : cstring, browser : Browser) -> bool ---
	webui_show_wv             :: proc "c" (win : c.size_t, content : cstring) -> bool ---
	webui_close               :: proc "c" (win : c.size_t) ---
	webui_destroy             :: proc "c" (win : c.size_t) ---
	webui_exit                :: proc "c" () ---
	webui_wait                :: proc "c" () ---
	webui_is_shown            :: proc "c" (win : c.size_t) -> bool ---
	webui_set_timeout              :: proc "c" (second : c.size_t) ---
	webui_set_root_folder          :: proc "c" (win : c.size_t, path : cstring) ---
	webui_set_default_root_folder  :: proc "c" (path : cstring) ---
	webui_set_kiosk                :: proc "c" (win : c.size_t, status : bool) ---
	webui_set_hide                 :: proc "c" (win : c.size_t, status : bool) ---
	webui_set_size                 :: proc "c" (win : c.size_t, width : c.size_t, height : c.size_t) ---
	webui_set_position             :: proc "c" (win : c.size_t, x : c.size_t, y : c.size_t) ---
	webui_set_icon                 :: proc "c" (win : c.size_t, icon : cstring, icon_type : cstring) ---
	webui_set_profile              :: proc "c" (win : c.size_t, name : cstring, path : cstring) ---
	webui_set_proxy                :: proc "c" (win : c.size_t, proxy_server : cstring) ---
	webui_set_public               :: proc "c" (win : c.size_t, status : bool) ---
	webui_set_port                 :: proc "c" (win : c.size_t, port : c.size_t) -> bool ---
	webui_set_config               :: proc "c" (option : Config, status : bool) -> bool ---
	webui_set_runtime              :: proc "c" (win : c.size_t, runtime : Runtime) ---
	webui_set_tls_certificate      :: proc "c" (certificate_pem : cstring, private_key_pem : cstring) -> bool ---
	webui_bind :: proc "c" (win : c.size_t, element : cstring, callback : Event_Callback) -> c.size_t ---
	webui_run       :: proc "c" (win : c.size_t, script : cstring) ---
	webui_script    :: proc "c" (win : c.size_t, script : cstring, timeout : c.size_t, buffer : cstring, buffer_length : c.size_t) -> bool ---
	webui_navigate  :: proc "c" (win : c.size_t, url : cstring) ---
	webui_get_url :: proc "c" (win : c.size_t) -> cstring ---
	webui_get_count       :: proc "c" (e : ^Event) -> c.size_t ---
	webui_get_int         :: proc "c" (e : ^Event) -> i64 ---
	webui_get_int_at      :: proc "c" (e : ^Event, idx : c.size_t) -> i64 ---
	webui_get_float       :: proc "c" (e : ^Event) -> f64 ---
	webui_get_float_at    :: proc "c" (e : ^Event, idx : c.size_t) -> f64 ---
	webui_get_string      :: proc "c" (e : ^Event) -> cstring ---
	webui_get_string_at   :: proc "c" (e : ^Event, idx : c.size_t) -> cstring ---
	webui_get_bool        :: proc "c" (e : ^Event) -> bool ---
	webui_get_bool_at     :: proc "c" (e : ^Event, idx : c.size_t) -> bool ---
	webui_get_size        :: proc "c" (e : ^Event) -> c.size_t ---
	webui_get_size_at     :: proc "c" (e : ^Event, idx : c.size_t) -> c.size_t ---
	webui_return_int    :: proc "c" (e : ^Event, n : i64) ---
	webui_return_string :: proc "c" (e : ^Event, s : cstring) ---
	webui_return_bool   :: proc "c" (e : ^Event, b : bool) ---
	webui_encode                  :: proc "c" (str : cstring) -> cstring ---
	webui_decode                  :: proc "c" (str : cstring) -> cstring ---
	webui_free                    :: proc "c" (ptr : rawptr) ---
	webui_malloc                  :: proc "c" (size : c.size_t) -> rawptr ---
	webui_send_raw                :: proc "c" (win : c.size_t, func : cstring, raw : rawptr, size : c.size_t) ---
	webui_clean                   :: proc "c" () ---
	webui_delete_all_profiles     :: proc "c" () ---
	webui_delete_profile          :: proc "c" (win : c.size_t) ---
	webui_get_parent_process_id   :: proc "c" (win : c.size_t) -> c.size_t ---
	webui_get_child_process_id    :: proc "c" (win : c.size_t) -> c.size_t ---
	webui_set_file_handler :: proc "c" (win : c.size_t, handler : File_Handler_Proc) ---
}

// Wrapper functions - accept cstring directly to avoid conversion issues
new_window :: proc() -> Window { return cast(Window) webui_new_window() }
new_window_id :: proc(id : Window) { webui_new_window_id(cast(c.size_t) id) }
get_new_window_id :: proc() -> Window { return cast(Window) webui_get_new_window_id() }
show :: proc(win : Window, content : cstring) -> bool { return webui_show(win, content) }
show_browser :: proc(win : Window, content : cstring, browser : Browser) -> bool { return webui_show_browser(win, content, browser) }
show_webview :: proc(win : Window, content : cstring) -> bool { return webui_show_wv(win, content) }
close :: proc(win : Window) { webui_close(win) }
destroy :: proc(win : Window) { webui_destroy(win) }
exit :: proc() { webui_exit() }
wait :: proc() { webui_wait() }
is_shown :: proc(win : Window) -> bool { return webui_is_shown(win) }
set_timeout :: proc(timeout : c.size_t) { webui_set_timeout(timeout) }
set_root_folder :: proc(win : Window, path : cstring) { webui_set_root_folder(win, path) }
set_default_root_folder :: proc(path : cstring) { webui_set_default_root_folder(path) }
set_kiosk :: proc(win : Window, kiosk : bool) { webui_set_kiosk(win, kiosk) }
set_hide :: proc(win : Window, hidden : bool) { webui_set_hide(win, hidden) }
set_size :: proc(win : Window, width : c.size_t, height : c.size_t) { webui_set_size(win, width, height) }
set_position :: proc(win : Window, x : c.size_t, y : c.size_t) { webui_set_position(win, x, y) }
set_icon :: proc(win : Window, icon : cstring, icon_type : cstring) { webui_set_icon(win, icon, icon_type) }
set_profile :: proc(win : Window, name : cstring, path : cstring) { webui_set_profile(win, name, path) }
set_proxy :: proc(win : Window, proxy_server : cstring) { webui_set_proxy(win, proxy_server) }
set_public :: proc(win : Window, public : bool) { webui_set_public(win, public) }
set_port :: proc(win : Window, port : c.size_t) -> bool { return webui_set_port(win, port) }
set_config :: proc(option : Config, status : bool) -> bool { return webui_set_config(option, status) }
set_runtime :: proc(win : Window, runtime : Runtime) { webui_set_runtime(win, runtime) }
set_tls_certificate :: proc(certificate_pem : cstring, private_key_pem : cstring) -> bool { return webui_set_tls_certificate(certificate_pem, private_key_pem) }
bind :: proc(win : Window, element : cstring, callback : Event_Callback) -> Bind_ID { return webui_bind(win, element, callback) }
run :: proc(win : Window, script : cstring) { webui_run(win, script) }
script :: proc(win : Window, script : cstring, timeout : c.size_t, buffer : []u8) -> bool { return webui_script(win, script, timeout, cast(cstring) &buffer[0], len(buffer)) }
navigate :: proc(win : Window, url : cstring) { webui_navigate(win, url) }
get_url :: proc(win : Window) -> string {
	url_c := webui_get_url(win)
	if url_c == nil || len(url_c) == 0 {
		return ""
	}
	return cast(string) url_c
}
event_get_count :: proc(e : ^Event) -> c.size_t { return webui_get_count(e) }
event_get_int :: proc(e : ^Event) -> i64 { return webui_get_int(e) }
event_get_int_at :: proc(e : ^Event, idx : c.size_t) -> i64 { return webui_get_int_at(e, idx) }
event_get_float :: proc(e : ^Event) -> f64 { return webui_get_float(e) }
event_get_float_at :: proc(e : ^Event, idx : c.size_t) -> f64 { return webui_get_float_at(e, idx) }
event_get_string :: proc(e : ^Event) -> string {
	str_c := webui_get_string(e)
	if str_c == nil || len(str_c) == 0 {
		return ""
	}
	return cast(string) str_c
}
event_get_string_at :: proc(e : ^Event, idx : c.size_t) -> string {
	str_c := webui_get_string_at(e, idx)
	if str_c == nil || len(str_c) == 0 {
		return ""
	}
	return cast(string) str_c
}
event_get_bool :: proc(e : ^Event) -> bool { return webui_get_bool(e) }
event_get_bool_at :: proc(e : ^Event, idx : c.size_t) -> bool { return webui_get_bool_at(e, idx) }
event_return_int :: proc(e : ^Event, n : i64) { webui_return_int(e, n) }
event_return_string :: proc(e : ^Event, s : cstring) { webui_return_string(e, s) }
event_return_bool :: proc(e : ^Event, b : bool) { webui_return_bool(e, b) }
encode :: proc(data : cstring) -> cstring {
	encoded_c := webui_encode(data)
	if encoded_c == nil || len(encoded_c) == 0 {
		return ""
	}
	defer webui_free(cast(rawptr) encoded_c)
	return encoded_c
}
decode :: proc(data : cstring) -> cstring {
	decoded_c := webui_decode(data)
	if decoded_c == nil || len(decoded_c) == 0 {
		return ""
	}
	defer webui_free(cast(rawptr) decoded_c)
	return decoded_c
}
clean :: proc() { webui_clean() }
delete_all_profiles :: proc() { webui_delete_all_profiles() }
delete_profile :: proc(win : Window) { webui_delete_profile(win) }
get_parent_process_id :: proc(win : Window) -> c.size_t { return webui_get_parent_process_id(win) }
get_child_process_id :: proc(win : Window) -> c.size_t { return webui_get_child_process_id(win) }

// Note: Direct foreign function imports are available with webui_ prefix
// Wrapper functions provide a more idiomatic Odin API
