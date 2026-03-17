# Odin + WebUI + Angular Integration

This project demonstrates integrating **Odin** system programming language with **WebUI** library and an **Angular** frontend, creating a powerful desktop application architecture.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Angular Frontend                         │
│  (TypeScript, Components, Services, RxJS)                   │
│                                                              │
│  ┌────────────────┐         ┌──────────────────┐            │
│  │  Components    │ ◄─────► │   WebUI Service  │            │
│  │  (UI/UX)       │         │   (Communication)│            │
│  └────────────────┘         └────────┬─────────┘            │
└─────────────────────────────────────┼───────────────────────┘
                                      │
                         webui.js (JavaScript Bridge)
                                      │
┌─────────────────────────────────────┼───────────────────────┐
│                          WebUI Library                       │
│  (Browser Management, Binary Communication)                 │
└─────────────────────────────────────┬───────────────────────┘
                                      │
                         Native FFI Bindings
                                      │
┌─────────────────────────────────────┼───────────────────────┐
│                       Odin Backend                           │
│  (System Programming, Business Logic, Performance)          │
│                                                              │
│  ┌────────────────┐         ┌──────────────────┐            │
│  │  webui.odin    │         │   main.odin      │            │
│  │  (FFI Wrapper) │         │  (Application)   │            │
│  └────────────────┘         └──────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
odin-webui-angular-rspack/
├── main.odin                    # Main Odin application
├── main_example.odin            # Example Odin application
├── webui.odin                   # Odin FFI bindings for WebUI
├── build.sh                     # Build script
├── README_WEBUI_INTEGRATION.md  # This file
│
├── lib/                         # Compiled libraries
│   ├── libwebui-2-static.a
│   └── libwebui-2.so
│
├── frontend/                    # Angular application
│   ├── src/
│   │   ├── core/
│   │   │   └── webui/
│   │   │       ├── index.ts
│   │   │       ├── webui.service.ts
│   │   │       └── webui-demo.component.ts
│   │   └── ...
│   └── dist/                    # Built Angular app
│
└── thirdparty/
    ├── webui/                   # WebUI library (C)
    │   ├── include/
    │   │   └── webui.h
    │   ├── src/
    │   ├── bridge/
    │   │   └── webui.js
    │   └── dist/
    └── v-webui/                 # V language wrapper (reference)
```

## Features

- **Bidirectional Communication**: Angular ↔ Odin via WebUI
- **Type-Safe FFI**: Odin bindings for WebUI C API
- **Modern Frontend**: Angular 19 with Rspack bundler
- **Lightweight**: Small memory footprint, fast startup
- **Cross-Platform**: Windows, macOS, Linux support
- **Browser Choice**: Use any installed browser as GUI

## Quick Start

### Prerequisites

1. **Odin Compiler**: [Install Odin](https://odin-lang.org/docs/install/)
2. **Node.js** v18+ or **Bun** v1.3+
3. **GCC/Clang** for building WebUI library
4. **Web Browser** (Chrome, Firefox, Edge, etc.)

### Build Everything

```bash
# Make build script executable
chmod +x build.sh

# Run build
./build.sh
```

### Run the Application

```bash
# Run main application
./app

# Or run example
./app_example
```

## Usage Examples

### Odin Backend - Basic Example

```odin
package main

import "core:fmt"
import "./webui"

my_window : webui.Window

// Callback for handling frontend events
handle_greet :: proc(e : ^webui.Event) {
    name := webui.event_get_string(e)
    fmt.printf("Received: %s\n", name)
    
    response := fmt.Sprintf("Hello %s from Odin!", name)
    webui.event_return_string(e, response)
}

main :: proc() {
    my_window = webui.new_window()
    webui.bind(my_window, "greet", handle_greet)
    
    html := `<html>
        <head><script src="webui.js"></script></head>
        <body>
            <button onclick="webui.greet('World')">Click Me</button>
        </body>
    </html>`
    
    webui.show(my_window, html)
    webui.wait()
}
```

### Angular Service - Call Odin Backend

```typescript
import { WebUIService } from './core/webui';

constructor(private webui: WebUIService) {}

async sendToBackend() {
  // Call Odin function and get response
  const response = await this.webui.send<string>('greet', 'Angular Developer');
  console.log(response.data); // "Hello Angular Developer from Odin!"
}

// Subscribe to backend events
this.webui.on('backend:message', (data) => {
  console.log('Message from Odin:', data);
});
```

### Angular Component - Full Example

```typescript
import { Component } from '@angular/core';
import { WebUIService } from './core/webui';

@Component({
  selector: 'app-demo',
  template: `
    <input [(ngModel)]="name" placeholder="Enter name">
    <button (click)="sendGreeting()">Send to Odin</button>
    <div>{{ response }}</div>
  `
})
export class DemoComponent {
  name = '';
  response = '';

  constructor(private webui: WebUIService) {}

  async sendGreeting() {
    const result = await this.webui.send('greet', this.name);
    this.response = result.data;
  }
}
```

## WebUI API Reference (Odin)

### Window Management

```odin
// Create new window
window := webui.new_window()

// Show window with HTML content
webui.show(window, "<html>...</html>")

// Show in specific browser
webui.show_browser(window, "<html>...</html>", .Chrome)

