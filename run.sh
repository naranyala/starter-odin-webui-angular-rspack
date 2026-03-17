#!/bin/bash
# Build and Run script for Odin + WebUI + Angular
# 
# Usage:
#   ./run.sh              # Build (if needed) and run
#   ./run.sh --build     # Build only
#   ./run.sh --run       # Run only (must be already built)
#   ./run.sh --help      # Show help

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

BUILD_DIR="$SCRIPT_DIR/build"

print_step() { echo -e "${GREEN}[STEP]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
ACTION="both"
while [[ $# -gt 0 ]]; do
    case $1 in
        --build) ACTION="build" ;;
        --run) ACTION="run" ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --build    Build only (Angular + Odin)"
            echo "  --run      Run only (must be built)"
            echo "  --help     Show this help"
            exit 0
            ;;
    esac
    shift
done

# Build Angular frontend
build_angular() {
    print_step "Building Angular frontend..."
    
    cd "$SCRIPT_DIR/frontend"
    
    if [ ! -d "node_modules" ]; then
        if command -v bun &> /dev/null; then
            bun install
        else
            npm install
        fi
    fi
    
    if command -v bun &> /dev/null; then
        bun run build
    else
        npm run build
    fi
    
    cd "$SCRIPT_DIR"
    echo "  ✓ Angular built"
}

# Build Odin app
build_odin() {
    print_step "Building Odin application..."
    
    mkdir -p "$BUILD_DIR"
    
    odin build . \
        -out:"$BUILD_DIR/app" \
        -extra-linker-flags:"-L./lib" \
        -o:speed
    
    echo "  ✓ Odin app built: $BUILD_DIR/app"
}

# Copy dependencies
copy_deps() {
    print_step "Copying dependencies..."
    
    # Copy WebUI library
    if [ -f "lib/libwebui-2.so" ]; then
        cp lib/libwebui-2.so "$BUILD_DIR/"
    fi
    
    # Copy Angular frontend
    if [ -d "frontend/dist/browser" ]; then
        mkdir -p "$BUILD_DIR/frontend"
        cp -r frontend/dist/browser/* "$BUILD_DIR/frontend/"
    fi
    
    echo "  ✓ Dependencies copied"
}

# Run the app
run_app() {
    cd "$BUILD_DIR"
    
    if [ ! -f "app" ]; then
        print_error "App not built. Run: $0 --build"
        exit 1
    fi
    
    if [ ! -f "libwebui-2.so" ]; then
        print_error "WebUI library not found. Run: $0 --build"
        exit 1
    fi
    
    export LD_LIBRARY_PATH="$BUILD_DIR:$LD_LIBRARY_PATH"
    
    if [ -n "$DISPLAY" ]; then
        ./app
    else
        echo "No DISPLAY set. Starting Xvfb..."
        Xvfb :99 -screen 0 1024x768x24 &
        XVFB_PID=$!
        export DISPLAY=:99
        trap "kill $XVFB_PID 2>/dev/null" EXIT
        ./app
    fi
}

# Main
echo
echo "=============================================="
echo "  Odin + WebUI + Angular Runner"
echo "=============================================="
echo

if [ "$ACTION" = "build" ] || [ "$ACTION" = "both" ]; then
    build_angular
    build_odin
    copy_deps
    
    echo
    echo "=============================================="
    echo -e "${GREEN}  Build Complete!${NC}"
    echo "=============================================="
fi

if [ "$ACTION" = "run" ] || [ "$ACTION" = "both" ]; then
    if [ ! -f "$BUILD_DIR/app" ]; then
        print_error "App not built. Run: $0 --build"
        exit 1
    fi
    echo
    echo "Running application..."
    run_app
fi
