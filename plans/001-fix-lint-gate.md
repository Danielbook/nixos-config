# Plan 001: Make `just check-all` pass (green lint gate)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat fb7d1bc..HEAD -- modules/ overlays/ flake.nix`
> If any in-scope file (listed under Scope) changed since this plan was
> written, compare the "Current state" excerpts against the live code before
> proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx
- **Planned at**: commit `fb7d1bc`, 2026-06-23

## Why this matters

The repo ships a `just check-all` quality gate (`format-check` + `lint` +
`flake-check`), and `just lint` runs `deadnix --fail` and `statix check`.
Right now **both exit non-zero**, so the gate is red: nobody can trust a
"clean" result before committing, and CI (if added later — see plan 003 if
present) would fail immediately. The failures are entirely mechanical style
issues, not logic bugs. Making the gate green restores its value as a
pre-commit signal at near-zero risk.

## Current state

`just lint` (from `justfile`) runs:

```
nix run nixpkgs#deadnix -- --fail .
nix run nixpkgs#statix -- check .
```

Both currently exit 1. The failures break down into exactly **three** lint
categories plus one deadnix finding — verified by running statix at commit
`fb7d1bc`:

1. **`deadnix` — 1 unused lambda argument.** `modules/home-manager/programs/ssh/default.nix:3`:
   ```nix
   {
     config,
     userConfig,   # <-- unused; never referenced in the module body
     ...
   }: let
   ```

2. **statix `W10 empty_pattern` — 17 files.** Each starts with `{...}:` where
   statix wants `_:` (the module ignores all args). The files:
   ```
   modules/home-manager/programs/fastfetch/default.nix
   modules/home-manager/programs/btop/default.nix
   modules/home-manager/services/hypridle/default.nix
   overlays/default.nix
   modules/home-manager/programs/atuin/default.nix
   modules/nixos/services/audio-lowlatency/default.nix
   modules/home-manager/programs/yazi/default.nix
   modules/home-manager/programs/direnv/default.nix
   modules/nixos/memory-protection/default.nix
   modules/home-manager/scripts/default.nix
   modules/home-manager/programs/lazygit/default.nix
   modules/home-manager/programs/fzf/default.nix
   modules/home-manager/programs/vscode/default.nix
   modules/home-manager/programs/bat/default.nix
   modules/home-manager/programs/alacritty/default.nix
   modules/home-manager/scripts/desktop/default.nix
   modules/nixos/services/tlp/default.nix
   ```

3. **statix `W04 manual_inherit_from` — 2 files.** An attribute assigned from a
   same-named field can use `inherit (x) field;`. Sites:
   - `modules/home-manager/programs/git/default.nix:33` — inside `settings.user`,
     `email = userConfig.email;` (the `name = userConfig.fullName;` line stays —
     names differ, no inherit possible).
   - `modules/home-manager/programs/jujutsu/default.nix:13` — same shape inside
     `settings.user`.

4. **statix `W20 repeated_keys` — 15 sites.** e.g.
   `modules/home-manager/programs/aerospace/default.nix:26` (`outer.left`,
   `outer.right`, `outer.top`). **This is the idiomatic flat `a.b = …; a.c = …;`
   Nix style and we are deliberately keeping it** — the fix for this plan is to
   **disable the `repeated_keys` lint**, not rewrite the code. (Decision made by
   the maintainer during planning.)

There is no statix config file yet (`statix.toml` does not exist). statix reads
`./statix.toml` automatically (its default `--config .`). Sample format
(`statix dump`):

```toml
disabled = []
ignore = [".direnv"]
```

Convention note: Nix files are formatted with `nixfmt` via `nix fmt` / `just format`.
Run the formatter after any automated rewrite so the diff stays consistent
with the rest of the repo.

## Commands you will need

| Purpose            | Command                                      | Expected on success |
|--------------------|----------------------------------------------|---------------------|
| Working-tree state | `git status --porcelain`                     | empty (see Step 0)  |
| Lint               | `just lint`                                   | exit 0, no warnings |
| statix fix (auto)  | `nix run nixpkgs#statix -- fix .`             | exit 0, edits files |
| statix dry-run     | `nix run nixpkgs#statix -- fix --dry-run .`   | shows diff only     |
| deadnix fix (auto) | `nix run nixpkgs#deadnix -- --edit .`         | exit 0, edits files |
| Format             | `just format`                                 | exit 0              |
| Format check       | `nix fmt -- --check .`                         | exit 0              |
| Flake eval check   | `just flake-check`                            | exit 0              |

## Scope

**In scope** (the only files you should modify):
- `statix.toml` (create at repo root)
- The 17 `empty_pattern` files listed in Current state §2
- `modules/home-manager/programs/git/default.nix`
- `modules/home-manager/programs/jujutsu/default.nix`
- `modules/home-manager/programs/ssh/default.nix`

