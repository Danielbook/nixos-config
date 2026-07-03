# k3s Cluster — Implementation Plan (execution-ready)

> Companion to [CLUSTER.md](./CLUSTER.md) (strategy/decisions). This is the
> stage-by-stage build. Check items off as you go. Stage A is unblocked and
> can start today; Stages B+ gate on the `endor` purchase and hardware.

## Locked inputs

| Thing | Value |
|-------|-------|
| Nodes | `naboo`=M80q (CP, **bootstrap — in hand, idle on desk**), `jupiter` (CP), `endor`=M70q (CP), `tatooine` (GPU worker) |
| Availability | **Free now:** `naboo` (M80q). **Incoming ~this week:** `endor` (M70q, bought @1,800 kr; needs a 16G stick). **Production until cutover:** `jupiter`, `tatooine` (GPU), `servarr` VM. |
| TrueNAS | `scarif` (Jonsbo N4) — storage backend, not a cluster node |
| OctoPi | `octopi` (Pi 3B+) — printer + Brio, off-cluster |
| Network | LAN `10.10.x` is **VLAN-segmented**: `.30` = servers/hypervisors (Proxmox, being decommissioned), `.40` = services. **Put the whole cluster — 4 nodes + scarif + MetalLB pool + VIP — in the `.40` services VLAN** (keeps service IPs where DNS/Traefik already point; storage stays intra-VLAN). k3s CIDRs unchanged (pods `10.42/16`, svc `10.43/16` — no clash with `10.10`). |
| API VIP | `kube.local.bookorjeman.com` → `10.10.40.5` (kube-vip) |
| MetalLB pool | small reserved `10.10.40.x` range (~8 IPs) for LoadBalancer svcs |
| Service domain | `*.local.bookorjeman.com` (existing convention, 33 services) → **OPNsense Unbound wildcard host override** (`*` / `local.bookorjeman.com` → Traefik LB IP) → LAN-only |
| Router/DNS/VPN | **OPNsense** (Unbound DNS + WireGuard server) — off-cluster; remote access survives cluster outages |
| Certs | cert-manager + **Cloudflare DNS-01** wildcard `*.local.bookorjeman.com` (⚠️ confirm `bookorjeman.com` zone is on Cloudflare) |
| Remote access | existing WireGuard on OPNsense |
| Secrets | SOPS + age (existing keys) → Argo via **ksops** |
| CSI | democratic-csi → scarif: **iSCSI** (mirror SSD pool, default SC) + **NFS** (HDD, RWX media) |
| GPU | GTX 1070 on tatooine; nvidia-container-toolkit + device plugin **time-slicing** so jellyfin (NVENC) + immich-ml (CUDA) share it |

**Reserved `.40` IPs** (Kea DHCP statics on OPNsense, all below the `.100+`
dynamic pool):

| Purpose | IP |
|---------|-----|
| API VIP (kube-vip) | `10.10.40.5` |
| naboo | `.13` |
| endor | `.14` |
| tatooine (GPU node) | `.12` *(existing reservation)* |
| jupiter (as node, after wipe) | `.30` *(existing box IP)* |
| MetalLB pool | `.50`–`.60` |
| scarif / TrueNAS mgmt | `.10` *(existing)* |

Existing `.40` occupants to route around: `.10` truenas-mgmt, `.11` servarr
(decommissioning), `.12` tatooine, `.20` mustafar, `.30` jupiter. **Correction:**
earlier text said device-services answer on "jupiter's `.10`" — wrong; `.10` is the
TrueNAS, jupiter is `.30`. Confirm the actual device-target IP (MQTT/UniFi) before
assigning the MetalLB service that reuses it.

**Reachability / firewall posture (OPNsense L3 rules):** clients reach
**service IPs (LoadBalancer / VIP), never node IPs.** Node IPs + API VIP + etcd
(2379-2380) are management/cluster-internal — reachable only from the admin VLAN
and node-to-node. Device/IoT VLANs get **allow-listed to only the specific LB
IP+port** they need (e.g. `mosquitto-LB:1883`, `traefik-LB:443`), denied the node
IPs/API. Nodes ↔ scarif storage stays intra-`.40` (off the router).

