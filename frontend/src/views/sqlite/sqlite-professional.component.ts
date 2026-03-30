/**
 * Professional SQLite CRUD Component
 * 
 * Production-ready interface for SQLite operations with:
 * - Clean transactional interface
 * - Product/Inventory management focus
 * - Lightweight and fast operations
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

export interface Product {
  id: number;
  name: string;
  price: number;
  category: string;
  stock: number;
  status: 'InStock' | 'LowStock' | 'OutOfStock';
  created_at: string;
}

export interface ProductStats {
  total_products: number;
  total_value: number;
  categories_count: number;
  low_stock_count: number;
  out_of_stock_count: number;
}

type TabType = 'overview' | 'products' | 'inventory';

// ============================================================================
// Main Component
// ============================================================================

@Component({
  selector: 'app-sqlite-professional',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="sqlite-professional">
      <!-- Header -->
      <header class="sp-header">
        <div class="sp-header__brand">
          <div class="sp-logo">🗄️</div>
          <div class="sp-header__titles">
            <h1 class="sp-header__title">SQLite Manager</h1>
            <p class="sp-header__subtitle">Lightweight transactional database interface</p>
          </div>
        </div>
        <div class="sp-header__actions">
          <div class="sp-connection-status" [class.sp-connection-status--active]="isConnected()">
            <span class="sp-status-dot"></span>
            <span class="sp-status-text">{{ isConnected() ? 'Connected' : 'Disconnected' }}</span>
          </div>
          <button class="sp-btn sp-btn--outline" (click)="refreshAll()" [disabled]="isLoading()">
            <span class="sp-btn__icon">🔄</span>
            Refresh
          </button>
        </div>
      </header>

      <!-- Navigation Tabs -->
      <nav class="sp-tabs">
        <button 
          class="sp-tab" 
          [class.sp-tab--active]="activeTab() === 'overview'"
          (click)="setActiveTab('overview')"
        >
          <span class="sp-tab__icon">📊</span>
          <span class="sp-tab__label">Overview</span>
        </button>
        <button 
          class="sp-tab" 
          [class.sp-tab--active]="activeTab() === 'products'"
          (click)="setActiveTab('products')"
        >
          <span class="sp-tab__icon">📦</span>
          <span class="sp-tab__label">Products</span>
        </button>
        <button 
          class="sp-tab" 
          [class.sp-tab--active]="activeTab() === 'inventory'"
          (click)="setActiveTab('inventory')"
        >
          <span class="sp-tab__icon">📋</span>
          <span class="sp-tab__label">Inventory</span>
        </button>
      </nav>

      <!-- Main Content -->
      <main class="sp-content">
        <!-- Overview Tab -->
        @if (activeTab() === 'overview') {
          <div class="sp-overview">
            <!-- Stats Grid -->
            <div class="sp-stats-grid">
              <div class="sp-stat-card sp-stat-card--blue">
                <div class="sp-stat-card__header">
                  <span class="sp-stat-card__icon">📦</span>
                  <span class="sp-stat-card__label">Total Products</span>
                </div>
                <div class="sp-stat-card__value">{{ stats().total_products }}</div>
                <div class="sp-stat-card__footer">
                  <span class="sp-stat-card__trend">All categories</span>
                </div>
              </div>

              <div class="sp-stat-card sp-stat-card--green">
                <div class="sp-stat-card__header">
                  <span class="sp-stat-card__icon">💰</span>
                  <span class="sp-stat-card__label">Total Value</span>
                </div>
                <div class="sp-stat-card__value">\${{ stats().total_value | number:'1.0-2' }}</div>
                <div class="sp-stat-card__footer">
                  <span class="sp-stat-card__trend">Inventory worth</span>
                </div>
              </div>

              <div class="sp-stat-card sp-stat-card--purple">
                <div class="sp-stat-card__header">
                  <span class="sp-stat-card__icon">🏷️</span>
                  <span class="sp-stat-card__label">Categories</span>
                </div>
                <div class="sp-stat-card__value">{{ stats().categories_count }}</div>
                <div class="sp-stat-card__footer">
                  <span class="sp-stat-card__trend">Product types</span>
                </div>
              </div>

              <div class="sp-stat-card sp-stat-card--orange">
                <div class="sp-stat-card__header">
                  <span class="sp-stat-card__icon">⚠️</span>
                  <span class="sp-stat-card__label">Low Stock</span>
                </div>
                <div class="sp-stat-card__value">{{ stats().low_stock_count }}</div>
                <div class="sp-stat-card__footer">
                  <span class="sp-stat-card__trend" [class.sp-stat-card__trend--danger]="stats().low_stock_count > 5">
                    {{ stats().out_of_stock_count }} out of stock
                  </span>
                </div>
              </div>
            </div>

            <!-- Quick Stats & Recent -->
            <div class="sp-overview-grid">
              <div class="sp-card">
                <div class="sp-card__header">
                  <h3 class="sp-card__title">📊 Category Distribution</h3>
                </div>
                <div class="sp-card__content">
                  <div class="sp-category-list">
                    @for (cat of categories(); track cat.name; let i = $index) {
                      <div class="sp-category-item">
                        <span class="sp-category-name">{{ cat.name }}</span>
                        <div class="sp-category-bar">
                          <div class="sp-category-fill" [style.width.%]="cat.percentage"></div>
                        </div>
                        <span class="sp-category-count">{{ cat.count }}</span>
                      </div>
                    }
                  </div>
                </div>
              </div>

              <div class="sp-card">
                <div class="sp-card__header">
                  <h3 class="sp-card__title">⚡ Quick Actions</h3>
                </div>
                <div class="sp-card__content">
                  <div class="sp-quick-actions">
                    <button class="sp-action-btn" (click)="setActiveTab('products'); setMode('create')">
                      <span class="sp-action-btn__icon">➕</span>
                      <span class="sp-action-btn__text">Add Product</span>
                    </button>
                    <button class="sp-action-btn" (click)="setActiveTab('inventory')">
                      <span class="sp-action-btn__icon">📋</span>
                      <span class="sp-action-btn__text">View Inventory</span>
                    </button>
                    <button class="sp-action-btn" (click)="exportData()">
                      <span class="sp-action-btn__icon">📥</span>
                      <span class="sp-action-btn__text">Export Data</span>
                    </button>
                    <button class="sp-action-btn" (click)="refreshAll()">
                      <span class="sp-action-btn__icon">🔄</span>
                      <span class="sp-action-btn__text">Refresh All</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        }

        <!-- Products Tab -->
        @if (activeTab() === 'products') {
          <div class="sp-products">
            <div class="sp-products__header">
              <div class="sp-products__title">
                <h2>Product Management</h2>
                <p>Manage your product catalog</p>
              </div>
              <div class="sp-products__actions">
                <div class="sp-search-filter">
                  <select class="sp-select" [(ngModel)]="selectedCategory" (change)="filterProducts()">
                    <option value="">All Categories</option>
                    @for (cat of categoryOptions; track cat) {
                      <option [value]="cat">{{ cat }}</option>
                    }
                  </select>
                </div>
                <div class="sp-search-box">
                  <span class="sp-search-box__icon">🔍</span>
                  <input 
                    type="text" 
                    class="sp-search-box__input" 
                    placeholder="Search products..."
                    [(ngModel)]="searchQuery"
                    (input)="filterProducts()"
                  />
                </div>
                <button class="sp-btn sp-btn--primary" (click)="setMode('create')">
                  <span class="sp-btn__icon">➕</span>
                  Add Product
                </button>
              </div>
            </div>

            @if (productsMode() === 'list') {
              <div class="sp-table-container">
                @if (isLoading()) {
                  <div class="sp-loading">
                    <div class="sploading-spinner"></div>
                    <span>Loading products...</span>
                  </div>
                } @else if (filteredProducts().length === 0) {
                  <div class="sp-empty-state">
                    <div class="sp-empty-state__icon">📭</div>
                    <h3>No products found</h3>
                    <p>Add your first product to get started</p>
                    <button class="sp-btn sp-btn--primary" (click)="setMode('create')">
                      Add Product
                    </button>
                  </div>
                } @else {
                  <table class="sp-table">
                    <thead>
                      <tr>
                        <th>Product</th>
                        <th>Category</th>
                        <th>Price</th>
                        <th>Stock</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      @for (product of filteredProducts(); track product.id) {
                        <tr class="sp-table__row">
                          <td>
                            <div class="sp-product-name">{{ product.name }}</div>
                            <div class="sp-product-id">ID: #{{ product.id }}</div>
                          </td>
                          <td>
                            <span class="sp-badge">{{ product.category }}</span>
                          </td>
                          <td>
                            <span class="sp-price">\${{ product.price | number:'1.2-2' }}</span>
                          </td>
                          <td>
                            <span class="sp-stock">{{ product.stock }} units</span>
                          </td>
                          <td>
                            <span class="sp-status" [class]="'sp-status--' + product.status.toLowerCase()">
                              {{ getStatusLabel(product.status) }}
                            </span>
                          </td>
                          <td>
                            <div class="sp-table__actions">
                              <button class="sp-icon-btn sp-icon-btn--edit" (click)="editProduct(product)" title="Edit">
                                ✏️
                              </button>
                              <button class="sp-icon-btn sp-icon-btn--delete" (click)="deleteProduct(product)" title="Delete">
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
              <div class="sp-form-wrapper">
                <div class="sp-form-card">
                  <div class="sp-form-header">
                    <div>
                      <h3>{{ isEditMode() ? '✏️ Edit Product' : '➕ Add Product' }}</h3>
                      <p>Fill in the product details</p>
                    </div>
                    <button class="sp-btn sp-btn--ghost" (click)="setMode('list')">Cancel</button>
                  </div>
                  <form class="sp-form" (ngSubmit)="saveProduct()">
                    <div class="sp-form__row">
                      <div class="sp-form__group">
                        <label class="sp-form__label">
                          <span class="sp-form__icon">📝</span>
                          Product Name
                        </label>
                        <input 
                          type="text" 
                          class="sp-form__input"
                          [ngModel]="editingProduct().name"
                          (ngModelChange)="updateEditingProduct('name', $event)"
                          name="name"
                          required
                          placeholder="Enter product name"
                        />
                      </div>
                      <div class="sp-form__group">
                        <label class="sp-form__label">
                          <span class="sp-form__icon">🏷️</span>
                          Category
                        </label>
                        <select 
                          class="sp-form__input sp-form__select"
                          [ngModel]="editingProduct().category"
                          (ngModelChange)="updateEditingProduct('category', $event)"
                          name="category"
                          required
                        >
                          <option value="">Select category</option>
                          @for (cat of categoryOptions; track cat) {
                            <option [value]="cat">{{ cat }}</option>
                          }
                        </select>
                      </div>
                    </div>
                    <div class="sp-form__row">
                      <div class="sp-form__group">
                        <label class="sp-form__label">
                          <span class="sp-form__icon">💰</span>
                          Price
                        </label>
                        <input 
                          type="number" 
                          class="sp-form__input"
                          [ngModel]="editingProduct().price"
                          (ngModelChange)="updateEditingProduct('price', $event)"
                          name="price"
                          required
                          min="0"
                          step="0.01"
                          placeholder="0.00"
                        />
                      </div>
                      <div class="sp-form__group">
                        <label class="sp-form__label">
                          <span class="sp-form__icon">📦</span>
                          Stock Quantity
                        </label>
                        <input 
                          type="number" 
                          class="sp-form__input"
                          [ngModel]="editingProduct().stock"
                          (ngModelChange)="updateEditingProduct('stock', $event)"
                          name="stock"
                          required
                          min="0"
                          placeholder="0"
                        />
                      </div>
                    </div>
                    <div class="sp-form__actions">
                      <button type="submit" class="sp-btn sp-btn--primary" [disabled]="isLoading()">
                        {{ isLoading() ? 'Saving...' : (isEditMode() ? '💾 Update Product' : '➕ Create Product') }}
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            }
          </div>
        }

        <!-- Inventory Tab -->
        @if (activeTab() === 'inventory') {
          <div class="sp-inventory">
            <div class="sp-inventory__header">
              <h2>📋 Inventory Overview</h2>
              <p>Track stock levels and inventory status</p>
            </div>

            <div class="sp-inventory-grid">
              <div class="sp-inventory-card sp-inventory-card--success">
                <div class="sp-inventory-card__icon">✅</div>
                <div class="sp-inventory-card__content">
                  <div class="sp-inventory-card__value">{{ inStockCount() }}</div>
                  <div class="sp-inventory-card__label">In Stock</div>
                </div>
              </div>

              <div class="sp-inventory-card sp-inventory-card--warning">
                <div class="sp-inventory-card__icon">⚠️</div>
                <div class="sp-inventory-card__content">
                  <div class="sp-inventory-card__value">{{ stats().low_stock_count }}</div>
                  <div class="sp-inventory-card__label">Low Stock</div>
                </div>
              </div>

              <div class="sp-inventory-card sp-inventory-card--danger">
                <div class="sp-inventory-card__icon">❌</div>
                <div class="sp-inventory-card__content">
                  <div class="sp-inventory-card__value">{{ stats().out_of_stock_count }}</div>
                  <div class="sp-inventory-card__label">Out of Stock</div>
                </div>
              </div>
            </div>

            <div class="sp-card">
              <div class="sp-card__header">
                <h3 class="sp-card__title">📦 All Products by Stock Level</h3>
              </div>
              <div class="sp-card__content">
                <div class="sp-inventory-list">
                  @for (product of sortedByStock(); track product.id) {
                    <div class="sp-inventory-item">
                      <div class="sp-inventory-item__info">
                        <span class="sp-inventory-item__name">{{ product.name }}</span>
                        <span class="sp-inventory-item__category">{{ product.category }}</span>
                      </div>
                      <div class="sp-inventory-item__stock">
                        <div class="sp-stock-bar">
                          <div 
                            class="sp-stock-fill" 
                            [class.sp-stock-fill--low]="product.stock < 10"
                            [class.sp-stock-fill--out]="product.stock === 0"
                            [style.width.%]="getStockPercentage(product.stock)"
                          ></div>
                        </div>
                        <span class="sp-inventory-item__count">{{ product.stock }} units</span>
                      </div>
                    </div>
                  }
                </div>
              </div>
            </div>
          </div>
        }
      </main>
    </div>
  `,
  styles: [`
    /* ============================================================================
       Professional SQLite Component Styles
       ============================================================================ */
    
    :host {
      display: block;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    }

    .sqlite-professional {
      min-height: 100vh;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
    }

    /* Header */
    .sp-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 24px 32px;
      background: rgba(255, 255, 255, 0.03);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .sp-header__brand {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .sp-logo {
      font-size: 48px;
      line-height: 1;
    }

    .sp-header__title {
      font-size: 28px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0;
    }

    .sp-header__subtitle {
      font-size: 14px;
      color: #94a3b8;
      margin: 4px 0 0;
    }

    .sp-header__actions {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .sp-connection-status {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      background: rgba(148, 163, 184, 0.1);
      border-radius: 20px;
      font-size: 13px;
      color: #94a3b8;
    }

    .sp-connection-status--active {
      background: rgba(16, 185, 129, 0.15);
      color: #10b981;
    }

    .sp-status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: currentColor;
      animation: pulse 2s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }

    /* Tabs */
    .sp-tabs {
      display: flex;
      gap: 8px;
      padding: 16px 32px;
      background: rgba(255, 255, 255, 0.02);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .sp-tab {
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

    .sp-tab:hover {
      background: rgba(148, 163, 184, 0.1);
      color: #f8fafc;
    }

    .sp-tab--active {
      background: linear-gradient(135deg, #10b981, #059669);
      color: white;
    }

    .sp-tab__icon {
      font-size: 16px;
    }

    /* Content */
    .sp-content {
      padding: 32px;
    }

    /* Stats Grid */
    .sp-stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      margin-bottom: 32px;
    }

    .sp-stat-card {
      padding: 24px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      transition: all 0.3s;
    }

    .sp-stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 30px rgba(0, 0, 0, 0.3);
    }

    .sp-stat-card__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
    }

    .sp-stat-card__icon {
      font-size: 28px;
    }

    .sp-stat-card__label {
      font-size: 13px;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .sp-stat-card__value {
      font-size: 36px;
      font-weight: 700;
      color: #f8fafc;
      margin-bottom: 8px;
    }

    .sp-stat-card__footer {
      padding-top: 12px;
      border-top: 1px solid rgba(148, 163, 184, 0.1);
    }

    .sp-stat-card__trend {
      font-size: 12px;
      color: #64748b;
    }

    .sp-stat-card__trend--danger {
      color: #ef4444;
    }

    .sp-stat-card--blue .sp-stat-card__icon { color: #3b82f6; }
    .sp-stat-card--green .sp-stat-card__icon { color: #10b981; }
    .sp-stat-card--purple .sp-stat-card__icon { color: #8b5cf6; }
    .sp-stat-card--orange .sp-stat-card__icon { color: #f59e0b; }

    /* Overview Grid */
    .sp-overview-grid {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 20px;
    }

    /* Cards */
    .sp-card {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .sp-card__header {
      padding: 20px 24px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .sp-card__title {
      font-size: 16px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0;
    }

    .sp-card__content {
      padding: 24px;
    }

    /* Category List */
    .sp-category-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .sp-category-item {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .sp-category-name {
      width: 120px;
      font-size: 14px;
      color: #f8fafc;
      font-weight: 500;
    }

    .sp-category-bar {
      flex: 1;
      height: 8px;
      background: rgba(148, 163, 184, 0.1);
      border-radius: 4px;
      overflow: hidden;
    }

    .sp-category-fill {
      height: 100%;
      background: linear-gradient(135deg, #10b981, #059669);
      border-radius: 4px;
      transition: width 0.5s ease;
    }

    .sp-category-count {
      width: 50px;
      text-align: right;
      font-size: 13px;
      color: #94a3b8;
    }

    /* Quick Actions */
    .sp-quick-actions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .sp-action-btn {
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

    .sp-action-btn:hover {
      background: rgba(148, 163, 184, 0.15);
      border-color: rgba(148, 163, 184, 0.3);
      color: #f8fafc;
      transform: translateY(-2px);
    }

    .sp-action-btn__icon {
      font-size: 24px;
    }

    .sp-action-btn__text {
      font-size: 13px;
      font-weight: 500;
    }

    /* Products Section */
    .sp-products__header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 24px;
      flex-wrap: wrap;
      gap: 16px;
    }

    .sp-products__title h2 {
      font-size: 24px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0 0 4px;
    }

    .sp-products__title p {
      font-size: 14px;
      color: #94a3b8;
      margin: 0;
    }

    .sp-products__actions {
      display: flex;
      gap: 12px;
      align-items: center;
      flex-wrap: wrap;
    }

    /* Search & Filter */
    .sp-search-filter {
      min-width: 180px;
    }

    .sp-select {
      width: 100%;
      padding: 10px 14px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 8px;
      font-size: 14px;
      color: #f8fafc;
      cursor: pointer;
    }

    .sp-search-box {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 10px 16px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 8px;
      min-width: 250px;
    }

    .sp-search-box__icon {
      font-size: 18px;
    }

    .sp-search-box__input {
      flex: 1;
      border: none;
      outline: none;
      font-size: 14px;
      background: transparent;
      color: #f8fafc;
    }

    /* Table */
    .sp-table-container {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .sp-table {
      width: 100%;
      border-collapse: collapse;
    }

    .sp-table th {
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

    .sp-table__row {
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      transition: background 0.2s;
    }

    .sp-table__row:hover {
      background: rgba(148, 163, 184, 0.05);
    }

    .sp-table td {
      padding: 16px 20px;
      font-size: 14px;
    }

    .sp-product-name {
      font-weight: 500;
      color: #f8fafc;
    }

    .sp-product-id {
      font-size: 12px;
      color: #64748b;
      margin-top: 4px;
    }

    .sp-badge {
      padding: 4px 12px;
      background: rgba(59, 130, 246, 0.15);
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      color: #3b82f6;
    }

    .sp-price {
      font-weight: 600;
      color: #10b981;
    }

    .sp-stock {
      color: #e2e8f0;
    }

    .sp-status {
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }

    .sp-status--instock {
      background: rgba(16, 185, 129, 0.15);
      color: #10b981;
    }

    .sp-status--lowstock {
      background: rgba(245, 158, 11, 0.15);
      color: #f59e0b;
    }

    .sp-status--outofstock {
      background: rgba(239, 68, 68, 0.15);
      color: #ef4444;
    }

    .sp-table__actions {
      display: flex;
      gap: 8px;
    }

    .sp-icon-btn {
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

    .sp-icon-btn--edit {
      background: rgba(59, 130, 246, 0.1);
    }

    .sp-icon-btn--edit:hover {
      background: rgba(59, 130, 246, 0.2);
    }

    .sp-icon-btn--delete {
      background: rgba(239, 68, 68, 0.1);
    }

    .sp-icon-btn--delete:hover {
      background: rgba(239, 68, 68, 0.2);
    }

    /* Form */
    .sp-form-wrapper {
      max-width: 800px;
      margin: 0 auto;
    }

    .sp-form-card {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      padding: 32px;
    }

    .sp-form-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 32px;
    }

    .sp-form-header h3 {
      font-size: 20px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0 0 4px;
    }

    .sp-form-header p {
      font-size: 14px;
      color: #94a3b8;
      margin: 0;
    }

    .sp-form {
      display: flex;
      flex-direction: column;
      gap: 24px;
    }

    .sp-form__row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 24px;
    }

    .sp-form__group {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .sp-form__label {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      font-weight: 600;
      color: #f8fafc;
    }

    .sp-form__icon {
      font-size: 16px;
    }

    .sp-form__input {
      padding: 12px 16px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 8px;
      font-size: 15px;
      color: #f8fafc;
      transition: all 0.2s;
    }

    .sp-form__input:focus {
      outline: none;
      border-color: #10b981;
      box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
    }

    .sp-form__select {
      cursor: pointer;
    }

    .sp-form__actions {
      padding-top: 8px;
    }

    /* Buttons */
    .sp-btn {
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

    .sp-btn--primary {
      background: linear-gradient(135deg, #10b981, #059669);
      color: white;
    }

    .sp-btn--primary:hover:not(:disabled) {
      background: linear-gradient(135deg, #059669, #047857);
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
    }

    .sp-btn--outline {
      background: transparent;
      border: 1px solid rgba(148, 163, 184, 0.3);
      color: #94a3b8;
    }

    .sp-btn--outline:hover {
      border-color: rgba(148, 163, 184, 0.5);
      color: #f8fafc;
    }

    .sp-btn--ghost {
      background: transparent;
      color: #94a3b8;
    }

    .sp-btn--ghost:hover {
      background: rgba(148, 163, 184, 0.1);
      color: #f8fafc;
    }

    .sp-btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .sp-btn__icon {
      font-size: 16px;
    }

    /* Loading & Empty States */
    .sploading {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      padding: 60px 20px;
      color: #94a3b8;
    }

    .sploading-spinner {
      width: 40px;
      height: 40px;
      border: 3px solid rgba(148, 163, 184, 0.2);
      border-top-color: #10b981;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .sp-empty-state {
      text-align: center;
      padding: 80px 20px;
      color: #94a3b8;
    }

    .sp-empty-state__icon {
      font-size: 64px;
      display: block;
      margin-bottom: 20px;
    }

    .sp-empty-state h3 {
      font-size: 20px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0 0 8px;
    }

    .sp-empty-state p {
      font-size: 14px;
      margin: 0 0 20px;
    }

    /* Inventory */
    .sp-inventory__header {
      margin-bottom: 32px;
    }

    .sp-inventory__header h2 {
      font-size: 24px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0 0 4px;
    }

    .sp-inventory__header p {
      font-size: 14px;
      color: #94a3b8;
      margin: 0;
    }

    .sp-inventory-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 20px;
      margin-bottom: 32px;
    }

    .sp-inventory-card {
      display: flex;
      align-items: center;
      gap: 20px;
      padding: 24px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
    }

    .sp-inventory-card__icon {
      font-size: 40px;
    }

    .sp-inventory-card__content {
      display: flex;
      flex-direction: column;
    }

    .sp-inventory-card__value {
      font-size: 32px;
      font-weight: 700;
      color: #f8fafc;
    }

    .sp-inventory-card__label {
      font-size: 13px;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .sp-inventory-card--success { border-color: rgba(16, 185, 129, 0.3); }
    .sp-inventory-card--warning { border-color: rgba(245, 158, 11, 0.3); }
    .sp-inventory-card--danger { border-color: rgba(239, 68, 68, 0.3); }

    .sp-inventory-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .sp-inventory-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      background: rgba(148, 163, 184, 0.05);
      border-radius: 8px;
    }

    .sp-inventory-item__info {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .sp-inventory-item__name {
      font-weight: 500;
      color: #f8fafc;
    }

    .sp-inventory-item__category {
      font-size: 13px;
      color: #94a3b8;
    }

    .sp-inventory-item__stock {
      display: flex;
      align-items: center;
      gap: 16px;
      flex: 1;
      max-width: 400px;
      margin-left: auto;
    }

    .sp-stock-bar {
      flex: 1;
      height: 8px;
      background: rgba(148, 163, 184, 0.1);
      border-radius: 4px;
      overflow: hidden;
    }

    .sp-stock-fill {
      height: 100%;
      background: linear-gradient(135deg, #10b981, #059669);
      border-radius: 4px;
      transition: width 0.5s ease;
    }

    .sp-stock-fill--low {
      background: linear-gradient(135deg, #f59e0b, #d97706);
    }

    .sp-stock-fill--out {
      background: linear-gradient(135deg, #ef4444, #dc2626);
    }

    .sp-inventory-item__count {
      width: 80px;
      text-align: right;
      font-size: 13px;
      color: #94a3b8;
      font-weight: 500;
    }

    /* Responsive */
    @media (max-width: 1200px) {
      .sp-stats-grid {
        grid-template-columns: repeat(2, 1fr);
      }
      
      .sp-overview-grid {
        grid-template-columns: 1fr;
      }
      
      .sp-inventory-grid {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 768px) {
      .sp-header {
        flex-direction: column;
        gap: 16px;
        padding: 20px;
      }
      
      .sp-tabs {
        flex-wrap: wrap;
        padding: 12px 20px;
      }
      
      .sp-content {
        padding: 20px;
      }
      
      .sp-stats-grid {
        grid-template-columns: 1fr;
      }
      
      .sp-products__header {
        flex-direction: column;
      }
      
      .sp-products__actions {
        width: 100%;
      }
      
      .sp-search-box {
        width: 100%;
      }
      
      .sp-form__row {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class SQLiteProfessionalComponent implements OnInit {
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);
  private readonly dbManager = inject(DatabaseManagementService);

  // State
  activeTab = signal<TabType>('overview');
  isLoading = signal(false);
  isConnected = signal(true);

  // Stats
  stats = signal<ProductStats>({ 
    total_products: 0, 
    total_value: 0, 
    categories_count: 0,
    low_stock_count: 0,
    out_of_stock_count: 0,
  });

  // Products
  products = signal<Product[]>([]);
  filteredProducts = signal<Product[]>([]);
  searchQuery = '';
  selectedCategory = '';
  productsMode = signal<'list' | 'create'>('list');
  isEditMode = signal(false);
  editingProduct = signal<Partial<Product>>({ name: '', category: '', price: 0, stock: 0 });

  categoryOptions = ['Electronics', 'Books', 'Clothing', 'Home & Garden', 'Sports', 'Toys', 'Food', 'Other'];
  categories = signal<Array<{name: string, count: number, percentage: number}>>([]);

  // Computed
  inStockCount = computed(() => 
    this.products().filter(p => p.stock >= 10).length
  );

  sortedByStock = computed(() => 
    [...this.products()].sort((a, b) => a.stock - b.stock)
  );

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
    if (tab === 'overview' || tab === 'inventory') {
      this.refreshAll();
    }
  }

  setMode(mode: 'list' | 'create'): void {
    this.productsMode.set(mode);
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
        this.loadProducts(),
        this.loadStats(),
        this.loadCategories(),
      ]);
    } catch (error) {
      this.logger.error('Failed to refresh data', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  async loadProducts(): Promise<void> {
    const products = await this.api.callOrThrow<Product[]>('sqlite:getProducts');
    this.products.set(products);
    this.filterProducts();
  }

  async loadStats(): Promise<void> {
    const stats = await this.api.callOrThrow<ProductStats>('sqlite:getProductStats');
    this.stats.set(stats);
  }

  async loadCategories(): Promise<void> {
    const productsList = this.products();
    const categoryMap: Record<string, number> = {};
    
    productsList.forEach(p => {
      categoryMap[p.category] = (categoryMap[p.category] || 0) + 1;
    });

    const total = productsList.length || 1;
    this.categories.set(
      Object.entries(categoryMap).map(([name, count]) => ({
        name,
        count,
        percentage: (count / total) * 100,
      }))
    );
  }

  // ============================================================================
  // Products Management
  // ============================================================================

  filterProducts(): void {
    let filtered = this.products();
    
    if (this.selectedCategory) {
      filtered = filtered.filter(p => p.category === this.selectedCategory);
    }
    
    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(query) ||
        p.category.toLowerCase().includes(query)
      );
    }
    
    this.filteredProducts.set(filtered);
  }

  resetForm(): void {
    this.isEditMode.set(false);
    this.editingProduct.set({ name: '', category: '', price: 0, stock: 0 });
  }

  updateEditingProduct(field: keyof Product, value: string | number) {
    this.editingProduct.update(p => ({ ...p, [field]: value }));
  }

  async saveProduct(): Promise<void> {
    if (!this.editingProduct().name || !this.editingProduct().category) {
      this.logger.warn('Validation failed');
      return;
    }

    this.isLoading.set(true);
    try {
      if (this.isEditMode()) {
        await this.api.callOrThrow('sqlite:updateProduct', [this.editingProduct()]);
        this.logger.info('Product updated');
      } else {
        await this.api.callOrThrow('sqlite:createProduct', [this.editingProduct()]);
        this.logger.info('Product created');
      }
      this.resetForm();
      this.setMode('list');
      await this.refreshAll();
    } catch (error) {
      this.logger.error('Failed to save product', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  editProduct(product: Product): void {
    this.editingProduct.set({ ...product });
    this.isEditMode.set(true);
    this.setMode('create');
  }

  async deleteProduct(product: Product): Promise<void> {
    const confirmed = await this.dbManager.deleteProduct(product.id, product.name);
    
    if (confirmed) {
      await this.refreshAll();
    }
  }

  // ============================================================================
  // Utilities
  // ============================================================================

  getStatusLabel(status: string): string {
    switch (status) {
      case 'InStock': return 'In Stock';
      case 'LowStock': return 'Low Stock';
      case 'OutOfStock': return 'Out of Stock';
      default: return status;
    }
  }

  getStockPercentage(stock: number): number {
    const maxStock = 100;
    return Math.min((stock / maxStock) * 100, 100);
  }

  exportData(): void {
    const data = JSON.stringify(this.products(), null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `products-export-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    this.logger.info('Data exported');
  }
}
