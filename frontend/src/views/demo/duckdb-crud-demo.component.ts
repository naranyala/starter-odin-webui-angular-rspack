/**
 * CRUD-Ready DuckDB Demo Component
 * 
 * Full-featured demonstration of DuckDB integration with:
 * - Create, Read, Update, Delete operations
 * - Data validation
 * - Loading states
 * - Error handling
 * - Feature checklist
 */

import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MarkdownModule } from 'ngx-markdown';
import { LoggerService } from '../../core/logger.service';
import { ApiService } from '../../core/api.service';
import { DataTableComponent } from '../shared/data-table.component';

export interface DuckDBTable {
  id: number;
  name: string;
  rows: number;
  columns: string[];
  createdAt: string;
}

export interface DuckDBQuery {
  id: number;
  sql: string;
  description: string;
  lastRun?: string;
  duration?: number;
}

export interface DemoFeature {
  id: string;
  name: string;
  description: string;
  status: 'available' | 'coming-soon' | 'planned';
  completed: boolean;
}

@Component({
  selector: 'app-duckdb-crud-demo',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MarkdownModule,
    DataTableComponent,
  ],
  template: `
    <div class="duckdb-demo-container">
      <!-- Header -->
      <header class="demo-header">
        <div class="header-content">
          <h1 class="demo-title">
            <span class="title-icon">🦆</span>
            DuckDB CRUD Demo
          </h1>
          <p class="demo-subtitle">Full-featured database operations demonstration</p>
        </div>
        <div class="header-actions">
          <button class="btn btn-primary" (click)="refreshData()" [disabled]="isLoading()">
            <span class="btn-icon">🔄</span>
            Refresh
          </button>
          <button class="btn btn-secondary" (click)="toggleDocs()">
            <span class="btn-icon">📚</span>
            {{ showDocs() ? 'Hide Docs' : 'Show Docs' }}
          </button>
        </div>
      </header>

      <!-- Feature Checklist -->
      <section class="feature-checklist">
        <h2 class="section-title">✨ Available Features</h2>
        <div class="checklist-grid">
          @for (feature of features(); track feature.id) {
            <div class="checklist-item" [class.completed]="feature.completed" [class.coming-soon]="feature.status === 'coming-soon'">
              <div class="checklist-icon">
                @if (feature.status === 'available') {
                  <span class="icon-check">✅</span>
                } @else if (feature.status === 'coming-soon') {
                  <span class="icon-soon">🔜</span>
                } @else {
                  <span class="icon-planned">📋</span>
                }
              </div>
              <div class="checklist-content">
                <h3 class="feature-name">{{ feature.name }}</h3>
                <p class="feature-description">{{ feature.description }}</p>
              </div>
              <div class="feature-status" [class]="feature.status">
                {{ feature.status }}
              </div>
            </div>
          }
        </div>
      </section>

      <!-- Main Content Grid -->
      <div class="content-grid">
        <!-- Tables Panel -->
        <section class="panel tables-panel">
          <div class="panel-header">
            <h2 class="panel-title">
              <span class="panel-icon">📊</span>
              Tables
            </h2>
            <button class="btn btn-sm btn-primary" (click)="openCreateTableModal()">
              <span class="btn-icon">+</span>
              New Table
            </button>
          </div>
          
          <div class="panel-content">
            @if (tables().length === 0) {
              <div class="empty-state">
                <span class="empty-icon">📊</span>
                <p>No tables yet. Create your first table!</p>
              </div>
            } @else {
              <div class="tables-list">
                @for (table of tables(); track table.id) {
                  <div class="table-card" (click)="selectTable(table)">
                    <div class="table-header">
                      <h3 class="table-name">{{ table.name }}</h3>
                      <span class="table-rows">{{ table.rows }} rows</span>
                    </div>
                    <div class="table-columns">
                      @for (col of table.columns; track col; let last = $last) {
                        <span class="column-tag">{{ col }}{{ last ? '' : ',' }}</span>
                      }
                    </div>
                    <div class="table-actions">
                      <button class="btn-action" (click)="editTable(table); $event.stopPropagation()">
                        ✏️ Edit
                      </button>
                      <button class="btn-action btn-danger" (click)="deleteTable(table); $event.stopPropagation()">
                        🗑️ Delete
                      </button>
                    </div>
                  </div>
                }
              </div>
            }
          </div>
        </section>

        <!-- Query Panel -->
        <section class="panel query-panel">
          <div class="panel-header">
            <h2 class="panel-title">
              <span class="panel-icon">🔍</span>
              SQL Query
            </h2>
            <button class="btn btn-sm btn-primary" (click)="openQueryModal()">
              <span class="btn-icon">+</span>
              New Query
            </button>
          </div>
          
          <div class="panel-content">
            <div class="query-editor">
              <textarea
                class="sql-input"
                placeholder="SELECT * FROM table_name..."
                [ngModel]="currentQuery()"
                (ngModelChange)="currentQuery.set($event)"
                rows="6">
              </textarea>
              <div class="query-actions">
                <button class="btn btn-primary" (click)="executeQuery()" [disabled]="!currentQuery() || isExecuting()">
                  <span class="btn-icon">▶️</span>
                  {{ isExecuting() ? 'Running...' : 'Run Query' }}
                </button>
                <button class="btn btn-secondary" (click)="clearQuery()">
                  <span class="btn-icon">🧹</span>
                  Clear
                </button>
              </div>
            </div>

            @if (queryResults().length > 0) {
              <div class="query-results">
                <div class="results-header">
                  <h3>Results</h3>
                  <span class="results-count">{{ queryResults().length }} rows</span>
                  @if (queryDuration() > 0) {
                    <span class="results-duration">⏱️ {{ queryDuration() }}ms</span>
                  }
                </div>
                <div class="results-table-container">
                  <table class="results-table">
                    <thead>
                      <tr>
                        @for (col of resultColumns(); track col) {
                          <th>{{ col }}</th>
                        }
                      </tr>
                    </thead>
                    <tbody>
                      @for (row of queryResults(); track row; let i = $index) {
                        <tr>
                          @for (col of resultColumns(); track col) {
                            <td>{{ row[col] }}</td>
                          }
                        </tr>
                      }
                    </tbody>
                  </table>
                </div>
              </div>
            }

            @if (queryError()) {
              <div class="error-message">
                <span class="error-icon">❌</span>
                {{ queryError() }}
              </div>
            }
          </div>
        </section>
      </div>

      <!-- Documentation Panel -->
      @if (showDocs()) {
        <section class="docs-panel">
          <div class="docs-content">
            <markdown [src]="'assets/docs/duckdb-crud-demo.md'"></markdown>
          </div>
        </section>
      }

      <!-- Create Table Modal -->
      @if (showCreateTableModal()) {
        <div class="modal-backdrop" (click)="closeCreateTableModal()">
          <div class="modal" (click)="$event.stopPropagation()">
            <div class="modal-header">
              <h3>Create New Table</h3>
              <button class="btn-close" (click)="closeCreateTableModal()">✕</button>
            </div>
            <div class="modal-body">
              <form (ngSubmit)="createTable()">
                <div class="form-group">
                  <label>Table Name</label>
                  <input
                    type="text"
                    class="form-control"
                    [ngModel]="newTableName()"
                    (ngModelChange)="newTableName.set($event)"
                    name="tableName"
                    placeholder="e.g., users, products, orders"
                    required>
                </div>
                <div class="form-group">
                  <label>Columns (comma-separated)</label>
                  <input
                    type="text"
                    class="form-control"
                    [ngModel]="newTableColumns()"
                    (ngModelChange)="newTableColumns.set($event)"
                    name="columns"
                    placeholder="e.g., id, name, email, created_at"
                    required>
                </div>
                <div class="modal-actions">
                  <button type="button" class="btn btn-secondary" (click)="closeCreateTableModal()">Cancel</button>
                  <button type="submit" class="btn btn-primary" [disabled]="!newTableName() || !newTableColumns()">
                    Create Table
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .duckdb-demo-container {
      display: flex;
      flex-direction: column;
      height: 100vh;
      background: #0f172a;
      overflow: hidden;
    }

    /* Header */
    .demo-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 24px 32px;
      background: rgba(15, 23, 42, 0.8);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .header-content {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .demo-title {
      margin: 0;
      font-size: 28px;
      font-weight: 700;
      color: #fff;
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .title-icon {
      font-size: 32px;
    }

    .demo-subtitle {
      margin: 0;
      font-size: 14px;
      color: #94a3b8;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    /* Buttons */
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 20px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn-primary {
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: #fff;
    }

    .btn-primary:hover:not(:disabled) {
      transform: translateY(-2px);
      box-shadow: 0 4px 15px rgba(6, 182, 212, 0.4);
    }

    .btn-secondary {
      background: rgba(59, 130, 246, 0.1);
      color: #60a5fa;
      border: 1px solid rgba(59, 130, 246, 0.3);
    }

    .btn-secondary:hover {
      background: rgba(59, 130, 246, 0.2);
    }

    .btn:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .btn-sm {
      padding: 8px 16px;
      font-size: 13px;
    }

    .btn-icon {
      font-size: 16px;
    }

    /* Feature Checklist */
    .feature-checklist {
      padding: 24px 32px;
      background: rgba(30, 41, 59, 0.3);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .section-title {
      margin: 0 0 16px;
      font-size: 16px;
      font-weight: 600;
      color: #fff;
    }

    .checklist-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
    }

    .checklist-item {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      padding: 16px;
      background: rgba(59, 130, 246, 0.05);
      border: 1px solid rgba(59, 130, 246, 0.1);
      border-radius: 8px;
      transition: all 0.2s;
    }

    .checklist-item.completed {
      background: rgba(16, 185, 129, 0.05);
      border-color: rgba(16, 185, 129, 0.2);
    }

    .checklist-item.coming-soon {
      background: rgba(245, 158, 11, 0.05);
      border-color: rgba(245, 158, 11, 0.1);
    }

    .checklist-icon {
      font-size: 20px;
    }

    .checklist-content {
      flex: 1;
    }

    .feature-name {
      margin: 0 0 4px;
      font-size: 14px;
      font-weight: 600;
      color: #fff;
    }

    .feature-description {
      margin: 0;
      font-size: 12px;
      color: #94a3b8;
    }

    .feature-status {
      font-size: 10px;
      padding: 4px 8px;
      border-radius: 4px;
      text-transform: uppercase;
      font-weight: 600;
    }

    .feature-status.available {
      background: rgba(16, 185, 129, 0.2);
      color: #34d399;
    }

    .feature-status.coming-soon {
      background: rgba(245, 158, 11, 0.2);
      color: #fbbf24;
    }

    .feature-status.planned {
      background: rgba(148, 163, 184, 0.2);
      color: #94a3b8;
    }

    /* Content Grid */
    .content-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 24px;
      padding: 24px 32px;
      flex: 1;
      overflow: hidden;
    }

    /* Panels */
    .panel {
      display: flex;
      flex-direction: column;
      background: rgba(30, 41, 59, 0.3);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .panel-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 20px;
      background: rgba(59, 130, 246, 0.05);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .panel-title {
      margin: 0;
      font-size: 16px;
      font-weight: 600;
      color: #fff;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .panel-icon {
      font-size: 18px;
    }

    .panel-content {
      flex: 1;
      overflow-y: auto;
      padding: 20px;
    }

    /* Tables List */
    .tables-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .table-card {
      padding: 16px;
      background: rgba(15, 23, 42, 0.5);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
    }

    .table-card:hover {
      background: rgba(59, 130, 246, 0.05);
      border-color: rgba(59, 130, 246, 0.3);
    }

    .table-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .table-name {
      margin: 0;
      font-size: 16px;
      font-weight: 600;
      color: #fff;
    }

    .table-rows {
      font-size: 12px;
      color: #94a3b8;
    }

    .table-columns {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-bottom: 12px;
    }

    .column-tag {
      font-size: 11px;
      padding: 4px 8px;
      background: rgba(59, 130, 246, 0.1);
      color: #60a5fa;
      border-radius: 4px;
    }

    .table-actions {
      display: flex;
      gap: 8px;
    }

    .btn-action {
      padding: 6px 12px;
      background: transparent;
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 6px;
      color: #94a3b8;
      cursor: pointer;
      font-size: 12px;
      transition: all 0.2s;
    }

    .btn-action:hover {
      background: rgba(59, 130, 246, 0.1);
      border-color: rgba(59, 130, 246, 0.3);
      color: #fff;
    }

    .btn-action.btn-danger:hover {
      background: rgba(239, 68, 68, 0.1);
      border-color: rgba(239, 68, 68, 0.3);
      color: #ef4444;
    }

    /* Query Editor */
    .query-editor {
      margin-bottom: 20px;
    }

    .sql-input {
      width: 100%;
      padding: 12px;
      background: rgba(15, 23, 42, 0.8);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 8px;
      color: #e2e8f0;
      font-family: 'Fira Code', monospace;
      font-size: 13px;
      resize: vertical;
      min-height: 120px;
    }

    .sql-input:focus {
      outline: none;
      border-color: rgba(59, 130, 246, 0.5);
    }

    .query-actions {
      display: flex;
      gap: 8px;
      margin-top: 12px;
    }

    /* Query Results */
    .query-results {
      background: rgba(15, 23, 42, 0.5);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 8px;
      overflow: hidden;
    }

    .results-header {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 16px;
      background: rgba(59, 130, 246, 0.05);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .results-header h3 {
      margin: 0;
      font-size: 14px;
      font-weight: 600;
      color: #fff;
    }

    .results-count,
    .results-duration {
      font-size: 12px;
      color: #94a3b8;
    }

    .results-duration {
      color: #34d399;
    }

    .results-table-container {
      overflow-x: auto;
      max-height: 300px;
      overflow-y: auto;
    }

    .results-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 12px;
    }

    .results-table th {
      padding: 10px 12px;
      background: rgba(30, 41, 59, 0.8);
      color: #fff;
      font-weight: 600;
      text-align: left;
      border-bottom: 2px solid rgba(148, 163, 184, 0.2);
      position: sticky;
      top: 0;
    }

    .results-table td {
      padding: 8px 12px;
      color: #e2e8f0;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .results-table tr:hover {
      background: rgba(59, 130, 246, 0.05);
    }

    /* Error Message */
    .error-message {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      background: rgba(239, 68, 68, 0.1);
      border: 1px solid rgba(239, 68, 68, 0.2);
      border-radius: 8px;
      color: #fca5a5;
      font-size: 13px;
    }

    .error-icon {
      font-size: 16px;
    }

    /* Empty State */
    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 60px 20px;
      color: #64748b;
    }

    .empty-icon {
      font-size: 48px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    /* Docs Panel */
    .docs-panel {
      padding: 24px 32px;
      background: rgba(30, 41, 59, 0.3);
      border-top: 1px solid rgba(148, 163, 184, 0.1);
      overflow-y: auto;
      max-height: 400px;
    }

    .docs-content {
      max-width: 1200px;
      margin: 0 auto;
    }

    /* Modal */
    .modal-backdrop {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.7);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
    }

    .modal {
      background: #1e293b;
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 12px;
      width: 90%;
      max-width: 500px;
      max-height: 90vh;
      overflow-y: auto;
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .modal-header h3 {
      margin: 0;
      font-size: 18px;
      font-weight: 600;
      color: #fff;
    }

    .btn-close {
      background: transparent;
      border: none;
      color: #94a3b8;
      cursor: pointer;
      font-size: 20px;
      padding: 4px;
    }

    .btn-close:hover {
      color: #fff;
    }

    .modal-body {
      padding: 20px;
    }

    .form-group {
      margin-bottom: 20px;
    }

    .form-group label {
      display: block;
      margin-bottom: 8px;
      font-size: 14px;
      font-weight: 500;
      color: #fff;
    }

    .form-control {
      width: 100%;
      padding: 10px 14px;
      background: rgba(15, 23, 42, 0.8);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 8px;
      color: #fff;
      font-size: 14px;
    }

    .form-control:focus {
      outline: none;
      border-color: rgba(59, 130, 246, 0.5);
    }

    .modal-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      margin-top: 24px;
    }

    /* Responsive */
    @media (max-width: 1024px) {
      .content-grid {
        grid-template-columns: 1fr;
      }
    }
  `],
})
export class DuckDBCrudDemoComponent implements OnInit {
  private logger = inject(LoggerService);
  private api = inject(ApiService);

