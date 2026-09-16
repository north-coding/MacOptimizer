import Foundation

/// Hard local policy for the remote-provider AI Assistant.
///
/// The assistant may choose observational tools, but it never receives cleanup
/// authority. This check is enforced after model decoding and is independent of
/// prompt wording or provider behavior.
enum AIAssistantReadOnlyPolicy {
    static func allows(_ tool: MacAgentTool) -> Bool {
        switch tool {
        case .scanJunk,
             .scanLargeFiles,
             .scanDuplicates,
             .inspectStorage,
             .inspectSystem,
             .inspectStartup,
             .listResults,
             .finish:
            return true
        case .prepareCleanup:
            return false
        }
    }

    static func sanitize(_ decision: MacAgentDecision, hasReport: Bool) -> MacAgentDecision {
        guard !allows(decision.tool) else { return decision }

        if hasReport {
            return MacAgentDecision(tool: .finish, arguments: nil, message: nil)
        }

        return MacAgentDecision(
            tool: .scanJunk,
            arguments: MacAgentArguments(minimumSizeMB: nil, olderThanDays: 3),
            message: nil
        )
    }
}
