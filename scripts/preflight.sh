#!/usr/bin/env bash
# Preflight check for the `tester` skill. Exits non-zero with a fix-it hint if anything is missing.
set -u

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
ok()   { printf "${GREEN}✓${NC} %s\n" "$1"; }
fail() { printf "${RED}✖${NC} %s\n  ${YELLOW}fix:${NC} %s\n" "$1" "$2"; FAILED=1; }

FAILED=0

# 1) Find the CLI
TESTER_BIN="${TESTER_BIN:-}"
if [[ -z "$TESTER_BIN" ]]; then
  if command -v tester >/dev/null 2>&1; then
    TESTER_BIN="$(command -v tester)"
  elif [[ -x "$HOME/workspaces/tester/apps/cli/dist/index.js" ]]; then
    TESTER_BIN="node $HOME/workspaces/tester/apps/cli/dist/index.js"
  fi
fi

if [[ -z "$TESTER_BIN" ]]; then
  fail "tester CLI not found" "cd ~/workspaces/tester && pnpm install && pnpm --filter @tester/cli build"
else
  ok "tester CLI: $TESTER_BIN"
fi

# 2) API reachable
API_URL="${TESTER_API_URL:-http://localhost:4000}"
if curl -fsS "$API_URL/health" >/dev/null 2>&1; then
  ok "API reachable at $API_URL"
else
  fail "API not reachable at $API_URL" "cd ~/workspaces/tester && pnpm db:up && pnpm dev:api"
fi

# 3) MongoDB reachable (via the API, which would refuse health if mongo were truly required, but we still hint)
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^tester-mongo$'; then
  ok "MongoDB container running"
else
  printf "${YELLOW}⚠${NC} tester-mongo container not running (you might be using an external Mongo — that's fine).\n"
fi

# 4) Playwright chromium installed
if [[ -d "$HOME/Library/Caches/ms-playwright" ]] || [[ -d "$HOME/.cache/ms-playwright" ]]; then
  ok "Playwright browsers installed"
else
  fail "Playwright Chromium not installed" "cd ~/workspaces/tester && pnpm --filter @tester/cli exec playwright install chromium"
fi

if [[ $FAILED -eq 1 ]]; then
  printf "\n${RED}Preflight failed.${NC} Resolve the items above before running tester.\n"
  exit 1
fi
printf "\n${GREEN}Preflight OK.${NC} You can now run: tester init <url> && tester run --url <url>\n"
