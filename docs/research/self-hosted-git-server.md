# Research: self-hosted git server for the homelab

> Status: research note (2026-07-17). Question: which self-hosted git server
> should run in the homelab for personal app repos, instead of pushing
> everything to GitHub — given the k3s/Argo CD GitOps setup, Authentik OIDC
> SSO, and a single user. Candidates evaluated against primary sources
> (official docs, source repos, release notes).

## TL;DR recommendation

**Forgejo**, deployed **in-cluster** via the official Helm chart following the
existing `k8s/apps/<name>` + `k8s/infra/<name>.yaml` conventions, with:

1. **Authentik OIDC** login (Authentik ships a dedicated Forgejo guide),
2. **push mirrors to GitHub on every repo** (triggered on push) as offsite
   backup and bootstrap escape hatch,
3. **`nixos-config`'s Argo CD root app keeps pulling from GitHub** — the repo
   that rebuilds the cluster must never depend on the cluster (see the
   bootstrap section below). App repos can use Forgejo as their Argo source.
4. CI later, if wanted: **Forgejo Actions** (GitHub-Actions-style workflows,
   separate `forgejo-runner`) — no extra service beyond the runner.

Footprint is sub-GB (Gitea-family Go binary + SQLite), well inside the
cluster's ~37G workload budget ([CLUSTER.md](../CLUSTER.md)).

---

## 1. Candidates

### Forgejo — recommended

