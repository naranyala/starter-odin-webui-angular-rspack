/**
 * Documentation Viewer Component
 * 
 * Main documentation viewer with navigation and content display
 */

import { Component, signal, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MarkdownModule } from 'ngx-markdown';
import { DocumentationNavComponent } from './documentation-nav.component';
import { DocumentationContentComponent } from './documentation-content.component';

export interface DocSection {
  id: string;
  title: string;
  icon: string;
  items: DocItem[];
}

export interface DocItem {
  id: string;
  title: string;
  path: string;
  content?: string;
}

@Component({
  selector: 'app-documentation-viewer',
  standalone: true,
  imports: [
    CommonModule,
    MarkdownModule,
    DocumentationNavComponent,
    DocumentationContentComponent,
  ],
  template: `
    <div class="docs-container">
      <!-- Navigation Sidebar -->
      <aside class="docs-nav">
        <app-documentation-nav
          [sections]="sections()"
          [activeSection]="activeSection()"
          [activeItem]="activeItem()"
          (sectionToggle)="toggleSection($event)"
          (itemSelect)="selectItem($event)">
        </app-documentation-nav>
      </aside>

      <!-- Content Area -->
      <main class="docs-content">
        <app-documentation-content
          [content]="currentContent()"
          [title]="currentTitle()"
          [isLoading]="isLoading()">
        </app-documentation-content>
      </main>
    </div>
  `,
  styles: [`
    .docs-container {
      display: flex;
      height: 100vh;
      background: #0f172a;
      overflow: hidden;
    }

    .docs-nav {
      width: 320px;
      background: rgba(15, 23, 42, 0.95);
      border-right: 1px solid rgba(148, 163, 184, 0.1);
      overflow-y: auto;
    }

    .docs-content {
      flex: 1;
      overflow-y: auto;
      background: #0f172a;
      padding: 0;
    }

    @media (max-width: 768px) {
      .docs-nav {
        width: 100%;
        position: absolute;
        z-index: 10;
        transform: translateX(-100%);
        transition: transform 0.3s ease;
      }

      .docs-nav.show {
        transform: translateX(0);
      }
    }
  `],
})
export class DocumentationViewerComponent {
  activeSection = signal<string>('quickstart');
  activeItem = signal<string>('overview');
  isLoading = signal(false);

  sections: ReturnType<typeof signal<DocSection[]>> = signal([
    {
      id: 'quickstart',
      title: 'Quick Start',
      icon: '🚀',
      items: [
        {
          id: 'overview',
          title: 'Overview',
          path: 'assets/docs/README.md',
          content: this.getQuickStartOverview(),
        },
        {
          id: 'installation',
          title: 'Installation',
          path: 'assets/docs/QUICKSTART.md',
          content: this.getQuickStartInstallation(),
        },
        {
          id: 'commands',
          title: 'Common Commands',
          path: 'assets/docs/QUICKSTART.md',
          content: this.getQuickStartCommands(),
        },
      ],
    },
    {
      id: 'architecture',
      title: 'Architecture',
      icon: '🏗️',
      items: [
        {
          id: 'arch-decisions',
          title: 'Architectural Decisions',
          path: 'assets/docs/ARCHITECTURAL_DECISIONS.md',
          content: this.getArchDecisions(),
        },
        {
          id: 'changelog',
          title: 'Changelog',
          path: 'assets/docs/CHANGELOG.md',
          content: this.getChangelog(),
        },
      ],
    },
    {
      id: 'backend',
      title: 'Backend',
      icon: '🔙',
      items: [
        {
          id: 'backend-readme',
          title: 'Backend Overview',
          path: 'assets/docs/backend/README.md',
          content: this.getBackendOverview(),
        },
        {
          id: 'duckdb-integration',
          title: 'DuckDB Integration',
          path: 'assets/docs/backend/duckdb-integration.md',
          content: this.getDuckDBIntegration(),
        },
        {
          id: 'sqlite-integration',
          title: 'SQLite Integration',
          path: 'assets/docs/backend/sqlite-integration.md',
          content: this.getSQLiteIntegration(),
        },
      ],
    },
    {
      id: 'frontend',
      title: 'Frontend',
      icon: '🎨',
      items: [
        {
          id: 'frontend-readme',
          title: 'Frontend Overview',
          path: 'assets/docs/frontend/README.md',
          content: this.getFrontendOverview(),
        },
        {
          id: 'duckdb-components',
          title: 'DuckDB Components',
          path: 'assets/docs/frontend/duckdb-components.md',
          content: this.getDuckDBComponents(),
        },
        {
          id: 'sqlite-components',
          title: 'SQLite Components',
          path: 'assets/docs/frontend/sqlite-components.md',
          content: this.getSQLiteComponents(),
        },
      ],
    },
    {
      id: 'guides',
      title: 'Guides',
      icon: '📚',
      items: [
        {
          id: 'crud-operations',
          title: 'CRUD Operations Guide',
          path: 'assets/docs/guides/crud-operations-guide.md',
          content: this.getCRUDOperationsGuide(),
        },
        {
          id: 'security',
          title: 'Security Guide',
          path: 'assets/docs/guides/README.md',
          content: this.getSecurityGuide(),
        },
      ],
    },
  ]);

