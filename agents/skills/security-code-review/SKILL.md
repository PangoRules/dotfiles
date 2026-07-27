---
name: security-code-review
description: Use when auditing application code for exploitable vulnerabilities — injection, XSS, broken auth/authz, secrets exposure, SSRF, insecure deserialization, weak crypto, missing rate-limiting/DoS resilience, CSRF, unsafe file upload. Stack-agnostic, adapt patterns to whatever languages are actually present.
---

Manual/grep-assisted review for exploitable code patterns, organized by OWASP-style category. Read-only — find and report, never fix here.

## Step 0 — Detect the stack before grepping

Look at what languages/frameworks are actually in the repo (`package.json`, `*.csproj`, `pyproject.toml`, etc.) and the project's own documented conventions (`CLAUDE.md`/`AGENTS.md` if present — they often state the intended auth model, error-handling pattern, or a "never do X" rule directly). Grep patterns below are illustrative starting points per category, not an exhaustive or fixed list — adapt them to the actual language/framework idioms present. A pattern with zero hits in a language that isn't in the repo isn't a clean bill of health, it's a non-check; don't report "no findings" for a category you didn't actually have a way to check in this stack.

## Categories

### Injection
SQL/NoSQL: string-concatenated or f-string/template-interpolated queries instead of parameterized queries/ORM query builders. Command injection: user input reaching a shell (`subprocess.run(..., shell=True)`, `exec()`, backticks, `child_process.exec` with concatenated args). Code injection: `eval()`, `Function()`, `exec()`, deserialization of untrusted input into executable code.

### Cross-Site Scripting (XSS)
Raw HTML rendering from user/DB-sourced content without sanitization: `v-html`, `dangerouslySetInnerHTML`, `.innerHTML =`, unescaped template interpolation in server-rendered HTML. Reflected XSS: user input echoed into a response (error messages, search results) without encoding.

### Broken authentication / authorization
Endpoints/routes missing an auth check entirely. Authorization decided client-side only (a hidden button isn't a security boundary — the server must reject it too). IDOR: an object fetched/mutated by an ID taken from the request without verifying the caller owns or is a member of it. Privilege checks that trust a client-supplied role/flag instead of re-deriving it server-side from the authenticated session.

### Secrets exposure
Hardcoded API keys, passwords, connection strings, or tokens in source or committed config files. Secrets written to logs. `.env` or credential files tracked in git (check `.gitignore` covers them, and check history — a secret removed from the current file but present in git history is still exposed).

### Insecure configuration
Wildcard CORS (`Access-Control-Allow-Origin: *`) on an endpoint that also accepts credentials. Debug/verbose error modes left enabled in a production config path (stack traces, SQL errors, or internal paths leaking to clients). Default/example credentials left in config templates without a clear "change this" callout.

### SSRF / path traversal
Server-side requests to a URL built from user input without an allowlist or scheme/host validation. File reads/writes using a path built from user input without normalization — check for `../` traversal, absolute-path overrides, and symlink handling.

### Insecure deserialization
Unsafe deserializers on untrusted input: Python `pickle.loads`, .NET `BinaryFormatter`, YAML `unsafe_load`, or any deserializer that can instantiate arbitrary types from the payload.

### Rate limiting / DoS resilience
Public-facing endpoints with no rate limit — especially auth (login/password-reset — brute-force target), search, file upload, and anything that triggers an expensive downstream call (LLM/AI calls, report generation, external API fan-out). No request body size cap. No timeout on expensive operations. No pagination cap on list endpoints (unbounded `?limit=999999` style queries). This category is explicitly in scope even though it's not classic "injection" — an unbounded endpoint is a real exploitable gap, not just a performance nit.

### Weak cryptography
Passwords hashed with a fast/general-purpose hash (MD5, SHA1, unsalted SHA256) instead of a slow password-hashing function (bcrypt, Argon2, scrypt, PBKDF2 with adequate iterations). Predictable tokens: session IDs, password-reset tokens, or API keys generated from a non-cryptographic RNG (`Math.random()`, `random.random()`, time-seeded generators) instead of a CSPRNG. Hardcoded encryption keys or IVs.

### CSRF
State-changing endpoints reachable from a browser with cookie-based session auth and no CSRF token/`SameSite` protection. Lower priority (often not applicable) for pure JWT-bearer APIs with no cookie auth — note the auth model before flagging this category, don't apply it blindly.

### Unsafe file upload
Missing content-type, size, or extension validation on uploads. Filename taken from the client used directly in a storage path (traversal risk) instead of a generated key. No scanning/sandboxing for a public-facing upload feature that other users can access.

## Output shape

Each finding:
```markdown
### [SEVERITY] <short title>
- **Category:** <one of the above>
- **Where:** <file:line, or endpoint/route>
- **Issue:** what's wrong, in one or two sentences
- **Impact:** what an attacker could actually do with this — be concrete, not generic ("could exfiltrate other users' project data via IDOR on GET /api/projects/{id}", not "could be a security issue")
- **Fix:** concrete remediation direction (not a full patch — that's the plan's job)
```

Severity guide: **Critical** = remotely exploitable, no auth required, high impact (RCE, auth bypass, mass data exposure). **High** = exploitable by an authenticated user against other users' data, or unauthenticated but limited impact. **Medium** = requires specific conditions or internal access, real but harder to reach. **Low** = defense-in-depth gap, best-practice deviation, not independently exploitable.

Don't inflate severity to pad the report, and don't downgrade a real finding because a fix looks inconvenient — report what's actually exploitable and let the human/architect weigh tradeoffs.
