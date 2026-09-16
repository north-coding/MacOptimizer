import Foundation
import Testing
@testable import AppUninstaller

struct CodexHandoffWorkspaceTests {
    @Test
    func exportWritesDeterministicScanFile() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }

        let finding = MacAgentFinding(
            path: home.appendingPathComponent("Library/Caches/example/cache.bin").path,
            category: .userCache,
            size: 512,
            modifiedAt: Date(timeIntervalSince1970: 10)
        )
        let report = MacAgentToolReport(
            tool: .scanJunk,
            findings: [finding],
            facts: ["older_than_days": "3"]
        )

        let url = try CodexHandoffWorkspace.export(report: report, home: home)

        #expect(url == CodexHandoffWorkspace.scanURL(home: home))
        #expect(FileManager.default.fileExists(atPath: url.path))

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(CodexHandoffEnvelope.self, from: data)

        #expect(envelope.schemaVersion == CodexHandoffService.schemaVersion)
        #expect(envelope.sourceTool == MacAgentTool.scanJunk.rawValue)
        #expect(envelope.findings.count == 1)
        #expect(envelope.findings[0].path == finding.path)
        #expect(envelope.findings[0].size == 512)
    }

    @Test
    func importValidatesAssessmentAgainstCurrentReport() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }

        let finding = MacAgentFinding(
            path: home.appendingPathComponent("Library/Caches/example/cache.bin").path,
            category: .userCache,
            size: 1_024,
            modifiedAt: nil
        )
        let report = MacAgentToolReport(tool: .scanJunk, findings: [finding], facts: [:])
        _ = try CodexHandoffWorkspace.export(report: report, home: home)

        try writeAssessment(
            .init(
                schemaVersion: CodexHandoffService.schemaVersion,
                assessedAt: Date(timeIntervalSince1970: 20),
                items: [
                    .init(
                        path: finding.path,
                        category: finding.category.rawValue,
                        size: finding.size,
                        recommendation: .trash,
                        reason: "rebuildable cache"
                    )
                ]
            ),
            home: home
        )

        let validated = try CodexHandoffWorkspace.importAssessment(report: report, home: home)

        #expect(validated.count == 1)
        #expect(validated[0].recommendation == .trash)
        #expect(!validated[0].isProtected)
    }

    @Test
    func workspaceStillDowngradesProtectedTrashRecommendation() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }

        let finding = MacAgentFinding(
            path: home.appendingPathComponent("Documents/important.txt").path,
            category: .largeFile,
            size: 4_096,
            modifiedAt: nil
        )
        let report = MacAgentToolReport(tool: .scanLargeFiles, findings: [finding], facts: [:])
        _ = try CodexHandoffWorkspace.export(report: report, home: home)

        try writeAssessment(
            .init(
                schemaVersion: CodexHandoffService.schemaVersion,
                assessedAt: Date(timeIntervalSince1970: 30),
                items: [
                    .init(
                        path: finding.path,
                        category: finding.category.rawValue,
                        size: finding.size,
                        recommendation: .trash,
                        reason: "model says removable"
                    )
                ]
            ),
            home: home
        )

        let validated = try CodexHandoffWorkspace.importAssessment(report: report, home: home)

        #expect(validated.count == 1)
        #expect(validated[0].recommendation == .review)
        #expect(validated[0].isProtected)
    }

    @Test
    func importFailsWhenAssessmentFileDoesNotExist() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }

        let finding = MacAgentFinding(
            path: home.appendingPathComponent("Library/Logs/example.log").path,
            category: .userLog,
            size: 64,
            modifiedAt: nil
        )
        let report = MacAgentToolReport(tool: .scanJunk, findings: [finding], facts: [:])

        let expectedPath = CodexHandoffWorkspace.assessmentURL(home: home).path
        #expect(throws: CodexHandoffWorkspaceError.assessmentMissing(expectedPath)) {
            try CodexHandoffWorkspace.importAssessment(report: report, home: home)
        }
    }

    private func temporaryHome() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("MacOptimizer-Codex-\(UUID().uuidString)", isDirectory: true)
    }

    private func writeAssessment(_ assessment: CodexAssessmentEnvelope, home: URL) throws {
        let directory = CodexHandoffWorkspace.directoryURL(home: home)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(assessment)
        try data.write(to: CodexHandoffWorkspace.assessmentURL(home: home), options: .atomic)
    }
}
