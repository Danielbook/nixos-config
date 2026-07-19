# Cluster improvements — deferred work

Outstanding items moved out of `docs/cluster-implementation.md` (the migration
itself is done; see that doc for full stage history). Each item here is
independent and can be picked up on its own.

## Convert `scarif` to bare-metal TrueNAS (was Stage G)

Gate: nothing left on the Jonsbo/Proxmox box `n4` — servarr pods live
in-cluster; the old `servarr` VM (VMID 101) is stopped rollback cruft.

Precondition (G0) already verified in Proxmox: the data pool is 2× 16TB
Seagate Exos passed through raw via `/dev/disk/by-id` (scsi1/scsi2), so the
pool imports cleanly on bare metal. The only virtual disk (scsi0, 32G
local-lvm) is the disposable TrueNAS OS boot — reinstall fresh.

- [ ] Confirm the 2×16TB HDD pool layout (mirror vs stripe).
- [ ] SSD mirror pool for iSCSI app/DB PVs = hardware to add to the N4.
- [ ] Export ZFS pools (clean shutdown) in the TrueNAS VM.
- [ ] Wipe Proxmox; install TrueNAS SCALE bare-metal; **import** pools
      (intact via passthrough).
- [ ] Re-point democratic-csi at the new IP/API if changed.
- [ ] Verify: PVs reconnect; immich reads its library.

## Decommission Proxmox (was H1)

tatooine (D1) and hoth (F2) are already bare-metal NixOS. The only Proxmox
left is the `n4` box hosting the TrueNAS VM — it goes away with the scarif
conversion above. Afterwards: no Proxmox anywhere.

## democratic-csi → TrueNAS TLS deferral (was C3, re-affirmed 2026-07-19, #14)

**Deferred:** both driver configs (`k8s/truenas/driver-config-{iscsi,nfs}.enc.yaml`,
mounted via the charts' `existingConfigSecret`) reach the TrueNAS API at the raw
IP `host: 10.10.40.10` with `allowInsecure: true` — TrueNAS presents only a
self-signed cert, so the connection is unverified.

**Why:** the original plan (C3) assumed `truenas.local.bookorjeman.com` would
carry a valid cert, but that name resolved to jupiter's legacy Traefik (.30),
and jupiter is wiped (F2). Making TrueNAS itself present a trustable cert is
manual TrueNAS-UI work (ACME setup), and the scarif bare-metal conversion above
reinstalls TrueNAS anyway — doing it twice is disproportionate, so it waits.

**Risk accepted:** CSI API traffic (incl. the api key) is MITM-able by any host
on the storage LAN segment; traffic never leaves the LAN and no untrusted hosts
sit on it. Accepted until the conversion.

**Lift when** TrueNAS is reinstalled (scarif conversion), in one pass:

1. TrueNAS native ACME cert: Credentials → Certificates → ACME
   DNS-Authenticator (Cloudflare) → CSR for `truenas.local.bookorjeman.com` →
   ACME cert → set as GUI cert.
2. OPNsense Unbound override `truenas.local.bookorjeman.com` → `10.10.40.10`
   (or the post-conversion IP).
3. Flip both driver configs (`EDITOR=nano sops <file>` — see
   cluster-implementation C2 for the formatter pitfall) to the hostname +
   `allowInsecure: false`; Argo resync + restart the controller pods.

## octoprint → dedicated Pi `kamino` (was F1e, decided 2026-07-08)

Not a k8s migration candidate — USB-attached Prusa MK3S
(`/dev/serial/by-id/usb-Prusa_Research__prusa3d.com__Original_Prusa_i3_MK3_CZPX2921X004XK96438-if00`).
Move the printer to a Raspberry Pi running NixOS, hostname `kamino`, its own
flake host — once the Pi is acquired. Deliberately docs-only until then.
Facts to carry forward:

- Image was `octoprint/octoprint:latest` on jupiter; NixOS's
  `services.octoprint` module is likely simpler than a container on a
  single-purpose Pi.
- Config data: 961M copied to `hoth:/home/daniel/jupiter-backup/` (jupiter is
  wiped — that backup is the only copy; tar to the Pi or fresh-start).

## matter-server mDNS startup burst (was F1d)

`Failed to advertise records: Network is unreachable` burst in the first
~100ms after pod start on naboo (2026-07-08), then self-recovered. Likely a
multicast-socket-join race, not a real gap — no Matter devices in use, no
action taken. If a future device commissioning fails: investigate OPNsense
IPv6 (WAN DHCPv6-PD, LAN Track Interface + RA `Assisted`, IPv6 pass rule).
Link-local multicast (`ff02::fb`, UDP 5353) isn't routed, so a global prefix
is probably irrelevant.

## Wildcard DNS revisit

A single Unbound `*` host override for `*.local.bookorjeman.com` crashed DNS
network-wide (2026-07); currently one per-app override each pointing at the
Traefik LB (`10.10.40.51`). Revisit with a dedicated subdomain zone
(`local-zone: ... redirect` + one `local-data` A) so new services need no DNS
change.

## Homepage kubernetes widget (review leftover)

`k8s/apps/homepage/homepage.yaml` already ships the RBAC (ServiceAccount +
`homepage-k8s-widget` ClusterRole/Binding: get/list on nodes/namespaces/pods
and `metrics.k8s.io`), but the widget config itself lives in
`widgets.yaml`/`services.yaml` on the PVC — app state, not git-tracked. Enable
the cluster/node CPU+memory widget there and verify it reads metrics (k3s'
bundled metrics-server).

## argocd-initial-admin-secret deletion check (review leftover)

Argo CD's install auto-generates `argocd-initial-admin-secret` (plaintext
initial admin password) in the `argocd` namespace. Nothing in the Nix
bootstrap (`modules/nixos/services/argocd`) deletes it or checks that it's
gone. Verify in-cluster that it has been deleted post-setup — Argo docs say to
delete it once the password is changed/stored — and delete it if it still
exists.

## dind runner hardening (review leftover)

`k8s/apps/forgejo/runner.yaml` runs CI jobs against a **privileged**
`docker:dind` sidecar — any Actions workflow is effectively root on the node
it lands on. Ideas, none applied yet:

- Rootless dind (`docker:*-dind-rootless`) instead of `privileged: true`.
- Pin the runner off the control-planes (nodeSelector/taint) to contain blast
  radius.
- Resource limits on the runner + dind containers (currently none).
- Keep Actions restricted to trusted repos/users on the Forgejo side.

## Future

- Offsite backup for **immich photos** (vaultwarden dropped — replaced by
  paid Bitwarden): restic/ZFS-replication to a cloud bucket.
- RAM 16→32G per node when memory requests pass ~80% (see CLUSTER.md
  capacity section).
