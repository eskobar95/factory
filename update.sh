#!/usr/bin/env bash
# update.sh — update factory submodule in a project and refresh all derived artifacts
#
# Run from project root: .factory/update.sh
# Or: bash .factory/update.sh

set -euo pipefail

FACTORY_PATH=".factory"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${PROJECT_ROOT}"

echo "==> Factory update (project: ${PROJECT_ROOT})"

# 1. Verify submodule exists
if [[ ! -e "${FACTORY_PATH}/.git" ]]; then
  echo "Error: .factory not found or not a submodule. Run install.sh first."
  exit 1
fi

# 2. Pull latest factory
echo "==> Pulling factory..."
BEFORE=$(git -C "${FACTORY_PATH}" rev-parse HEAD 2>/dev/null || true)
git submodule update --remote --merge "${FACTORY_PATH}"
AFTER=$(git -C "${FACTORY_PATH}" rev-parse HEAD 2>/dev/null || true)

if [[ "${BEFORE}" == "${AFTER}" ]]; then
  echo "    Already up to date (${AFTER:0:8})"
else
  echo "    Updated: ${BEFORE:0:8} → ${AFTER:0:8}"
  echo ""
  echo "    Recent commits:"
  git -C "${FACTORY_PATH}" log --oneline "${BEFORE}..${AFTER}" 2>/dev/null | sed 's/^/    /' || true
fi

# 3. Refresh hook script permissions (new scripts may have been added)
echo "==> Refreshing hook script permissions..."
for script in "${FACTORY_PATH}"/hooks/*.sh; do
  [[ -f "${script}" ]] && chmod +x "${script}" && echo "    chmod +x ${script}"
done

# 4. Verify symlinks are intact (re-create if broken)
echo "==> Verifying symlinks..."
FACTORY_SOURCE="${PROJECT_ROOT}/${FACTORY_PATH}"

verify_or_relink() {
  local name="$1"
  local link=".cursor/${name}"
  local target="../${FACTORY_PATH}/${name}"
  if [[ ! -e "${link}" ]]; then
    ln -sf "${target}" "${link}"
    echo "    re-created: ${link} -> ${target}"
  else
    echo "    ok: ${link}"
  fi
}

verify_or_relink "rules"
verify_or_relink "commands"
verify_or_relink "hooks"

# hooks.json symlink
if [[ ! -L ".cursor/hooks.json" ]]; then
  if [[ -f ".cursor/hooks.json" ]]; then
    echo "    Note: .cursor/hooks.json is a plain file (pre-symlink install)."
    echo "    Replacing with symlink..."
    rm -f .cursor/hooks.json
  fi
  ln -sf "../${FACTORY_PATH}/hooks/hooks.json" .cursor/hooks.json
  echo "    re-created: .cursor/hooks.json symlink"
else
  echo "    ok: .cursor/hooks.json (symlink)"
fi

# skills/factory symlink
if [[ ! -L ".cursor/skills/factory" ]]; then
  mkdir -p .cursor/skills
  ln -sf "../../${FACTORY_PATH}/skills" .cursor/skills/factory
  echo "    re-created: .cursor/skills/factory"
else
  echo "    ok: .cursor/skills/factory (symlink)"
fi

# 5. Remind about submodule pointer commit
echo ""
echo "Factory update complete."
if [[ "${BEFORE}" != "${AFTER}" ]]; then
  echo ""
  echo "To persist the updated submodule pointer:"
  echo "  git add ${FACTORY_PATH} && git commit -m 'chore: update factory to ${AFTER:0:8}'"
fi
echo ""
