# Build System Documentation

## Overview

The build system automates compilation of Odin backend, Angular frontend, and WebUI library.

## Build Script

```bash
./run.sh build    # Build all components
./run.sh run      # Run application
./run.sh dev      # Development mode
./run.sh clean    # Clean build artifacts
./run.sh test     # Run tests
./run.sh help     # Show help
```

## Build Process

### 1. Requirements Check

- Odin compiler (dev-2025-04 or later)
- GCC or Clang
- Bun or Node.js
- Make

### 2. WebUI Library Build

```bash
cd thirdparty/webui
make clean && make
```

Output:
- `dist/libwebui-2-static.a` - Static library
- `dist/libwebui-2.so` - Dynamic library

### 3. Angular Frontend Build

```bash
cd frontend
bun install
bun run build:rspack
```

Output:
- `frontend/dist/` - Production bundle

### 4. Odin Backend Build

```bash
odin build src/core \
    -out:build/odin-webui-app \
    -extra-linker-flags:"-Lthirdparty/webui/dist -lwebui-2-static -lpthread -lm -ldl" \
    -o:speed
```

Output:
- `build/odin-webui-app` - Application binary

### 5. Distribution Package

```
dist/
├── odin-webui-app
├── frontend/
└── lib/
```

## Build Options

| Option | Description |
|--------|-------------|
| `--verbose` | Enable verbose output |
| `--debug` | Build in debug mode |
| `--release` | Build in release mode (default) |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VERBOSE` | 0 | Enable verbose output |
| `DEBUG` | 0 | Build in debug mode |
| `RELEASE` | 1 | Build in release mode |

## Troubleshooting

### Odin Compiler Not Found

```bash
odin version
export PATH=$PATH:/path/to/odin
```

### WebUI Build Fails

```bash
gcc --version
sudo apt-get install build-essential
```

### Linker Errors

```bash
ls -la thirdparty/webui/dist/
cd thirdparty/webui && make clean && make
```

## Build Outputs

| Component | Location | Size |
|-----------|----------|------|
| Odin Backend | `build/odin-webui-app` | ~300-500 KB |
| Angular Frontend | `frontend/dist/` | 500 KB - 2 MB |
| WebUI Library | `thirdparty/webui/dist/` | ~300 KB |

## See Also

- [README.md](../README.md) - Main documentation
- [07_WEBUI_INTEGRATION_EVALUATION.md](07_WEBUI_INTEGRATION_EVALUATION.md) - WebUI details
