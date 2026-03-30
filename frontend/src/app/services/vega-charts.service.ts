/**
 * Vega Charts Service
 * 
 * Provides chart creation and rendering using Vega-Lite
 */

import { Injectable, signal } from '@angular/core';
import embed, { Result } from 'vega-embed';
import { TopLevelSpec } from 'vega-lite';

export interface ChartConfig {
  id: string;
  title: string;
  type: ChartType;
  spec: TopLevelSpec;
  data?: any[];
}

export type ChartType = 
  | 'bar' 
  | 'line' 
  | 'area' 
  | 'scatter' 
  | 'pie' 
  | 'donut'
  | 'histogram'
  | 'heatmap';

@Injectable({
  providedIn: 'root'
})
export class VegaChartsService {
  private readonly charts = signal<Map<string, Result>>(new Map());
  private readonly containerId = 'vega-chart-container';

  /**
   * Create a bar chart
   */
  createBarChart(data: any[], xField: string, yField: string, title: string): TopLevelSpec {
    return {
      $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
      title: {
        text: title,
        fontSize: 18,
        color: '#f8fafc',
        anchor: 'start',
      },
      data: { values: data },
      mark: { type: 'bar' },
      encoding: {
        x: { 
          field: xField, 
          type: 'nominal',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        y: { 
          field: yField, 
          type: 'quantitative',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        color: {
          field: xField,
          type: 'nominal',
          scale: {
            scheme: 'category10',
          },
          legend: null,
        },
      },
      config: {
        background: 'transparent',
        view: { stroke: null },
      },
    };
  }

  /**
   * Create a line chart
   */
  createLineChart(data: any[], xField: string, yField: string, title: string): TopLevelSpec {
    return {
      $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
      title: {
        text: title,
        fontSize: 18,
        color: '#f8fafc',
        anchor: 'start',
      },
      data: { values: data },
      mark: { type: 'line', strokeWidth: 3, point: true },
      encoding: {
        x: { 
          field: xField, 
          type: 'nominal',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        y: { 
          field: yField, 
          type: 'quantitative',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        color: {
          value: '#06b6d4',
        },
      },
      config: {
        background: 'transparent',
        view: { stroke: null },
      },
    };
  }

  /**
   * Create an area chart
   */
  createAreaChart(data: any[], xField: string, yField: string, title: string): TopLevelSpec {
    return {
      $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
      title: {
        text: title,
        fontSize: 18,
        color: '#f8fafc',
        anchor: 'start',
      },
      data: { values: data },
      mark: { type: 'area', line: true },
      encoding: {
        x: { 
          field: xField, 
          type: 'nominal',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        y: { 
          field: yField, 
          type: 'quantitative',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        color: {
          value: '#10b981',
        },
      },
      config: {
        background: 'transparent',
        view: { stroke: null },
      },
    };
  }

  /**
   * Create a scatter plot
   */
  createScatterPlot(
    data: any[], 
    xField: string, 
    yField: string, 
    title: string,
    colorField?: string
  ): TopLevelSpec {
    return {
      $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
      title: {
        text: title,
        fontSize: 18,
        color: '#f8fafc',
        anchor: 'start',
      },
      data: { values: data },
      mark: { type: 'point', filled: true, size: 100 },
      encoding: {
        x: { 
          field: xField, 
          type: 'quantitative',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        y: { 
          field: yField, 
          type: 'quantitative',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        color: colorField ? { field: colorField, type: 'nominal' } : { value: '#3b82f6' },
      },
      config: {
        background: 'transparent',
        view: { stroke: null },
      },
    };
  }

  /**
   * Create a pie/donut chart
   */
  createPieChart(data: any[], nameField: string, valueField: string, title: string, donut = false): TopLevelSpec {
    return {
      $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
      title: {
        text: title,
        fontSize: 18,
        color: '#f8fafc',
        anchor: 'start',
      },
      data: { values: data },
      mark: { type: 'arc', innerRadius: donut ? 80 : 0, stroke: '#1e293b', strokeWidth: 2 },
      encoding: {
        theta: {
          field: valueField,
          type: 'quantitative',
        },
        color: {
          field: nameField,
          type: 'nominal',
          scale: {
            scheme: 'category10',
          },
        },
      },
      config: {
        background: 'transparent',
        view: { stroke: null },
      },
    };
  }

  /**
   * Create a histogram
   */
  createHistogram(data: any[], field: string, title: string, binSize = 10): TopLevelSpec {
    return {
      $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
      title: {
        text: title,
        fontSize: 18,
        color: '#f8fafc',
        anchor: 'start',
      },
      data: { values: data },
      mark: 'bar',
      encoding: {
        x: {
          field: field,
          type: 'quantitative',
          bin: { maxbins: binSize },
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        y: {
          aggregate: 'count',
          title: 'Count',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        color: {
          value: '#8b5cf6',
        },
      },
      config: {
        background: 'transparent',
        view: { stroke: null },
      },
    };
  }

  /**
   * Create a heatmap
   */
  createHeatmap(
    data: any[], 
    xField: string, 
    yField: string, 
    valueField: string, 
    title: string
  ): TopLevelSpec {
    return {
      $schema: 'https://vega.github.io/schema/vega-lite/v5.json',
      title: {
        text: title,
        fontSize: 18,
        color: '#f8fafc',
        anchor: 'start',
      },
      data: { values: data },
      mark: 'rect',
      encoding: {
        x: { 
          field: xField, 
          type: 'nominal',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        y: { 
          field: yField, 
          type: 'nominal',
          axis: { 
            labelColor: '#94a3b8',
            titleColor: '#94a3b8',
          }
        },
        color: {
          field: valueField,
          type: 'quantitative',
          scale: { scheme: 'blues' },
        },
      },
      config: {
        background: 'transparent',
        view: { stroke: null },
      },
    };
  }

  /**
   * Render chart in container
   */
  async renderChart(containerId: string, spec: TopLevelSpec): Promise<Result> {
    try {
      const result = await embed(`#${containerId}`, spec, {
        actions: {
          export: true,
          source: false,
          compiled: false,
          editor: false,
        },
        theme: 'dark',
      });
      
      return result;
    } catch (error) {
      console.error('Failed to render chart:', error);
      throw error;
    }
  }

  /**
   * Create and render chart
   */
  async createAndRender(
    containerId: string,
    spec: TopLevelSpec
  ): Promise<Result> {
    return this.renderChart(containerId, spec);
  }

  /**
   * Get chart by ID
   */
  getChart(id: string): Result | undefined {
    return this.charts().get(id);
  }

  /**
   * Destroy chart
   */
  destroyChart(id: string): void {
    const chart = this.charts().get(id);
    if (chart) {
      chart.finalize();
      const chartsMap = new Map(this.charts());
      chartsMap.delete(id);
      this.charts.set(chartsMap);
    }
  }

  /**
   * Destroy all charts
   */
  destroyAll(): void {
    for (const chart of this.charts().values()) {
      chart.finalize();
    }
    this.charts.set(new Map());
  }
}
