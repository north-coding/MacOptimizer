import Foundation

struct CodexJunkGroup: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let rootPath: String
    let category: String
    let fileCount: Int
    let totalSize: Int64
    let oldestModifiedAt: Date?
    let newestModifiedAt: Date?
    let isHardProtected: Bool
}

struct CodexJunkGroupEnvelope: Codable, Sendable {
    let schemaVersion: Int
    let generatedAt: Date
    let sourceTool: String
    let sourceFindingCount: Int
    let sourceBytes: Int64
    let groups: [CodexJunkGroup]
}

struct CodexJunkGroupAssessmentItem: Codable, Sendable {
    let groupID: String
    let rootPath: String
    let category: String
    let fileCount: Int
    let totalSize: Int64
    let recommendation: CodexRecommendation
    let reason: String
}

struct CodexJunkGroupAssessmentEnvelope: Codable, Sendable {
    let schemaVersion: Int
    let assessedAt: Date
    let items: [CodexJunkGroupAssessmentItem]
}

struct ValidatedCodexJunkGroupAssessment: Sendable {
    let group: CodexJunkGroup
    let recommendation: CodexRecommendation
    let reason: String
}

enum CodexJunkGroupError: Error, Equatable {
    case unsupportedTool(String)
    case unsupportedSchema(Int)
    case duplicateGroupID(String)
    case unknownGroup(String)
    case groupMismatch(String)
    case noGroups
    case assessmentMissing(String)
}

extension CodexJunkGroupError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unsupportedTool(let tool):
            return "Junk grouping only supports scan_junk reports, not \(tool)."
        case .unsupportedSchema(let version):
            return "Unsupported junk-group schema version: \(version)."
        case .duplicateGroupID(let id):
            return "Duplicate junk-group assessment id: \(id)."
        case .unknownGroup(let id):
            return "The assessment references an unknown junk group: \(id)."
        case .groupMismatch(let id):
            return "The assessment no longer matches the current junk group: \(id)."
        case .noGroups:
            return "There are no junk groups available for Codex handoff."
        case .assessmentMissing(let path):
            return "No Codex junk-group assessment file was found at \(path)."
        }
    }
}

enum CodexJunkGroupService {
    static let schemaVersion = 1

    private struct Accumulator {
        let id: String
        let rootPath: String
        let category: String
        var fileCount: Int
        var totalSize: Int64
        var oldestModifiedAt: Date?
        var newestModifiedAt: Date?
        let isHardProtected: Bool

        mutating func add(_ finding: MacAgentFinding) {
            fileCount += 1
            totalSize += finding.size
            if let modifiedAt = finding.modifiedAt {
                if oldestModifiedAt == nil || modifiedAt < oldestModifiedAt! {
                    oldestModifiedAt = modifiedAt
                }
                if newestModifiedAt == nil || modifiedAt > newestModifiedAt! {
                    newestModifiedAt = modifiedAt
                }
            }
        }

        var group: CodexJunkGroup {
            CodexJunkGroup(
                id: id,
                rootPath: rootPath,
                category: category,
                fileCount: fileCount,
                totalSize: totalSize,
                oldestModifiedAt: oldestModifiedAt,
                newestModifiedAt: newestModifiedAt,
                isHardProtected: isHardProtected
            )
        }
    }

    static func makeEnvelope(
        from report: MacAgentToolReport,
        generatedAt: Date = Date(),
        home: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) throws -> CodexJunkGroupEnvelope {
        guard report.tool == .scanJunk else {
            throw CodexJunkGroupError.unsupportedTool(report.tool.rawValue)
        }

        let groups = groups(from: report, home: home)
        guard !groups.isEmpty else { throw CodexJunkGroupError.noGroups }

        return CodexJunkGroupEnvelope(
            schemaVersion: schemaVersion,
            generatedAt: generatedAt,
            sourceTool: report.tool.rawValue,
            sourceFindingCount: report.count,
            sourceBytes: report.bytes,
            groups: groups
        )
    }

    static func groups(
        from report: MacAgentToolReport,
        home: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) -> [CodexJunkGroup] {
        guard report.tool == .scanJunk else { return [] }
        var accumulators: [String: Accumulator] = [:]

        for finding in report.findings {
            guard categoryRoot(for: finding.category, home: home) != nil else { continue }
            let rootPath = groupRootPath(for: finding, home: home)
            let id = groupID(category: finding.category.rawValue, rootPath: rootPath)
            if var existing = accumulators[id] {
                existing.add(finding)
                accumulators[id] = existing
            } else {
                var accumulator = Accumulator(
                    id: id,
                    rootPath: rootPath,
                    category: finding.category.rawValue,
                    fileCount: 0,
                    totalSize: 0,
                    oldestModifiedAt: nil,
                    newestModifiedAt: nil,
                    isHardProtected: CodexHandoffService.isHardProtectedPath(rootPath, home: home)
                )
                accumulator.add(finding)
                accumulators[id] = accumulator
            }
        }

        return accumulators.values
            .map(\.group)
            .sorted {
                if $0.totalSize == $1.totalSize {
                    return $0.rootPath.localizedStandardCompare($1.rootPath) == .orderedAscending
                }
                return $0.totalSize > $1.totalSize
            }
    }

