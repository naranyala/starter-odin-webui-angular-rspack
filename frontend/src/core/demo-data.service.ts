/**
 * Demo Data Service
 * 
 * Shared service for managing in-memory demo data
 * Used by SQLite and DuckDB components for demonstration purposes
 */

import { Injectable, signal, inject } from '@angular/core';
import { LoggerService } from './logger.service';
import { DummyDataGeneratorService, User, Product, Order } from './dummy-data-generator.service';

// Re-export types for convenience
export { User, Product, Order };

export type DatabaseType = 'sqlite' | 'duckdb';

export interface UserStats {
  total_users: number;
  today_count: number;
  unique_domains: number;
}

@Injectable({ providedIn: 'root' })
export class DemoDataService {
  private readonly logger = inject(LoggerService);
  private readonly dummyDataGenerator = inject(DummyDataGeneratorService);

  // Database type
  private readonly databaseType = signal<DatabaseType>('duckdb');

  // In-memory data stores
  private readonly sqliteData = signal<{
    users: User[];
    initialized: boolean;
  }>({
    users: [],
    initialized: false,
  });

  private readonly duckdbData = signal<{
    users: User[];
    products: Product[];
    orders: Order[];
    initialized: boolean;
  }>({
    users: [],
    products: [],
    orders: [],
    initialized: false,
  });

  // Public readonly signals
  readonly databaseType$ = this.databaseType.asReadonly();

  constructor() {
    this.logger.info('DemoDataService initialized');
  }

  /**
   * Set database type
   */
  setDatabaseType(type: DatabaseType): void {
    this.databaseType.set(type);
  }

  /**
   * Get current database type
   */
  getDatabaseType(): DatabaseType {
    return this.databaseType();
  }

  /**
   * Initialize demo data for both databases
   */
  initialize(): void {
    this.logger.info('Initializing demo data...');

    // Initialize SQLite data
    const sqliteUsers = this.dummyDataGenerator.generateSqliteUsers();
    this.sqliteData.set({
      users: sqliteUsers,
      initialized: true,
    });

    // Initialize DuckDB data
    const duckdbData = this.dummyDataGenerator.generateDuckdbData();
    this.duckdbData.set({
      ...duckdbData,
      initialized: true,
    });

    this.logger.info('Demo data initialized', {
      sqliteUsers: sqliteUsers.length,
      duckdbUsers: duckdbData.users.length,
      duckdbProducts: duckdbData.products.length,
      duckdbOrders: duckdbData.orders.length,
    });
  }

  /**
   * Get users for current database
   */
  getUsers(): User[] {
    if (this.databaseType() === 'sqlite') {
      return this.sqliteData().users;
    }
    return this.duckdbData().users;
  }

  /**
   * Get products (DuckDB only)
   */
  getProducts(): Product[] {
    return this.duckdbData().products;
  }

  /**
   * Get orders (DuckDB only)
   */
  getOrders(): Order[] {
    return this.duckdbData().orders;
  }

  /**
   * Get all users with stats
   */
  getUserStats(): { total_users: number; today_count: number; unique_domains: number } {
    const users = this.getUsers();
    const today = new Date().toDateString();
    const todayCount = users.filter(u => new Date(u.created_at).toDateString() === today).length;
    const domains = new Set(users.map(u => u.email.split('@')[1]));
    return {
      total_users: users.length,
      today_count: todayCount,
      unique_domains: domains.size,
    };
  }

  /**
   * Create a new user
   */
  createUser(userData: Partial<User>): User {
    const users = this.databaseType() === 'sqlite' ? this.sqliteData().users : this.duckdbData().users;
    
    const newUser: User = {
      id: Math.max(0, ...users.map(u => u.id)) + 1,
      name: userData.name || 'Unknown',
      email: userData.email || 'unknown@example.com',
      age: userData.age || 25,
      status: 'active',
      created_at: new Date().toISOString(),
    };

    if (this.databaseType() === 'sqlite') {
      this.sqliteData.update(data => ({
        ...data,
        users: [...data.users, newUser],
      }));
    } else {
      this.duckdbData.update(data => ({
        ...data,
        users: [...data.users, newUser],
      }));
    }

    this.logger.info('User created', newUser);
    return newUser;
  }

