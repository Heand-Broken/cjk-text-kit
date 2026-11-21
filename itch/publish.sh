#!/usr/bin/env bash
# Publishes CJK Text Kit to itch.io with the official butler CLI.
#
#   ./publish.sh yourname/cjk-text-kit
#
# The itch.io API key is read from $ITCH_API_KEY, or from api_key.txt next to
# this script.

set -euo pipefail

PROJECT="${1:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
DIST="${TMPDIR:-/tmp}/cjk-text-kit-upload"

if [ -z "$PROJECT" ]; then
  echo "usage: $0 <user>/<project-slug>" >&2
  echo "example: $0 yourname/cjk-text-kit" >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$1"; }
ok()   { printf '    %s\n' "$1"; }
warn() { printf '    %s\n' "$1" >&2; }

# --- 1. butler ---------------------------------------------------------------

step "Locating butler"
BUTLER="${BUTLER:-}"
if [ -z "$BUTLER" ]; then
  if command -v butler >/dev/null 2>&1; then
    BUTLER="$(command -v butler)"
  elif [ -x "$ROOT/tools/butler/butler" ]; then
    BUTLER="$ROOT/tools/butler/butler"
  fi
fi

if [ -z "$BUTLER" ]; then
  warn "butler was not found. Fetching it from its GitHub release instead..."
  BUTLER_DIR="$ROOT/tools/butler"
  BUTLER_ZIP="${TMPDIR:-/tmp}/butler-windows-amd64.zip"
  BUTLER_URL="https://github.com/itchio/butler/releases/latest/download/butler-windows-amd64.zip"
  if command -v curl >/dev/null 2>&1 && curl -sL --max-time 300 -o "$BUTLER_ZIP" "$BUTLER_URL"; then
    mkdir -p "$BUTLER_DIR"
    if command -v unzip >/dev/null 2>&1; then
      unzip -o -q "$BUTLER_ZIP" -d "$BUTLER_DIR" && ok "downloaded butler"
    fi
    FOUND="$(find "$BUTLER_DIR" -name 'butler*' -type f 2>/dev/null | head -1)"
    if [ -n "$FOUND" ]; then
      BUTLER="$FOUND"
      chmod +x "$BUTLER" 2>/dev/null || true
    fi
  else
    warn "could not download butler."
  fi
fi

if [ -z "$BUTLER" ]; then
  warn "butler is still missing. Install it with one of:"
  warn "  winget install itchio.butler"
  warn "  brew install itchio/butler/butler"
  warn "  or download https://itch.io/docs/butler/ and put the binary on your PATH"
  exit 1
fi
ok "butler: $BUTLER"

# --- 2. API key -------------------------------------------------------------

if [ -z "${ITCH_API_KEY:-}" ] && [ -f "$HERE/api_key.txt" ]; then
  ITCH_API_KEY="$(tr -d '[:space:]' < "$HERE/api_key.txt")"
fi

if [ -z "${ITCH_API_KEY:-}" ]; then
  warn "No itch.io API key found. Create one at https://itch.io/settings/user/api-keys"
  warn "then export ITCH_API_KEY=your-key or save it to itch/api_key.txt"
  exit 1
fi
ok "API key loaded"

# --- 3. upload directory ----------------------------------------------------

step "Assembling the upload directory"
rm -rf "$DIST"
mkdir -p "$DIST"

for zip in "$ROOT/dist/cjk-text-kit-v1.0.0.zip" "$ROOT/dist/cjk-text-kit-demo-v1.0.0.zip"; do
  if [ -f "$zip" ]; then
    cp "$zip" "$DIST/"
    ok "staged $(basename "$zip")"
  else
    warn "missing $(basename "$zip") - skipped"
  fi
done

if [ -z "$(ls -A "$DIST")" ]; then
  warn "Nothing to upload. Run the packaging step first."
  exit 1
fi

# --- 4. push ----------------------------------------------------------------

step "Pushing to itch.io ($PROJECT)"
# butler takes the source directory first and the target second:
#   butler push <src> <target>
# The API key is passed through the environment, because butler's push
# command does not accept an --api-key flag.
BUTLER_API_KEY="$ITCH_API_KEY" "$BUTLER" push "$DIST" "$PROJECT" --assume-yes

# --- 5. verify --------------------------------------------------------------

step "Verifying the upload"
USER_PART="${PROJECT%%/*}"
SLUG_PART="${PROJECT#*/}"
if command -v curl >/dev/null 2>&1; then
  RESPONSE="$(curl -s --max-time 60 "https://itch.io/api/1/${USER_PART}/${SLUG_PART}/uploads?api_key=${ITCH_API_KEY}" || true)"
  if printf '%s' "$RESPONSE" | grep -q '"filename"'; then
    printf '%s' "$RESPONSE" | grep -o '"filename":"[^"]*"' | sed 's/.*:"//; s/"//' | sed 's/^/    /'
  else
    warn "the API did not list the uploads yet. Refresh the page in a moment."
  fi
else
  warn "curl is not available, skipping the verification step."
fi

cat <<'EOF'

Uploaded. Next on the website:
  1. Open https://itch.io/<user>/<project-slug>
  2. Paste the description from itch/itch-page.md
  3. Upload cover.png as the cover and demo.gif as the embedded file
  4. Set the price to 9.99 USD for launch, 19.99 USD afterwards
  5. Press Save, then set Visibility to Public

Full checklist: itch/PUBLISH.md
EOF