    static func membersByGroupID(
        from report: MacAgentToolReport,
        home: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) -> [String: [MacAgentFinding]] {
        guard report.tool == .scanJunk else { return [:] }
        return Dictionary(grouping: report.findings) { finding in
            let rootPath = groupRootPath(for: finding, home: home)
            return groupID(category: finding.category.rawValue, rootPath: rootPath)
        }
    }

    static func groupRootPath(
        for finding: MacAgentFinding,
        home: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) -> String {
        let path = URL(fileURLWithPath: finding.path).standardizedFileURL.path
        guard let rawRoot = categoryRoot(for: finding.category, home: home) else {
            return URL(fileURLWithPath: path).deletingLastPathComponent().standardizedFileURL.path
        }
        let root = URL(fileURLWithPath: rawRoot).standardizedFileURL.path
        guard path == root || path.hasPrefix(root + "/") else {
            return URL(fileURLWithPath: path).deletingLastPathComponent().standardizedFileURL.path
        }

        let suffix = String(path.dropFirst(root.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = suffix.split(separator: "/", omittingEmptySubsequences: true)
        guard components.count >= 2, let first = components.first else {
            return root
        }
        return URL(fileURLWithPath: root).appendingPathComponent(String(first), isDirectory: true).standardizedFileURL.path
    }

    static func encode(_ envelope: CodexJunkGroupEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(envelope)
    }

    static func decodeAssessment(_ data: Data) throws -> CodexJunkGroupAssessmentEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(CodexJunkGroupAssessmentEnvelope.self, from: data)
        guard envelope.schemaVersion == schemaVersion else {
            throw CodexJunkGroupError.unsupportedSchema(envelope.schemaVersion)
        }
        return envelope
    }

    static func validate(
        assessment: CodexJunkGroupAssessmentEnvelope,
        against source: CodexJunkGroupEnvelope
    ) throws -> [ValidatedCodexJunkGroupAssessment] {
        guard assessment.schemaVersion == schemaVersion else {
            throw CodexJunkGroupError.unsupportedSchema(assessment.schemaVersion)
        }

        let groupsByID = Dictionary(uniqueKeysWithValues: source.groups.map { ($0.id, $0) })
        var seen = Set<String>()
        var result: [ValidatedCodexJunkGroupAssessment] = []

        for item in assessment.items {
            guard seen.insert(item.groupID).inserted else {
                throw CodexJunkGroupError.duplicateGroupID(item.groupID)
            }
            guard let group = groupsByID[item.groupID] else {
                throw CodexJunkGroupError.unknownGroup(item.groupID)
            }
            guard group.rootPath == URL(fileURLWithPath: item.rootPath).standardizedFileURL.path,
                  group.category == item.category,
                  group.fileCount == item.fileCount,
                  group.totalSize == item.totalSize else {
                throw CodexJunkGroupError.groupMismatch(item.groupID)
            }

            result.append(
                ValidatedCodexJunkGroupAssessment(
                    group: group,
                    recommendation: group.isHardProtected ? .review : item.recommendation,
                    reason: item.reason
                )
            )
        }

        return result
    }

    private static func groupID(category: String, rootPath: String) -> String {
        "\(category)|\(URL(fileURLWithPath: rootPath).standardizedFileURL.path)"
    }

    private static func categoryRoot(for category: MacAgentFindingCategory, home: String) -> String? {
        let normalizedHome = URL(fileURLWithPath: home).standardizedFileURL.path
        switch category {
        case .userCache:
            return "\(normalizedHome)/Library/Caches"
        case .userLog:
            return "\(normalizedHome)/Library/Logs"
        case .crashReport:
            return "\(normalizedHome)/Library/Application Support/CrashReporter"
        case .savedState:
            return "\(normalizedHome)/Library/Saved Application State"
        case .systemCache:
            return "/Library/Caches"
        case .systemLog:
            return "/Library/Logs"
        case .largeFile, .duplicateFile, .startupItem:
            return nil
        }
    }
}

enum CodexJunkGroupWorkspace {
    static let groupsFileName = "groups.json"
    static let assessmentFileName = "group-assessment.json"

    static func groupsURL(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        CodexHandoffWorkspace.directoryURL(home: home).appendingPathComponent(groupsFileName, isDirectory: false)
    }

    static func assessmentURL(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        CodexHandoffWorkspace.directoryURL(home: home).appendingPathComponent(assessmentFileName, isDirectory: false)
    }

    @discardableResult
    static func export(
        report: MacAgentToolReport,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) throws -> URL {
        let envelope = try CodexJunkGroupService.makeEnvelope(
            from: report,
            home: home.standardizedFileURL.path
        )
        let directory = CodexHandoffWorkspace.directoryURL(home: home)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try CodexJunkGroupService.encode(envelope)
        let url = groupsURL(home: home)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func importAssessment(
        report: MacAgentToolReport,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) throws -> [ValidatedCodexJunkGroupAssessment] {
        let source = try CodexJunkGroupService.makeEnvelope(
            from: report,
            home: home.standardizedFileURL.path
        )
        let url = assessmentURL(home: home)
        guard fileManager.fileExists(atPath: url.path) else {
            throw CodexJunkGroupError.assessmentMissing(url.path)
        }
        let assessment = try CodexJunkGroupService.decodeAssessment(Data(contentsOf: url))
        return try CodexJunkGroupService.validate(assessment: assessment, against: source)
    }
}