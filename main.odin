// Odin + WebUI + Angular Integration
package main

import "core:fmt"
import "core:os"
import webui "./webui_lib"

main :: proc() {
	fmt.println("Starting Odin + WebUI + Angular...")
	
	// Find the path to Angular dist (relative to build/ directory)
	paths := []string{
		"frontend",
		"../frontend/dist/browser",
	}
	
	angular_path := ""
	
	for p in paths {
		if os.exists(p) {
			angular_path = p
			fmt.println("Found Angular at:", p)
			break
		}
	}
	
	if angular_path == "" {
		fmt.println("Could not find Angular frontend")
		return
	}
	
	// Create window
	win := webui.new_window()
	webui.set_size(win, 1200, 800)
	
	// Set root folder for WebUI to serve static files
	webui.set_root_folder(win, "frontend")
	
	// Navigate to index.html
	result := webui.show(win, cstring("index.html"))
	
	fmt.println("webui.show result:", result)
	
	fmt.println("Window open - Ctrl+C to exit")
	webui.wait()
	fmt.println("Done")
}
