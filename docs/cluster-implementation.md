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

- [x] **C1. DONE (2026-07-03).** New SSD (Samsung 850 PRO 512GB) → **raw-disk
      passthrough into the TrueNAS VM** (`qm set 100 -scsi3
      /dev/disk/by-id/ata-Samsung_SSD_850_PRO_512GB_...,discard=on,ssd=1`); pool
      **`ssd`** created, single-disk stripe ~476 GiB. 2nd SSD later → *Extend the
      VDEV* (converts to mirror in place; NOT "Add VDEV"). Whole-disk, so the pool
      survives the Stage G export/import.
- [x] **C2. DONE (2026-07-03).** iSCSI service enabled, portal `10.10.40.10:3260`
      (**portal group ID 2**, not 1 — TrueNAS assigned it, don't assume 1),
      Allow-All initiator group (ID 1). Datasets `ssd/k8s/{v,s}` and
      `pool1/k8s/{v,s}` (`v` = volumes, `s` = detached snapshots — siblings, a
      driver constraint; one recursive `k8s` parent per pool keeps C4 to one task).
      **API key gotcha:** the `democratic-csi` API key was originally tied to
      `truenas_admin` — that account could read (Probe succeeded) but silently
      failed all dataset **writes** with a misleading `"Invalid API key"` error
      (no exposed Role field on the key to diagnose from; TrueNAS's API-key edit
      dialog only shows Name/Username/Reset). Switching the key's Username to
      **`root`** fixed it immediately. Also hit repeated key-corruption bugs
      re-pasting into the sops-encrypted driver configs — an nvim YAML
      formatter (conform.nvim/yamlfmt-class, format-on-save) collapses the
      `driver-config-file.yaml: |` block scalar into a single quoted flow
      string, breaking both the key and the nested YAML structure. Fix: edit
      these `k8s/truenas/*.enc.yaml` files with `EDITOR=nano sops <file>` (or
      delete + rewrite plaintext + `sops -e -i`), never plain `nvim`/`sops
      edit` with the formatter active. Always verify a re-pasted key against a
      `shasum -a 256` of the **clipboard**, not just cross-file match (two
      files can be identically wrong).
- [x] **C3. DONE (2026-07-03).** democratic-csi via Argo: two Helm apps
      (`k8s/infra/democratic-csi-{iscsi,nfs}.yaml`, chart 0.15.1) → StorageClasses
      **`iscsi` (default**, zvols on `ssd/k8s/v`**)** + **`nfs`** (`pool1/k8s/v`).
      Full driver configs (incl. apiKey) as ksops Secrets in `k8s/truenas/` — the
      chart's `existingConfigSecret` is the only way to keep the key out of git.
      CSI snapshotter disabled (no snapshot-controller in k3s; C4 covers it).
      Node prereqs (iscsid + NFS mounts) added to the Nix k3s module → needs
      `just deploy-cluster` (the one non-GitOps bit of Stage C).
      **TLS deferral (2026-07-03):** `truenas.local.bookorjeman.com` turned out to
      resolve to **jupiter's legacy Traefik** (.30) — that's where the valid cert
      lives; TrueNAS itself (.10) serves self-signed. CSI must not depend on
      jupiter (wiped at F2), so the driver configs use `host: 10.10.40.10` +
      `allowInsecure: true` **temporarily**. Fix when jupiter's Traefik migrates
      (E4/F): TrueNAS native ACME cert (Credentials → Certificates → ACME
      DNS-Authenticator w/ Cloudflare → CSR for truenas.local.bookorjeman.com →
      ACME cert → set as GUI cert), OPNsense override → .10, then flip driver
      configs to the hostname + `allowInsecure: false`.
- [x] **C4. DONE (2026-07-03).** Periodic Snapshot Tasks: `ssd/k8s` + `pool1/k8s`
      (both recursive, daily 03:00, 2-week lifetime). Replication `ssd/k8s` →
      `pool1` **deferred** — 2nd SSD arriving soon, will extend `ssd` to a mirror
      instead of replicating; revisit if that slips.
- [x] **C5. DONE (2026-07-03).** Traefik's `acme.json` moved off `local-path`
      onto the `iscsi` SC. PVC `storageClassName` is immutable — needed a real
      cutover: scale deploy to 0, delete PVC, hard-refresh the **root** app (not
      just `traefik`) so the new `storageClass` value actually lands in the
      `traefik` Application CR, then re-sync + scale back up. Wildcard cert
      re-issued once via LE DNS-01, verified with a live HTTPS request
      (`SSL certificate verify ok`, HTTP/2 200). Traefik logs a `Register...`
      line and then go quiet on ACME success — no "obtained certificate" INFO
      line — don't mistake that silence for a hang; check the served cert
      instead of tailing logs.
- [ ] **Verify:** PVC on each SC binds; pod writes, deletes, reschedules to
      another node (after Stage D), data persists; zvol/export visible in scarif.

---

## Stage D — tatooine GPU node + media mini-cutover (~1 week before the rest migrates)

Decision: validate the scariest step (GPU-in-k3s) on real hardware *before* the
rest of the migration. Wiping tatooine takes its media stack down, so
jellyfin/immich/seerr **migrate now** as their own mini-cutover — a planned
short outage. Gate: Stage C (CSI) done + media pre-synced to scarif + media
manifests authored (Stage E). Scoped + grilled 2026-07-03; see
`docs/adr/0003-tatooine-bare-metal-conversion.md` (Proxmox VM → bare metal,
one-way door) and `docs/adr/0004-static-pv-for-preexisting-nas-data.md`
(pre-existing NAS media via static PV, not the `nfs` StorageClass).
**immich-machine-learning is out of scope** — it's not currently running on
tatooine (pointed at a stale external host); D3's time-slicing is
jellyfin-only for now. `*arr` + gluetun are servarr's (Stage E1), not D4.

- [x] **D0 (no outage). DONE (2026-07-03).** `hosts/tatooine/` (naboo/endor
      pattern, `role = "agent"`) + `modules/nixos/services/nvidia-headless`
      (`open = false` — Pascal predates NVIDIA's open kernel modules;
      nvidia-container-toolkit wired into k3s' *own* containerd via a
      `config.toml.tmpl` systemd-tmpfiles symlink, not the system containerd).
      flake + sops entries; `tatooine` config evaluates cleanly (needed
      `nvidia-kernel-modules` added to the unfree predicate — the closed
      driver isn't dual-licensed like coruscant's open one). E1 manifests
      authored under `k8s/apps/{jellyfin,immich,seerr,media-nfs-pv}` +
      `k8s/infra/*.yaml` (not yet pushed/synced by Argo). **Data migration
      done and verified**: immich postgres `pg_dump`'d straight from the live
      `immich_postgres` container into a throwaway pod on the `immich-postgres`
      iscsi PVC (38,729 assets / 2 users, row counts match source exactly);
      jellyfin's `/config` (2.0G) `tar`'d the same way into the `jellyfin-config`
      iscsi PVC. Old tatooine containers untouched, still serving. **Gotchas
      found live** (fixed in the manifests): postgres needs `PGDATA` set to a
      subdirectory — the iscsi PVC's ext4 root has a `lost+found` dir that
      breaks `initdb`. The three image tags/versions I'd guessed were wrong —
      corrected via `docker inspect` on tatooine: immich postgres is
      `14-vectorchord0.4.3-pgvectors0.2.0` (not the version I assumed), immich's
      redis is actually `valkey/valkey:8-bookworm`, and "seerr" is
      `ghcr.io/seerr-team/seerr` — **not** jellyseerr. The NAS share names are
      also misleading: `media/image-backups` (RW) is immich's real upload
      storage, `media/photos` (RO) is a read-only external library — backwards
      from what the names suggest. jellyfin's media mount isn't one flat
      `/media` — the old container bind-mounted 4 distinct subpaths
      (`kids/movies`, `kids/tv`→`series`, `movies`, `tv`→`series`), replicated
      via 4 `subPath` mounts of the single static NFS PVC so jellyfin's
      migrated library-path DB entries still resolve. `secrets.yaml` (k3s
      agent token) and the `immich-postgres-env`/`immich-server-env` ksops
      secrets still need generating before an agent join or a real Argo sync
      of the immich app.
- [x] **D1. DONE (2026-07-03).** Bare-metal wipe + `nixos-anywhere` install (kexec
      from the live Proxmox host worked — EFI, Secure Boot off, VM 100 stopped
      first to free RAM; final postgres/jellyfin-config delta re-sync done
      **before** the wipe, the source dies with the hypervisor). Built on
      **naboo** (the mac can't build x86_64-linux; repo rsync'd to
      `/tmp/nixos-config`, nixos-anywhere run from there with agent-forwarded
      SSH). Node then **moved to the cluster VLAN as `10.10.40.15`** — OPNsense
      blocks `10.10.30.x→10.10.40.x:6443`, an agent on the old VLAN can never
      join (NFS exports are 40.0/24-scoped too). Taint +
      `nvidia.com/gpu.present=true` label applied **declaratively** via
      `services.k3s.extraFlags` at registration. **Gotcha:**
      `nvidiaPackages.stable` (595) drops Pascal — module pins `legacy_580`,
      the last GTX 1070 branch.
- [x] **D2. DONE (2026-07-04).** Device plugin via multi-source Argo app
      (`k8s/infra/nvidia-plugin.yaml`: Helm chart 0.17.3 + `k8s/nvidia`'s
      RuntimeClass). Verified: throwaway CUDA pod (`runtimeClassName: nvidia`,
      `nvidia.com/gpu: 1`) ran `nvidia-smi` — GTX 1070 / driver 580.142, node
      allocatable `nvidia.com/gpu: 3` (time-slicing). **Three gotchas, all
      encoded in config:** (1) `nvidia-container-runtime` shells out to `runc`
      from PATH and the containerd shim env has none — the module's BinaryName
      points at a wrapper script baking `pkgs.runc` onto PATH; (2) the plain
      binary defaults to *legacy* mode (no `/etc/nvidia-container-runtime`
      config on NixOS) whose `nvidia-container-cli` isn't packaged — the
      wrapper execs the **`.cdi`** variant against the generated `/var/run/cdi`
      spec; (3) that spec names devices `0`/`all`, so the plugin needs
      `deviceIDStrategy: index` (default uuid → "unresolvable CDI devices").
      Restarting `k3s.service` does NOT restart its bundled containerd — bounce
      both (`systemctl stop k3s && pkill containerd`) or containerd keeps the
      old runtime config/env.
      **⚠ Incident + open items for D3:** Argo had auto-synced
      `k8s/apps/immich` *including* the throwaway `migrate-postgres.yaml` → two
      postgres on one RWO PVC → corrupted pgdata. Recovered (pgdata wiped,
      fresh restore from the then-still-live old container; 38,729 assets / 2
      users + max `updatedAt` verified identical). **`automated` sync is
      currently disabled on the `root` and `immich` Applications** and
      `immich-server` is scaled to 0; before re-enabling, move
      `migrate-*.yaml` out of the Argo-synced app dirs or the migrate pod
      resurrects. `nvidia-plugin` was `kubectl apply`'d directly (root sync
      off); root adopts it on its next sync.
