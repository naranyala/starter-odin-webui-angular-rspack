/**
 * SQLite CRUD Demo Component
 * 
 * Complete CRUD operations demo with SQLite database
 * Features: Create, Read, Update, Delete with transaction support
 */

import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LoggerService } from '../../core/logger.service';
import { ApiService } from '../../core/api.service';

export interface Product {
  id: number;
  name: string;
  price: number;
  category: string;
  stock: number;
  created_at: string;
}

export interface ProductStats {
  total_products: number;
  total_value: number;
  categories_count: number;
  low_stock_count: number;
}

@Component({
  selector: 'app-sqlite-crud-demo',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="crud-wrapper">
      <div class="crud-container">
        <!-- Header -->
        <div class="crud-header">
          <div class="header-logo">
            <span class="logo-icon">🗄️</span>
          </div>
          <div class="header-content">
            <h1 class="header-title">SQLite CRUD Demo</h1>
            <p class="header-subtitle">Lightweight database with transaction support</p>
          </div>
        </div>

        <!-- Stats Bar -->
        <div class="stats-bar">
          <div class="stat-item">
            <span class="stat-icon">📦</span>
            <span class="stat-value">{{ stats().total_products }}</span>
            <span class="stat-label">Total Products</span>
          </div>
          <div class="stat-item">
            <span class="stat-icon">💰</span>
            <span class="stat-value">\${{ stats().total_value | number:'1.0-2' }}</span>
            <span class="stat-label">Total Value</span>
          </div>
          <div class="stat-item">
            <span class="stat-icon">🏷️</span>
            <span class="stat-value">{{ stats().categories_count }}</span>
            <span class="stat-label">Categories</span>
          </div>
          <div class="stat-item">
            <span class="stat-icon">⚠️</span>
            <span class="stat-value">{{ stats().low_stock_count }}</span>
            <span class="stat-label">Low Stock</span>
          </div>
        </div>

        <!-- Action Tabs -->
        <div class="tabs">
          <button type="button" class="tab" [class.active]="activeTab() === 'list'" (click)="setActiveTab('list')">
            <span class="tab-icon">📋</span>
            <span class="tab-label">Product List</span>
          </button>
          <button type="button" class="tab" [class.active]="activeTab() === 'create'" (click)="setActiveTab('create')">
            <span class="tab-icon">➕</span>
            <span class="tab-label">Add Product</span>
          </button>
        </div>

        <!-- List Tab -->
        @if (activeTab() === 'list') {
          <div class="tab-content">
            <div class="toolbar">
              <div class="filter-group">
                <select class="category-filter" [(ngModel)]="selectedCategory" (change)="filterProducts()">
                  <option value="">All Categories</option>
                  @for (cat of categories; track cat) {
                    <option [value]="cat">{{ cat }}</option>
                  }
                </select>
              </div>
              <div class="search-box">
                <span class="search-icon">🔍</span>
                <input type="text" class="search-input" placeholder="Search products..." [(ngModel)]="searchQuery"
                  (input)="filterProducts()" />
              </div>
              <button class="btn-refresh" (click)="loadProducts()">
                <span>🔄</span> Refresh
              </button>
            </div>

            @if (isLoading()) {
              <div class="loading-state">
                <span class="loading-spinner">⏳</span>
                <span>Loading products...</span>
              </div>
            } @else if (filteredProducts().length === 0) {
              <div class="empty-state">
                <span class="empty-icon">📭</span>
                <p>No products found</p>
                <button class="btn-primary" (click)="setActiveTab('create')">Add your first product</button>
              </div>
            } @else {
              <div class="product-table">
                <div class="table-header">
                  <div class="col col-name">Product</div>
                  <div class="col col-category">Category</div>
                  <div class="col col-price">Price</div>
                  <div class="col col-stock">Stock</div>
                  <div class="col col-stock-level">Status</div>
                  <div class="col col-actions">Actions</div>
                </div>
                @for (product of filteredProducts(); track product.id) {
                  <div class="table-row">
                    <div class="col col-name">
                      <span class="product-name">{{ product.name }}</span>
                    </div>
                    <div class="col col-category">
                      <span class="category-badge">{{ product.category }}</span>
                    </div>
                    <div class="col col-price">\${{ product.price | number:'1.2-2' }}</div>
                    <div class="col col-stock">{{ product.stock }}</div>
                    <div class="col col-stock-level">
                      <span class="stock-badge" [class.low]="product.stock < 10" [class.ok]="product.stock >= 10">
                        {{ product.stock < 10 ? '⚠️ Low' : '✅ In Stock' }}
                      </span>
                    </div>
                    <div class="col col-actions">
                      <button class="btn-action btn-edit" (click)="editProduct(product)" title="Edit">✏️</button>
                      <button class="btn-action btn-delete" (click)="deleteProduct(product)" title="Delete">🗑️</button>
                    </div>
                  </div>
                }
              </div>
            }
          </div>
        }

        <!-- Create/Edit Tab -->
        @if (activeTab() === 'create') {
          <div class="tab-content">
            <form class="product-form" (ngSubmit)="saveProduct()">
              <div class="form-header">
                <h2>{{ isEditMode() ? 'Edit Product' : 'Add New Product' }}</h2>
                @if (isEditMode()) {
                  <button type="button" class="btn-cancel" (click)="cancelEdit()">Cancel</button>
                }
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">
                    <span class="label-icon">📝</span>
                    Product Name
                  </label>
                  <input type="text" class="form-input"
                    [ngModel]="editingProduct().name"
                    (ngModelChange)="updateEditingProduct('name', $event)"
                    name="name"
                    required
                    placeholder="Enter product name" />
                </div>
                
                <div class="form-group">
                  <label class="form-label">
                    <span class="label-icon">🏷️</span>
                    Category
                  </label>
                  <select class="form-input"
                    [ngModel]="editingProduct().category"
                    (ngModelChange)="updateEditingProduct('category', $event)"
                    name="category"
                    required>
                    <option value="">Select category</option>
                    @for (cat of categories; track cat) {
                      <option [value]="cat">{{ cat }}</option>
                    }
                  </select>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">
                    <span class="label-icon">💰</span>
                    Price
                  </label>
                  <input type="number" class="form-input"
                    [ngModel]="editingProduct().price"
                    (ngModelChange)="updateEditingProduct('price', $event)"
                    name="price"
                    required
                    min="0"
                    step="0.01"
                    placeholder="0.00" />
                </div>
                
                <div class="form-group">
                  <label class="form-label">
                    <span class="label-icon">📦</span>
                    Stock Quantity
                  </label>
                  <input type="number" class="form-input"
                    [ngModel]="editingProduct().stock"
                    (ngModelChange)="updateEditingProduct('stock', $event)"
                    name="stock"
                    required
                    min="0"
                    placeholder="0" />
                </div>
              </div>
              
              <div class="form-actions">
                <button type="submit" class="btn-submit" [disabled]="isLoading()">
                  {{ isLoading() ? (isEditMode() ? 'Updating...' : 'Creating...') : (isEditMode() ? '💾 Update Product' : '➕ Add Product') }}
                </button>
              </div>
            </form>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    :host { display: block; }
    .crud-wrapper { display: flex; justify-content: center; align-items: flex-start; min-height: 100vh; padding: 20px; background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%); }
    .crud-container { background: rgba(255,255,255,0.98); border-radius: 20px; padding: 40px; width: 100%; max-width: 1000px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
    .crud-header { display: flex; align-items: center; gap: 20px; margin-bottom: 30px; }
    .header-logo { display: flex; width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, #00b09b, #96c93d); justify-content: center; align-items: center; box-shadow: 0 4px 15px rgba(0,176,155,0.4); }
    .logo-icon { font-size: 40px; }
    .header-content { flex: 1; }
    .header-title { font-size: 32px; margin: 0 0 8px; color: #1a1a2e; font-weight: 700; }
    .header-subtitle { font-size: 15px; color: #666; margin: 0; }
    .stats-bar { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 30px; padding: 20px; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 15px; }
    .stat-item { text-align: center; display: flex; flex-direction: column; align-items: center; gap: 8px; }
    .stat-icon { font-size: 24px; }
    .stat-value { display: block; font-size: 24px; font-weight: bold; color: #00b09b; }
    .stat-label { display: block; font-size: 12px; color: #666; text-transform: uppercase; letter-spacing: 0.5px; }
    .tabs { display: flex; gap: 10px; margin-bottom: 25px; }
    .tab { flex: 1; padding: 14px 20px; border: 2px solid #e0e0e0; border-radius: 12px; background: white; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; justify-content: center; gap: 8px; font-size: 14px; font-weight: 600; color: #333; }
    .tab.active { border-color: #00b09b; background: linear-gradient(135deg, #e0fff5, #e8f5e9); color: #0077b6; }
    .tab:hover:not(.active) { border-color: #00b09b; background: #f8f9fa; }
    .tab-icon { font-size: 16px; }
    .tab-content { min-height: 400px; }
    .toolbar { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }
    .filter-group { flex: 0 0 200px; }
    .category-filter { width: 100%; padding: 12px 16px; border: 2px solid #e0e0e0; border-radius: 10px; font-size: 14px; cursor: pointer; transition: border-color 0.2s; }
    .category-filter:focus { outline: none; border-color: #00b09b; }
    .search-box { flex: 1; display: flex; align-items: center; gap: 10px; padding: 12px 16px; border: 2px solid #e0e0e0; border-radius: 10px; transition: border-color 0.2s; min-width: 200px; }
    .search-box:focus-within { border-color: #00b09b; }
    .search-icon { font-size: 18px; }
    .search-input { flex: 1; border: none; outline: none; font-size: 14px; }
    .btn-refresh { padding: 12px 20px; background: #f0f0f0; border: none; border-radius: 10px; cursor: pointer; font-weight: 600; transition: all 0.2s; display: flex; align-items: center; gap: 8px; }
    .btn-refresh:hover { background: #e0e0e0; }
    .loading-state { text-align: center; padding: 60px 20px; color: #666; }
    .loading-spinner { font-size: 32px; display: block; margin-bottom: 10px; animation: spin 1s linear infinite; }
    @keyframes spin { 100% { transform: rotate(360deg); } }
    .empty-state { text-align: center; padding: 60px 20px; color: #999; }
    .empty-icon { font-size: 48px; display: block; margin-bottom: 15px; }
    .btn-primary { padding: 12px 24px; background: linear-gradient(135deg, #00b09b, #96c93d); color: white; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; margin-top: 15px; }
    .product-table { display: flex; flex-direction: column; gap: 10px; }
    .table-header, .table-row { display: grid; grid-template-columns: 2fr 1.5fr 1fr 1fr 1.2fr 1fr; gap: 15px; padding: 15px; align-items: center; }
    .table-header { background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 12px; font-weight: 600; font-size: 13px; color: #333; text-transform: uppercase; letter-spacing: 0.5px; }
    .table-row { background: white; border: 1px solid #e0e0e0; border-radius: 12px; transition: all 0.2s; }
    .table-row:hover { border-color: #00b09b; box-shadow: 0 2px 10px rgba(0,176,155,0.1); }
    .col { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .product-name { font-weight: 500; }
    .category-badge { padding: 4px 12px; background: #e3f2fd; border-radius: 20px; font-size: 12px; font-weight: 600; color: #1976d2; }
    .stock-badge { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
    .stock-badge.ok { background: #e8f5e9; color: #2e7d32; }
    .stock-badge.low { background: #fff3e0; color: #f57c00; }
    .actions { display: flex; gap: 8px; }
    .btn-action { padding: 8px 12px; border: none; border-radius: 8px; cursor: pointer; font-size: 14px; transition: all 0.2s; }
    .btn-edit { background: #e3f2fd; }
    .btn-edit:hover { background: #bbdefb; }
    .btn-delete { background: #ffebee; }
    .btn-delete:hover { background: #ffcdd2; }
    .product-form { display: flex; flex-direction: column; gap: 25px; max-width: 600px; margin: 0 auto; }
    .form-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
    .form-header h2 { margin: 0; color: #1a1a2e; font-size: 24px; }
    .btn-cancel { padding: 8px 16px; background: #f0f0f0; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; }
    .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    .form-group { display: flex; flex-direction: column; gap: 8px; }
    .form-label { display: flex; align-items: center; gap: 8px; font-weight: 600; color: #333; font-size: 14px; }
    .label-icon { font-size: 16px; }
    .form-input { padding: 14px 16px; border: 2px solid #e0e0e0; border-radius: 10px; font-size: 15px; transition: all 0.2s; }
    .form-input:focus { outline: none; border-color: #00b09b; box-shadow: 0 0 0 3px rgba(0,176,155,0.1); }
    .form-actions { display: flex; justify-content: center; padding-top: 10px; }
    .btn-submit { padding: 16px 40px; background: linear-gradient(135deg, #00b09b, #96c93d); color: white; border: none; border-radius: 12px; font-size: 16px; font-weight: 600; cursor: pointer; transition: all 0.2s; min-width: 200px; }
    .btn-submit:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0,176,155,0.4); }
    .btn-submit:disabled { opacity: 0.6; cursor: not-allowed; }
    
    @media (max-width: 768px) {
      .stats-bar { grid-template-columns: repeat(2, 1fr); }
      .table-header, .table-row { grid-template-columns: 1fr 1fr; gap: 10px; font-size: 12px; }
      .col-actions { grid-column: 1 / -1; justify-content: center; }
      .tabs { flex-direction: column; }
      .form-row { grid-template-columns: 1fr; }
    }
  `]
})
export class SqliteCrudDemoComponent implements OnInit {
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);

  activeTab = signal<'list' | 'create'>('list');
  isLoading = signal(false);
  isEditMode = signal(false);
  stats = signal<ProductStats>({ total_products: 0, total_value: 0, categories_count: 0, low_stock_count: 0 });
  products = signal<Product[]>([]);
  filteredProducts = signal<Product[]>([]);
  searchQuery = '';
  selectedCategory = '';

  categories = ['Electronics', 'Books', 'Clothing', 'Home & Garden', 'Sports', 'Toys', 'Food', 'Other'];

  editingProduct = signal<Partial<Product>>({ name: '', category: '', price: 0, stock: 0 });

  updateEditingProduct(field: keyof Product, value: string | number) {
    this.editingProduct.update(p => ({ ...p, [field]: value }));
  }

  setActiveTab(tab: 'list' | 'create'): void {
    this.activeTab.set(tab);
    if (tab === 'list') {
      this.loadProducts();
    } else if (tab === 'create') {
      this.resetForm();
    }
  }

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

  async loadProducts(): Promise<void> {
    this.isLoading.set(true);
    try {
      const [products, stats] = await Promise.all([
        this.api.callOrThrow<Product[]>('sqlite:getProducts'),
        this.api.callOrThrow<ProductStats>('sqlite:getProductStats'),
      ]);
      this.products.set(products);
      this.stats.set(stats);
      this.filterProducts();
    } catch (error) {
      this.logger.error('Failed to load products', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  resetForm(): void {
    this.isEditMode.set(false);
    this.editingProduct.set({ name: '', category: '', price: 0, stock: 0 });
  }

  async saveProduct(): Promise<void> {
    if (!this.editingProduct().name || !this.editingProduct().category) {
      this.logger.warn('Save product validation failed');
      return;
    }

    this.isLoading.set(true);
    try {
      if (this.isEditMode()) {
        await this.api.callOrThrow('sqlite:updateProduct', [this.editingProduct()]);
        this.logger.info('Product updated successfully');
      } else {
        await this.api.callOrThrow('sqlite:createProduct', [this.editingProduct()]);
        this.logger.info('Product created successfully');
      }
      this.resetForm();
      this.setActiveTab('list');
    } catch (error) {
      this.logger.error('Failed to save product', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  editProduct(product: Product): void {
    this.editingProduct.set({ ...product });
    this.isEditMode.set(true);
    this.setActiveTab('create');
  }

  async deleteProduct(product: Product): Promise<void> {
    if (!confirm(`Delete ${product.name}?`)) {
      return;
    }

    this.isLoading.set(true);
    try {
      await this.api.callOrThrow('sqlite:deleteProduct', [product.id]);
      this.logger.info('Product deleted');
      await this.loadProducts();
    } catch (error) {
      this.logger.error('Failed to delete product', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  cancelEdit(): void {
    this.resetForm();
    this.setActiveTab('list');
  }

  ngOnInit(): void {
    this.loadProducts();
  }
}
