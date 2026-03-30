/**
 * Database Analytics Charts Component
 * 
 * Visualizes data from DuckDB and SQLite databases
 */

import { Component, signal, inject, OnInit, AfterViewInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { VegaChartsService } from '../../app/services/vega-charts.service';
import { LoggerService } from '../../core/logger.service';
import { ApiService } from '../../core/api.service';

export interface UserStats {
  total_users: number;
  today_count: number;
  unique_domains: number;
  avg_age: number;
}

export interface ProductStats {
  total_products: number;
  total_value: number;
  categories_count: number;
  low_stock_count: number;
}

@Component({
  selector: 'app-db-analytics-charts',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="db-analytics">
      <!-- Header -->
      <header class="analytics-header">
        <div class="header-content">
          <h1 class="analytics-title">📊 Database Analytics</h1>
          <p class="analytics-subtitle">Real-time insights from DuckDB & SQLite</p>
        </div>
        <button class="refresh-btn" (click)="refreshData()" [disabled]="isLoading()">
          <span class="refresh-icon">{{ isLoading() ? '⏳' : '🔄' }}</span>
          <span>Refresh</span>
        </button>
      </header>

      <!-- Stats Overview -->
      <div class="stats-overview">
        <div class="stat-card stat-primary">
          <div class="stat-icon">👥</div>
          <div class="stat-content">
            <div class="stat-value">{{ userStats().total_users }}</div>
            <div class="stat-label">Total Users</div>
          </div>
        </div>
        <div class="stat-card stat-success">
          <div class="stat-icon">📦</div>
          <div class="stat-content">
            <div class="stat-value">{{ productStats().total_products }}</div>
            <div class="stat-label">Total Products</div>
          </div>
        </div>
        <div class="stat-card stat-info">
          <div class="stat-icon">💰</div>
          <div class="stat-content">
            <div class="stat-value">\${{ productStats().total_value | number:'1.0-2' }}</div>
            <div class="stat-label">Inventory Value</div>
          </div>
        </div>
        <div class="stat-card stat-warning">
          <div class="stat-icon">📊</div>
          <div class="stat-content">
            <div class="stat-value">{{ userStats().avg_age }}</div>
            <div class="stat-label">Avg User Age</div>
          </div>
        </div>
      </div>

      <!-- Charts Grid -->
      <div class="charts-grid">
        <!-- User Distribution -->
        <div class="chart-card chart-card--large">
          <div class="chart-card-header">
            <h3>👥 User Age Distribution</h3>
            <p>Histogram showing user age groups</p>
          </div>
          <div class="chart-card-content">
            <div id="user-age-histogram" class="chart-container"></div>
          </div>
        </div>

        <!-- Category Distribution -->
        <div class="chart-card">
          <div class="chart-card-header">
            <h3>📦 Products by Category</h3>
            <p>Bar chart of product categories</p>
          </div>
          <div class="chart-card-content">
            <div id="category-bar" class="chart-container"></div>
          </div>
        </div>

        <!-- Stock Status -->
        <div class="chart-card">
          <div class="chart-card-header">
            <h3>📊 Stock Status</h3>
            <p>Donut chart of inventory status</p>
          </div>
          <div class="chart-card-content">
            <div id="stock-pie" class="chart-container"></div>
          </div>
        </div>
      </div>

      <!-- Data Tables -->
      <div class="data-section">
        <h2>📋 Detailed Statistics</h2>
        <div class="tables-grid">
          <div class="table-card">
            <h3>User Demographics</h3>
            <table class="data-table">
              <thead>
                <tr>
                  <th>Metric</th>
                  <th>Value</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Total Users</td>
                  <td>{{ userStats().total_users }}</td>
                </tr>
                <tr>
                  <td>New Today</td>
                  <td>{{ userStats().today_count }}</td>
                </tr>
                <tr>
                  <td>Average Age</td>
                  <td>{{ userStats().avg_age }}</td>
                </tr>
                <tr>
                  <td>Email Domains</td>
                  <td>{{ userStats().unique_domains }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="table-card">
            <h3>Inventory Summary</h3>
            <table class="data-table">
              <thead>
                <tr>
                  <th>Metric</th>
                  <th>Value</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Total Products</td>
                  <td>{{ productStats().total_products }}</td>
                </tr>
                <tr>
                  <td>Total Value</td>
                  <td>\${{ productStats().total_value | number:'1.0-2' }}</td>
                </tr>
                <tr>
                  <td>Categories</td>
                  <td>{{ productStats().categories_count }}</td>
                </tr>
                <tr>
                  <td>Low Stock</td>
                  <td>{{ productStats().low_stock_count }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .db-analytics {
      min-height: 100vh;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      padding: 0;
    }

    .analytics-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 32px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .analytics-title {
      font-size: 28px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0 0 8px;
    }

    .analytics-subtitle {
      font-size: 14px;
      color: #94a3b8;
      margin: 0;
    }

    .refresh-btn {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 24px;
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: white;
      border: none;
      border-radius: 10px;
      cursor: pointer;
      font-weight: 600;
      transition: all 0.2s;
    }

    .refresh-btn:hover:not(:disabled) {
      transform: translateY(-2px);
      box-shadow: 0 8px 20px rgba(6, 182, 212, 0.4);
    }

    .refresh-btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .stats-overview {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      padding: 32px;
    }

    .stat-card {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 24px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
    }

    .stat-icon {
      font-size: 36px;
    }

    .stat-content {
      display: flex;
      flex-direction: column;
    }

    .stat-value {
      font-size: 28px;
      font-weight: 700;
      color: #f8fafc;
    }

    .stat-label {
      font-size: 13px;
      color: #64748b;
      margin-top: 4px;
    }

    .stat-primary .stat-icon { color: #3b82f6; }
    .stat-success .stat-icon { color: #10b981; }
    .stat-info .stat-icon { color: #06b6d4; }
    .stat-warning .stat-icon { color: #f59e0b; }

    .charts-grid {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr;
      gap: 24px;
      padding: 32px;
    }

    .chart-card {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .chart-card--large {
      grid-column: span 2;
    }

    .chart-card-header {
      padding: 20px 24px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .chart-card-header h3 {
      font-size: 16px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0 0 4px;
    }

    .chart-card-header p {
      font-size: 13px;
      color: #64748b;
      margin: 0;
    }

    .chart-card-content {
      padding: 24px;
    }

    .chart-container {
      min-height: 300px;
    }

    .data-section {
      padding: 32px;
    }

    .data-section h2 {
      font-size: 20px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0 0 24px;
    }

    .tables-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 24px;
    }

    .table-card {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      overflow: hidden;
    }

    .table-card h3 {
      font-size: 16px;
      font-weight: 600;
      color: #f8fafc;
      padding: 20px 24px;
      margin: 0;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .data-table {
      width: 100%;
      border-collapse: collapse;
    }

    .data-table td {
      padding: 14px 24px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      font-size: 14px;
    }

    .data-table td:first-child {
      color: #94a3b8;
    }

    .data-table td:last-child {
      color: #f8fafc;
      font-weight: 600;
      text-align: right;
    }

    @media (max-width: 1200px) {
      .stats-overview {
        grid-template-columns: repeat(2, 1fr);
      }

      .charts-grid {
        grid-template-columns: 1fr;
      }

      .chart-card--large {
        grid-column: span 1;
      }
    }

    @media (max-width: 768px) {
      .stats-overview {
        grid-template-columns: 1fr;
      }

      .tables-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class DbAnalyticsChartsComponent implements OnInit, AfterViewInit, OnDestroy {
  private readonly chartsService = inject(VegaChartsService);
  private readonly logger = inject(LoggerService);
  private readonly api = inject(ApiService);

  isLoading = signal(false);
  userStats = signal<UserStats>({ total_users: 0, today_count: 0, unique_domains: 0, avg_age: 0 });
  productStats = signal<ProductStats>({ total_products: 0, total_value: 0, categories_count: 0, low_stock_count: 0 });

  usersData: any[] = [];
  productsData: any[] = [];

  ngOnInit(): void {
    this.loadData();
  }

  ngAfterViewInit(): void {
    this.renderCharts();
  }

  ngOnDestroy(): void {
    this.chartsService.destroyAll();
  }

  async loadData(): Promise<void> {
    this.isLoading.set(true);
    try {
      // Load users
      const users = await this.api.callOrThrow<any[]>('getUsers');
      this.usersData = users;
      
      // Load products
      const products = await this.api.callOrThrow<any[]>('sqlite:getProducts');
      this.productsData = products;

      // Calculate stats
      this.userStats.set({
        total_users: users.length,
        today_count: users.filter((u: any) => {
          const created = new Date(u.created_at);
          const today = new Date();
          return created.toDateString() === today.toDateString();
        }).length,
        unique_domains: new Set(users.map((u: any) => u.email.split('@')[1])).size,
        avg_age: Math.round(users.reduce((sum: number, u: any) => sum + u.age, 0) / users.length) || 0,
      });

      this.productStats.set({
        total_products: products.length,
        total_value: products.reduce((sum: number, p: any) => sum + (p.price * p.stock), 0),
        categories_count: new Set(products.map((p: any) => p.category)).size,
        low_stock_count: products.filter((p: any) => p.stock < 10).length,
      });

      this.logger.info('Analytics data loaded');
    } catch (error) {
      this.logger.error('Failed to load analytics data', error);
    } finally {
      this.isLoading.set(false);
    }
  }

  async renderCharts(): Promise<void> {
    try {
      // User Age Histogram
      const ageHistSpec = this.chartsService.createHistogram(
        this.usersData.map((u: any) => ({ age: u.age })),
        'age',
        'User Age Distribution'
      );
      await this.chartsService.renderChart('user-age-histogram', ageHistSpec);

      // Category Bar Chart
      const categoryData = this.productsData.reduce((acc: any, p: any) => {
        acc[p.category] = (acc[p.category] || 0) + 1;
        return acc;
      }, {});
      
      const categoryBarSpec = this.chartsService.createBarChart(
        Object.entries(categoryData).map(([category, count]) => ({ category, count })),
        'category',
        'count',
        'Products by Category'
      );
      await this.chartsService.renderChart('category-bar', categoryBarSpec);

      // Stock Status Pie Chart
      const stockStatus = {
        'In Stock': this.productsData.filter((p: any) => p.stock >= 10).length,
        'Low Stock': this.productsData.filter((p: any) => p.stock > 0 && p.stock < 10).length,
        'Out of Stock': this.productsData.filter((p: any) => p.stock === 0).length,
      };

      const stockPieSpec = this.chartsService.createPieChart(
        Object.entries(stockStatus).map(([status, count]) => ({ status, count })),
        'status',
        'count',
        'Stock Status',
        true
      );
      await this.chartsService.renderChart('stock-pie', stockPieSpec);

      this.logger.info('Charts rendered successfully');
    } catch (error) {
      this.logger.error('Failed to render charts', error);
    }
  }

  async refreshData(): Promise<void> {
    await this.loadData();
    setTimeout(() => this.renderCharts(), 100);
  }
}
