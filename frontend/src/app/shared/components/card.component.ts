/**
 * Card Component - Reusable card container
 *
 * A flexible card component for displaying content in a contained box
 * with optional header, footer, and actions.
 */

import { Component, Input, ContentChild, TemplateRef } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-card',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="card" [class.card--clickable]="clickable" [class.card--elevated]="elevated"
         [class.card--bordered]="bordered" [class.card--compact]="compact"
         [style.width]="width" (click)="onCardClick()">
      
      @if (header || headerTemplate) {
        <div class="card__header">
          <ng-content select="[card-header]"></ng-content>
          @if (headerTemplate) {
            <ng-container [ngTemplateOutlet]="headerTemplate"></ng-container>
          }
        </div>
      }
      
      <div class="card__content">
        <ng-content></ng-content>
      </div>
      
      @if (footer || footerTemplate) {
        <div class="card__footer">
          <ng-content select="[card-footer]"></ng-content>
          @if (footerTemplate) {
            <ng-container [ngTemplateOutlet]="footerTemplate"></ng-container>
          }
        </div>
      }
      
      @if (actions && hasActions) {
        <div class="card__actions">
          <ng-content select="[card-actions]"></ng-content>
        </div>
      }
    </div>
  `,
  styles: [`
    .card {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 12px;
      overflow: hidden;
      transition: all 0.3s ease;
    }
    
    .card--elevated {
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
    }
    
    .card--clickable {
      cursor: pointer;
    }
    
    .card--clickable:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2);
    }
    
    .card--bordered {
      border: 1px solid rgba(148, 163, 184, 0.2);
    }
    
    .card--compact {
      padding: 12px;
    }
    
    .card__header {
      padding: 16px 20px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      background: rgba(248, 249, 250, 0.5);
    }
    
    .card__content {
      padding: 20px;
    }
    
    .card__footer {
      padding: 16px 20px;
      border-top: 1px solid rgba(148, 163, 184, 0.1);
      background: rgba(248, 249, 250, 0.5);
    }
    
    .card__actions {
      padding: 12px 20px;
      display: flex;
      gap: 8px;
      justify-content: flex-end;
    }
  `]
})
export class CardComponent {
  @Input() header = false;
  @Input() footer = false;
  @Input() actions = true;
  @Input() clickable = false;
  @Input() elevated = true;
  @Input() bordered = false;
  @Input() compact = false;
  @Input() width: string | null = null;
  
  @ContentChild('headerTemplate') headerTemplate!: TemplateRef<any>;
  @ContentChild('footerTemplate') footerTemplate!: TemplateRef<any>;
  
  hasActions = false;
  
  onCardClick(): void {
    // Card click handler
  }
}
