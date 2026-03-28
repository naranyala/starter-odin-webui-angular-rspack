/**
 * Postbuild Script for Angular + WebUI Integration
 * 
 * This script:
 * 1. Builds webui.js from TypeScript source if needed
 * 2. Copies webui.js to the Angular dist folder
 * 3. Patches index.html to include webui.js script tag
 * 4. Ensures proper integration with the Odin backend
 */

import { readFileSync, writeFileSync, copyFileSync, existsSync, mkdirSync } from 'fs';
import { join, resolve, dirname } from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

// Get directory name (ESM compatible)
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration
const FRONTEND_ROOT = resolve(__dirname, '..');
const PROJECT_ROOT = resolve(FRONTEND_ROOT, '..');
const DIST_ROOT = join(FRONTEND_ROOT, 'dist', 'browser');
const WEBUI_ROOT = join(PROJECT_ROOT, 'thirdparty', 'webui');
const WEBUI_BRIDGE = join(WEBUI_ROOT, 'bridge');
const WEBUI_JS_SOURCE = join(WEBUI_BRIDGE, 'webui.js');
const WEBUI_TS_SOURCE = join(WEBUI_BRIDGE, 'webui.ts');

console.log('🔧 Running postbuild script...');
console.log(`   Frontend root: ${FRONTEND_ROOT}`);
console.log(`   Dist folder: ${DIST_ROOT}`);

// Step 1: Build webui.js if it doesn't exist
function buildWebUI() {
  console.log('\n📦 Step 1: Checking webui.js...');
  
  if (!existsSync(WEBUI_JS_SOURCE)) {
    console.log('   webui.js not found, building from TypeScript source...');
    
    try {
      // Check if esbuild is available (try multiple paths)
      const esbuildPaths = [
        join(FRONTEND_ROOT, 'node_modules', '.bin', 'esbuild'),
        join(PROJECT_ROOT, 'node_modules', '.bin', 'esbuild'),
      ];
      
      let esbuildPath = esbuildPaths.find(p => existsSync(p));
      
      // Fallback to global esbuild
      if (!esbuildPath) {
        try {
          execSync('which esbuild', { stdio: 'pipe' });
          esbuildPath = 'esbuild';
        } catch {
          // Try bunx
          try {
            execSync('bunx esbuild --version', { stdio: 'pipe' });
            esbuildPath = 'bunx esbuild';
          } catch {
            console.error('   ❌ esbuild not found. Installing...');
            execSync('bun add -d esbuild', { cwd: FRONTEND_ROOT, stdio: 'inherit' });
            esbuildPath = join(FRONTEND_ROOT, 'node_modules', '.bin', 'esbuild');
          }
        }
      }
      
      console.log(`   Using esbuild: ${esbuildPath}`);
      
      // Build webui.js from TypeScript
      const cmd = typeof esbuildPath === 'string' && esbuildPath.includes(' ') 
        ? esbuildPath 
        : `"${esbuildPath}"`;
      
      execSync(
        `${cmd} --bundle --target="chrome90,firefox90,safari15" --format=esm --tree-shaking=false --minify-syntax --minify-whitespace --outdir="${WEBUI_BRIDGE}" "${WEBUI_TS_SOURCE}"`,
        { cwd: WEBUI_BRIDGE, stdio: 'inherit' }
      );
      
      console.log('   ✅ webui.js built successfully');
    } catch (error) {
      console.error('   ❌ Failed to build webui.js:', error.message);
      process.exit(1);
    }
  } else {
    console.log('   ✅ webui.js already exists');
  }
}

// Step 2: Copy webui.js to dist folder
function copyWebUI() {
  console.log('\n📋 Step 2: Copying webui.js to dist...');
  
  try {
    // Ensure dist folder exists
    if (!existsSync(DIST_ROOT)) {
      mkdirSync(DIST_ROOT, { recursive: true });
      console.log('   Created dist folder');
    }
    
    const destPath = join(DIST_ROOT, 'webui.js');
    copyFileSync(WEBUI_JS_SOURCE, destPath);
    console.log(`   ✅ webui.js copied to: ${destPath}`);
  } catch (error) {
    console.error('   ❌ Failed to copy webui.js:', error.message);
    process.exit(1);
  }
}

// Step 3: Patch index.html to include webui.js
function patchIndexHTML() {
  console.log('\n🔧 Step 3: Patching index.html...');
  
  const indexPath = join(DIST_ROOT, 'index.html');
  
  if (!existsSync(indexPath)) {
    console.error('   ❌ index.html not found in dist folder');
    process.exit(1);
  }
  
  try {
    let htmlContent = readFileSync(indexPath, 'utf-8');
    
    // Check if webui.js is already included
    if (htmlContent.includes('webui.js')) {
      console.log('   ✅ webui.js already included in index.html');
      return;
    }
    
    // Find the </head> tag and insert webui.js script before it
    const headCloseTag = '</head>';
    const webuiScript = '  <script src="webui.js"></script>\n';
    
    const headIndex = htmlContent.indexOf(headCloseTag);
    if (headIndex === -1) {
      console.error('   ❌ </head> tag not found in index.html');
      process.exit(1);
    }
    
    // Insert webui.js script before </head>
    htmlContent = 
      htmlContent.slice(0, headIndex) + 
      webuiScript + 
      htmlContent.slice(headIndex);
    
    writeFileSync(indexPath, htmlContent, 'utf-8');
    console.log('   ✅ index.html patched successfully');
    console.log('   Added: <script src="webui.js"></script>');
  } catch (error) {
    console.error('   ❌ Failed to patch index.html:', error.message);
    process.exit(1);
  }
}

// Step 4: Verify the integration
function verifyIntegration() {
  console.log('\n✅ Step 4: Verifying integration...');
  
  const indexPath = join(DIST_ROOT, 'index.html');
  const webuiPath = join(DIST_ROOT, 'webui.js');
  
  const checks = [
    { name: 'index.html exists', pass: existsSync(indexPath) },
    { name: 'webui.js exists', pass: existsSync(webuiPath) },
  ];
  
  if (existsSync(indexPath)) {
    const htmlContent = readFileSync(indexPath, 'utf-8');
    checks.push({ name: 'webui.js script tag in HTML', pass: htmlContent.includes('webui.js') });
  }
  
  let allPassed = true;
  for (const check of checks) {
    const status = check.pass ? '✅' : '❌';
    console.log(`   ${status} ${check.name}`);
    if (!check.pass) allPassed = false;
  }
  
  if (!allPassed) {
    console.error('\n❌ Some checks failed. Please review the errors above.');
    process.exit(1);
  }
  
  console.log('\n🎉 Postbuild completed successfully!');
  console.log('   The Angular build is now ready for WebUI integration.');
}

// Main execution
function main() {
  console.log('\n' + '='.repeat(60));
  console.log('  Angular + WebUI Postbuild Integration');
  console.log('='.repeat(60) + '\n');
  
  buildWebUI();
  copyWebUI();
  patchIndexHTML();
  verifyIntegration();
  
  console.log('\n' + '='.repeat(60));
  console.log('  Build Complete! Ready to run with Odin backend.');
  console.log('='.repeat(60) + '\n');
}

// Run
main();