**Out of scope** (do NOT touch):
- The 15 `repeated_keys` sites (e.g. `aerospace/default.nix:26`) — disabled via
  `statix.toml`, code unchanged. Do **not** rewrite them into nested attrsets.
- Any file not flagged by statix/deadnix. If `statix fix` or `deadnix --edit`
  proposes a change to a file outside the in-scope list, that's a STOP condition.
- `justfile` — the lint recipe stays as-is; it picks up `statix.toml` automatically.

## Git workflow

- Branch: `advisor/001-fix-lint-gate` (or whatever the operator directs).
- Commit style matches the repo: short, imperative, no conventional-commit
  prefix (recent log: `fix for using ssh over https`, `Aerospace`). Suggested
  message: `fix lint warnings, disable repeated_keys`.
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 0: Ensure a clean working tree

This plan runs automated bulk rewrites; mixing them with unrelated in-progress
edits makes the diff unreviewable. If running in a fresh worktree off `fb7d1bc`
this is already satisfied.

**Verify**: `git status --porcelain` → **empty output**.
If it is NOT empty: **STOP and report** — the operator must commit or stash
their working-tree changes first (do not stash them yourself).

### Step 1: Disable the `repeated_keys` lint

Create `statix.toml` at the repo root with exactly:

```toml
disabled = ["repeated_keys"]
ignore = [".direnv"]
```

**Verify**: `nix run nixpkgs#statix -- check . 2>&1 | grep -c "repeated keys"` → `0`

### Step 2: Auto-fix the remaining statix lints

With `repeated_keys` now disabled, the only fixable lints left are
`empty_pattern` (17 files) and `manual_inherit_from` (2 files). Preview first,
then apply:

```
nix run nixpkgs#statix -- fix --dry-run .   # inspect: should only touch the 19 in-scope files
nix run nixpkgs#statix -- fix .
```

Confirm the dry-run diff only changes `{...}:` → `_:` and `email = userConfig.email;`
→ `inherit (userConfig) email;` (and the jujutsu equivalent). If it proposes
anything else, STOP.

**Verify**: `nix run nixpkgs#statix -- check .` → exit 0, no warnings.

### Step 3: Remove the unused `userConfig` argument

In `modules/home-manager/programs/ssh/default.nix`, drop the unused `userConfig,`
line from the lambda pattern (leaving `config` and `...`). Either run
`nix run nixpkgs#deadnix -- --edit .` (it edits only flagged sites) or hand-edit.

**Verify**: `nix run nixpkgs#deadnix -- --fail .` → exit 0.

### Step 4: Re-format

The automated rewrites may not match `nixfmt` spacing.

```
just format
```

**Verify**: `nix fmt -- --check .` → exit 0.

### Step 5: Confirm the config still evaluates

The fixes are syntactic, but confirm nothing broke evaluation.

**Verify**: `just flake-check` → exit 0.

## Test plan

This repo has no unit tests; verification is the lint + eval gate itself:
- `just lint` → exit 0 (was exit 1).
- `just flake-check` → exit 0 (unchanged — proves no eval regression).
- `nix fmt -- --check .` → exit 0.

No new test files. The done-criteria commands below are the regression check.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `statix.toml` exists with `disabled = ["repeated_keys"]`
- [ ] `just lint` exits 0
- [ ] `nix fmt -- --check .` exits 0
- [ ] `just flake-check` exits 0
- [ ] `nix run nixpkgs#statix -- check . 2>&1 | grep -c "repeated keys"` → `0`
- [ ] No file outside the Scope list is modified (`git status`); no `aerospace`
      / `hardware-configuration` / `*/common/default.nix` body changes from
      repeated-key rewrites
- [ ] `plans/README.md` status row for plan 001 updated

## STOP conditions

Stop and report back (do not improvise) if:

- `git status --porcelain` is non-empty at Step 0 (dirty working tree).
- `statix fix --dry-run` proposes changes to any file not in the Scope list, or
  any change other than `{...}:`→`_:` and `… = userConfig.email;`→`inherit …`.
- `just flake-check` fails after the fixes (an edit broke evaluation).
- Any verification fails twice after a reasonable fix attempt.
- The statix/deadnix versions resolved by `nix run` emit lint categories not
  described in "Current state" (the tool changed since planning).

## Maintenance notes

- `statix.toml` now governs which lints run. If a future maintainer wants the
  nested-attrset style after all, remove `"repeated_keys"` from `disabled` and
  run `statix fix` — but expect churn across ~7 files.
- A reviewer should confirm the diff is purely mechanical: pattern arg renames,
  two `inherit` rewrites, one removed arg, and the new `statix.toml`. Any logic
  change is out of scope and a red flag.
- Follow-on (separate plan): wire `just check-all` into CI or a pre-commit hook
  so the gate can't silently go red again.
