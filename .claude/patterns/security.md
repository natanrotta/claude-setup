# Security — App Security Model & Anti-Patterns (Authority)

**This document is the authoritative security reference for this project.** It is project-specific: it describes the *real* security model of this application (auth, multi-tenancy, endpoints, integrations, deploy) and a `SEC-*` anti-pattern catalog. Generic OWASP / LGPD checklists complement it but never replace it.

It is consumed by:
- the **`/security`** skill (`.claude/commands/security.md`) — consultant + implementer,
- the **`security-auditor`** agent (`.claude/agents/security-auditor.md`) — read-only scanner,
- `/code-review` and any reviewer who needs the security lens.

It **defers** to: `BASELINE.md` (R1–R28), `code-review-checklist.md` (B-/F-/X-/SC- codes — many are already security codes), `/devops` + `.claude/knowledge/devops.md` (infra). It cross-references those codes instead of duplicating them.

> **Namespace:** security codes are **`SEC-*`**. `S-*` is reserved for apps/site (see `code-review-checklist.md` § Spec Compliance note). Never mint an `S-*` security code.
>
> **Anchors drift.** Every `file:line` below was true at authoring time (2026-06-20). Before quoting an anchor as fact, re-grep the symbol by name — files move, line numbers rot.

---

## 0. Data classification (why this is not a normal CRUD app)

The data is **clinical (PHI) under LGPD**: consultation transcriptions, summaries, clinical notes, patient identifiers, documents. A leak here is a regulatory + ethical incident, not a bug. Three tiers:

| Tier | Examples | Rule |
|---|---|---|
| **Secret** | JWT secret, DB/Redis creds, Stripe/OpenAI/AWS/BirdID/SafeID keys, `SIGNATURE_SESSION_ENCRYPTION_KEY` | Env-only (validated config), `chmod 600` on the server, never in logs/commits/images/front. `R22`, `SEC-C4`. |
| **PHI / PII** | transcription, summary, notes, `fieldValues`, patient name/phone/email, document content | Never logged (`R5`/`SEC-C7`), never in URLs/referrers (`F-C4`), never returned cross-tenant (`SEC-C2`), redacted in pino. |
| **Operational** | ids, timestamps, counts, status | Normal handling; still tenant-scoped. |

The default posture is **fail-closed**: cross-tenant access returns `NotFoundError` (404), never `ForbiddenError` (403) — revealing existence is itself a leak (`R3`, `B-H16`).

---

## 1. Trust boundaries (the map you reason about per change)

```
Internet ── Cloudflare (WAF/proxy, hides origin IP, Origin Cert) ── Caddy (TLS, raw-body/SSE) ── Express API
                                                                                                     │
   Browser (app./adm.example.com, Cloudflare Pages)  ─cookies+Bearer+CSRF→  Express middleware chain
                                                                                                     │
   3rd parties (Stripe webhook, BirdID/SafeID, OpenAI, Tavily, S3, Resend)  ─signed/keyed→  providers
                                                                                                     │
   API ── WireGuard tunnel (10.8.0.0/24, private) ── Postgres+pgvector / Redis (VPS-DATA, never public)
```

Each boundary is a place to ask "what does the other side control, and what am I trusting?". The highest-risk inbound surfaces: **unauthenticated routes**, **webhooks**, **file uploads**, and **LLM-reachable content** (clinical text + tool/web output flowing into a model that can call tools).

---

## 2. Identity & authentication (real)

- **JWT** — `jsonwebtoken`, **HS256 pinned** on verify (alg-confusion defense) — `core/provider/jwt/jsonwebtoken-jwt-provider.ts`. Secret `env.JWT_SECRET` (min 32 chars, `core/config/env.ts`). Access TTL `JWT_EXPIRES_IN` (15m), refresh `REFRESH_TOKEN_EXPIRES_IN` (30d).
- **Token revocation** — `tokenVersion` claim must match the user row; bumped on password reset / suspension → invalidates all live JWTs. `auth.middleware.ts`.
- **Scoped tokens** — capability JWTs (`email:verify`, `support`, `imports:stream`) minted via `signScoped()`; gated by `requireScope()` / `rejectScopedTokens()`. `shared/constant/jwt-scopes.ts`.
- **Passwords** — bcrypt, cost 10 — `core/provider/hash/bcrypt-hash-provider.ts`. Strength enforced in `modules/auth/application/dto/auth.dto.ts` (8+, upper/lower/digit/special).
- **Middleware ladder** — `authMiddleware()` (full token, non-null accountId+role, onboarding gate), `interimAuthMiddleware()` (account-selection), `emailVerificationAuthMiddleware()`, `supportAuthMiddleware()` (admin, `is_support` + support scope, Google-only sign-in). All in `core/http/middlewares/`.
- **Cookies** — `app_rt` (httpOnly, path `/api/auth`), `app_csrf` (JS-readable, path `/`). Prod: `secure`+`sameSite=strict`. `core/http/helpers/auth-cookies.ts`.

