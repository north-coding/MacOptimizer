# Codex Junk Group Review

This slice reduces raw `scan_junk` findings into deterministic cache/log groups before Codex assessment.

## Why

A real Mac mini scan produced 20,000 `userCache` files. Per-file model review is noisy, expensive, and hard to audit. Group review makes the unit of reasoning an app/top-level cache directory instead of one file.

## Files

The existing raw handoff stays unchanged:

- `scan.json`
- `assessment.json`

The group flow adds:

- `groups.json`
- `group-assessment.json`

All files live in:

`~/Documents/MacOptimizer-Codex-Handoff/`

## Grouping rule

For supported `scan_junk` categories, MacOptimizer groups by the first directory below the category root:

- `~/Library/Caches/<group>/...`
- `~/Library/Logs/<group>/...`
- `~/Library/Application Support/CrashReporter/<group>/...`
- `~/Library/Saved Application State/<group>/...`
- `/Library/Caches/<group>/...`
- `/Library/Logs/<group>/...`

Files directly inside a category root share the category root as one group.

No file contents are read to create groups.

## Group metadata

Each group contains only:

- deterministic id;
- root path;
- category;
- file count;
- total bytes;
- oldest/newest modification timestamp;
- hard-protected flag.

`groups.json` also records the source finding count and source bytes so aggregation remains auditable against the raw scan.

## Validation

A returned group assessment must exactly match the current exported group identity:

- group id;
- root path;
- category;
- file count;
- total bytes.

Unknown, duplicate, or stale/mutated groups fail closed.

Hard-protected groups are always downgraded to `review` even if Codex returns `trash`.

## UI

`Codex > Open Junk Cache Group Review` opens a read-only group window.

It can:

- run the same read-only 7-day `scan_junk` scan;
- show aggregated groups sorted by size;
- expand a group to inspect up to the 100 largest member files;
- export both the raw scan and group summary;
- import a validated group assessment.

It cannot:

- delete or trash files;
- prepare cleanup;
- confirm cleanup;
- bypass SafetyGuard;
- change permissions;
- grant Full Disk Access;
- invoke shell cleanup commands.

No execution path is introduced by this slice.