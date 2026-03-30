/**
 * Professional DuckDB Analytics & CRUD Component
 * 
 * Production-ready interface for DuckDB operations with:
 * - Advanced analytics dashboard
 * - Complete CRUD operations
 * - Query builder with visual interface
 * - Real-time statistics
 * - Professional UI/UX
 */

import { Component, signal, inject, OnInit, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LoggerService } from '../../core/logger.service';
import { ApiService } from '../../core/api.service';
import { DatabaseManagementService } from '../../app/services/database-management.service';

// ============================================================================
// Type Definitions
// ============================================================================

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
  avg_age: number;
  growth_rate?: number;
}

export interface QueryResult {
  sql: string;
  data: any[];
  execution_time_ms: number;
  rows_affected: number;
}

type TabType = 'dashboard' | 'users' | 'analytics' | 'query';

// ============================================================================
// Main Component
// ============================================================================

@Component({
  selector: 'app-duckdb-professional',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="duckdb-professional">
      <!-- Header -->
      <header class="dp-header">
        <div class="dp-header__brand">
          <div class="dp-logo">🦆</div>
          <div class="dp-header__titles">
            <h1 class="dp-header__title">DuckDB Analytics</h1>
            <p class="dp-header__subtitle">Production-ready analytical database interface</p>
          </div>
        </div>
        <div class="dp-header__actions">
          <button class="dp-btn dp-btn--outline" (click)="refreshAll()" [disabled]="isLoading()">
            <span class="dp-btn__icon">🔄</span>
            Refresh All
          </button>
        </div>
      </header>

      <!-- Navigation Tabs -->
      <nav class="dp-tabs">
        <button 
          class="dp-tab" 
          [class.dp-tab--active]="activeTab() === 'dashboard'"
          (click)="setActiveTab('dashboard')"
        >
          <span class="dp-tab__icon">📊</span>
          <span class="dp-tab__label">Dashboard</span>
        </button>
        <button 
          class="dp-tab" 
          [class.dp-tab--active]="activeTab() === 'users'"
          (click)="setActiveTab('users')"
        >
          <span class="dp-tab__icon">👥</span>
          <span class="dp-tab__label">User Management</span>
        </button>
        <button 
          class="dp-tab" 
          [class.dp-tab--active]="activeTab() === 'analytics'"
          (click)="setActiveTab('analytics')"
        >
          <span class="dp-tab__icon">📈</span>
          <span class="dp-tab__label">Analytics</span>
        </button>
        <button 
          class="dp-tab" 
          [class.dp-tab--active]="activeTab() === 'query'"
          (click)="setActiveTab('query')"
        >
          <span class="dp-tab__icon">🔍</span>
          <span class="dp-tab__label">Query Builder</span>
        </button>
      </nav>

      <!-- Main Content -->
      <main class="dp-content">
        <!-- Dashboard Tab -->
        @if (activeTab() === 'dashboard') {
          <div class="dp-dashboard">
            <!-- Stats Cards -->
            <div class="dp-stats-grid">
              <div class="dp-stat-card dp-stat-card--primary">
                <div class="dp-stat-card__icon">👥</div>
                <div class="dp-stat-card__content">
                  <div class="dp-stat-card__value">{{ stats().total_users }}</div>
                  <div class="dp-stat-card__label">Total Users</div>
                  @if (stats().growth_rate) {
                    <div class="dp-stat-card__trend" [class.dp-stat-card__trend--positive]="stats().growth_rate! > 0">
                      {{ stats().growth_rate! > 0 ? '↑' : '↓' }} {{ Math.abs(stats().growth_rate!) }}%
                    </div>
                  }
                </div>
              </div>

              <div class="dp-stat-card dp-stat-card--success">
                <div class="dp-stat-card__icon">📅</div>
                <div class="dp-stat-card__content">
                  <div class="dp-stat-card__value">{{ stats().today_count }}</div>
                  <div class="dp-stat-card__label">Added Today</div>
                  <div class="dp-stat-card__trend">
                    {{ calculatePercentage(stats().today_count, stats().total_users) }}% of total
                  </div>
                </div>
              </div>

              <div class="dp-stat-card dp-stat-card--info">
                <div class="dp-stat-card__icon">🌐</div>
                <div class="dp-stat-card__content">
                  <div class="dp-stat-card__value">{{ stats().unique_domains }}</div>
                  <div class="dp-stat-card__label">Email Domains</div>
                  <div class="dp-stat-card__trend">
                    Unique providers
                  </div>
                </div>
              </div>

              <div class="dp-stat-card dp-stat-card--warning">
                <div class="dp-stat-card__icon">📊</div>
                <div class="dp-stat-card__content">
                  <div class="dp-stat-card__value">{{ stats().avg_age }}</div>
                  <div class="dp-stat-card__label">Average Age</div>
                  <div class="dp-stat-card__trend">
                    Years
                  </div>
                </div>
              </div>
            </div>

            <!-- Quick Actions & Recent Activity -->
            <div class="dp-dashboard-grid">
              <div class="dp-card">
                <div class="dp-card__header">
                  <h3 class="dp-card__title">⚡ Quick Actions</h3>
                </div>
                <div class="dp-card__content">
                  <div class="dp-quick-actions">
                    <button class="dp-action-btn" (click)="setActiveTab('users'); setTabMode('create')">
                      <span class="dp-action-btn__icon">➕</span>
                      <span class="dp-action-btn__label">Add User</span>
                    </button>
                    <button class="dp-action-btn" (click)="setActiveTab('query')">
                      <span class="dp-action-btn__icon">🔍</span>
                      <span class="dp-action-btn__label">New Query</span>
                    </button>
                    <button class="dp-action-btn" (click)="setActiveTab('analytics')">
                      <span class="dp-action-btn__icon">📈</span>
                      <span class="dp-action-btn__label">View Analytics</span>
                    </button>
                    <button class="dp-action-btn" (click)="exportData()">
                      <span class="dp-action-btn__icon">📥</span>
                      <span class="dp-action-btn__label">Export Data</span>
                    </button>
                  </div>
                </div>
              </div>

              <div class="dp-card">
                <div class="dp-card__header">
                  <h3 class="dp-card__title">📋 System Status</h3>
                </div>
                <div class="dp-card__content">
                  <div class="dp-status-list">
                    <div class="dp-status-item">
                      <span class="dp-status-dot dp-status-dot--success"></span>
                      <span class="dp-status-label">Database Connection</span>
                      <span class="dp-status-value">Active</span>
                    </div>
                    <div class="dp-status-item">
                      <span class="dp-status-dot dp-status-dot--success"></span>
                      <span class="dp-status-label">Query Engine</span>
                      <span class="dp-status-value">Ready</span>
                    </div>
                    <div class="dp-status-item">
                      <span class="dp-status-dot dp-status-dot--success"></span>
                      <span class="dp-status-label">Cache Status</span>
                      <span class="dp-status-value">Warm</span>
                    </div>
                    <div class="dp-status-item">
                      <span class="dp-status-dot dp-status-dot--info"></span>
                      <span class="dp-status-label">Last Refresh</span>
                      <span class="dp-status-value">{{ lastRefresh | date:'HH:mm:ss' }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        }

        <!-- Users Management Tab -->
        @if (activeTab() === 'users') {
          <div class="dp-users">
            <div class="dp-users__header">
              <div class="dp-users__title">
                <h2>User Management</h2>
                <p>Complete CRUD operations for user data</p>
              </div>
              <div class="dp-users__actions">
                <div class="dp-search-box">
                  <span class="dp-search-box__icon">🔍</span>
                  <input 
                    type="text" 
                    class="dp-search-box__input" 
                    placeholder="Search users..."
                    [(ngModel)]="searchQuery"
                    (input)="filterUsers()"
                  />
                </div>
                <button class="dp-btn dp-btn--primary" (click)="setTabMode('create')">
                  <span class="dp-btn__icon">➕</span>
                  Add User
                </button>
              </div>
            </div>

            @if (usersMode() === 'list') {
              <div class="dp-table-container">
                @if (isLoading()) {
                  <div class="dp-loading">
                    <div class="dploading-spinner"></div>
                    <span>Loading users...</span>
                  </div>
                } @else if (filteredUsers().length === 0) {
                  <div class="dp-empty-state">
                    <div class="dp-empty-state__icon">📭</div>
                    <h3>No users found</h3>
                    <p>Start by adding your first user</p>
                    <button class="dp-btn dp-btn--primary" (click)="setTabMode('create')">
                      Add User
                    </button>
                  </div>
                } @else {
                  <table class="dp-table">
                    <thead>
                      <tr>
                        <th class="dp-table__sort" (click)="sortBy('name')">
                          Name
                          @if (sortKey === 'name') {
                            <span class="dp-table__sort-icon">{{ sortAsc ? '↑' : '↓' }}</span>
                          }
                        </th>
                        <th class="dp-table__sort" (click)="sortBy('email')">
                          Email
                          @if (sortKey === 'email') {
                            <span class="dp-table__sort-icon">{{ sortAsc ? '↑' : '↓' }}</span>
                          }
                        </th>
                        <th class="dp-table__sort" (click)="sortBy('age')">
                          Age
                          @if (sortKey === 'age') {
                            <span class="dp-table__sort-icon">{{ sortAsc ? '↑' : '↓' }}</span>
                          }
                        </th>
                        <th class="dp-table__sort" (click)="sortBy('created_at')">
                          Created
                          @if (sortKey === 'created_at') {
                            <span class="dp-table__sort-icon">{{ sortAsc ? '↑' : '↓' }}</span>
                          }
                        </th>
                        <th class="dp-table__actions">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      @for (user of filteredUsers(); track user.id) {
                        <tr class="dp-table__row">
                          <td>
                            <div class="dp-user-cell">
                              <div class="dp-avatar">{{ getInitials(user.name) }}</div>
                              <span class="dp-user-name">{{ user.name }}</span>
                            </div>
                          </td>
                          <td>
                            <span class="dp-email">{{ user.email }}</span>
                          </td>
                          <td>
                            <span class="dp-age">{{ user.age }} yrs</span>
                          </td>
                          <td>
                            <span class="dp-date">{{ formatDate(user.created_at) }}</span>
                          </td>
                          <td>
                            <div class="dp-table__row-actions">
                              <button class="dp-icon-btn dp-icon-btn--edit" (click)="editUser(user)" title="Edit">
                                ✏️
                              </button>
                              <button class="dp-icon-btn dp-icon-btn--delete" (click)="deleteUser(user)" title="Delete">
                                🗑️
                              </button>
                            </div>
                          </td>
                        </tr>
                      }
                    </tbody>
                  </table>
                }
              </div>
            } @else {
              <div class="dp-form-container">
                <div class="dp-form-header">
                  <h3>{{ isEditMode() ? '✏️ Edit User' : '➕ Create User' }}</h3>
                  <button class="dp-btn dp-btn--ghost" (click)="setTabMode('list')">Cancel</button>
                </div>
                <form class="dp-form" (ngSubmit)="saveUser()">
                  <div class="dp-form__group">
                    <label class="dp-form__label">
                      <span class="dp-form__icon">👤</span>
                      Full Name
                    </label>
                    <input 
                      type="text" 
                      class="dp-form__input"
                      [ngModel]="editingUser().name"
                      (ngModelChange)="updateEditingUser('name', $event)"
                      name="name"
                      required
                      placeholder="Enter full name"
                    />
                  </div>
                  <div class="dp-form__group">
                    <label class="dp-form__label">
                      <span class="dp-form__icon">📧</span>
                      Email Address
                    </label>
                    <input 
                      type="email" 
                      class="dp-form__input"
                      [ngModel]="editingUser().email"
                      (ngModelChange)="updateEditingUser('email', $event)"
                      name="email"
                      required
                      placeholder="email@example.com"
                    />
                  </div>
                  <div class="dp-form__group">
                    <label class="dp-form__label">
                      <span class="dp-form__icon">🎂</span>
                      Age
                    </label>
                    <input 
                      type="number" 
                      class="dp-form__input"
                      [ngModel]="editingUser().age"
                      (ngModelChange)="updateEditingUser('age', $event)"
                      name="age"
                      required
                      min="1"
                      max="150"
                      placeholder="25"
                    />
                  </div>
                  <div class="dp-form__actions">
                    <button type="submit" class="dp-btn dp-btn--primary" [disabled]="isLoading()">
                      {{ isLoading() ? 'Saving...' : (isEditMode() ? '💾 Update User' : '➕ Create User') }}
                    </button>
                  </div>
                </form>
              </div>
            }
          </div>
        }

        <!-- Analytics Tab -->
        @if (activeTab() === 'analytics') {
          <div class="dp-analytics">
            <div class="dp-analytics__header">
              <h2>📈 Analytics Dashboard</h2>
              <p>Advanced insights and data visualization</p>
            </div>
            
            <div class="dp-analytics-grid">
              <div class="dp-card dp-card--large">
                <div class="dp-card__header">
                  <h3 class="dp-card__title">User Distribution by Age Group</h3>
                </div>
                <div class="dp-card__content">
                  <div class="dp-chart-placeholder">
                    <div class="dp-bar-chart">
                      @for (group of ageGroups(); track group.label; let i = $index) {
                        <div class="dp-bar-item">
                          <div class="dp-bar-label">{{ group.label }}</div>
                          <div class="dp-bar-container">
                            <div 
                              class="dp-bar-fill" 
                              [style.width.%]="group.percentage"
                              [style.animation-delay]="i * 0.1 + 's'"
                            >
                              <span class="dp-bar-value">{{ group.count }}</span>
                            </div>
                          </div>
                        </div>
                      }
                    </div>
                  </div>
                </div>
              </div>

              <div class="dp-card">
                <div class="dp-card__header">
                  <h3 class="dp-card__title">Email Domain Analysis</h3>
                </div>
                <div class="dp-card__content">
                  <div class="dp-domain-list">
                    @for (domain of topDomains(); track domain.name; let i = $index) {
                      <div class="dp-domain-item">
                        <span class="dp-domain-rank">{{ i + 1 }}</span>
                        <span class="dp-domain-name">{{ domain.name }}</span>
                        <span class="dp-domain-count">{{ domain.count }} users</span>
                        <div class="dp-domain-bar">
                          <div class="dp-domain-fill" [style.width.%]="domain.percentage"></div>
                        </div>
                      </div>
                    }
                  </div>
                </div>
              </div>

              <div class="dp-card">
                <div class="dp-card__header">
                  <h3 class="dp-card__title">Growth Metrics</h3>
                </div>
                <div class="dp-card__content">
                  <div class="dp-metrics-grid">
                    <div class="dp-metric-item">
                      <div class="dp-metric-label">Daily Growth</div>
                      <div class="dp-metric-value positive">+{{ stats().today_count }}</div>
                    </div>
                    <div class="dp-metric-item">
                      <div class="dp-metric-label">Avg. Age</div>
                      <div class="dp-metric-value">{{ stats().avg_age }}</div>
                    </div>
                    <div class="dp-metric-item">
                      <div class="dp-metric-label">Domains</div>
                      <div class="dp-metric-value">{{ stats().unique_domains }}</div>
                    </div>
                    <div class="dp-metric-item">
                      <div class="dp-metric-label">Total</div>
                      <div class="dp-metric-value">{{ stats().total_users }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        }

        <!-- Query Builder Tab -->
        @if (activeTab() === 'query') {
          <div class="dp-query">
            <div class="dp-query__header">
              <h2>🔍 SQL Query Builder</h2>
              <p>Build and execute custom SQL queries</p>
            </div>

            <div class="dp-query-builder">
              <div class="dp-query-builder__panels">
                <div class="dp-query-panel">
                  <div class="dp-query-panel__header">
                    <h4>Query Components</h4>
                  </div>
                  <div class="dp-query-panel__content">
                    <div class="dp-query-field">
                      <label class="dp-query-label">SELECT</label>
                      <input 
                        type="text" 
                        class="dp-query-input"
                        [(ngModel)]="queryFields"
                        placeholder="* or column names"
                      />
                    </div>
                    <div class="dp-query-field">
                      <label class="dp-query-label">WHERE</label>
                      <input 
                        type="text" 
                        class="dp-query-input"
                        [(ngModel)]="queryWhere"
                        placeholder="age > 25"
                      />
                    </div>
                    <div class="dp-query-field">
                      <label class="dp-query-label">ORDER BY</label>
                      <input 
                        type="text" 
                        class="dp-query-input"
                        [(ngModel)]="queryOrder"
                        placeholder="created_at DESC"
                      />
                    </div>
                    <div class="dp-query-field">
                      <label class="dp-query-label">LIMIT</label>
                      <input 
                        type="number" 
                        class="dp-query-input"
                        [(ngModel)]="queryLimit"
                        placeholder="10"
                        min="1"
                        max="1000"
                      />
                    </div>
                  </div>
                </div>

                <div class="dp-query-panel">
                  <div class="dp-query-panel__header">
                    <h4>Generated SQL</h4>
                  </div>
                  <div class="dp-query-panel__content">
                    <pre class="dp-sql-preview">{{ generatedSQL() }}</pre>
                  </div>
                </div>
              </div>

              <div class="dp-query-actions">
                <button class="dp-btn dp-btn--primary" (click)="executeQuery()" [disabled]="isLoading()">
                  <span class="dp-btn__icon">▶</span>
                  Execute Query
                </button>
                <button class="dp-btn dp-btn--outline" (click)="clearQuery()">
                  <span class="dp-btn__icon">🗑️</span>
                  Clear
                </button>
                <button class="dp-btn dp-btn--outline" (click)="copyQuery()">
                  <span class="dp-btn__icon">📋</span>
                  Copy SQL
                </button>
              </div>

              @if (queryResult()) {
                <div class="dp-query-result">
                  <div class="dp-query-result__header">
                    <h4>Query Results</h4>
                    <div class="dp-query-result__meta">
                      <span class="dp-query-result__time">⏱️ {{ queryResult()!.execution_time_ms }}ms</span>
                      <span class="dp-query-result__rows">📊 {{ queryResult()!.rows_affected }} rows</span>
                    </div>
                  </div>
                  <div class="dp-query-result__content">
                    <pre class="dp-json-preview">{{ queryResult()!.data | json }}</pre>
                  </div>
                </div>
              }
            </div>
          </div>
        }
      </main>
    </div>
  `,
  styles: [`
    /* ============================================================================
       Professional DuckDB Component Styles
       ============================================================================ */
    
    :host {
      display: block;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    }

    .duckdb-professional {
      min-height: 100vh;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      padding: 0;
    }

    /* Header */
    .dp-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 24px 32px;
      background: rgba(255, 255, 255, 0.02);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .dp-header__brand {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .dp-logo {
      font-size: 48px;
      line-height: 1;
    }

    .dp-header__title {
      font-size: 28px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0;
    }

    .dp-header__subtitle {
      font-size: 14px;
      color: #94a3b8;
      margin: 4px 0 0;
    }

    /* Tabs */
    .dp-tabs {
      display: flex;
      gap: 8px;
      padding: 16px 32px;
      background: rgba(255, 255, 255, 0.02);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .dp-tab {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 20px;
      background: transparent;
      border: 1px solid transparent;
      border-radius: 8px;
      color: #94a3b8;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s;
    }

    .dp-tab:hover {
      background: rgba(148, 163, 184, 0.1);
      color: #f8fafc;
    }

    .dp-tab--active {
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: white;
      border-color: transparent;
    }

    .dp-tab__icon {
      font-size: 16px;
    }

    /* Content */
    .dp-content {
      padding: 32px;
    }

    /* Stats Grid */
    .dp-stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      margin-bottom: 32px;
    }

    .dp-stat-card {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 24px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      transition: all 0.3s;
    }

    .dp-stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 30px rgba(0, 0, 0, 0.3);
    }

    .dp-stat-card__icon {
      font-size: 40px;
      width: 64px;
      height: 64px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 12px;
    }

    .dp-stat-card--primary .dp-stat-card__icon { background: rgba(59, 130, 246, 0.2); }
    .dp-stat-card--success .dp-stat-card__icon { background: rgba(16, 185, 129, 0.2); }
    .dp-stat-card--info .dp-stat-card__icon { background: rgba(6, 182, 212, 0.2); }
    .dp-stat-card--warning .dp-stat-card__icon { background: rgba(245, 158, 11, 0.2); }

    .dp-stat-card__content {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .dp-stat-card__value {
      font-size: 32px;
      font-weight: 700;
      color: #f8fafc;
    }

    .dp-stat-card__label {
      font-size: 13px;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .dp-stat-card__trend {
      font-size: 12px;
      color: #64748b;
    }

    .dp-stat-card__trend--positive {
      color: #10b981;
    }

    /* Dashboard Grid */
    .dp-dashboard-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
    }

    /* Cards */
    .dp-card {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .dp-card--large {
      grid-column: span 2;
    }

    .dp-card__header {
      padding: 20px 24px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .dp-card__title {
      font-size: 16px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0;
    }

    .dp-card__content {
      padding: 24px;
    }

    /* Quick Actions */
    .dp-quick-actions {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
    }

    .dp-action-btn {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      padding: 20px;
      background: rgba(148, 163, 184, 0.1);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 10px;
      color: #94a3b8;
      cursor: pointer;
      transition: all 0.2s;
    }

    .dp-action-btn:hover {
      background: rgba(148, 163, 184, 0.15);
      border-color: rgba(148, 163, 184, 0.3);
      color: #f8fafc;
      transform: translateY(-2px);
    }

    .dp-action-btn__icon {
      font-size: 24px;
    }

    .dp-action-btn__label {
      font-size: 13px;
      font-weight: 500;
    }

    /* Status List */
    .dp-status-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .dp-status-item {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .dp-status-dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
    }

    .dp-status-dot--success { background: #10b981; }
    .dp-status-dot--info { background: #3b82f6; }

    .dp-status-label {
      font-size: 14px;
      color: #94a3b8;
      flex: 1;
    }

    .dp-status-value {
      font-size: 14px;
      color: #f8fafc;
      font-weight: 500;
    }

    /* Buttons */
    .dp-btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 20px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }

    .dp-btn--primary {
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: white;
    }

    .dp-btn--primary:hover:not(:disabled) {
      background: linear-gradient(135deg, #0891b2, #2563eb);
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(6, 182, 212, 0.4);
    }

    .dp-btn--outline {
      background: transparent;
      border: 1px solid rgba(148, 163, 184, 0.3);
      color: #94a3b8;
    }

    .dp-btn--outline:hover {
      border-color: rgba(148, 163, 184, 0.5);
      color: #f8fafc;
    }

    .dp-btn--ghost {
      background: transparent;
      color: #94a3b8;
    }

    .dp-btn--ghost:hover {
      background: rgba(148, 163, 184, 0.1);
      color: #f8fafc;
    }

    .dp-btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .dp-btn__icon {
      font-size: 16px;
    }

    /* Users Section */
    .dp-users__header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 24px;
    }

    .dp-users__title h2 {
      font-size: 24px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0 0 4px;
    }

    .dp-users__title p {
      font-size: 14px;
      color: #94a3b8;
      margin: 0;
    }

    .dp-users__actions {
      display: flex;
      gap: 12px;
      align-items: center;
    }

    /* Search Box */
    .dp-search-box {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px 16px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 10px;
      min-width: 280px;
      transition: border-color 0.2s;
    }

    .dp-search-box:focus-within {
      border-color: #06b6d4;
    }

    .dp-search-box__icon {
      font-size: 18px;
    }

    .dp-search-box__input {
      flex: 1;
      border: none;
      outline: none;
      font-size: 14px;
      background: transparent;
      color: #f8fafc;
    }

    /* Table */
    .dp-table-container {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .dp-table {
      width: 100%;
      border-collapse: collapse;
    }

    .dp-table th {
      padding: 16px 20px;
      background: rgba(255, 255, 255, 0.05);
      border-bottom: 1px solid rgba(148, 163, 184, 0.2);
      font-size: 13px;
      font-weight: 600;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      text-align: left;
    }

    .dp-table__sort {
      cursor: pointer;
      user-select: none;
      transition: color 0.2s;
    }

    .dp-table__sort:hover {
      color: #f8fafc;
    }

    .dp-table__sort-icon {
      margin-left: 6px;
      opacity: 0.5;
    }

    .dp-table__row {
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      transition: background 0.2s;
    }

    .dp-table__row:hover {
      background: rgba(148, 163, 184, 0.05);
    }

    .dp-table td {
      padding: 16px 20px;
      font-size: 14px;
      color: #e2e8f0;
    }

    .dp-table__actions {
      width: 120px;
    }

    .dp-table__row-actions {
      display: flex;
      gap: 8px;
    }

    .dp-icon-btn {
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: none;
      border-radius: 6px;
      background: transparent;
      cursor: pointer;
      transition: all 0.2s;
      font-size: 14px;
    }

    .dp-icon-btn--edit {
      background: rgba(59, 130, 246, 0.1);
    }

    .dp-icon-btn--edit:hover {
      background: rgba(59, 130, 246, 0.2);
    }

    .dp-icon-btn--delete {
      background: rgba(239, 68, 68, 0.1);
    }

    .dp-icon-btn--delete:hover {
      background: rgba(239, 68, 68, 0.2);
    }

    /* User Cell */
    .dp-user-cell {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .dp-avatar {
      width: 36px;
      height: 36px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      border-radius: 50%;
      color: white;
      font-weight: 600;
      font-size: 13px;
      flex-shrink: 0;
    }

    .dp-user-name {
      font-weight: 500;
      color: #f8fafc;
    }

    .dp-email {
      color: #94a3b8;
      font-family: monospace;
    }

    .dp-age, .dp-date {
      color: #e2e8f0;
    }

    /* Form */
    .dp-form-container {
      max-width: 600px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      padding: 32px;
    }

    .dp-form-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .dp-form-header h3 {
      font-size: 20px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0;
    }

    .dp-form {
      display: flex;
      flex-direction: column;
      gap: 24px;
    }

    .dp-form__group {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .dp-form__label {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      font-weight: 600;
      color: #f8fafc;
    }

    .dp-form__icon {
      font-size: 16px;
    }

    .dp-form__input {
      padding: 12px 16px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 8px;
      font-size: 15px;
      color: #f8fafc;
      transition: all 0.2s;
    }

    .dp-form__input:focus {
      outline: none;
      border-color: #06b6d4;
      box-shadow: 0 0 0 3px rgba(6, 182, 212, 0.1);
    }

    .dp-form__actions {
      padding-top: 8px;
    }

    /* Loading & Empty States */
    .dploading {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      padding: 60px 20px;
      color: #94a3b8;
    }

    .dploading-spinner {
      width: 40px;
      height: 40px;
      border: 3px solid rgba(148, 163, 184, 0.2);
      border-top-color: #06b6d4;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .dp-empty-state {
      text-align: center;
      padding: 80px 20px;
      color: #94a3b8;
    }

    .dp-empty-state__icon {
      font-size: 64px;
      display: block;
      margin-bottom: 20px;
    }

    .dp-empty-state h3 {
      font-size: 20px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0 0 8px;
    }

    .dp-empty-state p {
      font-size: 14px;
      margin: 0 0 20px;
    }

    /* Analytics */
    .dp-analytics__header {
      margin-bottom: 32px;
    }

    .dp-analytics__header h2 {
      font-size: 24px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0 0 4px;
    }

    .dp-analytics__header p {
      font-size: 14px;
      color: #94a3b8;
      margin: 0;
    }

    .dp-analytics-grid {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr;
      gap: 20px;
    }

    /* Bar Chart */
    .dp-bar-chart {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .dp-bar-item {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .dp-bar-label {
      width: 100px;
      font-size: 13px;
      color: #94a3b8;
    }

    .dp-bar-container {
      flex: 1;
      height: 32px;
      background: rgba(148, 163, 184, 0.1);
      border-radius: 6px;
      overflow: hidden;
    }

    .dp-bar-fill {
      height: 100%;
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      border-radius: 6px;
      display: flex;
      align-items: center;
      justify-content: flex-end;
      padding-right: 12px;
      animation: grow 0.5s ease-out forwards;
      transform-origin: left;
    }

    @keyframes grow {
      from { transform: scaleX(0); }
      to { transform: scaleX(1); }
    }

    .dp-bar-value {
      font-size: 12px;
      font-weight: 600;
      color: white;
    }

    /* Domain List */
    .dp-domain-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .dp-domain-item {
      display: flex;
      align-items: center;
      gap: 12px;
      position: relative;
    }

    .dp-domain-rank {
      width: 24px;
      height: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: rgba(148, 163, 184, 0.2);
      border-radius: 50%;
      font-size: 12px;
      font-weight: 600;
      color: #94a3b8;
    }

    .dp-domain-name {
      width: 120px;
      font-size: 14px;
      color: #f8fafc;
      font-weight: 500;
    }

    .dp-domain-count {
      width: 80px;
      font-size: 13px;
      color: #94a3b8;
    }

    .dp-domain-bar {
      flex: 1;
      height: 6px;
      background: rgba(148, 163, 184, 0.1);
      border-radius: 3px;
      overflow: hidden;
    }

    .dp-domain-fill {
      height: 100%;
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      border-radius: 3px;
    }

    /* Metrics Grid */
    .dp-metrics-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 16px;
    }

    .dp-metric-item {
      padding: 16px;
      background: rgba(148, 163, 184, 0.1);
      border-radius: 8px;
    }

    .dp-metric-label {
      font-size: 12px;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
    }

    .dp-metric-value {
      font-size: 24px;
      font-weight: 700;
      color: #f8fafc;
    }

    .dp-metric-value.positive {
      color: #10b981;
    }

    /* Query Builder */
    .dp-query__header {
      margin-bottom: 24px;
    }

    .dp-query__header h2 {
      font-size: 24px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0 0 4px;
    }

    .dp-query__header p {
      font-size: 14px;
      color: #94a3b8;
      margin: 0;
    }

    .dp-query-builder {
      display: flex;
      flex-direction: column;
      gap: 20px;
    }

    .dp-query-builder__panels {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
    }

    .dp-query-panel {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .dp-query-panel__header {
      padding: 16px 20px;
      background: rgba(255, 255, 255, 0.05);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .dp-query-panel__header h4 {
      font-size: 14px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0;
    }

    .dp-query-panel__content {
      padding: 20px;
    }

    .dp-query-field {
      margin-bottom: 16px;
    }

    .dp-query-field:last-child {
      margin-bottom: 0;
    }

    .dp-query-label {
      display: block;
      font-size: 12px;
      font-weight: 600;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
    }

    .dp-query-input {
      width: 100%;
      padding: 12px 16px;
      background: rgba(0, 0, 0, 0.2);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 8px;
      font-size: 14px;
      font-family: 'Fira Code', monospace;
      color: #f8fafc;
      transition: border-color 0.2s;
    }

    .dp-query-input:focus {
      outline: none;
      border-color: #06b6d4;
    }

    .dp-sql-preview {
      padding: 16px;
      background: rgba(0, 0, 0, 0.3);
      border-radius: 8px;
      font-family: 'Fira Code', monospace;
      font-size: 13px;
      color: #98c379;
      white-space: pre-wrap;
      word-break: break-all;
      margin: 0;
      min-height: 150px;
    }

    .dp-query-actions {
      display: flex;
      gap: 12px;
      justify-content: center;
      padding: 20px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
    }

    .dp-query-result {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .dp-query-result__header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 20px;
      background: rgba(255, 255, 255, 0.05);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .dp-query-result__header h4 {
      font-size: 14px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0;
    }

    .dp-query-result__meta {
      display: flex;
      gap: 16px;
    }

    .dp-query-result__time,
    .dp-query-result__rows {
      font-size: 13px;
      color: #94a3b8;
    }

    .dp-json-preview {
      padding: 20px;
      background: rgba(0, 0, 0, 0.3);
      font-family: 'Fira Code', monospace;
      font-size: 13px;
      color: #98c379;
      white-space: pre-wrap;
      word-break: break-all;
      margin: 0;
      max-height: 400px;
      overflow-y: auto;
    }

    /* Responsive */
    @media (max-width: 1200px) {
      .dp-stats-grid {
        grid-template-columns: repeat(2, 1fr);
      }
      
      .dp-analytics-grid {
        grid-template-columns: 1fr;
      }
      
      .dp-card--large {
        grid-column: span 1;
      }
    }

    @media (max-width: 768px) {
      .dp-header {
        flex-direction: column;
        gap: 16px;
        padding: 20px;
      }
      
      .dp-tabs {
        flex-wrap: wrap;
        padding: 12px 20px;
      }
      
      .dp-content {
        padding: 20px;
      }
      
      .dp-stats-grid {
        grid-template-columns: 1fr;
      }
      
      .dp-dashboard-grid {
        grid-template-columns: 1fr;
      }
      
      .dp-users__header {
        flex-direction: column;
        gap: 16px;
      }
      
      .dp-users__actions {
        flex-wrap: wrap;
      }
      
      .dp-query-builder__panels {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class DuckDBProfessionalComponent implements OnInit {
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);
  private readonly dbManager = inject(DatabaseManagementService);

  // State
  readonly Math = Math; // For template access
  activeTab = signal<TabType>('dashboard');
  isLoading = signal(false);
  lastRefresh = new Date();

  // Stats
  stats = signal<UserStats>({ total_users: 0, today_count: 0, unique_domains: 0, avg_age: 0 });

  // Users
  users = signal<User[]>([]);
  filteredUsers = signal<User[]>([]);
  searchQuery = '';
  usersMode = signal<'list' | 'create'>('list');
  isEditMode = signal(false);
  editingUser = signal<Partial<User>>({ name: '', email: '', age: 25 });
  sortKey: keyof User | null = null;
  sortAsc = true;

  // Analytics
  ageGroups = signal<Array<{label: string, count: number, percentage: number}>>([]);
  topDomains = signal<Array<{name: string, count: number, percentage: number}>>([]);

  // Query Builder
  queryFields = signal('*');
  queryWhere = signal('');
  queryOrder = signal('');
  queryLimit = signal(10);
  queryResult = signal<QueryResult | null>(null);

  // Computed
  generatedSQL = computed(() => {
    let sql = `SELECT ${this.queryFields()}`;
    sql += ' FROM users';
    if (this.queryWhere()) sql += ` WHERE ${this.queryWhere()}`;
    if (this.queryOrder()) sql += ` ORDER BY ${this.queryOrder()}`;
    if (this.queryLimit()) sql += ` LIMIT ${this.queryLimit()}`;
    return sql;
  });

  // ============================================================================
  // Lifecycle
  // ============================================================================

  ngOnInit(): void {
    this.refreshAll();
  }

  // ============================================================================
  // Navigation
  // ============================================================================

  setActiveTab(tab: TabType): void {
    this.activeTab.set(tab);
    if (tab === 'dashboard' || tab === 'analytics') {
      this.refreshAll();
    }
  }

  setTabMode(mode: 'list' | 'create'): void {
    this.usersMode.set(mode);
    if (mode === 'create') {
      this.resetForm();
    }
  }

  // ============================================================================
  // Data Loading
  // ============================================================================

  async refreshAll(): Promise<void> {
    this.isLoading.set(true);
    try {
      await Promise.all([
        this.loadUsers(),
        this.loadStats(),
        this.loadAnalytics(),
      ]);
      this.lastRefresh = new Date();
    } catch (error) {
      this.logger.error('Failed to refresh data', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  async loadUsers(): Promise<void> {
    const users = await this.api.callOrThrow<User[]>('getUsers');
    this.users.set(users);
    this.filterUsers();
  }

  async loadStats(): Promise<void> {
    const stats = await this.api.callOrThrow<UserStats>('getUserStats');
    this.stats.set(stats);
  }

  async loadAnalytics(): Promise<void> {
    // Calculate age groups
    const usersList = this.users();
    const groups: Record<string, number> = { '18-25': 0, '26-35': 0, '36-45': 0, '46-55': 0, '56+': 0 };
    
    usersList.forEach(user => {
      if (user.age <= 25) groups['18-25']++;
      else if (user.age <= 35) groups['26-35']++;
      else if (user.age <= 45) groups['36-45']++;
      else if (user.age <= 55) groups['46-55']++;
      else groups['56+']++;
    });

    const total = usersList.length || 1;
    this.ageGroups.set(
      Object.entries(groups).map(([label, count]) => ({
        label,
        count,
        percentage: (count / total) * 100,
      }))
    );

    // Calculate top domains
    const domainMap: Record<string, number> = {};
    usersList.forEach(user => {
      const domain = user.email.split('@')[1] || 'unknown';
      domainMap[domain] = (domainMap[domain] || 0) + 1;
    });

    const sortedDomains = Object.entries(domainMap)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5);

    this.topDomains.set(
      sortedDomains.map(([name, count]) => ({
        name,
        count,
        percentage: (count / total) * 100,
      }))
    );
  }

  // ============================================================================
  // Users Management
  // ============================================================================

  filterUsers(): void {
    const query = this.searchQuery.toLowerCase();
    this.filteredUsers.set(
      this.users().filter(u =>
        u.name.toLowerCase().includes(query) ||
        u.email.toLowerCase().includes(query)
      )
    );
  }

  sortBy(key: keyof User): void {
    if (this.sortKey === key) {
      this.sortAsc = !this.sortAsc;
    } else {
      this.sortKey = key;
      this.sortAsc = true;
    }
    
    const sorted = [...this.filteredUsers()].sort((a, b) => {
      const aVal = a[key];
      const bVal = b[key];
      return this.sortAsc ? (aVal < bVal ? -1 : 1) : (aVal > bVal ? -1 : 1);
    });
    
    this.filteredUsers.set(sorted);
  }

  resetForm(): void {
    this.isEditMode.set(false);
    this.editingUser.set({ name: '', email: '', age: 25 });
  }

  updateEditingUser(field: keyof User, value: string | number) {
    this.editingUser.update(u => ({ ...u, [field]: value }));
  }

  async saveUser(): Promise<void> {
    if (!this.editingUser().name || !this.editingUser().email || !this.editingUser().age) {
      this.logger.warn('Validation failed');
      return;
    }

    this.isLoading.set(true);
    try {
      if (this.isEditMode()) {
        await this.api.callOrThrow('updateUser', [this.editingUser()]);
        this.logger.info('User updated');
      } else {
        await this.api.callOrThrow('createUser', [this.editingUser()]);
        this.logger.info('User created');
      }
      this.resetForm();
      this.setTabMode('list');
      await this.refreshAll();
    } catch (error) {
      this.logger.error('Failed to save user', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  editUser(user: User): void {
    this.editingUser.set({ ...user });
    this.isEditMode.set(true);
    this.setTabMode('create');
  }

  async deleteUser(user: User): Promise<void> {
    const confirmed = await this.dbManager.deleteUser(user.id, user.name);
    
    if (confirmed) {
      await this.refreshAll();
    }
  }

  // ============================================================================
  // Query Builder
  // ============================================================================

  async executeQuery(): Promise<void> {
    this.isLoading.set(true);
    const startTime = performance.now();
    
    try {
      const data = await this.api.callOrThrow<any[]>('executeQuery', [this.generatedSQL()]);
      const executionTime = Math.round(performance.now() - startTime);
      
      this.queryResult.set({
        sql: this.generatedSQL(),
        data,
        execution_time_ms: executionTime,
        rows_affected: data.length,
      });
      
      this.logger.info(`Query executed in ${executionTime}ms`);
    } catch (error) {
      this.logger.error('Query failed', error);
      this.queryResult.set({
        sql: this.generatedSQL(),
        data: [],
        execution_time_ms: 0,
        rows_affected: 0,
      });
    } finally {
      this.isLoading.set(false);
    }
  }

  clearQuery(): void {
    this.queryFields.set('*');
    this.queryWhere.set('');
    this.queryOrder.set('');
    this.queryLimit.set(10);
    this.queryResult.set(null);
  }

  copyQuery(): void {
    navigator.clipboard.writeText(this.generatedSQL());
    this.logger.info('SQL copied to clipboard');
  }

  // ============================================================================
  // Utilities
  // ============================================================================

  getInitials(name: string): string {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  }

  formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }

  calculatePercentage(part: number, total: number): number {
    if (total === 0) return 0;
    return Math.round((part / total) * 100);
  }

  exportData(): void {
    const data = JSON.stringify(this.users(), null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `users-export-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    this.logger.info('Data exported');
  }
}
