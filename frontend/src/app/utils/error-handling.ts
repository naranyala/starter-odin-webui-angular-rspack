/**
 * Unified Error Handling Utility
 * 
 * Provides consistent error handling across the application
 * with typed errors, error codes, and user-friendly messages.
 */

// ============================================================================
// Error Types
// ============================================================================

export enum ErrorCode {
  // Application errors
  UNKNOWN = 'UNKNOWN',
  INTERNAL = 'INTERNAL',
  INVALID_STATE = 'INVALID_STATE',
  TIMEOUT = 'TIMEOUT',
  NOT_FOUND = 'NOT_FOUND',
  ALREADY_EXISTS = 'ALREADY_EXISTS',
  
  // Parameter errors
  INVALID_PARAMETER = 'INVALID_PARAMETER',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  
  // IO errors
  IO_ERROR = 'IO_ERROR',
  FILE_ERROR = 'FILE_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR',
  PARSE_ERROR = 'PARSE_ERROR',
  
  // Auth errors
  AUTH_ERROR = 'AUTH_ERROR',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  SESSION_EXPIRED = 'SESSION_EXPIRED',
  
  // Service errors
  SERVICE_ERROR = 'SERVICE_ERROR',
  CACHE_ERROR = 'CACHE_ERROR',
  STORAGE_ERROR = 'STORAGE_ERROR',
}

export interface AppError {
  code: ErrorCode;
  message: string;
  details?: string;
  field?: string;
  timestamp: number;
  source?: string;
}

export interface ValidationError {
  field: string;
  message: string;
  code: ErrorCode;
}

export interface ErrorOptions {
  details?: string;
  field?: string;
  source?: string;
  cause?: Error;
}

// ============================================================================
// Error Factory Functions
// ============================================================================

/**
 * Create a new AppError with standardized format
 */
export function createError(
  code: ErrorCode,
  message: string,
  options?: ErrorOptions
): AppError {
  return {
    code,
    message,
    details: options?.details,
    field: options?.field,
    timestamp: Date.now(),
    source: options?.source,
  };
}

/**
 * Create an error from an unknown error object
 */
export function wrapError(error: unknown, fallbackCode: ErrorCode = ErrorCode.UNKNOWN): AppError {
  if (isAppError(error)) {
    return error;
  }
  
  if (error instanceof Error) {
    return createError(fallbackCode, error.message, {
      cause: error,
    });
  }
  
  return createError(fallbackCode, String(error));
}

/**
 * Create a validation error with field information
 */
export function createValidationError(
  field: string,
  message: string,
  code: ErrorCode = ErrorCode.VALIDATION_ERROR
): ValidationError {
  return { field, message, code };
}

/**
 * Create multiple validation errors
 */
export function createValidationErrors(errors: Array<{ field: string; message: string }>): ValidationError[] {
  return errors.map(({ field, message }) => createValidationError(field, message));
}

// ============================================================================
// Specific Error Creators
// ============================================================================

export const AppErrors = {
  // General errors
  unknown: (message = 'An unknown error occurred', options?: ErrorOptions) =>
    createError(ErrorCode.UNKNOWN, message, options),
  
  internal: (message = 'An internal error occurred', options?: ErrorOptions) =>
    createError(ErrorCode.INTERNAL, message, options),
  
  invalidState: (message = 'Invalid application state', options?: ErrorOptions) =>
    createError(ErrorCode.INVALID_STATE, message, options),
  
  timeout: (message = 'Request timeout', options?: ErrorOptions) =>
    createError(ErrorCode.TIMEOUT, message, options),
  
  notFound: (resource: string, id?: string | number) =>
    createError(
      ErrorCode.NOT_FOUND,
      id ? `${resource} with id '${id}' not found` : `${resource} not found`
    ),
  
  alreadyExists: (resource: string, identifier: string) =>
    createError(ErrorCode.ALREADY_EXISTS, `${resource} '${identifier}' already exists`),
  
  // Parameter errors
  invalidParameter: (param: string, reason: string) =>
    createError(ErrorCode.INVALID_PARAMETER, `Invalid parameter '${param}': ${reason}`, {
      field: param,
    }),
  
  validation: (field: string, message: string) =>
    createError(ErrorCode.VALIDATION_ERROR, message, { field }),
  
  // IO errors
  io: (message = 'IO operation failed', options?: ErrorOptions) =>
    createError(ErrorCode.IO_ERROR, message, options),
  
  file: (message = 'File operation failed', options?: ErrorOptions) =>
    createError(ErrorCode.FILE_ERROR, message, options),
  
  network: (message = 'Network error occurred', options?: ErrorOptions) =>
    createError(ErrorCode.NETWORK_ERROR, message, options),
  
  parse: (message = 'Failed to parse data', options?: ErrorOptions) =>
    createError(ErrorCode.PARSE_ERROR, message, options),
  
  // Auth errors
  auth: (message = 'Authentication failed', options?: ErrorOptions) =>
    createError(ErrorCode.AUTH_ERROR, message, options),
  
  unauthorized: (message = 'Authentication required') =>
    createError(ErrorCode.UNAUTHORIZED, message),
  
  forbidden: (message = 'Access denied') =>
    createError(ErrorCode.FORBIDDEN, message),
  
  sessionExpired: () =>
    createError(ErrorCode.SESSION_EXPIRED, 'Your session has expired. Please login again.'),
  
  // Service errors
  service: (service: string, message: string) =>
    createError(ErrorCode.SERVICE_ERROR, `${service}: ${message}`),
  
  cache: (message = 'Cache operation failed', options?: ErrorOptions) =>
    createError(ErrorCode.CACHE_ERROR, message, options),
  
  storage: (message = 'Storage operation failed', options?: ErrorOptions) =>
    createError(ErrorCode.STORAGE_ERROR, message, options),
};