**Power protection (UPS + NUT)** — *deploy when the UPS arrives; no UPS today.*
- Hardware: line-interactive **pure-sine** UPS (APC Smart-UPS 1500). Measured load
  ~250–330W (switch ~60W, cluster ~150–220W, OPNsense ~20W; +~20–30W when the 4
  Reolink cameras are plugged in — currently they're not) ≈ 30% of 1500VA →
  ~15–20 min runtime. Plug in: all cluster nodes, `scarif`, the UniFi US-48
  switch, OPNsense.
- **NUT topology:** `scarif` (TrueNAS, USB-connected to the UPS) = NUT **master**
  (`upsd`+`upsmon`); the NixOS nodes run **`power.ups`** as NUT **clients**
  (`upsmon` slave → scarif's `upsd`). New small module
  `modules/nixos/services/nut-client` imported by each node.
- **Prioritized shutdown:** the compute nodes shut down **early** (e.g. at
  `runtime < 300s` / battery < ~50%) to protect etcd + databases; the switch /
  cameras / OPNsense are **not** NUT-managed and ride the remaining battery
  (stateless — they just need power). Short blip → all stays up; long outage →
  cluster down cleanly, cameras keep recording until the battery is spent.

---

## Stage A — Repo scaffolding (UNBLOCKED — do now, no hardware)

Goal: configs that `just flake-check` green, ready to deploy when `endor` lands.

> **Status: ✅ built & verified (2026-06-24).** `naboo` NixOS config evaluates to
> a valid system derivation; deadnix/statix/nixfmt clean. Home config matches the
> working `dagobah` pattern (verified by equivalence — its only eval dep is a
> linux IFD that can't build on darwin, exactly like the existing `coruscant`
> home). **Run `just flake-check` on coruscant (linux) to confirm green.**
> A6's cluster age key + `k8s/**` rule are **deferred to Stage E** (no `k8s/` dir
> yet). Before deploy: set `apiVip`/`vipInterface` (reserve `.40` IPs), static IP,
> and re-key `secrets.yaml` to add naboo's host key after first install.

- [ ] **A1.** `modules/nixos/services/k3s/default.nix` — wrap `services.k3s` with a
      small role option:
  - `first-server`: `role="server"`, `clusterInit=true`, `--tls-san <VIP>`,
    `--disable servicelb` (MetalLB instead), **`--disable traefik`** (own Traefik
    in Argo — Daniel has an extensive existing Traefik config to bring; gives the
    authentik middleware + MQTT TCP entrypoint).
  - `join-server`: `role="server"`, `serverAddr=https://<VIP>:6443`, token.
  - `agent`: `role="agent"`, `serverAddr`, token (tatooine).
  - Token from sops: `sops.secrets.k3s_token` → `sops.templates` →
    `/var/lib/rancher/k3s/server/token` (0600), mirroring
    `hosts/coruscant/default.nix:32`.
  - Firewall (LAN-scoped): 6443, 2379-2380 (servers), 8472/udp, 10250; plus
    kube-vip ARP.
- [ ] **A2.** kube-vip manifest as a k3s **auto-deploy** add-on (drop in
      `/var/lib/rancher/k3s/server/manifests/` via the module) on control-plane
      nodes, advertising the API VIP.
- [ ] **A3.** Per-node host dirs (**start with `hosts/naboo/`** — M80q is in hand;
      `endor` follows when bought):
      `default.nix` (imports `common` + the k3s module, **no** `desktop/*`),
      `hardware-configuration.nix` (generated on the box), `secrets.yaml`
      (sops k3s token). Add `disko.nix` for declarative partitioning.
- [ ] **A4.** `home/daniel/endor/default.nix` — minimal, imports only
      `${nhModules}/common`.
- [ ] **A5.** `flake.nix` — add `endor = mkNixosConfiguration "endor" "daniel";`
      and `"daniel@endor" = mkHomeConfiguration "x86_64-linux" "daniel" "endor" {};`
      (repeat per node later). Add `disko` to inputs.
- [ ] **A6.** `.sops.yaml` — creation_rule for `hosts/<node>/secrets.yaml`
      (node host key + daniel age key) for the k3s token. **Generate a dedicated
      cluster age key**; add a creation_rule for `k8s/**` encrypting to **cluster
      key + daniel key** (Argo decrypts with the cluster key; daniel = recovery).
      See [ADR 0001](./adr/0001-cluster-secrets-age-key.md).
- [ ] **Verify:** `just flake-check` + `just check-all` green with `endor` added.

---

## Stage B — Bootstrap node `naboo` (M80q) → 1-node cluster + platform validation

Gate: none. **Status: ✅ B1–B2 + VIP + endor join done (2026-07-01).** `naboo`
installed via `nixos-anywhere` on `10.10.40.13`; k3s `server-init` up. API VIP
`10.10.40.5` live via kube-vip. `endor` (M70q, `10.10.40.14`) joined as the 2nd
`server` control-plane — `naboo`+`endor` both `Ready control-plane,etcd`
(v1.35.4), **2-member etcd (no fault tolerance until jupiter, F2)**. kube-vip
`vipInterface` is left empty → auto-detects each node's default-route NIC
(naboo `eno2` / endor `eno1`); a hardcoded interface crashloops the odd node out.
endor sets `apiVip` only for `--tls-san=.5` so the VIP fails over to it cleanly.
MetalLB (B3) is live; **B4 dropped, B5 (Argo CD + ksops) done (2026-07-01)** —
platform layer (Stage B) complete. Next is Stage E (author workloads in `k8s/`).

**Reproducible node install (the proven flow — see [ADR 0002](./adr/0002-node-provisioning-host-keys.md)):**
1. Pre-generate the host key into an `--extra-files` dir
   (`ssh-keygen -t ed25519 -f <dir>/etc/ssh/ssh_host_ed25519_key -N ""`).
2. `ssh-to-age` its pubkey → add `&<node>` to `.sops.yaml`; `sops -e -i
   --input-type binary` the key into `hosts/<node>/ssh_host_ed25519_key.sops`;
   `sops updatekeys hosts/<node>/secrets.yaml`.
3. Boot the node on the installer USB → `sudo systemctl start sshd && sudo passwd root`.
4. `nix run github:nix-community/nixos-anywhere -- --flake .#<node>
   --target-host root@<ip> --extra-files <dir>`.
5. Host key matches the sops recipient → secrets decrypt on **first** boot → k3s
   starts; `daniel`'s `authorizedKeys` (the portable Bitwarden key in
   `modules/nixos/common`) gives SSH. Verify: `ssh daniel@<ip> 'systemctl
   is-active k3s && sudo k3s kubectl get node'`.

