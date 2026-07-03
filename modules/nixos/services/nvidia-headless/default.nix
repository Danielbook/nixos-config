# Headless NVIDIA GPU for a k3s agent node (tatooine, GTX 1070/Pascal).
#
# Not modules/nixos/graphics: that module is coruscant's desktop/PRIME-sync
# setup (Xorg driver, GBM env vars, dual-GPU sync) — none of it applies to a
# headless worker. `open = false` because Pascal predates NVIDIA's open kernel
# modules (Turing+ only).
#
# k3s bundles its own containerd, separate from the system one, so
# `hardware.nvidia-container-toolkit.enable` alone isn't enough — the toolkit
# generates a CDI spec and the runtime binary, but k3s' containerd needs its
# own config pointed at the "nvidia" runtime via a config.toml.tmpl override
# (the documented k3s+NVIDIA pattern). k3s reads that template if present at
# /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl and merges it
# with `{{ template "base" . }}`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  nvidiaContainerRuntime =
    "${lib.getOutput "tools" config.hardware.nvidia-container-toolkit.package}/bin/nvidia-container-runtime";

  containerdConfigTemplate = pkgs.writeText "k3s-containerd-config.toml.tmpl" ''
    {{ template "base" . }}

    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
      runtime_type = "io.containerd.runc.v2"

    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
      BinaryName = "${nvidiaContainerRuntime}"
  '';
in
{
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # legacy_580, not stable: 595+ dropped Pascal — 580 is the last branch
    # supporting the GTX 1070 (boot dmesg NVRM message says so explicitly).
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;
    modesetting.enable = true;
    nvidiaSettings = false;
  };

  hardware.nvidia-container-toolkit.enable = true;

  # k3s' bundled containerd doesn't read /etc — materialize the override at
  # the path it actually looks for, into the k3s agent's runtime state dir.
  systemd.tmpfiles.rules = [
    "L+ /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl - - - - ${containerdConfigTemplate}"
  ];
}
