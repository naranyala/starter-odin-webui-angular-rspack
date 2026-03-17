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
| `test` | Run test suites |
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

The build pipeline executes the following steps:

### 1. Requirements Check

Verifies all required tools are installed:

- Odin compiler
- GCC or Clang
- Bun or Node.js
- Make

### 2. WebUI Library Build

Compiles the WebUI library from source:

```bash
cd thirdparty/webui
make clean
make
```

Output:
- `dist/libwebui-2-static.a` - Static library
- `dist/libwebui-2.so` - Dynamic library (Linux)

### 3. Angular Frontend Build

Builds the Angular application:

```bash
cd frontend
bun install  # If node_modules missing
bun run build:rspack
```

Output:
- `frontend/dist/` - Production bundle

### 4. Odin Backend Build

Compiles the Odin application:

```bash
odin build src/core \
    -out:build/odin-webui-app \
    -extra-linker-flags:"-Lthirdparty/webui/dist -lwebui-2-static -lpthread -lm -ldl" \
    -o:speed \
    -no-bounds-check
```

Output:
- `build/odin-webui-app` - Application binary
- `build/di_demo` - DI demonstration

### 5. Distribution Package

Creates deployable package:

```
dist/
├── odin-webui-app      # Application binary
├── frontend/           # Angular build output
├── lib/                # Shared libraries
└── README.txt          # Distribution info
```

## Build Configuration

### Debug Build

```bash
./run.sh build --debug
```

Or set environment variable:

```bash
DEBUG=1 ./run.sh build
```

### Release Build

```bash
./run.sh build --release
```

Or set environment variable:

```bash
RELEASE=1 ./run.sh build
```

### Verbose Output

```bash
./run.sh build --verbose
```

Or set environment variable:

```bash
VERBOSE=1 ./run.sh build
```

## Build Outputs

### Development Build

```
build/
├── odin-webui-app      # Main application (debug symbols)
├── di_demo             # DI demonstration
└── build.log           # Build log
```

### Distribution Package

```
dist/
├── odin-webui-app      # Main application
├── frontend/           # Angular production bundle
│   ├── index.html
│   ├── *.js
│   └── *.css
├── lib/
│   └── libwebui-2.so   # Shared library (Linux)
└── README.txt          # Distribution readme
```

## Customization

### Modify Build Flags

Edit `run.sh` to customize build flags:

```bash
# In build_odin() function
local build_flags="-o:speed"  # Optimize for speed

# For debug
local build_flags="-debug -g"

# For size optimization
local build_flags="-o:size"
```

### Add Custom Build Steps

Add custom steps in `run.sh`:

```bash
build_custom() {
    print_header "Building Custom Component"
    
    # Your custom build logic
    echo "Building custom component..."
    
    # Check for errors
    if [ $? -ne 0 ]; then
        print_error "Custom build failed"
        return 1
    fi
    
    print_step "Custom component built"
}
```

### Cross-Platform Builds

The build system supports multiple platforms:

#### Linux

```bash
./run.sh build
```

#### macOS

```bash
# May need to adjust linker flags for macOS
./run.sh build
```

#### Windows

```bash
# Use WSL or adjust paths for native Windows
./run.sh build
```

## Troubleshooting

### Odin Compiler Not Found

```bash
# Check Odin installation
odin version

# Add Odin to PATH
export PATH=$PATH:/path/to/odin
```

### WebUI Build Fails

```bash
# Check GCC installation
gcc --version

# Install build essentials (Ubuntu/Debian)
sudo apt-get install build-essential

# Install Xcode command line tools (macOS)
xcode-select --install
```

### Angular Build Fails

```bash
# Check Node.js/Bun installation
node --version
bun --version

# Clear node_modules and reinstall
cd frontend
rm -rf node_modules
bun install
```

### Linker Errors

```bash
# Check library paths
ls -la thirdparty/webui/dist/

# Rebuild WebUI library
cd thirdparty/webui
make clean
make
```

### Runtime Errors

```bash
# Set library path (Linux)
export LD_LIBRARY_PATH=thirdparty/webui/dist:$LD_LIBRARY_PATH

# Run application
./build/odin-webui-app
```

## Performance Optimization

### Build Time Optimization

1. **Use incremental builds**: Only rebuild changed components
2. **Enable caching**: Keep node_modules between builds
3. **Parallel builds**: Use multiple CPU cores

```bash
# Parallel make jobs
make -j$(nproc)
```

### Binary Size Optimization

```bash
# Optimize for size
odin build src/core -o:size -out:build/app

# Strip symbols
strip build/app
```

### Runtime Performance

```bash
# Optimize for speed
odin build src/core -o:speed -out:build/app

# Disable bounds checking (production only)
odin build src/core -o:speed -no-bounds-check -out:build/app
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
    - uses: actions/checkout@v2
    
    - name: Install Odin
      run: |
        # Install Odin compiler
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y build-essential
    
    - name: Build
      run: ./run.sh build
    
    - name: Test
      run: ./run.sh test
    
    - name: Upload artifact
      uses: actions/upload-artifact@v2
      with:
        name: application
        path: dist/
```

### GitLab CI Example

```yaml
stages:
  - build
  - test

build:
  stage: build
  script:
    - ./run.sh build
  artifacts:
    paths:
      - dist/

test:
  stage: test
  script:
    - ./run.sh test
```

## Build Metrics

### Typical Build Times

| Component | Time |
|-----------|------|
| WebUI Library | 5-10 seconds |
| Angular Frontend | 10-30 seconds |
| Odin Backend | 2-5 seconds |
| **Total** | **20-45 seconds** |

### Binary Sizes

| Component | Size |
|-----------|------|
| Odin Backend | 300-500 KB |
| Angular Frontend | 500 KB - 2 MB |
| WebUI Library | 300 KB |
| **Total** | **1-3 MB** |

## Advanced Usage

### Partial Builds

Build specific components:

```bash
# Build only WebUI
cd thirdparty/webui && make

# Build only Angular
cd frontend && bun run build:rspack

# Build only Odin
odin build src/core -out:build/app
```

### Custom Distribution

Create custom distribution package:

```bash
./run.sh build

# Create custom package
mkdir -p custom_dist
cp build/odin-webui-app custom_dist/
cp -r frontend/dist custom_dist/web
cp thirdparty/webui/dist/*.so custom_dist/lib/
```

### Build with Custom Flags

```bash
# Custom Odin flags
odin build src/core \
    -out:build/app \
    -extra-linker-flags:"custom-flags" \
    -define:CUSTOM_FLAG \
    -debug
```

## See Also

- `README.md` - Project overview
- `docs/DI_SYSTEM.md` - Dependency injection
- `docs/COMMUNICATION_APPROACHES.md` - Communication patterns
- `src/README.md` - Source code structure
