#!/usr/bin/env bash
# One-shot VPS bootstrap for Swarm Subnet 124 miner development.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

info() { echo -e "\033[34m[INFO]\033[0m $*"; }
ok() { echo -e "\033[32m[OK]\033[0m $*"; }
err() { echo -e "\033[31m[ERROR]\033[0m $*" >&2; exit 1; }

require_root_tools() {
  command -v git >/dev/null || err "git not found"
}

ensure_docker() {
  if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
    ok "Docker daemon reachable"
    return
  fi
  if command -v dockerd >/dev/null; then
    info "Starting Docker daemon (Vast container has no systemd)..."
    mkdir -p /var/run/docker
    if ! pgrep -x dockerd >/dev/null 2>&1; then
      nohup dockerd --host=unix:///var/run/docker.sock > /var/log/dockerd.log 2>&1 &
    fi
    for _ in $(seq 1 30); do
      docker info >/dev/null 2>&1 && return
      sleep 2
    done
  fi
  err "Docker not available — install docker.io and ensure daemon is running"
}

install_system_deps() {
  local deps_script="$REPO_ROOT/scripts/miner/install_dependencies.sh"
  if [[ -f "$deps_script" ]]; then
    info "Installing system dependencies..."
    bash "$deps_script"
  else
    err "scripts/miner/install_dependencies.sh not found"
  fi
}

install_python_env() {
  info "Creating miner Python environment..."
  bash "$REPO_ROOT/scripts/miner/setup.sh"
}

activate_env() {
  # shellcheck disable=SC1091
  source "$REPO_ROOT/miner_env/bin/activate"
}

verify_swarm_cli() {
  info "Running swarm doctor..."
  swarm doctor || err "swarm doctor failed — fix environment before training"
  ok "swarm doctor passed"
}

download_champion_if_missing() {
  if [[ -f "$REPO_ROOT/my_agent/model.pt" && -f "$REPO_ROOT/my_agent/model.onnx" ]]; then
    ok "Champion model weights already present in my_agent/"
    return
  fi
  info "Downloading champion baseline weights..."
  bash "$REPO_ROOT/scripts/vps/download_champion.sh"
}

quick_smoke_test() {
  info "Packaging my_agent for smoke test..."
  swarm model test --source "$REPO_ROOT/my_agent/" || err "my_agent validation failed"
  swarm model package --source "$REPO_ROOT/my_agent/" || err "my_agent packaging failed"
  ok "my_agent packages successfully"
}

main() {
  info "Repo root: $REPO_ROOT"
  require_root_tools
  ensure_docker
  install_system_deps
  install_python_env
  activate_env
  verify_swarm_cli
  download_champion_if_missing
  quick_smoke_test
  ok "VPS bootstrap complete"
  echo
  echo "Next:"
  echo "  source miner_env/bin/activate"
  echo "  swarm benchmark --model Submission/submission.zip --seeds-per-group 1 --workers 4"
}

main "$@"
