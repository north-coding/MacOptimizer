# Truthful Junk Scan v2

## Objective

Every junk-scan number MacOptimizer displays or exports must either describe the complete observed filesystem scope or explicitly state that the observation is incomplete.

`0` must never mean "not reached", "permission denied", or "truncated".

## Current defect

The current `scan_junk` implementation accumulates findings root-by-root with a per-enumeration limit of 20,000, breaks once the aggregate reaches 20,000, and finally returns `prefix(20_000)`. A first root can therefore starve all later roots. Enumeration errors are also swallowed.

The real Mac mini run that returned exactly 20,000 `userCache` findings cannot be treated as a complete inventory of user caches, logs, crash reports, saved state, system caches, or system logs.

## V2 source roots

The configured roots remain unchanged:

1. `~/Library/Caches` — `userCache`
2. `~/Library/Logs` — `userLog`
3. `~/Library/Application Support/CrashReporter` — `crashReport`
4. `~/Library/Saved Application State` — `savedState`
5. `/Library/Caches` — `systemCache`
6. `/Library/Logs` — `systemLog`

No additional roots are introduced in this slice.

## Coverage model

Every configured root must emit an explicit coverage record.

Minimum fields:

- `rootPath`
- `category`
- `status`
- `filesSeen`
- `filesMatched`
- `bytesMatched`
- `errorCount`

Status values should distinguish at least:

- `complete`
- `absent`
- `denied`
- `error`

If implementation later needs `truncated`, it may exist, but V2 should not silently truncate normal junk scanning.

`absent` means the configured root does not exist. It does not mean `complete` with zero files.

Permission/access failures must increment `errorCount` and must not be represented as an empty successful root.

## Streaming aggregation

The V2 arithmetic unit is the junk group, not the individual file.

The scan should enumerate each configured root without an arbitrary 20,000-file prefix and update group aggregates while walking.

Group identity remains the existing deterministic first-directory-below-category-root rule.

Per group retain:

- deterministic group id
- root path
- category
- total file count
- total bytes
- oldest modification time
- newest modification time
- hard-protected status
- age buckets
- only a bounded set of member findings for UI expansion

The UI-member retention limit may remain 100 largest members per group. That limit is display-only and must not affect totals.

## Age model

Do not pre-filter away files newer than seven days before aggregation.

Compute age buckets over the complete observed group metadata:

- `<7d`
- `7–30d`
- `30–180d`
- `>=180d`

Each bucket carries:

- file count
- total bytes

The bucket counts and bytes must sum exactly to the group totals for complete groups.

The old `olderThanDays=7` concept may remain as presentation/advisory semantics, but not as the data-collection filter for V2 group truth.

## Protocol

`groups.json` becomes schema version 2.

It must include:

- source tool
- generated time
- per-root coverage records
- group aggregates
- age buckets

A V2 assessment must not validate against a V1 group export and vice versa.

The existing raw `scan.json` protocol is not expanded into an unbounded all-files dump in this slice. Group V2 is the truthful primary review surface.

## UI truthfulness

The Junk Cache Group Review UI must surface scan coverage.

If every configured root is complete/absent with no access errors, it may show a complete summary.

If any configured root is denied/error/incomplete, the UI must visibly say the scan is partial and identify the affected root/category. A bare zero for that category is prohibited.

## Safety

This slice is read-only.

Do not add:

- cleanup executor
- Trash action
- Delete/Clean/Confirm Cleanup control
- permission escalation
- Full Disk Access request flow
- new scan roots
- app/bundle attribution
- trend/history storage
- vendor-specific cleanup policy

PR #6 made the AI Assistant read-only; V2 must preserve that boundary.

## Validation oracle

Synthetic filesystem tests should independently prove:

1. multiple roots are all visited even when one contains more than 20,000 matching files or an equivalent configurable test limit;
2. per-root coverage records distinguish complete, absent, and access/error states;
3. no global `prefix(20_000)` or root-starvation behavior remains in `scan_junk`;
4. group totals equal the sum of all observed member metadata, independent of the 100-member UI retention limit;
5. age-bucket counts and bytes sum to group totals;
6. V1/V2 schema mismatch fails closed;
7. UI/export never represents denied/unreached roots as zero.

After synthetic validation, run exactly one controlled real read-only junk scan on the Mac mini and compare it with the historical capped run:

- every configured root has an explicit coverage status;
- the result is not silently fixed at exactly 20,000 findings;
- later roots are either observed or explicitly unavailable;
- group totals and age buckets are internally consistent;
- no cleanup or deletion occurs.
