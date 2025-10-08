# Claude Code Instructions

## Build Commands
- **Always use `just nixos-rebuild` instead of `sudo nixos-rebuild switch`**
- **Always use `just home-manager-switch` instead of `home-manager switch`**

These just targets provide consistent build behavior and proper error handling.

## Commit Guidelines
- **Never add Claude co-authoring** to commit messages
- **No "Co-Authored-By: Claude" lines** in commits
- **No "Generated with Claude Code" references** in commit messages
- All commits should show only Daniel as the author