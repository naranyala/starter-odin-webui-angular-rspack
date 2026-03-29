.PHONY: help dev build test clean lint install fe-dev be-dev rebuild

# Default target
help:
	@echo "=============================================="
	@echo "  Odin WebUI Angular - Development Commands"
	@echo "=============================================="
	@echo ""
	@echo "  make dev       - Start full dev environment"
	@echo "  make build     - Build everything"
	@echo "  make test      - Run all tests"
	@echo "  make lint      - Lint and fix issues"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make install   - Install dependencies"
	@echo ""
	@echo "  make fe-dev    - Frontend dev server only"
	@echo "  make be-dev    - Backend build only"
	@echo "  make rebuild   - Clean and rebuild"
	@echo ""
	@echo "=============================================="

# Install dependencies
install:
	@echo "[1/2] Installing frontend dependencies..."
	cd frontend && bun install --frozen-lockfile
	@echo "[2/2] Verifying backend..."
	odin version || echo "⚠️  Odin not found in PATH"
	@echo "✓ Installation complete"

# Development mode (both frontend and backend)
dev:
	@echo "Starting development environment..."
	@echo "Frontend: http://localhost:4200"
	@echo ""
	cd frontend && bun run dev

# Frontend dev only
fe-dev:
	cd frontend && bun run dev

# Backend dev only
be-dev:
	./run.sh --build

# Build everything
build:
	@echo "Building project..."
	cd frontend && bun run build
	./run.sh --build
	@echo "✓ Build complete"

# Run tests
test:
	@echo "Running unit tests..."
	cd frontend && bun test
	@echo "✓ Tests complete"

# Run E2E tests
test-e2e:
	@echo "Running E2E tests..."
	cd frontend && bunx playwright test
	@echo "✓ E2E tests complete"

# Lint and fix
lint:
	cd frontend && bun run lint:fix
	@echo "✓ Linting complete"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build
	rm -rf frontend/dist
	rm -rf frontend/.angular
	rm -rf frontend/.rspack_cache
	rm -rf frontend/node_modules/.cache
	@echo "✓ Clean complete"

# Quick rebuild (skip dependency install)
rebuild: clean build

# Production build
prod:
	@echo "Building for production..."
	cd frontend && bun run build:rspack
	./run.sh --build
	@echo "✓ Production build complete"

# Bundle analysis
analyze:
	@echo "Analyzing bundle..."
	cd frontend && ANALYZE=true bun run build:rspack
	@echo "✓ Report generated: frontend/bundle-report.html"

# Generate new component
generate:
	@echo "Usage: make generate-component name=<component-name>"
	@echo "Example: make generate-component name=user-profile"

# Show development metrics
metrics:
	@echo "=== Development Metrics ==="
	@echo ""
	@echo "📦 Dependencies:"
	@du -sh frontend/node_modules 2>/dev/null || echo "N/A"
	@echo ""
	@echo "📝 Code Stats:"
	@find frontend/src -name "*.ts" | xargs wc -l 2>/dev/null | tail -1 || echo "N/A"
	@echo ""
	@echo "🏗️  Build Directory:"
	@du -sh build 2>/dev/null || echo "N/A"
	@echo ""
