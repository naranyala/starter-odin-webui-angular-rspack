#!/usr/bin/env node

/**
 * Documentation Manifest Generator
 * 
 * Scans the docs directory for markdown files and generates
 * a manifest.json file for dynamic menu generation.
 * 
 * Usage: node scripts/generate-docs-manifest.js
 */

const fs = require('fs');
const path = require('path');

// Configuration
const DOCS_DIR = path.join(__dirname, '..', 'src', 'assets', 'docs');
const OUTPUT_FILE = path.join(DOCS_DIR, 'manifest.json');

// Section configuration
const SECTIONS_CONFIG = {
  quickstart: {
    title: 'Quick Start',
    icon: '🚀',
    order: 1,
    patterns: ['README.md', 'QUICKSTART.md'],
  },
  architecture: {
    title: 'Architecture',
    icon: '🏗️',
    order: 2,
    patterns: ['ARCHITECTURAL_DECISIONS.md', 'CHANGELOG.md'],
  },
  backend: {
    title: 'Backend',
    icon: '🔙',
    order: 3,
    patterns: ['backend/*.md'],
  },
  frontend: {
    title: 'Frontend',
    icon: '🎨',
    order: 4,
    patterns: ['frontend/*.md'],
  },
  guides: {
    title: 'Guides',
    icon: '📚',
    order: 5,
    patterns: ['guides/*.md'],
  },
  security: {
    title: 'Security',
    icon: '🔒',
    order: 6,
    patterns: ['SECURITY*.md'],
  },
};

/**
 * Convert filename to title
 * Example: duckdb-integration.md → DuckDB Integration
 */
function filenameToTitle(filename) {
  return filename
    .replace('.md', '')
    .split('-')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

/**
 * Generate unique ID from filename
 * Example: duckdb-integration.md → duckdb-integration
 */
function filenameToId(filename) {
  return filename.replace('.md', '').toLowerCase();
}

/**
 * Scan directory for markdown files
 */
function scanDirectory(dir, relativePath = '') {
  const files = [];
  
  if (!fs.existsSync(dir)) {
    console.warn(`Warning: Directory not found: ${dir}`);
    return files;
  }

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const relPath = path.join(relativePath, entry.name);

    if (entry.isDirectory()) {
      // Skip node_modules and hidden directories
      if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
        files.push(...scanDirectory(fullPath, relPath));
      }
    } else if (entry.isFile() && entry.name.endsWith('.md') && entry.name !== 'manifest.json') {
      files.push({
        name: entry.name,
        path: relPath,
        fullPath: fullPath,
        category: relativePath.split(path.sep)[0] || 'root',
      });
    }
  }

  return files;
}

/**
 * Generate manifest from scanned files
 */
function generateManifest(files) {
  const sections = [];

  // Process each section configuration
  for (const [sectionId, config] of Object.entries(SECTIONS_CONFIG)) {
    const sectionItems = [];

    for (const pattern of config.patterns) {
      if (pattern.includes('/')) {
        // Directory pattern (e.g., 'backend/*.md')
        const [dir, filePattern] = pattern.split('/');
        const matchingFiles = files.filter(f => {
          return f.category === dir && 
                 (filePattern === '*.md' || f.name === filePattern);
        });

        for (const file of matchingFiles) {
          sectionItems.push({
            id: filenameToId(file.name),
            title: filenameToTitle(file.name),
            path: `assets/docs/${file.path}`,
            category: sectionId,
            order: sectionItems.length + 1,
          });
        }
      } else {
        // Root file pattern (e.g., 'README.md')
        const matchingFile = files.find(f => 
          f.category === 'root' && f.name === pattern
        );

        if (matchingFile) {
          sectionItems.push({
            id: filenameToId(matchingFile.name),
            title: filenameToTitle(matchingFile.name),
            path: `assets/docs/${matchingFile.name}`,
            category: sectionId,
            order: sectionItems.length + 1,
          });
        }
      }
    }

    // Only add section if it has items
    if (sectionItems.length > 0) {
      sections.push({
        id: sectionId,
        title: config.title,
        icon: config.icon,
        order: config.order,
        items: sectionItems.sort((a, b) => a.order - b.order),
      });
    }
  }

  return {
    version: '1.0.0',
    generated: new Date().toISOString(),
    sections: sections.sort((a, b) => a.order - b.order),
    stats: {
      totalSections: sections.length,
      totalItems: sections.reduce((sum, s) => sum + s.items.length, 0),
    },
  };
}

/**
 * Main function
 */
function main() {
  console.log('📚 Documentation Manifest Generator');
  console.log('====================================\n');

  // Check if docs directory exists
  if (!fs.existsSync(DOCS_DIR)) {
    console.error(`Error: Docs directory not found: ${DOCS_DIR}`);
    process.exit(1);
  }

  // Scan for markdown files
  console.log('🔍 Scanning for markdown files...');
  const files = scanDirectory(DOCS_DIR);
  console.log(`   Found ${files.length} markdown files\n`);

  // Generate manifest
  console.log('📝 Generating manifest...');
  const manifest = generateManifest(files);
  console.log(`   Generated ${manifest.sections.length} sections`);
  console.log(`   Total ${manifest.stats.totalItems} documentation items\n`);

  // Write manifest
  console.log('💾 Writing manifest file...');
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(manifest, null, 2));
  console.log(`   Saved to: ${OUTPUT_FILE}\n`);

  // Print summary
  console.log('📋 Manifest Summary:');
  console.log('─────────────────────');
  for (const section of manifest.sections) {
    console.log(`   ${section.icon} ${section.title}: ${section.items.length} items`);
    for (const item of section.items) {
      console.log(`      - ${item.title}`);
    }
  }

  console.log('\n✅ Manifest generation complete!\n');
}

// Run main function
main();
