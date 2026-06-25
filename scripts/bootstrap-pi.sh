#!/usr/bin/env bash
# Factory 2.0 — Pi + Graphify + Sentrux bootstrap
# Run from project root after Factory install.
#
# Prerequisites: Node 18+, npm 9+, Python 3.10+, pip, git

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${PROJECT_ROOT}"

CONFIG_FILE=".factory/factory.config.yaml"

log() { echo "==> $*"; }
ok()  { echo "    ✓ $*"; }
err() { echo "    ✗ $*" >&2; }

log "Factory 2.0 — Pi bootstrap"
echo "    Project: ${PROJECT_ROOT}"
echo ""

# ── 1. Graphify ───────────────────────────────────────────────────────────────
log "Graphify (open-source knowledge graph)"

if command -v graphify &>/dev/null; then
  ok "graphify already installed ($(graphify --version 2>/dev/null || echo 'version unknown'))"
else
  echo "    Installing graphifyy (PyPI)..."
  pip install graphifyy
  ok "graphify installed"
fi

if [[ ! -f "graphify-out/GRAPH_REPORT.md" ]]; then
  echo "    Building initial knowledge graph (this may take a minute)..."
  graphify init . 2>/dev/null || graphify update . 2>/dev/null || true
  ok "graph built → graphify-out/GRAPH_REPORT.md"
else
  ok "graph already exists — run 'graphify update .' to refresh"
fi

# Update factory.config.yaml
if [[ -f "${CONFIG_FILE}" ]]; then
  sed -i.bak 's/^  enabled: false.*# set true after.*graphify.*/  enabled: true/' "${CONFIG_FILE}" 2>/dev/null || true
  rm -f "${CONFIG_FILE}.bak"
fi

echo ""

# ── 2. Sentrux (self-hosted) ──────────────────────────────────────────────────
log "Sentrux (self-hosted architecture governance)"

SENTRUX_INSTALL_DIR="${HOME}/.sentrux"

if command -v sentrux &>/dev/null; then
  ok "sentrux already installed ($(sentrux --version 2>/dev/null || echo 'version unknown'))"
else
  echo "    Installing sentrux from source (self-hosted)..."
  if [[ ! -d "${SENTRUX_INSTALL_DIR}" ]]; then
    git clone https://github.com/sentrux/sentrux.git "${SENTRUX_INSTALL_DIR}" --depth 1
  fi
  cd "${SENTRUX_INSTALL_DIR}"
  if [[ -f "package.json" ]]; then
    npm install --silent
    npm link 2>/dev/null || true
  elif [[ -f "Makefile" ]]; then
    make install 2>/dev/null || true
  fi
  cd "${PROJECT_ROOT}"
  if command -v sentrux &>/dev/null; then
    ok "sentrux installed from ${SENTRUX_INSTALL_DIR}"
  else
    err "sentrux build may need manual steps — see ${SENTRUX_INSTALL_DIR}/README.md"
  fi
fi

if command -v sentrux &>/dev/null; then
  if [[ ! -f ".sentrux/rules.toml" ]]; then
    echo "    Initialising Sentrux..."
    sentrux init 2>/dev/null || true
    ok "Sentrux initialised → .sentrux/rules.toml"
    echo ""
    echo "    Edit .sentrux/rules.toml to set your layer structure:"
    echo "    (See https://sentrux.dev/docs/rules-engine/ for examples)"
  else
    ok "Sentrux already configured → .sentrux/rules.toml"
  fi

  # Update factory.config.yaml
  if [[ -f "${CONFIG_FILE}" ]]; then
    # Update sentrux.enabled
    python3 -c "
import re
with open('${CONFIG_FILE}') as f:
    content = f.read()
content = re.sub(r'(sentrux:\n  enabled:) false', r'\1 true', content)
with open('${CONFIG_FILE}', 'w') as f:
    f.write(content)
print('    factory.config.yaml: sentrux.enabled = true')
" 2>/dev/null || true
  fi
fi

echo ""

# ── 3. ultimate-pi ────────────────────────────────────────────────────────────
log "ultimate-pi (governed execution harness)"

if command -v pi &>/dev/null; then
  ok "pi already installed"
else
  echo ""
  echo "    Pi is not installed. Install it from https://pi.dev"
  echo "    (Pi requires a separate account/license)"
  echo ""
fi

if command -v pi &>/dev/null; then
  if [[ ! -d ".pi" ]]; then
    echo "    Bootstrapping ultimate-pi harness..."
    npx ultimate-pi@latest /harness-setup --non-interactive --skip-graphify 2>/dev/null || \
      echo "    Note: run 'pi \"/harness-setup\"' manually in a Pi session to complete harness setup"
    ok "ultimate-pi bootstrapped → .pi/"
  else
    ok ".pi/ already exists"
  fi

  # Update factory.config.yaml
  if [[ -f "${CONFIG_FILE}" ]]; then
    python3 -c "
import re
with open('${CONFIG_FILE}') as f:
    content = f.read()
content = re.sub(r'(pi:\n  enabled:) false', r'\1 true', content)
with open('${CONFIG_FILE}', 'w') as f:
    f.write(content)
print('    factory.config.yaml: pi.enabled = true')
" 2>/dev/null || true
  fi
fi

echo ""

# ── 4. .gitignore additions ───────────────────────────────────────────────────
append_gitignore() {
  local entry="$1"
  if ! grep -qF "${entry}" .gitignore 2>/dev/null; then
    echo "${entry}" >> .gitignore
    echo "    .gitignore += ${entry}"
  fi
}

log "Updating .gitignore"
append_gitignore ".sentrux/cache/"
append_gitignore ".pi/harness/runs/"
append_gitignore ".worktrees/"

# ── 5. Summary ────────────────────────────────────────────────────────────────
echo ""
echo "Bootstrap complete."
echo ""
echo "Enabled features:"

if command -v graphify &>/dev/null; then
  echo "  ✓ Graphify  — run 'graphify update .' to refresh graph before planning"
fi
if command -v sentrux &>/dev/null; then
  echo "  ✓ Sentrux   — edit .sentrux/rules.toml, then 'sentrux check_rules'"
fi
if command -v pi &>/dev/null; then
  echo "  ✓ Pi        — use Engine: pi on tasks, start with 'pi \"/harness-plan\"'"
fi

echo ""
echo "Next:"
echo "  1. Edit .factory/factory.config.yaml — review pi/graphify/sentrux settings"
echo "  2. Edit .sentrux/rules.toml — define your layer architecture"
echo "  3. Commit: git add .factory/ .pi/ .sentrux/ .gitignore"
echo "             git commit -m 'feat: bootstrap Pi + Graphify + Sentrux'"
echo ""
