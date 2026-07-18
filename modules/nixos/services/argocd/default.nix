# Argo CD (GitOps controller) + ksops (in-cluster sops decryption).
#
# Install shape mirrors the metallb/kube-vip pattern: pin the upstream native
# install.yaml (fetchurl), then render a kustomize overlay at BUILD time into a
# single manifest shipped via services.k3s.manifests. The overlay does three
# things in one render: creates the argocd Namespace, patches argocd-repo-server
# to embed KSOPS (initContainer copies ksops+kustomize into the repo-server, age
# key mounted from the out-of-band `sops-age` secret), and patches argocd-cm to
# enable kustomize exec plugins.
#
# Nix owns the Argo INSTALL; git (the app-of-apps below) owns everything else —
# no self-management circularity. The root Application points Argo at k8s/infra.
#
# CHICKEN-AND-EGG (one-time, manual, out-of-band — see docs/adr/0001):
#   the dedicated cluster age PRIVATE key must be loaded as secret `sops-age`
#   (key keys.txt) in the argocd namespace before repo-server can decrypt. Until
#   then repo-server sits ContainerCreating (missing secret volume) — expected.
#     <priv-key> | ssh daniel@<node> \
#       'sudo k3s kubectl create secret generic sops-age -n argocd \
#          --from-file=keys.txt=/dev/stdin'
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.argocd;

  argocdVersion = "v3.4.4";
  ksopsImage = "viaductoss/ksops:v4.5.1";

  # Pinned upstream install. Bump the tag + rehash (nix store prefetch-file <url>).
  install = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/argoproj/argo-cd/${argocdVersion}/manifests/install.yaml";
    hash = "sha256-sPkRmCHy4ZuFLIQrnLI165w+8VSVVPvaaqWQTo1EDq4=";
  };

  namespace = pkgs.writeText "namespace.yaml" ''
    apiVersion: v1
    kind: Namespace
    metadata:
      name: argocd
  '';

  # KSOPS strategic-merge patch on argocd-repo-server (viaduct-ai/kustomize-sops
  # README method): initContainer installs ksops + a compatible kustomize into a
  # shared emptyDir on the repo-server PATH; age key mounted from `sops-age`.
  repoServerPatch = pkgs.writeText "repo-server-patch.yaml" ''
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: argocd-repo-server
    spec:
      template:
        spec:
          volumes:
            - name: custom-tools
              emptyDir: {}
            - name: sops-age
              secret:
                secretName: sops-age
          initContainers:
            - name: install-ksops
              image: ${ksopsImage}
              # Distroless image: no shell, no entrypoint. Call the ksops binary
              # directly; `install --with-kustomize` copies ksops + a compatible
              # kustomize into /custom-tools (the repo-server PATH).
              command: ["/usr/local/bin/ksops"]
              args:
                - install
                - --with-kustomize
                - /custom-tools
              volumeMounts:
                - mountPath: /custom-tools
                  name: custom-tools
          containers:
            - name: argocd-repo-server
              env:
                - name: SOPS_AGE_KEY_FILE
                  value: /.config/sops/age/keys.txt
              volumeMounts:
                - mountPath: /usr/local/bin/kustomize
                  name: custom-tools
                  subPath: kustomize
                - mountPath: /usr/local/bin/ksops
                  name: custom-tools
                  subPath: ksops
                - mountPath: /.config/sops/age/
                  name: sops-age
  '';

  # Enable kustomize exec plugins so repo-server runs the ksops generator.
  argocdCmPatch = pkgs.writeText "argocd-cm-patch.yaml" ''
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: argocd-cm
    data:
      kustomize.buildOptions: "--enable-alpha-plugins --enable-exec"
  '';

  kustomization = pkgs.writeText "kustomization.yaml" ''
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: argocd
    resources:
      - namespace.yaml
      - install.yaml
    patches:
      - path: repo-server-patch.yaml
        target:
          kind: Deployment
          name: argocd-repo-server
      - path: argocd-cm-patch.yaml
        target:
          kind: ConfigMap
          name: argocd-cm
  '';

  # Render offline: all inputs copied into the build dir so kustomize's path
  # security check (resources must be under the kustomization root) passes.
  rendered = pkgs.runCommand "argocd-install.yaml" { nativeBuildInputs = [ pkgs.kustomize ]; } ''
    mkdir build
    cp ${install} build/install.yaml
    cp ${namespace} build/namespace.yaml
    cp ${repoServerPatch} build/repo-server-patch.yaml
    cp ${argocdCmPatch} build/argocd-cm-patch.yaml
    cp ${kustomization} build/kustomization.yaml
    kustomize build build > $out
  '';

  # Root app-of-apps: points Argo at k8s/infra (a plain dir of child Applications).
  # targetRevision tracks feat/cluster until B5 merges to main — flip to main then.
  rootApp = pkgs.writeText "argocd-root.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: root
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://forgejo.local.bookorjeman.com/danielbook/nixos-config.git
        targetRevision: feat/cluster
        path: k8s/infra
        directory:
          recurse: true
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
          # App-of-apps root can legitimately manage zero children between stages;
          # without this, Argo refuses to prune the last child ("would wipe out
          # all resources").
          allowEmpty: true
  '';
in
{
  options.homelab.argocd.enable = lib.mkEnableOption "Argo CD GitOps controller + ksops";

  config = lib.mkIf cfg.enable {
    services.k3s.manifests = {
      # Rendered install; the root app requires Argo's CRDs so its first apply may
      # fail — the k3s addon controller re-enqueues until they exist (like metallb).
      argocd.source = rendered;
      argocd-root.source = rootApp;
    };
  };
}
