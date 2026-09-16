import Testing
@testable import AppUninstaller

struct AIAssistantReadOnlyPolicyTests {
    @Test
    func observationalToolsRemainAllowed() {
        let allowed: [MacAgentTool] = [
            .scanJunk,
            .scanLargeFiles,
            .scanDuplicates,
            .inspectStorage,
            .inspectSystem,
            .inspectStartup,
            .listResults,
            .finish
        ]

        for tool in allowed {
            #expect(AIAssistantReadOnlyPolicy.allows(tool))
        }
    }

    @Test
    func cleanupPreparationIsNeverAllowed() {
        #expect(!AIAssistantReadOnlyPolicy.allows(.prepareCleanup))
    }

    @Test
    func cleanupRequestBeforeAnyReportFallsBackToReadOnlyScan() {
        let original = MacAgentDecision(
            tool: .prepareCleanup,
            arguments: MacAgentArguments(minimumSizeMB: nil, olderThanDays: 3),
            message: "cleanup"
        )

        let sanitized = AIAssistantReadOnlyPolicy.sanitize(original, hasReport: false)

        #expect(sanitized.tool == .scanJunk)
        #expect(sanitized.arguments?.olderThanDays == 3)
        #expect(sanitized.message == nil)
    }

    @Test
    func cleanupRequestAfterAReportFinishesInsteadOfExecuting() {
        let original = MacAgentDecision(
            tool: .prepareCleanup,
            arguments: nil,
            message: "cleanup"
        )

        let sanitized = AIAssistantReadOnlyPolicy.sanitize(original, hasReport: true)

        #expect(sanitized.tool == .finish)
        #expect(sanitized.arguments == nil)
        #expect(sanitized.message == nil)
    }

    @Test
    func allowedDecisionPassesThroughUnchanged() {
        let original = MacAgentDecision(
            tool: .inspectStorage,
            arguments: MacAgentArguments(minimumSizeMB: 123, olderThanDays: 9),
            message: "inspect"
        )

        let sanitized = AIAssistantReadOnlyPolicy.sanitize(original, hasReport: false)

        #expect(sanitized.tool == .inspectStorage)
        #expect(sanitized.arguments?.minimumSizeMB == 123)
        #expect(sanitized.arguments?.olderThanDays == 9)
        #expect(sanitized.message == "inspect")
    }
}
