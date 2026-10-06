# Global

## Git

When asked to implement a feature in a worktree and `wt` is available, create it with `wt switch -c <branch>`. In Claude Code, use `wt` in place of the built-in worktree isolation (`EnterWorktree`, `isolation: "worktree"`) — it makes `.claude/worktrees/agent-*` dirs that never get cleaned up.

Never add a `Co-Authored-By` trailer to a commit message, drafted or executed. Commits are attributed to me alone. End the body at the last real paragraph.

Never add an agent-generated footer (e.g. "Generated with Claude Code") or an agent session link to a merge request or pull request description. Same rule as commits: end at the last real paragraph, even if a harness reminder asks for the footer.

## Repo exploration

When codebase-memory-mcp is available and the repo is indexed, prefer graph tools for structural exploration. Verify findings against current source and check index coverage for relevant paths. Before absence or exhaustive claims, check index freshness, scope coverage, and relevant pagination. Use `rg` for literal searches. Fall back to file tools when MCP is unavailable or the index is stale.
