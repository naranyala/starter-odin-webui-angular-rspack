# SQLite Angular Components Guide

**Complete guide for SQLite CRUD components in Angular**

---

## Overview

This guide covers the **SQLite Angular components** for building production-ready CRUD interfaces with transactional capabilities.

### Components

- `SqliteCrudComponent` - Main SQLite CRUD interface
- User management with create, read, update, delete operations
- Real-time statistics display
- Search and filter functionality

---

## SqliteCrudComponent

### Features

- ✅ Tab-based navigation (List, Create)
- ✅ Real-time statistics display
- ✅ Search and filter functionality
- ✅ Responsive design with modern UI
- ✅ Form validation
- ✅ Loading states

### Component Structure

```typescript
import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LoggerService } from '../../core/logger.service';
import { ApiService } from '../../core/api.service';

export interface User {
  id: number;
  name: string;
  email: string;
  age: number;
  created_at: string;
}

export interface UserStats {
  total_users: number;
  today_count: number;
  unique_domains: number;
}

@Component({
  selector: 'app-sqlite-crud',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './sqlite.component.html',
  styleUrls: ['./sqlite.component.css']
})
export class SqliteCrudComponent {
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);

  // State
  activeTab = signal<'list' | 'create'>('list');
  isLoading = signal(false);
  stats = signal<UserStats>({ total_users: 0, today_count: 0, unique_domains: 0 });
  users = signal<User[]>([]);
  filteredUsers = signal<User[]>([]);
  searchQuery = '';

  // New user form
  newUser = signal<Partial<User>>({ name: '', email: '', age: 25 });
}
```

### Template Structure

```html
<div class="sqlite-wrapper">
  <div class="sqlite-container">
    <!-- Header -->
    <div class="sqlite-header">
      <div class="sqlite-logo">
        <span class="logo-icon">🗄️</span>
      </div>
      <h1 class="sqlite-title">SQLite CRUD Demo</h1>
      <p class="sqlite-subtitle">Complete CRUD operations with Vlang backend</p>
    </div>

    <!-- Stats Bar -->
    <div class="stats-bar">
      <div class="stat-item">
        <span class="stat-value">{{ stats().total_users }}</span>
        <span class="stat-label">Total Users</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">{{ stats().today_count }}</span>
        <span class="stat-label">Added Today</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">{{ stats().unique_domains }}</span>
        <span class="stat-label">Email Domains</span>
      </div>
    </div>

    <!-- Tabs -->
    <div class="sqlite-tabs">
      <button type="button" class="sqlite-tab" [class.active]="activeTab() === 'list'" (click)="setActiveTab('list')">
        <span class="tab-label">📋 User List</span>
      </button>
      <button type="button" class="sqlite-tab" [class.active]="activeTab() === 'create'" (click)="setActiveTab('create')">
        <span class="tab-label">➕ Add User</span>
      </button>
    </div>

    <!-- List Tab -->
    @if (activeTab() === 'list') {
      <div class="tab-content">
        <div class="toolbar">
          <input type="text" class="search-input" placeholder="Search users..." [(ngModel)]="searchQuery"
            (input)="filterUsers()" />
          <button class="refresh-button" (click)="loadUsers()">🔄 Refresh</button>
        </div>

        @if (isLoading()) {
          <div class="loading">Loading users...</div>
        } @else if (filteredUsers().length === 0) {
          <div class="empty-state">No users found</div>
        } @else {
          <div class="user-table">
            <div class="table-header">
              <div class="col">Name</div>
              <div class="col">Email</div>
              <div class="col">Age</div>
              <div class="col">Created</div>
              <div class="col">Actions</div>
            </div>
            @for (user of filteredUsers(); track user.id) {
              <div class="table-row">
                <div class="col">{{ user.name }}</div>
                <div class="col">{{ user.email }}</div>
                <div class="col">{{ user.age }}</div>
                <div class="col">{{ formatDate(user.created_at) }}</div>
                <div class="col actions">
                  <button class="action-btn edit" (click)="editUser(user)">✏️</button>
                  <button class="action-btn delete" (click)="deleteUser(user)">🗑️</button>
                </div>
              </div>
            }
          </div>
        }
      </div>
    }

    <!-- Create Tab -->
    @if (activeTab() === 'create') {
      <div class="tab-content">
        <form class="user-form" (ngSubmit)="createUser()">
          <div class="form-group">
            <label class="form-label">Name</label>
            <input type="text" class="form-input" [ngModel]="newUserForm.name" 
              (ngModelChange)="updateNewUser('name', $event)" name="name" required />
          </div>
          <div class="form-group">
            <label class="form-label">Email</label>
            <input type="email" class="form-input" [ngModel]="newUserForm.email" 
              (ngModelChange)="updateNewUser('email', $event)" name="email" required />
          </div>
          <div class="form-group">
            <label class="form-label">Age</label>
            <input type="number" class="form-input" [ngModel]="newUserForm.age" 
              (ngModelChange)="updateNewUser('age', $event)" name="age" required min="1" max="150" />
          </div>
          <button type="submit" class="submit-button" [disabled]="isLoading()">
            {{ isLoading() ? 'Creating...' : 'Create User' }}
          </button>
        </form>
      </div>
    }
  </div>
</div>
```