  currentContent = computed(() => {
    const section = this.sections().find(s => s.id === this.activeSection());
    const item = section?.items.find(i => i.id === this.activeItem());
    return item?.content || '# Select a topic from the navigation';
  });

  currentTitle = computed(() => {
    const section = this.sections().find(s => s.id === this.activeSection());
    const item = section?.items.find(i => i.id === this.activeItem());
    return item?.title || 'Documentation';
  });

  toggleSection(sectionId: string): void {
    if (this.activeSection() === sectionId) {
      this.activeSection.set('');
    } else {
      this.activeSection.set(sectionId);
    }
  }

  selectItem(itemId: string): void {
    this.activeItem.set(itemId);
    this.isLoading.set(true);
    
    // Simulate loading
    setTimeout(() => {
      this.isLoading.set(false);
    }, 300);
  }

  // ============================================================================
  // Content Methods (In production, these would load from actual markdown files)
  // ============================================================================

  private getQuickStartOverview(): string {
    return `# ⚡ Quick Start

**Get up and running in 5 minutes!**

---

## 🚀 First Time Setup

### **1. Prerequisites Check**

\`\`\`bash
# Verify Odin compiler
odin version

# Verify Bun (or Node.js)
bun --version
# OR
node --version

# Verify C compiler (for WebUI)
gcc --version  # or clang --version
\`\`\`

**Missing something?**
- Odin: https://odin-lang.org/docs/install/
- Bun: https://bun.sh/
- GCC: \`sudo apt install build-essential\` (Linux) or Xcode (macOS)

---

## **2. Install Dependencies**

\`\`\`bash
# One command install
make install

# Or manually
cd frontend && bun install
\`\`\`

**Time:** ~30 seconds (with Bun)

---

## **3. Start Development**

\`\`\`bash
# Option A: Use Makefile (recommended)
make dev

# Option B: Use run.sh
./run.sh

# Option C: Frontend only
make fe-dev
\`\`\`

**Access:** http://localhost:4200`;
  }

  private getQuickStartInstallation(): string {
    return `## Installation Details

### System Requirements

- **OS:** Linux, macOS, or Windows (WSL2)
- **RAM:** 8GB minimum, 16GB recommended
- **Disk:** 5GB free space
- **Node.js:** v18+ or Bun v1.3+

### Step-by-Step

1. Clone the repository
2. Run \`make install\`
3. Verify with \`make dev\`
4. Open http://localhost:4200`;
  }

  private getQuickStartCommands(): string {
    return `# Common Commands

## Development
\`\`\`bash
make dev          # Start full dev environment
make fe-dev       # Frontend dev server only
make be-dev       # Backend build only
\`\`\`

## Building
\`\`\`bash
make build        # Full build
make rebuild      # Clean + build
make prod         # Production build
\`\`\`

## Testing
\`\`\`bash
make test         # Unit tests
make test-e2e     # E2E tests
\`\`\`

## Maintenance
\`\`\`bash
make clean        # Clean artifacts
make lint         # Lint & fix
make metrics      # Show project stats
\`\`\``;
  }

  private getDXSummary(): string {
    return `# 🎯 Developer Experience Summary

## What We Improved

### Makefile - One-Command Development

**Before:** 3-4 commands to start development
**After:** 1 command (\`make dev\`)

### VSCode Configuration

- ✅ Format on save (Biome)
- ✅ Organize imports on save
- ✅ Exclude build artifacts from search
- ✅ Angular Language Service enabled

### Impact

| Metric | Before | After |
|--------|--------|-------|
| Commands to start | 3-4 | 1 |
| Setup time | 10 min | 2 min |
| IDE performance | Slow | Fast |

## Quick Commands

\`\`\`bash
make install     # Install dependencies
make dev         # Start development
make build       # Build everything
make test        # Run tests
make clean       # Clean artifacts
make lint        # Lint and fix
\`\`\``;
  }

