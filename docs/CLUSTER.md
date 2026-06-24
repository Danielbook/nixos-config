# Home-lab k3s Cluster — Strategy & Decisions (living doc)

> Status: **planning**, repo scaffolding next. The Proxmox → NixOS-managed k3s
> migration. This doc holds the **why** (hardware, decisions, capacity); the
> **how** (stage-by-stage build) lives in
> [cluster-implementation.md](./cluster-implementation.md). Last update: 2026-06-24.

## Goal

Replace the hand-managed Proxmox boxes with one declarative cluster:
**NixOS provisions the nodes (this repo), Argo CD provisions the workloads
(GitOps).** Storage is centralized on a bare-metal TrueNAS so nodes stay
stateless and workloads float freely between them.

---

## Hardware inventory

| Node | Box / board | CPU | RAM | Disk | GPU | Role |
|------|-------------|-----|-----|------|-----|------|
| `naboo` | Lenovo ThinkCentre M80q Tiny | i5-10500T (6c/12t) | 16G | 128G NVMe | — | Control-plane (etcd) — **bootstrap, in hand** |
| `jupiter` | HP EliteDesk 800 G2 Mini | i7-6700T (4c/8t) | 16G | 256G SSD | — | Control-plane (etcd) — **wiped/joined last** (hot-fallback) |
| `endor` | Lenovo ThinkCentre M70q Tiny | i5-10400T (6c/12t) | 8G (+ 16G stick) | 256G NVMe | — | Control-plane (etcd) — **purchased @1,800 kr, arriving ~this week** |
| `tatooine` | ASUS PRIME Z370-A (tower) | i7-8700K (6c/12t) | 16G | 2× 512G Samsung SSD | **NVIDIA GTX 1070 (8G)** | **GPU worker** (agent) |
| `scarif` | Jonsbo N4 / Supermicro X11SCL-F | i3-8100 (4c) | 32G | boot NVMe + 2× 16TB Exos (HDD pool, passthrough) + SSD mirror (to add) | — | **Bare-metal TrueNAS** — storage backend, **not** a cluster node |
| `octopi` | Raspberry Pi 3B+ | — | 1G | SD | — | OctoPrint (Prusa + Brio), **off-cluster appliance** |
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
| API endpoint | **kube-vip** floating VIP across the 3 control-plane nodes | Losing a node doesn't move the endpoint. |
| Network | Whole cluster (4 nodes + `scarif` + MetalLB + VIP) in the **`.40` services VLAN** (`10.10.40.x`); `.30` Proxmox VLAN decommissioned | Service IPs stay where DNS/Traefik point; storage intra-VLAN. k3s CIDRs (`10.42/16`,`10.43/16`) don't clash. |
| LB IPs | **MetalLB** (L2) pool in `.40`; kube-vip for the API VIP | Stable LAN IPs for ingress + device-facing services. |
| Access / TLS | **LAN-only**, services on `*.local.bookorjeman.com`; remote via **WireGuard on OPNsense**; wildcard cert via **cert-manager + Cloudflare DNS-01** | Valid certs, no open ports. One **OPNsense Unbound wildcard** record → Traefik; zero per-service DNS. |
| Ingress | **Traefik self-managed in Argo** (`--disable` bundled), the **whole-homelab front door** — also proxies external UIs (`router`/OPNsense, `truenas`, `n4`, `unifi`, `slzb`, …) behind authentik | Brings the existing extensive `/srv/traefik/dynamic` setup under GitOps. |
| Secrets | **SOPS + age**, Argo decrypts via **ksops**, using a **dedicated cluster age key** (+ `daniel` for recovery) | Least privilege — master key never enters the cluster. See [ADR 0001](./adr/0001-cluster-secrets-age-key.md). |
| Cutover | **Gradual**: migrate onto `naboo`+`endor`+`tatooine`, keep `jupiter` as a live hot-fallback, wipe `jupiter` **last** → joins as 3rd control-plane | A working rollback stays online the whole time. |
| Power | **Line-interactive, pure-sine UPS** (e.g. APC Smart-UPS 1500) + **NUT** graceful shutdown. Protects the whole stack: cluster + `scarif` + UniFi US-48 switch + APs + cameras (when added) + OPNsense | No UPS today — main exposure is a whole-house outage dropping all 3 etcd nodes uncleanly. Pure sine for the NAS's active-PFC PSU (Silverstone SX500). Measured switch draw ~60W; total stack ~250–330W ≈ 30% of a 1500VA UPS → ~15–20 min runtime. |
| Storage SSDs | **2× matched PLP enterprise SATA SSD** (mirror) for the app/DB tier — Intel S4500/S4510, Samsung PM883, Micron 5300 | No-UPS makes per-drive PLP the main write-integrity protection; sync-fast for DBs/iSCSI. 240–480GB is plenty (media is on the HDD pool). |

