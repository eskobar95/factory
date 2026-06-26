#!/usr/bin/env bash
# Migration 001 — scaffold Factory Pi model routing in existing projects
set -euo pipefail

PROJECT_ROOT="${1:?project root required}"
KIT="${2:?kit path required}"

echo "    migration 001: Pi model routing"
bash "${KIT}/scripts/sync-pi-config.sh" 2>&1 | sed 's/^/      /'