  private getDXImprovementPlan(): string {
    return `# 🚀 DX Improvement Plan

## Priority Matrix

### 🔴 P0: Quick Wins (Done)
- ✅ Makefile created
- ✅ VSCode settings configured
- ✅ QUICKSTART.md written
- ✅ .gitignore optimized

### 🟠 P1: High Value (This Week)
- Reduce node_modules (820MB → 450MB)
- Optimize HMR for faster updates
- Enable incremental TypeScript
- Create component scaffolding

### 🟡 P2: Nice to Have (This Month)
- Docker dev environment
- Dev metrics dashboard
- Pre-commit hooks
- Bundle size optimization

## Expected Results

| Metric | Before | After P1 |
|--------|--------|----------|
| Initial Build | 27s | 15s |
| HMR Update | 5s | 1s |
| Bundle Size | 877KB | 525KB |
| node_modules | 820MB | 450MB |`;
  }

  private getMakefileGuide(): string {
    return `# Makefile Guide

## All Available Commands

### Core Commands

\`\`\`bash
make help        # Show all available commands
make install     # Install all dependencies
make dev         # Start development server
make build       # Build everything
make test        # Run all tests
make clean       # Clean build artifacts
make lint        # Lint and fix issues
\`\`\`

### Development Commands

\`\`\`bash
make fe-dev      # Frontend dev server only
make be-dev      # Backend build only
make rebuild     # Clean and rebuild
\`\`\`

### Advanced Commands

\`\`\`bash
make test-e2e    # Run E2E tests
make prod        # Production build
make analyze     # Bundle analysis
make metrics     # Show project metrics
\`\`\`

## Customization

Edit the Makefile to add your own commands:

\`\`\`makefile
my-custom-command:
\t@echo "Running custom command"
\tcd frontend && bun run my-script
\`\`\``;
  }

  private getArchDecisions(): string {
    return `# Architectural Decisions

## Recent Major Changes

### 1. Frontend Consolidation

**Decision:** Merge 3 frontends into 1

**Why:**
- 80% code duplication
- Feature drift between versions
- Developer confusion

**Result:** Single source of truth

### 2. Documentation Consolidation

**Decision:** Move all docs to /docs/

**Why:**
- 73 files in 6 locations
- Outdated and contradictory info
- Maintenance burden

**Result:** Single source of truth

### 3. Thread Safety

**Decision:** Add mutex to DI system

**Why:**
- Audit finding #1 (HIGH severity)
- Race conditions possible
- Production blocker

**Result:** Thread-safe operations

### 4. Build Script Enhancement

**Decision:** Professional error handling

**Why:**
- Silent failures
- No verification
- Poor DX

**Result:** Reliable builds with verification`;
  }

  private getChangelog(): string {
    return `# Changelog - Latest Changes

## [Unreleased] - 2026-03-29

### 🚨 MAJOR ARCHITECTURAL RESTRUCTURING

#### Breaking Changes

**1. Project Structure Reorganization**
- Empty directories removed (comms/, errors/, webui_lib/, odin/)
- Binaries moved to build/
- Documentation consolidated to docs/

**2. Frontend Consolidation**
- Merged unique features from alt88/alt99
- New services: ArrayTransform, Encoding, Clipboard, Loading, NetworkMonitor
- Alternative frontends marked for deletion

**3. Security Improvements**
- Comprehensive .gitignore
- Thread-safe DI system
- Enhanced build script with verification

#### New Features

**Services Added:**
- ArrayTransformService - Array operations
- EncodingService - Base64, URL, HTML encoding
- ClipboardService - Clipboard operations
- LoadingService - Loading state management
- NetworkMonitorService - Online/offline tracking
- GlobalErrorService - Centralized error state

#### Bug Fixes

- Memory leak prevention (ngOnDestroy)
- Type safety fixes
- Duplicate interface removal`;
  }

  private getStructuralCleanup(): string {
    return `# Structural Cleanup Report

## Summary

All critical and high-priority structural pitfalls have been remediated.

## Fixes Implemented

### CRITICAL (5/5 Complete)

1. ✅ **Consolidated Frontends**
   - Merged unique services from alt88/alt99
   - 7 new services added

2. ✅ **Deleted Empty Directories**
   - Removed comms/, errors/, webui_lib/, odin/

3. ✅ **Moved Root Binaries**
   - 9 binaries moved to build/

4. ✅ **Updated .gitignore**
   - Comprehensive patterns (95% coverage)

5. ✅ **Consolidated Documentation**
   - 73 files from 6 locations → single docs/

### HIGH PRIORITY (2/2 Complete)

6. ✅ **Thread Safety**
   - DI system mutex-protected

7. ✅ **Build Script**
   - Professional error handling

## Results

**Build Status:** ✅ PASSING (26.7 seconds)

**Risk Reduction:**
- Code duplication: 🔴 → 🟢
- Security: 🔴 → 🟢
- Build fragility: 🟠 → 🟢
- Documentation drift: 🟠 → 🟢`;
  }

