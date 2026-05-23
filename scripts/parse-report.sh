#!/usr/bin/env bash
# Extracts top findings from a REPORT.md as a compact JSON array.
# Usage: parse-report.sh /path/to/REPORT.md [--top N]
set -euo pipefail

REPORT="${1:?usage: parse-report.sh <path-to-REPORT.md> [--top N]}"
TOP="${3:-10}"

node - "$REPORT" "$TOP" <<'EOF'
const fs = require('fs');
const [, , path, topArg] = process.argv;
const top = parseInt(topArg || '10', 10);
const text = fs.readFileSync(path, 'utf8');

const findings = [];
const sections = text.split(/\n### /);
let curSev = null;
for (const section of sections) {
  const head = section.split('\n', 1)[0];
  const sev = head.match(/^(Critical|High|Medium|Low|Info)/i);
  if (sev) curSev = sev[1].toLowerCase();
  const re = /####\s+([^\n]+)\n\n([\s\S]+?)(?=\n#### |\n## |\n---|\Z)/g;
  let m;
  while ((m = re.exec(section)) !== null) {
    findings.push({
      severity: curSev || 'info',
      title: m[1].trim(),
      body: m[2].trim().slice(0, 800),
    });
  }
}

const order = { critical: 0, high: 1, medium: 2, low: 3, info: 4 };
findings.sort((a, b) => order[a.severity] - order[b.severity]);
console.log(JSON.stringify(findings.slice(0, top), null, 2));
EOF
