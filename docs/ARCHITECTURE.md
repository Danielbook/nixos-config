# Architecture

## Flake Structure

`flake.nix` defines two builder functions that inject `specialArgs` into modules:

| Function | specialArgs | Module path variable |
|----------|-------------|---------------------|
| `mkNixosConfiguration` | `inputs`, `outputs`, `hostname`, `userConfig`, `nixosModules` | `nixosModules = "${self}/modules/nixos"` |
| `mkDarwinConfiguration` | `inputs`, `outputs`, `hostname`, `userConfig`, `darwinModules` | `darwinModules = "${self}/modules/nix-darwin"` |
| `mkHomeConfiguration` | `inputs`, `outputs`, `userConfig`, `nhModules` | `nhModules = "${self}/modules/home-manager"` |

`mkHomeConfiguration` accepts an `extraModules` parameter for host-specific flake modules (e.g., catppuccin, spicetify, noctalia). Servers skip the *desktop* flake modules (spicetify, noctalia, hyprdynamicmonitors) but still pass `catppuccin.homeModules.catppuccin` — the shared home `common` layer themes tmux/starship/etc. through it, so every home config needs it.

`userConfig` is an attrset: `{ name, fullName, email, avatar }` — modules use it for git config, user creation, etc.

## Module Import Pattern

Modules are referenced via **string interpolation** of the path variables, not relative imports:

```nix
# In a host's default.nix:
imports = [
  "${nixosModules}/common"
  "${nixosModules}/desktop/common"    # Desktop hosts only
  "${nixosModules}/desktop/hyprland"  # Compositor-specific
  "${nixosModules}/graphics"
];

# In a home config:
imports = [
  "${nhModules}/common"
  "${nhModules}/desktop/common"    # Desktop hosts only
  "${nhModules}/desktop/hyprland"  # Compositor-specific
];

# Within home-manager modules referencing siblings:
imports = [
  "${nhModules}/misc/gtk"
  "${nhModules}/services/noctalia"
];
```

Relative imports (`../programs/git`) are used only inside `common/default.nix` aggregator modules.

## Module Layers

The module tree branches from a universal trunk into host-type-specific layers:

```
common (all hosts, all platforms)
├── desktop/common (desktop hosts: workstation, HTPC — Linux only)
│   ├── desktop/hyprland (Hyprland compositor)
│   └── desktop/<other> (future: Kodi, etc.)
├── (macOS hosts import common + individual GUI programs)
└── (server hosts skip desktop entirely)
```

### Platform Conditionals

Shared home-manager modules use `pkgs.stdenv.isDarwin` / `pkgs.stdenv.isLinux` for the few platform-specific bits:
- `systemd.user.startServices` — Linux only
- `home.homeDirectory` — `/home/` vs `/Users/`
- `nh` package — Linux only (NixOS helper)
- `services.gpg-agent` — Linux only (macOS uses native pinentry)
- systemctl completion preview in zsh — Linux only

### nix-darwin Modules (`modules/nix-darwin/`)

| Module | Purpose |
|--------|---------|
| `common/` | Nix settings, Homebrew, macOS system defaults, Touch ID sudo |

### NixOS Modules (`modules/nixos/`)

| Module | Layer | Purpose |
|--------|-------|---------|
| `common/` | Universal | Nix settings, boot loader, networking, users, SSH, Docker, locale |
| `desktop/common/` | Desktop | PipeWire, Bluetooth, fonts, printing, Flatpak, Wayland vars, touchpad |
| `desktop/hyprland/` | Compositor | greetd, Hyprland, blueman, gvfs, desktop packages |
| `graphics/` | Per-host | GPU config (Intel iGPU, NVIDIA) |
| `memory-protection/` | Opt-in | systemd-oomd, memory limits |
| `services/tlp/` | Per-host | Laptop power management |
| `services/audio-lowlatency/` | Per-host | PipeWire pro-audio tuning |
| `services/usb-serial/` | Per-host | USB serial device support |
| `services/k3s/` | Cluster | Role-parameterized k3s node (`homelab.k3s`: server-init/server/agent) + kube-vip |

### Home-Manager Modules (`modules/home-manager/`)

| Module | Layer | Purpose |
|--------|-------|---------|
| `common/` | Universal | CLI programs (20+), CLI packages, Claude Code settings, catppuccin |
| `desktop/common/` | Desktop | GUI programs (alacritty, firefox, vscode, etc.), desktop packages, desktop scripts |
| `desktop/hyprland/` | Compositor | Hyprland config, cursor, gtk/qt/xdg, desktop services (noctalia, cliphist, hypridle) |
| `programs/` | Individual | 30+ program modules (imported by common or desktop/common) |
| `services/` | Individual | Service modules (imported by common, desktop/common, or desktop/hyprland) |
| `scripts/` | Universal | CLI scripts (fkill) |
| `scripts/desktop/` | Desktop | Desktop scripts (ocr, screen-recorder) |
| `misc/` | Desktop | gtk, qt, wallpaper, xdg (imported by desktop/hyprland) |

## Adding a New Host

### macOS (nix-darwin)

1. Create `hosts/<hostname>/default.nix`:
```nix
{ hostname, darwinModules, ... }: {
  imports = [ "${darwinModules}/common" ];
  networking.hostName = hostname;
}
```

