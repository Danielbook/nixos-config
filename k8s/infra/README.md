# k8s/infra — Argo CD app-of-apps root

The Nix-delivered `root` Application (see `modules/nixos/services/argocd`) watches
this directory (recurse) and applies every manifest here.

- `apps.yaml`: the `apps` ApplicationSet. It makes one Application per app
  directory `k8s/apps/<app>/`, with name and namespace `<app>`.
- All other files: hand-written Chart Applications for apps that the template
  does not fit (Helm charts, other namespaces, extra syncOptions). An app with
  ksops Secrets adds its dir `k8s/<name>/` as a second source (for example
  `traefik.yaml`, `headlamp.yaml` and `democratic-csi.yaml`).

To add an app, see `docs/CLUSTER.md` (Add an app).

Argo's directory source only reads `*.yaml`/`*.yml`/`*.json`, so Argo ignores
this README.

Secrets: encrypt as `*.enc.yaml` (sops → cluster + daniel keys, `.sops.yaml`
rule). The repo-server ksops plugin decrypts them in-cluster.
