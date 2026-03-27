# WebUI.js Integration Guide

## Overview

The Angular frontend is now properly integrated with WebUI.js for backend communication with the Odin application.

## Build Process

### Automatic Integration (Recommended)

When you run `bun run build` in the frontend folder, the following happens automatically:

1. **Angular Build** - Compiles the Angular application
2. **Postbuild Script** - Automatically patches the build output:
   - Builds `webui.js` from TypeScript source (if needed)
   - Copies `webui.js` to the dist folder
   - Patches `index.html` to include the webui.js script tag

### Manual Build Steps

If you need to run steps manually:

```bash
# 1. Build Angular
cd frontend
bun run build

# 2. Run postbuild script (auto-patches HTML)
bun run postbuild
```

## File Structure

```
frontend/
├── dist/browser/           # Build output
│   ├── index.html          # Patched with webui.js
│   ├── webui.js            # WebUI bridge (auto-copied)
│   ├── main-*.js           # Angular main bundle
│   ├── polyfills-*.js      # Angular polyfills
│   └── styles-*.css        # Angular styles
├── scripts/
│   └── postbuild.ts        # Postbuild integration script
└── thirdparty/webui/
    └── bridge/
        ├── webui.ts        # WebUI TypeScript source
        └── webui.js        # Compiled WebUI bridge
```

## How It Works

### 1. HTML Patching

The postbuild script automatically adds this to `index.html`:

```html
<head>
  <!-- ... other head elements ... -->
  <script src="webui.js"></script>
</head>
```

### 2. WebUI Bridge

The `webui.js` file provides the JavaScript bridge between Angular and the Odin backend:

```typescript
// Example: Call backend function
const response = await webui.myBackendFunction(arg1, arg2);
```

### 3. Backend Binding (Odin)

In your Odin backend, you bind functions like this:

```odin
package main

import webui "../lib/webui_lib"

handle_greet :: proc "c" (e : ^webui.Event) {
    name := webui.event_get_string(e)
    response := fmt.Sprintf("Hello, %s!", name)
    webui.event_return_string(e, response)
}

main :: proc() {
    win := webui.new_window()
    webui.bind(win, "greet", handle_greet)
    webui.show(win, "index.html")
    webui.wait()
}
```

## Verification

After building, verify the integration:

```bash
# Check if webui.js exists in dist
ls frontend/dist/browser/webui.js

# Check if index.html includes webui.js
grep "webui.js" frontend/dist/browser/index.html

# Should output: <script src="webui.js"></script>
```

## Running the Application

```bash
# From project root
./run.sh

# Or manually
cd build
./app
```

## Troubleshooting

### webui.js Not Found

If you see errors about webui.js not being found:

```bash
cd frontend
bun run postbuild
```

### Backend Functions Not Available

If frontend can't call backend functions:

1. Ensure functions are bound in Odin backend with `webui.bind()`
2. Check that function names match between frontend and backend
3. Verify the event handler signature is correct: `proc "c" (e : ^webui.Event)`

### Build Fails

If the build fails:

```bash
# Clean and rebuild
cd frontend
rm -rf dist
bun run build
```

## API Reference

### Frontend (TypeScript)

```typescript
// Call backend function
const result = await webui.functionName(arg1, arg2);

// Call with response handling
window.addEventListener('functionName_response', (event) => {
    console.log('Response:', event.detail);
});
```

### Backend (Odin)

```odin
// Get string parameter
name := webui.event_get_string(e)

// Get int parameter
value := webui.event_get_int(e)

// Return string
webui.event_return_string(e, "response")

// Return int
webui.event_return_int(e, 42)

// Run JavaScript in frontend
webui.run(win, "console.log('Hello from Odin')")
```

## Additional Resources

- [WebUI Documentation](https://webui.me)
- [WebUI GitHub](https://github.com/webui-dev/webui)
- [README_WEBUI_INTEGRATION.md](../README_WEBUI_INTEGRATION.md)