2. Create `home/<username>/<hostname>/default.nix`:
```nix
{ nhModules, inputs, ... }: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/programs/ghostty"
    "${nhModules}/programs/vscode"
    inputs.sops-nix.homeManagerModules.sops
  ];
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}
```

3. Add to `flake.nix`:
```nix
darwinConfigurations.<hostname> = mkDarwinConfiguration "<hostname>" "daniel";
homeConfigurations."daniel@<hostname>" = mkHomeConfiguration "aarch64-darwin" "daniel" "<hostname>" {
  extraModules = [ catppuccin.homeModules.catppuccin ];
};
```

### Server (headless)

1. Create `hosts/<hostname>/default.nix`:
```nix
{ hostname, nixosModules, ... }: {
  imports = [
    ./hardware-configuration.nix
    "${nixosModules}/common"
  ];
  networking.hostName = hostname;
  system.stateVersion = "25.05";
}
```

2. Create `home/<username>/<hostname>/default.nix`:
```nix
{ nhModules, inputs, ... }: {
  imports = [
    "${nhModules}/common"
    inputs.sops-nix.homeManagerModules.sops
  ];
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}
```

3. Add to `flake.nix`:
```nix
nixosConfigurations.<hostname> = mkNixosConfiguration "<hostname>" "daniel";
homeConfigurations."daniel@<hostname>" = mkHomeConfiguration "x86_64-linux" "daniel" "<hostname>" {
  extraModules = [ catppuccin.homeModules.catppuccin ];  # required by the shared home common layer
};
```

### Desktop (workstation/HTPC)

Same as server, but import `desktop/common` + a compositor module, and pass desktop flake modules:

```nix
# hosts/<hostname>/default.nix
imports = [
  "${nixosModules}/common"
  "${nixosModules}/desktop/common"
  "${nixosModules}/desktop/hyprland"  # or desktop/kodi, etc.
];

# flake.nix
homeConfigurations."daniel@<hostname>" = mkHomeConfiguration "x86_64-linux" "daniel" "<hostname>" {
  extraModules = [
    catppuccin.homeModules.catppuccin
    # ... other desktop flake modules
  ];
};
```

## Overlays

`overlays/default.nix` exports:
- **`vim-plugins-from-source`** — Builds specific vim plugins from source (workaround for hash issues).

All overlays are applied automatically via `builtins.attrValues outputs.overlays` in both `mkHomeConfiguration` (flake.nix) and `modules/nixos/common/default.nix`.

## Noctalia Config

Noctalia config lives in `home/daniel/coruscant/noctalia/` — files are **copied** (not symlinked) on activation so the GUI can edit them. `just noctalia-sync` copies runtime changes back to the repo (runs automatically before `just home-manager-switch`).

## k3s Cluster Config Map

Cluster config splits across two layers: **NixOS provisions the nodes**, **Argo CD (GitOps) provisions the workloads**. Strategy/decisions live in `docs/CLUSTER.md`; stage-by-stage build history in `docs/cluster-implementation.md`.

| Layer | Path | Purpose |
|-------|------|---------|
| Node role module | `modules/nixos/services/k3s/` | Role-parameterized k3s node (`homelab.k3s`: server-init/server/agent) + kube-vip |
| Argo CD bootstrap | `modules/nixos/services/argocd/` | Nix-delivered Argo CD install + root app-of-apps pointed at `k8s/infra` |
| Per-host config | `hosts/naboo/`, `hosts/endor/`, `hosts/tatooine/`, `hosts/hoth/` | Sets `homelab.k3s` role/options per node; host-level secrets (`secrets.yaml`, pre-generated `ssh_host_ed25519_key.sops`) |
| App-of-apps root | `k8s/infra/` | Child Argo CD `Application` manifests (one per workload) that Argo's directory generator applies — see `k8s/infra/README.md` |
| Per-app manifests | `k8s/<app>/` (e.g. `k8s/traefik/`, `k8s/authentik/`, `k8s/ollama/`) | Kustomize dirs — `kustomization.yaml`, `secret-generator.yaml`, sops-encrypted `*-env.enc.yaml` |
| Raw Kubernetes manifests | `k8s/apps/<app>/` | Deployment/Service/etc. YAML referenced by the matching `k8s/infra/<app>.yaml` Application |
| Helm charts | `k8s/charts/` | Vendored/local charts (e.g. `k8s/charts/ingress` for Traefik) |
| One-off migration Jobs | `k8s/migration/` | Data migration Jobs run during cutover (Stage F), not part of steady-state GitOps |
| Cluster secrets policy | `.sops.yaml` | Age recipients (daniel + per-host + dedicated `cluster` key) and `path_regex` rules deciding which keys encrypt which paths |
| ADRs | `docs/adr/` | e.g. `0001-cluster-secrets-age-key.md` (ksops uses a dedicated cluster key, never daniel's personal key), `0002-node-provisioning-host-keys.md` |

All `k8s/**/*.enc.yaml` files are sops-encrypted and decrypted in-cluster by ksops using the dedicated cluster age key — see [SECRETS.md](./SECRETS.md) and [ADR 0001](./adr/0001-cluster-secrets-age-key.md).