  private getBackendOverview(): string {
    return `# Backend Overview

## Architecture

The backend is built with **Odin**, a system programming language focused on performance and simplicity.

### Core Components

- **DI System** - Dependency injection container
- **Event Bus** - Type-safe event system
- **Services** - Business logic layer
- **WebUI Handlers** - Backend function bindings

### Key Features

- Thread-safe operations
- Errors as values pattern
- In-memory data storage
- WebSocket communication via WebUI`;
  }

  private getDISystem(): string {
    return `# Dependency Injection System

## Overview

Angular-inspired DI system implemented in Odin.

## Usage

\`\`\`odin
// Register a service
di.register_singleton(&injector, "Logger", size_of(Logger), logger_create)

// Resolve a service
logger, err := di.inject(&injector, Logger)
\`\`\`

## Thread Safety

All DI operations are protected by mutex:

\`\`\`odin
Injector :: struct {
    providers: hash_map.HashMap(Token, Provider),
    instances: hash_map.HashMap(Token, rawptr),
    mutex:     sync.Mutex,  // Thread-safe
}
\`\`\``;
  }

  private getErrorHandling(): string {
    return `# Error Handling Guide

## Errors as Values Pattern

Instead of exceptions, Odin uses error return values.

## Usage

\`\`\`odin
my_function :: proc() -> (Result, Error) {
    if something_wrong {
        return Result{}, errors.err_invalid_param("Error message")
    }
    return result, errors.Error{code = .None}
}
\`\`\`

## Error Codes

- \`Error_Code.None\` - No error
- \`Error_Code.Validation_Error\` - Invalid input
- \`Error_Code.Not_Found\` - Resource not found
- \`Error_Code.Auth_Error\` - Authentication failed
- \`Error_Code.Internal\` - Internal error`;
  }

  private getFrontendOverview(): string {
    return `# Frontend Overview

## Technology Stack

- **Framework:** Angular 21
- **Bundler:** Rspack (fast Rust bundler)
- **Package Manager:** Bun
- **State Management:** Angular Signals
- **Styling:** CSS with dark theme

## Architecture

### Core Services

- ApiService - Backend communication
- CommunicationService - Multi-channel IPC
- LoggerService - Logging with signals
- StorageService - LocalStorage wrapper

### Views

- Dashboard - Main navigation hub
- Auth - Login/Register
- DuckDB - Database demos
- DevTools - Developer tools`;
  }

  private getTestingGuide(): string {
    return `# Testing Guide

## Running Tests

\`\`\`bash
# Unit tests
make test

# E2E tests
make test-e2e

# With coverage
cd frontend && bun test --coverage
\`\`\`

## Test Structure

- **Unit Tests:** \`*.test.ts\` files
- **Integration Tests:** \`integration/\` folder
- **E2E Tests:** \`tests/e2e/\` folder

## Writing Tests

\`\`\`typescript
describe('MyComponent', () => {
  it('should create', () => {
    const fixture = TestBed.createComponent(MyComponent);
    expect(fixture.componentInstance).toBeTruthy();
  });
});
\`\`\``;
  }

  private getWebUIIntegration(): string {
    return `# WebUI Integration

## Overview

WebUI provides bidirectional communication between Angular frontend and Odin backend via WebSocket.

## Architecture

\`\`\`
Angular ←→ WebUI Bridge ←→ WebSocket ←→ WebUI ←→ Odin Backend
\`\`\`

## Frontend Usage

\`\`\`typescript
// Call backend function
const result = await webui.call('getUsers', []);

// Subscribe to events
webui.on('user:created', (data) => {
  console.log('New user:', data);
});
\`\`\`

## Backend Usage

\`\`\`odin
// Bind function
webui.bind(window, "getUsers", handle_get_users)

// Handler
handle_get_users :: proc "c" (e: ^webui.Event) {
    // Process request
    webui.webui_event_return_string(e, response_json)
}
\`\`\``;
  }

