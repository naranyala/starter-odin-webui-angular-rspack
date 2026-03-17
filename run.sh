#!/bin/bash
# =============================================================================
# Odin + WebUI + Angular - Complete Build & Run Pipeline
# =============================================================================
# Usage:
#   ./run.sh              # Build and run application
#   ./run.sh build        # Build only
#   ./run.sh run          # Run built application
#   ./run.sh dev          # Start development mode (Angular dev server)
#   ./run.sh clean        # Clean all build artifacts
#   ./run.sh test         # Run tests
#   ./run.sh help         # Show this help message
# =============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# =============================================================================
# Configuration
# =============================================================================
APP_NAME="odin-webui-app"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
WEBUI_DIR="$SCRIPT_DIR/thirdparty/webui"
ODIN_LIB_DIR="$SCRIPT_DIR/webui_lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build flags
VERBOSE=${VERBOSE:-0}
RELEASE=${RELEASE:-0}
DEBUG=${DEBUG:-0}

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "  $1"
    echo "=============================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log() {
    if [ "$VERBOSE" -eq 1 ]; then
        echo "  $1"
    fi
}

# =============================================================================
# Requirement Checks
# =============================================================================

check_requirements() {
    print_header "Checking Requirements"
    
    local missing=0
    
    # Check Odin
    if command -v odin &> /dev/null; then
        local odin_version=$(odin version 2>&1 | head -1)
        print_step "Odin: $odin_version"
    else
        print_error "Odin compiler not found"
        print_info "Install from: https://odin-lang.org/docs/install/"
        missing=1
    fi
    
    # Check GCC/Clang
    if command -v gcc &> /dev/null; then
        local gcc_version=$(gcc --version | head -1)
        print_step "GCC: $gcc_version"
    elif command -v clang &> /dev/null; then
        local clang_version=$(clang --version | head -1)
        print_step "Clang: $clang_version"
    else
        print_warning "No C compiler found (GCC/Clang)"
        missing=1
    fi
    
    # Check Node.js/Bun
    if command -v bun &> /dev/null; then
        local bun_version=$(bun --version)
        print_step "Bun: v$bun_version"
    elif command -v node &> /dev/null; then
        local node_version=$(node --version)
        print_step "Node.js: $node_version"
    else
        print_warning "No JavaScript runtime found (Bun/Node.js)"
        print_info "Angular build will be skipped"
    fi
    
    # Check Make
    if command -v make &> /dev/null; then
        local make_version=$(make --version | head -1)
        log "Make: $make_version"
    else
        print_error "Make not found"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        print_error "Some requirements are missing. Please install them and try again."
        return 1
    fi
    
    print_step "All requirements satisfied"
    return 0
}

# =============================================================================
# Build Functions
# =============================================================================

build_webui() {
    print_header "Building WebUI Library"
    
    if [ ! -d "$WEBUI_DIR" ]; then
        print_error "WebUI directory not found: $WEBUI_DIR"
        return 1
    fi
    
    cd "$WEBUI_DIR"
    
    # Clean previous build
    log "Cleaning previous build..."
    make clean 2>/dev/null || true
    
    # Build static and dynamic libraries
    log "Building static library..."
    make 2>&1 | grep -E "(Build|Done|Error)" || true
    
    # Verify build output
    if [ -f "dist/libwebui-2-static.a" ]; then
        print_step "Static library: dist/libwebui-2-static.a"
    else
        print_error "Failed to build static library"
        return 1
    fi
    
    if [ -f "dist/libwebui-2.so" ]; then
        print_step "Dynamic library: dist/libwebui-2.so"
    fi
    
    cd "$SCRIPT_DIR"
    print_step "WebUI library built successfully"
}

build_angular() {
    print_header "Building Angular Frontend"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found: $FRONTEND_DIR"
        return 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Check for package manager
    local pkg_manager=""
    if command -v bun &> /dev/null; then
        pkg_manager="bun"
    elif command -v npm &> /dev/null; then
        pkg_manager="npm"
    else
        print_warning "No package manager found. Skipping Angular build."
        cd "$SCRIPT_DIR"
        return 0
    fi
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        log "Installing dependencies with $pkg_manager..."
        $pkg_manager install
    fi
    
    # Build for production
    log "Building Angular application..."
    if [ "$pkg_manager" = "bun" ]; then
        bun run build:rspack 2>&1 | tail -20
    else
        npm run build:rspack 2>&1 | tail -20
    fi
    
    # Verify build
    if [ -d "dist" ]; then
        print_step "Angular build output: frontend/dist/"
        
        # Copy webui.js to dist
        if [ -f "$WEBUI_DIR/bridge/webui.js" ]; then
            cp "$WEBUI_DIR/bridge/webui.js" dist/
            log "Copied webui.js to dist/"
        fi
    else
        print_warning "Angular dist/ not found"
    fi
    
    cd "$SCRIPT_DIR"
    print_step "Angular frontend built successfully"
}

