#!/usr/bin/env bash
set -euo pipefail

session_name="pulse"
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_shell="${SHELL:-/bin/bash}"
attach_session=true

if [ "${1:-}" = "--detach" ]; then
  attach_session=false
elif [ -n "${1:-}" ]; then
  echo "Usage: $0 [--detach]"
  exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required. Install it, then run $0 again."
  exit 1
fi

if tmux has-session -t "$session_name" 2>/dev/null; then
  if "$attach_session"; then
    exec tmux attach-session -t "$session_name"
  fi

  echo "tmux session '$session_name' already exists."
  exit 0
fi

tab_names=("Rails server" "Sidekiq" "Clock" "Rails console" "Playground")
commands=("bun run rails" "bun run sidekiq" "bun run clock" "bun run console" "")

tmux new-session -d -s "$session_name" -n "${tab_names[0]}" -c "$project_dir" "$default_shell"
tmux set-option -t "$session_name" default-command "$default_shell"
tmux set-option -t "$session_name" mouse on

for index in "${!tab_names[@]}"; do
  window="$session_name:$index"

  if [ "$index" -ne 0 ]; then
    tmux new-window -t "$window" -n "${tab_names[$index]}" -c "$project_dir"
  fi

  if [ -n "${commands[$index]}" ]; then
    tmux send-keys -t "$window" "${commands[$index]}" C-m
  fi
done

if "$attach_session"; then
  exec tmux attach-session -t "$session_name"
fi

echo "Created tmux session '$session_name'."
