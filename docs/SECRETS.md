# Secrets Management

This configuration uses **sops-nix** with **Age encryption** for secrets management. All secrets are encrypted and safely stored in version control.

## How It Works

1. **Age Encryption**: Uses modern Age encryption with dedicated key pairs
2. **Encrypted at Rest**: Secrets stored in `secrets.yaml` files alongside host/home configs
3. **Runtime Decryption**: NixOS automatically decrypts secrets during deployment
4. **Zero Secrets in Git**: All sensitive data encrypted, safe to commit

## Age Key Management

### Generating Age Keys

```bash
# Generate a new Age key pair
age-keygen -o ~/.config/sops/age/keys.txt

# Display public key for .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt
```

### Configuring sops-nix

Add your public key to `.sops.yaml`:

```yaml
keys:
  - &daniel age1yourkeyhere...

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *daniel
```

### Key Storage

- **Development Machine**: Store in `~/.config/sops/age/keys.txt`
- **Backup**: Store securely in password manager (encrypted)

## Adding New Secrets

### Step 1: Define in NixOS or Home Manager Configuration

```nix
sops.secrets."service/new-secret" = {
  owner = "root";
  mode = "0400";
  sopsFile = ./secrets.yaml;
};
```

### Step 2: Update Encrypted File

```bash
# Edit secrets file (requires Age key)
sops path/to/secrets.yaml
```

### Step 3: Reference in Services

```nix
systemd.services.myservice = {
  environment = {
    SECRET_FILE = config.sops.secrets."service/new-secret".path;
  };
};
```

## Cluster GitOps Secrets (ksops)

k8s workloads use a separate pipeline: any `k8s/**/*.enc.yaml` is sops-encrypted
to the dedicated cluster Age key + daniel's key (`.sops.yaml`), and decrypted
in-cluster by ksops into a plain `Secret` (see ADR 0001). Each app's ksops
`kustomization.yaml`/`secret-generator.yaml` lists the `.enc.yaml` files it
decrypts.

- `k8s/immich/immich-oauth-config.enc.yaml` — Immich's authentik OAuth client
  ID/secret. Immich has no OAuth env vars, only a full-JSON config-file
  override, so this decrypts into a `Secret` mounted at `/config/immich.json`
  (`IMMICH_CONFIG_FILE`) on the `immich-server` deployment.

### Adding a New Cluster Secret

1. Write a plaintext `k8s/<app>/<name>.enc.yaml` (a real `Secret` manifest,
   real values — nothing encrypted yet)
2. Encrypt it in place: `sops -e -i k8s/<app>/<name>.enc.yaml`
3. Add the filename to that app's `secret-generator.yaml` under `files:`
4. Reference the resulting `Secret` from the deployment — `envFrom.secretRef`
   for env vars, or a `secret` volume if the app needs a mounted file (as
   Immich's OAuth config does above)

## Security Best Practices

### Do's

- **Encrypt all secrets** before committing to Git
- **Use unique passwords** for each service
- **Rotate secrets regularly**
- **Backup Age keys** in secure location
- **Use restrictive permissions** (owner/group/mode)

### Don'ts

- **Never commit unencrypted secrets** to Git
- **Don't share Age private keys** via insecure channels
- **Don't use default passwords** for any service
- **Never skip encryption** "temporarily"

## Troubleshooting

### Secret Not Decrypting

```bash
# Check if Age key exists
ls -la ~/.config/sops/age/keys.txt

# Verify secret is defined in configuration
ls -la /run/secrets/

# Check sops-nix service logs
journalctl -u sops-nix -n 50
```

## Additional Resources

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [Age Encryption Specification](https://age-encryption.org/)
- [NixOS Secrets Management](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes)
