# k8s/infra — Argo CD app-of-apps root

The Nix-delivered `root` Application (see `modules/nixos/services/argocd`) watches
this directory (recurse) and applies every child `Application` manifest here.

Empty for now — the B5 smoke test that proved the ksops pipeline lived here and
was torn down. Stage E populates this with the real infra apps (traefik,
democratic-csi, nvidia-plugin, and metallb once adopted out of the Nix module).

Argo's directory generator only reads `*.yaml`/`*.yml`/`*.json`, so this README
is ignored — it exists to keep the path present (git drops empty dirs).

Secrets: encrypt as `*.enc.yaml` (sops → cluster + daniel keys, `.sops.yaml`
rule); the repo-server ksops plugin decrypts them in-cluster.
