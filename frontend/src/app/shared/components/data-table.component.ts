/**
 * Data Table Component - Reusable data table with sorting, pagination, and actions
 *
 * A flexible table component for displaying tabular data with common features
 */

import { Component, Input, Output, EventEmitter, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonComponent } from './button.component';

export interface Column<T> {
  key: keyof T | string;
  label: string;
  sortable?: boolean;
  pipe?: 'date' | 'currency' | 'number' | 'uppercase' | 'lowercase';
  width?: string;
  template?: (item: T) => string;
}

export interface Action<T> {
  label: string;
  icon: string;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  action: (item: T) => void;
  show?: (item: T) => boolean;
}

@Component({
  selector: 'app-data-table',
  standalone: true,
  imports: [CommonModule, FormsModule, ButtonComponent],
  template: `
    <div class="data-table">
      <!-- Toolbar -->
      @if (showToolbar) {
        <div class="data-table__toolbar">
          <div class="data-table__search">
            <span class="search-icon">🔍</span>
            <input
              type="text"
              class="search-input"
              placeholder="{{searchPlaceholder}}"
              [(ngModel)]="searchQuery"
              (input)="onSearch()"
            />
          </div>
          
          <div class="data-table__actions">
            <ng-content select="[table-actions]"></ng-content>
          </div>
        </div>
      }
      
      <!-- Table -->
      <div class="data-table__container">
        <table class="table">
          <thead>
            <tr>
              @for (column of columns; track column.key) {
                <th
                  [style.width]="column.width"
                  [class.sortable]="column.sortable"
                  [class.sorted]="sortKey === column.key"
                  (click)="column.sortable && onSort(column.key)"
                >
                  <div class="th-content">
                    <span>{{ column.label }}</span>
                    @if (column.sortable) {
                      <span class="sort-icon">
                        {{ sortKey === column.key ? (sortAsc ? '↑' : '↓') : '⇅' }}
                      </span>
                    }
                  </div>
                </th>
              }
              @if (actions.length > 0) {
                <th class="actions-header">Actions</th>
              }
            </tr>
          </thead>
          <tbody>
            @for (item of paginatedData(); track trackBy($index, item)) {
              <tr [class.selected]="isSelected(item)">
                @for (column of columns; track column.key) {
                  <td>
                    @if (column.template) {
                      <span [innerHTML]="column.template!(item)"></span>
                    } @else {
                      <span>{{ getCellValue(item, column.key, column.pipe) }}</span>
                    }
                  </td>
                }
                @if (actions.length > 0) {
                  <td class="actions-cell">
                    @for (action of actions; track action.label) {
                      @if (!action.show || action.show(item)) {
                        <app-button
                          [variant]="action.variant || 'ghost'"
                          size="small"
                          icon="{{action.icon}}"
                          [iconOnly]="true"
                          (clicked)="action.action(item)"
                          [title]="action.label"
                        ></app-button>
                      }
                    }
                  </td>
                }
              </tr>
            } @empty {
              <tr>
                <td [attr.colspan]="columns.length + (actions.length > 0 ? 1 : 0)" class="empty-state">
                  <span class="empty-icon">📭</span>
                  <p>{{ emptyMessage }}</p>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      
      <!-- Pagination -->
      @if (pagination) {
        <div class="data-table__pagination">
          <div class="pagination-info">
            Showing {{ startIndex() + 1 }} - {{ endIndex() }} of {{ totalItems() }} items
          </div>
          
          <div class="pagination-controls">
            <app-button
              variant="secondary"
              size="small"
              (clicked)="previousPage()"
              [disabled]="currentPage === 1"
            >
              ← Previous
            </app-button>
            
            @for (page of visiblePages(); track page) {
              <button
                class="page-btn"
                [class.page-btn--active]="page === currentPage"
                (click)="goToPage(page)"
              >
                {{ page }}
              </button>
            }
            
            <app-button
              variant="secondary"
              size="small"
              (clicked)="nextPage()"
              [disabled]="currentPage === totalPages()"
            >
              Next →
            </app-button>
          </div>
          
          <div class="pagination-size">
            <label>Per page:</label>
            <select [ngModel]="pageSize" (change)="onPageSizeChange($event)">
              @for (size of pageSizeOptions; track size) {
                <option [value]="size">{{ size }}</option>
              }
            </select>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .data-table {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 12px;
      overflow: hidden;
    }
    
    .data-table__toolbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 20px;
      gap: 16px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }
    
    .data-table__search {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px 16px;
      border: 2px solid rgba(148, 163, 184, 0.2);
      border-radius: 10px;
      min-width: 250px;
      transition: border-color 0.2s;
    }
    
    .data-table__search:focus-within {
      border-color: #06b6d4;
    }
    
    .search-icon {
      font-size: 18px;
    }
    
    .search-input {
      flex: 1;
      border: none;
      outline: none;
      font-size: 14px;
      background: transparent;
    }
    
    .data-table__actions {
      display: flex;
      gap: 8px;
    }
    
    .data-table__container {
      overflow-x: auto;
    }
    
    .table {
      width: 100%;
      border-collapse: collapse;
    }
    
    .table th {
      padding: 14px 16px;
      background: linear-gradient(135deg, #f8f9fa, #e9ecef);
      border-bottom: 2px solid rgba(148, 163, 184, 0.2);
      font-weight: 600;
      font-size: 13px;
      color: #334155;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      text-align: left;
      cursor: default;
    }
    
    .table th.sortable {
      cursor: pointer;
      user-select: none;
    }
    
    .table th.sortable:hover {
      background: #e2e8f0;
    }
    
    .table th.sorted {
      background: #e0f2fe;
      color: #0369a1;
    }
    
    .th-content {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    
    .sort-icon {
      opacity: 0.5;
    }
    
    .table td {
      padding: 14px 16px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      font-size: 14px;
      color: #1e293b;
    }
    
    .table tbody tr {
      transition: all 0.2s;
    }
    
    .table tbody tr:hover {
      background: rgba(6, 182, 212, 0.05);
    }
    
    .table tbody tr.selected {
      background: rgba(6, 182, 212, 0.1);
    }
    
    .actions-cell {
      display: flex;
      gap: 8px;
      justify-content: flex-end;
    }
    
    .actions-header {
      width: 120px;
      text-align: right;
    }
    
    .empty-state {
      text-align: center;
      padding: 60px 20px;
      color: #94a3b8;
    }
    
    .empty-icon {
      font-size: 48px;
      display: block;
      margin-bottom: 15px;
    }
    
    .data-table__pagination {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 20px;
      border-top: 1px solid rgba(148, 163, 184, 0.1);
      gap: 16px;
      flex-wrap: wrap;
    }
    
    .pagination-info {
      font-size: 13px;
      color: #64748b;
    }
    
    .pagination-controls {
      display: flex;
      gap: 8px;
      align-items: center;
    }
    
    .page-btn {
      min-width: 36px;
      height: 36px;
      padding: 0 12px;
      border: 1px solid rgba(148, 163, 184, 0.2);
      background: white;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    
    .page-btn:hover {
      background: #f1f5f9;
      border-color: #94a3b8;
    }
    
    .page-btn--active {
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: white;
      border-color: transparent;
    }
    
    .pagination-size {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      color: #64748b;
    }
    
    .pagination-size select {
      padding: 6px 12px;
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 6px;
      font-size: 13px;
      cursor: pointer;
    }
  `]
})
export class DataTableComponent<T> {
  @Input() data: T[] = [];
  @Input() columns: Column<T>[] = [];
  @Input() actions: Action<T>[] = [];
  @Input() pagination = true;
  @Input() showToolbar = true;
  @Input() searchPlaceholder = 'Search...';
  @Input() emptyMessage = 'No data available';
  @Input() pageSizeOptions = [10, 25, 50, 100];
  @Input() selectable = false;
  @Input() selectedItems: T[] = [];
  
