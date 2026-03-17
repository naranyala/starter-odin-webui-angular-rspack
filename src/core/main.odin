// Odin + WebUI + Angular Integration - Main Application
package main

import "core:fmt"
import webui "../lib/webui_lib"

// Global window
my_window : webui.Window

// Event handlers
handle_greet :: proc "c" (e : ^webui.Event) {
    name_str := webui.event_get_string(e)
    if name_str != "" {
        fmt.printf("[Odin Backend] Received greeting from: %s\n", name_str)
        response_str := "Hello from Odin backend!"
        webui.event_return_string(e, response_str)
    }
}

handle_data :: proc "c" (e : ^webui.Event) {
    data_str := webui.event_get_string(e)
    if data_str != "" {
        fmt.printf("[Odin Backend] Received data: %s\n", data_str)
        response_str := "Processed in Odin!"
        webui.event_return_string(e, response_str)
    }
}

main :: proc() {
    fmt.println("===========================================")
    fmt.println("  Odin + WebUI + Angular Application")
    fmt.println("===========================================")
    fmt.println()

    // Create window
    my_window = webui.new_window()
    webui.set_size(my_window, 1200, 800)

    // Bind events
    webui.bind(my_window, "greet", handle_greet)
    webui.bind(my_window, "sendData", handle_data)

    // HTML content
    html_content := `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Odin + Angular WebUI</title>
    <style>
        body { 
            font-family: system-ui; 
            background: linear-gradient(135deg, #1e3c72, #2a5298);
            min-height: 100vh; 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            margin: 0; 
        }
        .container { 
            background: white; 
            border-radius: 16px; 
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3); 
            max-width: 600px; 
            width: 100%; 
        }
        h1 { color: #1e3c72; }
        input { 
            width: 100%; 
            padding: 12px; 
            border: 2px solid #e0e0e0; 
            border-radius: 8px;
            font-size: 16px; 
            margin-bottom: 15px; 
        }
        button { 
            width: 100%; 
            padding: 14px; 
            background: linear-gradient(135deg, #1e3c72, #2a5298);
            color: white; 
            border: none; 
            border-radius: 8px; 
            font-size: 16px; 
            cursor: pointer; 
        }
        .result { 
            margin-top: 20px; 
            padding: 15px; 
            background: #f5f5f5; 
            border-radius: 8px; 
            text-align: center; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🦉 Odin + Angular</h1>
        <input type="text" id="nameInput" placeholder="Enter your name..." value="Angular Developer">
        <button onclick="sendGreeting()">Send to Odin Backend</button>
        <div class="result" id="result">Response will appear here</div>
    </div>
    <script>
        async function sendGreeting() {
            const name = document.getElementById('nameInput').value;
            const resultEl = document.getElementById('result');
            resultEl.innerHTML = '⏳ Sending to Odin...';
            try {
                const response = await webui.greet(name);
                resultEl.innerHTML = '✅ ' + response;
            } catch (err) {
                resultEl.innerHTML = '❌ Error: ' + err;
            }
        }
    </script>
</body>
</html>
	`

    if !webui.show(my_window, html_content) {
        fmt.println("Failed to show window!")
        return
    }

    fmt.println("Window opened. Press Ctrl+C to exit.")
    webui.wait()
    fmt.println("Application closed.")
}
