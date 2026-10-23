---
name: ha-dashboard
description: Change the Glass dashboard of Home Assistant (the home-panel card and glass.yaml). Use when the user asks to change, add or fix something on the HA dashboard, a room page, the El page or a card.
---

The Glass dashboard is one custom Lit card, `home-panel`, that draws every page. The home screen is the default page. A room page opens at `#<room id>` and the El page at `#el`. The back gesture closes a page.

## Files

| File | Holds |
| --- | --- |
| `k8s/apps/homeassistant/panel/home-panel.js` | Layout, logic and styles. One file with no build step. |
| `k8s/apps/homeassistant/panel/lit-core.min.js` | A vendored copy of Lit. The card loads nothing from a CDN. |
| `k8s/apps/homeassistant/dashboards/glass.yaml` | Every entity ID, name, room, group and quick action. Its top comment explains the shape. |

The ConfigMaps `ha-panel` and `ha-dashboards` (see `kustomization.yaml`) mount these files read-only at `/config/www/home-panel` and `/config/dashboards`. The Lovelace resource `/local/home-panel/home-panel.js?v=N` is in HA storage, not in git.

Put a change of entity, name or text in `glass.yaml`. Put a change of layout or behaviour in `home-panel.js`.

## Steps

1. **Collect the facts.** Read real entity IDs, names, units and states from HA. Read the registry in the HA pod (`/config/.storage/core.entity_registry`, `core.device_registry`). Read history from `deploy/ha-postgres` with `psql -U homeassistant -d homeassistant`. The device name is the real name: for example, `light.kitchen_window` is "Kitchen Window 2". Done when you checked the ID, name and unit of each entity that you add against HA.
2. **Edit** `glass.yaml` or `home-panel.js`. Follow the house rules below.
3. **Check the entities.** Run `.agents/skills/ha-dashboard/check-entities.sh`. Done when it exits 0 and you can explain each `UNAVAILABLE` or `UNKNOWN` line that it prints.
4. **Test locally.**
   - Run `nix run nixpkgs#nodejs -- --check k8s/apps/homeassistant/panel/home-panel.js`.
   - Serve the repo root with `python3 -m http.server 8765 --bind 127.0.0.1`. Open `harness.html` in this folder with Playwright, as its top comment shows.
   - Take screenshots at 390 px and 1600 px wide, of the home screen and of each page that you changed. Use `?set=<entity>=<state>` for the states that you must see.

   Done when both widths look correct and the console shows no errors. The harness data is fake, so tell the user that you did not see real data.
5. **Deploy.** Commit, push and open a PR to `main` on Forgejo (see `docs/agents/issue-tracker.md`). After the merge, Argo CD syncs the ConfigMaps, and the kubelet updates the mounted files within about a minute. Then increase the resource version and restart HA:

   ```bash
   P=$(kubectl -n homeassistant get pod -l app=homeassistant -o name)
   kubectl -n homeassistant exec $P -- sed -i 's#home-panel.js?v=[0-9]*#home-panel.js?v=<next>#' /config/.storage/lovelace_resources
   kubectl -n homeassistant delete $P
   ```

   HA keeps YAML dashboards in a cache, so a change to `glass.yaml` alone also needs the restart. Done when `curl -s http://10.10.40.13:8123/local/home-panel/home-panel.js` contains the new code and the HA log shows no Lovelace errors.

## House rules

The dashboard shows only true values. Each rule below protects that.

- **Swedish.** Write all text in Swedish. Format dates and times with `sv-SE`, and numbers with `num()` (decimal comma).
- **Real names.** Take names from the device registry or from the user. When you do not know the real name, ask. A guessed name is a false fact.
- **Honest labels.** A title or a total must match what the data measures. For example, the plug sensors show "Mätta enheter", because no meter measures the whole house.
- **Unavailable.** `_state()` and `_na()` show an unavailable entity dimmed with "Ej tillgänglig". The header shows an amber status for each smoke detector in `offline_alerts` that is offline.
- **Light groups.** Give a group `members:` so that it opens as an accordion. The room count counts the single lights.
- **Safe taps.** A tap toggles only lights and safe switches. Locks, the garage, the car and servers open the HA more-info dialog.
- **Icons.** Use `<ha-icon>` with an `mdi:` icon. Put a brand logo inline as SVG from Simple Icons (CC0), like `TESLA_LOGO`.
- **Motion.** Write animations in CSS only, in the block with the comment `Animations`. `prefers-reduced-motion` stops all of them.

## Known problems

- **Restarts.** Restart HA with `kubectl delete pod`. If you stop the HA process many times, the kubelet adds a back-off delay to each container restart.
- **Icon stub.** In the harness, the `ha-icon` stub must render into a shadow root. Children in the light DOM move the part markers of Lit.
- **Nord Pool units.** The service `nordpool.get_prices_for_date` returns SEK/MWh. The sensors give SEK/kWh.
- **iOS activity.** The phones send activity only with a location update. So `_presence()` ignores an activity value that is older than 20 minutes.
- **YAML anchors.** Merge keys (`<<: *anchor`) cause "duplicate key" warnings in the HA log. Write each entry in full.