  @Output() pageChange = new EventEmitter<number>();
  @Output() pageSizeChange = new EventEmitter<number>();
  @Output() sortChange = new EventEmitter<{key: string, asc: boolean}>();
  @Output() searchChange = new EventEmitter<string>();
  @Output() selectionChange = new EventEmitter<T[]>();
  
  searchQuery = '';
  sortKey: string | keyof T | null = null;
  sortAsc = true;
  currentPage = 1;
  pageSize = 10;
  
  paginatedData = computed(() => {
    let filtered = this.searchData(this.data);
    filtered = this.sortData(filtered);
    
    if (this.pagination) {
      const start = (this.currentPage - 1) * this.pageSize;
      return filtered.slice(start, start + this.pageSize);
    }
    
    return filtered;
  });
  
  totalItems = computed(() => this.searchData(this.data).length);
  totalPages = computed(() => Math.ceil(this.totalItems() / this.pageSize));
  startIndex = computed(() => (this.currentPage - 1) * this.pageSize);
  endIndex = computed(() => Math.min(this.startIndex() + this.pageSize, this.totalItems()));
  
  visiblePages = computed(() => {
    const pages: number[] = [];
    const maxVisible = 5;
    let start = Math.max(1, this.currentPage - Math.floor(maxVisible / 2));
    let end = Math.min(this.totalPages(), start + maxVisible - 1);
    
    if (end - start < maxVisible - 1) {
      start = Math.max(1, end - maxVisible + 1);
    }
    
    for (let i = start; i <= end; i++) {
      pages.push(i);
    }
    
    return pages;
  });
  
