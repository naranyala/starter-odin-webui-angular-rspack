/**
 * Vega Charts Demo Component
 * 
 * Showcases various chart types using Vega-Lite
 */

import { Component, signal, inject, OnInit, AfterViewInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { VegaChartsService, ChartConfig } from '../../app/services/vega-charts.service';
import { TopLevelSpec } from 'vega-lite';

@Component({
  selector: 'app-vega-charts-demo',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="charts-container">
      <!-- Header -->
      <header class="charts-header">
        <div class="header-content">
          <h1 class="charts-title">📊 Vega Charts Gallery</h1>
          <p class="charts-subtitle">Interactive data visualizations powered by Vega-Lite</p>
        </div>
      </header>

      <!-- Chart Type Selector -->
      <nav class="chart-tabs">
        @for (tab of chartTabs; track tab.id) {
          <button
            type="button"
            class="chart-tab"
            [class.active]="activeTab() === tab.id"
            (click)="setActiveTab(tab.id)"
          >
            <span class="tab-icon">{{ tab.icon }}</span>
            <span class="tab-label">{{ tab.label }}</span>
          </button>
        }
      </nav>

      <!-- Charts Grid -->
      <main class="charts-grid">
        @if (activeTab() === 'all' || activeTab() === 'bar') {
          <div class="chart-card">
            <div class="chart-card-header">
              <h3>📊 Sales by Category</h3>
              <p>Bar chart showing sales distribution</p>
            </div>
            <div class="chart-card-content">
              <div id="bar-chart-1" class="chart-container"></div>
            </div>
          </div>
        }

        @if (activeTab() === 'all' || activeTab() === 'line') {
          <div class="chart-card">
            <div class="chart-card-header">
              <h3>📈 Revenue Trend</h3>
              <p>Line chart showing revenue over time</p>
            </div>
            <div class="chart-card-content">
              <div id="line-chart-1" class="chart-container"></div>
            </div>
          </div>
        }

        @if (activeTab() === 'all' || activeTab() === 'area') {
          <div class="chart-card">
            <div class="chart-card-header">
              <h3>📉 User Growth</h3>
              <p>Area chart showing cumulative users</p>
            </div>
            <div class="chart-card-content">
              <div id="area-chart-1" class="chart-container"></div>
            </div>
          </div>
        }

        @if (activeTab() === 'all' || activeTab() === 'pie') {
          <div class="chart-card">
            <div class="chart-card-header">
              <h3>🥧 Market Share</h3>
              <p>Donut chart showing market distribution</p>
            </div>
            <div class="chart-card-content">
              <div id="pie-chart-1" class="chart-container"></div>
            </div>
          </div>
        }

        @if (activeTab() === 'all' || activeTab() === 'scatter') {
          <div class="chart-card">
            <div class="chart-card-header">
              <h3>⚡ Age vs Income</h3>
              <p>Scatter plot showing correlation</p>
            </div>
            <div class="chart-card-content">
              <div id="scatter-chart-1" class="chart-container"></div>
            </div>
          </div>
        }

        @if (activeTab() === 'all' || activeTab() === 'histogram') {
          <div class="chart-card">
            <div class="chart-card-header">
              <h3>📊 Age Distribution</h3>
              <p>Histogram showing age frequency</p>
            </div>
            <div class="chart-card-content">
              <div id="histogram-chart-1" class="chart-container"></div>
            </div>
          </div>
        }
      </main>
    </div>
  `,
  styles: [`
    .charts-container {
      min-height: 100vh;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      padding: 0;
    }

    .charts-header {
      padding: 40px 32px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .header-content h1 {
      font-size: 32px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0 0 8px;
    }

    .header-content p {
      font-size: 15px;
      color: #94a3b8;
      margin: 0;
    }

    .chart-tabs {
      display: flex;
      gap: 8px;
      padding: 16px 32px;
      background: rgba(15, 23, 42, 0.5);
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      overflow-x: auto;
    }

    .chart-tab {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 20px;
      background: transparent;
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 10px;
      color: #94a3b8;
      cursor: pointer;
      transition: all 0.2s;
      font-size: 14px;
      font-weight: 500;
      white-space: nowrap;
    }

    .chart-tab:hover {
      background: rgba(148, 163, 184, 0.1);
      border-color: rgba(148, 163, 184, 0.3);
    }

    .chart-tab.active {
      background: linear-gradient(135deg, #8b5cf6, #6366f1);
      border-color: transparent;
      color: white;
    }

    .tab-icon {
      font-size: 16px;
    }

    .charts-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(500px, 1fr));
      gap: 24px;
      padding: 32px;
    }

    .chart-card {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 16px;
      overflow: hidden;
      transition: all 0.3s;
    }

    .chart-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4);
      border-color: rgba(148, 163, 184, 0.2);
    }

    .chart-card-header {
      padding: 20px 24px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .chart-card-header h3 {
      font-size: 18px;
      font-weight: 600;
      color: #f8fafc;
      margin: 0 0 8px;
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
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .chart-container canvas,
    .chart-container svg {
      max-width: 100%;
    }

    @media (max-width: 768px) {
      .charts-grid {
        grid-template-columns: 1fr;
        padding: 16px;
      }

      .chart-tabs {
        padding: 12px 16px;
      }
    }
  `]
})
export class VegaChartsDemoComponent implements OnInit, AfterViewInit, OnDestroy {
  private readonly chartsService = inject(VegaChartsService);

  activeTab = signal<string>('all');
  
  chartTabs = [
    { id: 'all', icon: '🎨', label: 'All Charts' },
    { id: 'bar', icon: '📊', label: 'Bar' },
    { id: 'line', icon: '📈', label: 'Line' },
    { id: 'area', icon: '📉', label: 'Area' },
    { id: 'pie', icon: '🥧', label: 'Pie' },
    { id: 'scatter', icon: '⚡', label: 'Scatter' },
    { id: 'histogram', icon: '📊', label: 'Histogram' },
  ];

  // Sample data
  salesData = [
    { category: 'Electronics', sales: 45000 },
    { category: 'Clothing', sales: 32000 },
    { category: 'Home', sales: 28000 },
    { category: 'Books', sales: 15000 },
    { category: 'Sports', sales: 22000 },
    { category: 'Toys', sales: 18000 },
  ];

  revenueData = [
    { month: 'Jan', revenue: 12000 },
    { month: 'Feb', revenue: 18000 },
    { month: 'Mar', revenue: 15000 },
    { month: 'Apr', revenue: 22000 },
    { month: 'May', revenue: 28000 },
    { month: 'Jun', revenue: 35000 },
    { month: 'Jul', revenue: 42000 },
  ];

  userData = [
    { month: 'Jan', users: 1000 },
    { month: 'Feb', users: 1500 },
    { month: 'Mar', users: 2200 },
    { month: 'Apr', users: 3100 },
    { month: 'May', users: 4200 },
    { month: 'Jun', users: 5500 },
  ];

  marketData = [
    { company: 'Company A', share: 35 },
    { company: 'Company B', share: 25 },
    { company: 'Company C', share: 20 },
    { company: 'Company D', share: 12 },
    { company: 'Others', share: 8 },
  ];

  scatterData = Array.from({ length: 50 }, () => ({
    age: Math.floor(Math.random() * 40) + 20,
    income: Math.floor(Math.random() * 80000) + 30000,
  }));

  ageData = Array.from({ length: 100 }, () => ({
    age: Math.floor(Math.random() * 50) + 18,
  }));

  ngOnInit(): void {
    // Initialize data if needed
  }

  ngAfterViewInit(): void {
    this.renderAllCharts();
  }

  ngOnDestroy(): void {
    this.chartsService.destroyAll();
  }

  setActiveTab(tabId: string): void {
    this.activeTab.set(tabId);
    setTimeout(() => this.renderAllCharts(), 100);
  }

  async renderAllCharts(): Promise<void> {
    try {
      // Bar Chart
      if (this.activeTab() === 'all' || this.activeTab() === 'bar') {
        const barSpec = this.chartsService.createBarChart(
          this.salesData,
          'category',
          'sales',
          'Sales by Category'
        );
        await this.chartsService.renderChart('bar-chart-1', barSpec);
      }

      // Line Chart
      if (this.activeTab() === 'all' || this.activeTab() === 'line') {
        const lineSpec = this.chartsService.createLineChart(
          this.revenueData,
          'month',
          'revenue',
          'Revenue Trend'
        );
        await this.chartsService.renderChart('line-chart-1', lineSpec);
      }

      // Area Chart
      if (this.activeTab() === 'all' || this.activeTab() === 'area') {
        const areaSpec = this.chartsService.createAreaChart(
          this.userData,
          'month',
          'users',
          'User Growth'
        );
        await this.chartsService.renderChart('area-chart-1', areaSpec);
      }

      // Pie Chart
      if (this.activeTab() === 'all' || this.activeTab() === 'pie') {
        const pieSpec = this.chartsService.createPieChart(
          this.marketData,
          'company',
          'share',
          'Market Share',
          true // donut
        );
        await this.chartsService.renderChart('pie-chart-1', pieSpec);
      }

      // Scatter Plot
      if (this.activeTab() === 'all' || this.activeTab() === 'scatter') {
        const scatterSpec = this.chartsService.createScatterPlot(
          this.scatterData,
          'age',
          'income',
          'Age vs Income'
        );
        await this.chartsService.renderChart('scatter-chart-1', scatterSpec);
      }

      // Histogram
      if (this.activeTab() === 'all' || this.activeTab() === 'histogram') {
        const histSpec = this.chartsService.createHistogram(
          this.ageData,
          'age',
          'Age Distribution'
        );
        await this.chartsService.renderChart('histogram-chart-1', histSpec);
      }
    } catch (error) {
      console.error('Failed to render charts:', error);
    }
  }
}
