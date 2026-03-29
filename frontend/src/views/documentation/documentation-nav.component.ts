/**
 * Documentation Navigation Component
 * 
 * Displays the documentation navigation tree
 */

import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DocSection } from './documentation-viewer.component';

@Component({
  selector: 'app-documentation-nav',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="nav-container">
      <div class="nav-header">
        <h2 class="nav-title">📚 Documentation</h2>
      </div>

      <nav class="nav-content">
        @for (section of sections; track section.id) {
          <div class="nav-section">
            <button
              class="nav-section-header"
              (click)="toggleSection(section.id)"
              [class.active]="activeSection === section.id">
              <span class="section-icon">{{ section.icon }}</span>
              <span class="section-title">{{ section.title }}</span>
              <span class="section-toggle">{{ isSectionExpanded(section.id) ? '▼' : '▶' }}</span>
            </button>

            @if (isSectionExpanded(section.id)) {
              <div class="nav-items">
                @for (item of section.items; track item.id) {
                  <button
                    class="nav-item"
                    [class.active]="activeItem === item.id"
                    (click)="selectItem(item.id)">
                    <span class="item-icon">📄</span>
                    <span class="item-title">{{ item.title }}</span>
                  </button>
                }
              </div>
            }
          </div>
        }
      </nav>
    </div>
  `,
  styles: [`
    .nav-container {
      display: flex;
      flex-direction: column;
      height: 100%;
    }

    .nav-header {
      padding: 20px 16px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
      background: rgba(15, 23, 42, 0.5);
    }

    .nav-title {
      margin: 0;
      font-size: 18px;
      font-weight: 600;
      color: #fff;
    }

    .nav-content {
      flex: 1;
      overflow-y: auto;
      padding: 12px 0;
    }

    .nav-section {
      margin-bottom: 8px;
    }

    .nav-section-header {
      display: flex;
      align-items: center;
      gap: 10px;
      width: 100%;
      padding: 12px 16px;
      background: transparent;
      border: none;
      color: #94a3b8;
      cursor: pointer;
      transition: all 0.2s;
      font-size: 14px;
      font-weight: 500;
    }

    .nav-section-header:hover {
      background: rgba(59, 130, 246, 0.1);
      color: #fff;
    }

    .nav-section-header.active {
      background: rgba(59, 130, 246, 0.15);
      color: #60a5fa;
    }

    .section-icon {
      font-size: 16px;
    }

    .section-title {
      flex: 1;
      text-align: left;
    }

    .section-toggle {
      font-size: 10px;
      opacity: 0.6;
    }

    .nav-items {
      padding-left: 16px;
    }

    .nav-item {
      display: flex;
      align-items: center;
      gap: 8px;
      width: 100%;
      padding: 10px 16px;
      background: transparent;
      border: none;
      color: #64748b;
      cursor: pointer;
      transition: all 0.2s;
      font-size: 13px;
      border-left: 2px solid transparent;
    }

    .nav-item:hover {
      background: rgba(59, 130, 246, 0.05);
      color: #94a3b8;
    }

    .nav-item.active {
      background: rgba(59, 130, 246, 0.1);
      color: #60a5fa;
      border-left-color: #60a5fa;
    }

    .item-icon {
      font-size: 12px;
      opacity: 0.7;
    }

    /* Scrollbar styling */
    .nav-content::-webkit-scrollbar {
      width: 6px;
    }

    .nav-content::-webkit-scrollbar-track {
      background: rgba(15, 23, 42, 0.5);
    }

    .nav-content::-webkit-scrollbar-thumb {
      background: rgba(148, 163, 184, 0.2);
      border-radius: 3px;
    }

    .nav-content::-webkit-scrollbar-thumb:hover {
      background: rgba(148, 163, 184, 0.3);
    }
  `],
})
export class DocumentationNavComponent {
  @Input() sections: DocSection[] = [];
  @Input() activeSection: string = '';
  @Input() activeItem: string = '';
  @Output() sectionToggle = new EventEmitter<string>();
  @Output() itemSelect = new EventEmitter<string>();

  private expandedSections = new Set<string>();

  isSectionExpanded(sectionId: string): boolean {
    return this.expandedSections.has(sectionId) || this.activeSection === sectionId;
  }

  toggleSection(sectionId: string): void {
    if (this.expandedSections.has(sectionId)) {
      this.expandedSections.delete(sectionId);
    } else {
      this.expandedSections.add(sectionId);
    }
    this.sectionToggle.emit(sectionId);
  }

  selectItem(itemId: string): void {
    this.itemSelect.emit(itemId);
  }
}
