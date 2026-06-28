#!/usr/bin/env bash
# Download current Swarm champion submission and sync weights into my_agent/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MY_AGENT="$REPO_ROOT/my_agent"
CHAMPION_REPO="${CHAMPION_REPO:-https://github.com/leec-72991-a10y/2}"
TMP_DIR="$(mktemp -d)"
ZIP_PATH="$TMP_DIR/submission.zip"

info() { echo -e "\033[34m[INFO]\033[0m $*"; }
ok() { echo -e "\033[32m[OK]\033[0m $*"; }
err() { echo -e "\033[31m[ERROR]\033[0m $*" >&2; exit 1; }

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

download_submission() {
  info "Fetching champion submission from $CHAMPION_REPO"
  curl -fsSL "$CHAMPION_REPO/raw/main/submission.zip" -o "$ZIP_PATH" \
    || err "Failed to download submission.zip"
}

extract_weights() {
  mkdir -p "$MY_AGENT"
  unzip -o "$ZIP_PATH" -d "$TMP_DIR/extracted" >/dev/null

  for file in drone_agent.py agent_pt.py agent_onnx.py \
    model.pt model.onnx navigation_model.onnx \
    map_xgboost_state_depth_stats_model.json; do
    if [[ -f "$TMP_DIR/extracted/$file" ]]; then
      cp "$TMP_DIR/extracted/$file" "$MY_AGENT/$file"
    fi
  done

  ok "Synced champion files into my_agent/"
  ls -lh "$MY_AGENT"
}

main() {
  download_submission
  extract_weights
}

main "$@"
