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

# ── 3. Pi + ultimate-pi ───────────────────────────────────────────────────────
log "Pi + ultimate-pi (governed execution harness)"

echo ""
echo "    Pi is a separate agent environment (like Cursor) that must be installed"
echo "    manually from https://pi.dev before ultimate-pi can be used."
echo ""

if command -v pi &>/dev/null; then
  ok "pi CLI found ($(pi --version 2>/dev/null || echo 'version unknown'))"
  PI_INSTALLED=true
else
  PI_INSTALLED=false
  echo "    ✗ pi not found in PATH"
  echo ""
  echo "    ─────────────────────────────────────────────────────────"
  echo "    Install Pi first:"
  echo "      1. Go to https://pi.dev and create an account"
  echo "      2. Follow the installation instructions for your platform"
  echo "      3. Verify: pi --version"
  echo "      4. Re-run this script"
  echo "    ─────────────────────────────────────────────────────────"
  echo ""
fi

if [[ "${PI_INSTALLED}" == "true" ]]; then
  # Pi uses its own Node.js at ~/.hermes/node/bin/
  # ultimate-pi must be installed via Pi's own npm, not system npm.
  PI_NPM="${HOME}/.hermes/node/bin/npm"
  PI_MODULES="${HOME}/.hermes/node/lib/node_modules"

  if [[ -d "${PI_MODULES}/ultimate-pi" ]]; then
    UPIVERSION=$(node -e "console.log(require('${PI_MODULES}/ultimate-pi/package.json').version)" 2>/dev/null || echo "unknown")
    ok "ultimate-pi@${UPIVERSION} already installed"
  else
    echo "    Installing ultimate-pi via Pi's npm (~/.hermes/node/bin/npm)..."
    if [[ -f "${PI_NPM}" ]]; then
      "${PI_NPM}" install -g ultimate-pi
      ok "ultimate-pi installed"
    else
      echo "    Warning: Pi's npm not found at ${PI_NPM}"
      echo "    Try manually: export PATH=\"\$HOME/.hermes/node/bin:\$PATH\" && npm install -g ultimate-pi"
    fi
  fi

  echo ""
  if [[ ! -d ".pi" ]]; then
    echo "    ─────────────────────────────────────────────────────────"
    echo "    Harness not yet bootstrapped for this project."
    echo "    Run these commands to finish setup:"
    echo ""
    echo "      export PATH=\"\$HOME/.hermes/node/bin:\$PATH\""
    echo "      cd ${PROJECT_ROOT}"
    echo "      pi                 # open Pi session (requires /login first if new)"
    echo "      /harness-setup     # inside Pi: bootstraps .pi/ harness files"
    echo ""
    echo "    /harness-setup is idempotent — safe to re-run."
    echo "    ─────────────────────────────────────────────────────────"
  else
    ok ".pi/ exists — ultimate-pi harness already bootstrapped"

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

# ── 4b. Pi model setup ───────────────────────────────────────────────────────
if [[ "${PI_INSTALLED}" == "true" ]]; then
  log "Pi model configuration"
  echo ""
  echo "    Pi supports your existing subscriptions and OpenRouter."
  echo "    Recommended setup:"
  echo ""
  echo "    Option A — Claude Pro/Max subscription (no extra cost):"
  echo "      pi → /login → select 'Claude Pro/Max'"
  echo "      (draws from extra usage pool, not plan messages)"
  echo ""
  echo "    Option B — OpenRouter (access to 200+ models, pay-per-use):"
  echo "      export OPENROUTER_API_KEY=sk-or-v1-..."
  echo "      pi → /login → select 'OpenRouter'"
  echo "      (supports Claude, GPT-5, Gemini, Grok, Kimi K2, etc.)"
  echo ""
  echo "    Option C — Both (Claude primary, OpenRouter for experiments):"
  echo "      Login to Claude first, set OPENROUTER_API_KEY in .env"
  echo "      Switch per session: pi --provider openrouter --model anthropic/claude-opus-4"
  echo ""
  echo "    NOTE: Cursor's subscription cannot be used as a model API for Pi."
  echo "    Cursor SDK is for running Cursor agents — not an LLM proxy."
  echo ""
fi

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
if [[ "${PI_INSTALLED}" == "true" ]]; then
  if [[ -d ".pi" ]]; then
    echo "  ✓ Pi        — .pi/ harness ready. Use Engine: pi on tasks."
  else
    echo "  ⚠ Pi        — installed, but harness not yet set up."
    echo "                Run: pi → /harness-setup"
  fi
else
  echo "  ✗ Pi        — not installed. See https://pi.dev"
fi

echo ""
echo "Next:"
echo "  1. Edit .factory/factory.config.yaml — review pi/graphify/sentrux settings"
echo "  2. Edit .sentrux/rules.toml — define your layer architecture"
echo "  3. Commit: git add .factory/ .pi/ .sentrux/ .gitignore"
echo "             git commit -m 'feat: bootstrap Pi + Graphify + Sentrux'"
echo ""