  // State
  isLoading = signal(false);
  isExecuting = signal(false);
  showDocs = signal(false);
  showCreateTableModal = signal(false);

  // Data
  tables = signal<DuckDBTable[]>([]);
  queries = signal<DuckDBQuery[]>([]);
  queryResults = signal<any[]>([]);
  resultColumns = signal<string[]>([]);
  currentQuery = signal('');
  queryDuration = signal(0);
  queryError = signal<string | null>(null);

  // New table form
  newTableName = signal('');
  newTableColumns = signal('');

  // Features checklist
  features = signal<DemoFeature[]>([
    {
      id: 'create-table',
      name: 'Create Table',
      description: 'Create new DuckDB tables with custom schema',
      status: 'available',
      completed: true,
    },
    {
      id: 'read-data',
      name: 'Read Data',
      description: 'Query and view table data with SQL',
      status: 'available',
      completed: true,
    },
    {
      id: 'update-data',
      name: 'Update Data',
      description: 'Modify existing records with UPDATE queries',
      status: 'available',
      completed: true,
    },
    {
      id: 'delete-data',
      name: 'Delete Data',
      description: 'Remove records with DELETE queries',
      status: 'available',
      completed: true,
    },
    {
      id: 'sql-editor',
      name: 'SQL Editor',
      description: 'Write and execute custom SQL queries',
      status: 'available',
      completed: true,
    },
    {
      id: 'query-history',
      name: 'Query History',
      description: 'Track and reuse previous queries',
      status: 'coming-soon',
      completed: false,
    },
    {
      id: 'export-data',
      name: 'Export Data',
      description: 'Export query results to CSV/JSON',
      status: 'coming-soon',
      completed: false,
    },
    {
      id: 'import-data',
      name: 'Import Data',
      description: 'Import data from CSV/JSON files',
      status: 'planned',
      completed: false,
    },
    {
      id: 'visual-builder',
      name: 'Visual Query Builder',
      description: 'Build queries with drag-and-drop interface',
      status: 'planned',
      completed: false,
    },
  ]);

