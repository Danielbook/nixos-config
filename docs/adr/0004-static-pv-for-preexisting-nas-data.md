# Pre-existing NAS data uses a static PV, not the CSI-dynamic StorageClass

Status: accepted

Stage D's media (jellyfin library, immich photo archive + uploads) already
lives on TrueNAS today, reached via SMB — it doesn't need to move anywhere.
The `nfs` StorageClass from Stage C (democratic-csi) provisions a **new**
dataset per PVC under `pool1/k8s/v`; pointing a dynamically-provisioned PVC at
it would mean copying however much existing media into a second dataset for
no reason. Instead, k8s consumes the existing TrueNAS NFS exports
(`/mnt/pool1/data`, `/mnt/pool1/media/photos`, `/mnt/pool1/media/image-backups`)
directly via a hand-authored static PV (server + path), with no
StorageClass/dynamic provisioning involved. This is the same shape Stage E1
will need for servarr's media once it migrates — any workload consuming
data that already lives on the NAS, rather than starting from empty storage,
takes this path instead of the `nfs`/`iscsi` StorageClasses.

## Considered and rejected

- **Copy existing media into a CSI-dynamic `nfs` PVC**: works, but duplicates
  potentially large datasets onto a second TrueNAS dataset with no benefit —
  rejected as pure waste.

## Consequences

- Static PVs bypass the CSI driver entirely: no snapshot integration (Stage
  C4's periodic snapshot tasks already cover these datasets directly on
  TrueNAS, so this isn't a regression), no dynamic resize.
- The existing NFS exports were scoped to a WireGuard-only network
  (`10.11.11.0/24`); they needed `10.10.40.0/24` (the cluster's network) added
  before k3s nodes could mount them at all — a prerequisite for this pattern
  working, not something CSI's own dynamic provisioning would have hit (CSI
  creates its own exports scoped correctly from the start).
