# Codex Safe Handoff

This fork uses Codex only as an advisory local analyzer. Codex is not a deletion authority.

## Contract

1. MacOptimizer performs the real local scan.
2. MacOptimizer exports a versioned JSON envelope containing the exact findings.
3. Codex may inspect those findings and return `keep`, `review`, or `trash` recommendations with reasons.
4. MacOptimizer validates every returned item against the exact exported path, category, and size.
5. Codex may not invent files or change finding identity.
6. Hard-protected paths are always downgraded to `review`, regardless of Codex output.
7. A Codex recommendation never bypasses `SafetyGuard` or any future execution-time safety check.
8. This first slice has no deletion/execution path. It only establishes export/import/validation semantics.

## Hard-protected areas

The initial policy treats these as review-only for Codex-assisted cleanup:

- `/System`
- `/Library`
- `/Applications`
- `/usr`, `/bin`, `/sbin`, `/private`
- `~/Documents`, `~/Desktop`, `~/Movies`, `~/Music`, `~/Pictures`
- `~/Library/Keychains`
- `~/Library/LaunchAgents`
- `~/Library/Containers`
- `~/Library/Group Containers`
- `~/.ssh`, `~/.gnupg`, `~/.codex`

The list is intentionally conservative. MacOptimizer may still scan and display these areas where the existing product allows it, but Codex cannot turn them into an automatic-cleanup authorization.

## Explicit non-goals for this slice

- No `rm`, `rm -rf`, `sudo`, `launchctl`, or process killing.
- No direct Codex filesystem deletion.
- No Full Disk Access changes.
- No automatic cleanup of large files, duplicate files, startup items, app containers, application support data, or user documents.
- No use of the existing `ignoreProtection` / `bypassProtection` path for Codex-assisted actions.

## Next validation gate

Before adding UI or execution:

- run the full Swift test suite locally;
- build the app on the target Mac mini;
- export one scan-only report;
- round-trip a synthetic Codex assessment;
- verify hard-protected items are downgraded to `review`;
- verify unknown or stale findings fail closed.
