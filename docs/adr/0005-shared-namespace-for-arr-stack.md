# Shared `arr` namespace for the *arr stack, breaking the one-namespace-per-app convention

Every other cluster app (jellyfin, immich, seerr) gets its own namespace. The
*arr stack (gluetun+deluge+nzbget+prowlarr in one VPN pod, plus
sonarr/radarr/lidarr/bazarr as floats) instead shares a single `arr`
namespace, because the design requires one NFS-backed downloads PVC mounted
by both the VPN pod and every float so completed-download imports resolve at
identical paths — and PVCs are namespace-scoped. Per-app namespaces would
mean N near-duplicate static PV objects pointed at the same NFS export for
zero isolation benefit (no separate RBAC/ownership need here — these apps are
one cooperating unit, not independent tenants). Decided 2026-07-04.
