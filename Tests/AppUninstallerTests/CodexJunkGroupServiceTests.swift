import Foundation
import Testing
@testable import AppUninstaller

struct CodexJunkGroupServiceTests {
    private let home = "/Users/tester"

    @Test
    func groupsUserCacheByFirstDirectoryBelowCacheRoot() throws {
        let report = junkReport([
            finding("/Users/tester/Library/Caches/com.example.alpha/a.bin", .userCache, 100, 100),
            finding("/Users/tester/Library/Caches/com.example.alpha/sub/b.bin", .userCache, 200, 200),
            finding("/Users/tester/Library/Caches/com.example.beta/c.bin", .userCache, 300, 300)
        ])

        let envelope = try CodexJunkGroupService.makeEnvelope(
            from: report,
            generatedAt: Date(timeIntervalSince1970: 999),
            home: home
        )

        #expect(envelope.sourceFindingCount == 3)
        #expect(envelope.sourceBytes == 600)
        #expect(envelope.groups.count == 2)
        #expect(envelope.groups[0].rootPath == "/Users/tester/Library/Caches/com.example.alpha" || envelope.groups[0].rootPath == "/Users/tester/Library/Caches/com.example.beta")

        let alpha = try #require(envelope.groups.first { $0.rootPath.hasSuffix("/com.example.alpha") })
        #expect(alpha.fileCount == 2)
        #expect(alpha.totalSize == 300)
        #expect(alpha.oldestModifiedAt == Date(timeIntervalSince1970: 100))
        #expect(alpha.newestModifiedAt == Date(timeIntervalSince1970: 200))
        #expect(!alpha.isHardProtected)
    }

    @Test
    func directFilesBelowCategoryRootShareOneGroup() throws {
        let report = junkReport([
            finding("/Users/tester/Library/Logs/one.log", .userLog, 10, 100),
            finding("/Users/tester/Library/Logs/two.log", .userLog, 20, 200)
        ])

        let groups = CodexJunkGroupService.groups(from: report, home: home)

        #expect(groups.count == 1)
        #expect(groups[0].rootPath == "/Users/tester/Library/Logs")
        #expect(groups[0].fileCount == 2)
        #expect(groups[0].totalSize == 30)
    }

    @Test
    func systemGroupsAreHardProtectedAndTrashDowngradesToReview() throws {
        let report = junkReport([
            finding("/Library/Caches/com.example.system/cache.bin", .systemCache, 500, 100)
        ])
        let source = try CodexJunkGroupService.makeEnvelope(from: report, home: home)
        let group = try #require(source.groups.first)
        #expect(group.isHardProtected)

        let assessment = CodexJunkGroupAssessmentEnvelope(
            schemaVersion: CodexJunkGroupService.schemaVersion,
            assessedAt: Date(),
            items: [assessmentItem(group, recommendation: .trash)]
        )

        let validated = try CodexJunkGroupService.validate(assessment: assessment, against: source)
        #expect(validated.count == 1)
        #expect(validated[0].recommendation == .review)
    }

    @Test
    func assessmentCannotInventOrMutateAGroup() throws {
        let report = junkReport([
            finding("/Users/tester/Library/Caches/com.example/cache.bin", .userCache, 100, 100)
        ])
        let source = try CodexJunkGroupService.makeEnvelope(from: report, home: home)
        let group = try #require(source.groups.first)

        let invented = CodexJunkGroupAssessmentEnvelope(
            schemaVersion: CodexJunkGroupService.schemaVersion,
            assessedAt: Date(),
            items: [
                .init(
                    groupID: "userCache|/invented",
                    rootPath: "/invented",
                    category: group.category,
                    fileCount: group.fileCount,
                    totalSize: group.totalSize,
                    recommendation: .review,
                    reason: "invented"
                )
            ]
        )
        #expect(throws: CodexJunkGroupError.unknownGroup("userCache|/invented")) {
            try CodexJunkGroupService.validate(assessment: invented, against: source)
        }

        let mutated = CodexJunkGroupAssessmentEnvelope(
            schemaVersion: CodexJunkGroupService.schemaVersion,
            assessedAt: Date(),
            items: [
                .init(
                    groupID: group.id,
                    rootPath: group.rootPath,
                    category: group.category,
                    fileCount: group.fileCount,
                    totalSize: group.totalSize + 1,
                    recommendation: .trash,
                    reason: "stale"
                )
            ]
        )
        #expect(throws: CodexJunkGroupError.groupMismatch(group.id)) {
            try CodexJunkGroupService.validate(assessment: mutated, against: source)
        }
    }

    @Test
    func workspaceRoundTripUsesGroupFilesWithoutTouchingRawProtocol() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexJunkGroupServiceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)

        let report = junkReport([
            finding(temp.appendingPathComponent("Library/Caches/com.example/a.bin").path, .userCache, 100, 100),
            finding(temp.appendingPathComponent("Library/Caches/com.example/b.bin").path, .userCache, 200, 200)
        ])
        let groupsURL = try CodexJunkGroupWorkspace.export(report: report, home: temp)
        #expect(groupsURL.lastPathComponent == "groups.json")
        #expect(FileManager.default.fileExists(atPath: groupsURL.path))
        #expect(!FileManager.default.fileExists(atPath: CodexHandoffWorkspace.scanURL(home: temp).path))

        let source = try CodexJunkGroupService.makeEnvelope(from: report, home: temp.path)
        let group = try #require(source.groups.first)
        let assessment = CodexJunkGroupAssessmentEnvelope(
            schemaVersion: CodexJunkGroupService.schemaVersion,
            assessedAt: Date(),
            items: [assessmentItem(group, recommendation: .trash)]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(assessment).write(to: CodexJunkGroupWorkspace.assessmentURL(home: temp), options: .atomic)

        let validated = try CodexJunkGroupWorkspace.importAssessment(report: report, home: temp)
        #expect(validated.count == 1)
        #expect(validated[0].group.totalSize == 300)
        #expect(validated[0].recommendation == .trash)
    }

    private func junkReport(_ findings: [MacAgentFinding]) -> MacAgentToolReport {
        .init(tool: .scanJunk, findings: findings, facts: ["older_than_days": "7"])
    }

    private func finding(
        _ path: String,
        _ category: MacAgentFindingCategory,
        _ size: Int64,
        _ modified: TimeInterval
    ) -> MacAgentFinding {
        .init(
            path: path,
            category: category,
            size: size,
            modifiedAt: Date(timeIntervalSince1970: modified)
        )
    }

    private func assessmentItem(
        _ group: CodexJunkGroup,
        recommendation: CodexRecommendation
    ) -> CodexJunkGroupAssessmentItem {
        .init(
            groupID: group.id,
            rootPath: group.rootPath,
            category: group.category,
            fileCount: group.fileCount,
            totalSize: group.totalSize,
            recommendation: recommendation,
            reason: "metadata-only assessment"
        )
    }
}