**Storage ceiling:** `scarif` is a hard dependency for cluster state — keep it on
the UPS, treat reboots as planned. Revisit Longhorn only if an app must survive
TrueNAS downtime.

**Power-priority (NUT):** servers (etcd/DBs) are signalled to shut down **early**
(~5 min remaining); the switch + cameras + OPNsense keep running on the rest of
the battery (stateless — they just need power, no graceful shutdown). So a short
blip leaves everything up; a long outage takes the cluster down cleanly while the
cameras keep recording until the battery is spent.

---

## Peripherals (keep the cluster stateless)

- **Zigbee/Matter** — on an **Ethernet** coordinator (`slzb`); HA reaches it over
  the LAN → no node pinning.
- **OctoPrint** (Prusa + Brio) — moves to its own **Pi 3B+ (`octopi`)**, off the
  cluster; HA talks to it over the network.
- **Garage door** — Arduino **Mega 2560** (USB serial, no WiFi) stays plugged
  into `jupiter`; HA is pinned to `jupiter` and migrates **last**. Relocating it
  / a ser2net bridge to free HA float is a **deferred** optional later step.

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
- [x] **`endor` bought** — Lenovo M70q i5-10400T @**1,800 kr** (Blocket), arriving
      ~this week. RAM: it's 8G — add a **single 8G SODIMM → 16G** (uniform with
      `naboo`; cheapest) once you confirm a free slot. `naboo` is 2×8 (both slots
      full → replace-to-upgrade later; the pulled 2×8 can feed `endor`).
- [ ] **Buy a UPS** — line-interactive **pure-sine** (APC Smart-UPS 1500 ~1,500 kr
      used on Blocket); budget a fresh battery if old (~300–600 kr). Then wire NUT.
- [ ] **Buy the SSD pair** — 2× matched **PLP enterprise SATA** (Intel S4500/S4510,
      Samsung PM883), 240–480GB, ~500 kr each on Tradera. Check SMART wear on arrival.
- [ ] **Confirm `bookorjeman.com` zone is on Cloudflare** (for the DNS-01 cert).
- [ ] **Reserve `.40` IPs** (4 nodes + VIP + ~8 MetalLB + scarif), outside DHCP.
- [ ] **Add the SSD mirror pool** to the Jonsbo N4 (iSCSI app/DB tier).
- [ ] Confirm the 2×16TB HDD pool layout (mirror vs stripe).
- [ ] Stand up `octopi` (Pi 3B+) for the Prusa + Brio.

## Risks
- **GPU-in-k3s on NixOS** is the least-trodden step — validated early on
  `tatooine` (its own media mini-cutover) before the rest migrates.
- **Reprovisioning to NixOS is destructive** — data must be on `scarif`/backed
  up first; `jupiter` (the fallback) is wiped only when all else is green.
- **No UPS yet** — a whole-house outage drops all 3 etcd nodes uncleanly at once
  (HA doesn't help vs simultaneous power loss). Mitigation: buy a UPS + NUT, and
  PLP SSDs for the DB pool. Until then, power loss is the highest live risk.
- **`scarif` = single dependency** for cluster state → on the UPS, planned reboots.
- **No offsite backup yet** — plan restic/replication for immich + vaultwarden
  (the irreplaceable data) as a follow-up.

---

**Build steps:** [cluster-implementation.md](./cluster-implementation.md) — Stages A–H.
