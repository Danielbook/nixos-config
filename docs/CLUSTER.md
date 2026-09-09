# Home-lab k3s Cluster — Strategy & Decisions (living doc)

> Status: **Migration complete (Stage H, 2026-07-19)** — 3-node HA control-plane
> (`naboo`, `endor`, `hoth`) + GPU agent (`tatooine`),
> all workloads GitOps-managed by Argo CD. Only Stage G (bare-metal TrueNAS on
> `scarif`) is outstanding — see [improvements.md](./improvements.md).
> This doc holds the **why** (hardware, decisions, capacity); the **how**
> (stage-by-stage build) lives in
> [cluster-implementation.md](./cluster-implementation.md). The
> node-provisioning pattern (pre-generated host keys + portable admin key) is
> [ADR 0002](./adr/0002-node-provisioning-host-keys.md). For where each config
> file actually lives (Nix modules, `k8s/` manifests, secrets), see
> [ARCHITECTURE.md → k3s Cluster Config Map](./ARCHITECTURE.md#k3s-cluster-config-map).
> Last update: 2026-09-09.

## Goal

Replace the hand-managed Proxmox boxes with one declarative cluster:
**NixOS provisions the nodes (this repo), Argo CD provisions the workloads
(GitOps).** Storage is centralized on a bare-metal TrueNAS so nodes stay
stateless and workloads float freely between them.

---

## Hardware inventory

| Node | Box / board | CPU | RAM | Disk | GPU | Role |
|------|-------------|-----|-----|------|-----|------|
| `naboo` | Lenovo ThinkCentre M80q Tiny | i5-10500T (6c/12t) | 16G | 128G NVMe | — | Control-plane (etcd) — **bootstrap** |
| `endor` | Lenovo ThinkCentre M70q Tiny | i5-10400T (6c/12t) | 16G | 256G NVMe | — | Control-plane (etcd) |
| `hoth` | HP EliteDesk 800 G2 Mini | i7-6700T (4c/8t) | 16G | 256G SSD | — | Control-plane (etcd) — the ex-`jupiter` box, wiped last (F2) |
| `tatooine` | ASUS PRIME Z370-A (tower) | i7-8700K (6c/12t) | 16G | 2× 512G Samsung SSD | **NVIDIA GTX 1070 (8G)** | **GPU worker** (agent) |
| `scarif` | Jonsbo N4 / Supermicro X11SCL-F | i3-8100 (4c) | 32G | boot NVMe + 2× 16TB Exos (HDD pool, passthrough) + SSD mirror to add (850 PRO 512G + 1× ~500G SATA) | — | **Bare-metal TrueNAS** — storage backend, **not** a cluster node |
| `kamino` | Raspberry Pi (not yet acquired) | — | — | SD | — | OctoPrint (Prusa MK3S), **off-cluster appliance** — see [improvements.md](./improvements.md) |
| ~~`servarr`~~ | VM on the Jonsbo box | — | — | — | — | **Dissolved into k3s pods** — not hardware |

Notes:
- **tatooine GPU = GTX 1070 (Pascal).** CUDA (immich ML) + NVENC/NVDEC (Jellyfin
  transcode) → `nvidia-container-toolkit`. Caveats: Pascal NVENC consumer
  session cap (nvidia-patch if >2-3 streams); NVDEC has no AV1.
- Mini-PC NVMe holds only OS + k3s; all app/media data lives on `scarif`.
- `servarr` is a VM co-located with the TrueNAS VM on the Jonsbo/Proxmox box;
  its *arr stack moves into the cluster, freeing the box for bare-metal TrueNAS.

---

## Locked decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| Node OS | **NixOS + `services.k3s`** | One repo/toolchain; reuses `common` layer, sops-nix, justfile. Rejected Talos (separate toolchain outside Nix). |
| Topology | **3-node HA, embedded etcd** (`naboo`+`jupiter`+`endor`); `tatooine` a GPU worker | Survives one control-plane node failing. |
| Storage | **democratic-csi on TrueNAS**, single CSI | NFS for media/RWX; iSCSI zvols (SSD **mirror** pool) for app/DB PVs. ZFS snapshots = backup. No Longhorn. |
| Workloads | **Argo CD** app-of-apps, manifests in `k8s/` in this repo | Clean nodes-by-NixOS / apps-by-GitOps boundary. |
| Git hosting | **Forgejo (in-cluster) is the source of truth** — Argo and all `repoURL`s point at `forgejo.local.bookorjeman.com/danielbook/nixos-config`; push-mirrors (sync on commit, all branches) to **GitHub** and **Codeberg** | Own the data; mirrors are the disaster-recovery copies since Forgejo runs *on* the cluster it defines — see rebuild runbook below. |
| API endpoint | **kube-vip** floating VIP across the 3 control-plane nodes | Losing a node doesn't move the endpoint. |
| Network | Whole cluster (4 nodes + `scarif` + MetalLB + VIP) in the **`.40` services VLAN** (`10.10.40.x`); `.30` Proxmox VLAN decommissioned | Service IPs stay where DNS/Traefik point; storage intra-VLAN. k3s CIDRs (`10.42/16`,`10.43/16`) don't clash. |
| LB IPs | **MetalLB** (L2) pool in `.40`; kube-vip for the API VIP | Stable LAN IPs for ingress + device-facing services. |
| Access / TLS | **LAN-only**, services on `*.local.bookorjeman.com`; remote via **WireGuard on OPNsense**; wildcard cert via **cert-manager + Cloudflare DNS-01** | Valid certs, no open ports. DNS is **one OPNsense Unbound host override per app** → Traefik — a single `*` override crashed DNS network-wide (2026-07); revisit via a dedicated subdomain zone (see [improvements.md](./improvements.md)). |
| Ingress | **Traefik self-managed in Argo** (`--disable` bundled), the **whole-homelab front door** — also proxies external UIs (`router`/OPNsense, `truenas`, `n4`, `unifi`, `slzb`, …) behind authentik | Brings the existing extensive `/srv/traefik/dynamic` setup under GitOps. |
| Secrets | **SOPS + age**, Argo decrypts via **ksops**, using a **dedicated cluster age key** (+ `daniel` for recovery) | Least privilege — master key never enters the cluster. See [ADR 0001](./adr/0001-cluster-secrets-age-key.md). |
| Cutover | **Gradual** (done): migrated onto `naboo`+`endor`+`tatooine`, kept `jupiter` as a live hot-fallback, wiped it **last** → rejoined as `hoth`, the 3rd control-plane | A working rollback stayed online the whole time. |
| Power | **Line-interactive, pure-sine UPS** (e.g. APC Smart-UPS 1500) + **NUT** graceful shutdown. Protects the whole stack: cluster + `scarif` + UniFi US-48 switch + APs + cameras (when added) + OPNsense | No UPS today — main exposure is a whole-house outage dropping all 3 etcd nodes uncleanly. Pure sine for the NAS's active-PFC PSU (Silverstone SX500). Measured switch draw ~60W; total stack ~250–330W ≈ 30% of a 1500VA UPS → ~15–20 min runtime. |
| Storage SSDs (app/DB mirror) | **Leaning (not locked):** reuse tatooine's **Samsung 850 PRO 512GB** (freed when the GPU node boots off its **960 PRO** NVMe) + buy **one ~500GB SATA SSD** → ~500GB ZFS mirror | The planned **UPS** covers the no-PLP gap, so prosumer/consumer TLC+DRAM is fine. PLP enterprise (Intel S4500/S4510, PM883) remains the alternative if you'd rather not lean on the UPS. Media is on the HDD pool, so 500GB is ample. |

**Storage ceiling:** `scarif` is a hard dependency for cluster state — keep it on
the UPS, treat reboots as planned. Revisit Longhorn only if an app must survive
TrueNAS downtime.

**Power-priority (NUT):** servers (etcd/DBs) are signalled to shut down **early**
(~5 min remaining); the switch + cameras + OPNsense keep running on the rest of
the battery (stateless — they just need power, no graceful shutdown). So a short
blip leaves everything up; a long outage takes the cluster down cleanly while the
cameras keep recording until the battery is spent.

**UPS findings (shortlist — nothing locked):**
- Must be **line-interactive + pure sine** (the NAS's active-PFC SX500 PSU faults
  on simulated/stepped sine), ~1000–1500VA, USB → NUT (driver **`usbhid-ups`** on
  every candidate; `scarif` = NUT master).
- **Buy on the model suffix:** `SMT/SUA/SMC` (APC Smart-UPS), `5P/5SC/PR/…PFC/
  Sinewave` = **pure sine** ✅; `AVR/5S/OR`(non-PFC)`/BR…/…SH` = **simulated → avoid** ❌.
- Used shortlist seen: APC **Smart-UPS 1500** (~1,500 kr), **Eaton 5P 1150iR**
  (~2,000), **Eaton 9130** (online, ~1,035). Refurb-with-warranty
  (battery-direct.de SMT1500I ~2,170) dodges the dead-battery gamble.
- **Battery is the hidden cost** on used units — APC RBC7 ≈ 1,200–2,400 kr
  aftermarket. Always ask the seller for the **battery date + a self-test**.

---

## Peripherals (keep the cluster stateless)

- **Zigbee/Matter** — on an **Ethernet** coordinator (`slzb`); HA reaches it over
  the LAN → no node pinning.
- **OctoPrint** (Prusa MK3S) — moves to its own Pi (`kamino`), off the cluster;
  HA talks to it over the network. Pi not acquired yet — docs-only.
- **Garage door** — Arduino **Mega 2560** (USB serial, no WiFi) is plugged into
  `naboo`; HA is pinned there. Relocating it / a ser2net bridge to free HA float
  is a **deferred** optional later step.

---

## Capacity ceiling (when do I need another node?)

**RAM is the limit, not CPU** (services are mostly idle against ~22 cores).
4 nodes × 16G = **64G** − ~8G system − ~3G platform ≈ **~53G usable**, − 16G
reserved (tolerate one node down) ⇒ **~37G workload budget with HA headroom**.
Today's real usage ≈ **11G** ⇒ **~3.5× headroom** out of the gate.

- **Signal:** node memory requests >~80%, `Evicted`/`OOMKilled`, or pending pods
  on drain. Watch memory.
- **First lever is RAM, not a node:** 16→32G/node (~500 kr each) = 128G total
  (~9× today). Add a 5th node only after RAM is maxed, or for GPU/failure-domain.

---

## Open items
- [x] **`endor` bought and joined** — Lenovo M70q i5-10400T (Blocket), now 16G.
- [x] **Cluster IPs reserved** — VIP, the four nodes and the MetalLB pool live in
      the `.40` VLAN; the address map is in
      [cluster-implementation.md](./cluster-implementation.md).
- [x] **`bookorjeman.com` zone on Cloudflare** — DNS-01 wildcard cert issuing.
- [ ] **Buy a UPS** — pure-sine line-interactive (see *UPS findings* above for the
      shortlist + suffix cheat-sheet); verify battery date/self-test. Then wire NUT
      (`usbhid-ups`, `scarif` = master).
- [ ] **App/DB mirror drives** — *leaning:* reuse tatooine's **850 PRO 512GB** +
      buy **one ~500GB SATA** (e.g. Samsung 850/870 EVO ~650 kr); UPS covers the
      no-PLP gap. *Alt:* 2× PLP enterprise SATA (Intel S4500/S4510, PM883) if not
      relying on the UPS. (GPU node then boots off the 960 PRO NVMe.)
- [ ] **Add the SSD mirror pool** to the Jonsbo N4 (iSCSI app/DB tier).
- [ ] Confirm the 2×16TB HDD pool layout (mirror vs stripe).
- [ ] Stand up `kamino` (Pi) for the Prusa.

## Risks
- **No UPS yet** — a whole-house outage drops all 3 etcd nodes uncleanly at once
  (HA doesn't help vs simultaneous power loss). Mitigation: buy a UPS + NUT (PLP
  SSDs only if not reusing the 850 PRO). Until then, power loss is the highest live risk.
- **`scarif` = single dependency** for cluster state → on the UPS, planned reboots.
  A storage blip can leave iSCSI-backed pods stuck read-only — recovery is to
  scale the workload to 0 and back, not a rollout restart.
- **No offsite backup yet** — plan restic/replication for immich photos (the
  irreplaceable data) as a follow-up. Vaultwarden was dropped for paid Bitwarden.

## Disaster recovery: full cluster rebuild

Forgejo runs **on** the cluster, and Argo syncs the cluster **from** Forgejo —
on a total rebuild neither exists yet. Escape hatch (untested — walk it before
trusting it at 3am):

1. Clone this repo from a mirror: `https://github.com/Danielbook/nixos-config.git`
   (or `https://codeberg.org/Danielbook/nixos-config.git`).
2. Rebuild the nodes: `just deploy-cluster` (+ agents). Argo comes up but every
   app — including the `forgejo` child app — points at Forgejo, which isn't
   running yet, so nothing syncs. Do **not** flip `repoURL`s to a mirror; that
   splits history and touches ~36 files. Instead:
3. Manually bootstrap Forgejo from the local clone: render its manifests
   (ksops secrets decrypt with the personal `daniel` age key — the recovery
   key per [ADR 0001](./adr/0001-cluster-secrets-age-key.md)) and
   `kubectl apply` them. Forgejo's data survives on the TrueNAS PVC, so it
   returns with all repos intact.
4. Once Forgejo serves the repo again, Argo syncs everything else on its own;
   it also adopts the hand-applied Forgejo resources (same names/namespace).
5. Verify `kubectl -n argocd get applications` — all Synced/Healthy.

---

**Build steps:** [cluster-implementation.md](./cluster-implementation.md) — Stages A–H.
