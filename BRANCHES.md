# Branch Strategy

## Active Branches

### `main`
- **Purpose:** Active development — all new features, fixes, and refactors land here first.
- **Owner:** Vijay Dixit
- **Allowed:** Any commit. This is the integration branch.
- **CI/CD:** Deploys to development/staging environment.

### `stable-v1`
- **Purpose:** Production-stable snapshot of the v1.0 release. Frozen except for critical patches.
- **Owner:** Vijay Dixit
- **Allowed:** **Patches only** — security fixes, data-loss bugs, broken deployments. No features, no refactors.
- **How to patch:** Branch off `stable-v1`, fix, PR back into `stable-v1`, then cherry-pick the commit to `main`.
- **Do NOT:** Push feature work, schema migrations, or experimental changes here.
- **Tagged at:** `v1.0-stable` / `db-driven-admin-UI-14May26-11pm`

---

## Tags

| Tag | Branch | Date | Notes |
|-----|--------|------|-------|
| `v1.0-stable` | stable-v1 | 2026-05-14 | Production baseline — admin UI, DB-driven config, agent failure handling |
| `db-driven-admin-UI-14May26-11pm` | main | 2026-05-14 | Same commit as v1.0-stable; descriptive label for this session |

---

## Workflow

```
feature work  →  main  →  (cherry-pick critical fixes)  →  stable-v1
```

Never merge `main` into `stable-v1` wholesale — it would pull in unvalidated changes.
