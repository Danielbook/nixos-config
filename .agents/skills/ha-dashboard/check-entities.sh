#!/usr/bin/env bash
# Checks every entity ID in glass.yaml against the live Home Assistant.
# It prints the last recorded state from ha-postgres and fails on an ID that
# is missing or disabled. YAML entities without a unique_id (for example
# sensor.count_lights_on) are not in the registry. The script finds them in
# restore_state or in the recorder instead.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
NS=homeassistant
ids=$(grep -ohE '\b(alarm_control_panel|automation|binary_sensor|camera|climate|cover|device_tracker|input_boolean|light|lock|media_player|number|person|scene|script|sensor|switch|vacuum|weather|zone)\.[a-z0-9_]+' \
  k8s/apps/homeassistant/dashboards/glass.yaml | sort -u)

values=$(printf "('%s')," $ids)
recorded=$(kubectl -n "$NS" exec deploy/ha-postgres -- psql -U homeassistant -d homeassistant -AtF '|' -c "
  SELECT v.id, COALESCE((SELECT s.state FROM states s JOIN states_meta m ON s.metadata_id = m.metadata_id
                         WHERE m.entity_id = v.id ORDER BY s.last_updated_ts DESC LIMIT 1), '')
  FROM (VALUES ${values%,}) AS v(id)")

pod=$(kubectl -n "$NS" get pod -l app=homeassistant -o name)
echo "$recorded" | kubectl -n "$NS" exec -i "$pod" -- python3 -c '
import json, sys
S = "/config/.storage/"
reg = {e["entity_id"]: e for e in json.load(open(S + "core.entity_registry"))["data"]["entities"]}
restored = {s["state"]["entity_id"] for s in json.load(open(S + "core.restore_state"))["data"]}
bad = 0
for line in sys.stdin.read().splitlines():
    i, state = line.split("|", 1)
    e = reg.get(i)
    if e is None and i not in restored and not state and not i.startswith("zone."):
        print(f"MISSING   {i}"); bad += 1
    elif e is not None and e.get("disabled_by"):
        print("DISABLED ", i, e["disabled_by"]); bad += 1
    elif state in ("unavailable", "unknown"):
        print(f"{state.upper():9} {i}")
print(f"{bad} problem(s)")
sys.exit(1 if bad else 0)
'
