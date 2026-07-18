# Issue tracker: Forgejo

Issues live on self-hosted Forgejo:
`https://forgejo.local.bookorjeman.com/danielbook/nixos-config` — the source of
truth. GitHub and Codeberg are push mirrors; never file issues there.

No CLI installed — use the Gitea-compatible REST API via curl.

## Auth

Token in `$FORGEJO_TOKEN`, sops-managed: stored in
`home/daniel/dagobah/secrets.yaml` (key `forgejo_api_token`) and exported by
zsh via home-manager. Created in Forgejo → Settings → Applications, issue
read/write scope. Every call: `-H "Authorization: token $FORGEJO_TOKEN"`.

Base URL: `API=https://forgejo.local.bookorjeman.com/api/v1/repos/danielbook/nixos-config`

## Conventions

- **Create an issue**: `curl -X POST $API/issues -H "Authorization: token $FORGEJO_TOKEN" -H 'Content-Type: application/json' -d '{"title":"...","body":"..."}'`
- **Read an issue**: `curl $API/issues/<n>`; comments: `curl $API/issues/<n>/comments`
- **List issues**: `curl "$API/issues?state=open&labels=<label>&type=issues"`
- **Comment**: `POST $API/issues/<n>/comments` with `{"body":"..."}`
- **Apply labels**: `PUT $API/issues/<n>/labels` with `{"labels":["name", ...]}`.
  A label must exist in the repo first — create with `POST $API/labels` and
  `{"name":"...","color":"#ededed"}`.
- **Close**: `PATCH $API/issues/<n>` with `{"state":"closed"}`

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

## When a skill says "publish to the issue tracker"

Create a Forgejo issue.

## When a skill says "fetch the relevant ticket"

`GET $API/issues/<n>` plus its comments.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: one issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: a plain issue with `Part of #<map>` at the top of its body
  and a task-list entry in the map body. Labels: `wayfinder:<type>`
  (`research`/`prototype`/`grilling`/`task`). Once claimed, assigned to the
  driving dev.
- **Blocking**: a `Blocked by: #<n>, #<n>` line at the top of the child body.
  Unblocked when every listed issue is closed.
- **Frontier query**: open children of the map without an open blocker or an
  assignee; first in map order wins.
- **Claim**: `PATCH $API/issues/<n>` with `{"assignees":["danielbook"]}` — the session's first write.
- **Resolve**: comment the answer, close the issue, append a context pointer to the map's Decisions-so-far.
