#!/usr/bin/env bash
# install-pi-user-deps.sh — fix ultimate-pi peer deps at user level (~/.pi/)
# Run once per machine after: pi install npm:ultimate-pi

set -euo pipefail

export PATH="${HOME}/.hermes/node/bin:${PATH}"

log() { echo "==> $*"; }
ok()  { echo "    ✓ $*"; }

if ! command -v pi &>/dev/null; then
  echo "Error: pi not in PATH. Add: export PATH=\"\$HOME/.hermes/node/bin:\$PATH\""
  exit 1
fi

PI_NPM="${HOME}/.hermes/node/bin/npm"
AGENT_NPM="${HOME}/.pi/agent/npm"

log "Installing ultimate-pi peer dependencies"

if [[ -f "${PI_NPM}" && -d "${AGENT_NPM}" ]]; then
  cd "${AGENT_NPM}"
  "${PI_NPM}" install yaml @alexleekt/pi-ask-user-glimpse glimpseui 2>&1 | tail -3
  ok "yaml + pi-ask-user-glimpse in ~/.pi/agent/npm"
else
  echo "    Warning: ${AGENT_NPM} not found — run: pi install npm:ultimate-pi"
fi

mkdir -p "${HOME}/.pi/npm"
if [[ ! -f "${HOME}/.pi/npm/package.json" ]]; then
  cat > "${HOME}/.pi/npm/package.json" << 'EOF'
{
  "name": "pi-harness-deps",
  "private": true,
  "dependencies": {
    "@alexleekt/pi-ask-user-glimpse": "^0.5.1",
    "glimpseui": "^0.1.0",
    "yaml": "^2.8.0"
  }
}
EOF
fi
cd "${HOME}/.pi/npm"
"${PI_NPM}" install 2>&1 | tail -3
ok "harness deps in ~/.pi/npm"

echo ""
echo "User-level Pi deps ready. Run pi again — extension errors should be gone."
echo ""
