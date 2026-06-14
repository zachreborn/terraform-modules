---
name: commit-standards
description: Guide for writing git commit messages and selecting a commit standard. Use this skill whenever the user asks how to format a commit message, what commit type to use, how to write a good commit, which commit convention to follow, how to set up commitlint or semantic-release, what Conventional Commits are, how commit messages relate to versioning, or asks about Angular/Gitmoji/Linux commit formats. Also trigger when the user is about to run `git commit` and seems uncertain about the message, when they ask "what type should this be?", or when they mention conventional commits, semantic versioning, or changelog generation.
---

# Commit Message Standards

**Default to Conventional Commits** unless the repo or user explicitly uses a different standard. It is the most widely adopted structured commit format, has the richest tooling ecosystem, and maps directly to Semantic Versioning.

---

## Conventional Commits (Primary Standard)

### Format

```
<type>[optional scope][!]: <short description>

[optional body]

[optional footer(s)]
```

**Rules for the subject line:**
- Use lowercase imperative mood: "add feature" not "added feature" or "adds feature"
- No period at the end
- Keep under 72 characters (50 is ideal for `git log --oneline` readability)
- The `!` suffix signals a breaking change (triggers a SemVer MAJOR bump)

### Type Reference

| Type | When to Use | SemVer Bump |
| --- | --- | --- |
| `feat` | A new user-facing feature | **MINOR** |
| `fix` | A bug fix | **PATCH** |
| `docs` | Documentation only (README, comments, guides) | none |
| `style` | Formatting, whitespace, missing semicolons — no logic change | none |
| `refactor` | Code restructure that neither fixes a bug nor adds a feature | none |
| `perf` | Performance improvement | none |
| `test` | Adding or correcting tests | none |
| `build` | Build system, dependency updates (npm, gradle, cargo) | none |
| `ci` | CI configuration (GitHub Actions, CircleCI, Dockerfile) | none |
| `chore` | Catch-all for maintenance tasks that don't fit elsewhere | none |
| `revert` | Reverts a previous commit | none |

> Only `feat`, `fix`, and `BREAKING CHANGE` affect SemVer. Everything else is informational.

### Breaking Changes

Two equivalent ways to signal a breaking change — pick one:

**Option A — `!` suffix (preferred for brevity):**
```
feat(api)!: rename user.email to user.primaryEmail
```

**Option B — `BREAKING CHANGE:` footer:**
```
feat(api): rename user.email to user.primaryEmail

BREAKING CHANGE: user.email has been renamed to user.primaryEmail.
Update all clients reading user.email to use user.primaryEmail instead.
```

Both trigger a MAJOR SemVer bump. Use both together when the description needs extra migration detail.

### Scope

An optional noun in parentheses narrowing the affected area: `fix(auth)`, `feat(dashboard)`, `build(deps)`. Keep scopes short and consistent across your team. Leave it out when the change spans the whole codebase or doesn't map cleanly to one component.

### Body and Footers

The body should explain **why**, not what — the diff already shows what changed. Use it when the motivation isn't obvious from the subject line.

```
fix(payments): prevent duplicate charge on network timeout

Previously, if the upstream payment processor timed out, we retried
the charge without checking for an existing pending transaction.
This caused some customers to be charged twice.

Add an idempotency key to all charge requests so the processor
deduplicates retries on its end.

Closes #1847
Reviewed-by: Jane Smith <jane@example.com>
```

**Footer trailers** (one per line after a blank line following the body):
- `Closes #123` — links and closes a GitHub/GitLab issue
- `Fixes #123` — same, but signals a bug fix specifically
- `Co-Authored-By: Name <email>` — credits a collaborator
- `Reviewed-by: Name <email>` — credits a reviewer
- `BREAKING CHANGE: <description>` — mandatory if using Option B above

### Examples

**Documentation update:**
```
docs(api): add request/response examples to authentication guide
```

**Bug fix:**
```
fix(auth): resolve token refresh race condition on concurrent requests

When two requests arrived simultaneously with an expired token, both
triggered a refresh. The second refresh failed because the token had
already been rotated by the first.

Add a mutex around the refresh call to serialize concurrent attempts.

Closes #392
```

**Feature (with breaking change):**
```
feat(dashboard)!: replace chart library with lightweight alternative

BREAKING CHANGE: ChartWidget now expects data in { labels, values }
shape instead of [{ label, value }]. Update all ChartWidget consumers
before upgrading.
```

