# Napkin

## Corrections
| Date | Source | What Went Wrong | What To Do Instead |
|------|--------|-----------------|-------------------|
| 2026-09-19 | self | `git push origin <branch>` from a worktree created via `git worktree add -b <branch> origin/main` landed straight on remote main — the worktree branch's upstream was `origin/main` and this machine sets `push.default=upstream` globally. | Always push with an explicit destination refspec: `git push origin HEAD:refs/heads/<branch>` (or `HEAD:main` when main is intended). Never rely on push.default from this machine. |

## User Preferences
- Direct-to-main is acceptable for small, single-purpose fixes in this portfolio (CI fixes, metadata). Precedent: emojix/ex_abby CI fixes landed on main; the 2026-09-19 CI fix landed the same way and the user raised no objection after disclosure.
- Routine Dependabot compatible-group PRs get batch-merged once the Hex audit is green (user approved that recommendation 2026-09-19).

## Patterns That Work
- DB-touching tests must check out an Ecto SQL Sandbox connection in `setup` (see `ExEmailTrackerTest`, `TrackOpenTest`). `EventRecorder.record_event/3` is expected to fail the FK to a nonexistent send and be handled gracefully.
- CI postgres service health check must be `pg_isready -U postgres` — the default OS user does not exist as a role.

## Domain Notes
- Hex-publishable library. Package metadata in `mix.exs` `package/0`: grahac URLs, maintainer Charlie Graham. Tests use a hand-rolled `TestRepo` + `storage_up` in `test/test_helper.exs` (no ecto.create/migrate mix aliases) — fresh Postgres works out of the box.