## 3. Authorization & multi-tenancy (real)

- **Tenant isolation** — every repository query filters `account_id`; entities fetched then checked via `ensureSameAccount(entity, accountId, notFoundCode)` (throws `NotFoundError`). `shared/policy/ensure-same-account.ts`. This is the #1 invariant (`R1`/`R3`).
- **RBAC** — `requireRole(...roles)` (account role, `rbac.middleware.ts`), `requireWorkplaceRole(...roles)` (per-request workplace membership lookup, `workplace-role.middleware.ts`).
- **Request context** — `req.auth` (userId, accountId, role, language, onboardingStatus, scope), `req.interimAuth`, `req.adminAuth`. Use cases receive `{ userId, accountId }` as DTO fields — never `req` (`R7`/`B-C9`).

## 4. HTTP hardening (real — `core/http/app.ts`)

- **helmet** — HSTS 1y + preload, frameguard deny, referrer strict-origin; **CSP** (`defaultSrc 'self'`, `scriptSrc 'self'`, `objectSrc 'none'`, `frameAncestors 'none'`). `/admin/*` uses a CSP-relaxed variant for BullBoard.
- **CORS** — origin allowlist from `ALLOWED_ORIGIN` (strips `*` in prod), `credentials: true`.
- **CSRF** — double-submit (`app_csrf` cookie ↔ `X-CSRF-Token` header); safe methods + Bearer-only `/api/admin/*` skip. `csrf.middleware.ts` (`B-C12`).
- **Rate limiting (layered)** — global 1000/5min/IP; auth 10/15min/IP (`auth-rate-limit`); user 200/min/userId (`user-rate-limit`); AI/copilot 20/min/user (`ai-rate-limit`); public-share 30/15min/IP. Webhooks skipped.
- **Body limits** — webhooks raw 1MB, copilot 100KB, patient-documents 11MB, default 10KB.
- **Validation** — Zod via `validateRequest` middleware on params/query/body (`B-C6`). `trust proxy: 1`.
- **Errors** — central handler; `{ ok:false, error:{ message, code, debug? } }`, stack only non-prod, query strings stripped from Bugsnag reports. `error-handler.middleware.ts`.

## 5. Data layer, secrets, logging (real)

- **Prisma** — no `$queryRaw`/`$executeRaw` template injection; the few `$queryRawUnsafe` (RAG/consultation search) use **positional `$1` placeholders + separate params array** — parameterized, not injectable. Soft delete (`deleted_at: null`, `R2`). `mapPrismaError` on catches (`B-H3`). Cross-tenant mutations fail-closed (zero rows).
- **Secrets** — single validated config `core/config/env.ts` (Zod); **no scattered `process.env`**. `SIGNATURE_SESSION_ENCRYPTION_KEY` has a dev default — must be a real secret in prod. Provider tokens (BirdID/SafeID) encrypted at rest (AES-256-GCM).
- **Logging** — pino with `redact` list (`core/http/logger.ts`): authorization, cookies, csrf, password/token/refreshToken/credentials, and clinical fields (`message`, `text`, `notes`, `transcript`, `transcription`, `summary`, `fieldValues`, `contextData`). **Redaction is defense-in-depth, not a license to log PHI** (`R5`/`SEC-C7`). A new clinical field added to a payload must be added to the redact list (`SEC-M2`).

## 6. Integrations (real)

