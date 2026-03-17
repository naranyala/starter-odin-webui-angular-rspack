# Build System Documentation

## Overview

The build system automates the compilation and packaging of the Odin backend, Angular frontend, and WebUI library into a complete desktop application.

## Build Script

The main build script is `run.sh`, which provides a unified interface for all build operations.

### Usage

```bash
# Build all components
./run.sh build

# Build and run
./run.sh

# Run built application
./run.sh run

# Development mode (Angular dev server)
./run.sh dev

# Clean build artifacts
./run.sh clean

# Run tests
./run.sh test

# Show help
./run.sh help
```

### Commands

| Command | Description |
|---------|-------------|
| `build` | Build all components (WebUI, Angular, Odin) |
| `run` | Run the built application |
| `dev` | Start development mode with Angular dev server |
| `clean` | Remove all build artifacts |
| `test` | Run tests |
| `help` | Show help message |

### Options

| Option | Description |
|--------|-------------|
| `--verbose` | Enable verbose output |
| `--debug` | Build in debug mode |
| `--release` | Build in release mode (default) |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VERBOSE` | 0 | Enable verbose output |
| `DEBUG` | 0 | Build in debug mode |
| `RELEASE` | 1 | Build in release mode |

## Build Process

### Step 1: Check Requirements

The build script verifies all required tools are available:

```bash
[STEP] Checking Requirements
[OK] Odin: odin version dev-2025-04
[OK] GCC: gcc (GCC) 13.2.0
[OK] Bun: v1.0.0
[OK] Make: GNU Make 4.4
```

Required tools:
- Odin compiler
- GCC or Clang (for WebUI)
- Bun or Node.js (for Angular)
- Make

### Step 2: Build WebUI Library

```bash
[STEP] Building WebUI Library
Build WebUI library (gcc  release static)...
Build WebUI library (gcc  release dynamic)...
Done.
[OK] Static library: dist/libwebui-2-static.a
[OK] Dynamic library: dist/libwebui-2.so
[OK] WebUI library built successfully
```

Output:
- `thirdparty/webui/dist/libwebui-2-static.a` - Static library
- `thirdparty/webui/dist/libwebui-2.so` - Dynamic library

### Step 3: Build Angular Frontend

```bash
[STEP] Building Angular Frontend
Installing dependencies...
Building Angular application...
asset main.js 65.6 KiB [emitted]
asset angular.js 448 KiB [emitted]
[OK] Angular build output: frontend/dist/
[OK] Angular frontend built successfully
```

Output:
- `frontend/dist/` - Production build output
- `frontend/dist/webui.js` - WebUI JavaScript bridge

### Step 4: Build Odin Application

```bash
[STEP] Building Odin Application
Building main.odin...
[OK] Built: build/odin-webui-app
[OK] Odin application built successfully
```

Output:
- `build/odin-webui-app` - Main application binary
- `build/build.log` - Build log

### Step 5: Create Distribution Package

```bash
[STEP] Creating Distribution Package
[OK] Copied application binary
[OK] Copied Angular frontend
[OK] Copied webui.js
[OK] Distribution package created: dist/
```

Output:
- `dist/odin-webui-app` - Application binary
- `dist/frontend/` - Angular build
- `dist/lib/` - Shared libraries
- `dist/webui.js` - WebUI JavaScript bridge

## Build Output Structure

```
build/
├── odin-webui-app      # Main application binary
├── di_demo             # DI demonstration
└── build.log           # Build log

dist/
├── odin-webui-app      # Application binary
├── frontend/           # Angular build output
│   ├── index.html
│   ├── main.js
│   ├── angular.js
│   └── ...
├── lib/                # Shared libraries
│   └── libwebui-2.so
├── webui.js            # WebUI JavaScript bridge
└── README.txt          # Distribution readme
```

## Build Configuration

### Odin Build Flags

```bash
# Release build (default)
odin build . -out:app -o:speed -no-bounds-check

# Debug build
odin build . -out:app -debug -g

# With custom linker flags
odin build . -out:app \
    -extra-linker-flags:"-L./thirdparty/webui/dist -lwebui-2-static -lpthread -lm -ldl"
```

### Angular Build Configuration

```json
// angular.json
{
  "build": {
    "options": {
      "outputPath": "dist",
      "optimization": true,
      "sourceMap": false,
      "extractLicenses": false
    }
  }
}
```

### WebUI Build Configuration

```bash
# Build static library
make static

# Build dynamic library
make dynamic

# Clean
make clean
```

## Development Mode

Development mode runs the Angular dev server with hot reload:

```bash
./run.sh dev
```

This starts:
- Angular dev server on http://localhost:4200
- File watching for changes
- Hot module replacement

## Cleaning Build Artifacts

```bash
./run.sh clean
```

Removes:
- `build/` directory
- `dist/` directory
- `frontend/dist/` directory
- `frontend/node_modules/` directory
- WebUI build output
- Odin cache

## Troubleshooting

### Odin Compiler Not Found

```
[ERROR] Odin compiler not found
```

Solution: Install Odin or add it to PATH:
```bash
export PATH=$PATH:/path/to/odin
```

### WebUI Build Fails

```
[ERROR] Failed to build WebUI library
```

Solution: Install build dependencies:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# Fedora
sudo dnf install gcc make
```

### Angular Build Fails

```
[ERROR] Angular build failed
```

Solution: Install dependencies:
```bash
cd frontend
bun install
# or
npm install
```

### Linker Errors

```
undefined reference to webui_new_window
```

Solution: Ensure WebUI library is built and linker flags are correct:
```bash
# Rebuild WebUI
cd thirdparty/webui
make clean
make

# Rebuild application
./run.sh build
```

## Custom Build Scripts

### Build Only Odin

```bash
#!/bin/bash
odin build . \
    -out:build/app \
    -extra-linker-flags:"-L./thirdparty/webui/dist -lwebui-2-static -lpthread" \
    -o:speed
```

### Build Only Angular

```bash
#!/bin/bash
cd frontend
bun run build:rspack
```

### Build Only WebUI

```bash
#!/bin/bash
cd thirdparty/webui
make clean
make
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Odin
      run: |
        wget https://github.com/odin-lang/Odin/releases/download/dev-2025-04/odin-linux-amd64-dev-2025-04.tar.gz
        tar -xzf odin-linux-amd64-dev-2025-04.tar.gz
        echo "$PWD/odin" >> $GITHUB_PATH
    
    - name: Install Bun
      run: curl -fsSL https://bun.sh/install | bash
    
    - name: Build
      run: ./run.sh build
    
    - name: Test
      run: ./run.sh test
```

## Performance Tips

1. **Use Release Mode**: `-o:speed` flag optimizes for speed
2. **Disable Bounds Checking**: `-no-bounds-check` for production
3. **Parallel Builds**: Build Angular and WebUI in parallel
4. **Cache Dependencies**: Cache `node_modules` and WebUI build

## See Also

- `run.sh` - Main build script
- `build.sh` - Legacy build script
- `frontend/angular.json` - Angular configuration
- `thirdparty/webui/Makefile` - WebUI build configuration
