#!/usr/bin/env bash
# Factory 2.0 update — pull latest kit and re-copy .cursor/ files
# Run from project root: .factory/kit/update.sh

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${PROJECT_ROOT}"

FACTORY_KIT=".factory/kit"
FACTORY_WS=".factory"

if [[ ! -f "${FACTORY_KIT}/install.sh" ]]; then
  echo "Error: Factory kit not found. Run install.sh first."
  exit 1
fi

echo "==> Factory 2.0 update (project: ${PROJECT_ROOT})"
echo "    Kit: ${FACTORY_KIT}"

# ── 1. Pull latest submodule ──────────────────────────────────────────────────
BEFORE=$(git -C "${FACTORY_KIT}" rev-parse HEAD 2>/dev/null || true)
git submodule update --init --remote --merge "${FACTORY_KIT}" 2>/dev/null || \
  git submodule update --remote --merge "${FACTORY_KIT}"
AFTER=$(git -C "${FACTORY_KIT}" rev-parse HEAD 2>/dev/null || true)

if [[ "${BEFORE}" == "${AFTER}" ]]; then
  echo "    Kit already up to date (${AFTER:0:8})"
else
  echo "    Kit updated: ${BEFORE:0:8} → ${AFTER:0:8}"
  git -C "${FACTORY_KIT}" log --oneline "${BEFORE}..${AFTER}" 2>/dev/null | sed 's/^/    /' || true
fi

# ── 2. Re-copy kit-owned .cursor/ files (overwrite) ──────────────────────────
echo "==> Re-copying kit files to .cursor/"

mkdir -p .cursor/rules .cursor/commands/planning .cursor/commands/harness \
         .cursor/commands/productivity .cursor/hooks .cursor/skills/factory

recopy_kit_dir() {
  local src="${FACTORY_KIT}/$1"
  local dest=".cursor/$1"
  if [[ ! -d "${src}" ]]; then
    echo "    Warning: ${FACTORY_KIT}/$1 missing, skipping"
    return
  fi
  cp -r "${src}/." "${dest}/"
  echo "    .cursor/$1 updated"
}

recopy_kit_dir "rules"
recopy_kit_dir "commands"
recopy_kit_dir "hooks"

# Kit skills → .cursor/skills/factory/
cp -r "${FACTORY_KIT}/skills/." ".cursor/skills/factory/"
echo "    .cursor/skills/factory/ updated"

for script in .cursor/hooks/*.sh; do
  [[ -f "${script}" ]] && chmod +x "${script}"
done

# Sync Pi model routing if kit templates exist
if [[ -f "${FACTORY_KIT}/scripts/sync-pi-config.sh" ]]; then
  echo "==> Syncing Pi model routing..."
  bash "${FACTORY_KIT}/scripts/sync-pi-config.sh" 2>&1 | sed 's/^/    /' || true
fi

# Ensure pi-harness MCP server is present in .cursor/mcp.json
MCP_FILE=".cursor/mcp.json"
KIT_MCP="${FACTORY_KIT}/templates/mcp.json"
if [[ -f "${KIT_MCP}" ]]; then
  if [[ ! -f "${MCP_FILE}" ]]; then
    cp "${KIT_MCP}" "${MCP_FILE}"
    echo "    created ${MCP_FILE}"
  elif ! grep -q '"pi-harness"' "${MCP_FILE}" 2>/dev/null; then
    if command -v node >/dev/null 2>&1; then
      node - "${MCP_FILE}" "${KIT_MCP}" <<'JSEOF'
const [, , dest, src] = process.argv;
const fs = require('fs');
const existing = JSON.parse(fs.readFileSync(dest, 'utf8'));
const kit = JSON.parse(fs.readFileSync(src, 'utf8'));
existing.mcpServers = existing.mcpServers || {};
Object.assign(existing.mcpServers, kit.mcpServers);
fs.writeFileSync(dest, JSON.stringify(existing, null, 2) + '\n');
JSEOF
      echo "    merged pi-harness into ${MCP_FILE}"
    else
      echo "    Warning: node not found — add pi-harness to ${MCP_FILE} manually"
    fi
  else
    echo "    ${MCP_FILE} already has pi-harness — skipped"
  fi
fi

# ── 3. Re-sync project rules ──────────────────────────────────────────────────
if [[ -n "$(ls -A "${FACTORY_WS}/rules/" 2>/dev/null)" ]]; then
  cp "${FACTORY_WS}/rules/"*.mdc .cursor/rules/ 2>/dev/null || true
  echo "    project rules synced to .cursor/rules/"
fi

# ── 4. Run pending migrations ─────────────────────────────────────────────────
MIGRATIONS_DIR="${FACTORY_KIT}/migrations"
META_FILE="${PROJECT_ROOT}/.kit-meta.json"

if [[ -d "${MIGRATIONS_DIR}" ]] && [[ -f "${META_FILE}" ]]; then
  echo "==> Checking migrations"
  APPLIED=$(python3 -c "import json,sys; d=json.load(open('${META_FILE}')); print(d.get('last_migration','000'))" 2>/dev/null || echo "000")

  for migration in "${MIGRATIONS_DIR}"/*.sh; do
    [[ -f "${migration}" ]] || continue
    num=$(basename "${migration}" | cut -d'-' -f1)
    if [[ "${num}" > "${APPLIED}" ]]; then
      echo "    applying migration: $(basename ${migration})"
      bash "${migration}" "${PROJECT_ROOT}" "${FACTORY_KIT}"
      APPLIED="${num}"
    fi
  done

  KIT_SHA=$(git -C "${FACTORY_KIT}" rev-parse HEAD 2>/dev/null || echo "unknown")
  KIT_VERSION=$(cat "${FACTORY_KIT}/VERSION" 2>/dev/null || echo "2.0")
  python3 -c "
import json
with open('${META_FILE}') as f:
    d = json.load(f)
d['kit_sha'] = '${KIT_SHA}'
d['factory_version'] = '${KIT_VERSION}'
d['updated_at'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
d['last_migration'] = '${APPLIED}'
with open('${META_FILE}', 'w') as f:
    json.dump(d, f, indent=2)
print('    .kit-meta.json updated')
" 2>/dev/null || true
fi

# ── 5. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "Factory 2.0 update complete."
if [[ "${BEFORE}" != "${AFTER}" ]]; then
  echo "  Commit the update:"
  echo "  git add ${FACTORY_KIT} .cursor/ .kit-meta.json"
  echo "  git commit -m 'chore: update factory kit to ${AFTER:0:8}'"
fi
echo ""
