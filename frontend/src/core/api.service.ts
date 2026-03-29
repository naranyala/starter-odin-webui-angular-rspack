// Modern API service with signals for backend communication
import { Injectable, signal, computed, inject, OnDestroy } from '@angular/core';
import { DEFAULT_TIMEOUT_MS } from '../app/constants/app.constants';
import { EndpointName, EndpointRequest, EndpointResponse } from '../models';

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

export interface CallOptions {
  timeoutMs?: number;
}

export interface ApiState {
  loading: boolean;
  error: string | null;
  lastCallTime: number | null;
  callCount: number;
}

@Injectable({ providedIn: 'root' })
export class ApiService implements OnDestroy {
  private readonly defaultTimeout = DEFAULT_TIMEOUT_MS;

  // Internal state signals
  private readonly loading = signal(false);
  private readonly error = signal<string | null>(null);
  private readonly lastCallTime = signal<number | null>(null);
  private readonly callCount = signal(0);
  
  // Track active event listeners for cleanup
  private readonly activeListeners = new Map<string, EventListener>();

  // Public readonly signals
  readonly isLoading = this.loading.asReadonly();
  readonly error$ = this.error.asReadonly();
  readonly lastCallTime$ = this.lastCallTime.asReadonly();
  readonly callCount$ = this.callCount.asReadonly();

  // Computed signals
  readonly hasError = computed(() => this.error() !== null);
  readonly isReady = computed(() => !this.loading() && this.error() === null);
  
  /**
   * Call a backend function with automatic loading/error state management
   */
  async call<T>(functionName: string, args: unknown[] = [], options?: CallOptions): Promise<ApiResponse<T>> {
    this.loading.set(true);
    this.error.set(null);
    this.callCount.update(count => count + 1);

    return new Promise((resolve, reject) => {
      const timeoutMs = options?.timeoutMs ?? this.defaultTimeout;
      const responseEventName = `${functionName}_response`;

      const handler = (event: CustomEvent<ApiResponse<T>>) => {
        clearTimeout(timeoutId);
        window.removeEventListener(responseEventName, handler as EventListener);
        this.activeListeners.delete(responseEventName);

        this.loading.set(false);
        this.lastCallTime.set(Date.now());

        if (!event.detail.success) {
          this.error.set(event.detail.error ?? 'Unknown error');
        }

        resolve(event.detail);
      };

      // Store listener for cleanup
      this.activeListeners.set(responseEventName, handler as EventListener);

      const timeoutId = setTimeout(() => {
        window.removeEventListener(responseEventName, handler as EventListener);
        this.activeListeners.delete(responseEventName);
        this.loading.set(false);
        this.error.set(`Request timeout after ${timeoutMs}ms`);

        reject({
          success: false,
          error: `Request timeout after ${timeoutMs}ms`,
        });
      }, timeoutMs);

      try {
        const backendFn = (window as unknown as Record<string, unknown>)[functionName];

        if (typeof backendFn !== 'function') {
          clearTimeout(timeoutId);
          window.removeEventListener(responseEventName, handler as EventListener);
          this.activeListeners.delete(responseEventName);
          this.loading.set(false);
          this.error.set(`Backend function not found: ${functionName}`);

          reject({
            success: false,
            error: `Backend function not found: ${functionName}`,
          });
          return;
        }

        backendFn(...args);
      } catch (error) {
        clearTimeout(timeoutId);
        window.removeEventListener(responseEventName, handler as EventListener);
        this.activeListeners.delete(responseEventName);
        this.loading.set(false);
        const errorMsg = error instanceof Error ? error.message : String(error);
        this.error.set(errorMsg);

        reject({
          success: false,
          error: errorMsg,
        });
      }
    });
  }

  /**
   * Call backend and throw on error
   */
  async callOrThrow<T>(functionName: string, args: unknown[] = []): Promise<T> {
    const response = await this.call<T>(functionName, args);
    if (!response.success) {
      throw new Error(response.error ?? 'Unknown error');
    }
    return response.data as T;
  }

  /**
   * Typed call method using endpoint definitions
   */
  async callTyped<T extends EndpointName>(
    functionName: T, 
    ...args: EndpointRequest<T>
  ): Promise<ApiResponse<EndpointResponse<T>>> {
    return this.call<EndpointResponse<T>>(functionName, args as unknown[]);
  }

  /**
   * Typed callOrThrow method using endpoint definitions
   */
  async callOrThrowTyped<T extends EndpointName>(
    functionName: T, 
    ...args: EndpointRequest<T>
  ): Promise<EndpointResponse<T>> {
    const response = await this.callTyped(functionName, ...args);
    if (!response.success) {
      throw new Error(response.error ?? 'Unknown error');
    }
    return response.data as EndpointResponse<T>;
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
  }

  /**
   * Cleanup to prevent memory leaks
   */
  ngOnDestroy(): void {
    // Remove all active event listeners
    this.activeListeners.forEach((listener, event) => {
      window.removeEventListener(event, listener);
    });
    this.activeListeners.clear();
  }
}
