#!/bin/bash
# Build and Run script for Odin + WebUI + Angular
#
# Usage:
#   ./run.sh              # Build (if needed) and run
#   ./run.sh dev          # Build frontend + backend, then run with WebUI window
#   ./run.sh build        # Build only
#   ./run.sh run          # Run only (must be already built)
#   ./run.sh --build     # Build only
#   ./run.sh --run       # Run only (must be already built)
#   ./run.sh --dev       # Build and run with WebUI window
#   ./run.sh --clean     # Clean build artifacts
#   ./run.sh --help      # Show help

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUILD_DIR="$SCRIPT_DIR/build"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Counters for summary
BUILD_START_TIME=$(date +%s)
ERRORS=0
WARNINGS=0

print_step() { echo -e "${GREEN}[STEP]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)) || true; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; ((ERRORS++)) || true; }

# Cleanup function for error handling
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Build failed with exit code $exit_code"
        print_error "Check the error messages above for details"
    fi
}

trap cleanup_on_error EXIT

# Parse arguments
ACTION="both"
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|development)
            ACTION="dev"
            ;;
        build)
            ACTION="build"
            ;;
        run)
            ACTION="run"
            ;;
        --build) ACTION="build" ;;
        --run) ACTION="run" ;;
        --dev|development) ACTION="dev" ;;
        --clean)
            print_step "Cleaning build artifacts..."
            rm -rf "$BUILD_DIR"
            rm -rf "$FRONTEND_DIR/dist"
            rm -rf "$FRONTEND_DIR/.angular"
            rm -rf "$FRONTEND_DIR/.rspack_cache"
            print_info "Clean complete"
            exit 0
            ;;
        --verbose|-v) VERBOSE=true ;;
        --help|-h)
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  dev        Build frontend + backend, then run with WebUI window"
            echo "  build      Build only (Angular + Odin)"
            echo "  run        Run only (must be built)"
            echo ""
            echo "Options:"
            echo "  --dev      Build and run with WebUI window"
            echo "  --build    Build only (Angular + Odin)"
            echo "  --run      Run only (must be built)"
            echo "  --clean    Clean all build artifacts"
            echo "  --verbose  Show detailed output"
            echo "  --help     Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 dev           # Build and run with WebUI window"
            echo "  $0 build         # Build everything"
            echo "  $0 run           # Run the application"
            echo "  $0 --clean       # Clean build artifacts"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
    shift
done

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check for Odin compiler
    if ! command -v odin &> /dev/null; then
        print_error "Odin compiler not found. Please install Odin first."
        exit 1
    fi
    print_info "✓ Odin compiler found: $(odin version 2>&1 | head -1)"
    
    # Check for Node.js/Bun
    if command -v bun &> /dev/null; then
        print_info "✓ Bun found: $(bun --version)"
    elif command -v node &> /dev/null; then
        print_info "✓ Node.js found: $(node --version)"
    else
        print_error "Neither Bun nor Node.js found. Please install one of them."
        exit 1
    fi
    
    # Check for C compiler (needed for WebUI)
    if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
        print_warn "No C compiler found. WebUI library must be pre-built."
    fi
}

# Build Angular frontend
build_angular() {
    print_step "Building Angular frontend..."
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_info "Installing dependencies..."
        if command -v bun &> /dev/null; then
            bun install || { print_error "Failed to install dependencies"; exit 1; }
        else
            npm install || { print_error "Failed to install dependencies"; exit 1; }
        fi
    fi
    
    # Build
    print_info "Building Angular application..."
    if command -v bun &> /dev/null; then
        bun run build || { print_error "Angular build failed"; exit 1; }
    else
        npm run build || { print_error "Angular build failed"; exit 1; }
    fi
    
    cd "$SCRIPT_DIR"
    print_info "✓ Angular build complete"
}

# Build Odin application
build_odin() {
    print_step "Building Odin application..."
    
    mkdir -p "$BUILD_DIR"
    
    # Check for main.odin
    if [ ! -f "$SCRIPT_DIR/main.odin" ]; then
        print_error "main.odin not found in project root"
        exit 1
    fi
    
    # Check for WebUI library
    if [ ! -f "$SCRIPT_DIR/lib/libwebui-2.so" ]; then
        print_error "WebUI library not found: $SCRIPT_DIR/lib/libwebui-2.so"
        exit 1
    fi
    
    # Build with error handling
    print_info "Compiling Odin application..."
    if [ "$VERBOSE" = true ]; then
        odin build "$SCRIPT_DIR" \
            -out:"$BUILD_DIR/app" \
            -extra-linker-flags:"-L$SCRIPT_DIR/lib" \
            -o:speed \
            -show-timings
    else
        odin build "$SCRIPT_DIR" \
            -out:"$BUILD_DIR/app" \
            -extra-linker-flags:"-L$SCRIPT_DIR/lib" \
            -o:speed 2>&1 | head -20
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Odin build failed"
        exit 1
    fi
    
    if [ ! -f "$BUILD_DIR/app" ]; then
        print_error "Build succeeded but output binary not found"
        exit 1
    fi
    
    print_info "✓ Odin build complete: $BUILD_DIR/app ($(du -h "$BUILD_DIR/app" | cut -f1))"
}

