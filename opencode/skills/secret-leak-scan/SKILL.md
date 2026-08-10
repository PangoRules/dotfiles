---
name: secret-leak-scan
description: Use during code review on every diff — a cheap grep-pattern check for hardcoded credentials/keys/tokens newly introduced in the changed lines, so an obvious secret doesn't ship in a cycle where the full security-code-review skill wasn't separately invoked. Not a substitute for that skill's full audit — narrower, faster, runs every time.
---

Carter's `security-code-review` skill covers "Secrets exposure" as one category in a full on-demand audit — but Carter isn't invoked on every review cycle, so a hardcoded key can currently ship clean through a normal LGTM if nobody separately asked for a security pass. This skill is the cheap, always-on check that closes that gap: scoped to what the diff actually *added*, not a repo-wide sweep.

## Step 1 — Scan added lines only

```bash
git diff <base>..<head> -- . | grep -E '^\+' | grep -viE '^\+\+\+'
```

Grep that output (not the whole repo — added lines only, since a pre-existing secret elsewhere is a finding for a full Carter audit, not this diff's problem) for:

| Pattern | Signature |
|---|---|
| AWS access key | `AKIA[0-9A-Z]{16}` |
| Private key block | `-----BEGIN (RSA\|EC\|OPENSSH\|PGP)? ?PRIVATE KEY-----` |
| GitHub token | `ghp_[A-Za-z0-9]{36}`, `github_pat_[A-Za-z0-9_]{22,}` |
| Stripe key | `sk_live_[A-Za-z0-9]{24,}` |
| Slack token | `xox[baprs]-[A-Za-z0-9-]{10,}` |
| Generic assigned secret | a variable/field named `password`, `secret`, `api_?key`, `access_?token`, `client_?secret`, `connection_?string` (case-insensitive) assigned a quoted literal that isn't obviously a placeholder |
| Embedded credential in a URL | `://[^/\s]+:[^/\s@]+@` (a `user:password@host` connection string) |

## Step 2 — Filter placeholders before reporting

A hit is not a finding if the literal value is an obvious placeholder: `changeme`, `your-key-here`, `xxx`/`****`, `example`, `test`/`fake`/`dummy`, an empty string, or a value already wrapped in an env-var reference (`process.env.X`, `${X}`, `os.environ[...]`, `Environment.GetEnvironmentVariable(...)`) rather than a literal. Also skip anything inside a file the platform's own secrets denylist already treats as safe by convention (`.env.example`, `appsettings.Example.json`, etc. — see this project's `opencode.json` `permission` block) — those exist specifically to hold fake values.

## Step 3 — Report

Any real-looking hit → a finding: `file:line, <pattern matched>, looks like a live <credential type> — confirm this is a placeholder or remove it and rotate the real value if it was ever live`. This blocks LGTM the same as any other Mandatory-check finding.

**If the hit looks like a genuinely live credential** (matches a specific provider's key format, not just a generic `password = "..."` assignment) — say so explicitly and recommend the user route this to `@carter` for a fuller pass once fixed, since a live key that made it into a commit needs rotation, not just deletion from the diff — deleting the line doesn't undo the exposure if it was ever pushed.

## When this is NOT enough

This is pattern-matching on the diff's added lines, not a real secret-detection engine (no entropy analysis, no historical-commit scan). It will miss a secret introduced with unusual formatting and won't catch one already sitting in git history from an earlier commit. If the project handles anything sensitive enough to warrant real secret-scanning, that's a `@carter`-level recommendation to make once, not something this skill retrofits every cycle.

## Idempotent by nature

Read-only pattern match against a diff — safe to call repeatedly.
