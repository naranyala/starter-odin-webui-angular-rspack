/**
 * Database Mode Service
 * Manages switching between SQLite and DuckDB modes
 */

import { Injectable, signal, computed } from '@angular/core';
import { LoggerService } from './logger.service';

export type DatabaseMode = 'sqlite' | 'duckdb';

export interface DatabaseModeInfo {
  id: DatabaseMode;
  name: string;
  icon: string;
  description: string;
  color: string;
}

@Injectable({
  providedIn: 'root'
})
export class DatabaseModeService {
  private readonly STORAGE_KEY = 'app_database_mode';

  private readonly modes: DatabaseModeInfo[] = [
    {
      id: 'sqlite',
      name: 'SQLite',
      icon: '🗄️',
      description: 'Lightweight embedded SQL database',
      color: '#003b57'
    },
    {
      id: 'duckdb',
      name: 'DuckDB',
      icon: '🦆',
      description: 'Analytical database for data science',
      color: '#06b6d4'
    }
  ];

  currentMode = signal<DatabaseMode>('sqlite');
  
  modeInfo = computed(() => {
    return this.modes.find(m => m.id === this.currentMode()) || this.modes[0];
  });

  availableModes = signal<DatabaseModeInfo[]>(this.modes);

  constructor(
    private logger: LoggerService
  ) {
    this.loadSavedMode();
  }

  private loadSavedMode(): void {
    const saved = localStorage.getItem(this.STORAGE_KEY) as DatabaseMode | null;
    if (saved && this.modes.some(m => m.id === saved)) {
      this.currentMode.set(saved);
      this.logger.info(`Loaded saved database mode: ${saved}`);
    }
  }

  setMode(mode: DatabaseMode): void {
    if (this.currentMode() === mode) return;
    
    this.currentMode.set(mode);
    localStorage.setItem(this.STORAGE_KEY, mode);
    this.logger.info(`Switched database mode to: ${mode}`);
    
    // Dispatch event for components to react
    window.dispatchEvent(new CustomEvent('database-mode-changed', { 
      detail: { mode } 
    }));
  }

  toggleMode(): void {
    const newMode = this.currentMode() === 'sqlite' ? 'duckdb' : 'sqlite';
    this.setMode(newMode);
  }

  isSqlite(): boolean {
    return this.currentMode() === 'sqlite';
  }

  isDuckdb(): boolean {
    return this.currentMode() === 'duckdb';
  }

  getModeColor(): string {
    return this.modeInfo().color;
  }
}
