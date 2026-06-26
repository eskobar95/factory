#!/usr/bin/env bash
# sync-pi-config.sh — copy Factory Pi templates into project workspace and sync to .pi/
# Run from project root: .factory/kit/scripts/sync-pi-config.sh [--force-policy]
#
# Default: non-destructive — never overwrites existing .factory/pi/agents.policy.yaml
# --force-policy: overwrite .factory/pi/agents.policy.yaml from kit template (backup first)

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${PROJECT_ROOT}"

FORCE_POLICY=false
for arg in "$@"; do
  case "${arg}" in
    --force-policy) FORCE_POLICY=true ;;
  esac
done

if [[ -f ".factory/kit/scripts/sync-pi-config.sh" ]]; then
  KIT=".factory/kit"
elif [[ -f "scripts/sync-pi-config.sh" && -d "templates/pi" ]]; then
  KIT="."
else
  echo "Error: Factory kit not found."
  exit 1
fi

PI_TEMPLATE="${KIT}/templates/pi"
FACTORY_PI=".factory/pi"
TARGET_POLICY=".pi/agents.policy.yaml"

log() { echo "==> $*"; }
ok()  { echo "    ✓ $*"; }

copy_if_missing() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "${dest}" ]]; then
    cp "${src}" "${dest}"
    ok "created ${dest}"
  else
    echo "    kept existing ${dest}"
  fi
}

log "Sync Pi config (project: ${PROJECT_ROOT})"
mkdir -p "${FACTORY_PI}"

# ── 1. Scaffold .factory/pi/ from kit templates ───────────────────────────────
for f in agents.policy.yaml models.profile.yaml README.md; do
  if [[ -f "${PI_TEMPLATE}/${f}" ]]; then
    if [[ "${f}" == "agents.policy.yaml" && "${FORCE_POLICY}" == "true" && -f "${FACTORY_PI}/${f}" ]]; then
      cp "${FACTORY_PI}/${f}" "${FACTORY_PI}/${f}.bak"
      cp "${PI_TEMPLATE}/${f}" "${FACTORY_PI}/${f}"
      ok "updated ${FACTORY_PI}/${f} (backup: ${f}.bak)"
    else
      copy_if_missing "${PI_TEMPLATE}/${f}" "${FACTORY_PI}/${f}"
    fi
  fi
done

# ── 2. Sync .factory/pi/agents.policy.yaml → .pi/ (when harness exists) ───────
if [[ -f "${FACTORY_PI}/agents.policy.yaml" ]]; then
  if [[ -d ".pi" ]]; then
    mkdir -p .pi
    cp "${FACTORY_PI}/agents.policy.yaml" "${TARGET_POLICY}"
    ok "synced ${TARGET_POLICY} ← ${FACTORY_PI}/agents.policy.yaml"
  else
    echo "    .pi/ not found — run 'pi' → '/harness-setup' first, then re-run this script"
  fi
else
  echo "    Warning: ${FACTORY_PI}/agents.policy.yaml missing"
fi

# ── 3. Merge harness env vars into .env (non-destructive) ─────────────────────
ENV_EXAMPLE="${KIT}/templates/.env.factory.example"
if [[ -f "${ENV_EXAMPLE}" ]]; then
  if [[ ! -f ".env" ]]; then
    echo "    No .env — copy harness vars from ${ENV_EXAMPLE} manually"
  elif ! grep -q "HARNESS_WEB_FAST_MODEL" .env 2>/dev/null; then
    {
      echo ""
      echo "# ── Factory Pi harness (added by sync-pi-config.sh) ──"
      echo "HARNESS_WEB_FAST_MODEL=openrouter/openrouter/owl-alpha"
      echo "HARNESS_WEB_EXPANDER_MODEL=openrouter/tencent/hy3-preview"
      echo "HARNESS_WEB_QUALITY_MODEL=openrouter/z-ai/glm-5.2"
    } >> .env
    ok "appended HARNESS_WEB_* vars to .env"
  else
    echo "    .env already has HARNESS_WEB_* vars"
  fi
fi

echo ""
echo "Pi config sync complete."
echo "  Edit:  ${FACTORY_PI}/agents.policy.yaml"
echo "  Active: ${TARGET_POLICY} (when .pi/ exists)"
echo ""