**Ongoing redeploys (already-installed nodes):** use the `just` recipes
(`build:.#` → activate on the target over SSH, no local `nixos-rebuild`):
`just deploy-naboo` / `just deploy-endor`, or **`just deploy-cluster`** for both.
Redeploy **BOTH** control-planes whenever a Nix-delivered k3s auto-deploy
manifest changes (`modules/nixos/services/{k3s,argocd,…}`) — they ship the same
manifests and drift/race otherwise.

> **Lockout gotcha:** headless nodes set `PermitRootLogin=no` +
> `PasswordAuthentication=off`, so a declared
> `users.daniel.openssh.authorizedKeys` (now in `common`) is the *only* way in —
> omit it and the node is unreachable after install.

- [x] **B1.** Installed via `nixos-anywhere` (disko wiped the 128G NVMe; host key
      pre-injected via `--extra-files`). `hardware-configuration.nix` is the
      generic M80q placeholder; disko owns the filesystems.
- [x] **B2.** k3s `server-init` up; `naboo Ready control-plane,etcd` v1.35.4.
- [x] **B3.** MetalLB (L2) v0.16.1 — auto-deployed via `services.k3s.manifests`
      (`modules/nixos/services/metallb`) on both servers; pool `10.10.40.50–.60`.
      Verified: controller + speaker Running, a `type=LoadBalancer` svc got `.50`
      and returned HTTP 200 from a `.40` client. `L2Advertisement` interface left
      unset (per-node auto-detect, like kube-vip). Argo adopts it into `k8s/infra`
      at Stage E (move out of the Nix module).
- [x] **B4. DROPPED (2026-07-01).** cert-manager is redundant: jupiter's Traefik
      already does Cloudflare DNS-01 for the wildcard `*.local.bookorjeman.com`
      (single-instance, proven), and cluster-Traefik reuses that resolver at Stage
      E3. Re-add only for Traefik HA (>1 replica races on local `acme.json`) or
      non-Traefik TLS consumers.
