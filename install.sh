#!/usr/bin/env bash
# Factory install — run from YOUR PROJECT ROOT (not from inside the kit repo)
#
# Creates:
#   .factory/kit/     ← git submodule (eskobar95/factory — read-only kit)
#   .factory/context/ ← PRD, TECHSPEC, CONTEXT, ADR, STACK (your project)
#   .factory/planning/← milestones, sprints, tasks
#   .factory/logs/    ← diary, decisions
#   .factory/skills/  ← project-specific skill overrides
#   .cursor/          ← symlinks into .factory/kit (rules, skills, commands, hooks)

set -euo pipefail

FACTORY_REPO="${FACTORY_REPO:-git@github.com:eskobar95/factory.git}"
FACTORY_KIT=".factory/kit"
FACTORY_WS=".factory"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve project root and kit source
if [[ -f "${SCRIPT_DIR}/install.sh" && -d "${SCRIPT_DIR}/commands" ]]; then
  # Running from inside the kit (submodule or clone)
  KIT_SOURCE="${SCRIPT_DIR}"
  PROJECT_ROOT="$(pwd)"
  if [[ "${PROJECT_ROOT}" == "${SCRIPT_DIR}" ]]; then
    echo "Error: Run from your project root, not from inside the factory kit repo."
    echo "  cd /path/to/your-project && ./.factory/kit/install.sh"
    exit 1
  fi
else
  PROJECT_ROOT="$(pwd)"
  KIT_SOURCE="${PROJECT_ROOT}/${FACTORY_KIT}"
fi

cd "${PROJECT_ROOT}"

echo "==> Factory install"
echo "    Project: ${PROJECT_ROOT}"
echo "    Kit:     ${FACTORY_KIT}"
echo "    Workspace: ${FACTORY_WS}/"

# ── Legacy: .ai/ → .factory/ workspace ───────────────────────────────────────
migrate_ai_workspace() {
  [[ ! -d ".ai" ]] && return 0
  echo "==> Migrating legacy .ai/ → .factory/"
  mkdir -p "${FACTORY_WS}"
  for item in context planning logs skills specs; do
    if [[ -e ".ai/${item}" && ! -e "${FACTORY_WS}/${item}" ]]; then
      mv ".ai/${item}" "${FACTORY_WS}/${item}"
      echo "    moved .ai/${item} → ${FACTORY_WS}/${item}"
    fi
  done
  rmdir .ai 2>/dev/null || true
}

# ── Legacy: submodule at .factory/ (old layout) ─────────────────────────────
warn_legacy_kit() {
  if [[ -e ".factory/.git" ]] && [[ ! -d ".factory/kit" ]] && [[ -f ".factory/install.sh" ]]; then
    echo ""
    echo "WARNING: Legacy layout detected — kit submodule is at .factory/ (not .factory/kit/)."
    echo "  Project workspace should live in .factory/context, not inside the submodule."
    echo "  See docs/MIGRATION.md to move the submodule to .factory/kit/"
    echo "  Until migrated, re-run may overwrite submodule files. Proceeding with .factory as kit."
    echo ""
    FACTORY_KIT=".factory"
    KIT_SOURCE="${PROJECT_ROOT}/${FACTORY_KIT}"
  fi
}

migrate_ai_workspace
warn_legacy_kit

# ── 1. Workspace scaffold ───────────────────────────────────────────────────
WS_DIRS=(
  "${FACTORY_WS}/context/ADR"
  "${FACTORY_WS}/planning"
  "${FACTORY_WS}/logs"
  "${FACTORY_WS}/skills"
  "${FACTORY_WS}/specs"
)

for dir in "${WS_DIRS[@]}"; do
  mkdir -p "${dir}"
done

# ── 2. Git submodule (kit) ────────────────────────────────────────────────────
if [[ ! -d "${FACTORY_KIT}" ]] || [[ ! -f "${FACTORY_KIT}/install.sh" ]]; then
  if [[ "${FACTORY_KIT}" == ".factory/kit" ]]; then
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      echo "Error: Not a git repository. Run 'git init' first."
      exit 1
    fi
    echo "==> Adding submodule ${FACTORY_REPO} -> ${FACTORY_KIT}"
    git submodule add "${FACTORY_REPO}" "${FACTORY_KIT}"
    git submodule update --init --recursive
  fi
fi

KIT_SOURCE="${PROJECT_ROOT}/${FACTORY_KIT}"

if [[ ! -f "${KIT_SOURCE}/install.sh" ]]; then
  echo "Error: Factory kit not found at ${FACTORY_KIT} (missing install.sh)."
  exit 1
fi

copy_if_missing() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "${dest}" ]]; then
    cp "${src}" "${dest}"
    echo "    created ${dest}"
  else
    echo "    kept existing ${dest}"
  fi
}

