# DuckDB Angular Components Guide

**Complete guide for DuckDB CRUD components in Angular**

---

## Overview

This guide covers the **DuckDB Angular components** for building production-ready CRUD interfaces with analytical capabilities.

### Components

- `DuckdbDemoComponent` - Main DuckDB CRUD interface with tabs
- `DuckdbUsersComponent` - User management table
- `DuckdbProductsComponent` - Product catalog
- `DuckdbOrdersComponent` - Order management
- `DuckdbAnalyticsComponent` - Data analytics dashboard

---

## DuckdbDemoComponent

### Features

- ✅ Tab-based navigation (List, Create, Query Builder)
- ✅ Real-time statistics display
- ✅ Search and filter functionality
- ✅ Query builder for custom SQL
- ✅ Responsive design with modern UI

### Component Structure

```typescript
import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LoggerService } from '../../core/logger.service';
import { ApiService } from '../../core/api.service';

@Component({
  selector: 'app-duckdb-crud',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './duckdb-demo.component.html',
  styleUrls: ['./duckdb-demo.component.css']
})
export class DuckdbDemoComponent implements OnInit {
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);

  // State
  activeTab = signal<'list' | 'create' | 'query'>('list');
  isLoading = signal(false);
  stats = signal<UserStats>({ total_users: 0, today_count: 0, unique_domains: 0 });
  users = signal<User[]>([]);
  filteredUsers = signal<User[]>([]);
  searchQuery = '';
  queryResult = signal<unknown>(null);

  // New user form
  newUser = signal<Partial<User>>({ name: '', email: '', age: 25 });

  // Query builder
  queryFields = signal('*');
  queryWhere = signal('');
  queryOrder = signal('');
  queryLimit = signal(10);
}
```

### Template Structure