- [x] **B5.** Argo CD **v3.4.4** + **ksops v4.5.1** — auto-deployed via
      `services.k3s.manifests` (`modules/nixos/services/argocd`): pinned upstream
      `install.yaml` + a **build-time kustomize overlay** (renders one manifest:
      argocd Namespace, KSOPS strategic-merge patch on `argocd-repo-server`,
      `argocd-cm` `kustomize.buildOptions`). Nix owns the install; the Nix-delivered
      **root app-of-apps** tracks `k8s/infra` (public repo, anonymous HTTPS — sops
      keeps it safe). ksops decrypts `k8s/**/*.enc.yaml` in-cluster with the
      **dedicated cluster age key** (`.sops.yaml` `k8s/**` rule → cluster + daniel,
      ADR 0001). **One-time bootstrap:** cluster age private key `kubectl`-loaded
      out-of-band as secret `sops-age` in `argocd` (piped over ssh stdin, never on
      disk/git). Verified: root `Synced`+`Healthy`; a sops-encrypted test Secret
      decrypted into the cluster (smoke app, since torn down).
      **Also fixed a latent cluster-wide DNS bug** (`modules/nixos/services/k3s`):
      pods inherited `search local.bookorjeman.com` + k8s default `ndots:5`, so
      external short names got suffixed into the `*.local.bookorjeman.com` wildcard
      (→ Traefik) and were hijacked. Kubelet now gets a `--resolv-conf` without the
      LAN search domain. Would have broken every external-calling app at Stage E.
- [x] **B6.** **GPU smoke test deferred to Stage D** (GPU lives on tatooine).
      Device-plugin manifests render as part of the Stage E `k8s/infra` authoring.
- [x] **Verify:** VIP serves the API; MetalLB hands out `.50` (B3); Argo root app
      `Synced`+`Healthy` syncing from git; ksops decrypt proven. Ingress/cert path
      is validated at Stage E3 (Traefik reuses jupiter's resolver, B4 dropped).

---

## Stage C — `scarif` storage backend + CSI (still virtualized TrueNAS)

The TrueNAS VM keeps serving; bare-metal conversion is Stage G. **Bare-metal is
deliberately deferred** (evaluated 2026-07-01): scarif's Proxmox also hosts the
`servarr` VM (`10.10.40.11` — the arr-stack + authentik-outpost + navidrome),
which isn't on k3s yet, so wiping Proxmox now would kill it. And the 2×16TB media
mirror (`pool1`) is already full, so its export/import to bare metal costs the
same now or at G — there's no "migrate while empty" saving to capture. So: run
Stage C against the **VM's** TrueNAS API (democratic-csi doesn't care VM vs metal),
migrate servarr in Stage E1, then convert to bare metal at G once the box is
TrueNAS-only. `democratic-csi` uses **`iscsi` (RWO, DBs) + `nfs` (RWX, media)** —
best practice for a NAS-backed cluster; NFS-only would force DBs onto node-pinned
local-path.

- [ ] **C1.** New SSD → **raw-disk passthrough into the TrueNAS VM** (`qm set
      <vmid> -scsiN /dev/disk/by-id/<id>,discard=on,ssd=1`); create a **single-disk
      `ssd` pool** now (iSCSI zvols) — `zpool attach` the 2nd SSD into a **mirror**
      when it arrives. The **HDD pool** (`pool1`, 2×16TB mirror) already exists and
      serves media over NFS. Keep the SSD whole-disk (not a vdisk image) so the pool
      survives the Stage G export/import.
- [ ] **C2.** Dedicated democratic-csi API user + key; enable iSCSI + NFS.
- [ ] **C3.** democratic-csi via Argo: StorageClasses **`iscsi` (default)** +
      **`nfs`**. TrueNAS creds as a sops secret (ksops).
- [ ] **C4.** Snapshot tasks + intra-TrueNAS replication on both pools.
- [ ] **C5.** **Migrate Traefik's `acme.json` off `local-path` onto the `iscsi`
      SC** (E3 parked it on node-local `local-path` — survives pod restart but a
      reschedule to the other node re-issues the wildcard cert). Swap the
      `k8s/infra/traefik.yaml` `persistence.storageClass` to `iscsi`.
