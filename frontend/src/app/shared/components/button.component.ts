/**
 * Button Component - Reusable button with variants
 *
 * A flexible button component supporting multiple variants, sizes, and states
 */

import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

export type ButtonVariant = 'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'info' | 'ghost';
export type ButtonSize = 'small' | 'medium' | 'large';
export type ButtonType = 'button' | 'submit' | 'reset';

@Component({
  selector: 'app-button',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button
      type="{{type}}"
      class="btn btn--{{variant}} btn--{{size}}"
      [class.btn--full-width]="fullWidth"
      [class.btn--loading]="loading"
      [class.btn--disabled]="disabled || loading"
      [class.btn--icon]="iconOnly"
      [disabled]="disabled || loading"
      (click)="onClick($event)"
    >
      @if (loading) {
        <span class="btn__loader">
          <span class="spinner"></span>
        </span>
      }
      
      @if (icon && !loading) {
        <span class="btn__icon">{{ icon }}</span>
      }
      
      @if (!iconOnly) {
        <span class="btn__label">
          <ng-content></ng-content>
        </span>
      }
    </button>
  `,
  styles: [`
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 10px 20px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
      white-space: nowrap;
      position: relative;
    }
    
    .btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
    
    /* Sizes */
    .btn--small {
      padding: 6px 12px;
      font-size: 12px;
    }
    
    .btn--medium {
      padding: 10px 20px;
      font-size: 14px;
    }
    
    .btn--large {
      padding: 14px 28px;
      font-size: 16px;
    }
    
    /* Variants */
    .btn--primary {
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: white;
    }
    
    .btn--primary:hover:not(:disabled) {
      background: linear-gradient(135deg, #0891b2, #2563eb);
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(6, 182, 212, 0.4);
    }
    
    .btn--secondary {
      background: #f1f5f9;
      color: #334155;
      border: 1px solid #e2e8f0;
    }
    
    .btn--secondary:hover:not(:disabled) {
      background: #e2e8f0;
    }
    
    .btn--success {
      background: linear-gradient(135deg, #10b981, #059669);
      color: white;
    }
    
    .btn--success:hover:not(:disabled) {
      background: linear-gradient(135deg, #059669, #047857);
    }
    
    .btn--danger {
      background: linear-gradient(135deg, #ef4444, #dc2626);
      color: white;
    }
    
    .btn--danger:hover:not(:disabled) {
      background: linear-gradient(135deg, #dc2626, #b91c1c);
    }
    
    .btn--warning {
      background: linear-gradient(135deg, #f59e0b, #d97706);
      color: white;
    }
    
    .btn--warning:hover:not(:disabled) {
      background: linear-gradient(135deg, #d97706, #b45309);
    }
    
    .btn--info {
      background: linear-gradient(135deg, #3b82f6, #2563eb);
      color: white;
    }
    
    .btn--info:hover:not(:disabled) {
      background: linear-gradient(135deg, #2563eb, #1d4ed8);
    }
    
    .btn--ghost {
      background: transparent;
      color: #64748b;
    }
    
    .btn--ghost:hover:not(:disabled) {
      background: #f1f5f9;
      color: #334155;
    }
    
    /* Full width */
    .btn--full-width {
      width: 100%;
    }
    
    /* Icon only */
    .btn--icon {
      padding: 8px;
      border-radius: 50%;
    }
    
    /* Loading state */
    .btn--loading {
      pointer-events: none;
    }
    
    .btn__loader {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .spinner {
      width: 16px;
      height: 16px;
      border: 2px solid rgba(255, 255, 255, 0.3);
      border-top-color: white;
      border-radius: 50%;
      animation: spin 0.6s linear infinite;
    }
    
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    
    .btn__icon {
      font-size: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .btn__label {
      display: flex;
      align-items: center;
    }
  `]
})
export class ButtonComponent {
  @Input() variant: ButtonVariant = 'primary';
  @Input() size: ButtonSize = 'medium';
  @Input() type: ButtonType = 'button';
  @Input() icon = '';
  @Input() fullWidth = false;
  @Input() loading = false;
  @Input() disabled = false;
  @Input() iconOnly = false;
  
  @Output() clicked = new EventEmitter<MouseEvent>();
  
  onClick(event: MouseEvent): void {
    if (!this.disabled && !this.loading) {
      this.clicked.emit(event);
    }
  }
}
