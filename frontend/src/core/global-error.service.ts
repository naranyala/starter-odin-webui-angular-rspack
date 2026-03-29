// Global error service - centralized error state management
import { Injectable, signal } from '@angular/core';
import { ErrorCode } from '../app/utils/error-handling';

export interface GlobalErrorState {
  title: string;
  userMessage: string;
  code: ErrorCode;
  details?: string;
  source?: string;
  timestamp: number;
}

@Injectable({ providedIn: 'root' })
export class GlobalErrorService {
  private readonly errorState = signal<GlobalErrorState | null>(null);

  readonly currentError = this.errorState.asReadonly();

  /**
   * Set error from error state object
   */
  setError(error: GlobalErrorState): void {
    this.errorState.set(error);
  }

  /**
   * Set error from code and message
   */
  setErrorFromCode(
    code: ErrorCode,
    message: string,
    title?: string,
    details?: string
  ): void {
    this.errorState.set({
      title: title ?? 'Error',
      userMessage: message,
      code,
      details,
      timestamp: Date.now(),
    });
  }

  /**
   * Set error from Error object
   */
  setErrorFromError(error: Error, title?: string): void {
    this.errorState.set({
      title: title ?? 'Error',
      userMessage: error.message,
      code: ErrorCode.UNKNOWN,
      timestamp: Date.now(),
    });
  }

  /**
   * Clear current error
   */
  clearError(): void {
    this.errorState.set(null);
  }

  /**
   * Check if there is an active error
   */
  hasError(): boolean {
    return this.errorState() !== null;
  }
}