- [ ] **Verify:** PVC on each SC binds; pod writes, deletes, reschedules to
      another node (after Stage D), data persists; zvol/export visible in scarif.

---

## Stage D — tatooine GPU node + media mini-cutover (~1 week before the rest migrates)

Decision: validate the scariest step (GPU-in-k3s) on real hardware *before* the rest of the migration. Wiping tatooine takes its media stack down, so jellyfin/immich/seerr
**migrate now** as their own mini-cutover — a planned short outage. Gate: Stage C
(CSI) done + media pre-synced to scarif + media manifests authored (Stage E).

- [ ] **D1.** Build `hosts/tatooine/` (Stage A pattern) + GPU module:
      `hardware.nvidia` + `nvidia-container-toolkit` wired into k3s' containerd.
      flake + sops entries; `flake-check`.
- [ ] **D2.** Planned jellyfin/immich outage. Wipe tatooine → NixOS, join as
      `agent` (GPU worker). Label/taint for GPU workloads.
- [ ] **D3.** NVIDIA device plugin + **time-slicing** (e.g. 3 replicas) so
      jellyfin (NVENC) + immich-ml (CUDA) share the 1070.
- [ ] **D4.** Migrate media stack: jellyfin, immich (pg on iSCSI, library on
      NFS), seerr, *arr + gluetun. Restore data.
- [ ] **Verify:** a CUDA pod sees the GPU; jellyfin does a HW transcode; immich
      ML runs; `*arr→download→jellyfin` path works. **This proves the GPU path
      with a 1-week safety margin before the rest cuts over.**

> **etcd quorum timeline:** buy `endor` early and join it as a 2nd control-plane
> so this and later stages run on `naboo`+`endor` (2-member etcd) + tatooine
> (agent). A 2-member etcd has **no fault tolerance** (needs both up) — fine as a
> transient migration state, don't camp on it. **Full 3-node HA is reached when
> `jupiter` is wiped and joins last** (Stage F2).

---

## Stage E — Author all workloads in `k8s/` (the bulk of the work)

Argo app-of-apps. Structure: `k8s/infra/` (metallb, traefik [does its own
Cloudflare DNS-01, cert-manager dropped — see B4], democratic-csi, nvidia-plugin,
kube-vip) + `k8s/apps/` (one dir per service).
Do this **before** cutover so the weekend is just apply + restore.

- [ ] **E1.** Convert each current container → manifest/Helm release. PV from
      `iscsi` SC for app/DB data, `nfs` SC for media (RWX). Secrets via ksops.
  - Stateless: homepage, linkding, mealie, navidrome, seerr.
  - Media: jellyfin (NVENC, on tatooine), immich (pg on iSCSI, library on NFS,
    `nvidia.com/gpu` for ML, on tatooine).
  - **Downloaders (VPN pod):** one pod = gluetun + deluge + nzbget + prowlarr
    sharing the netns; pod-mates egress through the tunnel, gluetun kill-switch
    protects all. Preserve gluetun VPN **port-forwarding** for deluge.
  - ***arr (float):** sonarr/radarr/lidarr/bazarr as normal pods (no VPN), reach
    the downloaders + prowlarr via a Service.
  - **Shared downloads volume:** the completed-downloads dir must be one **NFS
    (RWX)** PVC mounted by *both* the VPN pod and the *arr pods, with identical
    mount paths, so imports work.
  - Critical: vaultwarden, authentik (pg+redis), unifi (mongo), home-assistant.
  - Monitoring: **migrate influxdb** (home-metrics history, data → PV) +
    **grafana** (dashboards; add Prometheus datasource); **loki fresh** (logs
    transient); **add kube-prometheus-stack** for cluster observability.
- [ ] **E2.** **HA pinning:** keep the garage Arduino plugged into jupiter; pin
      `home-assistant` → `nodeSelector: jupiter` + mount `/dev/ttyACM*`. So HA
      migrates **last, with jupiter** (no physical move now). Zigbee/Matter are
      Ethernet → no pin. Everything else floats. *Deferred (optional later):*
      relocate the Arduino or stand up a ser2net bridge to let HA float freely.