# Copy dependencies
copy_deps() {
    print_step "Copying dependencies..."
    
    # Copy WebUI library
    if [ -f "$SCRIPT_DIR/lib/libwebui-2.so" ]; then
        cp "$SCRIPT_DIR/lib/libwebui-2.so" "$BUILD_DIR/"
        print_info "✓ WebUI library copied"
    else
        print_warn "WebUI library not found"
    fi
    
    # Copy Angular frontend
    if [ -d "$FRONTEND_DIR/dist/browser" ]; then
        mkdir -p "$BUILD_DIR/frontend"
        cp -r "$FRONTEND_DIR/dist/browser/"* "$BUILD_DIR/frontend/"
        print_info "✓ Angular frontend copied"
    else
        print_warn "Angular build output not found"
    fi
}

# Verify build
verify_build() {
    print_step "Verifying build..."
    
    local errors=0
    
    # Check binary
    if [ ! -f "$BUILD_DIR/app" ]; then
        print_error "Binary not found: $BUILD_DIR/app"
        ((errors++))
    elif [ ! -x "$BUILD_DIR/app" ]; then
        print_error "Binary is not executable: $BUILD_DIR/app"
        ((errors++))
    fi
    
    # Check WebUI library
    if [ ! -f "$BUILD_DIR/libwebui-2.so" ]; then
        print_error "WebUI library not found in build directory"
        ((errors++))
    fi
    
    # Check frontend
    if [ ! -f "$BUILD_DIR/frontend/index.html" ]; then
        print_error "Frontend not found in build directory"
        ((errors++))
    fi
    
    if [ $errors -gt 0 ]; then
        print_error "Build verification failed with $errors error(s)"
        return 1
    fi
    
    print_info "✓ Build verification passed"
    return 0
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
    
    print_info "Starting application..."
    
    if [ -n "$DISPLAY" ]; then
        ./app
    else
        print_info "No DISPLAY set. Starting Xvfb..."
        Xvfb :99 -screen 0 1024x768x24 &
        XVFB_PID=$!
        export DISPLAY=:99
        trap "kill $XVFB_PID 2>/dev/null; exit" EXIT INT TERM
        ./app
    fi
}

# Print summary
print_summary() {
    local BUILD_END_TIME=$(date +%s)
    local DURATION=$((BUILD_END_TIME - BUILD_START_TIME))
    
    echo
    echo "=============================================="
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}  Build Complete!${NC}"
    else
        echo -e "${RED}  Build Failed with $ERRORS error(s)${NC}"
    fi
    echo "=============================================="
    echo -e "  Duration: ${DURATION}s"
    echo -e "  Errors:   ${ERRORS}"
    echo -e "  Warnings: ${WARNINGS}"
    echo "=============================================="
}

# Main
echo
echo "=============================================="
echo "  Odin + WebUI + Angular Runner"
echo "=============================================="
echo

# Handle dev mode separately (build frontend + backend, then run with WebUI window)
if [ "$ACTION" = "dev" ]; then
    print_step "Starting development mode (full build + WebUI)..."
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi
    
    # Check prerequisites for full build
    check_prerequisites
    echo
    
    # Build Angular frontend for production
    print_step "Building Angular frontend for production..."
    
    cd "$FRONTEND_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_info "Installing dependencies..."
        if command -v bun &> /dev/null; then
            bun install || { print_error "Failed to install dependencies"; exit 1; }
        else
            npm install || { print_error "Failed to install dependencies"; exit 1; }
        fi
    fi
    
    # Build for production
    print_info "Building Angular application..."
    if command -v bun &> /dev/null; then
        bun run build || { print_error "Angular build failed"; exit 1; }
    else
        npm run build || { print_error "Angular build failed"; exit 1; }
    fi
    
    cd "$SCRIPT_DIR"
    print_info "✓ Angular build complete"
    
    # Build Odin backend
    build_odin
    
    # Copy dependencies
    copy_deps
    
    # Verify build
    verify_build
    
    if [ $ERRORS -gt 0 ]; then
        print_summary
        exit 1
    fi
    
    print_summary
    echo
    print_info "Starting application with WebUI window..."
    echo
    
    # Run the app with WebUI
    run_app
    
    exit 0
fi

# For build/run modes, check prerequisites
check_prerequisites
echo

if [ "$ACTION" = "build" ] || [ "$ACTION" = "both" ]; then
    build_angular
    build_odin
    copy_deps
    verify_build

    print_summary

    if [ $ERRORS -gt 0 ]; then
        exit 1
    fi
fi

if [ "$ACTION" = "run" ] || [ "$ACTION" = "both" ]; then
    if [ ! -f "$BUILD_DIR/app" ]; then
        print_error "App not built. Run: $0 build"
        exit 1
    fi
    echo
    echo "Running application..."
    run_app
fi
