# Branch & Repository Strategy

This document covers the full evolution of the ARB AI Agent codebase — from today's monorepo
through to a split backend + frontend architecture with multi-tenant branding support.

---

## Current State — Monorepo (`arb-ai-agent`) ✅ Phase 1 Complete

### Branches

| Branch | Purpose | Allowed | Status |
|--------|---------|---------|--------|
| `main` | Active development — all new features, fixes, and refactors land here | Everything | Active |
| `stable-v1` | Frozen production snapshot. Patches only. | **Critical patches only** (security, data-loss, broken deploy) | Frozen |

### Tags

| Tag | Points to | Date | Notes |
|-----|-----------|------|-------|
| `v1.0-stable` | `stable-v1` tip | 2026-05-14 | Permanent recovery point — admin UI, DB-driven config, agent failure handling |
| `db-driven-admin-UI-14May26-11pm` | `main` @ `ef5af55` | 2026-05-14 | Session label for the same baseline commit |

### Rules for `stable-v1`
- **Never** merge `main` into `stable-v1` wholesale — it pulls in unvalidated changes.
- Patch workflow: branch off `stable-v1` → fix → PR back to `stable-v1` → cherry-pick the commit to `main`.
- No features, no schema migrations, no refactors.

---

## Planned Split — Phase 2–3 (Day 1–2)

The monorepo will be split into two standalone repos. The monorepo is **not deleted** — it
remains as the audit trail and git history reference.

### `arb-ai-backend` (new repo: `vijaydixitffis/arb-ai-backend`)

Contains: `backend/`, `supabase/`, `knowledge-base/`

| Branch | Purpose |
|--------|---------|
| `main` | Active backend development |
| `stable-v1` | Frozen v1 API — patches only |

Key tasks before first commit:
- Restructure routes into `api/v1/` (frozen) and `api/v2/` (evolve here)
- Export and commit `openapi-v1.yaml` as the frozen v1 API contract
- Adapt CI workflows (Python lint, tests, Docker build)

**Rule:** `/api/v1` routes are read-only. New data shapes or endpoints go into `/api/v2` only.

### `arb-ai-frontend` (new repo: `vijaydixitffis/arb-ai-frontend`)

Contains: `frontend/` (promoted to repo root — not a subfolder)

| Branch | Purpose |
|--------|---------|
| `main` | Integration branch |
| `stable-v1` | Frozen original UI — patches only, wired to `/api/v1` |
| `new-ui-v1` | Active new UI development, wired to `/api/v2` |

Key tasks before first commit:
- Add `src/brand.config.ts` — all hardcoded names, colours, logos read from here via env vars
- Point all API calls at `brand.config.apiBase + brand.config.apiVersion`

**Deploy targets** (same `new-ui-v1` branch, different `.env`):

```
.env.stable-v1        → VITE_API_VERSION=v1  (original UI)
.env.new-ui-generic   → VITE_API_VERSION=v2  (generic branding)
.env.ffis             → VITE_API_VERSION=v2  + FFIS branding vars
```

---

## Active Development Phase — Phase 4 (Week 2+)

- New UI work happens exclusively on `arb-ai-frontend / new-ui-v1`
- New backend endpoints go into `/api/v2` only — v1 is untouched
- Critical fixes cherry-picked to `stable-v1` in both repos if applicable:

```bash
git checkout stable-v1
git cherry-pick <commit-hash>
git push origin stable-v1
```

- FFIS launch: same `new-ui-v1` code, different `.env` at deploy time — no new branch needed

---

## Retirement — Phase 5 (Month 4–6)

Once the new UI is proven in production:

1. Archive (do not delete) `stable-v1` branches in both repos
2. Add `@deprecated` headers to `/api/v1` routes for a grace period, then remove the v1 router mount
3. Update this monorepo's README: *"Superseded by arb-ai-backend + arb-ai-frontend. Kept for historical reference."*

---

## Quick Reference — Where to Commit What

| Work type | Repo | Branch |
|-----------|------|--------|
| New features / admin / agents | `arb-ai-agent` (now) → `arb-ai-backend` (post-split) | `main` |
| New UI components | `arb-ai-agent` (now) → `arb-ai-frontend / new-ui-v1` (post-split) | `new-ui-v1` |
| Critical prod fix (old UI) | `arb-ai-agent` or `arb-ai-frontend` | `stable-v1` |
| New API shape needed by new UI | `arb-ai-backend` | `main` (under `/api/v2`) |
| Branding change (FFIS vs generic) | `arb-ai-frontend` | `.env` only — no branch change |
