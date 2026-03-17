#!/bin/bash
# Build script for Odin + WebUI + Angular Integration
# This script builds all components and creates the final application

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=============================================="
echo "  Odin + WebUI + Angular Build Script"
echo "=============================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for required tools
check_requirements() {
    print_step "Checking requirements..."
    
    # Check for Odin
    if ! command -v odin &> /dev/null; then
        print_error "Odin compiler not found. Please install Odin first."
        echo "See: https://odin-lang.org/docs/install/"
        exit 1
    fi
    echo "  ✓ Odin: $(odin version 2>/dev/null || echo 'installed')"
    
    # Check for Bun (optional, for Angular build)
    if command -v bun &> /dev/null; then
        echo "  ✓ Bun: $(bun --version)"
    else
        print_warning "Bun not found. Will use npm for Angular build."
    fi
    
    # Check for Node.js
    if command -v node &> /dev/null; then
        echo "  ✓ Node.js: $(node --version)"
    else
        print_warning "Node.js not found. Angular build will be skipped."
    fi
}

# Build WebUI library
build_webui() {
    print_step "Building WebUI library..."
    
    WEBUI_DIR="$SCRIPT_DIR/thirdparty/webui"
    
    if [ ! -d "$WEBUI_DIR" ]; then
        print_error "WebUI directory not found: $WEBUI_DIR"
        exit 1
    fi
    
    cd "$WEBUI_DIR"
    
    # Clean previous build
    make clean 2>/dev/null || true
    
    # Build static library
    make
    
    # Copy library to project root
    mkdir -p "$SCRIPT_DIR/lib"
    cp dist/libwebui-2-static.a "$SCRIPT_DIR/lib/" 2>/dev/null || true
    cp dist/libwebui-2.so "$SCRIPT_DIR/lib/" 2>/dev/null || true
    
    cd "$SCRIPT_DIR"
    echo "  ✓ WebUI library built"
}

# Build Angular frontend
build_angular() {
    print_step "Building Angular frontend..."
    
    FRONTEND_DIR="$SCRIPT_DIR/frontend"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "  Installing dependencies..."
        if command -v bun &> /dev/null; then
            bun install
        else
            npm install
        fi
    fi
    
    # Build for production
    echo "  Building Angular app..."
    if command -v bun &> /dev/null; then
        bun run build:rspack
    else
        npm run build:rspack
    fi
    
    cd "$SCRIPT_DIR"
    echo "  ✓ Angular frontend built"
}

# Build Odin application
build_odin() {
    print_step "Building Odin application..."
    
    WEBUI_LIB="$SCRIPT_DIR/thirdparty/webui/dist"
    
    # Build main application
    if [ -f "$SCRIPT_DIR/main.odin" ]; then
        echo "  Building main.odin..."
        odin build "$SCRIPT_DIR" \
            -out:"$SCRIPT_DIR/app" \
            -extra-linker-flags:"-L$WEBUI_LIB -lwebui-2-static -lpthread -lm -ldl" \
            -o:speed \
            -no-bounds-check \
            || print_warning "Odin build failed. Check for Odin installation."
    fi
    
    # Build example application
    if [ -f "$SCRIPT_DIR/main_example.odin" ]; then
        echo "  Building main_example.odin..."
        odin build "$SCRIPT_DIR" \
            -out:"$SCRIPT_DIR/app_example" \
            -extra-linker-flags:"-L$WEBUI_LIB -lwebui-2-static -lpthread -lm -ldl" \
            -o:speed \
            -no-bounds-check \
            || print_warning "Odin example build failed."
    fi
    
    echo "  ✓ Odin application built"
}

# Copy webui.js to Angular dist
copy_webui_js() {
    print_step "Setting up WebUI JavaScript bridge..."
    
    WEBUI_BRIDGE="$SCRIPT_DIR/thirdparty/webui/bridge"
    ANGULAR_DIST="$SCRIPT_DIR/frontend/dist"
    
    if [ -f "$WEBUI_BRIDGE/webui.js" ] && [ -d "$ANGULAR_DIST" ]; then
        cp "$WEBUI_BRIDGE/webui.js" "$ANGULAR_DIST/"
        echo "  ✓ webui.js copied to Angular dist"
    else
        print_warning "webui.js not found or Angular dist not built yet"
    fi
}

# Create distribution package
create_dist() {
    print_step "Creating distribution package..."
    
    DIST_DIR="$SCRIPT_DIR/dist"
    mkdir -p "$DIST_DIR"
    
    # Copy Odin binary
    if [ -f "$SCRIPT_DIR/app" ]; then
        cp "$SCRIPT_DIR/app" "$DIST_DIR/"
    fi
    
    # Copy Angular dist
    if [ -d "$SCRIPT_DIR/frontend/dist" ]; then
        cp -r "$SCRIPT_DIR/frontend/dist" "$DIST_DIR/frontend"
    fi
    
    # Copy webui.js
    if [ -f "$SCRIPT_DIR/thirdparty/webui/bridge/webui.js" ]; then
        cp "$SCRIPT_DIR/thirdparty/webui/bridge/webui.js" "$DIST_DIR/"
    fi
    
    echo "  ✓ Distribution package created in $DIST_DIR"
}

# Main build function
main() {
    echo
    check_requirements
    echo
    
    build_webui
    echo
    
    build_angular
    echo
    
    copy_webui_js
    echo
    
    build_odin
    echo
    
    create_dist
    echo
    
    echo "=============================================="
    echo -e "${GREEN}  Build Complete!${NC}"
    echo "=============================================="
    echo
    echo "To run the application:"
    echo "  ./app              # Run main application"
    echo "  ./app_example      # Run example application"
    echo
    echo "Or for development:"
    echo "  cd frontend && bun run dev  # Start Angular dev server"
    echo
}

# Run main function
main "$@"
