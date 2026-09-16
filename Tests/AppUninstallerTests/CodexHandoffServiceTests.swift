import Foundation
import Testing
@testable import AppUninstaller

struct CodexHandoffServiceTests {
    @Test
    func protectedPathCannotBeAuthorizedForTrash() throws {
        let home = "/Users/tester"
        let finding = CodexHandoffFinding(
            path: "\(home)/Documents/important.txt",
            category: "largeFile",
            size: 42,
            modifiedAt: nil
        )
        let source = CodexHandoffEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            generatedAt: Date(timeIntervalSince1970: 0),
            sourceTool: "scan_large_files",
            findings: [finding]
        )
        let assessment = CodexAssessmentEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            assessedAt: Date(timeIntervalSince1970: 1),
            items: [
                .init(
                    path: finding.path,
                    category: finding.category,
                    size: finding.size,
                    recommendation: .trash,
                    reason: "model says removable"
                )
            ]
        )

        let validated = try CodexHandoffService.validate(assessment: assessment, against: source, home: home)

        #expect(validated.count == 1)
        #expect(validated[0].isProtected)
        #expect(validated[0].recommendation == .review)
    }

    @Test
    func assessmentCannotInventAPath() {
        let source = CodexHandoffEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            generatedAt: Date(),
            sourceTool: "scan_junk",
            findings: []
        )
        let assessment = CodexAssessmentEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            assessedAt: Date(),
            items: [
                .init(
                    path: "/tmp/invented",
                    category: "userCache",
                    size: 100,
                    recommendation: .trash,
                    reason: "invented"
                )
            ]
        )

        #expect(throws: CodexHandoffError.unknownFinding("/tmp/invented")) {
            try CodexHandoffService.validate(assessment: assessment, against: source, home: "/Users/tester")
        }
    }

    @Test
    func assessmentMustMatchCategoryAndSize() {
        let finding = CodexHandoffFinding(
            path: "/Users/tester/Library/Caches/example/cache.bin",
            category: "userCache",
            size: 100,
            modifiedAt: nil
        )
        let source = CodexHandoffEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            generatedAt: Date(),
            sourceTool: "scan_junk",
            findings: [finding]
        )
        let assessment = CodexAssessmentEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            assessedAt: Date(),
            items: [
                .init(
                    path: finding.path,
                    category: finding.category,
                    size: 101,
                    recommendation: .trash,
                    reason: "stale assessment"
                )
            ]
        )

        #expect(throws: CodexHandoffError.findingMismatch(finding.path)) {
            try CodexHandoffService.validate(assessment: assessment, against: source, home: "/Users/tester")
        }
    }

    @Test
    func cacheRecommendationCanRemainTrashWhenNotProtected() throws {
        let finding = CodexHandoffFinding(
            path: "/Users/tester/Library/Caches/example/cache.bin",
            category: "userCache",
            size: 100,
            modifiedAt: nil
        )
        let source = CodexHandoffEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            generatedAt: Date(),
            sourceTool: "scan_junk",
            findings: [finding]
        )
        let assessment = CodexAssessmentEnvelope(
            schemaVersion: CodexHandoffService.schemaVersion,
            assessedAt: Date(),
            items: [
                .init(
                    path: finding.path,
                    category: finding.category,
                    size: finding.size,
                    recommendation: .trash,
                    reason: "rebuildable cache"
                )
            ]
        )

        let validated = try CodexHandoffService.validate(assessment: assessment, against: source, home: "/Users/tester")

        #expect(validated[0].recommendation == .trash)
        #expect(!validated[0].isProtected)
    }
}