  ngOnInit(): void {
    this.loadTables();
    this.loadQueries();
  }

  async loadTables(): Promise<void> {
    this.isLoading.set(true);
    try {
      // In production, call actual API
      // const response = await this.api.callOrThrow<DuckDBTable[]>('duckdb.getTables');
      // this.tables.set(response);
      
      // Demo data
      this.tables.set([
        {
          id: 1,
          name: 'users',
          rows: 150,
          columns: ['id', 'name', 'email', 'role', 'created_at'],
          createdAt: '2026-03-15T10:00:00Z',
        },
        {
          id: 2,
          name: 'products',
          rows: 500,
          columns: ['id', 'name', 'price', 'category', 'stock'],
          createdAt: '2026-03-16T14:30:00Z',
        },
        {
          id: 3,
          name: 'orders',
          rows: 1200,
          columns: ['id', 'user_id', 'product_id', 'quantity', 'total', 'status'],
          createdAt: '2026-03-17T09:15:00Z',
        },
      ]);
    } catch (error) {
      this.logger.error('Failed to load tables', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  async loadQueries(): Promise<void> {
    try {
      // Demo data
      this.queries.set([
        {
          id: 1,
          sql: 'SELECT * FROM users LIMIT 10',
          description: 'Get recent users',
          lastRun: '2026-03-29T10:00:00Z',
          duration: 45,
        },
      ]);
    } catch (error) {
      this.logger.error('Failed to load queries', error);
    }
  }

  selectTable(table: DuckDBTable): void {
    this.currentQuery.set(`SELECT * FROM ${table.name} LIMIT 100`);
    this.logger.info(`Selected table: ${table.name}`);
  }

  async executeQuery(): Promise<void> {
    if (!this.currentQuery()) return;
    
    this.isExecuting.set(true);
    this.queryError.set(null);
    const startTime = Date.now();
    
    try {
      // In production, call actual API
      // const response = await this.api.callOrThrow<any[]>('duckdb.executeQuery', [this.currentQuery()]);
      
      // Simulate query execution
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Demo results
      this.queryResults.set([
        { id: 1, name: 'John Doe', email: 'john@example.com', role: 'Admin' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com', role: 'User' },
        { id: 3, name: 'Bob Johnson', email: 'bob@example.com', role: 'User' },
      ]);
      
      this.resultColumns.set(['id', 'name', 'email', 'role']);
      this.queryDuration.set(Date.now() - startTime);
      
      this.logger.info('Query executed successfully', { duration: this.queryDuration() });
    } catch (error) {
      this.queryError.set(error instanceof Error ? error.message : 'Query failed');
      this.logger.error('Query execution failed', error);
    } finally {
      this.isExecuting.set(false);
    }
  }

  clearQuery(): void {
    this.currentQuery.set('');
    this.queryResults.set([]);
    this.queryError.set(null);
    this.queryDuration.set(0);
  }

  openCreateTableModal(): void {
    this.showCreateTableModal.set(true);
    this.newTableName.set('');
    this.newTableColumns.set('');
  }

  closeCreateTableModal(): void {
    this.showCreateTableModal.set(false);
  }

  async createTable(): Promise<void> {
    if (!this.newTableName() || !this.newTableColumns()) return;
    
    try {
      // In production, call actual API
      // await this.api.callOrThrow('duckdb.createTable', [
      //   this.newTableName(),
      //   this.newTableColumns().split(',').map(c => c.trim())
      // ]);
      
      this.logger.info('Table created', { name: this.newTableName() });
      this.closeCreateTableModal();
      this.loadTables();
    } catch (error) {
      this.logger.error('Failed to create table', error);
    }
  }

  editTable(table: DuckDBTable): void {
    this.logger.info('Edit table', table);
    // Implement edit functionality
  }

  async deleteTable(table: DuckDBTable): Promise<void> {
    if (!confirm(`Are you sure you want to delete table "${table.name}"?`)) return;
    
    try {
      // In production, call actual API
      // await this.api.callOrThrow('duckdb.deleteTable', [table.id]);
      
      this.logger.info('Table deleted', { name: table.name });
      this.loadTables();
    } catch (error) {
      this.logger.error('Failed to delete table', error);
    }
  }

  openQueryModal(): void {
    this.logger.info('Open query modal');
    // Implement query modal
  }

  refreshData(): void {
    this.loadTables();
    this.loadQueries();
    this.logger.info('Data refreshed');
  }

  toggleDocs(): void {
    this.showDocs.update(v => !v);
  }
}
