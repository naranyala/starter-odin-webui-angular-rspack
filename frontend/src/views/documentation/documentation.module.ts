/**
 * Documentation Module
 * 
 * Central documentation viewer for the application
 * Displays all markdown documentation as Angular components
 */

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MarkdownModule } from 'ngx-markdown';
import { DocumentationViewerComponent } from './documentation-viewer.component';
import { DocumentationNavComponent } from './documentation-nav.component';
import { DocumentationContentComponent } from './documentation-content.component';

@NgModule({
  imports: [
    CommonModule,
    MarkdownModule.forChild(),
    DocumentationViewerComponent,
    DocumentationNavComponent,
    DocumentationContentComponent,
  ],
  exports: [
    DocumentationViewerComponent,
  ],
})
export class DocumentationModule {}
