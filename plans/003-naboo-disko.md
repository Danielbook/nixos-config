# Plan 003: Declarative partitioning for `naboo` via disko

> **STATUS: DONE (2026-06-30)** — applied to the repo and used to install naboo
> via nixos-anywhere (disko wiped the 128G NVMe; ext4 root + 1G ESP confirmed).

> **Executor instructions**: Follow step by step. Run every verification command
> and confirm the expected result before moving on. If a STOP condition occurs,
> stop and report — do not improvise. When done, update the status row in
> `plans/README.md`.

## Status

- **Priority**: P1 (blocks the `naboo` nixos-anywhere install)
- **Effort**: S
- **Risk**: MEDIUM — disko **wipes the target disk** on install. Only ever run
  against `naboo`'s blank 128G NVMe, never an in-use disk.
- **Depends on**: none (pure repo change; runs before any hardware exists)
- **Category**: cluster / node-provisioning
- **Planned at**: commit `a3477f6`, 2026-06-30

## Why this matters

`nixos-anywhere --flake .#naboo` needs a `config.disko` partition layout to drive
the install; without it the command has nothing to partition and fails. This is
plan item **A3** in `docs/cluster-implementation.md` ("Add `disko.nix` for
declarative partitioning"), currently the only unmet prerequisite for the
Stage B bootstrap. Declarative partitioning is also what makes a node
*disposable* — wipe + re-run nixos-anywhere yields a byte-identical box, which is
the "stateless nodes" goal in `docs/CLUSTER.md`.

## Design decisions

| Choice | Value | Rationale |
|--------|-------|-----------|
| Filesystem | **ext4** on root | Nodes hold only OS + k3s; all app/DB/media data lives on `scarif`. No zfs/btrfs complexity warranted. |
| Swap | **none** | k3s/kubelet defaults to failing on swap; matches the placeholder `swapDevices = [ ]`. |
| Scheme | **GPT**: ESP + root | UEFI + systemd-boot (set by `modules/nixos/common`). |
| ESP | **1 GiB**, vfat, `/boot` | nixos-unstable accumulates generations; 1G avoids ESP-full pain. Cheap on 128G. |
| Device | **`/dev/nvme0n1`** | Single NVMe on the M80q. **Confirm on the box** (Step 0). |

No ADR: ext4/no-swap on a stateless k3s node is conventional, not a surprising
hard-to-reverse trade-off.

## Scope

**In scope** (the only files to modify/create):
- `hosts/naboo/disko.nix` (new)
- `hosts/naboo/default.nix` (add 2 imports)
- `hosts/naboo/hardware-configuration.nix` (drop the placeholder `fileSystems` +
  `swapDevices` — disko owns them now)
- `flake.nix` (add the `disko` input)

**Out of scope**: every other host, the k3s module, any `k8s/` manifest.

## Steps

### Step 0: Confirm the disk device (on the box, before install)

Once `naboo` boots the NixOS installer USB, run `lsblk -d -o NAME,SIZE,TYPE`.
Expect a single ~119G `nvme0n1` disk. If the device is named differently (e.g.
`nvme1n1`), use that path in Step 1 instead. **STOP** if there is more than one
disk and it's ambiguous which is the 128G NVMe.

### Step 1: Create `hosts/naboo/disko.nix`

```nix
# Declarative partitioning for naboo's 128G NVMe (plan 003).
# disko wipes this disk on nixos-anywhere install — naboo only, blank disk only.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1"; # confirm with `lsblk` on the box (plan step 0)
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
```

### Step 2: Wire disko into `hosts/naboo/default.nix`

Add to the `imports` list (alongside the existing entries):

```nix
    inputs.disko.nixosModules.disko
    ./disko.nix
```

### Step 3: Strip the placeholder layout from `hardware-configuration.nix`

disko now defines `fileSystems` and `swapDevices`; leaving the placeholder
definitions causes a duplicate-`fileSystems."/"` eval error. In
`hosts/naboo/hardware-configuration.nix`, **delete** the two `fileSystems.*`
blocks and the `swapDevices = [ ];` line. **Keep** the `imports`,
`boot.initrd.availableKernelModules`, `boot.kernelModules`,
`nixpkgs.hostPlatform`, and `hardware.cpu.intel.updateMicrocode` lines — those
are correct for the M80q and don't need regenerating.

### Step 4: Add the `disko` input to `flake.nix`

In the `inputs` block:

```nix
    # Declarative disk partitioning (k3s node installs via nixos-anywhere)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

`naboo` reaches it via `inputs.disko` (the `@inputs` catch-all) — no change to
the `outputs` destructure needed.

## Verify

```
nix flake check          # or: just flake-check  (on a linux host)
just check-all           # nixfmt + statix + deadnix + flake check
```

Both green. Specifically, `nix eval .#nixosConfigurations.naboo.config.disko.devices.disk.main.device`
should print `/dev/nvme0n1`.

## Install (after merge — runs on real hardware, Stage B)

```
nix run github:nix-community/nixos-anywhere -- \
  --flake .#naboo --target-host root@<naboo-.40-IP>
```

disko partitions + formats, then NixOS installs. Post-install: capture naboo's
host age key (`ssh-to-age` on its host pubkey), add `&naboo` to `.sops.yaml`,
`sops updatekeys hosts/naboo/secrets.yaml` (see `hosts/naboo/default.nix`
comment).

## STOP conditions

- Step 0 shows more than one disk and the 128G NVMe is ambiguous.
- `flake check` errors with a duplicate `fileSystems."/"` — Step 3 was missed.
- The box uses SATA/eMMC (device not `nvme*`) — re-confirm the layout before
  proceeding.

## Done criteria

- [ ] `hosts/naboo/disko.nix` exists with the layout above
- [ ] `hosts/naboo/default.nix` imports disko module + `./disko.nix`
- [ ] `hardware-configuration.nix` placeholder `fileSystems`/`swapDevices` removed
- [ ] `flake.nix` has the `disko` input
- [ ] `just check-all` green
- [ ] `plans/README.md` status row for 003 updated
