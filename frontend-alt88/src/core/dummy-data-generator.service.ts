/**
 * Dummy Data Generator Service
 * 
 * Generates realistic mock data for SQLite and DuckDB demos
 * Provides seed data for users, products, and orders
 */

import { Injectable, inject } from '@angular/core';
import { LoggerService } from './logger.service';

export interface User {
  id: number;
  name: string;
  email: string;
  age: number;
  status: 'active' | 'inactive';
  created_at: string;
}

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  stock: number;
  category: string;
  created_at: string;
}

export interface Order {
  id: number;
  customer_name: string;
  customer_email: string;
  product_name: string;
  quantity: number;
  total: number;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  created_at: string;
}

// Sample data pools for generating realistic mock data
const FIRST_NAMES = [
  'James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda',
  'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica',
  'Thomas', 'Sarah', 'Charles', 'Karen', 'Christopher', 'Nancy', 'Daniel', 'Lisa',
  'Matthew', 'Betty', 'Anthony', 'Margaret', 'Mark', 'Sandra', 'Donald', 'Ashley',
  'Steven', 'Kimberly', 'Paul', 'Emily', 'Andrew', 'Donna', 'Joshua', 'Michelle',
  'Kenneth', 'Dorothy', 'Kevin', 'Carol', 'Brian', 'Amanda', 'George', 'Melissa',
  'Edward', 'Deborah', 'Ronald', 'Stephanie', 'Timothy', 'Rebecca', 'Jason', 'Sharon',
];

const LAST_NAMES = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
  'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
  'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson',
  'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker',
  'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
];

const EMAIL_DOMAINS = [
  'gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com', 'icloud.com',
  'protonmail.com', 'mail.com', 'zoho.com', 'aol.com', 'yandex.com',
];

const PRODUCT_CATEGORIES = [
  'Electronics', 'Clothing', 'Books', 'Home & Garden', 'Sports',
  'Toys & Games', 'Health & Beauty', 'Automotive', 'Food & Beverages', 'Office Supplies',
];

const PRODUCT_NAMES = {
  'Electronics': ['Laptop', 'Smartphone', 'Tablet', 'Headphones', 'Smart Watch', 'Camera', 'Speaker', 'Monitor'],
  'Clothing': ['T-Shirt', 'Jeans', 'Jacket', 'Sweater', 'Dress', 'Shorts', 'Coat', 'Sneakers'],
  'Books': ['Novel', 'Textbook', 'Cookbook', 'Biography', 'Science Fiction', 'Mystery', 'Self-Help', 'History'],
  'Home & Garden': ['Lamp', 'Chair', 'Table', 'Sofa', 'Plant Pot', 'Rug', 'Curtains', 'Mirror'],
  'Sports': ['Basketball', 'Tennis Racket', 'Yoga Mat', 'Dumbbells', 'Running Shoes', 'Bicycle', 'Football', 'Golf Club'],
  'Toys & Games': ['Board Game', 'Puzzle', 'Action Figure', 'Doll', 'Building Blocks', 'RC Car', 'Card Game', 'Plush Toy'],
  'Health & Beauty': ['Shampoo', 'Lotion', 'Makeup Kit', 'Perfume', 'Vitamins', 'Skincare Set', 'Hair Dryer', 'Electric Shaver'],
  'Automotive': ['Car Charger', 'Phone Mount', 'Air Freshener', 'Seat Covers', 'Floor Mats', 'Dash Cam', 'Tool Kit', 'Jump Starter'],
  'Food & Beverages': ['Coffee', 'Tea', 'Chocolate', 'Snack Box', 'Protein Bar', 'Juice', 'Cookies', 'Energy Drink'],
  'Office Supplies': ['Pen Set', 'Notebook', 'Stapler', 'Desk Organizer', 'Whiteboard', 'Calculator', 'Paper Clips', 'Tape Dispenser'],
};

const PRODUCT_ADJECTIVES = [
  'Premium', 'Deluxe', 'Professional', 'Ultra', 'Smart', 'Classic', 'Modern', 'Vintage',
  'Eco-Friendly', 'Wireless', 'Portable', 'Compact', 'Heavy-Duty', 'Lightweight', 'Advanced',
];

const ORDER_STATUSES: Array<'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'> = [
  'pending', 'processing', 'shipped', 'delivered', 'cancelled',
];

@Injectable({ providedIn: 'root' })
export class DummyDataGeneratorService {
  private readonly logger = inject(LoggerService);

  private userIdCounter = 1;
  private productIdCounter = 1;
  private orderIdCounter = 1;

  constructor() {
    this.logger.info('DummyDataGeneratorService initialized');
  }

