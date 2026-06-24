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
| `endor` | Lenovo ThinkCentre M70q Tiny | i5-10400T (6c/12t) | 16G (+ stick) | 256G NVMe | — | Control-plane (etcd) — **pending purchase @2,000 kr** |
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

**Storage ceiling:** `scarif` is a hard dependency for cluster state — UPS it,
treat reboots as planned. Revisit Longhorn only if an app must survive TrueNAS
downtime.

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
- [ ] **Buy `endor`** — Lenovo M70q i5-10400T @2,000 kr (Blocket) + a 16G SODIMM.
      Seller confirmed the i5-10400**T**. (Verify: 1×8G stick = free slot.)
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
- **`scarif` = single dependency** for cluster state → UPS + planned reboots.
- **No offsite backup yet** — plan restic/replication for immich + vaultwarden
  (the irreplaceable data) as a follow-up.

---

**Build steps:** [cluster-implementation.md](./cluster-implementation.md) — Stages A–H.
