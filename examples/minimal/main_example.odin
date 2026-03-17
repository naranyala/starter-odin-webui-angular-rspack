// Odin + WebUI - Minimal Example
package main

import "core:fmt"
import "core:c"
import webui "../../webui_lib"

my_window : webui.Window

greet_callback :: proc "c" (e : ^webui.Event) {
	name_c := webui.webui_get_string(e)
	if name_c != nil {
		name_str := cast(string) name_c
		fmt.printf("Received from JavaScript: %s\n", name_str)
		response_str := "Hello from Odin backend!"
		webui.webui_return_string(e, response_str)
	}
}

button_click_callback :: proc "c" (e : ^webui.Event) {
	fmt.println("Button clicked!")
	webui.run(my_window, `document.getElementById('status').innerHTML = 'Clicked!';`)
}

counter_value : i64
counter_callback :: proc "c" (e : ^webui.Event) {
	counter_value += 1
	fmt.printf("Counter: %d\n", counter_value)
}

main :: proc() {
	fmt.println("Starting Odin + WebUI Application...")

	my_window = webui.new_window()

	webui.bind(my_window, "greet", greet_callback)
	webui.bind(my_window, "buttonClick", button_click_callback)
	webui.bind(my_window, "increment", counter_callback)

	html_content := `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Odin + WebUI</title>
    <style>
        body { font-family: system-ui; background: linear-gradient(135deg, #667eea, #764ba2);
               min-height: 100vh; display: flex; justify-content: center; align-items: center; }
        .container { background: white; border-radius: 20px; padding: 40px; 
                     box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 500px; }
        h1 { color: #333; text-align: center; }
        input { width: 100%; padding: 12px; border: 2px solid #e0e0e0; border-radius: 8px; margin-bottom: 15px; }
        button { width: 100%; padding: 12px; background: linear-gradient(135deg, #667eea, #764ba2);
                 color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; margin-top: 10px; }
        .result { margin-top: 15px; padding: 15px; background: #f5f5f5; border-radius: 8px; text-align: center; }
        .counter { text-align: center; padding: 20px; background: #f8f9fa; border-radius: 12px; margin-top: 20px; }
        .counter-display { font-size: 48px; font-weight: bold; color: #667eea; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🦉 Odin + WebUI</h1>
        <input type="text" id="nameInput" value="Developer">
        <button onclick="sendToOdin()">Send to Odin</button>
        <div class="result" id="greetingResult">Response will appear here</div>
        
        <button onclick="clickButton()" style="background: linear-gradient(135deg, #f093fb, #f5576c);">Click Me!</button>
        <div id="status"></div>
        
        <div class="counter">
            <div class="counter-display" id="counterDisplay">0</div>
            <button onclick="incrementCounter()" style="background: linear-gradient(135deg, #4facfe, #00f2fe);">Increment</button>
        </div>
    </div>
    <script>
        async function sendToOdin() {
            const name = document.getElementById('nameInput').value;
            const result = await webui.greet(name);
            document.getElementById('greetingResult').innerHTML = result;
        }
        function clickButton() { webui.buttonClick(); }
        async function incrementCounter() {
            const result = await webui.increment();
            document.getElementById('counterDisplay').innerHTML = result;
        }
    </script>
</body>
</html>
	`

	if !webui.show(my_window, html_content) {
		fmt.println("Failed to show window!")
		return
	}

	fmt.println("Window opened. Waiting for events...")
	webui.wait()
	fmt.println("Application closed.")
}
