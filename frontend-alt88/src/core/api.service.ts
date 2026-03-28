/**
 * Enhanced API Service with JSON Serialization
 * 
 * Provides robust serialization/deserialization for backend communication
 * with proper error handling and type safety
 */

import { Injectable, signal, computed, inject } from '@angular/core';
import { LoggerService } from './logger.service';

// ============================================================================
// Type Definitions
// ============================================================================

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  code?: number;
  message?: string;
  details?: string[];
  requestId?: string;
  timestamp?: number;
}

export interface ApiRequest {
  functionName: string;
  args: unknown[];
  timestamp: number;
}

export interface CallOptions {
  timeoutMs?: number;
  skipSerialization?: boolean;
  logRequest?: boolean;
  logResponse?: boolean;
}

export interface ApiState {
  loading: boolean;
  error: string | null;
  lastCallTime: number | null;
  callCount: number;
  pendingRequests: number;
}

// ============================================================================
// API Service
// ============================================================================

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly logger = inject(LoggerService);
  private readonly defaultTimeout = 30000;
  private readonly requestLog = new Map<string, ApiRequest>();

  // Internal state signals
  private readonly loading = signal(false);
  private readonly error = signal<string | null>(null);
  private readonly lastCallTime = signal<number | null>(null);
  private readonly callCount = signal(0);
  private readonly pendingRequests = signal(0);

  // Public readonly signals
  readonly isLoading = this.loading.asReadonly();
  readonly error$ = this.error.asReadonly();
  readonly lastCallTime$ = this.lastCallTime.asReadonly();
  readonly callCount$ = this.callCount.asReadonly();
  readonly pendingRequests$ = this.pendingRequests.asReadonly();

  // Computed signals
  readonly hasError = computed(() => this.error() !== null);
  readonly isReady = computed(() => !this.loading() && this.error() === null);
  readonly isActive = computed(() => this.pendingRequests() > 0);

  /**
   * Serialize arguments for backend
   * Complex objects are JSON stringified, primitives are passed as-is
   */
  private serializeArgs(args: unknown[]): string[] {
    return args.map(arg => {
      if (arg === undefined || arg === null) {
        return 'null';
      }
      if (typeof arg === 'object') {
        // Serialize objects to JSON
        return JSON.stringify(arg);
      }
      // Primitives: convert to string
      return String(arg);
    });
  }

  /**
   * Deserialize response from backend
   * Tries to parse JSON, falls back to raw value
   */
  private deserializeResponse<T>(response: unknown): T {
    if (typeof response === 'string') {
      try {
        // Try to parse as JSON
        return JSON.parse(response) as T;
      } catch {
        // Not JSON, return as string
        return response as unknown as T;
      }
    }
    return response as T;
  }

  /**
   * Parse standardized API response
   * Handles both wrapped and unwrapped responses
   */
  private parseApiResponse<T>(response: unknown): ApiResponse<T> {
    const parsed = this.deserializeResponse<ApiResponse<T> | T>(response);

    // Check if it's already a standardized response
    if (parsed && typeof parsed === 'object' && 'success' in parsed) {
      const apiResponse = parsed as ApiResponse<T>;
      
      // If data is a JSON string, parse it
      if (typeof apiResponse.data === 'string') {
        try {
          apiResponse.data = JSON.parse(apiResponse.data) as T;
        } catch {
          // Keep as string if not JSON
        }
      }
      
      return apiResponse;
    }

    // Wrap raw response in standardized format
    return {
      success: true,
      data: parsed,
      timestamp: Date.now(),
    };
  }

  /**
   * Call a backend function with automatic serialization
   */
  async call<T>(
    functionName: string,
    args: unknown[] = [],
    options?: CallOptions
  ): Promise<ApiResponse<T>> {
    const timeoutMs = options?.timeoutMs ?? this.defaultTimeout;
    const logRequest = options?.logRequest ?? true;
    const logResponse = options?.logResponse ?? true;
    const skipSerialization = options?.skipSerialization ?? false;

    this.loading.set(true);
    this.callCount.update(count => count + 1);
    this.pendingRequests.update(count => count + 1);
    this.lastCallTime.set(Date.now());
    this.error.set(null);

    const requestId = this.generateRequestId();
    const startTime = Date.now();

    if (logRequest) {
      this.logger.info('[API] Request', {
        function: functionName,
        args: skipSerialization ? args : '[serialized]',
        requestId,
      });
    }

    return new Promise((resolve, reject) => {
      const responseEventName = `${functionName}_response`;
      const serializedArgs = skipSerialization ? args : this.serializeArgs(args);

      const handler = (event: CustomEvent<unknown>) => {
        clearTimeout(timeoutId);
        window.removeEventListener(responseEventName, handler as EventListener);

        const duration = Date.now() - startTime;
        this.pendingRequests.update(count => Math.max(0, count - 1));
        this.loading.set(this.pendingRequests() > 0);

        // Parse response
        const response = this.parseApiResponse<T>(event.detail);

        if (logResponse) {
          this.logger.info('[API] Response', {
            function: functionName,
            success: response.success,
            duration: `${duration}ms`,
            requestId,
          });
        }

        if (!response.success) {
          this.error.set(response.error ?? 'Unknown error');
          reject(response);
        } else {
          resolve(response);
        }
      };

      const timeoutId = setTimeout(() => {
        window.removeEventListener(responseEventName, handler as EventListener);
        this.pendingRequests.update(count => Math.max(0, count - 1));
        this.loading.set(this.pendingRequests() > 0);

        const errorMsg = `Request timeout after ${timeoutMs}ms`;
        this.error.set(errorMsg);

        const timeoutResponse: ApiResponse<T> = {
          success: false,
          error: errorMsg,
          code: 408,
          requestId,
          timestamp: Date.now(),
        };

        reject(timeoutResponse);
      }, timeoutMs);

      try {
        const backendFn = (window as unknown as Record<string, unknown>)[functionName];

        if (typeof backendFn !== 'function') {
          clearTimeout(timeoutId);
          window.removeEventListener(responseEventName, handler as EventListener);
          this.pendingRequests.update(count => Math.max(0, count - 1));
          this.loading.set(this.pendingRequests() > 0);

          const errorMsg = `Backend function not found: ${functionName}`;
          this.error.set(errorMsg);

          const errorResponse: ApiResponse<T> = {
            success: false,
            error: errorMsg,
            code: 404,
            requestId,
            timestamp: Date.now(),
          };

          reject(errorResponse);
          return;
        }

        // Call backend function with serialized arguments
        backendFn(...serializedArgs);
      } catch (error) {
        clearTimeout(timeoutId);
        window.removeEventListener(responseEventName, handler as EventListener);
        this.pendingRequests.update(count => Math.max(0, count - 1));
        this.loading.set(this.pendingRequests() > 0);

        const errorMsg = error instanceof Error ? error.message : String(error);
        this.error.set(errorMsg);

        const errorResponse: ApiResponse<T> = {
          success: false,
          error: errorMsg,
          code: 500,
          requestId,
          timestamp: Date.now(),
        };

        reject(errorResponse);
      }
    });
  }

  /**
   * Call backend and throw on error (returns data directly)
   */
  async callOrThrow<T>(functionName: string, args: unknown[] = []): Promise<T> {
    const response = await this.call<T>(functionName, args);
    if (!response.success) {
      throw new Error(response.error ?? 'Unknown error');
    }
    return response.data as T;
  }

  /**
   * Call backend with retry logic
   */
  async callWithRetry<T>(
    functionName: string,
    args: unknown[] = [],
    retries: number = 3,
    delayMs: number = 1000
  ): Promise<ApiResponse<T>> {
    let lastError: unknown;

    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        return await this.call<T>(functionName, args, {
          logRequest: attempt === 1,
          logResponse: attempt === retries,
        });
      } catch (error) {
        lastError = error;
        
        if (attempt < retries) {
          this.logger.warn('[API] Retry', {
            function: functionName,
            attempt,
            maxRetries: retries,
            delay: `${delayMs}ms`,
          });
          await this.delay(delayMs * attempt); // Exponential backoff
        }
      }
    }

    // All retries failed
    const errorResponse: ApiResponse<T> = {
      success: false,
      error: `Failed after ${retries} attempts: ${lastError}`,
      code: 500,
      timestamp: Date.now(),
    };

    return errorResponse;
  }

  /**
   * Call multiple backend functions in parallel
   */
  async callAll<T extends Record<string, unknown>>(
    calls: Array<{ function: string; args?: unknown[] }>
  ): Promise<{ [K in keyof T]: ApiResponse<T[K]> }> {
    const promises = calls.map(call =>
      this.call<T[keyof T]>(call.function, call.args || [])
        .then(response => ({ key: call.function, response }))
        .catch(error => ({ key: call.function, response: error }))
    );

    const results = await Promise.all(promises);
    const responseMap: any = {};

    for (const { key, response } of results) {
      responseMap[key] = response;
    }

    return responseMap;
  }

  /**
   * Clear error state
   */
  clearError(): void {
    this.error.set(null);
  }

  /**
   * Reset all state
   */
  reset(): void {
    this.loading.set(false);
    this.error.set(null);
    this.lastCallTime.set(null);
    this.callCount.set(0);
    this.pendingRequests.set(0);
  }

  /**
   * Get current state
   */
  getState(): ApiState {
    return {
      loading: this.loading(),
      error: this.error(),
      lastCallTime: this.lastCallTime(),
      callCount: this.callCount(),
      pendingRequests: this.pendingRequests(),
    };
  }

  /**
   * Generate unique request ID
   */
  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Delay helper
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