  /**
   * Generate a random integer between min and max (inclusive)
   */
  private randomInt(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  /**
   * Generate a random item from an array
   */
  private randomChoice<T>(array: T[]): T {
    return array[this.randomInt(0, array.length - 1)];
  }

  /**
   * Generate a random date within the last N days
   */
  private randomDate(daysBack: number = 365): string {
    const now = new Date();
    const pastDate = new Date(now.getTime() - this.randomInt(0, daysBack) * 24 * 60 * 60 * 1000);
    return pastDate.toISOString();
  }

  /**
   * Generate a random email address
   */
  private generateEmail(firstName: string, lastName: string): string {
    const formats = [
      `${firstName.toLowerCase()}.${lastName.toLowerCase()}`,
      `${firstName.toLowerCase()}${lastName.toLowerCase()}`,
      `${firstName.toLowerCase()}${this.randomInt(1, 999)}`,
      `${lastName.toLowerCase()}.${this.randomInt(1, 999)}`,
    ];
    const domain = this.randomChoice(EMAIL_DOMAINS);
    return `${this.randomChoice(formats)}@${domain}`;
  }

  /**
   * Generate a single user
   */
  generateUser(override?: Partial<User>): User {
    const firstName = this.randomChoice(FIRST_NAMES);
    const lastName = this.randomChoice(LAST_NAMES);
    const name = `${firstName} ${lastName}`;

    return {
      id: this.userIdCounter++,
      name,
      email: override?.email || this.generateEmail(firstName, lastName),
      age: override?.age || this.randomInt(18, 80),
      status: override?.status || this.randomChoice(['active', 'active', 'active', 'inactive']), // 75% active
      created_at: override?.created_at || this.randomDate(365),
    };
  }

  /**
   * Generate multiple users
   */
  generateUsers(count: number = 10): User[] {
    const users: User[] = [];
    for (let i = 0; i < count; i++) {
      users.push(this.generateUser());
    }
    return users;
  }

  /**
   * Generate a single product
   */
  generateProduct(override?: Partial<Product>): Product {
    const category = override?.category || this.randomChoice(PRODUCT_CATEGORIES);
    const baseName = this.randomChoice(PRODUCT_NAMES[category as keyof typeof PRODUCT_NAMES]);
    const adjective = this.randomChoice(PRODUCT_ADJECTIVES);
    const name = `${adjective} ${baseName}`;

    return {
      id: this.productIdCounter++,
      name,
      description: override?.description || `High-quality ${name.toLowerCase()} in the ${category.toLowerCase()} category.`,
      price: override?.price || parseFloat((this.randomInt(10, 500) + Math.random()).toFixed(2)),
      stock: override?.stock || this.randomInt(0, 500),
      category,
      created_at: override?.created_at || this.randomDate(365),
    };
  }

  /**
   * Generate multiple products
   */
  generateProducts(count: number = 20): Product[] {
    const products: Product[] = [];
    for (let i = 0; i < count; i++) {
      products.push(this.generateProduct());
    }
    return products;
  }

  /**
   * Generate a single order
   */
  generateOrder(customerName?: string, customerEmail?: string, productName?: string, override?: Partial<Order>): Order {
    const name = customerName || `${this.randomChoice(FIRST_NAMES)} ${this.randomChoice(LAST_NAMES)}`;
    const email = customerEmail || this.generateEmail(name.split(' ')[0], name.split(' ')[1]);
    const product = productName || this.randomChoice(Object.values(PRODUCT_NAMES).flat());
    const quantity = override?.quantity || this.randomInt(1, 5);
    const unitPrice = override?.total ? override.total / quantity : this.randomInt(20, 300);
    const total = override?.total || parseFloat((unitPrice * quantity).toFixed(2));

    return {
      id: this.orderIdCounter++,
      customer_name: name,
      customer_email: email,
      product_name: `${this.randomChoice(PRODUCT_ADJECTIVES)} ${product}`,
      quantity,
      total,
      status: override?.status || this.randomChoice(ORDER_STATUSES),
      created_at: override?.created_at || this.randomDate(90),
    };
  }

  /**
   * Generate multiple orders
   */
  generateOrders(count: number = 30): Order[] {
    const orders: Order[] = [];
    for (let i = 0; i < count; i++) {
      orders.push(this.generateOrder());
    }
    return orders;
  }

  /**
   * Generate complete seed data for a database
   */
  generateSeedData(userCount: number = 15, productCount: number = 25, orderCount: number = 40): {
    users: User[];
    products: Product[];
    orders: Order[];
  } {
    this.logger.info(`Generating seed data: ${userCount} users, ${productCount} products, ${orderCount} orders`);
    
    // Reset counters
    this.userIdCounter = 1;
    this.productIdCounter = 1;
    this.orderIdCounter = 1;

    const users = this.generateUsers(userCount);
    const products = this.generateProducts(productCount);
    const orders = this.generateOrders(orderCount);

    this.logger.info('Seed data generated successfully');

    return { users, products, orders };
  }

  /**
   * Generate sample users specifically for SQLite demo
   */
  generateSqliteUsers(): User[] {
    this.userIdCounter = 1;
    return this.generateUsers(15).map(user => ({
      ...user,
      // SQLite demo uses simpler schema
      created_at: this.randomDate(180),
    }));
  }

  /**
   * Generate sample data specifically for DuckDB demo
   */
  generateDuckdbData(): { users: User[]; products: Product[]; orders: Order[] } {
    return this.generateSeedData(20, 30, 50);
  }

  /**
   * Reset all counters (useful for regenerating data)
   */
  reset(): void {
    this.userIdCounter = 1;
    this.productIdCounter = 1;
    this.orderIdCounter = 1;
    this.logger.debug('Dummy data generator reset');
  }
}