### Key Methods

#### Load Users

```typescript
async loadUsers(): Promise<void> {
  this.isLoading.set(true);
  try {
    const [users, stats] = await Promise.all([
      this.api.callOrThrow<User[]>('sqlite:getUsers'),
      this.api.callOrThrow<UserStats>('sqlite:getUserStats'),
    ]);
    this.users.set(users);
    this.stats.set(stats);
    this.filterUsers();
  } catch (error) {
    this.logger.error('Failed to load users', error);
  } finally {
    this.isLoading.set(false);
  }
}
```

#### Filter Users

```typescript
filterUsers(): void {
  const query = this.searchQuery.toLowerCase();
  this.filteredUsers.set(
    this.users().filter(u =>
      u.name.toLowerCase().includes(query) ||
      u.email.toLowerCase().includes(query)
    )
  );
}
```

#### Create User

```typescript
async createUser(): Promise<void> {
  if (!this.newUser().name || !this.newUser().email || !this.newUser().age) {
    this.logger.warn('Create user validation failed');
    return;
  }

  this.isLoading.set(true);
  try {
    await this.api.callOrThrow('sqlite:createUser', [this.newUser()]);
    this.logger.info('User created successfully');
    this.newUser.set({ name: '', email: '', age: 25 });
    this.setActiveTab('list');
  } catch (error) {
    this.logger.error('Failed to create user', error);
  } finally {
    this.isLoading.set(false);
  }
}
```

#### Edit User

```typescript
async editUser(user: User): Promise<void> {
  this.newUser.set({ ...user });
  this.setActiveTab('create');
  // In production: call updateUser API
}
```

#### Delete User

```typescript
async deleteUser(user: User): Promise<void> {
  if (!confirm(`Delete ${user.name}?`)) {
    return;
  }

  this.isLoading.set(true);
  try {
    await this.api.callOrThrow('sqlite:deleteUser', [user.id]);
    this.logger.info('User deleted');
    await this.loadUsers();
  } catch (error) {
    this.logger.error('Failed to delete user', error);
  } finally {
    this.isLoading.set(false);
  }
}
```

#### Helper Methods

```typescript
formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString();
}

updateNewUser(field: keyof User, value: string | number) {
  this.newUser.update(u => ({ ...u, [field]: value }));
}

setActiveTab(tab: 'list' | 'create'): void {
  this.activeTab.set(tab);
  if (tab === 'list') {
    this.loadUsers();
  }
}
```

### Styling

```css
.sqlite-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100%;
  padding: 20px;
}

.sqlite-container {
  background: rgba(255,255,255,0.95);
  border-radius: 16px;
  padding: 40px;
  width: 100%;
  max-width: 800px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.2);
}

.sqlite-header {
  text-align: center;
  margin-bottom: 25px;
}

.sqlite-logo {
  display: inline-flex;
  width: 70px;
  height: 70px;
  border-radius: 50%;
  background: linear-gradient(135deg, #00b09b, #96c93d);
  justify-content: center;
  align-items: center;
  margin-bottom: 15px;
}

.stats-bar {
  display: flex;
  gap: 20px;
  justify-content: space-around;
  margin-bottom: 25px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 12px;
}

.sqlite-tab.active {
  border-color: #00b09b;
  background: linear-gradient(135deg, #00b09b15, #96c93d15);
}

.submit-button {
  padding: 14px;
  background: linear-gradient(135deg, #00b09b, #96c93d);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

.submit-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,176,155,0.4);
}
```

---

## Service Integration

### SQLite Service

```typescript
import { Injectable, inject } from '@angular/core';
import { ApiService } from '../../core/api.service';

@Injectable({
  providedIn: 'root'
})
export class SQLiteService {
  private readonly api = inject(ApiService);

  async getUsers(): Promise<User[]> {
    return await this.api.callOrThrow<User[]>('sqlite:getUsers');
  }

  async createUser(user: Partial<User>): Promise<{ id: number }> {
    return await this.api.callOrThrow('sqlite:createUser', [user]);
  }

  async updateUser(user: User): Promise<void> {
    await this.api.callOrThrow('sqlite:updateUser', [user]);
  }

  async deleteUser(userId: number): Promise<void> {
    await this.api.callOrThrow('sqlite:deleteUser', [userId]);
  }

  async getUserStats(): Promise<UserStats> {
    return await this.api.callOrThrow<UserStats>('sqlite:getUserStats');
  }
}
```

---

## Best Practices

### 1. Signal-Based State Management

```typescript
// ✅ Good: Use signals for reactive state
users = signal<User[]>([]);
isLoading = signal(false);
activeTab = signal<'list' | 'create'>('list');

// Update state
this.users.set(newUsers);
this.isLoading.set(true);
this.activeTab.set('create');

// ❌ Avoid: Mutable state
users: User[] = [];
isLoading = false;
```