  searchData(data: T[]): T[] {
    if (!this.searchQuery) return data;
    
    const query = this.searchQuery.toLowerCase();
    return data.filter(item =>
      Object.values(item as any).some(val =>
        String(val).toLowerCase().includes(query)
      )
    );
  }
  
  sortData(data: T[]): T[] {
    if (!this.sortKey) return data;
    
    return [...data].sort((a, b) => {
      const aVal = (a as any)[this.sortKey!];
      const bVal = (b as any)[this.sortKey!];
      
      if (aVal < bVal) return this.sortAsc ? -1 : 1;
      if (aVal > bVal) return this.sortAsc ? 1 : -1;
      return 0;
    });
  }
  
  onSort(key: string | keyof T): void {
    const keyStr = typeof key === 'string' ? key : String(key);
    
    if (this.sortKey === keyStr) {
      this.sortAsc = !this.sortAsc;
    } else {
      this.sortKey = keyStr;
      this.sortAsc = true;
    }
    this.sortChange.emit({ key: keyStr, asc: this.sortAsc });
  }
  
  onSearch(): void {
    this.currentPage = 1;
    this.searchChange.emit(this.searchQuery);
  }
  
  previousPage(): void {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.pageChange.emit(this.currentPage);
    }
  }
  
  nextPage(): void {
    if (this.currentPage < this.totalPages()) {
      this.currentPage++;
      this.pageChange.emit(this.currentPage);
    }
  }
  
  goToPage(page: number): void {
    this.currentPage = page;
    this.pageChange.emit(page);
  }
  
  onPageSizeChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    this.pageSize = parseInt(value, 10);
    this.currentPage = 1;
    this.pageSizeChange.emit(this.pageSize);
  }
  
  getCellValue(item: T, key: keyof T | string, pipe?: string): string {
    const value = (item as any)[key];
    
    if (value === null || value === undefined) return '';
    
    switch (pipe) {
      case 'date':
        return new Date(value).toLocaleDateString();
      case 'currency':
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
      case 'number':
        return new Intl.NumberFormat().format(value);
      case 'uppercase':
        return String(value).toUpperCase();
      case 'lowercase':
        return String(value).toLowerCase();
      default:
        return String(value);
    }
  }
  
  trackBy(index: number, item: T): any {
    return (item as any).id || index;
  }
  
  isSelected(item: T): boolean {
    return this.selectedItems.includes(item);
  }
}