echo "==> Scaffolding ${FACTORY_WS}/ workspace"
copy_if_missing "${KIT_SOURCE}/templates/WORKSPACE-README.md" "${FACTORY_WS}/README.md"
copy_if_missing "${KIT_SOURCE}/templates/CONTEXT.md" "${FACTORY_WS}/context/CONTEXT.md"
copy_if_missing "${KIT_SOURCE}/templates/PRD.md" "${FACTORY_WS}/context/PRD.md"
copy_if_missing "${KIT_SOURCE}/templates/TECHSPEC.md" "${FACTORY_WS}/context/TECHSPEC.md"
copy_if_missing "${KIT_SOURCE}/templates/ADR.md" "${FACTORY_WS}/context/ADR/ADR-000-template.md"
copy_if_missing "${KIT_SOURCE}/templates/STACK.md" "${FACTORY_WS}/context/STACK.md"
copy_if_missing "${KIT_SOURCE}/templates/milestones.md" "${FACTORY_WS}/planning/milestones.md"
copy_if_missing "${KIT_SOURCE}/templates/sprints.md" "${FACTORY_WS}/planning/sprints.md"
copy_if_missing "${KIT_SOURCE}/templates/tasks.md" "${FACTORY_WS}/planning/tasks.md"
copy_if_missing "${KIT_SOURCE}/templates/specs/README.md" "${FACTORY_WS}/specs/README.md"
copy_if_missing "${KIT_SOURCE}/templates/specs/example.feature" "${FACTORY_WS}/specs/example.feature"
copy_if_missing "${KIT_SOURCE}/templates/DESIGN-SYSTEM.md" "${FACTORY_WS}/context/DESIGN-SYSTEM.md"

if [[ ! -s "${FACTORY_WS}/logs/diary.md" ]]; then
  echo "# Dev diary" > "${FACTORY_WS}/logs/diary.md"
  echo "" >> "${FACTORY_WS}/logs/diary.md"
fi
touch "${FACTORY_WS}/logs/decisions.md"

# ── 3. .cursor/ symlinks → kit ────────────────────────────────────────────────
mkdir -p .cursor/rules .cursor/skills .cursor/commands .cursor/hooks

link_kit_dir() {
  local name="$1"
  local link=".cursor/${name}"
  if [[ ! -d "${KIT_SOURCE}/${name}" ]]; then
    echo "    Warning: ${KIT_SOURCE}/${name} missing, skipping"
    return
  fi
  rm -rf "${link}" 2>/dev/null || true
  ln -sf "../${FACTORY_KIT}/${name}" "${link}"
  echo "    ${link} → ${FACTORY_KIT}/${name}"
}

echo "==> Linking .cursor/ → ${FACTORY_KIT}/"
link_kit_dir "rules"
link_kit_dir "commands"
link_kit_dir "hooks"

if [[ -f .cursor/hooks.json && ! -L .cursor/hooks.json ]]; then
  echo "    Replacing plain .cursor/hooks.json with symlink"
  rm -f .cursor/hooks.json
fi
if [[ -f "${KIT_SOURCE}/hooks/hooks.json" ]]; then
  ln -sf "../${FACTORY_KIT}/hooks/hooks.json" .cursor/hooks.json
  echo "    .cursor/hooks.json → ${FACTORY_KIT}/hooks/hooks.json"
fi

for script in "${KIT_SOURCE}"/hooks/*.sh; do
  [[ -f "${script}" ]] && chmod +x "${script}" 2>/dev/null || true
done

# Skills: kit + project overrides
rm -rf .cursor/skills/factory .cursor/skills/project 2>/dev/null || true
mkdir -p .cursor/skills
ln -sf "../../${FACTORY_KIT}/skills" .cursor/skills/factory
if [[ -d "${FACTORY_WS}/skills" ]] && [[ -n "$(ls -A "${FACTORY_WS}/skills" 2>/dev/null || true)" ]]; then
  ln -sf "../../${FACTORY_WS}/skills" .cursor/skills/project
fi
echo "    .cursor/skills/factory → ${FACTORY_KIT}/skills"
echo "    .cursor/skills/project  → ${FACTORY_WS}/skills (when populated)"

# ── 4. .gitignore (Cursor symlinks only — commit .factory/ workspace!) ────────
GITIGNORE_ENTRIES=(
  "# Factory — Cursor symlinks (regenerated by install.sh)"
  ".cursor/rules/"
  ".cursor/skills/"
  ".cursor/commands/"
  ".cursor/hooks/"
  ".cursor/hooks.json"
)

append_gitignore() {
  local entry="$1"
  if [[ -f .gitignore ]] && grep -qF "${entry}" .gitignore 2>/dev/null; then
    return
  fi
  echo "${entry}" >> .gitignore
}

echo "==> Updating .gitignore"
touch .gitignore
for entry in "${GITIGNORE_ENTRIES[@]}"; do
  append_gitignore "${entry}"
done

echo ""
echo "Factory installed successfully."
echo ""
echo "Project layout:"
echo "  ${FACTORY_WS}/context/   PRD, TECHSPEC, CONTEXT, ADR"
echo "  ${FACTORY_WS}/planning/  milestones, sprints, tasks"
echo "  ${FACTORY_WS}/specs/     BDD feature files (optional)"
echo "  ${FACTORY_WS}/logs/      diary, decisions"
echo "  ${FACTORY_KIT}/          kit submodule (do not edit — run update.sh)"
echo "  .cursor/                 symlinks to kit (rules, skills, commands, hooks)"
echo ""
echo "Next steps:"
echo "  1. /bootstrap-branches"
echo "  2. /align → /to-prd → /to-backlog   (or /to-plan)"
echo "  3. /run-sprint S001"
echo ""
echo "Docs: ${FACTORY_KIT}/docs/INSTALL.md"
echo ""
