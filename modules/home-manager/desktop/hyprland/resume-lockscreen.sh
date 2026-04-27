#!/usr/bin/env bash
# Handle noctalia crash recovery after suspend resume.
# Called by hypridle's after_sleep_cmd in user session context.
set -euo pipefail

MAX_WAIT=10

sleep 1
hyprctl dispatch dpms on

# If noctalia survived, just ensure screen is locked
if pgrep -x noctalia-shell >/dev/null 2>&1; then
    noctalia-shell ipc call lockScreen lock 2>/dev/null || true
    exit 0
fi

# Noctalia crashed — wait for its internal supervisor to restart it
waited=0
while [ $waited -lt $MAX_WAIT ]; do
    if pgrep -x noctalia-shell >/dev/null 2>&1; then
        break
    fi
    sleep 1
    waited=$((waited + 1))
done

# Fallback: manual restart if the internal supervisor didn't bring it back
if ! pgrep -x noctalia-shell >/dev/null 2>&1; then
    setsid noctalia-shell </dev/null >/dev/null 2>&1 &
    disown || true
    sleep 2
fi

# Lock the session — noctalia acquiring ext-session-lock-v1 clears "oopsie daisy"
noctalia-shell ipc call lockScreen lock 2>/dev/null || loginctl lock-session
