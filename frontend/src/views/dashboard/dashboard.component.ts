/**
 * Dashboard Component
 *
 * Main dashboard with statistics and navigation to different data views
 * Supports switching between SQLite and DuckDB databases
 */

import { Component, signal, inject, OnInit, OnDestroy, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LoggerService } from '../../core/logger.service';
import { ApiService } from '../../core/api.service';
import { DatabaseSelectorService, DatabaseType } from '../../core/database-selector.service';
import { DummyDataGeneratorService, User, Product, Order } from '../../core/dummy-data-generator.service';
import { DemoDataService } from '../../core/demo-data.service';
import { SqliteCrudComponent } from '../sqlite/sqlite.component';
import { DuckdbUsersComponent } from '../duckdb/duckdb-users.component';
import { DuckdbProductsComponent } from '../duckdb/duckdb-products.component';
import { DuckdbOrdersComponent } from '../duckdb/duckdb-orders.component';
import { DuckdbAnalyticsComponent } from '../duckdb/duckdb-analytics.component';

export interface DashboardStats {
  totalUsers: number;
  totalProducts: number;
  totalOrders: number;
  totalRevenue: number;
  activeUsers: number;
  pendingOrders: number;
}

export interface NavItem {
  id: string;
  label: string;
  icon: string;
  active: boolean;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    SqliteCrudComponent,
    DuckdbUsersComponent,
    DuckdbProductsComponent,
    DuckdbOrdersComponent,
    DuckdbAnalyticsComponent,
  ],
  template: `
    <div class="dashboard-container">
      <!-- Sidebar Navigation -->
      <aside class="sidebar" [class.collapsed]="sidebarCollapsed()">
        <div class="sidebar-header">
          <div class="logo">
            <span class="logo-icon">{{ currentDbConfig().icon }}</span>
            @if (!sidebarCollapsed()) {
              <span class="logo-text">{{ currentDbConfig().name }} Admin</span>
            }
          </div>
        </div>

        <!-- Database Switcher -->
        <div class="database-switcher" [class.collapsed]="sidebarCollapsed()">
          <div class="switcher-label">Database</div>
          <div class="switcher-buttons">
            <button
              class="db-btn"
              [class.active]="currentDb() === 'sqlite'"
              (click)="switchDatabase('sqlite')"
              [disabled]="isSwitching()"
              title="Switch to SQLite"
            >
              <span class="db-icon">🗄️</span>
              @if (!sidebarCollapsed()) {
                <span class="db-name">SQLite</span>
              }
            </button>
            <button
              class="db-btn"
              [class.active]="currentDb() === 'duckdb'"
              (click)="switchDatabase('duckdb')"
              [disabled]="isSwitching()"
              title="Switch to DuckDB"
            >
              <span class="db-icon">🦆</span>
              @if (!sidebarCollapsed()) {
                <span class="db-name">DuckDB</span>
              }
            </button>
          </div>
        </div>

        <nav class="sidebar-nav">
          @for (item of navItems(); track item.id) {
            <button
              class="nav-item"
              [class.active]="activeView() === item.id"
              (click)="onNavClick(item.id)"
              [attr.title]="sidebarCollapsed() ? item.label : ''"
            >
              <span class="nav-icon">{{ item.icon }}</span>
              @if (!sidebarCollapsed()) {
                <span class="nav-label">{{ item.label }}</span>
              }
            </button>
          }
        </nav>

        <div class="sidebar-footer">
          <button class="nav-item" (click)="toggleSidebar()" title="Toggle sidebar">
            <span class="nav-icon">{{ sidebarCollapsed() ? '→' : '←' }}</span>
            @if (!sidebarCollapsed()) {
              <span class="nav-label">Collapse</span>
            }
          </button>
        </div>
      </aside>

      <!-- Main Content -->
      <main class="main-content">
        <!-- Top Header -->
        <header class="top-header">
          <div class="header-left">
            <button class="menu-toggle" (click)="toggleSidebar()" title="Toggle menu">
              <span>☰</span>
            </button>
            <div class="title-with-badge">
              <h1 class="page-title">{{ currentPageTitle() }}</h1>
              <span class="db-badge" [style.background]="currentDbConfig().color + '20'" [style.borderColor]="currentDbConfig().color">
                <span class="db-badge-icon">{{ currentDbConfig().icon }}</span>
                <span class="db-badge-text">{{ currentDbConfig().name }}</span>
              </span>
            </div>
          </div>
          <div class="header-right">
            <div class="header-stats">
              <div class="mini-stat">
                <span class="mini-stat-label">Total Records</span>
                <span class="mini-stat-value">{{ stats().totalUsers + stats().totalProducts + stats().totalOrders }}</span>
              </div>
            </div>
            <button class="btn-seed" (click)="generateSeedData()" title="Generate sample data">
              <span>🌱</span>
              @if (!sidebarCollapsed()) {
                <span>Seed Data</span>
              }
            </button>
            <button class="btn-refresh" (click)="refreshAll()" title="Refresh all data">
              <span class="refresh-icon" [class.spinning]="isLoading()">🔄</span>
            </button>
          </div>
        </header>

        <!-- Stats Cards -->
        <div class="stats-grid">
          <div class="stat-card stat-primary">
            <div class="stat-icon">👥</div>
            <div class="stat-content">
              <span class="stat-value">{{ stats().totalUsers | number }}</span>
              <span class="stat-label">Total Users</span>
            </div>
          </div>
          <div class="stat-card stat-success">
            <div class="stat-icon">📦</div>
            <div class="stat-content">
              <span class="stat-value">{{ stats().totalProducts | number }}</span>
              <span class="stat-label">Products</span>
            </div>
          </div>
          <div class="stat-card stat-warning">
            <div class="stat-icon">🛒</div>
            <div class="stat-content">
              <span class="stat-value">{{ stats().totalOrders | number }}</span>
              <span class="stat-label">Orders</span>
            </div>
          </div>
          <div class="stat-card stat-info">
            <div class="stat-icon">💰</div>
            <div class="stat-content">
              <span class="stat-value">{{ stats().totalRevenue | number:'1.2-2' }}</span>
              <span class="stat-label">Revenue</span>
            </div>
          </div>
        </div>

        <!-- Content Area -->
        <div class="content-area">
          @if (currentDb() === 'sqlite') {
            @if (activeView() === 'users') {
              <app-sqlite-crud></app-sqlite-crud>
            }
          } @else {
            @if (activeView() === 'users') {
              <app-duckdb-users (statsChange)="onStatsUpdate($any($event))"></app-duckdb-users>
            } @else if (activeView() === 'products') {
              <app-duckdb-products (statsChange)="onStatsUpdate($any($event))"></app-duckdb-products>
            } @else if (activeView() === 'orders') {
              <app-duckdb-orders (statsChange)="onStatsUpdate($any($event))"></app-duckdb-orders>
            } @else if (activeView() === 'analytics') {
              <app-duckdb-analytics></app-duckdb-analytics>
            }
          }
        </div>
      </main>
    </div>
  `,
  styles: [`
    .dashboard-container {
      display: flex;
      height: 100vh;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      overflow: hidden;
    }

    /* Sidebar */
    .sidebar {
      width: 260px;
      background: rgba(15, 23, 42, 0.95);
      border-right: 1px solid rgba(148, 163, 184, 0.1);
      display: flex;
      flex-direction: column;
      transition: width 0.3s ease;
      backdrop-filter: blur(10px);
    }

    .sidebar.collapsed {
      width: 70px;
    }

    .sidebar-header {
      padding: 20px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .logo {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .logo-icon {
      font-size: 32px;
    }

    .logo-text {
      font-size: 20px;
      font-weight: 700;
      color: #fff;
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    /* Database Switcher */
    .database-switcher {
      padding: 16px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .database-switcher.collapsed {
      padding: 12px 8px;
    }

    .switcher-label {
      font-size: 11px;
      text-transform: uppercase;
      color: #64748b;
      letter-spacing: 0.5px;
      margin-bottom: 10px;
      font-weight: 600;
    }

    .database-switcher.collapsed .switcher-label {
      display: none;
    }

    .switcher-buttons {
      display: flex;
      gap: 8px;
    }

    .db-btn {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      padding: 10px 8px;
      background: rgba(148, 163, 184, 0.1);
      border: 2px solid transparent;
      border-radius: 10px;
      color: #94a3b8;
      cursor: pointer;
      transition: all 0.2s;
    }

    .db-btn:hover:not(:disabled) {
      background: rgba(148, 163, 184, 0.2);
      color: #fff;
    }

    .db-btn.active {
      border-color: #06b6d4;
      background: rgba(6, 182, 212, 0.2);
      color: #06b6d4;
    }

    .db-btn:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .db-btn.collapsed {
      padding: 8px;
    }

    .db-icon {
      font-size: 20px;
    }

    .db-name {
      font-size: 11px;
      font-weight: 600;
      white-space: nowrap;
    }

    .database-switcher.collapsed .db-name {
      display: none;
    }

    .sidebar-nav {
      flex: 1;
      padding: 16px 12px;
      display: flex;
      flex-direction: column;
      gap: 8px;
      overflow-y: auto;
    }

    .nav-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 16px;
      background: transparent;
      border: none;
      border-radius: 10px;
      color: #94a3b8;
      cursor: pointer;
      transition: all 0.2s;
      text-align: left;
      width: 100%;
    }

    .nav-item:hover {
      background: rgba(59, 130, 246, 0.1);
      color: #fff;
    }

    .nav-item.active {
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: #fff;
      box-shadow: 0 4px 15px rgba(6, 182, 212, 0.4);
    }

    .nav-icon {
      font-size: 20px;
      width: 24px;
      text-align: center;
    }

    .nav-label {
      font-size: 14px;
      font-weight: 500;
      white-space: nowrap;
    }

    .sidebar-footer {
      padding: 16px;
      border-top: 1px solid rgba(148, 163, 184, 0.1);
    }

    /* Main Content */
    .main-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      background: #0f172a;
    }

    .top-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px 32px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      background: rgba(15, 23, 42, 0.5);
    }

    .header-left {
      display: flex;
      align-items: center;
      gap: 20px;
    }

    .menu-toggle {
      display: none;
      padding: 8px 12px;
      background: rgba(148, 163, 184, 0.1);
      border: none;
      border-radius: 8px;
      color: #fff;
      cursor: pointer;
      font-size: 20px;
    }

    .page-title {
      margin: 0;
      font-size: 24px;
      font-weight: 600;
      color: #fff;
    }

    .header-right {
      display: flex;
      align-items: center;
      gap: 20px;
    }

    .header-stats {
      display: flex;
      gap: 16px;
    }

    .mini-stat {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
    }

    .mini-stat-label {
      font-size: 12px;
      color: #64748b;
    }

    .mini-stat-value {
      font-size: 18px;
      font-weight: 600;
      color: #06b6d4;
    }

    .btn-refresh {
      padding: 10px 16px;
      background: rgba(59, 130, 246, 0.2);
      border: 1px solid rgba(59, 130, 246, 0.3);
      border-radius: 8px;
      color: #60a5fa;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn-refresh:hover {
      background: rgba(59, 130, 246, 0.3);
    }

    .btn-seed {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 16px;
      background: linear-gradient(135deg, #10b981, #059669);
      border: none;
      border-radius: 8px;
      color: #fff;
      cursor: pointer;
      transition: all 0.2s;
      font-weight: 600;
      font-size: 13px;
    }

    .btn-seed:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(16, 185, 129, 0.4);
    }

    .title-with-badge {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .db-badge {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }

    .db-badge-icon {
      font-size: 16px;
    }

    .db-badge-text {
      white-space: nowrap;
    }

    .refresh-icon.spinning {
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    /* Stats Grid */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      padding: 24px 32px;
    }

    .stat-card {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 20px;
      background: rgba(30, 41, 59, 0.5);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      transition: all 0.3s;
    }

    .stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
    }

    .stat-icon {
      font-size: 40px;
      width: 60px;
      height: 60px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: rgba(255, 255, 255, 0.05);
      border-radius: 12px;
    }

    .stat-content {
      display: flex;
      flex-direction: column;
    }

    .stat-value {
      font-size: 28px;
      font-weight: 700;
      color: #fff;
    }

    .stat-label {
      font-size: 13px;
      color: #64748b;
      margin-top: 4px;
    }

    .stat-primary .stat-icon { background: rgba(59, 130, 246, 0.2); }
    .stat-success .stat-icon { background: rgba(16, 185, 129, 0.2); }
    .stat-warning .stat-icon { background: rgba(245, 158, 11, 0.2); }
    .stat-info .stat-icon { background: rgba(6, 182, 212, 0.2); }

    /* Content Area */
    .content-area {
      flex: 1;
      overflow-y: auto;
      padding: 0 32px 32px;
    }

    /* Responsive */
    @media (max-width: 1200px) {
      .stats-grid {
        grid-template-columns: repeat(2, 1fr);
      }
    }

    @media (max-width: 768px) {
      .sidebar {
        position: fixed;
        left: 0;
        top: 0;
        height: 100vh;
        z-index: 1000;
        transform: translateX(-100%);
      }

      .sidebar:not(.collapsed) {
        transform: translateX(0);
      }

      .menu-toggle {
        display: block;
      }

      .stats-grid {
        grid-template-columns: 1fr;
        padding: 16px 20px;
      }

      .top-header {
        padding: 16px 20px;
      }

      .content-area {
        padding: 0 20px 20px;
      }
    }
  `]
})
export class DashboardComponent implements OnInit, OnDestroy {
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);
  private readonly dbSelector = inject(DatabaseSelectorService);
  private readonly dummyDataGenerator = inject(DummyDataGeneratorService);
  private readonly demoData = inject(DemoDataService);

  sidebarCollapsed = signal(false);
  activeView = signal<'users' | 'products' | 'orders' | 'analytics'>('users');
  isLoading = signal(false);
  stats = signal<DashboardStats>({
    totalUsers: 0,
    totalProducts: 0,
    totalOrders: 0,
    totalRevenue: 0,
    activeUsers: 0,
    pendingOrders: 0,
  });

  // Database signals
  currentDb = signal<DatabaseType>('duckdb');
  isSwitching = signal(false);
  currentDbConfig = computed(() => this.dbSelector.getDatabaseConfig(this.currentDb()));

  navItems = signal<NavItem[]>([
    { id: 'users', label: 'Users', icon: '👥', active: true },
    { id: 'products', label: 'Products', icon: '📦', active: false },
    { id: 'orders', label: 'Orders', icon: '🛒', active: false },
    { id: 'analytics', label: 'Analytics', icon: '📊', active: false },
  ]);

  currentPageTitle = signal('Users');

  ngOnInit(): void {
    // Initialize demo data service
    this.demoData.initialize();
    this.loadDashboardStats();
    this.setupDatabaseChangeListener();
  }

  ngOnDestroy(): void {
    window.removeEventListener('database-change', this.onDatabaseChange as EventListener);
  }

  /**
   * Setup database change listener
   */
  private setupDatabaseChangeListener(): void {
    this.onDatabaseChange = (event: Event) => {
      const customEvent = event as CustomEvent<{ database: DatabaseType }>;
      this.logger.info('Database changed to', customEvent.detail.database);
      this.loadDashboardStats();
    };
    window.addEventListener('database-change', this.onDatabaseChange as EventListener);
  }

  private onDatabaseChange: ((event: Event) => void) | undefined;

  /**
   * Switch database
   */
  async switchDatabase(type: DatabaseType): Promise<void> {
    if (this.currentDb() === type) return;
    
    this.isSwitching.set(true);
    try {
      // Update database selector service
      await this.dbSelector.switchDatabase(type);
      // Update demo data service
      this.demoData.setDatabaseType(type);
      // Update local state
      this.currentDb.set(type);
      this.loadDashboardStats();
    } catch (error) {
      this.logger.error('Failed to switch database', error);
    } finally {
      this.isSwitching.set(false);
    }
  }

  /**
   * Generate new seed data
   */
  async generateSeedData(): Promise<void> {
    this.isLoading.set(true);
    try {
      this.demoData.addSeedData(10, 15, 20);
      this.logger.info('Seed data generated');
      this.loadDashboardStats();
    } catch (error) {
      this.logger.error('Failed to generate seed data', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  /**
   * Get current data based on selected database
   */
  private getCurrentData(): { users: User[]; products: Product[]; orders: Order[] } | null {
    return {
      users: this.demoData.getUsers(),
      products: this.demoData.getProducts(),
      orders: this.demoData.getOrders(),
    };
  }

  setActiveView(viewId: 'users' | 'products' | 'orders' | 'analytics'): void {
    this.activeView.set(viewId);
    this.currentPageTitle.set(viewId.charAt(0).toUpperCase() + viewId.slice(1));
    this.loadDashboardStats();
  }

  onNavClick(viewId: string): void {
    this.setActiveView(viewId as 'users' | 'products' | 'orders' | 'analytics');
  }

  toggleSidebar(): void {
    this.sidebarCollapsed.update(v => !v);
  }

  async loadDashboardStats(): Promise<void> {
    this.isLoading.set(true);
    try {
      const currentData = this.getCurrentData();
      
      if (!currentData) {
        this.stats.set({
          totalUsers: 0,
          totalProducts: 0,
          totalOrders: 0,
          totalRevenue: 0,
          activeUsers: 0,
          pendingOrders: 0,
        });
        return;
      }

      const { users, products, orders } = currentData;

      this.stats.set({
        totalUsers: users.length,
        totalProducts: products.length,
        totalOrders: orders.length,
        totalRevenue: orders.reduce((sum: number, o: Order) => sum + (o.total || 0), 0),
        activeUsers: users.filter((u: User) => u.status !== 'inactive').length,
        pendingOrders: orders.filter((o: Order) => o.status === 'pending').length,
      });
    } catch (error) {
      this.logger.error('Failed to load dashboard stats', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  onStatsUpdate(event: { type: string; count: number }): void {
    this.stats.update(stats => ({
      ...stats,
      [event.type]: event.count,
    }));
  }

  refreshAll(): void {
    this.loadDashboardStats();
  }
}
