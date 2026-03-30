/**
 * Documentation Viewer Component (Dynamic)
 *
 * Main documentation viewer with dynamic menu generation
 * Auto-discovers markdown files and generates navigation
 */

import { Component, signal, computed, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MarkdownModule } from 'ngx-markdown';
import { DocumentationService } from '../../app/services/documentation.service';
import { DocSection, DocItem } from '../../app/models/doc-manifest';

@Component({
  selector: 'app-documentation-viewer',
  standalone: true,
  imports: [
    CommonModule,
    MarkdownModule,
  ],
  template: `
    <div class="docs-container">
      <!-- Loading State -->
      @if (isLoading()) {
        <div class="docs-loading">
          <div class="loading-spinner"></div>
          <p>Loading documentation...</p>
        </div>
      }

      <!-- Error State -->
      @if (hasError()) {
        <div class="docs-error">
          <h2>⚠️ Failed to Load Documentation</h2>
          <p>{{ errorMessage() }}</p>
          <button class="retry-btn" (click)="retry()">Retry</button>
        </div>
      }

      <!-- Main Content -->
      @if (!isLoading() && !hasError()) {
        <!-- Navigation Sidebar -->
        <aside class="docs-nav">
          <div class="docs-nav-header">
            <h2 class="docs-nav-title">📚 Documentation</h2>
          </div>

          <nav class="docs-nav-items">
            @for (section of sections(); track section.id) {
              <div class="docs-nav-section">
                <button 
                  class="docs-nav-section-header"
                  (click)="toggleSection(section.id)"
                >
                  <span class="section-icon">{{ section.icon }}</span>
                  <span class="section-title">{{ section.title }}</span>
                  <span class="section-toggle">{{ expandedSections()[section.id] ? '▼' : '▶' }}</span>
                </button>

                @if (expandedSections()[section.id]) {
                  <div class="docs-nav-items-list">
                    @for (item of section.items; track item.id) {
                      <button
                        class="docs-nav-item"
                        [class.active]="activeItem() === item.id"
                        (click)="selectItem(item)"
                      >
                        <span class="item-icon">📄</span>
                        <span class="item-title">{{ item.title }}</span>
                      </button>
                    }
                  </div>
                }
              </div>
            }
          </nav>
        </aside>

        <!-- Content Area -->
        <main class="docs-content">
          @if (currentContent()) {
            <article class="docs-article">
              <markdown 
                [data]="currentContent()"
                (error)="onMarkdownError($event)">
              </markdown>
            </article>
          } @else {
            <div class="docs-welcome">
              <h1>Welcome to Documentation</h1>
              <p>Select a topic from the navigation to get started.</p>
              <div class="quick-links">
                <h3>Quick Links</h3>
                <div class="quick-links-grid">
                  @for (item of recentItems(); track item.id) {
                    <button class="quick-link" (click)="selectItem(item)">
                      <span class="quick-link-icon">📄</span>
                      <span class="quick-link-title">{{ item.title }}</span>
                    </button>
                  }
                </div>
              </div>
            </div>
          }
        </main>
      }
    </div>
  `,
  styles: [`
    .docs-container {
      display: flex;
      height: 100vh;
      background: #0f172a;
      overflow: hidden;
    }

    /* Loading State */
    .docs-loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      color: #94a3b8;
    }

    .loading-spinner {
      width: 40px;
      height: 40px;
      border: 3px solid rgba(148, 163, 184, 0.2);
      border-top-color: #06b6d4;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-bottom: 16px;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    /* Error State */
    .docs-error {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      color: #ef4444;
      text-align: center;
      padding: 20px;
    }

    .docs-error h2 {
      font-size: 24px;
      margin-bottom: 16px;
    }

    .retry-btn {
      margin-top: 20px;
      padding: 12px 24px;
      background: linear-gradient(135deg, #06b6d4, #3b82f6);
      color: white;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      font-weight: 600;
    }

    /* Navigation */
    .docs-nav {
      width: 320px;
      background: rgba(15, 23, 42, 0.95);
      border-right: 1px solid rgba(148, 163, 184, 0.1);
      overflow-y: auto;
    }

    .docs-nav-header {
      padding: 20px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .docs-nav-title {
      font-size: 18px;
      font-weight: 700;
      color: #f8fafc;
      margin: 0;
    }

    .docs-nav-items {
      padding: 10px 0;
    }

    .docs-nav-section {
      margin-bottom: 8px;
    }

    .docs-nav-section-header {
      display: flex;
      align-items: center;
      gap: 10px;
      width: 100%;
      padding: 12px 20px;
      background: transparent;
      border: none;
      color: #94a3b8;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: all 0.2s;
    }

    .docs-nav-section-header:hover {
      background: rgba(148, 163, 184, 0.1);
      color: #f8fafc;
    }

    .section-icon {
      font-size: 18px;
    }

    .section-title {
      flex: 1;
      text-align: left;
    }

    .section-toggle {
      font-size: 12px;
      opacity: 0.7;
    }

    .docs-nav-items-list {
      padding-left: 20px;
    }

    .docs-nav-item {
      display: flex;
      align-items: center;
      gap: 10px;
      width: 100%;
      padding: 10px 20px;
      background: transparent;
      border: none;
      color: #64748b;
      cursor: pointer;
      font-size: 13px;
      transition: all 0.2s;
    }

    .docs-nav-item:hover {
      background: rgba(148, 163, 184, 0.1);
      color: #f8fafc;
    }

    .docs-nav-item.active {
      background: rgba(6, 182, 212, 0.15);
      color: #06b6d4;
      border-left: 3px solid #06b6d4;
    }

    .item-icon {
      font-size: 14px;
    }

    /* Content */
    .docs-content {
      flex: 1;
      overflow-y: auto;
      background: #0f172a;
      padding: 40px;
    }

    .docs-article {
      max-width: 900px;
      margin: 0 auto;
    }

    .docs-article ::ng-deep markdown {
      color: #e2e8f0;
      line-height: 1.7;
    }

    .docs-article ::ng-deep markdown h1 {
      font-size: 2.5rem;
      font-weight: 700;
      color: #f8fafc;
      margin-bottom: 1.5rem;
      padding-bottom: 0.75rem;
      border-bottom: 1px solid rgba(148, 163, 184, 0.2);
    }

    .docs-article ::ng-deep markdown h2 {
      font-size: 1.75rem;
      font-weight: 600;
      color: #f1f5f9;
      margin-top: 2rem;
      margin-bottom: 1rem;
    }

    .docs-article ::ng-deep markdown p {
      margin-bottom: 1rem;
    }

    .docs-article ::ng-deep markdown code {
      background: rgba(30, 41, 59, 0.8);
      padding: 0.2rem 0.4rem;
      border-radius: 4px;
      font-family: 'Fira Code', monospace;
      font-size: 0.9em;
      color: #06b6d4;
    }

    .docs-article ::ng-deep markdown pre {
      background: #1e293b;
      border-radius: 8px;
      padding: 1rem;
      overflow-x: auto;
      margin: 1rem 0;
    }

    .docs-article ::ng-deep markdown pre code {
      background: transparent;
      padding: 0;
      color: #e2e8f0;
    }

    /* Welcome */
    .docs-welcome {
      max-width: 900px;
      margin: 0 auto;
      text-align: center;
      padding: 60px 20px;
    }

    .docs-welcome h1 {
      font-size: 2.5rem;
      font-weight: 700;
      color: #f8fafc;
      margin-bottom: 16px;
    }

    .docs-welcome p {
      font-size: 1.1rem;
      color: #94a3b8;
      margin-bottom: 40px;
    }

    .quick-links {
      text-align: left;
      margin-top: 40px;
    }

    .quick-links h3 {
      font-size: 1.25rem;
      color: #f8fafc;
      margin-bottom: 20px;
    }

    .quick-links-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 16px;
    }

    .quick-link {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(148, 163, 184, 0.1);
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.2s;
    }

    .quick-link:hover {
      background: rgba(255, 255, 255, 0.1);
      border-color: rgba(6, 182, 212, 0.3);
      transform: translateY(-2px);
    }

    .quick-link-icon {
      font-size: 20px;
    }

    .quick-link-title {
      font-size: 14px;
      font-weight: 600;
      color: #e2e8f0;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .docs-nav {
        position: absolute;
        z-index: 10;
        transform: translateX(-100%);
        transition: transform 0.3s ease;
      }

      .docs-nav.show {
        transform: translateX(0);
      }

      .docs-content {
        padding: 20px;
      }

      .docs-article ::ng-deep markdown h1 {
        font-size: 1.75rem;
      }
    }
  `],
})
export class DocumentationViewerComponent implements OnInit {
  private readonly docsService = inject(DocumentationService);