  /**
   * Update a user
   */
  updateUser(id: number, userData: Partial<User>): User | null {
    const updateInData = (users: User[]): User[] => {
      return users.map(u => u.id === id ? { ...u, ...userData } : u);
    };

    let updatedUser: User | null = null;

    if (this.databaseType() === 'sqlite') {
      const users = this.sqliteData().users;
      updatedUser = users.find(u => u.id === id) || null;
      if (updatedUser) {
        this.sqliteData.update(data => ({
          ...data,
          users: updateInData(users),
        }));
      }
    } else {
      const users = this.duckdbData().users;
      updatedUser = users.find(u => u.id === id) || null;
      if (updatedUser) {
        this.duckdbData.update(data => ({
          ...data,
          users: updateInData(users),
        }));
      }
    }

    if (updatedUser) {
      this.logger.info('User updated', { id, ...userData });
    }
    return updatedUser;
  }

  /**
   * Delete a user
   */
  deleteUser(id: number): boolean {
    const deleteFromData = (users: User[]): User[] => {
      return users.filter(u => u.id !== id);
    };

    let deleted = false;

    if (this.databaseType() === 'sqlite') {
      const users = this.sqliteData().users;
      if (users.some(u => u.id === id)) {
        this.sqliteData.update(data => ({
          ...data,
          users: deleteFromData(users),
        }));
        deleted = true;
      }
    } else {
      const users = this.duckdbData().users;
      if (users.some(u => u.id === id)) {
        this.duckdbData.update(data => ({
          ...data,
          users: deleteFromData(users),
        }));
        deleted = true;
      }
    }

    if (deleted) {
      this.logger.info('User deleted', id);
    }
    return deleted;
  }

  /**
   * Create a product (DuckDB only)
   */
  createProduct(productData: Partial<Product>): Product {
    const products = this.duckdbData().products;
    
    const newProduct: Product = {
      id: Math.max(0, ...products.map(p => p.id)) + 1,
      name: productData.name || 'Unknown Product',
      description: productData.description || 'No description',
      price: productData.price || 0,
      stock: productData.stock || 0,
      category: productData.category || 'General',
      created_at: new Date().toISOString(),
    };

    this.duckdbData.update(data => ({
      ...data,
      products: [...data.products, newProduct],
    }));

    this.logger.info('Product created', newProduct);
    return newProduct;
  }

  /**
   * Create an order (DuckDB only)
   */
  createOrder(orderData: Partial<Order>): Order {
    const orders = this.duckdbData().orders;
    
    const newOrder: Order = {
      id: Math.max(0, ...orders.map(o => o.id)) + 1,
      customer_name: orderData.customer_name || 'Unknown',
      customer_email: orderData.customer_email || 'unknown@example.com',
      product_name: orderData.product_name || 'Unknown Product',
      quantity: orderData.quantity || 1,
      total: orderData.total || 0,
      status: orderData.status || 'pending',
      created_at: new Date().toISOString(),
    };

    this.duckdbData.update(data => ({
      ...data,
      orders: [...data.orders, newOrder],
    }));

    this.logger.info('Order created', newOrder);
    return newOrder;
  }

  /**
   * Reset all data
   */
  reset(): void {
    this.dummyDataGenerator.reset();
    this.initialize();
    this.logger.info('Demo data reset');
  }

  /**
   * Add more seed data
   */
  addSeedData(userCount: number = 10, productCount: number = 15, orderCount: number = 20): void {
    if (this.databaseType() === 'sqlite') {
      const newUsers = this.dummyDataGenerator.generateUsers(userCount);
      this.sqliteData.update(data => ({
        ...data,
        users: [...data.users, ...newUsers],
      }));
      this.logger.info(`Added ${userCount} users to SQLite`);
    } else {
      const newUsers = this.dummyDataGenerator.generateUsers(userCount);
      const newProducts = this.dummyDataGenerator.generateProducts(productCount);
      const newOrders = this.dummyDataGenerator.generateOrders(orderCount);
      
      this.duckdbData.update(data => ({
        ...data,
        users: [...data.users, ...newUsers],
        products: [...data.products, ...newProducts],
        orders: [...data.orders, ...newOrders],
      }));
      this.logger.info(`Added seed data to DuckDB: ${userCount} users, ${productCount} products, ${orderCount} orders`);
    }
  }
}
