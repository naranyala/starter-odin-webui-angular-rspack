/**
 * Dashboard and Entity Models
 * Shared types between Frontend and Backend
 * 
 * NOTE: These types MUST match the backend Odin models in:
 * - src/handlers/webui_handlers.odin (User, Product, Order structs)
 */

/**
 * User model - MUST match backend User struct
 * Backend: src/handlers/webui_handlers.odin
 */
export interface User {
  id: number;
  name: string;
  email: string;
  role: 'User' | 'Admin' | 'Manager';
  status: 'Active' | 'Inactive' | 'Pending';
  created_at: string; // ISO 8601 date string
}

/**
 * Product model - MUST match backend Product struct
 * Backend: src/handlers/webui_handlers.odin
 */
export interface Product {
  id: number;
  name: string;
  price: number;
  category: string;
  status: 'Available' | 'OutOfStock' | 'Discontinued';
  created_at: string; // ISO 8601 date string
}

/**
 * Order model - MUST match backend Order struct
 * Backend: src/handlers/webui_handlers.odin
 */
export interface Order {
  id: number;
  customer_name: string;
  total: number;
  status: 'Pending' | 'Processing' | 'Shipped' | 'Delivered' | 'Cancelled';
  created_at: string; // ISO 8601 date string
}

export interface DashboardStats {
  totalUsers: number;
  totalProducts: number;
  totalOrders: number;
  totalRevenue: number;
  activeUsers?: number;
  pendingOrders?: number;
}

export interface NavItem {
  id: string;
  label: string;
  icon: string;
  active: boolean;
  description?: string;
}

export interface DataTableColumn {
  key: string;
  label: string;
  type?: 'text' | 'number' | 'date' | 'actions' | 'status';
  width?: string;
}

export interface FormField {
  key: string;
  label: string;
  type: 'text' | 'number' | 'select' | 'date';
  options?: Array<{ value: string; label: string }>;
}

export interface DataTableConfig {
  entityName: 'User' | 'Product' | 'Order';
  entityNamePlural: string;
  icon: string;
  columns: DataTableColumn[];
  formFields: FormField[];
}

// NOTE: ApiResponse is defined in api.types.ts to avoid duplication

export interface UserStats {
  total_users: number;
  today_count: number;
  unique_domains: number;
}

export interface StatsUpdateEvent {
  type: 'totalUsers' | 'totalProducts' | 'totalOrders';
  count: number;
}