- [x] **E3. DONE (2026-07-01).** Traefik (Helm chart 41.0.1 / Traefik v3.7.5) via
      an Argo Helm app (`k8s/infra/traefik.yaml`). Wildcard `*.local.bookorjeman.com`
      generated once via the Cloudflare DNS-01 resolver and served as the default
      cert through a **`TLSStore` `default` `defaultGeneratedCert`** (the entrypoint
      `certResolver`/`domains` approach did NOT trigger issuance — TLSStore is what
      works in k8s Traefik; per-entrypoint certResolver omitted on purpose to avoid
      per-HOST issuance). CF token via ksops (`k8s/traefik/cf-token.enc.yaml`). The
      `mkRoute` helper is a local Helm chart (`k8s/charts/ingress`): `default-headers`
      + `authentik-forwardauth` middlewares ported verbatim + rendered once, each app
      one `{name,port,auth?}` line in `k8s/infra/ingress.yaml` (http→https handled
      natively at the web entrypoint, not a middleware). `providers.kubernetesCRD.allowCrossNamespace=true`
      so IngressRoutes in the `traefik` ns reach Services in app namespaces. acme.json
      on `local-path` (→ iscsi at C5). MetalLB adopted out of the Nix module into
      `k8s/infra/metallb.yaml` (LB IP `10.10.40.51`). Verified: valid LE wildcard
      (issuer Let's Encrypt), whoami HTTP/2 200 routed by Host header; also deployed
      Headlamp dashboard + a local `~/.kube/config` (VIP) for k9s. **DNS:** single
      OPNsense override per cluster app → `.51` for now; full wildcard cutover at E4.
  <details><summary>Original E3 design (for reference)</summary>

  Ingress on `*.local.bookorjeman.com` — **templated, not one hand-
      written dynamic file per service** (that's the docker file-provider habit;
      drop it). Reuse jupiter's proven Traefik config (`/srv/traefik`, v3.3,
      already serves the wildcard via its **own Cloudflare DNS-01 resolver** — so
      **cert-manager is redundant**, see B4 note). Structure:
      - **Shared once:** the wildcard TLS on the `websecure` entrypoint (per-route
        `tls:` block disappears), plus the `default-headers` / `https-redirect` /
        `authentik-forwardauth` middlewares (port jupiter's `dynamic/*.yml`
        middlewares verbatim, referenced by name).
      - **Cluster-native apps:** no route file. A ~30-line library/helper template
        (`mkRoute name port [auth]`) renders each app's IngressRoute from the
        `name`+`port` its own chart already defines — `Host(<name>.local.…)` →
        Service, wildcard cert inherited. Adding a service adds **nothing**.
      - **DNS:** **one-time, single** OPNsense Unbound record —
        `*.local.bookorjeman.com → Traefik LB IP` (Host Override host `*`, or
        `local-zone: "local.bookorjeman.com." redirect` + one `local-data` A).
        Traefik routes by Host header → **adding a service needs no DNS change**.
        Pod-to-pod uses CoreDNS; no external-dns. (Non-HTTP LB services like
        mosquitto are IP-targeted and need no DNS at all.)

  </details>
- [ ] **E4.** **External-services bucket** — the `/srv/traefik/dynamic/*.yml`
      routers pointing at **non-cluster IPs** (OPNsense `router`, `truenas`/scarif,
      `n4`, `unifi`, `slzb`, `andromeda`, octoprint, …) collapse into **one values
      list + one `range` template**, not a file each:
      `- { host: truenas, url: http://10.10.40.10 }` /
      `- { host: router, url: https://192.168.1.1, insecure: true, auth: true }`.
      The template emits the IngressRoute (+ Service-without-selector/external URL)
      and attaches authentik forward-auth when `auth: true`. New external target =
      **one line**. k8s-Traefik becomes the whole-homelab front door, replacing
      jupiter's. (Cruft to leave behind on jupiter: 2.4G unrotated `logs/`,
      `_removed/`, `*.backup*`.)
- [ ] **E5.** **Device-facing services** (mosquitto MQTT 1883, unifi controller
      inform 8080 / STUN 3478, HA if needed) → dedicated **MetalLB LoadBalancer
      IPs**, not ingress. **Reuse the IPs devices already target** to avoid
      reconfiguring every ESPHome/zigbee device and re-adopting the UniFi fleet.
      Caveat: those services currently answer on **jupiter's host IP**
      (`10.10.40.10`) — so give the **node a fresh IP** and assign the old
      `.40.10` to the MQTT/unifi LoadBalancer service. Reserve these specific IPs
      in the MetalLB pool.