// Set window size
webui.set_size(window, 1200, 800)

// Close/destroy
webui.close(window)
webui.destroy(window)

// Wait for all windows to close
webui.wait()
```

### Event Binding

```odin
// Define callback
my_callback :: proc(e : ^webui.Event) {
    data := webui.event_get_string(e)
    webui.event_return_string(e, "Response")
}

// Bind to HTML element
webui.bind(window, "myFunction", my_callback)
```

### Event Data Access

```odin
my_handler :: proc(e : ^webui.Event) {
    // Get arguments
    str := webui.event_get_string(e)
    num := webui.event_get_int(e)
    bool := webui.event_get_bool(e)
    
    // Get by index
    str_at := webui.event_get_string_at(e, 1)
    
    // Return values
    webui.event_return_string(e, "text response")
    webui.event_return_int(e, 42)
    webui.event_return_bool(e, true)
}
```

### JavaScript Execution

```odin
// Run JavaScript (fire and forget)
webui.run(window, "document.title = 'New Title'")

// Run JavaScript and get result
buffer := make([]u8, 1024)
success := webui.script(window, "return 2 + 2", 1000, buffer)

// Navigate to URL
webui.navigate(window, "https://example.com")
```

## Configuration Options

### Window Configuration

```odin
// Set timeout for browser startup
webui.set_timeout(30)

// Set root folder for static files
webui.set_root_folder(window, "/path/to/frontend/dist")

// Enable kiosk mode (fullscreen)
webui.set_kiosk(window, true)

// Set custom profile
webui.set_profile(window, "my_profile", "/path/to/profile")

// Set proxy
webui.set_proxy(window, "http://proxy:8080")

// Set custom port
webui.set_port(window, 8080)
```

### Browser Selection

```odin
// Available browsers
Browser :: enum c.int {
    No_Browser      = 0,
    Any             = 1,
    Chrome          = 2,
    Firefox         = 3,
    Edge            = 4,
    Safari          = 5,
    Chromium        = 6,
    Opera           = 7,
    Brave           = 8,
    Vivaldi         = 9,
    Epic            = 10,
    Yandex          = 11,
    Chromium_Based  = 12,
}
```

## Building for Production

### Linux

```bash
# Build WebUI static library
cd thirdparty/webui
make clean && make

# Build Odin application
odin build main.odin \
    -out:app \
    -extra-linker-flags:"-Lthirdparty/webui/dist -lwebui-2-static -lpthread -lm -ldl" \
    -extra-include-dirs:thirdparty/webui/include \
    -o:speed

# Build Angular
cd frontend
npm run build:rspack

# Copy webui.js
cp ../thirdparty/webui/bridge/webui.js dist/
```

### Windows (PowerShell)

```powershell
# Build WebUI
cd thirdparty\webui
mingw32-make

# Build Odin
odin build main.odin `
    -out:app.exe `
    -extra-linker-flags:"-Lthirdparty\webui\dist -lwebui-2-static -lws2_32 -lole32" `
    -extra-include-dirs:thirdparty\webui\include

# Build Angular
cd frontend
npm run build:rspack
```

### macOS

```bash
# Build WebUI
cd thirdparty/webui
make

# Build Odin
odin build main.odin \
    -out:app \
    -extra-linker-flags:"-Lthirdparty/webui/dist -lwebui-2-static -lpthread -lm" \
    -extra-include-dirs:thirdparty/webui/include

# Build Angular
cd frontend
npm run build:rspack
```

## Debugging

### Enable WebUI Logging

```bash
# Build WebUI with logging
cd thirdparty/webui
make WEBUI_LOG=1
```

### Odin Debug Build

```odin
odin build main.odin -debug -extra-linker-flags:"..."
```

### Angular Debug Mode

```typescript
// In Angular component
constructor(private webui: WebUIService) {
  console.log('WebUI available:', this.webui.isAvailable());
}
```

## Performance Tips

1. **Use Static Library**: Link against `libwebui-2-static.a` for single binary
2. **Minimize FFI Calls**: Batch data transfers
3. **Async Communication**: Use promises in Angular for non-blocking calls
4. **Binary Data**: Use `webui_send_raw` for large data transfers
5. **Production Build**: Use `-o:speed` flag for Odin optimization

## Security Considerations

1. **Input Validation**: Always validate data from frontend
2. **CORS**: Configure properly for network access
3. **HTTPS**: Use TLS for production deployments
4. **Profile Isolation**: Use separate browser profiles per app
5. **Content Security Policy**: Set appropriate CSP headers

## Troubleshooting

### "WebUI not available" in Angular

Ensure `webui.js` is loaded:
```html
<head>
  <script src="webui.js"></script>
</head>
```

### Odin build fails with linker errors

Verify library paths:
```bash
ls thirdparty/webui/dist/
# Should show: libwebui-2-static.a libwebui-2.so
```

### Browser doesn't open

Check browser installation and timeout:
```odin
webui.set_timeout(60)  // Increase timeout to 60 seconds
```

## Additional Resources

- [WebUI Official Docs](https://webui.me/docs/)
- [WebUI GitHub](https://github.com/webui-dev/webui)
- [Odin Language](https://odin-lang.org/)
- [Angular Documentation](https://angular.dev/)

## License

This integration project is provided as-is under the same license as WebUI (MIT).