- **Stripe webhook** — mounted before the JSON parser with `express.raw` (raw body intact); `stripe.webhooks.constructEvent(rawBody, sig, STRIPE_WEBHOOK_SECRET)` → 400 `BILLING_WEBHOOK_INVALID_SIGNATURE` on failure. `webhook.routes.ts`, `billing.controller.ts`, `stripe-payment-provider.ts`. Any new webhook MUST mirror this (`SEC-C3`).
- **File upload / S3** — MIME + size gated per type (audio 50MB, attachment 20MB, image 5MB, pdf 10MB, csv 50MB+extension check), codecs stripped, filename sanitized, S3 key `knowledge/{accountId}/{uuid}-{name}`, signed URLs (1h), compensating delete on failure. `upload.middleware.ts`, `s3-storage-provider.ts`. Media lives in S3 and is **outside** the `pg_dump` backup scope.
- **Providers** — OpenAI/Tavily (LLM/search), BirdID/SafeID (ICP-Brasil signature), Resend (email), Redis (cache), GitHub Actions token (read-only, CI status panel). All env-keyed via the validated config; LLM only via `ILlmProvider` (`R23`/`B-C13`).

## 7. LLM / Copilot — the live risk surface

The copilot runs a LangGraph ReAct loop with ~28 tools (some with `writes`/`webSearch` capability), token-budget guards, and tenant-scoped RAG (`rag_chunk` filtered by account). Tool allow-listing is compile-time bound per skill with a boot guard. **Open risk (audit G1–G4, `docs/architecture/copilot/`):**

- **G1/G2 prompt injection** — preloaded clinical context (summary/transcription/fieldValues) and tool/RAG/web output are injected into the prompt **unsanitized/unfenced** (`modules/ai/infrastructure/prompts/copilot/copilot-prompt.builder.ts`). Untrusted clinical text containing "ignore previous instructions…" reaches the model, which can call tools. This is the highest-leverage app-layer security gap. → `SEC-C5`.
- **G3 clinical scope** — guardrails are prompt-level only; no code-enforced scope limiter.
- **G4 eval** — no automated red-team / eval harness for prompt/RAG output.

## 8. Deploy security (defer to `/devops`; summary here)

Authoritative: `.claude/knowledge/devops.md` (fonte única de infra). Security-relevant invariants:
- **Golden rule** — VPS-DATA never exposes `5432`/`6379` to the internet; app↔DB only over the WireGuard tunnel.
- **Edge** — Cloudflare proxied (hides origin IP) + **Origin Certificate** (Full strict); origin should accept 80/443 only from Cloudflare (ufw hardening still pending).
- **Secrets** — `.env.prod` on the server (`chmod 600`), not in the image (except stamped `APP_VERSION`).
- **Backup** — encrypted (`age`) offsite, private key off the data VPS; **not yet active** — TRAVA before real patient data.
- **Known open infra-security items** — backup activation, ufw lockdown to Cloudflare, **rotate secrets that passed through chat**, Cloudflare Access on admin. (devops backlog).

---

## SEC-* Anti-Pattern Catalog

Same rubric as `code-review-checklist.md`: **Critical** blocks merge, **High** fix before merge, **Medium** recommended, **Low** nitpick. Cite the code; cross-refs in parentheses point at the existing checklist/baseline code that already governs the same thing — `SEC-*` is the security *lens* over them, not a replacement.

### Critical (block merge)

| # | Anti-pattern | Why |
|---|--------------|-----|
| SEC-C1 | **Broken authentication** — a route accepting input/returning data mounted without `authMiddleware()` (or the right scope/interim variant) and not in the documented public allowlist in `routes/index.ts` | Anyone can call it (⊃ `B-C11`) |
| SEC-C2 | **Broken object-level auth / IDOR** — entity fetched by id without `account_id` scoping AND without `ensureSameAccount(...)`; or `ForbiddenError` used (reveals existence) | Cross-tenant PHI leak (`R1`/`R3`, ⊃ `B-C1`/`B-C3`/`B-H16`) |
| SEC-C3 | **Unverified webhook / inbound** — webhook handler without signature verification, or JSON body parser placed before the raw-body route (breaks Stripe-style verification) | Forged events; mirror `webhook.routes.ts` |
| SEC-C4 | **Secret exposed** — credential committed, hardcoded, read outside the validated config, baked into an image, or sent to the front | Immediate revocation needed (`R22`, ⊃ `X-C4`) |
| SEC-C5 | **Prompt-injection sink** — untrusted content (clinical text, RAG, tool/web output) injected into an LLM prompt without fencing/sanitization, or an LLM with `writes`-capable tools reachable from untrusted input | Model hijack → data exfil / unauthorized writes (the G1/G2 surface) |
| SEC-C6 | **Injection** — raw SQL with string interpolation, shell exec with user input, SSRF (server fetch to a user-controlled URL), or unsafe deserialization | Classic RCE/injection (⊃ `B-C7`) |
| SEC-C7 | **PHI/PII leak** — clinical/personal data logged, returned in an error to the client, placed in a URL/query/referrer, or emitted cross-tenant | LGPD incident (`R5`, ⊃ `B-C5`/`F-C4`) |

