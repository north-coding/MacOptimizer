import Foundation

/// A read-only handoff contract between MacOptimizer and a local Codex session.
///
/// Important: a Codex assessment is advisory only. This service never deletes files
/// and never grants authorization to bypass MacOptimizer safety checks.
enum CodexRecommendation: String, Codable, CaseIterable, Sendable {
    case keep
    case review
    case trash
}

struct CodexHandoffFinding: Codable, Hashable, Sendable {
    let path: String
    let category: String
    let size: Int64
    let modifiedAt: Date?
}

struct CodexHandoffEnvelope: Codable, Sendable {
    let schemaVersion: Int
    let generatedAt: Date
    let sourceTool: String
    let findings: [CodexHandoffFinding]
}

struct CodexAssessmentItem: Codable, Sendable {
    let path: String
    let category: String
    let size: Int64
    let recommendation: CodexRecommendation
    let reason: String
}

struct CodexAssessmentEnvelope: Codable, Sendable {
    let schemaVersion: Int
    let assessedAt: Date
    let items: [CodexAssessmentItem]
}

struct ValidatedCodexAssessment: Sendable {
    let finding: CodexHandoffFinding
    let recommendation: CodexRecommendation
    let reason: String
    let isProtected: Bool
}

enum CodexHandoffError: Error, Equatable {
    case unsupportedSchema(Int)
    case duplicateAssessmentPath(String)
    case unknownFinding(String)
    case findingMismatch(String)
}

enum CodexHandoffWorkspaceError: Error, Equatable {
    case noScanResults
    case assessmentMissing(String)
}

extension CodexHandoffWorkspaceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noScanResults:
            return "There is no scan result available for Codex handoff."
        case .assessmentMissing(let path):
            return "No Codex assessment file was found at \(path)."
        }
    }
}

enum CodexHandoffService {
    static let schemaVersion = 1

    /// Paths Codex may analyze but may never authorize for automatic cleanup.
    /// Keep this list intentionally conservative for a long-running owner Mac.
    static func isHardProtectedPath(_ rawPath: String, home: String = FileManager.default.homeDirectoryForCurrentUser.path) -> Bool {
        let path = URL(fileURLWithPath: rawPath).standardizedFileURL.path
        let roots = [
            "/System",
            "/Library",
            "/Applications",
            "/usr",
            "/bin",
            "/sbin",
            "/private",
            "\(home)/Documents",
            "\(home)/Desktop",
            "\(home)/Movies",
            "\(home)/Music",
            "\(home)/Pictures",
            "\(home)/Library/Application Support",
            "\(home)/Library/Preferences",
            "\(home)/Library/Keychains",
            "\(home)/Library/LaunchAgents",
            "\(home)/Library/Containers",
            "\(home)/Library/Group Containers",
            "\(home)/.ssh",
            "\(home)/.gnupg",
            "\(home)/.codex"
        ].map { URL(fileURLWithPath: $0).standardizedFileURL.path }

        return roots.contains { root in
            path == root || path.hasPrefix(root + "/")
        }
    }

    static func makeEnvelope(from report: MacAgentToolReport, generatedAt: Date = Date()) -> CodexHandoffEnvelope {
        CodexHandoffEnvelope(
            schemaVersion: schemaVersion,
            generatedAt: generatedAt,
            sourceTool: report.tool.rawValue,
            findings: report.findings.map {
                CodexHandoffFinding(
                    path: URL(fileURLWithPath: $0.path).standardizedFileURL.path,
                    category: $0.category.rawValue,
                    size: $0.size,
                    modifiedAt: $0.modifiedAt
                )
            }
        )
    }

    static func encode(_ envelope: CodexHandoffEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(envelope)
    }

    static func decodeAssessment(_ data: Data) throws -> CodexAssessmentEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(CodexAssessmentEnvelope.self, from: data)
        guard envelope.schemaVersion == schemaVersion else {
            throw CodexHandoffError.unsupportedSchema(envelope.schemaVersion)
        }
        return envelope
    }

    /// Validates Codex output against the exact exported findings.
    /// A protected path is always downgraded to `.review`; no model output can override this.
    static func validate(
        assessment: CodexAssessmentEnvelope,
        against source: CodexHandoffEnvelope,
        home: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) throws -> [ValidatedCodexAssessment] {
        guard assessment.schemaVersion == schemaVersion else {
            throw CodexHandoffError.unsupportedSchema(assessment.schemaVersion)
        }

        let sourceByPath = Dictionary(uniqueKeysWithValues: source.findings.map { ($0.path, $0) })
        var seen = Set<String>()
        var result: [ValidatedCodexAssessment] = []

        for item in assessment.items {
            let normalizedPath = URL(fileURLWithPath: item.path).standardizedFileURL.path
            guard seen.insert(normalizedPath).inserted else {
                throw CodexHandoffError.duplicateAssessmentPath(normalizedPath)
            }
            guard let finding = sourceByPath[normalizedPath] else {
                throw CodexHandoffError.unknownFinding(normalizedPath)
            }
            guard finding.category == item.category, finding.size == item.size else {
                throw CodexHandoffError.findingMismatch(normalizedPath)
            }

            let protected = isHardProtectedPath(normalizedPath, home: home)
            result.append(
                ValidatedCodexAssessment(
                    finding: finding,
                    recommendation: protected ? .review : item.recommendation,
                    reason: item.reason,
                    isProtected: protected
                )
            )
        }

        return result
    }
}

/// Deterministic local file workspace used to exchange one scan and one assessment
/// with a local Codex session. It performs file I/O only; it never cleans or deletes.
enum CodexHandoffWorkspace {
    static let directoryName = "MacOptimizer-Codex-Handoff"
    static let scanFileName = "scan.json"
    static let assessmentFileName = "assessment.json"

    static func directoryURL(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        home
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    static func scanURL(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        directoryURL(home: home).appendingPathComponent(scanFileName, isDirectory: false)
    }

    static func assessmentURL(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        directoryURL(home: home).appendingPathComponent(assessmentFileName, isDirectory: false)
    }

    @discardableResult
    static func export(
        report: MacAgentToolReport,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) throws -> URL {
        guard !report.findings.isEmpty else {
            throw CodexHandoffWorkspaceError.noScanResults
        }

        let directory = directoryURL(home: home)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let data = try CodexHandoffService.encode(CodexHandoffService.makeEnvelope(from: report))
        let url = scanURL(home: home)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func importAssessment(
        report: MacAgentToolReport,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) throws -> [ValidatedCodexAssessment] {
        guard !report.findings.isEmpty else {
            throw CodexHandoffWorkspaceError.noScanResults
        }

        let url = assessmentURL(home: home)
        guard fileManager.fileExists(atPath: url.path) else {
            throw CodexHandoffWorkspaceError.assessmentMissing(url.path)
        }

        let data = try Data(contentsOf: url)
        let assessment = try CodexHandoffService.decodeAssessment(data)
        let source = CodexHandoffService.makeEnvelope(from: report)
        return try CodexHandoffService.validate(
            assessment: assessment,
            against: source,
            home: home.standardizedFileURL.path
        )
    }
}
