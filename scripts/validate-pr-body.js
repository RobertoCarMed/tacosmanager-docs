#!/usr/bin/env node
/**
 * SDD traceability gate.
 *
 * Reads a PR body from PR_BODY env var (or stdin) and validates it references
 * either a REQ-NNNN, a spec path, or carries the docs-only escape-hatch label.
 *
 * Used by .github/workflows/sdd-traceability-gate.yml. Designed to run with
 * zero npm dependencies so it works in any GitHub Actions runner.
 *
 * Exit codes:
 *   0 — PR body is valid
 *   1 — PR body fails validation; reason printed to stdout
 */

'use strict';

const fs = require('fs');
const path = require('path');

const REQ_PATTERN = /\bREQ-\d{4}\b/g;
const CLOSES_PATTERN = /\b(?:Closes|Closes:|Fixes|Resolves)\s+REQ-\d{4}\b/i;
const SPEC_PATTERN = /\bspecs\/[a-z0-9][a-z0-9-]*\/spec\.md\b/;
const ALLOWED_LABELS = new Set(['docs-only', 'chore', 'release', 'sdd-bootstrap']);

function readBody() {
  if (process.env.PR_BODY !== undefined) return process.env.PR_BODY;
  return fs.readFileSync(0, 'utf8');
}

function readLabels() {
  const raw = process.env.PR_LABELS || '';
  return raw
    .split(',')
    .map((l) => l.trim().toLowerCase())
    .filter(Boolean);
}

function repoRoot() {
  return process.env.GITHUB_WORKSPACE || process.cwd();
}

function loadTraceabilityReqIds() {
  const file = path.join(repoRoot(), 'traceability.md');
  if (!fs.existsSync(file)) return null;
  const content = fs.readFileSync(file, 'utf8');
  const ids = new Set();
  for (const match of content.matchAll(REQ_PATTERN)) ids.add(match[0]);
  return ids;
}

function specExists(specPath) {
  return fs.existsSync(path.join(repoRoot(), specPath));
}

function main() {
  const body = readBody();
  const labels = readLabels();

  for (const label of labels) {
    if (ALLOWED_LABELS.has(label)) {
      console.log(`OK: label "${label}" exempts this PR from traceability gate.`);
      return 0;
    }
  }

  const reqMatches = [...body.matchAll(REQ_PATTERN)].map((m) => m[0]);
  const specMatch = body.match(SPEC_PATTERN);
  const hasCloses = CLOSES_PATTERN.test(body);

  if (reqMatches.length === 0 && !specMatch) {
    console.error(
      [
        'FAIL: PR body does not reference any REQ-NNNN or specs/<feature>/spec.md.',
        '',
        'Fix one of:',
        '  - Add "Closes REQ-NNNN" listing the requirement(s) covered.',
        '  - Add "Spec: specs/<feature>/spec.md" if the PR works on a spec.',
        '  - Apply the label "docs-only" (or chore/release/sdd-bootstrap) for changes',
        '    that genuinely have no requirement to trace.',
        '',
        'See .github/PULL_REQUEST_TEMPLATE.md and ADR-0008 for context.',
      ].join('\n'),
    );
    return 1;
  }

  const traceabilityIds = loadTraceabilityReqIds();
  if (traceabilityIds) {
    const unknown = reqMatches.filter((id) => !traceabilityIds.has(id));
    if (unknown.length > 0) {
      console.error(
        [
          `FAIL: REQ-IDs not found in traceability.md: ${[...new Set(unknown)].join(', ')}`,
          '',
          'Either add the row to traceability.md as part of this PR, or fix the ID.',
        ].join('\n'),
      );
      return 1;
    }
  }

  if (specMatch && !specExists(specMatch[0])) {
    console.error(`FAIL: referenced spec "${specMatch[0]}" does not exist in the repo.`);
    return 1;
  }

  if (reqMatches.length > 0 && !hasCloses) {
    console.warn(
      'WARN: REQ-IDs mentioned but no "Closes REQ-NNNN" found. Consider using the canonical form.',
    );
  }

  const summary = [];
  if (reqMatches.length) summary.push(`REQ-IDs: ${[...new Set(reqMatches)].join(', ')}`);
  if (specMatch) summary.push(`Spec: ${specMatch[0]}`);
  console.log(`OK: ${summary.join(' | ')}`);
  return 0;
}

process.exit(main());
