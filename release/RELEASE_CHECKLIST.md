# Release checklist and release notes - Laboratory 8

Fill every `___`. Copy the finished tables into the Word report. Use fictional data only.
Do not paste passwords, `APP_KEY`, tokens or real personal data anywhere in this file.

## 1. Roles and starting environment

| Item | Value |
|---|---|
| Driver (prepares the release) | ___ |
| Reviewer (checks artifact and evidence) | ___ |
| Roles swapped before smoke testing? (time) | ___ |
| Staging target | Render web service `lab-staging`, URL ___ (https) |
| Staging database | Supabase project ___ (region ___), runtime role `laravel_app` |
| Deployment service | GitHub Actions **Release** workflow -> Render deploy hook (digest-pinned image) |
| Workflow name | Release (`.github/workflows/release.yml`) |
| Plans in use (Render / Supabase) | ___ / ___ (note sleep, hours, backups) |
| Current known-good release (before this lab) | ___ (none yet if first release) |
| Laravel version (`php artisan --version`) | Laravel Framework 13.33.0 |
| Starting commit (`git rev-parse HEAD`, before any Lab 8 change) | ___ |
| Instructor permission to build own staging (who / when / how) | ___ |

## 2. Release record (candidate)

| Field | Value |
|---|---|
| Candidate version | v1.4.0 (change if you use another) |
| Commit SHA | ___ |
| Image digest (one image, nginx + PHP-FPM) | `ghcr.io/.../app@sha256:___` |
| Change summary | ___ |
| CI results (run link, test / audit outcome) | ___ |
| Migration plan | ___ (e.g. "first release: empty database, run `migrate --force` through the workflow's run_migrations"; later: "no schema change; status only") |
| Dev vs staging database | MySQL (dev) vs Postgres/Supabase (staging). Differences checked: ___ (CI ran tests on both: run link ___) |
| Approver | ___ |
| Smoke tests | see section 6 |
| Rollback criteria | If the request-creation smoke test (STAGE-LIB-08) fails, roll back to the known-good digest at once. |
| Recovery point before any schema change | ___ (e.g. `mysqldump` file name, taken at ___) |

## 3. Release notes

**v1.4.0** - ___ (date)

- Added: `/health` endpoint reporting version, commit and database status.
- Added: release identity (`APP_VERSION`, `GIT_SHA`) baked into the image.
- Added: staging stack, gated release workflow, deployment script.
- Changed: ___
- Schema: no change / migration `___`.
- Known issues: ___

## 4. Approval gate evidence

| Item | Value |
|---|---|
| Workflow run link | ___ |
| Gate state captured (screenshot no.) | "Waiting for review" - Fig. 8-__ |
| Things the approver verified | CI result [ ], artifact digest [ ], staging target [ ], migration plan [ ] |
| Approver | ___ |
| Decision | Approved / Rejected |
| Timestamp (local, Asia/Manila) | ___ |
| Deployed digest equals approved digest? | yes / no |

If GitHub environments with required reviewers were unavailable, record the manual
promotion here instead: approver name, "approved" decision, timestamp, link to the PR
comment or issue where it was written.

## 5. Migration decision

| Item | Value |
|---|---|
| How run | workflow `run_migrations` / `scripts/artisan-remote.ps1` (circle one) |
| `php artisan migrate:status` output (screenshot no.) | Fig. 8-__ |
| Schema change required? | Yes / No |
| If yes: recovery point confirmed, compatible with the known-good app? | ___ |

## 6. Smoke tests (fictional accounts and data only)

Test request label: `STAGE-LIB-08` (item: HDMI adapter)  -  **Request ID recorded: ___**

| # | Test | Expected | Actual | Result | Evidence |
|---|---|---|---|---|---|
| 1 | Health and revision | `/health` returns status ok; version equals the release record | ___ | ___ | Fig. 8-__ |
| 2 | Student login | Test student signs in and reaches the request page | ___ | ___ | Fig. 8-__ |
| 3 | Request creation | Student submits the HDMI adapter request STAGE-LIB-08; reopening shows the saved record | ___ | ___ | Fig. 8-__ |
| 4 | Administrator status update | Test administrator updates the request to an allowed status | ___ | ___ | Fig. 8-__ |
| 5 | Student restriction | Student account cannot perform the status change | ___ | ___ | Fig. 8-__ |

## 7. Faulty release and rollback

| Item | Value |
|---|---|
| Instructor approval for the faulty deploy (who / when) | ___ |
| Faulty version / digest | v1.4.1-lab-fault / `sha256:___` |
| Failing smoke test | Test # ___ - expected ___, actual ___ |
| Time failure observed | ___ |
| **Time rollback decision was made** | ___ |
| Rollback method | **Release** workflow, environment `staging`, mode `redeploy`, version v1.4.0 (deploys the old digest; no rebuild) |
| Old image still available in GHCR? | yes / no (Render pulls it again on every deploy) |
| Restored version (from `/health`) | ___ |
| Time restoration confirmed | ___ |
| Smoke tests re-run after rollback | all 5 passed? yes / no (Fig. 8-__) |
| Request STAGE-LIB-08 present with the same ID? | yes / no - ID before ___, ID after ___ |

### Why the record survived the rollback

The application artifact (the image) holds code only. Staging data lives in the staging
Supabase (Postgres) project, which is outside the image and outside Render. Redeploying a
different image changes the running code and leaves the database, its tables and rows
untouched, so STAGE-LIB-08 keeps the same ID. This only works because the faulty release
used the same schema. A release with a destructive schema change would not be undone by
redeploying the old artifact.

### What a database recovery would need (separate from an artifact rollback)

1. Have a backup from before the change: a Supabase backup if your plan includes one (state which plan and what it provides), otherwise a `pg_dump` taken beforehand and stored away from the database.
2. Stop writes (pause the Render service) so the restore is consistent.
3. Restore into the staging database.
4. Check the schema matches the application version (`migrate:status`); redeploy a compatible artifact.
5. Verify the data (row counts, the STAGE-LIB-08 record) and re-run the smoke tests.
6. Record the recovery time and the data loss window (changes made after the backup).

## 8. Reviewer sign-off

| Item | Value |
|---|---|
| Reviewer checked the report against the workflow log | yes / no |
| Repository link | ___ |
| Pull request link | ___ |
| Reviewer name / date | ___ |