  private getDataTransform(): string {
    return `# Data Transform Services

## Overview

Comprehensive data transformation utilities for Angular.

## Services

### ArrayTransformService

\`\`\`typescript
map<T, U>(arr: T[], transform: fn): U[]
filter<T>(arr: T[], predicate: fn): T[]
reduce<T, U>(arr: T[], initial: U, reducer: fn): U
unique<T>(arr: T[]): T[]
\`\`\`

### EncodingService

\`\`\`typescript
base64Encode/Decode(data: string | Uint8Array)
urlEncode/Decode(str: string)
htmlEncode/Decode(str: string)  // XSS prevention
hexEncode/Decode(data: Uint8Array)
\`\`\`

### ValidationService

\`\`\`typescript
addRule(field, ruleType, message)
validate<T>(data: T): ValidationResult
\`\`\``;
  }

  private getDuckDBIntegration(): string {
    return `# DuckDB Integration Guide

## Overview

Production-ready DuckDB integration for analytical workloads.

## Features

- Complete CRUD operations
- Query builder support
- Analytics functions
- Thread-safe operations

## Backend Implementation

\`\`\`odin
// Initialize DuckDB
conn := database.init_connection(.DuckDB, "build/duckdb.db")

// Execute query
result := database.execute_query(&conn, "SELECT * FROM users")

// Transaction support
database.begin_transaction(&conn, .{})
// ... operations
database.commit_transaction(&conn)
\`\`\`

## Frontend Usage

\`\`\`typescript
const users = await api.callOrThrow<User[]>('getUsers');
const stats = await api.callOrThrow<UserStats>('getUserStats');
\`\`\``;
  }

  private getSQLiteIntegration(): string {
    return `# SQLite Integration Guide

## Overview

Production-ready SQLite integration for transactional workloads.

## Features

- Complete CRUD operations
- Transaction support
- Lightweight storage
- Embedded deployment ready

## Backend Implementation

\`\`\`odin
// Initialize SQLite
conn := database.init_connection(.SQLite, "build/sqlite.db")

// Execute query
result := database.execute_query(&conn, "SELECT * FROM products")

// Transaction support
database.begin_transaction(&conn, .{})
// ... operations
database.commit_transaction(&conn)
\`\`\`

## Frontend Usage

\`\`\`typescript
const products = await api.callOrThrow<Product[]>('sqlite:getProducts');
const stats = await api.callOrThrow<ProductStats>('sqlite:getProductStats');
\`\`\``;
  }

  private getCRUDOperationsGuide(): string {
    return `# CRUD Operations Guide

## Overview

End-to-end tutorial for implementing CRUD operations with DuckDB and SQLite.

## Backend CRUD

\`\`\`odin
// Create
id, err := duckdb_create_user(&svc, &user)

// Read
users, err := duckdb_get_users(&svc)

// Update
err := duckdb_update_user(&svc, &user)

// Delete
err := duckdb_delete_user(&svc, user_id)
\`\`\`

## Frontend CRUD

\`\`\`typescript
// Create
await api.callOrThrow('createUser', [user]);

// Read
const users = await api.callOrThrow<User[]>('getUsers');

// Update
await api.callOrThrow('updateUser', [user]);

// Delete
await api.callOrThrow('deleteUser', [userId]);
\`\`\``;
  }

  private getSecurityGuide(): string {
    return `# Security Guide

## Overview

Comprehensive security implementation for the application.

## Security Features

### Authentication
- Session-based authentication
- Rate limiting (5 attempts max)
- Role-Based Access Control (RBAC)

### Input Validation
- Email validation
- Password strength validation
- SQL injection prevention
- XSS prevention

### Data Protection
- Data masking
- Secure logging
- Sensitive field redaction

## Security Tests

65+ security tests covering:
- Input validation
- XSS prevention
- SQL injection prevention
- Authentication/Authorization
- Rate limiting`;
  }

  private getDuckDBComponents(): string {
    return `# DuckDB Components Guide

## Overview

Angular components for DuckDB CRUD operations.

## Components

### DuckdbDemoComponent
Main DuckDB CRUD interface with:
- Tab-based navigation
- Real-time statistics
- Query builder
- User management

### DuckdbUsersComponent
User management table with:
- Sorting
- Pagination
- Search/filter
- Edit/Delete actions

### DuckdbAnalyticsComponent
Data analytics dashboard with:
- Age distribution charts
- Email domain analysis
- Growth metrics`;
  }

  private getSQLiteComponents(): string {
    return `# SQLite Components Guide

## Overview

Angular components for SQLite CRUD operations.

## Components

### SqliteCrudComponent
Main SQLite CRUD interface with:
- Tab-based navigation (List, Create)
- Real-time statistics
- Search/filter
- Product management

### Features
- Category filtering
- Stock level indicators
- Price formatting
- Status badges`;
  }
}