```html
<div class="duckdb-wrapper">
  <div class="duckdb-container">
    <!-- Header -->
    <div class="duckdb-header">
      <div class="header-logo">
        <span class="logo-icon">🦆</span>
      </div>
      <h1 class="header-title">DuckDB CRUD Demo</h1>
      <p class="header-subtitle">Analytical database with query builder</p>
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
    <div class="tabs">
      <button type="button" class="tab" [class.active]="activeTab() === 'list'" (click)="setActiveTab('list')">
        <span class="tab-label">📋 User List</span>
      </button>
      <button type="button" class="tab" [class.active]="activeTab() === 'create'" (click)="setActiveTab('create')">
        <span class="tab-label">➕ Add User</span>
      </button>
      <button type="button" class="tab" [class.active]="activeTab() === 'query'" (click)="setActiveTab('query')">
        <span class="tab-label">🔍 Query Builder</span>
      </button>
    </div>

    <!-- Tab Contents -->
    @if (activeTab() === 'list') {
      <!-- List Tab Content -->
    }
    @if (activeTab() === 'create') {
      <!-- Create Tab Content -->
    }
    @if (activeTab() === 'query') {
      <!-- Query Builder Tab Content -->
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
      this.api.callOrThrow<User[]>('getUsers'),
      this.api.callOrThrow<UserStats>('getUserStats'),
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

#### Create User

```typescript
async createUser(): Promise<void> {
  if (!this.newUser().name || !this.newUser().email || !this.newUser().age) {
    this.logger.warn('Create user validation failed');
    return;
  }

  this.isLoading.set(true);
  try {
    await this.api.callOrThrow('createUser', [this.newUser()]);
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

#### Delete User

```typescript
async deleteUser(user: User): Promise<void> {
  if (!confirm(`Delete ${user.name}?`)) {
    return;
  }

  this.isLoading.set(true);
  try {
    await this.api.callOrThrow('deleteUser', [user.id]);
    this.logger.info('User deleted');
    await this.loadUsers();
  } catch (error) {
    this.logger.error('Failed to delete user', error);
  } finally {
    this.isLoading.set(false);
  }
}
```

#### Execute Query

```typescript
async executeQuery(): Promise<void> {
  this.isLoading.set(true);
  try {
    // Build SQL query from builder inputs
    let sql = `SELECT ${this.queryFields()}`;
    sql += ' FROM users';

    if (this.queryWhere()) {
      sql += ` WHERE ${this.queryWhere()}`;
    }

    if (this.queryOrder()) {
      sql += ` ORDER BY ${this.queryOrder()}`;
    }

    if (this.queryLimit()) {
      sql += ` LIMIT ${this.queryLimit()}`;
    }

    this.logger.info('Executing query:', sql);

    const result = await this.api.callOrThrow('executeQuery', [sql]);
    this.queryResult.set(result);
  } catch (error) {
    this.logger.error('Query execution failed', error);
    this.queryResult.set({ error: String(error) });
  } finally {
    this.isLoading.set(false);
  }
}
```

### Styling

```css
.duckdb-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
}

.duckdb-container {
  background: rgba(255,255,255,0.98);
  border-radius: 20px;
  padding: 40px;
  width: 100%;
  max-width: 900px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
}

.stats-bar {
  display: flex;
  gap: 20px;
  justify-content: space-around;
  margin-bottom: 30px;
  padding: 25px;
  background: linear-gradient(135deg, #f8f9fa, #e9ecef);
  border-radius: 15px;
}

.tab.active {
  border-color: #00b4d8;
  background: linear-gradient(135deg, #e0f7ff, #e8f5e9);
  color: #0077b6;
}
```

---

## DuckdbUsersComponent

### Features

- ✅ Data table with sorting
- ✅ Pagination support
- ✅ Bulk operations
- ✅ Inline editing

### Usage

```typescript
import { Component, inject, OnInit } from '@angular/core';
import { DataTableComponent, DataTableConfig } from '../shared/data-table.component';
import { DuckDBService } from '../../services/duckdb.service';

@Component({
  selector: 'app-duckdb-users',
  standalone: true,
  imports: [DataTableComponent],
  template: `
    <app-data-table
      [data]="users()"
      [config]="tableConfig"
      (delete)="deleteUser($event)"
      (edit)="editUser($event)">
    </app-data-table>
  `
})
export class DuckdbUsersComponent implements OnInit {
  private readonly duckDB = inject(DuckDBService);
  
  users = signal<User[]>([]);
  
  tableConfig: DataTableConfig<User> = {
    columns: [
      { key: 'name', label: 'Name', sortable: true },
      { key: 'email', label: 'Email', sortable: true },
      { key: 'age', label: 'Age', sortable: true },
      { key: 'created_at', label: 'Created', sortable: true, pipe: 'date' }
    ],
    actions: ['edit', 'delete']
  };
}
```

---

## DuckdbProductsComponent

### Features

- ✅ Product catalog display
- ✅ Category filtering
- ✅ Price sorting
- ✅ Stock status indicators

### Usage

```typescript
@Component({
  selector: 'app-duckdb-products',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="products-container">
      <div class="filters">
        <select [(ngModel)]="selectedCategory" (change)="filterProducts()">
          <option value="">All Categories</option>
          @for (cat of categories; track cat) {
            <option [value]="cat">{{ cat }}</option>
          }
        </select>
      </div>
      
      <div class="products-grid">
        @for (product of filteredProducts(); track product.id) {
          <div class="product-card">
            <h3>{{ product.name }}</h3>
            <p class="price">\${{ product.price }}</p>
            <span class="status {{ product.status }}">{{ product.status }}</span>
          </div>
        }
      </div>
    </div>
  `
})
export class DuckdbProductsComponent implements OnInit {
  products = signal<Product[]>([]);
  filteredProducts = signal<Product[]>([]);
  selectedCategory = '';
  categories = ['Electronics', 'Books', 'Clothing'];
}
```

---

## DuckdbOrdersComponent

### Features

- ✅ Order timeline view
- ✅ Status tracking
- ✅ Customer information
- ✅ Revenue calculations

### Usage

```typescript
@Component({
  selector: 'app-duckdb-orders',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="orders-container">
      <div class="stats-summary">
        <div class="stat">Total Revenue: \${{ totalRevenue() }}</div>
        <div class="stat">Pending Orders: {{ pendingOrders() }}</div>
      </div>
      
      <div class="orders-list">
        @for (order of orders(); track order.id) {
          <div class="order-item">
            <div class="order-header">
              <span class="order-id">#{{ order.id }}</span>
              <span class="order-status {{ order.status }}">{{ order.status }}</span>
            </div>
            <div class="order-details">
              <p>Customer: {{ order.customer_name }}</p>
              <p>Total: \${{ order.total }}</p>
              <p>Date: {{ order.created_at | date }}</p>
            </div>
          </div>
        }
      </div>
    </div>
  `
})
export class DuckdbOrdersComponent implements OnInit {
  orders = signal<Order[]>([]);
  
  totalRevenue = computed(() => 
    this.orders().reduce((sum, order) => sum + order.total, 0)
  );
  
  pendingOrders = computed(() => 
    this.orders().filter(o => o.status === 'Pending').length
  );
}
```

---

## DuckdbAnalyticsComponent

### Features

- ✅ Data visualizations
- ✅ Trend analysis
- ✅ Custom metrics
- ✅ Export capabilities

### Usage

```typescript
@Component({
  selector: 'app-duckdb-analytics',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="analytics-dashboard">
      <div class="metrics-grid">
        <div class="metric-card">
          <h3>User Growth</h3>
          <div class="metric-value">{{ growthRate() }}%</div>
          <div class="metric-trend up">↑ 12%</div>
        </div>
        
        <div class="metric-card">
          <h3>Average Age</h3>
          <div class="metric-value">{{ averageAge() }}</div>
        </div>
      </div>
      
      <div class="chart-container">
        <canvas #userChart></canvas>
      </div>
    </div>
  `
})
export class DuckdbAnalyticsComponent implements OnInit, AfterViewInit {
  @ViewChild('userChart') userChart!: ElementRef;
  
