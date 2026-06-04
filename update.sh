#!/usr/bin/env bash
# update.sh — pull latest factory kit and refresh .cursor/ symlinks
# Run from project root: .factory/kit/update.sh

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${PROJECT_ROOT}"

# Detect kit path (new vs legacy layout)
if [[ -e ".factory/kit/.git" ]] || [[ -f ".factory/kit/install.sh" ]]; then
  FACTORY_KIT=".factory/kit"
elif [[ -e ".factory/.git" ]] && [[ -f ".factory/install.sh" ]]; then
  FACTORY_KIT=".factory"
else
  echo "Error: Factory kit not found. Run install.sh first."
  exit 1
fi

FACTORY_WS=".factory"

echo "==> Factory update (project: ${PROJECT_ROOT})"
echo "    Kit: ${FACTORY_KIT}"

BEFORE=$(git -C "${FACTORY_KIT}" rev-parse HEAD 2>/dev/null || true)
git submodule update --init --remote --merge "${FACTORY_KIT}" 2>/dev/null || \
  git submodule update --remote --merge "${FACTORY_KIT}"
AFTER=$(git -C "${FACTORY_KIT}" rev-parse HEAD 2>/dev/null || true)

if [[ "${BEFORE}" == "${AFTER}" ]]; then
  echo "    Already up to date (${AFTER:0:8})"
else
  echo "    Updated: ${BEFORE:0:8} → ${AFTER:0:8}"
  git -C "${FACTORY_KIT}" log --oneline "${BEFORE}..${AFTER}" 2>/dev/null | sed 's/^/    /' || true
fi

echo "==> Refreshing hook permissions..."
for script in "${FACTORY_KIT}"/hooks/*.sh; do
  [[ -f "${script}" ]] && chmod +x "${script}"
done

echo "==> Verifying .cursor/ symlinks..."
relink() {
  local name="$1"
  local link=".cursor/${name}"
  local target="../${FACTORY_KIT}/${name}"
  if [[ ! -e "${link}" ]]; then
    ln -sf "${target}" "${link}"
    echo "    re-created ${link}"
  else
    echo "    ok ${link}"
  fi
}

relink "rules"
relink "commands"
relink "hooks"

if [[ ! -L ".cursor/hooks.json" ]]; then
  rm -f .cursor/hooks.json
  ln -sf "../${FACTORY_KIT}/hooks/hooks.json" .cursor/hooks.json
  echo "    re-created .cursor/hooks.json"
else
  echo "    ok .cursor/hooks.json"
fi

mkdir -p .cursor/skills
ln -sf "../../${FACTORY_KIT}/skills" .cursor/skills/factory
if [[ -d "${FACTORY_WS}/skills" ]] && [[ -n "$(ls -A "${FACTORY_WS}/skills" 2>/dev/null || true)" ]]; then
  ln -sf "../../${FACTORY_WS}/skills" .cursor/skills/project
fi
echo "    ok .cursor/skills/factory"

echo ""
echo "Update complete."
if [[ "${BEFORE}" != "${AFTER}" ]]; then
  echo "  git add ${FACTORY_KIT} && git commit -m 'chore: update factory kit to ${AFTER:0:8}'"
fi
echo ""