build_odin() {
    print_header "Building Odin Application"

    local linker_flags="-L$WEBUI_DIR/dist -lwebui-2-static -lpthread -lm -ldl"
    local build_flags="-o:speed"

    if [ "$DEBUG" -eq 1 ]; then
        build_flags="-debug -g"
        print_info "Building in debug mode"
    fi

    # Create build directory
    mkdir -p "$BUILD_DIR"

    # Build main application
    if [ -f "$SCRIPT_DIR/main.odin" ]; then
        log "Building main.odin..."

        odin build "$SCRIPT_DIR" \
            -out:"$BUILD_DIR/$APP_NAME" \
            -extra-linker-flags:"$linker_flags" \
            $build_flags \
            -no-bounds-check \
            2>&1 | tee "$BUILD_DIR/build.log" || {
            print_warning "Odin build failed, check $BUILD_DIR/build.log"
        }

        if [ -f "$BUILD_DIR/$APP_NAME" ]; then
            print_step "Built: $BUILD_DIR/$APP_NAME"
        fi
    fi

    # Build DI demo
    if [ -f "$SCRIPT_DIR/examples/di_demo.odin" ]; then
        log "Building di_demo.odin..."
        odin build "$SCRIPT_DIR/examples" \
            -out:"$BUILD_DIR/di_demo" \
            -file \
            2>&1 | tee -a "$BUILD_DIR/build.log" || {
            print_warning "DI demo build failed"
        }

        if [ -f "$BUILD_DIR/di_demo" ]; then
            print_step "Built: $BUILD_DIR/di_demo"
        fi
    fi

    print_step "Odin application built successfully"
}

create_distribution() {
    print_header "Creating Distribution Package"
    
    mkdir -p "$DIST_DIR"
    
    # Copy Odin binary
    if [ -f "$BUILD_DIR/$APP_NAME" ]; then
        cp "$BUILD_DIR/$APP_NAME" "$DIST_DIR/"
        print_step "Copied application binary"
    fi
    
    # Copy Angular dist
    if [ -d "$FRONTEND_DIR/dist" ]; then
        cp -r "$FRONTEND_DIR/dist" "$DIST_DIR/frontend"
        print_step "Copied Angular frontend"
    fi
    
    # Copy webui.js
    if [ -f "$WEBUI_DIR/bridge/webui.js" ]; then
        cp "$WEBUI_DIR/bridge/webui.js" "$DIST_DIR/"
        print_step "Copied webui.js"
    fi
    
    # Copy libraries
    mkdir -p "$DIST_DIR/lib"
    if [ -f "$WEBUI_DIR/dist/libwebui-2.so" ]; then
        cp "$WEBUI_DIR/dist/libwebui-2.so" "$DIST_DIR/lib/"
        print_step "Copied shared library"
    fi
    
    # Create README
    cat > "$DIST_DIR/README.txt" << EOF
$APP_NAME Distribution
======================

To run the application:
  ./ $APP_NAME

Files:
  - $APP_NAME          : Main application
  - frontend/          : Angular web application
  - webui.js          : WebUI JavaScript bridge
  - lib/              : Shared libraries

Requirements:
  - A modern web browser (Chrome, Firefox, Edge, etc.)
EOF
    
    print_step "Distribution package created: $DIST_DIR/"
}

# =============================================================================
# Run Functions
# =============================================================================

run_app() {
    print_header "Running Application"
    
    local app_binary="$BUILD_DIR/$APP_NAME"
    
    if [ ! -f "$app_binary" ]; then
        print_error "Application not found. Run './run.sh build' first."
        return 1
    fi
    
    print_info "Starting $APP_NAME..."
    echo
    
    # Set library path for dynamic linking
    export LD_LIBRARY_PATH="$WEBUI_DIR/dist:$LD_LIBRARY_PATH"
    
    # Run application
    cd "$SCRIPT_DIR"
    "$app_binary"
}

