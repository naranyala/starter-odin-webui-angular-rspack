import { Injectable, signal } from '@angular/core';

export interface DevTool {
  id: string;
  name: string;
  enabled: boolean;
  icon?: string;
}

@Injectable({
  providedIn: 'root'
})
export class DevtoolsService {
  private tools = signal<DevTool[]>([
    { id: 'console', name: 'Console', enabled: true, icon: '📝' },
    { id: 'network', name: 'Network', enabled: true, icon: '🌐' },
    { id: 'storage', name: 'Storage', enabled: true, icon: '💾' },
    { id: 'perf', name: 'Performance', enabled: true, icon: '⚡' },
  ]);

  readonly tools$ = this.tools.asReadonly();

  init(): void {
    // Initialization logic
  }

  dispose(): void {
    // Cleanup logic
  }

  isEnabled(toolId: string): boolean {
    return this.tools().find(t => t.id === toolId)?.enabled ?? false;
  }

  toggleTool(toolId: string): void {
    this.tools.update(tools => 
      tools.map(t => t.id === toolId ? { ...t, enabled: !t.enabled } : t)
    );
  }

  enableTool(toolId: string): void {
    this.tools.update(tools =>
      tools.map(t => t.id === toolId ? { ...t, enabled: true } : t)
    );
  }

  disableTool(toolId: string): void {
    this.tools.update(tools =>
      tools.map(t => t.id === toolId ? { ...t, enabled: false } : t)
    );
  }

  getEnabledTools(): DevTool[] {
    return this.tools().filter(t => t.enabled);
  }

  recordMetric(name: string, value: number): void {
    // Mock implementation
  }

  reportError(error: Error | string): void {
    // Mock implementation
  }

  getMetrics(): Record<string, number> {
    return {};
  }

  getErrors(): any[] {
    return [];
  }

  log(message: string): void {
    // Mock implementation
  }
}
