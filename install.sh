#!/usr/bin/env bash
# Factory install script — run from target project root
# Adds .factory submodule, scaffolds .ai/, symlinks .cursor/ to factory assets

set -euo pipefail

FACTORY_REPO="${FACTORY_REPO:-git@github.com:eskobar/factory.git}"
FACTORY_PATH=".factory"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect if we're running from inside the factory repo (dev) or from a project
if [[ -f "${SCRIPT_DIR}/install.sh" && -d "${SCRIPT_DIR}/commands" ]]; then
  FACTORY_SOURCE="${SCRIPT_DIR}"
  PROJECT_ROOT="$(pwd)"
  if [[ "${PROJECT_ROOT}" == "${SCRIPT_DIR}" ]]; then
    echo "Error: Run install.sh from your project root, not from inside the factory repo."
    echo "  cd /path/to/your-project && ./.factory/install.sh"
    exit 1
  fi
else
  PROJECT_ROOT="$(pwd)"
  FACTORY_SOURCE="${PROJECT_ROOT}/${FACTORY_PATH}"
fi

cd "${PROJECT_ROOT}"

echo "==> Factory install (project: ${PROJECT_ROOT})"

# 1. Git submodule
if [[ ! -d "${FACTORY_PATH}" ]]; then
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not a git repository. Run 'git init' first."
    exit 1
  fi
  echo "==> Adding submodule ${FACTORY_REPO} -> ${FACTORY_PATH}"
  git submodule add "${FACTORY_REPO}" "${FACTORY_PATH}"
  git submodule update --init --recursive
else
  echo "==> Submodule ${FACTORY_PATH} already exists"
  git submodule update --init --recursive 2>/dev/null || true
fi

FACTORY_SOURCE="${PROJECT_ROOT}/${FACTORY_PATH}"

if [[ ! -f "${FACTORY_SOURCE}/install.sh" ]]; then
  echo "Error: ${FACTORY_PATH} does not look like factory (missing install.sh)."
  exit 1
fi

# 2. .ai/ scaffold
AI_DIRS=(
  ".ai/context/ADR"
  ".ai/planning"
  ".ai/logs"
  ".ai/skills"
)

for dir in "${AI_DIRS[@]}"; do
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

echo "==> Scaffolding .ai/"
copy_if_missing "${FACTORY_SOURCE}/templates/PRD.md" ".ai/context/PRD.md"
copy_if_missing "${FACTORY_SOURCE}/templates/TECHSPEC.md" ".ai/context/TECHSPEC.md"
copy_if_missing "${FACTORY_SOURCE}/templates/milestones.md" ".ai/planning/milestones.md"
touch ".ai/planning/sprints.md"
copy_if_missing "${FACTORY_SOURCE}/templates/tasks.md" ".ai/planning/tasks.md"
touch ".ai/logs/diary.md"
touch ".ai/logs/decisions.md"
touch ".ai/context/STACK.md"

if [[ ! -s ".ai/planning/sprints.md" ]]; then
  cat > ".ai/planning/sprints.md" << 'EOF'
# Sprints

| ID | Milestone | Goal | Status |
|----|-----------|------|--------|
| S001 | M001 | [Sprint goal] | planned |

EOF
fi

if [[ ! -s ".ai/logs/diary.md" ]]; then
  echo "# Dev diary" > ".ai/logs/diary.md"
  echo "" >> ".ai/logs/diary.md"
fi

# 3. .cursor/ directories
mkdir -p .cursor/rules .cursor/skills .cursor/commands .cursor/hooks

# 4–7. Symlinks
link_dir() {
  local name="$1"
  local target="${FACTORY_SOURCE}/${name}"
  local link=".cursor/${name}"
  if [[ ! -d "${target}" ]]; then
    echo "Warning: ${target} missing, skipping ${link}"
    return
  fi
  rm -rf "${link}" 2>/dev/null || true
  ln -sf "../${FACTORY_PATH}/${name}" "${link}"
  echo "    ${link} -> ../${FACTORY_PATH}/${name}"
}

echo "==> Symlinking .cursor/"
link_dir "rules"
link_dir "commands"
link_dir "hooks"

# hooks.json at project root (Cursor reads .cursor/hooks.json)
if [[ -f "${FACTORY_SOURCE}/hooks/hooks.json" ]]; then
  if [[ ! -f .cursor/hooks.json ]] || [[ "${FORCE_HOOKS:-}" == "1" ]]; then
    cp "${FACTORY_SOURCE}/hooks/hooks.json" .cursor/hooks.json
    echo "    .cursor/hooks.json installed from factory"
  else
    echo "    kept existing .cursor/hooks.json (set FORCE_HOOKS=1 to overwrite)"
  fi
fi
for script in run-typecheck.sh run-security-audit.sh; do
  if [[ -f "${FACTORY_SOURCE}/hooks/${script}" ]]; then
    chmod +x "${FACTORY_SOURCE}/hooks/${script}" 2>/dev/null || true
  fi
done

# Skills: factory + project overrides
rm -rf .cursor/skills/factory .cursor/skills/project 2>/dev/null || true
mkdir -p .cursor/skills
ln -sf "../../${FACTORY_PATH}/skills" .cursor/skills/factory
if [[ -d ".ai/skills" ]] && [[ -n "$(ls -A .ai/skills 2>/dev/null || true)" ]]; then
  ln -sf "../../.ai/skills" .cursor/skills/project
fi

# 8. .gitignore entries
GITIGNORE_ENTRIES=(
  "# Factory / Cursor (symlinked from .factory)"
  ".cursor/rules/"
  ".cursor/skills/"
  ".cursor/commands/"
  ".cursor/hooks/"
)

append_gitignore() {
  local entry="$1"
  if [[ -f .gitignore ]] && grep -qF "${entry}" .gitignore 2>/dev/null; then
    return
  fi
  echo "${entry}" >> .gitignore
}

echo "==> Updating .gitignore"
if [[ ! -f .gitignore ]]; then
  touch .gitignore
fi
for entry in "${GITIGNORE_ENTRIES[@]}"; do
  append_gitignore "${entry}"
done

echo ""
echo "Factory installed successfully."
echo ""
echo "Next steps:"
echo "  1. Fill .ai/context/PRD.md and TECHSPEC.md (or run /po-breakdown with your macro idea)"
echo "  2. Plan milestones and tasks in .ai/planning/"
echo "  3. Create branch 'dev' from your default branch if it does not exist"
echo "  4. Run /run-sprint S001 when tasks are ready"
echo ""
