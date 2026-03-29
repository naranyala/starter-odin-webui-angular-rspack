/**
 * Documentation Content Component
 * 
 * Displays markdown documentation content
 */

import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MarkdownModule } from 'ngx-markdown';

@Component({
  selector: 'app-documentation-content',
  standalone: true,
  imports: [CommonModule, MarkdownModule],
  template: `
    <div class="content-container">
      @if (isLoading) {
        <div class="loading-state">
          <div class="loading-spinner"></div>
          <p>Loading documentation...</p>
        </div>
      } @else {
        <div class="content-wrapper">
          <header class="content-header">
            <h1 class="content-title">{{ title }}</h1>
          </header>
          
          <article class="markdown-body">
            <markdown
              [data]="content"
              [clipboard]="true"
              [lineHighlight]="true"
              [lineNumbers]="true">
            </markdown>
          </article>
        </div>
      }
    </div>
  `,
  styles: [`
    .content-container {
      height: 100%;
      overflow-y: auto;
      background: #0f172a;
    }

    .loading-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100%;
      color: #94a3b8;
    }

    .loading-spinner {
      width: 40px;
      height: 40px;
      border: 3px solid rgba(59, 130, 246, 0.3);
      border-top-color: #3b82f6;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-bottom: 16px;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .content-wrapper {
      max-width: 1200px;
      margin: 0 auto;
      padding: 40px 32px;
    }

    .content-header {
      margin-bottom: 32px;
      padding-bottom: 24px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.1);
    }

    .content-title {
      margin: 0;
      font-size: 32px;
      font-weight: 700;
      color: #fff;
    }

    .markdown-body {
      color: #e2e8f0;
      line-height: 1.7;
    }

    /* Markdown Styles */
    .markdown-body ::ng-deep {
      /* Headings */
      h1 {
        font-size: 2.5rem;
        font-weight: 700;
        color: #fff;
        margin: 0 0 1.5rem;
        padding-bottom: 0.75rem;
        border-bottom: 1px solid rgba(148, 163, 184, 0.2);
      }

      h2 {
        font-size: 2rem;
        font-weight: 600;
        color: #f1f5f9;
        margin: 2.5rem 0 1.5rem;
        padding-bottom: 0.5rem;
        border-bottom: 1px solid rgba(148, 163, 184, 0.15);
      }

      h3 {
        font-size: 1.5rem;
        font-weight: 600;
        color: #e2e8f0;
        margin: 2rem 0 1rem;
      }

      h4 {
        font-size: 1.25rem;
        font-weight: 600;
        color: #cbd5e1;
        margin: 1.5rem 0 0.75rem;
      }

      /* Paragraphs */
      p {
        margin: 0 0 1.25rem;
      }

      /* Lists */
      ul, ol {
        margin: 0 0 1.25rem;
        padding-left: 2rem;
      }

      li {
        margin-bottom: 0.5rem;
      }

      li > ul, li > ol {
        margin-top: 0.5rem;
        margin-bottom: 0;
      }

      /* Links */
      a {
        color: #38bdf8;
        text-decoration: none;
        transition: color 0.2s;
      }

      a:hover {
        color: #7dd3fc;
        text-decoration: underline;
      }

      /* Code */
      code {
        background: rgba(30, 41, 59, 0.8);
        padding: 0.2rem 0.4rem;
        border-radius: 4px;
        font-family: 'Fira Code', 'Consolas', monospace;
        font-size: 0.9em;
        color: #38bdf8;
      }

      pre {
        background: #1e293b;
        border-radius: 8px;
        padding: 1.5rem;
        overflow-x: auto;
        margin: 0 0 1.5rem;
        border: 1px solid rgba(148, 163, 184, 0.1);
      }

      pre code {
        background: transparent;
        padding: 0;
        color: #e2e8f0;
        font-size: 0.875rem;
        line-height: 1.6;
      }

      /* Blockquotes */
      blockquote {
        border-left: 4px solid #38bdf8;
        padding-left: 1.5rem;
        margin: 0 0 1.5rem;
        color: #94a3b8;
        font-style: italic;
      }

      /* Tables */
      table {
        width: 100%;
        border-collapse: collapse;
        margin: 0 0 1.5rem;
        background: rgba(30, 41, 59, 0.3);
        border-radius: 8px;
        overflow: hidden;
      }

      th {
        background: rgba(30, 41, 59, 0.8);
        padding: 0.75rem 1rem;
        text-align: left;
        font-weight: 600;
        color: #fff;
        border-bottom: 2px solid rgba(148, 163, 184, 0.2);
      }

      td {
        padding: 0.75rem 1rem;
        border-bottom: 1px solid rgba(148, 163, 184, 0.1);
        color: #e2e8f0;
      }

      tr:last-child td {
        border-bottom: none;
      }

      tr:hover {
        background: rgba(59, 130, 246, 0.05);
      }

      /* Horizontal rule */
      hr {
        border: none;
        border-top: 1px solid rgba(148, 163, 184, 0.2);
        margin: 2.5rem 0;
      }

      /* Images */
      img {
        max-width: 100%;
        border-radius: 8px;
        margin: 1.5rem 0;
      }

      /* Strong */
      strong {
        color: #fff;
        font-weight: 600;
      }

      /* Emphasis */
      em {
        color: #cbd5e1;
      }
    }

    /* Scrollbar styling */
    .content-container::-webkit-scrollbar {
      width: 8px;
    }

    .content-container::-webkit-scrollbar-track {
      background: rgba(15, 23, 42, 0.5);
    }

    .content-container::-webkit-scrollbar-thumb {
      background: rgba(148, 163, 184, 0.2);
      border-radius: 4px;
    }

    .content-container::-webkit-scrollbar-thumb:hover {
      background: rgba(148, 163, 184, 0.3);
    }
  `],
})
export class DocumentationContentComponent {
  @Input() content: string = '';
  @Input() title: string = '';
  @Input() isLoading: boolean = false;
}
