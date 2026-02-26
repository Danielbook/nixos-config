# Architecture

## Flake Structure

`flake.nix` defines three builder functions that inject `specialArgs` into modules:

| Function | specialArgs | Module path variable |
|----------|-------------|---------------------|
| `mkNixosConfiguration` | `inputs`, `outputs`, `hostname`, `userConfig`, `nixosModules` | `nixosModules = "${self}/modules/nixos"` |
| `mkHomeConfiguration` | `inputs`, `outputs`, `userConfig`, `nhModules` | `nhModules = "${self}/modules/home-manager"` |
| `mkDarwinConfiguration` | `inputs`, `outputs`, `hostname`, `userConfig`, `darwinModules` | `darwinModules = "${self}/modules/darwin"` |

`userConfig` is an attrset: `{ name, fullName, email, avatar }` — modules use it for git config, user creation, etc.

## Module Import Pattern

Modules are referenced via **string interpolation** of the path variables, not relative imports:

```nix
# In a host's default.nix:
imports = [
  "${nixosModules}/common"
  "${nixosModules}/desktop/hyprland"
  "${nixosModules}/nvidia"
];

# In a home config:
imports = [
  "${nhModules}/common"
  "${nhModules}/desktop/hyprland"
];

# Within home-manager modules referencing siblings:
imports = [
  "${nhModules}/misc/gtk"
  "${nhModules}/services/noctalia"
];
```

Relative imports (`../programs/git`) are used only inside `common/default.nix` aggregator modules.

## Module Organization

Three separate module trees with strict separation:

- **`modules/nixos/`** — System-level: `common/`, `desktop/{hyprland,kde}`, `nvidia/`, `server/headless/`, `services/{tlp,audio-lowlatency,usb-serial}`, `memory-protection/`
- **`modules/home-manager/`** — User-space: `common/` (Linux aggregator), `common-darwin/` (macOS aggregator), `desktop/{hyprland,kde}`, `programs/` (30+ programs), `services/`, `misc/`, `scripts/`
- **`modules/darwin/`** — macOS system-level: `common/`, `desktop/`

**Key patterns:**
- `common/` modules are **aggregators** — they import 20-30 sub-modules (programs, services). Import `common` to get the full stack.
- `common-darwin/` is a separate macOS-specific aggregator (different subset of programs).
- `desktop/hyprland/` (home-manager) imports related services: noctalia, awww, cliphist, kanshi, hypridle, gtk, qt, xdg.
- `server/headless/` imports `common` then uses `lib.mkForce` to strip desktop packages/services.

## Overlays

`overlays/default.nix` exports:
- **`stable-packages`** — Makes `pkgs.stable.*` available (nixpkgs-stable/nixos-25.05). Used in modules via `outputs.overlays.stable-packages`.
- **`vim-plugins-from-source`** — Builds specific vim plugins from source (workaround for hash issues).

Home Manager configs apply overlays automatically (set in `mkHomeConfiguration`). NixOS/Darwin modules apply them explicitly.

## Noctalia Config

Noctalia config lives in `home/daniel/weepinbell/noctalia/` — files are **copied** (not symlinked) on activation so the GUI can edit them. `just noctalia-sync` copies runtime changes back to the repo (runs automatically before `just home-manager-switch`).