### High (should fix)

| # | Anti-pattern | Fix |
|---|--------------|-----|
| SEC-H1 | Route accepts input without `validateRequest(...)` (Zod) | Add the schema + middleware (`B-C6`) |
| SEC-H2 | Sensitive/unauthenticated endpoint (auth, password reset, public share, AI, file upload) without rate limiting | Add the right limiter (`auth`/`user`/`ai`/`public`) |
| SEC-H3 | Privileged action without role gate (`requireRole` / `requireWorkplaceRole` / `supportAuthMiddleware`) | Add the gate; admin ≠ authenticated |
| SEC-H4 | State-changing cookie-auth route bypassing CSRF | Keep it under the CSRF middleware (`B-C12`) |
| SEC-H5 | Weak token/crypto — JWT alg not pinned, no expiry, predictable/guessable token, missing `tokenVersion` revocation, password not bcrypt, MD5/SHA1 for secrets | Mirror the JWT/bcrypt providers |
| SEC-H6 | File upload trusting client MIME/filename, or missing size/type gate, or unsanitized path | Gate via `upload.middleware.ts`; sanitize filename; account-scoped key |
| SEC-H7 | Permissive CORS (`*` with credentials) or weakened/removed security header / CSP `unsafe-eval` | Keep the allowlist + helmet/CSP posture |
| SEC-H8 | New secret added without env validation + rotation path, or default secret left in prod (`SIGNATURE_SESSION_ENCRYPTION_KEY`-style) | Register in `env.ts`; require a real value in prod (`X-H4`) |

### Medium (recommended)

| # | Anti-pattern | Fix |
|---|--------------|-----|
| SEC-M1 | Error response leaks internals (stack, SQL, file path, dependency version) to the client in prod | Map to an `AppError`+`ErrorCode`; debug only non-prod |
| SEC-M2 | New sensitive/clinical field in a request/response payload not added to the pino `redact` list | Add the path to `logger.ts` |
| SEC-M3 | No refresh-token rotation / session-fixation defense on long-lived sessions | Rotate on refresh where feasible; document trade-off |
| SEC-M4 | Sensitive admin/impersonation/billing action without an audit trail | Log the actor + action (no PHI) for forensics |
| SEC-M5 | Dependency with a known CVE / no `yarn npm audit` consideration on a new dep | Pin/upgrade; note in the spec Decisions log |
| SEC-M6 | Token promoted from query (`?access_token=`) for SSE/download without proxy stripping it from access logs | Document the proxy requirement; prefer header |

### Low / Nitpick

| # | Issue |
|---|-------|
| SEC-L1 | Verbose version/server header disclosure |
| SEC-L2 | Overly long token/session TTL with no justification |
| SEC-L3 | Missing `aria`/UX affordance that nudges users toward insecure behavior (e.g. paste-secret-in-plaintext field) |

When you spot something real that no `SEC-*` code covers, report it as **`Issue (proposed)`** so it can be promoted into this catalog.

---

## Analysis techniques (how the specialist reasons)

1. **Threat-model the change, not the whole app.** For the diff, ask STRIDE-lite per touched boundary: *Spoofing* (auth ok?), *Tampering* (validation/signature?), *Repudiation* (audit trail?), *Information disclosure* (tenant scope + PHI in logs/errors?), *DoS* (rate limit + pagination + body cap?), *Elevation* (role gate + IDOR?).
2. **Follow the data.** Trace untrusted input from the boundary to where it's trusted (DB query, LLM prompt, shell, file path, response). Every hop is a SEC checkpoint.
3. **Per change-type checklist** — *new route* → SEC-C1/H1/H2/H3 + C2; *new webhook/integration* → SEC-C3/C4; *touches copilot/prompt/tool* → SEC-C5; *touches auth/JWT/crypto* → SEC-H5; *new env/secret* → SEC-C4/H8; *logging/new field* → SEC-C7/M2; *file upload* → SEC-H6; *infra/deploy* → defer to `/devops` golden rules (§8).
4. **Prefer existing primitives.** The repo already ships the secure way (ensureSameAccount, validateRequest, the limiters, the JWT/bcrypt providers, the redact list, the raw-body webhook pattern). A security fix is usually "use the existing primitive", not "invent crypto".