- [ ] **Verify (dry):** every app Healthy in Argo against empty PVs / test data
      before real data lands.

---

## Stage F — Gradual migration onto naboo+endor+tatooine (jupiter stays as fallback)

Migrate the remaining services off jupiter/servarr onto the running 3-node
cluster, **service by service, with jupiter still serving as a live rollback.**
Nothing on jupiter is destroyed until everything is verified on the cluster.

- [ ] **F1.** Per service (authentik first — it gates the others' forward-auth,
      then vaultwarden, unifi, monitoring, homepage/linkding/mealie/navidrome):
      sync data to scarif → restore into PV → bring up via Argo → verify →
      cut its internal DNS over to the Traefik LB IP. Old container stays up
      until verified.
- [ ] **F2.** HA is the last service still on jupiter. **Wipe jupiter → NixOS,
      join as the 3rd `join-server`** (Arduino stays plugged in). → etcd reaches
      **3-member HA quorum**; +16G headroom.
- [ ] **F3.** Migrate HA into the cluster pinned to jupiter-the-node + mount
      `/dev/ttyACM*`; verify Zigbee/Matter (Ethernet) + garage door work.
      (Brief garage/HA downtime during the wipe — acceptable.)
- [ ] **Verify:** `kubectl get nodes` → 4 Ready, 3 CP; etcd 3-member quorum;
      drain/reboot one CP node → VIP/API stays up. Full smoke test (auth, data,
      GPU transcode, garage door, *arr→download→jellyfin).
- [ ] **Rollback:** each service's old container stays up until its cluster
      counterpart is verified; DNS cutover is per-service and reversible.
      jupiter (the last box) isn't wiped until the whole cluster is green.

---

## Stage G — Convert `scarif` to bare-metal TrueNAS

Gate: nothing left on the Jonsbo/Proxmox box (servarr pods live in-cluster).

- [x] **G0 (precondition — RESOLVED).** Verified in Proxmox (VM 100 on node `n4`):
      data pool = **2× 16TB Seagate Exos passed through raw via `/dev/disk/by-id`**
      (scsi1/scsi2) → **pool imports cleanly on bare metal**. The only virtual
      disk (scsi0, 32G local-lvm) is the disposable TrueNAS OS boot — reinstall
      it fresh on bare metal. Export/import path (G1–G3) is valid as written.
      (servarr = VM 101 on the same `n4` host.)
      - [ ] Confirm the 2×16TB HDD pool layout (mirror vs stripe).
      - [ ] SSD mirror pool for iSCSI app/DB PVs = **hardware to add** to the N4.

- [ ] **G1.** Export ZFS pools (clean shutdown) in the TrueNAS VM.
- [ ] **G2.** Wipe Proxmox; install TrueNAS SCALE bare-metal; **import** pools
      (intact via passthrough).
- [ ] **G3.** Re-point democratic-csi at the new IP/API if changed.
- [ ] **Verify:** PVs reconnect; immich reads its library.

---

## Stage H — Cleanup, docs, future

- [ ] **H1.** Decommission Proxmox everywhere.
- [ ] **H2.** Update `CLAUDE.md` host table, `docs/ARCHITECTURE.md` (k3s module +
      server layer), `docs/FEATURES.md`. Keep CLUSTER.md current.
- [ ] **H3.** `just check-all` green; commit.
- [ ] **Future:** offsite backup for **immich photos + vaultwarden** (the two you
      flagged) — restic/ZFS-replication to a cloud bucket. RAM 16→32G/node when
      memory requests pass ~80% (see CLUSTER.md capacity section).

---

## Critical path (TL;DR)
`A (repo, now)` → `B (naboo bootstrap + platform, in hand)` → buy **endor**, join
as 2nd CP → `C (scarif + CSI)` → `E (author manifests)` → `D (tatooine + media,
GPU validate)` → `F (gradual migrate rest; jupiter as fallback → wipe jupiter
last → 3-node HA)` → `G (bare-metal TrueNAS)` → `H`.

**Cutover model:** gradual with jupiter as a live hot-fallback, **not** big-bang.
Destructive wipes happen only after each piece is verified on the cluster;
jupiter — the last box — is wiped only when everything else is green.