- [x] **D3. DONE (2026-07-04).** `migrate-*.yaml` moved to `k8s/migration/`
      (plain files, no Application) before re-enabling `root`/`immich`
      auto-sync — both restored to `automated: {prune, selfHeal}`. **Three
      bugs found and fixed getting the three services live:** (1) the
      democratic-csi iscsi/nfs node DaemonSets had no toleration for
      tatooine's `nvidia.com/gpu=present:NoSchedule` taint, so the CSI node
      plugin never ran there — any PVC mount on tatooine failed with
      "driver name org.democratic-csi.iscsi not found"; fixed by adding
      `node.tolerations` to both `k8s/infra/democratic-csi-{iscsi,nfs}.yaml`.
      (2) `jellyfin.yaml`'s pod spec was missing `runtimeClassName: nvidia` —
      it scheduled and got `nvidia.com/gpu: 1` allocated, but without the
      RuntimeClass the container ran under plain `runc` and never got
      `/dev/nvidia*` devices. (3) seerr's CrashLoopBackOff was
      `EACCES: permission denied, mkdir '/app/config/logs/'` —
      `ghcr.io/seerr-team/seerr` runs as uid/gid `1000(node)` but the fresh
      iscsi PVC mounts root-owned; added `securityContext.fsGroup: 1000` to
      `k8s/apps/seerr/seerr.yaml`.
