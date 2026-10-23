# Pin `--node-ip` on every k3s node instead of relying on auto-detection

k3s (and the flannel CNI it embeds) by default auto-detects each node's
advertised IP from the default route. On naboo and endor, kube-vip's floating
API VIP (`10.10.40.5`) shares the same NIC as the node's real LAN IP —
flannel's auto-detection can pick the VIP instead of the real address for its
`flannel.alpha.coreos.com/public-ip` node annotation. This corrupted the VXLAN
FDB entries on the *other* nodes after naboo's k3s restarted (2026-07-04):
endor and tatooine kept forwarding pod traffic bound for naboo to the wrong
destination IP, silently breaking cross-node pod networking to anything
scheduled on naboo — discovered via homepage/dex-server pods landing there
and becoming unreachable from Traefik (on endor).

Decided: set `homelab.k3s.nodeIp` (→ k3s's `--node-ip` flag) explicitly per
host to each node's real static IP (naboo `.13`, endor `.14`, tatooine `.15`),
removing the auto-detection ambiguity at the source. This is the officially
documented k3s mechanism for this exact class of problem (confirmed via
k3s GitHub issues/docs research, 2026-07-04) — `--flannel-iface` was
considered but has inconsistent reported reliability for this failure mode,
so left unset.

## Update 2026-10-23: --node-ip was not sufficient

After the flake update to k3s 1.36.5, naboo rebooted while it held the VIP.
Its flannel `public-ip` annotation became `10.10.40.5` again, although
`--node-ip=10.10.40.13` was set. Cross-node traffic to naboo pods failed
until a k3s restart on naboo with the VIP on another node.

Decided: also set `--node-external-ip` to the same real IP on every node,
and `--flannel-external-ip` on all servers. Flannel then uses the given
external IP as the VXLAN destination, without detection.