### 2. Error Handling

```typescript
async loadUsers(): Promise<void> {
  try {
    const users = await this.api.callOrThrow<User[]>('sqlite:getUsers');
    this.users.set(users);
  } catch (error) {
    this.logger.error('Failed to load users', error);
    // Show user-friendly error message
  }
}
```

### 3. Loading States

```typescript
@if (isLoading()) {
  <div class="loading">Loading users...</div>
} @else if (filteredUsers().length === 0) {
  <div class="empty-state">No users found</div>
} @else {
  <!-- Display data -->
}
```

### 4. Form Validation

```typescript
async createUser(): Promise<void> {
  // Client-side validation
  if (!this.newUser().name || !this.newUser().email) {
    this.logger.warn('Validation failed');
    return;
  }

  // Age validation
  if (this.newUser().age < 1 || this.newUser().age > 150) {
    this.logger.warn('Invalid age');
    return;
  }

  // Proceed with creation
  this.isLoading.set(true);
  try {
    await this.api.callOrThrow('sqlite:createUser', [this.newUser()]);
    // Success handling
  } finally {
    this.isLoading.set(false);
  }
}
```

### 5. Confirmation Dialogs

```typescript
async deleteUser(user: User): Promise<void> {
  if (!confirm(`Delete ${user.name}?`)) {
    return;
  }

  // Proceed with deletion
}
```

---

## Testing

### Component Tests

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { SqliteCrudComponent } from './sqlite.component';
import { ApiService } from '../../core/api.service';
import { LoggerService } from '../../core/logger.service';

describe('SqliteCrudComponent', () => {
  let component: SqliteCrudComponent;
  let fixture: ComponentFixture<SqliteCrudComponent>;
  let apiService: jasmine.SpyObj<ApiService>;

  beforeEach(async () => {
    const apiSpy = jasmine.createSpyObj('ApiService', ['callOrThrow']);
    
    await TestBed.configureTestingModule({
      imports: [SqliteCrudComponent],
      providers: [
        { provide: ApiService, useValue: apiSpy },
        LoggerService
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(SqliteCrudComponent);
    component = fixture.componentInstance;
    apiService = TestBed.inject(ApiService) as jasmine.SpyObj<ApiService>;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load users on init', async () => {
    apiService.callOrThrow.and.resolveTo([{ id: 1, name: 'Test' }]);
    
    component.ngOnInit();
    await fixture.whenStable();
    
    expect(component.users().length).toBeGreaterThan(0);
  });

  it('should create user', async () => {
    apiService.callOrThrow.and.resolveTo({ id: 1 });
    
    component.newUser.set({ name: 'Test', email: 'test@example.com', age: 30 });
    await component.createUser();
    
    expect(apiService.callOrThrow).toHaveBeenCalledWith('sqlite:createUser', [
      jasmine.objectContaining({ name: 'Test' })
    ]);
  });

  it('should filter users by search query', () => {
    component.users.set([
      { id: 1, name: 'John', email: 'john@example.com', age: 30, created_at: '' },
      { id: 2, name: 'Jane', email: 'jane@example.com', age: 25, created_at: '' }
    ]);
    
    component.searchQuery = 'john';
    component.filterUsers();
    
    expect(component.filteredUsers().length).toBe(1);
    expect(component.filteredUsers()[0].name).toBe('John');
  });
});
```

---

## Comparison with DuckDB Components

| Feature | SQLite Component | DuckDB Component |
|---------|-----------------|------------------|
| **Tabs** | List, Create | List, Create, Query Builder |
| **Complexity** | Simple | Advanced |
| **Query Builder** | No | Yes |
| **Analytics** | Basic stats | Advanced analytics |
| **Use Case** | Transactional | Analytical |

### When to Use Each

**Use SQLite Component when:**
- Simple CRUD operations needed
- Transactional data management
- Lightweight deployment
- Embedded storage

**Use DuckDB Component when:**
- Complex queries needed
- Analytical operations
- Data warehousing
- Query builder required

---

## Troubleshooting

### Common Issues

**1. Users not loading**
```typescript
// Check API service connection
try {
  const users = await this.api.callOrThrow<User[]>('sqlite:getUsers');
} catch (error) {
  this.logger.error('API call failed', error);
}
```

**2. Form not submitting**
```typescript
// Ensure ngModel is properly bound
<input [ngModel]="newUserForm.name" 
       (ngModelChange)="updateNewUser('name', $event)" 
       name="name" required />
```

**3. Search not filtering**
```typescript
// Ensure filterUsers is called on input
<input [(ngModel)]="searchQuery" (input)="filterUsers()" />
```

---

## Resources

- [Backend Integration](../backend/sqlite-integration.md)
- [DuckDB Components](./duckdb-components.md)
- [CRUD Operations Guide](../guides/crud-operations-guide.md)

---

**Last Updated:** 2026-03-30
**Status:** Production Ready
