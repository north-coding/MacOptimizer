# Codex round-trip review

This slice connects MacOptimizer's latest real local scan result to a deterministic local file handoff and a read-only review window.

## Workspace

MacOptimizer uses:

`~/Documents/MacOptimizer-Codex-Handoff/`

Files:

- `scan.json` — written by MacOptimizer from the current `MacAgentToolReport`.
- `assessment.json` — written by the local Codex workflow and imported by MacOptimizer.

The app does not invoke Codex directly in this slice.

## Flow

1. Run a real scan with the existing Mac Optimization Agent.
2. Open **Codex > Open Codex Safe Review**.
3. Export the current scan. MacOptimizer atomically writes `scan.json`.
4. A local Codex session reads `scan.json`, performs read-only analysis, and writes `assessment.json` using schema version 1.
5. Import the assessment in MacOptimizer.
6. MacOptimizer validates every returned path, category, and size against the exact current scan result before displaying it.

## Assessment schema

```json
{
  "schemaVersion": 1,
  "assessedAt": "2026-09-16T00:00:00Z",
  "items": [
    {
      "path": "/Users/example/Library/Caches/app/cache.bin",
      "category": "userCache",
      "size": 1234,
      "recommendation": "trash",
      "reason": "Rebuildable application cache"
    }
  ]
}
```

Allowed recommendations:

- `keep`
- `review`
- `trash`

## Fail-closed rules

A Codex recommendation is advisory, not authorization.

MacOptimizer rejects assessments that:

- use an unsupported schema version;
- contain duplicate paths;
- invent a path not present in the current scan;
- change the scanned category or byte size.

A `trash` recommendation is forcibly downgraded to `review` for hard-protected locations, including system roots, user documents/media, Application Support, Preferences, Keychains, LaunchAgents, Containers, Group Containers, SSH/GPG material, and `.codex`.

## Explicit non-goals for this slice

There is no cleanup executor connected to the Codex review window.

The window cannot:

- delete or trash files;
- run `rm` or `sudo`;
- unload LaunchAgents or LaunchDaemons;
- kill processes;
- grant Full Disk Access;
- call `ignoreProtection` / `bypassProtection`;
- convert a model recommendation into an automatic action.

A future execution slice must remain separately gated and must reuse MacOptimizer's safety checks and explicit Owner confirmation.

## Privacy note

`scan.json` contains local file paths and metadata, not file contents. Export is an explicit Owner action. A Codex session may use a remote model depending on the user's Codex configuration, so the user should treat exported path names as data that may be processed by that configured service.
