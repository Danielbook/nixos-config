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

### Machines

**Host**:
A machine that this flake configures, as a NixOS or nix-darwin system. All
six machines in the fleet are hosts.
_Avoid_: "server" for a host. k3s uses "server" as the name of a
control-plane role.

**Cluster node**:
A host that runs k3s as a member of the cluster. Each cluster node has an
entry in the Node inventory. `coruscant` and `dagobah` are hosts, but not
cluster nodes.
_Avoid_: "host" when you mean a cluster node. Also avoid "jupiter", the old
name of `hoth`.

**Node inventory**:
The one list of cluster nodes, with the name, IP and role of each node. It
is the single source of truth for these values.
_Avoid_: using a node IP from a different file or doc as the truth. Those
are reference copies.

### Roles

**Bootstrap node**:
The single control-plane node that initialises the embedded-etcd cluster
(`role = server-init`). Every other node *joins* it. Currently `naboo`.
_Avoid_: "master" (k3s uses control-plane / server).

**Control-plane node**:
A cluster node that runs the Kubernetes API and an etcd member (k3s role
`server` or `server-init`). There are three: the Bootstrap node and two
nodes that join it.
_Avoid_: "master".

**Agent node**:
A cluster node that runs workloads only, with no API server or etcd member
(k3s role `agent`). Currently only `tatooine`, the node with the GPU.
_Avoid_: "worker". k3s and the Node inventory use "agent".

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

**Host-network app**:
An app that uses the network of its node directly, not the pod network. It
is pinned to one cluster node, and that node opens the ports of the app. To
move the app to a different node, change the app and both nodes together.
Currently `homeassistant`, `matter-server` and `music-assistant`, all on
`naboo`.
_Avoid_: making an app a host-network app without a need for it. The usual
need is LAN discovery or a protocol that the pod network cannot carry
(mDNS, AirPlay, Matter).

**App directory**:
The directory `k8s/apps/<app>/` that holds all that Argo CD deploys for one
app: its manifests and its sops-encrypted `*.enc.yaml` Secrets. An app with
secrets also has a `kustomization.yaml` with the ksops generator. The `apps`
ApplicationSet makes one Application per app directory, with the name and
namespace `<app>`.
_Avoid_: a separate `k8s/<app>/` secret tree with its own `<app>-secret`
Application (the old split, removed in 2026-10).
