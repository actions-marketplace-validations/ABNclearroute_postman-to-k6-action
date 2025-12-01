#!/usr/bin/env node

/**
 * Script to merge load profile options into k6 test script
 * Usage: node merge-k6-options.js <script-file> <stages-json> <thresholds-json> <profile-name>
 */

const fs = require('fs');
const path = require('path');

const scriptFile = process.argv[2];
const stagesJson = process.argv[3];
const thresholdsJson = process.argv[4];
const profileName = process.argv[5] || 'default';

if (!scriptFile || !fs.existsSync(scriptFile)) {
  console.error(`Error: Script file not found: ${scriptFile}`);
  process.exit(1);
}

if (!stagesJson || stagesJson === 'null' || stagesJson === '') {
  console.log('No profile configuration provided, keeping original script');
  process.exit(0);
}

let scriptContent = fs.readFileSync(scriptFile, 'utf8');

// Parse JSON strings (they come as escaped strings from bash)
let stages, thresholds;
try {
  stages = JSON.parse(stagesJson);
  thresholds = JSON.parse(thresholdsJson);
} catch (e) {
  // If parsing fails, try eval (less safe but handles bash-generated JSON)
  try {
    stages = eval(`(${stagesJson})`);
    thresholds = eval(`(${thresholdsJson})`);
  } catch (e2) {
    console.error('Error parsing stages/thresholds JSON:', e2.message);
    process.exit(1);
  }
}

// Generate options block
const optionsBlock = `// Load profile: ${profileName}
export const options = {
  stages: ${JSON.stringify(stages, null, 2)},
  thresholds: ${JSON.stringify(thresholds, null, 2)},
};`;

// Check if script already has options
const hasOptions = /export\s+(const|let|var)\s+options\s*=/.test(scriptContent);

if (hasOptions) {
  // Replace existing options block
  console.log('Replacing existing options in k6 script...');
  
  // More robust regex that handles nested objects properly
  // Match: export const/let/var options = { ... }; (with proper brace matching)
  let braceCount = 0;
  let startIndex = scriptContent.search(/export\s+(const|let|var)\s+options\s*=/);
  
  if (startIndex !== -1) {
    // Find where the options block ends
    let i = scriptContent.indexOf('{', startIndex);
    if (i !== -1) {
      braceCount = 1;
      i++;
      while (i < scriptContent.length && braceCount > 0) {
        if (scriptContent[i] === '{') braceCount++;
        if (scriptContent[i] === '}') braceCount--;
        i++;
        // Skip strings and comments
        if (scriptContent[i] === '"' || scriptContent[i] === "'") {
          const quote = scriptContent[i];
          i++;
          while (i < scriptContent.length && scriptContent[i] !== quote) {
            if (scriptContent[i] === '\\') i++; // Skip escape chars
            i++;
          }
        }
      }
      
      // Find the end of the statement (semicolon or newline)
      while (i < scriptContent.length && scriptContent[i] !== ';' && scriptContent[i] !== '\n') {
        i++;
      }
      if (scriptContent[i] === ';') i++;
      
      // Replace the options block
      const before = scriptContent.substring(0, startIndex);
      const after = scriptContent.substring(i).replace(/^\s*\n?/, '\n');
      scriptContent = before + optionsBlock + after;
    }
  }
} else {
  // Insert options after imports
  console.log('Adding options to k6 script...');
  
  // Find the last import or require statement
  const importLines = scriptContent.split('\n');
  let lastImportIndex = -1;
  
  for (let i = 0; i < importLines.length; i++) {
    if (/^(import|const.*require|export.*from)/.test(importLines[i])) {
      lastImportIndex = i;
    }
  }
  
  if (lastImportIndex >= 0) {
    // Insert after last import
    importLines.splice(lastImportIndex + 1, 0, '', optionsBlock);
    scriptContent = importLines.join('\n');
  } else {
    // Insert at the beginning
    scriptContent = optionsBlock + '\n\n' + scriptContent;
  }
}

// Write back to file
fs.writeFileSync(scriptFile, scriptContent, 'utf8');
console.log(`Successfully merged load profile options into ${scriptFile}`);