- **Footprint**: no official minimums published; docs recommend SQLite3 for
  "low to moderate activity" and explicitly target small instances
  ([installation](https://forgejo.org/docs/latest/admin/installation/),
  [recommendations](https://forgejo.org/docs/latest/admin/setup/recommendations/)).
  Same Go codebase family as Gitea, whose docs state 2 cores / 1 GB RAM is
  sufficient and that it runs on a Raspberry Pi 3
  ([docs.gitea.com](https://docs.gitea.com/)). Real-world: a few hundred MB.
- **Helm chart**: official, at
  [code.forgejo.org/forgejo-helm/forgejo-helm](https://code.forgejo.org/forgejo-helm/forgejo-helm),
  OCI `oci://code.forgejo.org/forgejo-helm/forgejo` (chart v17 → Forgejo v15).
  Since chart v14 the bundled Postgres/Valkey deps are removed — built-in
  SQLite is fine single-user. Do not set `replicaCount > 1` (not HA-ready
  without external DB + Valkey).
- **OIDC / Authentik**: first-class — Authentik publishes a Forgejo
  integration guide (OpenID Connect authentication source + discovery URL,
  `ENABLE_AUTO_REGISTRATION: true`):
  [integrations.goauthentik.io/development/forgejo/](https://integrations.goauthentik.io/development/forgejo/).
  Forgejo is also itself an OAuth2 *provider*
  ([docs](https://forgejo.org/docs/latest/user/oauth2-provider/)) — useful for
  chaining Woodpecker or Argo CD SSO off it.
- **CI**: Forgejo Actions — workflows in `.forgejo/workflows`, GitHub-Actions
  syntax ("similar and compatible", not 1:1); separate `forgejo-runner`
  binary/container that pulls jobs from the instance; docs warn to isolate the
  runner (it is remote code execution)
  ([admin/actions](https://forgejo.org/docs/latest/admin/actions/)).
- **Push mirrors to GitHub**: Settings → Repository → Mirror Settings; GitHub
  via PAT or auto-generated Ed25519 key; periodic (default interval 8h, min
  10m via `[mirror]` in app.ini) **plus "Sync when new commits are pushed"**
  for immediate propagation; force-pushes the remote
  ([forgejo repo-mirror docs](https://forgejo.org/docs/latest/user/repo-mirror/),
  [gitea config cheat-sheet](https://docs.gitea.com/administration/config-cheat-sheet)).
  Pull mirrors (GitHub → Forgejo) can only be created at migration time.
- **Governance / health**: created in reaction to the 2022 Gitea Ltd takeover;
  domains held by Codeberg e.V. (Berlin nonprofit), community governance
  ([FAQ](https://forgejo.org/faq/)); **hard fork since Feb 2024**
  ([Forking Forward](https://forgejo.org/2024-02-forking-forward/)). Quarterly
  majors with a **yearly LTS train** — v15 LTS supported until 2027-07-15,
  v16.0 stable released 2026-07-16
  ([releases](https://forgejo.org/releases/),
  [release schedule](https://forgejo.org/docs/v11.0/admin/release-schedule/)).
  LTS + on-push mirroring = low-touch, which fits this homelab.
- **NixOS**: `services.forgejo` module exists in nixpkgs (freeform `settings`
  → app.ini, sqlite3/postgres, secrets via systemd LoadCredential, scheduled
  `dump` backups; default package is forgejo-lts)
  ([nixos/modules/services/misc/forgejo.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/forgejo.nix),
  [wiki.nixos.org/wiki/Forgejo](https://wiki.nixos.org/wiki/Forgejo)) —
  relevant only if the out-of-cluster variant is ever preferred (§3).

### Gitea — functionally equivalent, governance worse

- Footprint: 2 cores / 1 GB RAM officially sufficient
  ([docs.gitea.com](https://docs.gitea.com/)). Official Helm chart
  ([gitea.com/gitea/helm-gitea](https://gitea.com/gitea/helm-gitea)) — but it
  bundles Bitnami postgresql-ha + valkey-cluster **enabled by default** (HA
  default since chart 9.0.0); you'd strip that down for single-user.
- Authentik guide exists
  ([integrations.goauthentik.io/development/gitea/](https://integrations.goauthentik.io/development/gitea/));
  Gitea Actions enabled by default since 1.21
  ([release](https://blog.gitea.com/release-of-1.21.0/)); push mirrors with
  on-push sync since 1.18 ([docs](https://docs.gitea.com/usage/repo-mirror)).
- **Governance**: 2022-10-25 domains + trademark moved to for-profit Gitea Ltd
  without community consultation; 48 contributors' demands
  ([open letter](https://gitea-open-letter.coding.social/)) were rejected —
  which is what spawned Forgejo. Actively developed, but no reason to prefer
  it over Forgejo here.

### GitLab CE — disqualified on resources and ops burden

- Single-node baseline **8 vCPU / 16 GB RAM** (floor 8 GB with tuning); the
  cloud-native Helm chart "is intended to fit in a cluster with at least
  8 vCPU and 30 GB of RAM"
  ([requirements](https://docs.gitlab.com/install/requirements/),
  [charts](https://docs.gitlab.com/charts/)) — that is most of the cluster's
  HA-headroom RAM budget for one user's git hosting.
- Monthly minor releases, patches twice monthly, mandatory upgrade paths with
  required stops ([maintenance policy](https://docs.gitlab.com/policy/maintenance/)).
- For the record: OIDC (`omniauth_openid_connect`) and push mirroring are both
  in the Free tier
  ([OIDC](https://docs.gitlab.com/administration/auth/oidc/),
  [push mirroring](https://docs.gitlab.com/user/project/repository/mirror/push/));
  GitLab CI is excellent. Wrong size regardless.

### Gerrit — wrong shape

Code-*review* system (change/patchset workflow), not a general forge — no
issues/releases UI. Its k8s story is an operator aimed at large installs
([GerritCodeReview/k8s-gerrit](https://github.com/GerritCodeReview/k8s-gerrit));
OIDC only via plugin
([gerrit-oauth-provider](https://github.com/davido/gerrit-oauth-provider)).
Multi-reviewer ceremony has no value for one user.

### Plain git over SSH / gitolite — works, forfeits everything else

Bare repos over sshd: zero services, but no web UI, no webhooks (Argo CD falls
back to 3-min polling), no CI, mirroring only via cron `git push --mirror`.
gitolite's ACL engine is moot single-user and the project is near-dormant
(~1–3 commits/year;
[commit history](https://github.com/sitaramc/gitolite/commits/master)).

### soft-serve — charming, but no web UI and no OIDC

SSH-first server with a terminal UI; has webhooks, LFS, mirroring; **no web
UI, no CI, auth is SSH keys only** — no Authentik integration possible
([README](https://github.com/charmbracelet/soft-serve)). Active (v0.11.6,
2026-03-19), Docker image but no official Helm chart.

### OneDev — capable, single-maintainer risk

Built-in CI/CD (k8s executors), kanban, package registries; MIT; official k8s
deployment docs ([docs.onedev.io](https://docs.onedev.io/installation-guide/deploy-to-k8s))
and a Helm chart on [Artifact Hub](https://artifacthub.io/packages/helm/onedev/onedev);
generic OIDC SSO ([Okta tutorial](https://docs.onedev.io/tutorials/security/sso-with-okta));
claims 1 core / 2 GB (Java, so ~1 GB+ heap in practice). Mirroring is not
native — done via CI job steps
([repo-mirror tutorial](https://docs.onedev.io/tutorials/code/repo-mirror)).
Effectively one primary maintainer (@theonedev) — bus-factor risk for the
thing holding all your source.

### CI note: Woodpecker

Woodpecker has a dedicated Forgejo forge driver
([docs](https://woodpecker-ci.org/docs/administration/configuration/forges/forgejo));
login is via the forge's OAuth2 app, so SSO chains Authentik → Forgejo →
Woodpecker. Only worth adding if Forgejo Actions proves insufficient — start
with Actions (one runner, no extra web service).

---

## 2. The GitOps bootstrap problem

Argo CD currently pulls `https://github.com/Danielbook/nixos-config.git`
anonymously (`modules/nixos/services/argocd/default.nix`). Pointing it at a
git server that runs *on* the cluster creates two failure modes:

**a) Git server down ≠ cluster down.** Argo CD is a reconciliation controller,
not in the serving path: already-applied resources keep running; what stops is
refresh/compare/sync (status degrades to Unknown/ComparisonError) and
self-heal/prune of drift — new changes freeze, workloads don't
([argoproj/argo-cd#17623](https://github.com/argoproj/argo-cd/issues/17623),
[#19920](https://github.com/argoproj/argo-cd/issues/19920)). Default git poll
is every 3 min (`timeout.reconciliation`,
[FAQ](https://argo-cd.readthedocs.io/en/stable/faq/)).

**b) Cluster rebuild needs git, git needs the cluster.** If the *only* copy of
the manifests lives in-cluster, a full rebuild has nothing to bootstrap from.

Mitigations (all documented upstream):

- **Push-mirror every Forgejo repo to GitHub with on-push sync**
  ([forgejo repo-mirror](https://forgejo.org/docs/latest/user/repo-mirror/)) —
  near-real-time offsite copy. On disaster, Argo CD is repointed at GitHub.
- **Keep `nixos-config`'s root app on GitHub permanently** (this note's
  recommendation): the repo that *bootstraps* Argo CD and the nodes stays
  outside the dependency loop entirely. Day-to-day pushes can go to Forgejo
  with the push mirror fanning out to GitHub, or straight to GitHub as today —
  either way the bootstrap source is off-cluster.
- **Repo credentials are just Secrets** labeled
  `argocd.argoproj.io/secret-type: repository`
  ([declarative setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)) —
  the Nix layer that already delivers the root app can deliver/repoint these
  without a working GitOps loop.
- **Emergency sync from a laptop checkout**: `argocd app sync --local <dir>`
  makes no git queries at all
  ([CLI docs](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_sync/)).
- **Re-bootstrap** = what the Nix module already does: install Argo CD + apply
  the root app against a reachable repo
  ([cluster bootstrapping](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)).
  `argocd admin export/import` exists
  ([disaster recovery](https://argo-cd.readthedocs.io/en/stable/operator-manual/disaster_recovery/))
  but is largely redundant in this fully declarative setup.

## 3. In-cluster vs out-of-cluster Forgejo

Out-of-cluster (NixOS `services.forgejo` on a node or separate box) breaks the
self-reference completely — git survives cluster wipes and is rebuilt by
`nixos-rebuild`. But this homelab's locked decision is "nodes stateless,
workloads in the cluster, data on scarif" ([CLUSTER.md](../CLUSTER.md)), and
there is no spare always-on non-cluster host. **In-cluster + on-push GitHub
mirror + GitHub-hosted bootstrap repo** gets ~the same safety without breaking
that boundary: the only scenario where the mirror doesn't save you is
simultaneous loss of cluster *and* GitHub, and even then scarif's ZFS
snapshots hold the Forgejo PV.

## 4. Concrete deployment sketch

- `k8s/apps/forgejo/` — official Helm chart via an Argo CD Application
  (`oci://code.forgejo.org/forgejo-helm/forgejo`), SQLite, single replica,
  PVC on the democratic-csi iSCSI class (repos + DB are the state; scarif
  snapshots back it up).
- Ingress: Traefik at `git.local.bookorjeman.com` (per-app Unbound override —
  see the DNS-wildcard caveat) for HTTPS; SSH clone either via a MetalLB
  `LoadBalancer` Service on port 22 (cleanest) or Forgejo's built-in SSH on an
  alternate NodePort.
- Auth: Authentik OIDC provider `forgejo`, config per
  [integrations.goauthentik.io/development/forgejo/](https://integrations.goauthentik.io/development/forgejo/);
  client secret via the usual sops/ksops `*.enc.yaml` pipeline.
- Every repo: push mirror → GitHub (PAT in Forgejo), "sync on push" enabled.
- `nixos-config` root app: **leave `repoURL` on GitHub.**
- Later: one `forgejo-runner` (Deployment, docker-in-docker or host executor
  on a labeled node) if CI is wanted.

## Comparison table

| Candidate | RAM class | Official Helm chart | Authentik OIDC | CI | GitHub push mirror | Governance |
|---|---|---|---|---|---|---|
| **Forgejo** | ~0.2–0.5 G | Yes (code.forgejo.org) | Yes (official guide) | Forgejo Actions | Native, on-push | Nonprofit-custodied, yearly LTS |
| Gitea | ~0.2–0.5 G | Yes (HA-heavy defaults) | Yes (official guide) | Gitea Actions | Native, on-push | For-profit Gitea Ltd |
| GitLab CE | 16–30 G target | Yes (huge) | Yes | GitLab CI | Yes (Free) | GitLab Inc; monthly mandatory upgrades |
| Gerrit | Java, heavy | Operator (large-scale) | Plugin only | No | No | Google-adjacent; review tool, not forge |
| Bare git/gitolite | ~0 | n/a | No | No | cron only | gitolite near-dormant |
| soft-serve | tiny | No | No (SSH keys only) | No | Mirroring yes | Charmbracelet, active |
| OneDev | ~1–2 G (Java) | Community/ArtifactHub | Generic OIDC | Built-in | Via CI jobs | Single maintainer |
