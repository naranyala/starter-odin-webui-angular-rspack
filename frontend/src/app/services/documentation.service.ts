/**
 * Documentation Service
 * 
 * Dynamically loads and manages documentation structure
 * Auto-discovers markdown files and generates menu
 */

import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { DOCS_MANIFEST, DocManifest, DocSection, DocItem } from '../models/doc-manifest';

@Injectable({
  providedIn: 'root'
})
export class DocumentationService {
  private readonly manifestUrl = 'assets/docs/manifest.json';
  
  // Signals for reactive state
  private readonly manifest = signal<DocManifest | null>(null);
  private readonly loaded = signal(false);
  private readonly error = signal<string | null>(null);

  // Public readonly signals
  readonly sections = computed(() => this.manifest()?.sections || []);
  readonly isLoaded = this.loaded.asReadonly();
  readonly hasError = computed(() => this.error() !== null);
  readonly errorMessage = this.error.asReadonly();

  // Fallback manifest for development
  private readonly fallbackSections: DocSection[] = [
    {
      id: 'quickstart',
      title: 'Quick Start',
      icon: '🚀',
      order: 1,
      items: [
        { id: 'overview', title: 'Overview', path: 'assets/docs/README.md', category: 'quickstart', order: 1 },
        { id: 'installation', title: 'Installation', path: 'assets/docs/QUICKSTART.md', category: 'quickstart', order: 2 },
      ]
    },
    {
      id: 'backend',
      title: 'Backend',
      icon: '🔙',
      order: 2,
      items: [
        { id: 'backend-readme', title: 'Backend Overview', path: 'assets/docs/backend/README.md', category: 'backend', order: 1 },
        { id: 'duckdb-integration', title: 'DuckDB Integration', path: 'assets/docs/backend/duckdb-integration.md', category: 'backend', order: 2 },
        { id: 'sqlite-integration', title: 'SQLite Integration', path: 'assets/docs/backend/sqlite-integration.md', category: 'backend', order: 3 },
      ]
    },
    {
      id: 'frontend',
      title: 'Frontend',
      icon: '🎨',
      order: 3,
      items: [
        { id: 'frontend-readme', title: 'Frontend Overview', path: 'assets/docs/frontend/README.md', category: 'frontend', order: 1 },
        { id: 'duckdb-components', title: 'DuckDB Components', path: 'assets/docs/frontend/duckdb-components.md', category: 'frontend', order: 2 },
        { id: 'sqlite-components', title: 'SQLite Components', path: 'assets/docs/frontend/sqlite-components.md', category: 'frontend', order: 3 },
      ]
    },
    {
      id: 'guides',
      title: 'Guides',
      icon: '📚',
      order: 4,
      items: [
        { id: 'crud-operations', title: 'CRUD Operations', path: 'assets/docs/guides/crud-operations-guide.md', category: 'guides', order: 1 },
        { id: 'security', title: 'Security Guide', path: 'assets/docs/guides/README.md', category: 'guides', order: 2 },
      ]
    }
  ];

  constructor(private readonly http: HttpClient) {}

  /**
   * Load documentation manifest
   * Falls back to hardcoded structure if manifest not found
   */
  async loadManifest(): Promise<void> {
    try {
      const manifest = await this.http.get<DocManifest>(this.manifestUrl).toPromise();
      
      if (manifest && manifest.sections && manifest.sections.length > 0) {
        this.manifest.set(manifest);
        this.loaded.set(true);
        console.log('[Docs] Loaded manifest with', manifest.sections.length, 'sections');
      } else {
        console.warn('[Docs] Manifest empty, using fallback');
        this.useFallback();
      }
    } catch (err) {
      console.warn('[Docs] Failed to load manifest, using fallback:', err);
      this.useFallback();
    }
  }

  /**
   * Use fallback documentation structure
   */
  private useFallback(): void {
    this.manifest.set({
      version: '1.0.0',
      generated: new Date().toISOString(),
      sections: this.fallbackSections.sort((a, b) => a.order - b.order)
    });
    this.loaded.set(true);
  }

  /**
   * Get all sections sorted by order
   */
  getSections(): DocSection[] {
    return this.sections().sort((a, b) => a.order - b.order);
  }

  /**
   * Get items for a specific section
   */
  getSectionItems(sectionId: string): DocItem[] {
    const section = this.sections().find(s => s.id === sectionId);
    return section?.items.sort((a, b) => a.order - b.order) || [];
  }

  /**
   * Get item by ID
   */
  getItem(itemId: string): DocItem | undefined {
    for (const section of this.sections()) {
      const item = section.items.find(i => i.id === itemId);
      if (item) return item;
    }
    return undefined;
  }

  /**
   * Get item path by ID
   */
  getItemPath(itemId: string): string | undefined {
    return this.getItem(itemId)?.path;
  }

  /**
   * Search documentation
   */
  search(query: string): DocItem[] {
    const lowerQuery = query.toLowerCase();
    const results: DocItem[] = [];

    for (const section of this.sections()) {
      for (const item of section.items) {
        if (
          item.title.toLowerCase().includes(lowerQuery) ||
          item.id.toLowerCase().includes(lowerQuery) ||
          item.tags?.some(tag => tag.toLowerCase().includes(lowerQuery))
        ) {
          results.push(item);
        }
      }
    }

    return results;
  }

  /**
   * Get recent documentation items
   */
  getRecent(limit: number = 5): DocItem[] {
    const allItems = this.sections().flatMap(s => s.items);
    return allItems.slice(0, limit);
  }

  /**
   * Get documentation by category
   */
  getByCategory(category: string): DocItem[] {
    const allItems = this.sections().flatMap(s => s.items);
    return allItems.filter(item => item.category === category);
  }

  /**
   * Refresh manifest (for development)
   */
  async refresh(): Promise<void> {
    this.loaded.set(false);
    this.error.set(null);
    await this.loadManifest();
  }
}
