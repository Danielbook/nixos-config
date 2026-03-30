#!/usr/bin/env bash
# Handle noctalia crash recovery after suspend resume.
# Called by hypridle's after_sleep_cmd in user session context.
set -euo pipefail

MAX_WAIT=10

sleep 1
hyprctl dispatch dpms on

# If noctalia survived, just ensure screen is locked
if systemctl --user is-active noctalia-shell.service >/dev/null 2>&1; then
    noctalia-shell ipc call lockScreen lock 2>/dev/null || true
    exit 0
fi

# Noctalia crashed — wait for systemd Restart=on-failure
waited=0
while [ $waited -lt $MAX_WAIT ]; do
    if systemctl --user is-active noctalia-shell.service >/dev/null 2>&1; then
        break
    fi
    sleep 1
    waited=$((waited + 1))
done

# Fallback: manual restart if auto-restart didn't work
if ! systemctl --user is-active noctalia-shell.service >/dev/null 2>&1; then
    systemctl --user restart noctalia-shell.service || true
    sleep 2
fi

# Lock the session — noctalia acquiring ext-session-lock-v1 clears "oopsie daisy"
noctalia-shell ipc call lockScreen lock 2>/dev/null || loginctl lock-session
