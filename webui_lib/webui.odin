package webui

import "core:c"

WEBUI_VERSION :: "2.5.0"

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

Event :: struct {
	window : c.size_t, 
	event_type : Event_Type, 
	element : cstring,
	event_number : c.size_t, 
	bind_id : c.size_t,
}

Event_Callback :: proc "c" (e : ^Event)
Window :: c.size_t

foreign import webui_lib "system:webui-2"

foreign webui_lib {
	webui_new_window   :: proc() -> c.size_t ---
	webui_show         :: proc(win : c.size_t, content : cstring) -> bool ---
	webui_show_browser :: proc(win : c.size_t, content : cstring, browser : Browser) -> bool ---
	webui_close        :: proc(win : c.size_t) ---
	webui_destroy      :: proc(win : c.size_t) ---
	webui_exit_app     :: proc() ---
	webui_wait         :: proc() ---
	
	webui_set_size     :: proc(win : c.size_t, width : c.int, height : c.int) ---
	webui_set_resizable :: proc(win : c.size_t, resizable : bool) ---
	
	webui_bind         :: proc(win : c.size_t, element : cstring, callback : Event_Callback) -> bool ---
	webui_unbind       :: proc(win : c.size_t, element : cstring) -> bool ---
	
	webui_run          :: proc(win : c.size_t, script : cstring) ---
	webui_navigate     :: proc(win : c.size_t, url : cstring) -> bool ---
	webui_get_url      :: proc(win : c.size_t) -> cstring ---
	
	webui_set_root_folder :: proc(win : c.size_t, path : cstring) ---
	
	webui_return_string :: proc(e : ^Event, response : cstring) ---
	webui_return_int    :: proc(e : ^Event, response : c.int) ---
	webui_return_bool   :: proc(e : ^Event, response : bool) ---
	
	webui_encode       :: proc(data : cstring) -> cstring ---
	webui_decode       :: proc(data : cstring) -> cstring ---
	
	webui_get_string   :: proc(e : ^Event) -> cstring ---
	webui_get_int      :: proc(e : ^Event) -> c.int ---
	webui_get_bool     :: proc(e : ^Event) -> bool ---
	webui_get_float    :: proc(e : ^Event) -> c.double ---
}

new_window :: proc() -> Window {
	return Window(webui_new_window())
}

show :: proc(win : Window, content : cstring) -> bool {
	return webui_show(c.size_t(win), content)
}

show_browser :: proc(win : Window, content : cstring, browser : Browser) -> bool {
	return webui_show_browser(c.size_t(win), content, browser)
}

close :: proc(win : Window) {
	webui_close(c.size_t(win))
}

exit :: proc() {
	webui_exit_app()
}

wait :: proc() {
	webui_wait()
}

set_size :: proc(win : Window, width : int, height : int) {
	webui_set_size(c.size_t(win), c.int(width), c.int(height))
}

bind :: proc(win : Window, element : cstring, callback : Event_Callback) -> bool {
	return webui_bind(c.size_t(win), element, callback)
}

return_string :: proc(e : ^Event, response : cstring) {
	webui_return_string(e, response)
}

get_string :: proc(e : ^Event) -> cstring {
	return webui_get_string(e)
}

set_root_folder :: proc(win : Window, path : cstring) {
	webui_set_root_folder(c.size_t(win), path)
}
