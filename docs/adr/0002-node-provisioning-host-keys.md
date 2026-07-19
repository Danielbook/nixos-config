# Node provisioning: pre-generated host keys + portable admin identity

Headless cluster nodes are installed with `nixos-anywhere` + `disko`. Two
decisions came out of bootstrapping `naboo`, both aimed at making nodes
**reproducible and never self-locking**:

1. **Each node's SSH host key is pre-generated on the admin machine, committed
   sops-encrypted in the repo (`hosts/<node>/ssh_host_ed25519_key.sops`,
   encrypted to `daniel` only), and injected at install via
   `nixos-anywhere --extra-files`.** Because the host key's age recipient is
   known *before* install, sops-nix decrypts the node's secrets (e.g. the k3s
   token) on the **first** boot — and a wipe-and-reinstall reuses the same key,
   so sops keeps working. The node becomes reproducible from `git` + the master
   age key alone.

2. **The admin login key is a portable identity, not a machine's key.** A
   dedicated `k3s-cluster-admin` SSH key lives in Bitwarden (served by its SSH
   agent) and is declared in `modules/nixos/common` `authorizedKeys`, so every
   node authorizes it and any machine with Bitwarden unlocked can SSH in.
   Headless nodes have `PermitRootLogin=no` + `PasswordAuthentication=off`, so a
   declared `authorizedKeys` is the **only** way in — omitting it locks the node
   out entirely (which is exactly what happened on naboo's first install).

## Considered and rejected

- **Let the node generate its host key at install** (the default): forces a
  two-phase install (install → authorize the new key → re-key → rebuild) and
  **breaks sops on every reinstall**, since the key — and thus the recipient —
  changes. Rejected; it defeats the "disposable node" goal.
- **Store host keys in Bitwarden** like the admin key: works, but the node's
  identity then lives outside the repo and is manual to retrieve per reinstall.
  The repo (sops) keeps host identities version-controlled with the rest of the
  node config. Bitwarden is reserved for keys that must be *portable/interactive*
  (the admin login); the repo holds keys that are *infrastructure* (host
  identities).

## Consequences

- Adding a node = generate its host key into `--extra-files`, `ssh-to-age` →
  add `&<node>` to `.sops.yaml`, `sops -e -i` the key into the repo, `updatekeys`
  its secrets. See the Stage-B runbook in `docs/cluster-implementation.md`.
- The encrypted host *private* keys in the repo are recoverable by anyone with
  the `daniel` master key — acceptable in this single-admin homelab.