  analytics = signal<AnalyticsData>(null);
  
  growthRate = computed(() => {
    const data = this.analytics();
    if (!data) return 0;
    return ((data.today_count - data.yesterday_count) / data.yesterday_count) * 100;
  });
  
  averageAge = computed(() => {
    const data = this.analytics();
    if (!data) return 0;
    return data.total_age / data.total_users;
  });
}
```

---

## Service Integration

### DuckDB Service

```typescript
import { Injectable, inject } from '@angular/core';
import { ApiService } from '../../core/api.service';

@Injectable({
  providedIn: 'root'
})
export class DuckDBService {
  private readonly api = inject(ApiService);

  async getUsers(): Promise<User[]> {
    return await this.api.callOrThrow<User[]>('getUsers');
  }

  async createUser(user: Partial<User>): Promise<{ id: number }> {
    return await this.api.callOrThrow('createUser', [user]);
  }

  async updateUser(user: User): Promise<void> {
    await this.api.callOrThrow('updateUser', [user]);
  }

  async deleteUser(userId: number): Promise<void> {
    await this.api.callOrThrow('deleteUser', [userId]);
  }

  async getUserStats(): Promise<UserStats> {
    return await this.api.callOrThrow<UserStats>('getUserStats');
  }

  async executeQuery(sql: string): Promise<any> {
    return await this.api.callOrThrow('executeQuery', [sql]);
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

// Update state
this.users.set(newUsers);
this.isLoading.set(true);

// ❌ Avoid: Mutable state
users: User[] = [];
```

### 2. Error Handling

```typescript
async loadUsers(): Promise<void> {
  try {
    const users = await this.api.callOrThrow<User[]>('getUsers');
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
  <div class="loading-state">
    <span class="loading-spinner">⏳</span>
    <span>Loading...</span>
  </div>
} @else if (users().length === 0) {
  <div class="empty-state">No users found</div>
} @else {
  <!-- Display data -->
}
```

### 4. Form Validation

```typescript
async createUser(): Promise<void> {
  if (!this.newUser().name || !this.newUser().email) {
    this.logger.warn('Validation failed');
    return;
  }
  
  // Proceed with creation
}
```

---

## Testing

### Component Tests

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DuckdbDemoComponent } from './duckdb-demo.component';
import { ApiService } from '../../core/api.service';
import { LoggerService } from '../../core/logger.service';

describe('DuckdbDemoComponent', () => {
  let component: DuckdbDemoComponent;
  let fixture: ComponentFixture<DuckdbDemoComponent>;
  let apiService: jasmine.SpyObj<ApiService>;

  beforeEach(async () => {
    const apiSpy = jasmine.createSpyObj('ApiService', ['callOrThrow']);
    
    await TestBed.configureTestingModule({
      imports: [DuckdbDemoComponent],
      providers: [
        { provide: ApiService, useValue: apiSpy },
        LoggerService
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(DuckdbDemoComponent);
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
});
```

---

## Resources

- [Backend Integration](../backend/duckdb-integration.md)
- [SQLite Components](./sqlite-components.md)
- [CRUD Operations Guide](../guides/crud-operations-guide.md)

---

**Last Updated:** 2026-03-30
**Status:** Production Ready