- [x] **Verify. DONE (2026-07-04).** jellyfin: pod Running on tatooine, UI
      reachable at `jellyfin.local.bookorjeman.com`, real NVENC transcode
      confirmed (`nvidia-smi` showed `jellyfin-ffmpeg/ffmpeg` at 35% GPU util,
      P2 power state, during a forced-quality playback). immich: gallery
      loads, asset count matches the D0 migration. seerr: UI reachable, but
      landed on the first-run setup wizard — its config PVC was empty.
      **Gap found post-hoc: seerr's `/app/config` was never migrated in D0**
      (unlike jellyfin/immich, no migrate pod was ever authored/run for it
      before the D1 wipe); since tatooine's wipe is a one-way door (ADR-0003),
      its old settings/request history/users are unrecoverable — redoing
      Seerr's setup from scratch (no media data involved, app-config only).
      **DNS cutover:** OPNsense Unbound per-app host overrides
      for `jellyfin`/`immich-server`/`seerr` repointed from jupiter's old
      `10.10.40.30` to the cluster Traefik LB `10.10.40.51`. A literal `*`
      wildcard host override was tried instead and **crashed Unbound
      network-wide** (GUI-generated per-host overrides don't support a real
      wildcard; deleting the row let the service start cleanly again) — stuck
      with explicit per-app overrides for now, see the wildcard TODO in agent
      memory for a safer subdomain-scoped approach later.

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
  - [x] **navidrome. DONE (2026-07-04).** Migrated from servarr's Docker
        Compose VM. Config (SQLite db, artwork) tar-streamed in; the
        regenerable album-art thumbnail cache (`cache/`, root-owned on the
        source, ~200M) skipped — navidrome rebuilds it automatically, not
        worth chasing root-only source files over plain SSH. Music library
        mounted **read-only** from the pre-existing TrueNAS NFS export
        (`/mnt/pool1/data/media/music` — same server + top-level pool as
        jellyfin's `nfs-data`, easy to misread as immich's separate
        `/mnt/pool1/media/*` export; double-checked against servarr's fstab
        before writing the PV). last.fm credentials via ksops. No authentik
        forward-auth — manages its own users, like jellyfin/immich/seerr.
        Applied and verified manually before wiring Argo (same safe
        sequencing as the arr-stack). seerr done (Stage D).
  - [x] **linkding, homepage, mealie. DONE (2026-07-05).** Migrated from
        jupiter's Docker Compose VM (`10.10.40.30`). linkding: auth via
        authentik header forwarding (`LD_ENABLE_AUTH_PROXY`, no separate
        secret). homepage: ~20 widget API keys/tokens via ksops; `services.yaml`'s
        widget URLs (jellyfin/immich/seerr/sonarr/radarr/lidarr/prowlarr/
        deluge/nzbget) were still pointing at pre-migration IPs — fixed by
        hand post-migration, same class of touch-up as the *arr download-client
        reconnection. mealie: OIDC client secret via ksops.
        **Incident: accidentally `cat`'d mealie's live compose file, which —
        unlike every other app — inlines real secrets instead of using an
        `.env` file (`OIDC_CLIENT_SECRET`, `OPENAI_API_KEY`) — both leaked
        into the session transcript. `OPENAI_API_KEY` was revoked (unused,
        dropped entirely); `OIDC_CLIENT_SECRET` carried over pending
        rotation. jupiter's compose file corrected to use `env_file: .env`
        going forward. Lesson: grep for `_SECRET\|_KEY\|_TOKEN\|_PASS` before
        ever `cat`-ing a source compose file mid-migration, never assume the
        `.env`-file convention holds.
        **Bigger finding while wiring homepage's `kubernetes` cluster/node
        widget: a real cluster-wide networking bug**, not a homepage issue —
        see the `--node-ip` entry below. homepage's `kubernetes` widget
        itself still isn't rendering despite correct RBAC/ServiceAccount
        (reports "No kubernetes configuration" against a config that looks
        right) — minor unresolved follow-up, not blocking.
  - [x] **Cluster-wide flannel/kube-vip node-ip bug found + fixed
        (2026-07-05).** kube-vip's floating API VIP (`10.10.40.5`) shares a
        NIC with naboo's real IP; flannel's `public-ip` node-annotation
        auto-detection picked the VIP instead after naboo's k3s restarted,
        corrupting the VXLAN FDB on endor/tatooine (both pointed naboo's VTEP
        MAC at the wrong destination IP) — silently broke **all** cross-node
        pod traffic to anything scheduled on naboo for ~23h, undetected until
        homepage/argocd-dex-server pods happened to land there. Root-caused
        via `deep-research` (k3s/flannel GitHub issues, official docs — no
        source names kube-vip specifically, but the general "flannel picks
        the wrong candidate IP when multiple addresses share an interface"
        failure mode matches exactly). Fix: `homelab.k3s.nodeIp` → `--node-ip`
        pinned per host (naboo `.13`, endor `.14`, tatooine `.15`) — see
        ADR-0006. The already-stale annotation needed one manual
        `kubectl annotate --overwrite` on naboo (the pin only prevents
        *future* staleness; flannel doesn't rewrite an existing annotation on
        restart) — the corrected value then propagated live to endor/tatooine
        via flannel's own k8s watch, no restart needed on either. Rolled out
        tatooine → naboo → endor (agent first, zero etcd risk; then one
        control-plane node at a time, verifying `etcd`/2-member quorum before
        each next step). Endor's annotation was already correct — the bug is
        specific to whichever node currently holds the kube-vip VIP.
        Verified: cross-node curl to a naboo-scheduled pod from endor now
        succeeds instantly (`200`, ~4ms) instead of silently timing out.
  - Media: jellyfin (NVENC, on tatooine), immich (pg on iSCSI, library on NFS,
    `nvidia.com/gpu` for ML, on tatooine).
  - [x] **Downloaders (VPN pod) + *arr floats. DONE (2026-07-04).** One pod =
        gluetun (Mullvad WireGuard) + deluge + nzbget + prowlarr sharing the
        netns (k8s Pod containers already share a network namespace — no
        Compose-style `network_mode: service:gluetun` needed).
        sonarr/radarr/lidarr/bazarr floats + recyclarr as a CronJob, all in a
        single shared `arr` namespace (ADR-0005) so every app mounts the same
        NFS downloads PVC. Migrated live from the servarr Docker Compose VM
        (`10.10.40.11`) — configs tar-streamed in via an ad-hoc migrate pod,
        applied directly before wiring Argo (no migrate-vs-workload race
        window this time). **Mullvad doesn't support gluetun's VPN
        port-forwarding** (confirmed via the live `.env`) — deluge's torrent
        port is just static through the tunnel, nothing to preserve.
        **Gotchas found + fixed:** gluetun's kill-switch blocks ALL egress by
        default, including pod-to-pod traffic — needed
        `FIREWALL_OUTBOUND_SUBNETS=10.42.0.0/16,10.43.0.0/16` (k3s pod+service
        CIDR) or prowlarr couldn't reach sonarr/radarr/lidarr; bazarr's first
        boot against the migrated library took ~200s, a fixed
        `initialDelaySeconds` liveness probe crashlooped it — replaced with a
        `startupProbe`; the ksops secret (gluetun's WireGuard key) needed the
        `config.kubernetes.io/function: exec: path: ksops` annotation that
        was missing from the first draft (kustomize otherwise falls back to
        a plugin-discovery path that doesn't exist on the repo-server). DNS
        cut over for all 7 hostnames (per-app OPNsense Unbound overrides,
        same `.30`→`.51` pattern as D3) with `auth: true` (authentik
        forward-auth, still hosted on servarr — unaffected by this
        migration). **Verified end-to-end**: search → grab (Prowlarr indexer)
        → download (NZBGet) → import into `/data/media` all completed for a
        real title post-migration. servarr's old `arr-stack` compose is now
        stopped (`docker compose down`) — `authentik-outpost`, `navidrome`,
        `watchtower`, `portainer-agent`, `autokuma` (separate compose stacks,
        same host) intentionally left running.
  - **Shared downloads volume:** the completed-downloads dir must be one **NFS
    (RWX)** PVC mounted by *both* the VPN pod and the *arr pods, with identical
    mount paths, so imports work. **Done** — see above.
  - [x] **authentik (pg+redis+server+worker). DONE (2026-07-06).** Migrated
        from jupiter's Docker Compose stack (`10.10.40.30`). postgres/redis
        stopped on jupiter, `pg_dump --clean --if-exists` piped straight into
        the new in-cluster postgres (`ssh jupiter docker exec ... pg_dump |
        kubectl exec -i ... psql`); `media`/`custom-templates` tar-streamed
        via a throwaway busybox pod onto a small RWX `nfs` PVC.
        `AUTHENTIK_SECRET_KEY` carried over verbatim from jupiter's
        `secret_key.txt` (regenerating it would break existing sessions and
        anything authentik encrypts at rest). server/worker Deployments
        shipped at `replicas: 0` in the first commit so they wouldn't
        fresh-install against an empty DB mid-restore, bumped to 1 once data
        was verified (611 `django_migrations` rows, 6 users, 16 flows, 14
        OAuth2 providers all present post-restore).
        **Retired the standalone `goauthentik/proxy` outpost** that ran on
        servarr (`10.10.40.11:9000`, needed only because servarr was on a
        different network than jupiter) — now that Traefik and authentik
        share the cluster network, `authentik-server`'s own embedded outpost
        (Service `auth.authentik.svc.cluster.local:9000`) handles
        forward-auth directly. `k8s/charts/ingress/values.yaml`'s
        `authentikAddress` repointed accordingly.
        **Gotchas found + fixed:** (1) `ksops`'s
        `config.kubernetes.io/function` annotation must be a literal
        block-scalar string (`|` + nested keys), not a YAML mapping — used
        the wrong form initially, same failure class as the gluetun bug
        (kustomize silently falls back to a nonexistent plugin path).
        (2) `ghcr.io/goauthentik/server:latest` actually resolved to
        **2025.2.4**, older than jupiter's source **2025.8** — the tag
        doesn't track newest-stable — and 500'd on every request because the
        restored DB already had post-2025.8 schema (`session_id` column,
        code still expected `session_key`). Pinned to `2025.8.4` instead
        (matches the version the old proxy-outpost was already running).
        (3) The pg_dump carried over each proxy provider's outpost
        assignment (Linkding + all 7 *arr providers were still assigned to
        the old jupiter/servarr-era "Arr ForwardAuth" outpost object, not
        authentik's embedded one) — reassigned via direct SQL on
        `authentik_outposts_outpost_providers`
        (a raw DB edit bypasses authentik's signal-driven routing-cache
        rebuild, so a `kubectl rollout restart` of server+worker was needed
        to pick it up). The embedded outpost's own `_config.authentik_host`
        also still pointed at jupiter's IP (used to build the OAuth
        authorize redirect a browser follows) — unlike the old
        split internal/browser-host setup (needed only because the
        standalone outpost lived on a different host), the embedded outpost
        is the same process as core, so both `authentik_host` and
        `authentik_host_browser` were set to the same public
        `https://auth.local.bookorjeman.com`.
        **Incident during cutover:** DNS was flipped to the cluster before
        the workload was deployed, causing a brief real outage (self-inflicted,
        caught immediately). Separately, an unrelated **recurrence of the
        flannel/kube-vip cross-node VXLAN bug** (ADR-0006) hit mid-migration —
        `kube-vip` on naboo flapped (10 restarts), leadership moved to
        endor, and cross-node pod traffic to naboo broke entirely (CoreDNS
        included), independent of authentik. Re-annotating
        `flannel.alpha.coreos.com/public-ip` to the *same* value didn't help
        this time (flannel only reacts to an actual change) — fixed by
        `systemctl restart k3s` on naboo (etcd traffic runs over host IPs,
        not the flannel overlay, and naboo wasn't the active VIP holder, so
        this was lower-risk than a typical CP restart).
  - Critical: unifi (mongo), home-assistant.
  - **vaultwarden: SKIPPED (2026-07-06)** — not in use, replaced by paid
    Bitwarden. Left running as-is on jupiter, not migrated; jupiter's wipe in
    Stage F2 will take it with it, no offsite backup needed.
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

- [x] **F1a. authentik DONE (2026-07-06).** See Stage E1 for the full writeup.
- [ ] **F1.** Remaining: unifi, monitoring (vaultwarden skipped, see Stage E1).
      Per service: sync data to scarif → restore into PV → bring up via
      Argo → verify → cut its internal DNS over to the Traefik LB IP. Old
      container stays up until verified.
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
- [ ] **Future:** offsite backup for **immich photos** (vaultwarden dropped,
      see Stage E1 — replaced by paid Bitwarden) — restic/ZFS-replication to
      a cloud bucket. RAM 16→32G/node when
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
