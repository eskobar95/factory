#!/usr/bin/env bash
# Factory hook: npm audit after package.json or pnpm-lock.yaml changes
# Logs findings to .ai/logs/diary.md (does not block by default)

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "${INPUT}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null || echo "")

case "${FILE_PATH}" in
  *package.json|*pnpm-lock.yaml|*package-lock.json) ;;
  *) exit 0 ;;
esac

DIARY=".ai/logs/diary.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

run_audit() {
  if command -v pnpm >/dev/null 2>&1 && pnpm audit --audit-level=high 2>&1; then
    return 0
  fi
  if command -v npm >/dev/null 2>&1; then
    npm audit --audit-level=high 2>&1 || true
  fi
}

OUTPUT=$(run_audit 2>&1 | head -40 || true)

mkdir -p "$(dirname "${DIARY}")"
{
  echo ""
  echo "## Security audit — ${TIMESTAMP}"
  echo ""
  echo "Triggered by edit: \`${FILE_PATH}\`"
  echo ""
  echo '```'
  echo "${OUTPUT}"
  echo '```'
} >> "${DIARY}"

exit 0
