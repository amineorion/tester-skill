#!/usr/bin/env bash
set -euo pipefail
API_URL="${TESTER_API_URL:-http://localhost:4000}"
if curl -fsS "$API_URL/health" >/dev/null; then
  echo "API ok at $API_URL"
  exit 0
fi
cat <<EOM
API not reachable at $API_URL.

Start it locally:
  cd ~/workspaces/tester
  pnpm db:up          # starts MongoDB on :27117
  pnpm dev:api        # starts the API on :4000
EOM
exit 1
