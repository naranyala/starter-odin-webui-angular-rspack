# ⚡ Quick Start Guide

**Get up and running in 5 minutes!**

---

## 🚀 First Time Setup

### **1. Prerequisites Check**

```bash
# Verify Odin compiler
odin version

# Verify Bun (or Node.js)
bun --version
# OR
node --version

# Verify C compiler (for WebUI)
gcc --version  # or clang --version
```

**Missing something?**
- Odin: https://odin-lang.org/docs/install/
- Bun: https://bun.sh/
- GCC: `sudo apt install build-essential` (Linux) or Xcode (macOS)

---

## **2. Install Dependencies**

```bash
# One command install
make install

# Or manually
cd frontend && bun install
```

**Time:** ~30 seconds (with Bun)

---

## **3. Start Development**

```bash
# Option A: Use Makefile (recommended)
make dev

# Option B: Use run.sh
./run.sh

# Option C: Frontend only
make fe-dev
```

**Access:** http://localhost:4200

---

## 📝 Common Commands

### **Development**
```bash
make dev          # Start everything
make fe-dev       # Frontend only
make be-dev       # Backend only
```

### **Building**
```bash
make build        # Full build
make rebuild      # Clean + build
make prod         # Production build
```

### **Testing**
```bash
make test         # Unit tests
make test-e2e     # E2E tests
```

### **Maintenance**
```bash
make clean        # Clean artifacts
make lint         # Lint & fix
make metrics      # Show project stats
```

---

## 🎯 Shell Aliases (Optional)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Project shortcuts
alias odin-dev='cd /path/to/project && make dev'
alias fe-dev='cd /path/to/project/frontend && bun run dev'
alias be-build='cd /path/to/project && ./run.sh --build'
alias fe-test='cd /path/to/project/frontend && bun test'
alias clean-build='cd /path/to/project && make clean && make build'
```

**Then:**
```bash
source ~/.bashrc  # Apply changes
odin-dev          # Start dev from anywhere!
```

---

## 🛠️ VSCode Setup

### **Required Extensions**
```bash
# Install from VSCode Extensions panel:
# - Biome (biomejs.biome)
# - Angular Language Service (Angular.ng-template)
```

### **Settings**
Already configured in `.vscode/settings.json`:
- ✅ Format on save
- ✅ Organize imports on save
- ✅ Exclude build artifacts from search
- ✅ TypeScript workspace SDK

---

## 🐛 Troubleshooting

### **"Module not found"**
```bash
make clean
make install
```

### **"Port 4200 already in use"**
```bash
# Kill process on port 4200
lsof -ti:4200 | xargs kill -9

# Or use different port
cd frontend && bun run dev --port 4201
```

### **"Odin not found"**
```bash
# Add Odin to PATH
export PATH=$PATH:/path/to/odin
```

### **"WebUI library not found"**
```bash
# Verify library exists
ls -la lib/libwebui-2.so

# Rebuild
./run.sh --build
```

---

## 📊 Project Structure

```
project/
├── frontend/          # Angular application
│   ├── src/
│   │   ├── core/     # Core services
│   │   ├── app/      # App services
│   │   ├── views/    # Components/views
│   │   └── models/   # Type definitions
│   └── dist/         # Build output
│
├── src/              # Odin backend
│   ├── lib/          # Core libraries
│   ├── services/     # Business logic
│   └── handlers/     # WebUI handlers
│
├── build/            # Compiled binaries
├── docs/             # Documentation
└── Makefile          # Build commands
```

---

## 🎓 Next Steps

1. **Read Documentation**
   - `docs/README.md` - Full documentation
   - `docs/frontend/` - Frontend guides
   - `docs/backend/` - Backend guides

2. **Start Developing**
   - `make dev` - Start coding!
   - Components auto-reload
   - Backend rebuilds on changes

3. **Learn the Patterns**
   - `ARCHITECTURAL_DECISIONS.md` - Why things are built this way
   - `CHANGELOG.md` - Recent changes
   - `DX_IMPROVEMENT_PLAN.md` - How we're improving DX

---

## 📞 Need Help?

- **Documentation:** `docs/README.md`
- **Issues:** Check `audit/open/` for known issues
- **Architecture:** See `ARCHITECTURAL_DECISIONS.md`

---

**Happy Coding!** 🚀
