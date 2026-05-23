#!/usr/bin/env bash
# Thin wrapper. Locates the `tester` CLI and forwards args.
# Adds non-CLI subcommands: status, learnings, save-learnings, signin, share.
set -euo pipefail

API_URL="${TESTER_API_URL:-http://localhost:4000}"
API_KEY="${TESTER_API_KEY:-dev-local-key-change-me}"
AUTH_FILE="$HOME/.tester/auth.json"

resolve_cli() {
  if command -v tester >/dev/null 2>&1; then
    echo "tester"
  elif [[ -x "$HOME/workspaces/tester/tester-cli/dist/index.js" ]]; then
    echo "node $HOME/workspaces/tester/tester-cli/dist/index.js"
  elif [[ -x "$HOME/workspaces/tester/apps/cli/dist/index.js" ]]; then
    # back-compat for pre-restructure layout
    echo "node $HOME/workspaces/tester/apps/cli/dist/index.js"
  else
    echo "(missing)"
  fi
}

CLI="$(resolve_cli)"
if [[ "$CLI" == "(missing)" ]]; then
  echo "tester CLI not found. Run ./scripts/preflight.sh for fix-it instructions." >&2
  exit 2
fi

# Pull the user bearer token from ~/.tester/auth.json if present.
user_token() {
  if [[ -f "$AUTH_FILE" ]]; then
    node -e "try { const j = require('$AUTH_FILE'); if (j.token) process.stdout.write(j.token); } catch {}" 2>/dev/null
  fi
}

auth_headers() {
  local t
  t="$(user_token)"
  if [[ -n "$t" ]]; then
    echo "-H 'authorization: Bearer $t'"
  else
    echo "-H 'x-api-key: $API_KEY'"
  fi
}

project_key_of() {
  node -e "const {createHash}=require('crypto');const u=new URL(process.argv[1]);u.hash='';u.search='';let p=u.pathname;if(p.length>1&&p.endsWith('/'))p=p.slice(0,-1);u.pathname=p;console.log(createHash('sha256').update(u.toString()).digest('hex').slice(0,24));" "$1"
}

case "${1:-}" in
  status)
    URL="${2:?status requires <url>}"
    PROJECT_KEY="$(project_key_of "$URL")"
    HEADERS=$(auth_headers)
    eval curl -fsS $HEADERS "$API_URL/v1/projects/$PROJECT_KEY" || { echo "(not registered)"; exit 1; }
    ;;
  learnings)
    URL="${2:?learnings requires <url>}"
    PROJECT_KEY="$(project_key_of "$URL")"
    HEADERS=$(auth_headers)
    eval curl -fsS $HEADERS "$API_URL/v1/learnings/$PROJECT_KEY" || { echo "(no learnings yet)"; exit 0; }
    ;;
  save-learnings)
    URL="${2:?save-learnings requires <url>}"
    shift 2
    PROJECT_KEY="$(project_key_of "$URL")"
    # accept --auth-script <path> --seeds <comma-list> --notable-selectors <json>
    AUTH_SCRIPT=""
    SEEDS=""
    SELECTORS="{}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --auth-script) AUTH_SCRIPT="$2"; shift 2 ;;
        --seeds) SEEDS="$2"; shift 2 ;;
        --notable-selectors) SELECTORS="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    ORIGIN="$(node -e "console.log(new URL(process.argv[1]).origin)" "$URL")"
    NAME="$(node -e "console.log(new URL(process.argv[1]).hostname)" "$URL")"
    SEED_ARR=$(node -e "console.log(JSON.stringify((process.argv[1]||'').split(',').filter(Boolean)))" "$SEEDS")
    BODY=$(node -e "console.log(JSON.stringify({origin:process.argv[1],name:process.argv[2],authScript:process.argv[3]||undefined,seedPaths:JSON.parse(process.argv[4]),notableSelectors:JSON.parse(process.argv[5])}))" "$ORIGIN" "$NAME" "$AUTH_SCRIPT" "$SEED_ARR" "$SELECTORS")
    HEADERS=$(auth_headers)
    eval curl -fsS -X PUT $HEADERS -H "'content-type: application/json'" -d "'$BODY'" "$API_URL/v1/learnings/$PROJECT_KEY"
    ;;
  signin)
    EMAIL="${2:?signin requires <email>}"
    mkdir -p "$(dirname "$AUTH_FILE")"
    echo "Requesting code for $EMAIL ..."
    curl -fsS -X POST -H "content-type: application/json" -d "{\"email\":\"$EMAIL\"}" "$API_URL/v1/auth/request" >/dev/null || { echo "request failed"; exit 1; }
    read -r -p "Code (check the server log or your inbox): " CODE
    RESP=$(curl -fsS -X POST -H "content-type: application/json" -d "{\"email\":\"$EMAIL\",\"code\":\"$CODE\",\"userAgent\":\"tester-cli\"}" "$API_URL/v1/auth/verify") || { echo "verify failed"; exit 1; }
    echo "$RESP" > "$AUTH_FILE"
    chmod 600 "$AUTH_FILE"
    echo "Signed in. Token stored at $AUTH_FILE"
    ;;
  share)
    URL="${2:?share requires <url>}"
    RUN_ID="${3:-}"
    PROJECT_KEY="$(project_key_of "$URL")"
    if [[ -z "$RUN_ID" ]]; then
      HEADERS=$(auth_headers)
      RUN_ID=$(eval curl -fsS $HEADERS "$API_URL/v1/runs?projectKey=$PROJECT_KEY" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{const j=JSON.parse(d);if(j.items?.[0])process.stdout.write(j.items[0].runId);})")
    fi
    HEADERS=$(auth_headers)
    BODY="{\"projectKey\":\"$PROJECT_KEY\",\"runId\":\"$RUN_ID\",\"expiresInDays\":30}"
    eval curl -fsS -X POST $HEADERS -H "'content-type: application/json'" -d "'$BODY'" "$API_URL/v1/report/share"
    ;;
  api-health)
    curl -fsS "$API_URL/health"
    ;;
  init|run|report|auth|list|sink|*)
    exec $CLI "$@"
    ;;
esac
