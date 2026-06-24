# k3s Cluster — Implementation Plan (execution-ready)

> Companion to [CLUSTER.md](./CLUSTER.md) (strategy/decisions). This is the
> stage-by-stage build. Check items off as you go. Stage A is unblocked and
> can start today; Stages B+ gate on the `endor` purchase and hardware.

## Locked inputs

| Thing | Value |
|-------|-------|
| Nodes | `naboo`=M80q (CP, **bootstrap — in hand, idle on desk**), `jupiter` (CP), `endor`=M70q (CP), `tatooine` (GPU worker) |
| Availability | **Free now:** `naboo` (M80q). **Not yet bought:** `endor` (M70q). **Production until cutover:** `jupiter`, `tatooine` (GPU), `servarr` VM. |
| TrueNAS | `scarif` (Jonsbo N4) — storage backend, not a cluster node |
| OctoPi | `octopi` (Pi 3B+) — printer + Brio, off-cluster |
| Network | LAN `10.10.x` is **VLAN-segmented**: `.30` = servers/hypervisors (Proxmox, being decommissioned), `.40` = services. **Put the whole cluster — 4 nodes + scarif + MetalLB pool + VIP — in the `.40` services VLAN** (keeps service IPs where DNS/Traefik already point; storage stays intra-VLAN). k3s CIDRs unchanged (pods `10.42/16`, svc `10.43/16` — no clash with `10.10`). |
| API VIP | `kube.local.bookorjeman.com` (kube-vip, an unused `10.10.40.x` IP) |
| MetalLB pool | small reserved `10.10.40.x` range (~8 IPs) for LoadBalancer svcs |
| Service domain | `*.local.bookorjeman.com` (existing convention, 33 services) → **OPNsense Unbound wildcard host override** (`*` / `local.bookorjeman.com` → Traefik LB IP) → LAN-only |
| Router/DNS/VPN | **OPNsense** (Unbound DNS + WireGuard server) — off-cluster; remote access survives cluster outages |
| Certs | cert-manager + **Cloudflare DNS-01** wildcard `*.local.bookorjeman.com` (⚠️ confirm `bookorjeman.com` zone is on Cloudflare) |
| Remote access | existing WireGuard on OPNsense |
| Secrets | SOPS + age (existing keys) → Argo via **ksops** |
| CSI | democratic-csi → scarif: **iSCSI** (mirror SSD pool, default SC) + **NFS** (HDD, RWX media) |
| GPU | GTX 1070 on tatooine; nvidia-container-toolkit + device plugin **time-slicing** so jellyfin (NVENC) + immich-ml (CUDA) share it |

**Reserve before starting (all in VLAN `.40`):** 4 node static IPs, 1 API VIP,
~8 MetalLB IPs, 1 scarif IP — all outside the DHCP pool. Note them here once chosen.

**Reachability / firewall posture (OPNsense L3 rules):** clients reach
**service IPs (LoadBalancer / VIP), never node IPs.** Node IPs + API VIP + etcd
(2379-2380) are management/cluster-internal — reachable only from the admin VLAN
and node-to-node. Device/IoT VLANs get **allow-listed to only the specific LB
IP+port** they need (e.g. `mosquitto-LB:1883`, `traefik-LB:443`), denied the node
IPs/API. Nodes ↔ scarif storage stays intra-`.40` (off the router).

---

## Stage A — Repo scaffolding (UNBLOCKED — do now, no hardware)

Goal: configs that `just flake-check` green, ready to deploy when `endor` lands.

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

Gate: none — M80q is in hand. **This stage can start as soon as Stage A is
green.** `endor` joins later (Stage D) as a `join-server`.

- [ ] **B1.** Install via `nixos-anywhere` (disko wipes the 128G NVMe).
      Generate `hardware-configuration.nix`, commit.
- [ ] **B2.** `just nixos-rebuild` on naboo → k3s `first-server` comes up;
      `kubectl get node` Ready; API reachable on the **VIP**.
- [ ] **B3.** MetalLB (L2) — install, configure the 10.10.40.x address pool.
- [ ] **B4.** cert-manager + ClusterIssuer (Cloudflare DNS-01, token via sops);
      issue the wildcard `*.local.bookorjeman.com`. Confirm a valid cert.
- [ ] **B5.** Argo CD — bootstrap, point at `k8s/` app-of-apps; wire **ksops**.
      **One-time manual bootstrap (chicken-and-egg):** `kubectl`-load the
      **dedicated cluster age private key** into the argocd namespace *before*
      Argo can sync any sops-encrypted manifest. (The key itself is held in
      Bitwarden like your other age keys.) See ADR 0001.
- [ ] **B6.** **GPU smoke test is deferred to Stage D** (GPU lives on tatooine),
      but validate the device-plugin manifests render now.
- [ ] **Verify:** VIP serves the API; a dummy ingress gets a trusted cert and
      resolves via internal DNS; Argo syncs a hello-world app from git.

---

## Stage C — `scarif` storage backend + CSI (still virtualized TrueNAS)

The TrueNAS VM keeps serving; bare-metal conversion is Stage G.

- [ ] **C1.** On scarif: **mirror SSD pool** (iSCSI zvols) + **HDD pool**
      (datasets + NFS share). Ensure **disk passthrough** (survives Stage G
      export/import).
- [ ] **C2.** Dedicated democratic-csi API user + key; enable iSCSI + NFS.
- [ ] **C3.** democratic-csi via Argo: StorageClasses **`iscsi` (default)** +
      **`nfs`**. TrueNAS creds as a sops secret (ksops).
- [ ] **C4.** Snapshot tasks + intra-TrueNAS replication on both pools.
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

Argo app-of-apps. Structure: `k8s/infra/` (metallb, cert-manager, traefik,
democratic-csi, nvidia-plugin, kube-vip) + `k8s/apps/` (one dir per service).
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
- [ ] **E3.** Ingress per service on `*.local.bookorjeman.com` + authentik
      forward-auth middleware. **One-time, single** OPNsense Unbound record —
      `*.local.bookorjeman.com → Traefik LB IP` (Host Override host `*`, or
      `local-zone: "local.bookorjeman.com." redirect` + one `local-data` A).
      Traefik routes by Host header → **adding a service needs no DNS change**,
      just its IngressRoute in git. Pod-to-pod uses CoreDNS automatically; no
      external-dns needed. (Only non-HTTP LB services like mosquitto are
      IP-targeted and need no DNS at all.)
- [ ] **E4.** **External-services bucket** — port the existing `/srv/traefik/
      dynamic/*.yml` routers that point at **non-cluster IPs** (OPNsense `router`,
      `truenas`/scarif, `n4`, `unifi`, `slzb`, `andromeda`, octoprint, …) into
      k8s-Traefik as IngressRoutes to external targets (Service-without-selector
      + Endpoints, or external URL), keeping authentik forward-auth. k8s-Traefik
      becomes the whole-homelab front door, replacing jupiter's Traefik.
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
