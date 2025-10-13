# 🔐 Secrets Management

This configuration uses **sops-nix** with **Age encryption** for enterprise-grade secrets management. All secrets are encrypted and safely stored in version control.

## 🔑 How It Works

1. **Age Encryption**: Uses modern Age encryption with dedicated key pairs
2. **Encrypted at Rest**: All secrets encrypted in `hosts/kamino/secrets.yaml`
3. **Runtime Decryption**: NixOS automatically decrypts secrets during deployment
4. **Bitwarden Integration**: Automated secret deployment with CLI integration
5. **Zero Secrets in Git**: All sensitive data encrypted, safe to commit

## 🚀 Secret Deployment Process

### Automated Deployment (Recommended)

```bash
# Full deployment with automated secret setup
just deploy-kamino
```

This command will:
- Check Bitwarden CLI availability
- Deploy NixOS configuration
- Set up Age encryption keys
- Deploy all secrets from Bitwarden
- Start all services automatically

### Manual Secret Setup

If Bitwarden CLI is unavailable or you prefer manual setup:

```bash
# Set up Age keys and prepare for manual secret entry
just setup-kamino-secrets

# Check Bitwarden CLI status
just check-bw
```

## 📋 Secret Categories

### 🏠 Home Assistant
- API keys and access tokens
- OAuth client secrets
- Integration credentials
- Webhook URLs
- MQTT passwords

### 📊 Monitoring & Logging
- Grafana admin password
- InfluxDB tokens and credentials
- Loki authentication
- Prometheus scrape credentials

### 🔗 Networking & Proxy
- Cloudflare API tokens
- Traefik dashboard credentials
- SSL certificate keys
- Dynamic DNS tokens

### 🌐 ESPHome & IoT
- Device API keys
- OTA (Over-The-Air) update passwords
- WiFi credentials
- MQTT device credentials

### 📡 Additional Services
- UniFi Controller password
- Docker registry tokens
- Backup encryption keys
- SSH keys and certificates

## 🔧 Adding New Secrets

### Step 1: Define in NixOS Configuration

Add the secret definition to your host configuration:

```nix
# hosts/kamino/default.nix
sops.secrets."kamino/service/new-secret" = {
  owner = "root";
  group = "docker";
  mode = "0440";
  sopsFile = ./secrets.yaml;
};
```

### Step 2: Store in Bitwarden

Add the secret to your Bitwarden vault:

```bash
# Using Bitwarden CLI
bw get item "Kamino Secrets"

# Or add via web interface
# Item: Kamino Secrets
# Field: kamino/service/new-secret
# Value: your_secret_value
```

### Step 3: Update Encrypted File

```bash
# Edit secrets file (requires Age key)
sops hosts/kamino/secrets.yaml

# Or deploy automatically (pulls from Bitwarden)
just deploy-kamino
```

### Step 4: Reference in Services

Use the secret in your Docker Compose or systemd services:

```yaml
# docker-compose.yaml
services:
  myservice:
    environment:
      - SECRET_FILE=/run/secrets/kamino-service-new-secret
    volumes:
      - /run/secrets/kamino-service-new-secret:/run/secrets/kamino-service-new-secret:ro
```

```nix
# Or in a systemd service
systemd.services.myservice = {
  environment = {
    SECRET_FILE = config.sops.secrets."kamino/service/new-secret".path;
  };
};
```

## 🔑 Age Key Management

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
  - &admin_daniel age1yourkeyhere...

creation_rules:
  - path_regex: hosts/kamino/secrets\.yaml$
    key_groups:
      - age:
          - *admin_daniel
```

### Key Distribution

- **Development Machine**: Store in `~/.config/sops/age/keys.txt`
- **Server**: Deployed automatically during `nixos-anywhere` deployment
- **Backup**: Store securely in password manager (encrypted)

## 🛡️ Security Best Practices

### ✅ Do's

- **Encrypt all secrets** before committing to Git
- **Use unique passwords** for each service
- **Rotate secrets regularly** (quarterly recommended)
- **Backup Age keys** in secure location (Bitwarden, encrypted USB)
- **Use restrictive permissions** (owner/group/mode)
- **Audit secret access** regularly

### ❌ Don'ts

- **Never commit unencrypted secrets** to Git
- **Don't share Age private keys** via insecure channels
- **Avoid storing secrets** in configuration files
- **Don't use default passwords** for any service
- **Never skip encryption** "temporarily"

## 🔍 Troubleshooting

### Secret Not Decrypting

```bash
# Check if Age key exists on server
ssh kamino "ls -la /var/lib/sops-nix/key.txt"

# Verify secret is defined in configuration
ssh kamino "ls -la /run/secrets/"

# Check sops-nix service logs
ssh kamino "journalctl -u sops-nix -n 50"
```

### Bitwarden CLI Issues

```bash
# Check Bitwarden CLI status
just check-bw

# Verify login status
bw status

# Re-login if needed
bw login

# Unlock vault
bw unlock
```

### Permission Denied Errors

```bash
# Check secret file permissions
ssh kamino "ls -la /run/secrets/kamino-*"

# Verify owner and group match service requirements
# Fix in configuration if needed:
sops.secrets."kamino/service/secret" = {
  owner = "correct-user";
  group = "correct-group";
  mode = "0440";
};
```

### Secrets Not Updating

```bash
# Force NixOS rebuild
just deploy-kamino

# Or manually rebuild on server
ssh kamino "nixos-rebuild switch"

# Restart affected services
ssh kamino "systemctl restart docker-compose@homeassistant-stack"
```

## 📚 Additional Resources

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [Age Encryption Specification](https://age-encryption.org/)
- [Bitwarden CLI Guide](https://bitwarden.com/help/cli/)
- [NixOS Secrets Management](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes)

## 🎯 Quick Reference

```bash
# Check Bitwarden status
just check-bw

# Deploy with automated secrets
just deploy-kamino

# Manual secret setup
just setup-kamino-secrets

# Edit encrypted secrets file
sops hosts/kamino/secrets.yaml

# View secret without decrypting file
ssh kamino "cat /run/secrets/kamino-service-name"

# List all secrets
ssh kamino "ls -la /run/secrets/"

# Restart service after secret update
ssh kamino "systemctl restart service-name"
```
