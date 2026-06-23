# Plan 002: Remove stale `awww` references and fix the dagobah platform label

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat fb7d1bc..HEAD -- README.md docs/FEATURES.md docs/ARCHITECTURE.md`
> `docs/ARCHITECTURE.md` was already modified in the working tree at planning
> time — re-read line 93 before editing it (see Step 4). On any mismatch with
> the excerpts below, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: docs
- **Planned at**: commit `fb7d1bc`, 2026-06-23

## Why this matters

The docs advertise an `awww` Wayland wallpaper daemon as a flake input and
desktop feature, but `awww` exists nowhere in the actual configuration — not in
`flake.nix`, `flake.lock`, or any `.nix` file. Wallpaper is now handled by
**Noctalia** (the curated `walls` collection is symlinked for Noctalia to
consume in `modules/home-manager/misc/wallpaper/default.nix:15-16`). Separately,
`README.md` calls the `dagobah` host an "Intel Mac" when it is Apple Silicon
(`aarch64-darwin`, per `CLAUDE.md:12` and `flake.nix:157`). Stale setup/feature
docs are worse than missing ones — they mislead anyone reading the repo. These
are pure text fixes.

## Current state

Confirmed at commit `fb7d1bc`: `grep -rin awww` matches only docs (never `.nix`):

- `README.md:64` — flake-inputs table row:
  `| **awww** | Wayland wallpaper daemon |`
- `README.md:78` — Highlights bullet:
  `- **awww** wallpaper daemon with curated wallpaper collection`
  (The line above it, `README.md:77`, already credits Noctalia with the
  "wallpaper engine"; the `walls` collection is still listed at `README.md:71`.)
- `README.md:20` — repo-structure comment:
  `│   └── dagobah/        # Intel Mac (nix-darwin)`
- `docs/FEATURES.md:29` — Tools & Utilities bullet:
  `- **awww**: Wayland wallpaper daemon with smooth transitions`
- `docs/ARCHITECTURE.md:93` — desktop/hyprland services list:
  `… desktop services (noctalia, awww, cliphist, hypridle) …`

Ground truth for the corrected wording:
- `flake.nix:157` — `"daniel@dagobah" = mkHomeConfiguration "aarch64-darwin" …`
  → Apple Silicon.
- `CLAUDE.md:12` — `| `dagobah` | macOS (nix-darwin) | Apple Silicon MacBook Pro |`.

## Commands you will need

| Purpose             | Command                                          | Expected on success      |
|---------------------|--------------------------------------------------|--------------------------|
| Find awww refs      | `grep -rin awww README.md docs/`                 | (after fix) no output    |
| Find Intel label    | `grep -n "Intel Mac" README.md`                  | (after fix) no output    |
| Confirm awww absent | `grep -rin awww --include=*.nix --include=*.lock .` | no output (already true) |

## Scope

**In scope** (the only files you should modify):
- `README.md`
- `docs/FEATURES.md`
- `docs/ARCHITECTURE.md`

**Out of scope** (do NOT touch):
- Any `.nix` file — `awww` is already absent from the actual config; there is
  nothing to remove in code.
- `README.md:71` and the `walls` input — the curated wallpaper collection still
  exists and is still wired up; keep it.
- Other working-tree edits already present in `docs/ARCHITECTURE.md` — change
  only line 93's services list, nothing else in that file.

## Git workflow

- Branch: `advisor/002-fix-doc-drift` (or whatever the operator directs).
- Commit style: short imperative, matching repo log. Suggested:
  `docs: drop stale awww refs, fix dagobah platform`.
- Do NOT push or open a PR unless instructed.

## Steps

### Step 1: Fix the dagobah platform label in `README.md`

Change `README.md:20` from `# Intel Mac (nix-darwin)` to
`# Apple Silicon Mac (nix-darwin)`. Keep the box-drawing alignment intact.

**Verify**: `grep -n "Intel Mac" README.md` → no output.

### Step 2: Remove the `awww` flake-input row in `README.md`

Delete the entire table row at `README.md:64`
(`| **awww** | Wayland wallpaper daemon |`). Leave the surrounding rows
(noctalia at 63, walls at 71) untouched.

### Step 3: Remove the `awww` Highlights bullet in `README.md`

Delete the bullet at `README.md:78`
(`- **awww** wallpaper daemon with curated wallpaper collection`). The Noctalia
bullet at line 77 already covers the wallpaper engine, so no replacement text is
needed.

**Verify (Steps 2–3)**: `grep -in awww README.md` → no output.

### Step 4: Remove `awww` from `docs/FEATURES.md` and `docs/ARCHITECTURE.md`

- `docs/FEATURES.md:29` — delete the bullet
  `- **awww**: Wayland wallpaper daemon with smooth transitions`.
- `docs/ARCHITECTURE.md:93` — **re-read this line first** (the file had
  uncommitted edits at planning time). In the services list, change
  `(noctalia, awww, cliphist, hypridle)` to `(noctalia, cliphist, hypridle)`
  (remove `awww, `). If the line no longer contains `awww`, skip it and note
  that in your report — do not edit anything else in this file.

**Verify**: `grep -rin awww README.md docs/` → no output.

## Test plan

No code, no tests. Verification is the grep gate in Done criteria.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `grep -rin awww README.md docs/` → no output
- [ ] `grep -n "Intel Mac" README.md` → no output
- [ ] `grep -rin awww --include=*.nix --include=*.lock .` → no output (unchanged)
- [ ] Only `README.md`, `docs/FEATURES.md`, `docs/ARCHITECTURE.md` modified
      (`git status`); `walls` references intact
- [ ] `plans/README.md` status row for plan 002 updated

## STOP conditions

Stop and report back if:

- `docs/ARCHITECTURE.md:93` no longer matches the excerpt and you can't locate
  the `awww` token in the services list (someone already edited it).
- Removing a line would break Markdown table structure (column count mismatch)
  — report rather than guess.
- `grep` finds `awww` in a `.nix` file (the config changed since planning — the
  premise "awww is gone from code" no longer holds).

## Maintenance notes

- If `awww` (or any wallpaper daemon) is ever reintroduced, these doc surfaces
  (README inputs table, README highlights, FEATURES, ARCHITECTURE services list)
  are the four places to update.
- A reviewer only needs to confirm: no `awww` left in docs, `walls`/Noctalia
  wallpaper wording intact, dagobah labeled Apple Silicon.
