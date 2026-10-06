# nixos-config

Glossary for this declarative NixOS/nix-darwin fleet and its home-lab k3s
cluster. Defines the project's canonical language — not implementation; the
"how" lives in `docs/`.

## Language

### Cluster layering

**Node provisioning**:
Getting NixOS (and therefore k3s itself) onto a physical box, and keeping that
box's OS config in sync. Lives in this repo; driven by `nixos-rebuild`.
_Avoid_: "the cluster setup" (ambiguous between this and workload provisioning).

**Workload provisioning**:
Deploying what *runs on* the cluster (apps, ingress, storage drivers) once it
is up. Lives in `k8s/`; driven by Argo CD / GitOps.
_Avoid_: "deploying the cluster" (that's node provisioning).

These are **two ordered layers, never alternatives**: node provisioning stands
up a running cluster, then workload provisioning lives on top of it.

### Roles

**Bootstrap node**:
The single control-plane node that initialises the embedded-etcd cluster
(`role = server-init`). Every other node *joins* it. Currently `naboo`.
_Avoid_: "master" (k3s uses control-plane / server).

**App namespace**:
The default workload-provisioning pattern — one Kubernetes namespace per
deployed app (jellyfin, immich, seerr, ...).
_Avoid_: assuming every app follows this — see Shared namespace group.

**Shared namespace group**:
An exception to App namespace: several cooperating apps placed in one
namespace because they must share a namespace-scoped resource (typically a
PVC) that can't cross namespace boundaries. Currently only `arr` (the
downloaders pod + sonarr/radarr/lidarr/bazarr/bindery floats, sharing one NFS
downloads PVC) — see ADR-0005.
_Avoid_: creating one of these by default; it's a deliberate exception, not
the norm.
