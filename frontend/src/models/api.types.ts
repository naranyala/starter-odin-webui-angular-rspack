/**
 * Shared API Types
 * Contract between Frontend (Angular) and Backend (Odin)
 * 
 * These interfaces define the expected data structure for all API calls.
 * Backend handlers must return data matching these interfaces.
 */

import { User, Product, Order, DashboardStats, UserStats } from './dashboard.model';

// ============================================================================
// API Request/Response Types
// ============================================================================

export interface ApiRequest<T = unknown> {
  function: string;
  args: T[];
  timestamp: number;
  requestId: string;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: number;
}

// ============================================================================
// API Endpoints
// ============================================================================

export interface ApiEndpoints {
  // User endpoints
  getUsers: {
    request: [];
    response: User[];
  };
  createUser: {
    request: [Omit<User, 'id' | 'created_at'>];
    response: User;
  };
  updateUser: {
    request: [number, Partial<User>];
    response: { success: boolean; message: string };
  };
  deleteUser: {
    request: [number];
    response: { success: boolean; message: string };
  };
  getUserStats: {
    request: [];
    response: UserStats;
  };
  
  // Product endpoints
  getProducts: {
    request: [];
    response: Product[];
  };
  createProduct: {
    request: [Omit<Product, 'id' | 'created_at'>];
    response: Product;
  };
  updateProduct: {
    request: [number, Partial<Product>];
    response: { success: boolean; message: string };
  };
  deleteProduct: {
    request: [number];
    response: { success: boolean; message: string };
  };
  
  // Order endpoints
  getOrders: {
    request: [];
    response: Order[];
  };
  createOrder: {
    request: [Omit<Order, 'id' | 'created_at'>];
    response: Order;
  };
  updateOrder: {
    request: [number, Partial<Order>];
    response: { success: boolean; message: string };
  };
  deleteOrder: {
    request: [number];
    response: { success: boolean; message: string };
  };
  
  // Stats endpoints
  getDashboardStats: {
    request: [];
    response: DashboardStats;
  };
  
  // Utility endpoints
  echo: {
    request: [unknown];
    response: { received: unknown; timestamp: string };
  };
  validationTest: {
    request: [];
    response: never; // Always returns error
  };
}

// ============================================================================
// Typed API Helper
// ============================================================================

export type EndpointName = keyof ApiEndpoints;

export type EndpointRequest<T extends EndpointName> = ApiEndpoints[T]['request'];
export type EndpointResponse<T extends EndpointName> = ApiEndpoints[T]['response'];

// ============================================================================
// Event Types
// ============================================================================

export interface BackendEvent {
  event: string;
  data: unknown;
  timestamp: number;
}

export interface StateUpdate {
  key: string;
  value: unknown;
  version: number;
}

// ============================================================================
// Error Types
// ============================================================================

export interface ApiError {
  code: number;
  message: string;
  details?: string[];
  timestamp: number;
}

export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

// ============================================================================
// WebSocket Message Types
// ============================================================================

export type WebSocketMessageType = 
  | 'request'
  | 'response' 
  | 'event'
  | 'state-update'
  | 'broadcast'
  | 'error';

export interface WebSocketMessage {
  id: string;
  type: WebSocketMessageType;
  channel?: string;
  payload: unknown;
  timestamp: number;
  source: 'frontend' | 'backend';
}