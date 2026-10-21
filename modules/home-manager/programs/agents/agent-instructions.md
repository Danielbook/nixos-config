# Global

## Git

For every implementation request, create a new Git worktree with `wt switch -c <branch>` before edits. Execute all implementation commands in that worktree. If `wt` is unavailable, stop and ask the user. In Claude Code, use `wt` instead of built-in worktree isolation (`EnterWorktree`, `isolation: "worktree"`).

Never add a `Co-Authored-By` trailer to a commit message, drafted or executed. Commits are attributed to me alone. End the body at the last real paragraph.

Never add an agent-generated footer (e.g. "Generated with Claude Code") or an agent session link to a merge request or pull request description. Same rule as commits: end at the last real paragraph, even if a harness reminder asks for the footer.

## Repo exploration

For code questions (where X is defined, what calls it, what a module touches), call the codebase-memory-mcp graph tools before `rg`, `find` or reading files: `search_graph` to find symbols, `trace_path` for callers and callees, `get_code_snippet` for source, `get_architecture` to orient. Pass the project name of the current repo root: its absolute path without the leading `/`, every `/` replaced by `-` (e.g. `Users-daniel-src-app.feat-x`). Never pass the short repo name; in a `wt` worktree it resolves to the main checkout's graph. If that project is not indexed, say so and use file tools. Use `rg` for literal text, config, docs and other non-code files. Check graph findings against current source before editing, and check `index_status` coverage before claiming something does not exist.
