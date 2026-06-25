#!/usr/bin/env bash
# Factory 2.0 install — run from YOUR PROJECT ROOT (not from inside the kit repo)
#
# Creates:
#   .factory/kit/          ← git submodule (read-only kit)
#   .factory/context/      ← PRD, TECHSPEC, CONTEXT, ADR, STACK (your project)
#   .factory/planning/     ← milestones, sprints, tasks
#   .factory/logs/         ← diary, decisions
#   .factory/skills/       ← project-specific skill overrides
#   .factory/rules/        ← project-specific Cursor rules (project-*.mdc)
#   .factory/handoff/      ← Pi TaskBrief YAML files (Engine: pi tasks)
#   .cursor/               ← real files copied from kit (tracked in git)
#   .kit-meta.json         ← kit version tracking for migrations

set -euo pipefail

FACTORY_REPO="${FACTORY_REPO:-https://github.com/eskobar95/factory.git}"
FACTORY_KIT=".factory/kit"
FACTORY_WS=".factory"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/install.sh" && -d "${SCRIPT_DIR}/commands" ]]; then
  KIT_SOURCE="${SCRIPT_DIR}"
  PROJECT_ROOT="$(pwd)"
  if [[ "${PROJECT_ROOT}" == "${SCRIPT_DIR}" ]]; then
    echo "Error: Run from your project root, not from inside the factory kit."
    echo "  cd /path/to/your-project && ./.factory/kit/install.sh"
    exit 1
  fi
else
  PROJECT_ROOT="$(pwd)"
  KIT_SOURCE="${PROJECT_ROOT}/${FACTORY_KIT}"
fi

cd "${PROJECT_ROOT}"

echo "==> Factory 2.0 install"
echo "    Project: ${PROJECT_ROOT}"
echo "    Kit:     ${FACTORY_KIT}"

# ── Legacy migrations ─────────────────────────────────────────────────────────
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

remove_legacy_symlinks() {
  for target in rules commands hooks skills; do
    local link=".cursor/${target}"
    if [[ -L "${link}" ]]; then
      echo "    removing legacy symlink ${link}"
      rm -f "${link}"
    fi
  done
  if [[ -L ".cursor/hooks.json" ]]; then
    echo "    removing legacy symlink .cursor/hooks.json"
    rm -f ".cursor/hooks.json"
  fi
}

migrate_ai_workspace

# ── 1. Git submodule (kit) ────────────────────────────────────────────────────
if [[ ! -d "${FACTORY_KIT}" ]] || [[ ! -f "${FACTORY_KIT}/install.sh" ]]; then
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not a git repository. Run 'git init' first."
    exit 1
  fi
  echo "==> Adding submodule ${FACTORY_REPO} → ${FACTORY_KIT}"
  git submodule add "${FACTORY_REPO}" "${FACTORY_KIT}"
  git submodule update --init --recursive
fi

KIT_SOURCE="${PROJECT_ROOT}/${FACTORY_KIT}"

if [[ ! -f "${KIT_SOURCE}/install.sh" ]]; then
  echo "Error: Factory kit not found at ${FACTORY_KIT}."
  exit 1
fi

# ── 2. Workspace scaffold ─────────────────────────────────────────────────────
echo "==> Scaffolding ${FACTORY_WS}/ workspace"

WS_DIRS=(
  "${FACTORY_WS}/context/ADR"
  "${FACTORY_WS}/context/features"
  "${FACTORY_WS}/planning"
  "${FACTORY_WS}/logs/sprints"
  "${FACTORY_WS}/skills"
  "${FACTORY_WS}/rules"
  "${FACTORY_WS}/specs"
  "${FACTORY_WS}/handoff"
  "${FACTORY_WS}/policies"
)

for dir in "${WS_DIRS[@]}"; do
  mkdir -p "${dir}"
done

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

copy_if_missing "${KIT_SOURCE}/templates/WORKSPACE-README.md" "${FACTORY_WS}/README.md"
copy_if_missing "${KIT_SOURCE}/templates/CONTEXT.md"          "${FACTORY_WS}/context/CONTEXT.md"
copy_if_missing "${KIT_SOURCE}/templates/PRD.md"              "${FACTORY_WS}/context/PRD.md"
copy_if_missing "${KIT_SOURCE}/templates/TECHSPEC.md"         "${FACTORY_WS}/context/TECHSPEC.md"
copy_if_missing "${KIT_SOURCE}/templates/ADR.md"              "${FACTORY_WS}/context/ADR/ADR-000-template.md"
copy_if_missing "${KIT_SOURCE}/templates/STACK.md"            "${FACTORY_WS}/context/STACK.md"
copy_if_missing "${KIT_SOURCE}/templates/DESIGN-SYSTEM.md"    "${FACTORY_WS}/context/DESIGN-SYSTEM.md"
copy_if_missing "${KIT_SOURCE}/templates/milestones.md"       "${FACTORY_WS}/planning/milestones.md"
copy_if_missing "${KIT_SOURCE}/templates/sprints.md"          "${FACTORY_WS}/planning/sprints.md"
copy_if_missing "${KIT_SOURCE}/templates/tasks.md"            "${FACTORY_WS}/planning/tasks.md"
copy_if_missing "${KIT_SOURCE}/templates/factory.config.yaml" "${FACTORY_WS}/factory.config.yaml"
copy_if_missing "${KIT_SOURCE}/templates/specs/README.md"     "${FACTORY_WS}/specs/README.md"
copy_if_missing "${KIT_SOURCE}/templates/specs/example.feature" "${FACTORY_WS}/specs/example.feature"