---

## Body Writing Tips (Universal)

These apply regardless of which standard you use:

- **Imperative mood, present tense**: "Fix bug" not "Fixed bug" or "Fixes bug"
- **Explain why, not how**: The diff shows how; the message should explain the motivation
- **50/72 rule**: Subject ≤ 50 chars (hard limit: 72); body lines wrapped at 72 chars
- **Separate subject from body** with a blank line — many tools depend on this
- **Reference issues** in the footer, not the subject: `Closes #42`, not `fix login (closes #42)`
- **Keep commits atomic**: one logical change per commit. If you need two type labels, split the commit

---

## Tooling Setup

These tools assume Conventional Commits as the commit format:

### commitlint — enforce the standard at commit time

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
echo "export default { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
```

Add as a git hook via Husky:
```bash
npm install --save-dev husky
npx husky install
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
```

### commitizen — interactive commit prompt

```bash
npm install --save-dev commitizen cz-conventional-changelog
npx commitizen init cz-conventional-changelog --save-dev
```

Then use `git cz` instead of `git commit`.

### Release automation decision: semantic-release vs. release-please

| | semantic-release | release-please (Google) |
| --- | --- | --- |
| **Release trigger** | Every merge to `main` — fully automatic | Opens a "Release PR"; human merges it |
| **Human oversight** | None (by design) | Yes — review changelog before publishing |
| **Best for** | Libraries, packages needing zero-touch CI/CD | Web apps, teams wanting a release gate |
| **Stars** | 23K ★ | 7K ★ |

Both read Conventional Commits from git history to determine SemVer bump and generate `CHANGELOG.md`.

---

## Other Standards Reference

Use these sections if you encounter a codebase that doesn't use Conventional Commits.

### 1. Tim Pope / 50/72 Rule
Plain imperative prose — no type prefix, pure human readability. The baseline that predates structured standards.

```
Update README with installation prerequisites

Add a "Prerequisites" section listing Node 18+, npm 9+, and a
PostgreSQL 14+ instance. Clarifies setup issues reported by new
contributors (see issue #54).
```

```
Fix null pointer when user session expires during checkout
```

```
Add dark mode toggle to user preferences panel
```

**When you'll see it:** Linux kernel, OpenStack, older open source projects, teams that haven't adopted a structured standard.

### 2. Angular Commit Message Guidelines
The stricter ancestor of Conventional Commits. Same `type(scope): subject` format but: no `!` shorthand for breaking changes, body required for non-docs commits, header max 72 chars.

```
docs(router): clarify lazy-loading configuration in migration guide
```
```
fix(forms): prevent duplicate submit events on rapid double-click
```
```
feat(http): add retry interceptor with exponential backoff
```

**When you'll see it:** The Angular framework's own repository; projects using `@commitlint/config-angular`.

### 3. Gitmoji
Emoji-prefix visual categorization. Can be combined with Conventional Commits.

```
📝 update contributing guide with branch naming conventions
🐛 fix pagination breaking when total items equals page size
✨ add CSV export to the reports dashboard
```

Common emojis: `✨` feat · `🐛` fix · `📝` docs · `♻️` refactor · `🚀` deploy · `⚡️` perf · `🔒` security · `⬆️` dependency upgrade

**When you'll see it:** Individual developers and smaller teams; projects using `gitmoji-cli` or `devmoji`.

### 4. Linux Kernel Style
Detailed multi-paragraph messages with mandatory `Signed-off-by:` trailers. Optimized for email-based patch review.

```
net: tcp: fix use-after-free in tcp_v4_destroy_sock

When a socket is closed while a delayed ACK timer fires concurrently,
tcp_v4_destroy_sock may dereference sk_prot after the socket has been
freed, triggering a KASAN splat in production.

Move the timer cancellation before the memset to ensure the timer
cannot fire during teardown.

Fixes: a3f5c1d89e02 ("net: tcp: introduce delayed ACK coalescing")
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=217654
Signed-off-by: Jane Developer <jane@example.com>
Reviewed-by: John Maintainer <john@example.com>
```

**When you'll see it:** Linux kernel, device driver development, embedded systems, OpenStack (which adds `Change-Id:`, `Depends-On:`, `DocImpact:` trailers for Gerrit).
