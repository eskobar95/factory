#!/usr/bin/env bash
# Factory hook: typecheck after agent file edit (TypeScript files only)
# Exit 2 blocks the agent loop on failure (Cursor hooks contract)

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "${INPUT}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null || echo "")

if [[ -z "${FILE_PATH}" ]]; then
  exit 0
fi

case "${FILE_PATH}" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

if ! command -v pnpm >/dev/null 2>&1; then
  echo "Factory typecheck hook: pnpm not found" >&2
  exit 2
fi

if ! pnpm run typecheck --if-present 2>/dev/null; then
  if ! pnpm exec tsc --noEmit 2>&1; then
    echo "Typecheck failed. Fix errors before continuing." >&2
    exit 2
  fi
fi

exit 0
