import AppKit
import SwiftUI

@MainActor
final class CodexJunkGroupWindowController {
    static let shared = CodexJunkGroupWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 940, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Junk Group Review"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = NSHostingController(rootView: CodexJunkGroupReviewView())
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct CodexJunkGroupReviewView: View {
    @ObservedObject private var maintenanceAgent = MacMaintenanceAgentService.shared
    @ObservedObject private var loc = LocalizationManager.shared

    @State private var validated: [ValidatedCodexJunkGroupAssessment] = []
    @State private var statusMessage = ""
    @State private var statusIsError = false
    @State private var isScanning = false
    @State private var expandedGroupIDs = Set<String>()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            scanSummary
            actionBar
            assessmentSummary
            groupList
        }
        .padding(22)
        .frame(minWidth: 800, minHeight: 580)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(t("垃圾缓存分组审阅", "垃圾快取分組審閱", "Junk Cache Group Review", "ジャンクキャッシュのグループレビュー", "정크 캐시 그룹 검토", "Групповая проверка кэша"))
                .font(.system(size: 22, weight: .semibold))
            Text(t(
                "先按 App / 顶层缓存目录聚合，再让 Codex 判断组。组级建议仍然只是审阅，不会删除文件。",
                "先依 App / 頂層快取目錄分組，再讓 Codex 判斷群組。群組建議仍僅供審閱，不會刪除檔案。",
                "Aggregate by app/top-level cache directory before Codex assessment. Group recommendations are still advisory only and cannot delete files.",
                "App／トップレベルのキャッシュディレクトリ単位で集約してから Codex が評価します。提案はレビュー専用で削除は行いません。",
                "앱/최상위 캐시 디렉터리별로 집계한 뒤 Codex가 평가합니다. 그룹 권고는 검토 전용이며 파일을 삭제하지 않습니다.",
                "Сначала файлы объединяются по приложению или верхнему каталогу кэша, затем их оценивает Codex. Рекомендации не удаляют файлы."
            ))
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
    }

    private var scanSummary: some View {
        GroupBox {
            HStack(spacing: 14) {
                Image(systemName: groups.isEmpty ? "tray" : "square.stack.3d.up.fill")
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 4) {
                    if let report = junkReport, !groups.isEmpty {
                        Text(t("当前垃圾扫描", "目前垃圾掃描", "Current junk scan", "現在のジャンクスキャン", "현재 정크 검사", "Текущее сканирование мусора"))
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(report.count) files → \(groups.count) groups · \(ByteCountFormatter.string(fromByteCount: report.bytes, countStyle: .file))")
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text(t("还没有可分组的垃圾扫描", "尚無可分組的垃圾掃描", "No junk scan is available for grouping", "グループ化できるジャンクスキャンがありません", "그룹화할 정크 검사가 없습니다", "Нет сканирования мусора для группировки"))
                            .font(.system(size: 13, weight: .semibold))
                        Text(t("运行只读安全垃圾扫描后，结果会按缓存根目录聚合。", "執行唯讀安全垃圾掃描後，結果會依快取根目錄分組。", "Run the read-only safe junk scan to aggregate results by cache root.", "読み取り専用の安全スキャン後、キャッシュルート単位で集約します。", "읽기 전용 안전 검사를 실행하면 캐시 루트별로 집계됩니다.", "Запустите безопасное сканирование только для чтения, чтобы сгруппировать результаты."))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(4)
        }
    }

    private var actionBar: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Button {
                    Task { await runSafeJunkScan() }
                } label: {
                    if isScanning {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(t("扫描中…", "掃描中…", "Scanning…", "スキャン中…", "검사 중…", "Сканирование…"))
                        }
                    } else {
                        Label(t("运行安全垃圾扫描", "執行安全垃圾掃描", "Run Safe Junk Scan", "安全ジャンクスキャン", "안전 정크 검사", "Безопасное сканирование"), systemImage: "magnifyingglass")
                    }
                }
                .disabled(isScanning)

                Button(action: exportGroups) {
                    Label(t("导出分组", "匯出分組", "Export Groups", "グループを書き出す", "그룹 내보내기", "Экспорт групп"), systemImage: "square.and.arrow.up")
                }
                .disabled(groups.isEmpty || isScanning)

                Button(action: importGroupAssessment) {
                    Label(t("导入分组评估", "匯入分組評估", "Import Group Assessment", "グループ評価を読み込む", "그룹 평가 가져오기", "Импорт оценки групп"), systemImage: "square.and.arrow.down")
                }
                .disabled(groups.isEmpty || isScanning)

                Button(action: openWorkspaceFolder) {
                    Label(t("打开目录", "開啟目錄", "Open Folder", "フォルダを開く", "폴더 열기", "Открыть папку"), systemImage: "folder")
                }
                Spacer()
            }

            Text(CodexHandoffWorkspace.directoryURL().path)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if !statusMessage.isEmpty {
                Label(statusMessage, systemImage: statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 11.5))
                    .foregroundStyle(statusIsError ? .orange : .secondary)
                    .textSelection(.enabled)
            }
        }
    }

    @ViewBuilder
    private var assessmentSummary: some View {
        if !validated.isEmpty {
            HStack(spacing: 14) {
                summaryPill("keep", count: count(.keep))
                summaryPill("review", count: count(.review))
                summaryPill("trash", count: count(.trash))
                Spacer()
                Text(t("组级建议 · 未连接执行器", "群組建議 · 未連接執行器", "Group advisory only · no executor connected", "グループ提案のみ・実行機構なし", "그룹 권고 전용 · 실행기 없음", "Только групповые рекомендации · без исполнителя"))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var groupList: some View {
        GroupBox(t("缓存组", "快取群組", "Cache groups", "キャッシュグループ", "캐시 그룹", "Группы кэша")) {
            if groups.isEmpty {
                Text(t("运行一次安全垃圾扫描后，这里会显示聚合结果。", "執行一次安全垃圾掃描後，這裡會顯示分組結果。", "Run a safe junk scan to see aggregated groups here.", "安全ジャンクスキャンを実行すると集約結果が表示されます。", "안전 정크 검사를 실행하면 집계 결과가 표시됩니다.", "Запустите безопасное сканирование, чтобы увидеть группы."))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(10)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(groups) { group in
                            groupRow(group)
                            Divider()
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func groupRow(_ group: CodexJunkGroup) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedGroupIDs.contains(group.id) },
                set: { expanded in
                    if expanded { expandedGroupIDs.insert(group.id) }
                    else { expandedGroupIDs.remove(group.id) }
                }
            )
        ) {
            let members = displayedMembers(for: group)
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(members.enumerated()), id: \.element.id) { _, finding in
                    HStack(spacing: 8) {
                        Text(finding.path)
                            .font(.system(size: 10.5, design: .monospaced))
                            .lineLimit(1)
                            .textSelection(.enabled)
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: finding.size, countStyle: .file))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                if group.fileCount > members.count {
                    Text(t("仅显示最大的 ", "僅顯示最大的 ", "Showing the largest ", "最大の ", "가장 큰 ", "Показаны крупнейшие ") + "\(members.count) / \(group.fileCount)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 18)
            .padding(.top, 6)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                recommendationBadge(for: group)
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.rootPath)
                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                        .lineLimit(2)
                        .textSelection(.enabled)
                    HStack(spacing: 8) {
                        Text(group.category)
                        Text("\(group.fileCount) files")
                        Text(ByteCountFormatter.string(fromByteCount: group.totalSize, countStyle: .file))
                        if group.isHardProtected {
                            Text(t("受保护", "受保護", "protected", "保護対象", "보호됨", "защищено"))
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    if let assessment = validated.first(where: { $0.group.id == group.id }) {
                        Text(assessment.reason)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func recommendationBadge(for group: CodexJunkGroup) -> some View {
        if let assessment = validated.first(where: { $0.group.id == group.id }) {
            Text(assessment.recommendation.rawValue.uppercased())
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .frame(width: 54, alignment: .leading)
        } else {
            Text("GROUP")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 54, alignment: .leading)
        }
    }

    private var junkReport: MacAgentToolReport? {
        guard let report = maintenanceAgent.lastReport, report.tool == .scanJunk else { return nil }
        return report
    }

    private var groups: [CodexJunkGroup] {
        guard let report = junkReport else { return [] }
        return CodexJunkGroupService.groups(from: report)
    }

    private var membersByGroupID: [String: [MacAgentFinding]] {
        guard let report = junkReport else { return [:] }
        return CodexJunkGroupService.membersByGroupID(from: report)
    }

    private func displayedMembers(for group: CodexJunkGroup) -> [MacAgentFinding] {
        Array((membersByGroupID[group.id] ?? []).sorted { $0.size > $1.size }.prefix(100))
    }

    private func count(_ recommendation: CodexRecommendation) -> Int {
        validated.filter { $0.recommendation == recommendation }.count
    }

    private func summaryPill(_ title: String, count: Int) -> some View {
        Text("\(title) \(count)")
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(.quaternary, in: Capsule())
    }

    private func runSafeJunkScan() async {
        isScanning = true
        validated = []
        statusIsError = false
        statusMessage = t("正在执行只读安全垃圾扫描…", "正在執行唯讀安全垃圾掃描…", "Running read-only safe junk scan…", "読み取り専用スキャンを実行中…", "읽기 전용 안전 검사 실행 중…", "Выполняется сканирование только для чтения…")
        defer { isScanning = false }

        let report = await maintenanceAgent.execute(
            .scanJunk,
            arguments: .init(minimumSizeMB: nil, olderThanDays: 7)
        )
        let groupCount = CodexJunkGroupService.groups(from: report).count
        statusMessage = t("扫描完成：", "掃描完成：", "Scan complete: ", "スキャン完了: ", "검사 완료: ", "Сканирование завершено: ")
            + "\(report.count) files → \(groupCount) groups · \(ByteCountFormatter.string(fromByteCount: report.bytes, countStyle: .file))"
    }

    private func exportGroups() {
        guard let report = junkReport else { return }
        do {
            _ = try CodexHandoffWorkspace.export(report: report)
            let groupsURL = try CodexJunkGroupWorkspace.export(report: report)
            validated = []
            statusIsError = false
            statusMessage = t("已导出原始扫描和分组：", "已匯出原始掃描與分組：", "Exported raw scan and groups: ", "生スキャンとグループを書き出しました: ", "원시 검사와 그룹 내보냄: ", "Экспортированы исходное сканирование и группы: ") + groupsURL.path
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func importGroupAssessment() {
        guard let report = junkReport else { return }
        do {
            validated = try CodexJunkGroupWorkspace.importAssessment(report: report)
            statusIsError = false
            statusMessage = t("分组评估已通过本机安全校验。", "分組評估已通過本機安全校驗。", "Group assessment passed local safety validation.", "グループ評価はローカル安全検証に合格しました。", "그룹 평가가 로컬 안전 검증을 통과했습니다.", "Оценка групп прошла локальную проверку безопасности.")
        } catch {
            validated = []
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func openWorkspaceFolder() {
        let directory = CodexHandoffWorkspace.directoryURL()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            NSWorkspace.shared.open(directory)
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func t(_ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String, _ ru: String) -> String {
        loc.text(
            simplifiedChinese: zh,
            traditionalChinese: zhHant,
            english: en,
            japanese: ja,
            korean: ko,
            russian: ru
        )
    }
}