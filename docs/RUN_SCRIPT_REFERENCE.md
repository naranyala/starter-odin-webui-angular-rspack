# run.sh Command Reference

## Overview

The `run.sh` script is the main build and run automation tool for the project. It supports both command-style and flag-style arguments.

---

## Usage

```bash
# Command-style (recommended)
bash run.sh <command> [options]

# Flag-style (legacy support)
bash run.sh [options]
```

---

## Commands

### dev / development

Start the Angular development server with hot module replacement (HMR).

```bash
bash run.sh dev
bash run.sh development
bash run.sh --dev
```

**What it does:**
1. Checks if frontend directory exists
2. Installs dependencies if needed (using Bun or npm)
3. Starts the Angular dev server on port 4200
4. Enables HMR for instant updates

**Output:**
```
[STEP] Starting development mode...
[INFO] Starting Angular development server...
[INFO] Access the application at: http://localhost:4200
```

**Use case:** Daily development work with live reload.

---

### build

Build both frontend and backend for production.

```bash
bash run.sh build
bash run.sh --build
```

**What it does:**
1. Checks prerequisites (Odin, Bun/Node, C compiler)
2. Builds Angular frontend with Rspack
3. Compiles Odin backend
4. Copies dependencies to build/ directory
5. Verifies build output

**Output:**
```
[STEP] Checking prerequisites...
[INFO] ✓ Odin compiler found: odin version dev-2025-10
[INFO] ✓ Bun found: 1.3.11

[STEP] Building Angular frontend...
[INFO] Building Angular application...
✔ Building...

[STEP] Building Odin application...
[INFO] ✓ Odin build complete: build/app (326KB)

[STEP] Verifying build...
[INFO] ✓ Build verification passed

==============================================
  Build Complete!
==============================================
  Duration: 28s
  Errors:   0
  Warnings: 0
==============================================
```

**Use case:** Creating production builds or testing the full build pipeline.

---

### run

Run the compiled application (requires prior build).

```bash
bash run.sh run
bash run.sh --run
```

**What it does:**
1. Checks if build/app exists
2. Checks if WebUI library exists
3. Sets LD_LIBRARY_PATH
4. Starts the application

**Output:**
```
Running application...
[INFO] Starting application...
```

**Use case:** Running the application after a successful build.

---

### clean

Clean all build artifacts.

```bash
bash run.sh --clean
```

**What it does:**
- Removes build/ directory
- Removes frontend/dist/
- Removes frontend/.angular/
- Removes frontend/.rspack_cache/

**Output:**
```
[STEP] Cleaning build artifacts...
[INFO] Clean complete
```

**Use case:** Fresh rebuild or freeing disk space.

---

## Options

### --verbose / -v

Show detailed build output.

```bash
bash run.sh build --verbose
```

**Effect:**
- Shows Odin build timings
- Displays full compiler output
- Shows detailed error messages

---

### --help / -h

Show help information.

```bash
bash run.sh --help
```

**Output:**
```
Usage: run.sh [command] [options]

Commands:
  dev        Start development mode (frontend dev server)
  build      Build only (Angular + Odin)
  run        Run only (must be built)

Options:
  --dev      Start development mode
  --build    Build only (Angular + Odin)
  --run      Run only (must be built)
  --clean    Clean all build artifacts
  --verbose  Show detailed output
  --help     Show this help

Examples:
  run.sh dev           # Start development server
  run.sh build         # Build everything
  run.sh run           # Run the application
  run.sh --clean       # Clean build artifacts
```

---

## Common Workflows

### Daily Development

```bash
# Start dev server with HMR
bash run.sh dev

# Then open http://localhost:4200
```

### Full Build and Run

```bash
# Build everything
bash run.sh build

# Run the application
bash run.sh run
```

### Clean Rebuild

```bash
# Clean artifacts
bash run.sh --clean

# Fresh build
bash run.sh build

# Run
bash run.sh run
```

### Quick Build (After Code Changes)

```bash
# Just build (skip clean)
bash run.sh build
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Build failed |
| 1 | Prerequisites missing |
| 1 | Unknown command/option |

---

## Environment Variables

The script uses these environment variables:

| Variable | Purpose |
|----------|---------|
| `LD_LIBRARY_PATH` | Set automatically for running app |
| `DISPLAY` | Checked for GUI support (X11) |

---

## Prerequisites

The script checks for these tools:

| Tool | Required For | Fallback |
|------|--------------|----------|
| Odin | Backend compilation | None |
| Bun | Frontend build | npm/Node.js |
| GCC/Clang | WebUI library | Pre-built library |

---

## Troubleshooting

### "Odin compiler not found"

Install Odin: https://odin-lang.org/docs/install/

### "Neither Bun nor Node.js found"

Install Bun: https://bun.sh/
Or install Node.js: https://nodejs.org/

### "App not built"

Run `bash run.sh build` first.

### "WebUI library not found"

Ensure `lib/libwebui-2.so` exists in project root.

---

## Migration from Old Commands

| Old Command | New Command |
|-------------|-------------|
| `./run.sh` | `bash run.sh build` then `bash run.sh run` |
| `./run.sh --build` | `bash run.sh build` |
| `./run.sh --run` | `bash run.sh run` |
| N/A | `bash run.sh dev` (new!) |

---

## Examples

### Start Development

```bash
bash run.sh dev
```

### Build for Production

```bash
bash run.sh build
```

### Build with Verbose Output

```bash
bash run.sh build --verbose
```

### Clean and Rebuild

```bash
bash run.sh --clean && bash run.sh build
```

### Build Then Run

```bash
bash run.sh build && bash run.sh run
```

---

## See Also

- [Makefile](../Makefile) - Alternative build automation
- [QUICKSTART.md](../QUICKSTART.md) - Getting started guide
- [DX_IMPROVEMENT_PLAN.md](../DX_IMPROVEMENT_PLAN.md) - Developer experience improvements

---

**Last Updated:** 2026-03-29  
**Status:** Production Ready
