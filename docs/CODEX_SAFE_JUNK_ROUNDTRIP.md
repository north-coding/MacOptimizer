# Codex Safe Junk Round Trip

This node removes an unnecessary dependency on the remote AI agent for creating a Codex handoff scan.

## Purpose

The Codex Safe Review window may start one local read-only junk scan directly before export.

The scan uses the existing `MacMaintenanceAgentService.scan_junk` path with `olderThanDays = 7`.

It inspects only the existing junk roots used by `MacMaintenanceAgentService`:

- `~/Library/Caches`
- `~/Library/Logs`
- `~/Library/Application Support/CrashReporter`
- `~/Library/Saved Application State`
- `/Library/Caches`
- `/Library/Logs`

This action does not call `prepare_cleanup` or `confirmCleanup` and does not delete, trash, quarantine, kill, unload, elevate, or change permissions.

## First real round trip

1. Open **Codex > Open Codex Safe Review**.
2. Choose **Run Safe Junk Scan**.
3. Export the resulting `scan.json`.
4. Local Codex reads `scan.json` and writes `assessment.json` only.
5. Import the assessment in the same review window.
6. Review `keep / review / trash` recommendations.

No recommendation is executable in this node.
