# Local-AI automations — implementation plan

Source spec: HANDOVER (ntfy, email triage, news digest). One phase per PR; stop
for review after each.

## Decisions

| Topic | Decision |
|---|---|
| Deploy | Argo app-of-apps: `k8s/infra/<app>.yaml` + `k8s/apps/<app>/` (+ `k8s/<app>/` ksops + `k8s/infra/<app>-secret.yaml` when secrets) |
| Secrets | sops/age `*.enc.yaml`, ksops in-cluster |
| Hosts | `<name>.local.bookorjeman.com`, one line in `k8s/infra/ingress.yaml`, wildcard cert (cert-manager). One OPNsense Unbound override per host (never `*`) |
| Storage | sqlite/state on `iscsi` RWO PVCs |
| Ollama | `http://ollama.ollama.svc.cluster.local:11434`, model `qwen2.5:7b-instruct-q4_K_M` |
| Postgres | per-app `postgres:16-alpine` on iscsi (authentik/fartlek pattern) |
| Mail | websupport.se, IMAP `imap.websupport.se:993`, mailbox password (Dovecot; IDLE + custom keywords expected — verify) |
| Code | one Forgejo repo `danielbook/c3po`, one image, two entrypoints (`mail-triage`, `news-digest`), image pinned to git sha; CI = rootless BuildKit (kaniko is archived) |
| Phone | iPhone WireGuard on-demand in place → ntfy content fetch works off-LAN |
| Watchdog | **skipped** (no healthchecks.io). Known gap: a full outage goes unnoticed |
| Homepage | `services.yaml` is on the PVC (not git) — edit via `kubectl exec`; ntfy link tile, Miniflux `miniflux` widget |

## GPU reality

tatooine's GTX 1070 is shared by ollama (HA Jarvis, Mealie, Open WebUI), holocron
(whisper ≈3 GB + llama3.1 cleanup) and Jellyfin NVENC. HA Assist requests take
25–70 s, so with `NUM_PARALLEL=1` a mail can queue behind one; 1–2 s/mail holds
only on an idle GPU. Watch `ollama ps` for reload churn if HA sends a different
`num_ctx` than the triage service — match it rather than raise it.

## Phase 0 — Ollama tuning

- `k8s/apps/ollama/ollama.yaml`: env `OLLAMA_NUM_PARALLEL=1`,
  `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_KEEP_ALIVE=-1`.
- `k8s/apps/holocron/holocron.yaml`: `OLLAMA_MODEL` → `qwen2.5:7b-instruct-q4_K_M`
  (stop evicting qwen).
- Verify: `ollama ps` shows qwen resident; `nvidia-smi` headroom for holocron; a
  Jellyfin transcode still works.

## Phase 1 — ntfy

- `k8s/infra/ntfy.yaml`, `k8s/infra/ntfy-secret.yaml`, `k8s/apps/ntfy/ntfy.yaml`,
  `k8s/ntfy/{kustomization,secret-generator,ntfy-config.enc.yaml}`.
- ns `ntfy`, 1Gi iscsi PVC (`cache.db`, `user.db`), Recreate Deployment, pinned
  `binwiederhier/ntfy:v2.x`, Service :80.
- `server.yml` (sops Secret — holds bcrypt hashes + tokens): `base-url`,
  `behind-proxy: true`, `upstream-base-url: https://ntfy.sh`,
  `auth-default-access: deny-all`, declarative `auth-users`/`auth-access`/
  `auth-tokens`: `daniel` (read all topics), `publisher` (token, write
  `email,news,homelab,security`).
- Ingress route `ntfy`, no forward-auth (iOS app/API). Unbound override.
- Homepage link tile. Docs: `docs/FEATURES.md`, `docs/CLUSTER.md`.
- Verify: token curl per topic from a pod lands on iPhone; anonymous publish → 403.

## Phase 2 — mail-triage

- `c3po` repo: `imap-tools` + `httpx`, Dockerfile, Forgejo CI (rootless BuildKit).
- IDLE (5 min timeout) → fallback poll; fetch `UID > last`, `mark_seen=False`;
  `last_uid` + `UIDVALIDITY` in a file on a 1Gi iscsi PVC.
- Ollama: `format` = JSON schema (`category` enum from ConfigMap, `important`
  bool, `summary` str), `temperature: 0`; input = from, subject, first 1000 chars.
  Few-shots first in the prompt (prefix cache reuse), mail last.
- ConfigMap: categories, `few-shot.txt`, quiet hours, flags `move`,
  `flag_colors`, `notify` — all `false`. Secret: IMAP creds, ntfy token.
- stdout JSON line per mail: message-id, from, subject, category, important,
  latency_ms.
- `k8s/apps/mail-triage/`: Deployment (Recreate), PVC, ConfigMap. No ingress, no
  Homepage tile (no UI).
- Test `$MailFlagBit0-2` against websupport before enabling `flag_colors`.
- Verify: 24 h, 0 restarts; `kubectl logs deploy/mail-triage | jq`.

## Phase 3 — Miniflux + news-digest

- ns `miniflux`: pinned `miniflux/miniflux:2.x` + `miniflux-postgres`; Secret
  (`DATABASE_URL`, admin pw, pg pw); route `miniflux`, no forward-auth
  (Reeder/NetNewsWire API). Feeds via one-time OPML import
  (`k8s/apps/miniflux/feeds.opml` kept for the record); "fetch original" on
  excerpt feeds.
- Evaluate miniflux-ai (~1 h). Expected miss: no 0–10 relevance, no dedupe, no
  release classification → custom `news-digest` entrypoint.
- CronJob daily 06:00: unread entries → LLM `{score 0-10,
  kind: normal|breaking|security|none, summary}` vs interest-profile ConfigMap;
  keep ≥7; dedupe by `difflib` title similarity + canonical URL; HN/Lobsters add
  `comments_url`; cap 15; publish to `news` (split if > 4 KB); mark read.
- CronJob hourly, `releases` category only: `security` → push `security` now;
  don't mark read (daily run still picks up breaking changes).
- Priority: email is realtime, digest runs at a quiet hour — no shared queue.
- Homepage: Miniflux tile + `miniflux` widget (key in `homepage-env`).
- Verify: `kubectl create job --from=cronjob/news-digest ...` → ≤15 items on
  iPhone; mail latency unaffected while it runs.

## Out of scope

Bill extraction, Paperless, Alertmanager triage, HA Assist, Frigate GenAI,
external watchdog.
