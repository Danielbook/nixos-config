# 0001 — Dedicated age key for in-cluster (ksops/Argo) secret decryption

- **Status:** Accepted
- **Date:** 2026-06-24
- **Context:** k3s cluster migration (see `docs/cluster-implementation.md`)

## Context

Workloads are managed by Argo CD (GitOps) with secrets encrypted via SOPS +
age, decrypted in-cluster by **ksops**. For Argo to decrypt, the age **private
key must live inside the cluster** (a k8s Secret in the argocd namespace).

The existing `daniel` age key (in `.sops.yaml`, sourced from Bitwarden) decrypts
**everything** in this repo, including NixOS host/system secrets. Placing that
key inside the cluster would mean a cluster compromise leaks the master key that
unlocks all other secrets.

There is also an unavoidable bootstrap ordering issue: the key that lets Argo
decrypt cannot itself be delivered by Argo.

## Decision

Use a **dedicated cluster age key**, separate from the personal `daniel` key.

- `k8s/**` sops files are encrypted to **two** recipients: the **cluster key**
  (so Argo/ksops can decrypt) **and** the **`daniel` key** (recovery / break-glass).
- Only the **cluster key** is ever installed inside the cluster.
- The personal `daniel` master key **never enters the cluster**.
- The cluster key's private half is stored in Bitwarden alongside the other age
  keys, and is **`kubectl`-loaded once, out of band**, into the argocd namespace
  during cluster bootstrap (Stage B5) — before Argo syncs any encrypted manifest.
- `.sops.yaml` gets a creation_rule scoped to `k8s/**` listing both recipients.

## Consequences

- **Least privilege:** a cluster compromise exposes only cluster-app secrets,
  not the master key for NixOS host secrets and everything else.
- **Independent rotation:** the cluster key can be rotated/revoked without
  touching the personal key (re-encrypt `k8s/**`, reload the in-cluster secret).
- **Recovery preserved:** `daniel` can still decrypt every `k8s/**` file directly.
- **Cost:** one more key to manage, and a documented manual bootstrap step
  (the chicken-and-egg seed) that isn't itself GitOps-managed.