// ============================================================================
// Type Guards
// ============================================================================

/**
 * Check if value is an AppError
 */
export function isAppError(value: unknown): value is AppError {
  return (
    typeof value === 'object' &&
    value !== null &&
    'code' in value &&
    'message' in value &&
    'timestamp' in value
  );
}

/**
 * Check if value is a ValidationError
 */
export function isValidationError(value: unknown): value is ValidationError {
  return (
    typeof value === 'object' &&
    value !== null &&
    'field' in value &&
    'message' in value &&
    'code' in value
  );
}

// ============================================================================
// Error Formatting
// ============================================================================

/**
 * Format error for display to user
 */
export function formatError(error: AppError | string): string {
  if (typeof error === 'string') {
    return error;
  }
  
  const parts = [error.message];
  if (error.details) {
    parts.push(error.details);
  }
  if (error.field) {
    parts.unshift(`Field '${error.field}':`);
  }
  
  return parts.join(' - ');
}

/**
 * Format error for logging
 */
export function formatErrorForLog(error: AppError): string {
  const timestamp = new Date(error.timestamp).toISOString();
  const base = `[${timestamp}] [${error.code}] ${error.message}`;
  
  const parts = [base];
  if (error.field) parts.push(`Field: ${error.field}`);
  if (error.details) parts.push(`Details: ${error.details}`);
  if (error.source) parts.push(`Source: ${error.source}`);
  
  return parts.join(' | ');
}

/**
 * Get user-friendly error message based on error code
 */
export function getUserFriendlyMessage(error: AppError): string {
  const userMessages: Record<ErrorCode, string> = {
    [ErrorCode.UNKNOWN]: 'Something went wrong. Please try again.',
    [ErrorCode.INTERNAL]: 'An internal error occurred. Please contact support.',
    [ErrorCode.INVALID_STATE]: 'The application is in an invalid state. Please refresh.',
    [ErrorCode.TIMEOUT]: 'The request took too long. Please try again.',
    [ErrorCode.NOT_FOUND]: 'The requested item was not found.',
    [ErrorCode.ALREADY_EXISTS]: 'This item already exists.',
    [ErrorCode.INVALID_PARAMETER]: 'Invalid input provided.',
    [ErrorCode.VALIDATION_ERROR]: 'Please check your input and try again.',
    [ErrorCode.IO_ERROR]: 'Failed to read/write data.',
    [ErrorCode.FILE_ERROR]: 'File operation failed.',
    [ErrorCode.NETWORK_ERROR]: 'Network error. Please check your connection.',
    [ErrorCode.PARSE_ERROR]: 'Failed to process data.',
    [ErrorCode.AUTH_ERROR]: 'Authentication failed.',
    [ErrorCode.UNAUTHORIZED]: 'Please login to continue.',
    [ErrorCode.FORBIDDEN]: 'You do not have permission to perform this action.',
    [ErrorCode.SESSION_EXPIRED]: 'Your session has expired. Please login again.',
    [ErrorCode.SERVICE_ERROR]: 'A service error occurred.',
    [ErrorCode.CACHE_ERROR]: 'Cache error. Some features may not work correctly.',
    [ErrorCode.STORAGE_ERROR]: 'Failed to save data locally.',
  };
  
  return userMessages[error.code] || error.message;
}

// ============================================================================
// Error Handler Class
// ============================================================================

export class ErrorHandler {
  private errors: AppError[] = [];
  private maxErrors = 100;
  
  /**
   * Add an error to the error stack
   */
  add(error: AppError): void {
    this.errors.push(error);
    if (this.errors.length > this.maxErrors) {
      this.errors.shift();
    }
  }
  
  /**
   * Add multiple errors
   */
  addMany(errors: AppError[]): void {
    errors.forEach(error => this.add(error));
  }
  
  /**
   * Get all errors
   */
  getAll(): AppError[] {
    return [...this.errors];
  }
  
  /**
   * Get errors by code
   */
  getByCode(code: ErrorCode): AppError[] {
    return this.errors.filter(error => error.code === code);
  }
  
  /**
   * Get most recent error
   */
  getLatest(): AppError | null {
    return this.errors.length > 0 ? this.errors[this.errors.length - 1] : null;
  }
  
  /**
   * Clear all errors
   */
  clear(): void {
    this.errors = [];
  }
  
  /**
   * Clear errors by code
   */
  clearByCode(code: ErrorCode): void {
    this.errors = this.errors.filter(error => error.code !== code);
  }
  
  /**
   * Check if there are any errors
   */
  hasErrors(): boolean {
    return this.errors.length > 0;
  }
  
  /**
   * Check if there are errors of a specific code
   */
  hasErrorCode(code: ErrorCode): boolean {
    return this.errors.some(error => error.code === code);
  }
}

// Singleton error handler for global use
export const globalErrorHandler = new ErrorHandler();
