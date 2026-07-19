# tatooine: convert Proxmox VM to bare metal, not in-place VM reinstall

Status: accepted

tatooine (the GPU media node, GTX 1070) currently runs as a Proxmox VM with the
GPU PCI-passed-through — reinstalling just the guest OS via `nixos-anywhere`
would have kept the hypervisor layer, passthrough config, and Proxmox-side
snapshotting intact, and was the lower-risk, faster option. We chose instead to
wipe the Proxmox host entirely and install NixOS directly on the hardware.
Confirmed first that the box is single-purpose (VMID 100/tatooine is the only
guest on `10.10.30.12`), so no other workload is put at risk by taking the
hypervisor down. Bare metal also drops the PCI-passthrough (vfio-pci/hostpci)
config entirely — the GPU is used natively, one less moving part long-term.

## Considered and rejected

- **In-place VM OS reinstall** (`nixos-anywhere` targeting the existing VM,
  Proxmox/passthrough untouched): lower risk, no need to re-verify the
  hypervisor's disk layout or the physical box's provisioning method. Rejected
  in favor of removing the hypervisor layer this node no longer needs.

## Consequences

- No Proxmox snapshot/rollback safety net for tatooine once wiped — this is a
  one-way door for this node.
- `disko.nix` targets the physical NVMe (`/dev/nvme0n1`, 476.9G) directly,
  confirmed via SSH to the Proxmox host itself, not the guest's virtual disk.
- Node provisioning for tatooine needs physical/remote console access to the
  bare box (not just SSH to a running VM) for the initial `nixos-anywhere` run.
