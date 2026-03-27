/**
 * Database Selector Service
 * 
 * Manages switching between SQLite and DuckDB databases
 * Tracks current database type and provides database-specific configurations
 */

import { Injectable, signal, computed, inject } from '@angular/core';
import { LoggerService } from './logger.service';

export type DatabaseType = 'sqlite' | 'duckdb';

export interface DatabaseConfig {
  type: DatabaseType;
  name: string;
  icon: string;
  color: string;
  description: string;
  features: string[];
}

export interface DatabaseStats {
  users: number;
  products: number;
  orders: number;
  lastSync?: number;
}

const DATABASE_CONFIGS: Record<DatabaseType, DatabaseConfig> = {
  sqlite: {
    type: 'sqlite',
    name: 'SQLite',
    icon: '🗄️',
    color: '#00b09b',
    description: 'Lightweight relational database',
    features: ['ACID compliant', 'Zero configuration', 'Embedded', 'Cross-platform'],
  },
  duckdb: {
    type: 'duckdb',
    name: 'DuckDB',
    icon: '🦆',
    color: '#00b4d8',
    description: 'Analytical columnar database',
    features: ['Columnar storage', 'OLAP queries', 'Fast analytics', 'SQL support'],
  },
};

@Injectable({ providedIn: 'root' })
export class DatabaseSelectorService {
  private readonly logger = inject(LoggerService);

  // Current database selection
  private readonly currentDb = signal<DatabaseType>('duckdb');
  
  // Database stats per type
  private readonly stats = signal<Record<DatabaseType, DatabaseStats>>({
    sqlite: { users: 0, products: 0, orders: 0 },
    duckdb: { users: 0, products: 0, orders: 0 },
  });

  // Is database switching in progress
  private readonly isSwitching = signal(false);

  // Public readonly signals
  readonly currentDb$ = this.currentDb.asReadonly();
  readonly stats$ = this.stats.asReadonly();
  readonly isSwitching$ = this.isSwitching.asReadonly();

  // Computed current config
  readonly currentConfig = computed(() => DATABASE_CONFIGS[this.currentDb()]);
  
  // Computed current stats
  readonly currentStats = computed(() => this.stats()[this.currentDb()]);

  // Available databases
  readonly availableDatabases = computed(() => 
    Object.values(DATABASE_CONFIGS)
  );

  constructor() {
    this.logger.info('DatabaseSelectorService initialized');
  }

  /**
   * Get current database type
   */
  getCurrentDatabase(): DatabaseType {
    return this.currentDb();
  }

  /**
   * Get database configuration
   */
  getDatabaseConfig(type: DatabaseType): DatabaseConfig {
    return DATABASE_CONFIGS[type];
  }

  /**
   * Switch to a different database
   */
  async switchDatabase(type: DatabaseType): Promise<void> {
    if (this.currentDb() === type) {
      this.logger.debug('Already using', type);
      return;
    }

    this.isSwitching.set(true);
    this.logger.info('Switching database to', type);

    try {
      // Simulate async operation (in future, call backend to switch)
      await new Promise(resolve => setTimeout(resolve, 500));
      
      this.currentDb.set(type);
      this.logger.info('Database switched to ' + type);
      
      // Emit event for components to refresh
      this.emitDatabaseChange(type);
    } catch (error) {
      this.logger.error('Failed to switch database', error);
      throw error;
    } finally {
      this.isSwitching.set(false);
    }
  }

  /**
   * Update stats for current database
   */
  updateStats(stats: Partial<DatabaseStats>): void {
    this.stats.update(current => ({
      ...current,
      [this.currentDb()]: {
        ...current[this.currentDb()],
        ...stats,
        lastSync: Date.now(),
      },
    }));
  }

  /**
   * Reset stats for all databases
   */
  resetStats(): void {
    this.stats.set({
      sqlite: { users: 0, products: 0, orders: 0 },
      duckdb: { users: 0, products: 0, orders: 0 },
    });
  }

  /**
   * Toggle between SQLite and DuckDB
   */
  async toggleDatabase(): Promise<void> {
    const next = this.currentDb() === 'sqlite' ? 'duckdb' : 'sqlite';
    await this.switchDatabase(next);
  }

  /**
   * Check if current database is SQLite
   */
  isSqlite(): boolean {
    return this.currentDb() === 'sqlite';
  }

  /**
   * Check if current database is DuckDB
   */
  isDuckdb(): boolean {
    return this.currentDb() === 'duckdb';
  }

  /**
   * Emit database change event
   */
  private emitDatabaseChange(type: DatabaseType): void {
    const event = new CustomEvent('database-change', {
      detail: { database: type, config: DATABASE_CONFIGS[type] },
    });
    window.dispatchEvent(event);
  }
}