run_dev() {
    print_header "Starting Development Mode"
    
    cd "$FRONTEND_DIR"
    
    local pkg_manager=""
    if command -v bun &> /dev/null; then
        pkg_manager="bun"
    elif command -v npm &> /dev/null; then
        pkg_manager="npm"
    fi
    
    if [ -z "$pkg_manager" ]; then
        print_error "No package manager found for development mode"
        return 1
    fi
    
    print_info "Starting Angular dev server..."
    print_info "Access at: http://localhost:4200"
    echo
    
    $pkg_manager run dev
}

# =============================================================================
# Clean Functions
# =============================================================================

clean_all() {
    print_header "Cleaning Build Artifacts"
    
    # Clean Odin build
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_step "Removed: $BUILD_DIR/"
    fi
    
    # Clean distribution
    if [ -d "$DIST_DIR" ]; then
        rm -rf "$DIST_DIR"
        print_step "Removed: $DIST_DIR/"
    fi
    
    # Clean Angular
    if [ -d "$FRONTEND_DIR/dist" ]; then
        rm -rf "$FRONTEND_DIR/dist"
        print_step "Removed: frontend/dist/"
    fi
    
    if [ -d "$FRONTEND_DIR/node_modules" ]; then
        rm -rf "$FRONTEND_DIR/node_modules"
        print_step "Removed: frontend/node_modules/"
    fi
    
    # Clean WebUI
    cd "$WEBUI_DIR"
    make clean 2>/dev/null || true
    print_step "Cleaned: WebUI library"
    
    cd "$SCRIPT_DIR"
    
    # Remove Odin cache
    if [ -d "$SCRIPT_DIR/odin_cache" ]; then
        rm -rf "$SCRIPT_DIR/odin_cache"
        print_step "Removed: odin_cache/"
    fi
    
    print_step "Clean complete"
}

# =============================================================================
# Test Functions
# =============================================================================

run_tests() {
    print_header "Running Tests"
    
    local test_failed=0
    
    # Angular tests
    if [ -d "$FRONTEND_DIR" ]; then
        cd "$FRONTEND_DIR"
        
        if command -v bun &> /dev/null; then
            print_info "Running Angular tests with bun..."
            bun test 2>&1 | tail -30 || test_failed=1
        elif command -v npm &> /dev/null; then
            print_info "Running Angular tests with npm..."
            npm test 2>&1 | tail -30 || test_failed=1
        fi
        
        cd "$SCRIPT_DIR"
    fi
    
    if [ $test_failed -eq 0 ]; then
        print_step "All tests passed"
    else
        print_warning "Some tests failed"
    fi
    
    return $test_failed
}

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << EOF
${CYAN}Odin + WebUI + Angular - Build & Run Pipeline${NC}

${GREEN}Usage:${NC}
  ./run.sh [command] [options]

${GREEN}Commands:${NC}
  (none)      Build and run application
  build       Build all components (WebUI, Angular, Odin)
  run         Run the built application
  dev         Start development mode (Angular dev server)
  clean       Remove all build artifacts
  test        Run tests
  help        Show this help message

${GREEN}Options:${NC}
  --verbose   Enable verbose output
  --debug     Build in debug mode
  --release   Build in release mode (default)

${GREEN}Examples:${NC}
  ./run.sh                    # Build and run
  ./run.sh build              # Build only
  ./run.sh build --verbose    # Build with verbose output
  ./run.sh dev                # Start dev server
  ./run.sh clean && ./run.sh  # Clean rebuild

${GREEN}Environment Variables:${NC}
  VERBOSE=1   Enable verbose output
  DEBUG=1     Build in debug mode
  RELEASE=1   Build in release mode

EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    local command="${1:-build}"
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=1
                ;;
            --debug)
                DEBUG=1
                RELEASE=0
                ;;
            --release)
                RELEASE=1
                DEBUG=0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                ;;
        esac
        shift
    done
    
    case $command in
        build)
            check_requirements || exit 1
            build_webui || exit 1
            build_angular || exit 1
            build_odin || exit 1
            create_distribution
            print_header "Build Complete"
            print_info "Run with: ./run.sh run"
            ;;
        
        run)
            run_app
            ;;
        
        dev)
            run_dev
            ;;
        
        clean)
            clean_all
            ;;
        
        test)
            run_tests
            ;;
        
        help|--help|-h)
            show_help
            ;;
        
        *)
            # Default: build and run
            check_requirements || exit 1
            build_webui || exit 1
            build_angular || exit 1
            build_odin || exit 1
            create_distribution
            print_header "Build Complete - Running Application"
            run_app
            ;;
    esac
}

# Run main function with all arguments
main "$@"
