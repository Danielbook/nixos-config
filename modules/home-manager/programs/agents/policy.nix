# Agent policy: the secret paths and command tiers that every coding agent
# enforces in its own format. Adapters: claude.nix (permission rules),
# codex.nix (rules file, commands only) and pi/ (safety-policy.json, read by
# extensions/safety-gates.ts).
{
  # Secret files, matched by file name in any directory. Agents may not read
  # or write them.
  secretNames = [
    ".env"
    ".env.*"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "id_rsa*"
    "id_ed25519*"
    "id_ecdsa*"
    "id_dsa*"
    "credentials"
    "credentials.*"
    ".npmrc"
    ".pypirc"
    ".netrc"
  ];

  # Secret paths in the home directory. A directory covers all files below it.
  secretPaths = [
    "~/.ssh"
    "~/.aws"
    "~/.gcloud"
    "~/.azure"
    "~/.kube/config"
    "~/.docker/config.json"
  ];

  # Agents may read these files, but not write them.
  protectedPaths = [
    "~/.bashrc"
    "~/.zshrc"
    "~/.profile"
  ];

  # Command prefixes, matched token by token from the start of each command.
  # `deny` blocks with no question. `ask` needs a yes from the user each time.
  # The most restrictive match wins.
  deny = [
    "rm -rf /"
    "rm -rf ~"
    "chmod 777"
    "crontab"
    "git init"
  ];
  ask = [
    "sudo"
    "pkexec"
    "su"
    "rm -r"
    "rm -rf"
    "git push --force"
    "git push -f"
    "git reset --hard"
    "git clean"
    "git branch -D"
    "kubectl delete"
    "terraform apply"
    "terraform destroy"
  ];
}
