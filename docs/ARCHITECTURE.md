# Architecture

## Flake Structure

`flake.nix` defines two builder functions that inject `specialArgs` into modules:

| Function | specialArgs | Module path variable |
|----------|-------------|---------------------|
| `mkNixosConfiguration` | `inputs`, `outputs`, `hostname`, `userConfig`, `nixosModules` | `nixosModules = "${self}/modules/nixos"` |
| `mkHomeConfiguration` | `inputs`, `outputs`, `userConfig`, `nhModules` | `nhModules = "${self}/modules/home-manager"` |

`mkHomeConfiguration` accepts an `extraModules` parameter for host-specific flake modules (e.g., catppuccin, spicetify, noctalia). Servers pass `{}` to skip desktop flake modules.

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

## Module Layers (Dendritic Architecture)

The module tree branches from a universal trunk into host-type-specific layers:

```
common (all hosts)
├── desktop/common (desktop hosts: workstation, HTPC)
│   ├── desktop/hyprland (Hyprland compositor)
│   └── desktop/<other> (future: Kodi, etc.)
└── (server hosts skip desktop entirely)
```

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

### Home-Manager Modules (`modules/home-manager/`)

| Module | Layer | Purpose |
|--------|-------|---------|
| `common/` | Universal | CLI programs (20+), CLI packages, Claude Code settings, catppuccin |
| `desktop/common/` | Desktop | GUI programs (alacritty, firefox, vscode, etc.), desktop packages, desktop scripts |
| `desktop/hyprland/` | Compositor | Hyprland config, cursor, gtk/qt/xdg, desktop services (noctalia, awww, cliphist, hypridle) |
| `programs/` | Individual | 30+ program modules (imported by common or desktop/common) |
| `services/` | Individual | Service modules (imported by common, desktop/common, or desktop/hyprland) |
| `scripts/` | Universal | CLI scripts (fkill) |
| `scripts/desktop/` | Desktop | Desktop scripts (hyprshot, ocr, screen-recorder, waybar-restart) |
| `misc/` | Desktop | gtk, qt, wallpaper, xdg (imported by desktop/hyprland) |

## Adding a New Host

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
homeConfigurations."daniel@<hostname>" = mkHomeConfiguration "x86_64-linux" "daniel" "<hostname>" {};
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

Noctalia config lives in `home/daniel/weepinbell/noctalia/` — files are **copied** (not symlinked) on activation so the GUI can edit them. `just noctalia-sync` copies runtime changes back to the repo (runs automatically before `just home-manager-switch`).
