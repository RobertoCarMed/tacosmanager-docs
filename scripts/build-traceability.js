#!/usr/bin/env node
/**
 * SDD auto-traceability builder.
 *
 * Scans the repo and emits a coverage report:
 *   - REQ-IDs declared in specs/<feature>/spec.md
 *   - REQ-IDs tagged in specs/<feature>/acceptance.feature
 *   - REQ-IDs already listed in traceability.md
 *   - Orphans:
 *       * spec REQ not in traceability.md
 *       * traceability REQ not declared in any spec
 *       * Gherkin tag not declared in any spec
 *
 * Modes:
 *   node scripts/build-traceability.js report           # human-readable
 *   node scripts/build-traceability.js check            # exit 1 on orphans
 *   node scripts/build-traceability.js json > out.json  # machine-readable
 *
 * Note: this script intentionally has zero npm dependencies. It runs in any
 * GitHub Actions runner with stock Node.
 *
 * Test-file extraction (backend/mobile) is performed once those repos adopt
 * the "@REQ-NNNN" comment convention documented in CLAUDE.md. For now the
 * script focuses on docs-repo authoritative sources (specs + traceability.md).
 */

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = process.env.SDD_ROOT || process.cwd();
const REQ_PATTERN = /\bREQ-\d{4}\b/g;
const SPEC_HEADER_PATTERN = /^###\s+(REQ-\d{4})\b/gm;
const GHERKIN_TAG_PATTERN = /@(REQ-\d{4})\b/g;

function walk(dir, predicate) {
  const out = [];
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === '.git') continue;
      out.push(...walk(full, predicate));
    } else if (predicate(full)) {
      out.push(full);
    }
  }
  return out;
}

function read(file) {
  return fs.readFileSync(file, 'utf8');
}

function uniqueMatches(text, pattern) {
  const set = new Set();
  for (const m of text.matchAll(pattern)) set.add(m[1] || m[0]);
  return set;
}

function collectSpecReqs() {
  const specs = walk(path.join(ROOT, 'specs'), (f) => f.endsWith('/spec.md'));
  const result = new Map(); // REQ-ID -> spec path
  const bySpec = new Map(); // spec path -> Set<REQ-ID>
  for (const file of specs) {
    const text = read(file);
    const ids = uniqueMatches(text, SPEC_HEADER_PATTERN);
    const rel = path.relative(ROOT, file);
    bySpec.set(rel, ids);
    for (const id of ids) {
      if (result.has(id) && result.get(id) !== rel) {
        console.warn(`WARN: ${id} declared in multiple specs: ${result.get(id)} and ${rel}`);
      }
      result.set(id, rel);
    }
  }
  return { byReq: result, bySpec };
}

function collectGherkinTags() {
  const files = walk(path.join(ROOT, 'specs'), (f) => f.endsWith('.feature'));
  const result = new Map(); // REQ-ID -> Set<feature paths>
  for (const file of files) {
    const text = read(file);
    const ids = uniqueMatches(text, GHERKIN_TAG_PATTERN);
    const rel = path.relative(ROOT, file);
    for (const id of ids) {
      if (!result.has(id)) result.set(id, new Set());
      result.get(id).add(rel);
    }
  }
  return result;
}

function collectTraceabilityReqs() {
  const file = path.join(ROOT, 'traceability.md');
  if (!fs.existsSync(file)) return new Set();
  const text = read(file);
  const inMatrix = text.split(/^##\s+Matriz\s*$/m)[1] || '';
  const stopped = inMatrix.split(/^##\s+/m)[0];
  return uniqueMatches(stopped, REQ_PATTERN);
}

function computeReport() {
  const specInfo = collectSpecReqs();
  const gherkin = collectGherkinTags();
  const traceability = collectTraceabilityReqs();

  const specReqs = new Set(specInfo.byReq.keys());
  const gherkinReqs = new Set(gherkin.keys());

  const reqInSpecNotInTrace = [...specReqs].filter((id) => !traceability.has(id)).sort();
  const reqInTraceNotInSpec = [...traceability].filter((id) => !specReqs.has(id)).sort();
  const reqGherkinNotInSpec = [...gherkinReqs].filter((id) => !specReqs.has(id)).sort();
  const reqSpecNotInGherkin = [...specReqs].filter((id) => !gherkinReqs.has(id)).sort();

  return {
    counts: {
      specs: specInfo.bySpec.size,
      reqInSpecs: specReqs.size,
      reqInTraceability: traceability.size,
      reqInGherkin: gherkinReqs.size,
    },
    orphans: {
      inSpecNotInTraceability: reqInSpecNotInTrace,
      inTraceabilityNotInSpec: reqInTraceNotInSpec,
      inGherkinNotInSpec: reqGherkinNotInSpec,
      inSpecNotInGherkin: reqSpecNotInGherkin,
    },
  };
}

function printReport(report) {
  const lines = [];
  lines.push('SDD Traceability Report');
  lines.push('=======================');
  lines.push(`Specs scanned:           ${report.counts.specs}`);
  lines.push(`REQ-IDs in specs:        ${report.counts.reqInSpecs}`);
  lines.push(`REQ-IDs in traceability: ${report.counts.reqInTraceability}`);
  lines.push(`REQ-IDs in Gherkin tags: ${report.counts.reqInGherkin}`);
  lines.push('');
  const sections = [
    ['REQ in spec but missing from traceability.md', report.orphans.inSpecNotInTraceability],
    ['REQ in traceability.md but no spec', report.orphans.inTraceabilityNotInSpec],
    ['REQ tagged in Gherkin but no spec', report.orphans.inGherkinNotInSpec],
    ['REQ in spec but no Gherkin tag', report.orphans.inSpecNotInGherkin],
  ];
  for (const [label, ids] of sections) {
    lines.push(`${label}: ${ids.length}`);
    for (const id of ids) lines.push(`  - ${id}`);
  }
  return lines.join('\n');
}

function totalOrphans(report) {
  return Object.values(report.orphans).reduce((acc, arr) => acc + arr.length, 0);
}

function main() {
  const mode = process.argv[2] || 'report';
  const report = computeReport();
  if (mode === 'json') {
    process.stdout.write(JSON.stringify(report, null, 2) + '\n');
    return 0;
  }
  if (mode === 'report') {
    process.stdout.write(printReport(report) + '\n');
    return 0;
  }
  if (mode === 'check') {
    process.stdout.write(printReport(report) + '\n');
    if (totalOrphans(report) > 0) {
      console.error('\nFAIL: orphans detected. See report above.');
      return 1;
    }
    console.log('\nOK: no orphans.');
    return 0;
  }
  console.error(`Unknown mode: ${mode}. Use: report | check | json`);
  return 2;
}

process.exit(main());