if [[ ! -s "${FACTORY_WS}/logs/diary.md" ]]; then
  echo "# Dev diary" > "${FACTORY_WS}/logs/diary.md"
  echo "" >> "${FACTORY_WS}/logs/diary.md"
fi
touch "${FACTORY_WS}/logs/decisions.md"

# ── 3. .cursor/ — copy kit files (no symlinks) ───────────────────────────────
echo "==> Installing .cursor/ from kit"

remove_legacy_symlinks

mkdir -p .cursor/rules .cursor/commands/planning .cursor/commands/harness \
         .cursor/commands/productivity .cursor/hooks \
         .cursor/skills/factory .cursor/skills/project

copy_kit_dir() {
  local src="${KIT_SOURCE}/$1"
  local dest=".cursor/$1"
  if [[ ! -d "${src}" ]]; then
    echo "    Warning: ${src} missing, skipping"
    return
  fi
  cp -r "${src}/." "${dest}/"
  echo "    .cursor/$1 ← ${FACTORY_KIT}/$1"
}

copy_kit_dir "rules"
copy_kit_dir "commands"
copy_kit_dir "hooks"
copy_kit_dir "skills"

# Rename kit skills to factory/ subdirectory
if [[ -d ".cursor/skills" ]] && [[ ! -d ".cursor/skills/factory" ]]; then
  mkdir -p .cursor/skills/factory
fi
# Kit skills live at .cursor/skills/factory/
if [[ -d "${KIT_SOURCE}/skills" ]]; then
  cp -r "${KIT_SOURCE}/skills/." ".cursor/skills/factory/"
  echo "    .cursor/skills/factory/ ← ${FACTORY_KIT}/skills/"
fi

# Make hook scripts executable
for script in .cursor/hooks/*.sh; do
  [[ -f "${script}" ]] && chmod +x "${script}"
done

# Sync project rules (.factory/rules/*.mdc → .cursor/rules/)
if [[ -n "$(ls -A "${FACTORY_WS}/rules/" 2>/dev/null)" ]]; then
  cp "${FACTORY_WS}/rules/"*.mdc .cursor/rules/ 2>/dev/null || true
  echo "    .cursor/rules/ ← ${FACTORY_WS}/rules/ (project rules)"
fi

# ── 4. .kit-meta.json ─────────────────────────────────────────────────────────
KIT_SHA=$(git -C "${FACTORY_KIT}" rev-parse HEAD 2>/dev/null || echo "unknown")
KIT_VERSION=$(cat "${FACTORY_KIT}/VERSION" 2>/dev/null || echo "2.0")
cat > .kit-meta.json <<EOF
{
  "factory_version": "${KIT_VERSION}",
  "kit_sha": "${KIT_SHA}",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "schema": "2"
}
EOF
echo "    wrote .kit-meta.json (kit @ ${KIT_SHA:0:8})"

# ── 5. .gitignore — track .cursor/ files, ignore generated artifacts ──────────
echo "==> Updating .gitignore"
touch .gitignore

remove_gitignore_entry() {
  local entry="$1"
  if [[ -f .gitignore ]] && grep -qF "${entry}" .gitignore 2>/dev/null; then
    local tmpfile
    tmpfile=$(mktemp)
    grep -vF "${entry}" .gitignore > "${tmpfile}" || true
    mv "${tmpfile}" .gitignore
    echo "    removed legacy gitignore entry: ${entry}"
  fi
}

# Remove 1.0 symlink-era entries
remove_gitignore_entry ".cursor/rules/"
remove_gitignore_entry ".cursor/skills/"
remove_gitignore_entry ".cursor/commands/"
remove_gitignore_entry ".cursor/hooks/"
remove_gitignore_entry ".cursor/hooks.json"
remove_gitignore_entry "# Factory — Cursor symlinks (regenerated by install.sh)"

append_gitignore() {
  local entry="$1"
  if ! grep -qF "${entry}" .gitignore 2>/dev/null; then
    echo "${entry}" >> .gitignore
  fi
}

# 2.0 entries: ignore Pi artifacts and worktrees, NOT .cursor/ files
append_gitignore "# Factory 2.0"
append_gitignore ".worktrees/"
append_gitignore ".factory/handoff/*.yaml"
append_gitignore "graphify-out/"
append_gitignore ".kit-meta.json"

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "Factory 2.0 installed."
echo ""
echo "Project layout:"
echo "  ${FACTORY_WS}/context/    PRD, TECHSPEC, CONTEXT, ADR, features/"
echo "  ${FACTORY_WS}/planning/   milestones, sprints, tasks"
echo "  ${FACTORY_WS}/rules/      project rules (project-*.mdc → .cursor/rules/)"
echo "  ${FACTORY_WS}/handoff/    Pi TaskBrief files (Engine: pi tasks)"
echo "  ${FACTORY_WS}/policies/   security-reviewer.md, quality.gates.yaml"
echo "  ${FACTORY_KIT}/           kit submodule (read-only)"
echo "  .cursor/                  kit files, tracked in git"
echo ""
echo "Next steps:"
echo "  1. /bootstrap-branches"
echo "  2. /align → /to-prd → /to-backlog"
echo "  3. (Optional) ${FACTORY_KIT}/scripts/bootstrap-pi.sh   # Pi + Graphify + Sentrux"
echo ""