  // State signals
  activeSection = signal<string>('');
  activeItem = signal<string>('');
  currentContent = signal<string>('');
  expandedSections = signal<Record<string, boolean>>({});
  isLoading = signal(true);
  hasError = signal(false);
  errorMessage = signal<string>('');

  // Computed signals
  sections = computed(() => this.docsService.getSections());
  recentItems = computed(() => this.docsService.getRecent(6));

  ngOnInit(): void {
    this.loadDocumentation();
  }

  /**
   * Load documentation structure
   */
  async loadDocumentation(): Promise<void> {
    this.isLoading.set(true);
    this.hasError.set(false);

    try {
      await this.docsService.loadManifest();
      
      // Expand first section by default
      const sections = this.docsService.getSections();
      if (sections.length > 0) {
        this.expandedSections.set({ [sections[0].id]: true });
        this.activeSection.set(sections[0].id);
      }

      this.isLoading.set(false);
    } catch (err) {
      this.hasError.set(true);
      this.errorMessage.set('Failed to load documentation structure');
      this.isLoading.set(false);
      console.error('Failed to load docs:', err);
    }
  }

  /**
   * Toggle section expansion
   */
  toggleSection(sectionId: string): void {
    this.expandedSections.update(sections => ({
      ...sections,
      [sectionId]: !sections[sectionId],
    }));
  }

  /**
   * Select documentation item
   */
  async selectItem(item: DocItem): Promise<void> {
    this.activeItem.set(item.id);
    this.activeSection.set(item.category);
    
    try {
      const content = await this.loadMarkdown(item.path);
      this.currentContent.set(content);
    } catch (err) {
      this.currentContent.set(`# Error\n\nFailed to load: ${item.title}`);
      console.error('Failed to load markdown:', err);
    }
  }

  /**
   * Load markdown file content
   */
  private async loadMarkdown(path: string): Promise<string> {
    // In production, this would fetch the actual file
    // For now, return placeholder content
    return `# Loading...\n\nContent from: ${path}`;
  }

  /**
   * Handle markdown rendering error
   */
  onMarkdownError(error: any): void {
    console.error('Markdown render error:', error);
  }

  /**
   * Retry loading documentation
   */
  async retry(): Promise<void> {
    await this.loadDocumentation();
  }
}
