import AppKit
import SwiftUI

@MainActor
final class CodexRoundTripWindowController {
    static let shared = CodexRoundTripWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Codex Review"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = NSHostingController(rootView: CodexRoundTripReviewView())
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct CodexRoundTripReviewView: View {
    @ObservedObject private var maintenanceAgent = MacMaintenanceAgentService.shared
    @ObservedObject private var loc = LocalizationManager.shared

    @State private var validated: [ValidatedCodexAssessment] = []
    @State private var statusMessage = ""
    @State private var statusIsError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            scanCard
            actionBar
            resultSummary
            resultList
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t("Codex 安全审阅", "Codex 安全審閱", "Codex Safe Review", "Codex セーフレビュー", "Codex 안전 검토", "Безопасная проверка Codex"))
                .font(.system(size: 22, weight: .semibold))

            Text(t(
                "导出最近一次真实扫描，让本机 Codex 给出 keep / review / trash 建议；建议只用于审阅，不会执行删除。",
                "匯出最近一次真實掃描，讓本機 Codex 提供 keep / review / trash 建議；建議只供審閱，不會執行刪除。",
                "Export the latest real scan for local Codex analysis. Recommendations are review-only and cannot delete files.",
                "最新の実スキャンをローカル Codex に渡します。提案はレビュー専用で、ファイル削除は実行できません。",
                "최근 실제 검사 결과를 로컬 Codex에 전달합니다. 권고는 검토 전용이며 파일을 삭제할 수 없습니다.",
                "Экспортирует последний реальный результат сканирования для локального Codex. Рекомендации предназначены только для проверки и не удаляют файлы."
            ))
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
    }

    private var scanCard: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: reportAvailable ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 5) {
                    if let report = maintenanceAgent.lastReport {
                        Text(t("最近扫描", "最近掃描", "Latest scan", "最新スキャン", "최근 검사", "Последнее сканирование"))
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(report.tool.rawValue) · \(report.count) · \(ByteCountFormatter.string(fromByteCount: report.bytes, countStyle: .file))")
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text(t("还没有可导出的扫描结果", "尚無可匯出的掃描結果", "No scan result is available yet", "エクスポート可能なスキャン結果がありません", "내보낼 검사 결과가 아직 없습니다", "Нет результатов сканирования для экспорта"))
                            .font(.system(size: 13, weight: .semibold))
                        Text(t("先在 Mac 优化智能体中运行一次垃圾、大文件、重复文件或启动项扫描。", "請先在 Mac 最佳化智慧代理中執行一次垃圾、大型檔案、重複檔案或啟動項目掃描。", "Run a junk, large-file, duplicate, or startup scan in the Mac Optimization Agent first.", "まず Mac 最適化エージェントでジャンク、大容量ファイル、重複、または起動項目のスキャンを実行してください。", "먼저 Mac 최적화 에이전트에서 정크, 대용량 파일, 중복 파일 또는 시작 항목 검사를 실행하세요.", "Сначала запустите в агенте оптимизации Mac сканирование мусора, крупных файлов, дубликатов или элементов автозапуска."))
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button(action: exportCurrentScan) {
                    Label(t("导出给 Codex", "匯出給 Codex", "Export for Codex", "Codex 用に書き出す", "Codex용 내보내기", "Экспорт для Codex"), systemImage: "square.and.arrow.up")
                }
                .disabled(!reportAvailable)

                Button(action: importAssessment) {
                    Label(t("导入评估", "匯入評估", "Import assessment", "評価を読み込む", "평가 가져오기", "Импорт оценки"), systemImage: "square.and.arrow.down")
                }
                .disabled(!reportAvailable)

                Button(action: openWorkspaceFolder) {
                    Label(t("打开目录", "開啟目錄", "Open folder", "フォルダを開く", "폴더 열기", "Открыть папку"), systemImage: "folder")
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
    private var resultSummary: some View {
        if !validated.isEmpty {
            HStack(spacing: 16) {
                summaryPill("keep", count: count(.keep))
                summaryPill("review", count: count(.review))
                summaryPill("trash", count: count(.trash))
                Spacer()
                Text(t("仅建议 · 未连接执行器", "僅建議 · 未連接執行器", "Advisory only · no executor connected", "提案のみ・実行機構なし", "권고 전용 · 실행기 연결 안 됨", "Только рекомендации · исполнитель не подключён"))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var resultList: some View {
        if !validated.isEmpty {
            GroupBox(t("Codex 评估结果", "Codex 評估結果", "Codex assessment", "Codex 評価結果", "Codex 평가 결과", "Оценка Codex")) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(validated.enumerated()), id: \.offset) { _, item in
                            assessmentRow(item)
                            Divider()
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(minHeight: 180)
            }
        }
    }

    private func assessmentRow(_ item: ValidatedCodexAssessment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(item.recommendation.rawValue.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .frame(width: 58, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.finding.path)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(item.finding.category)
                    Text(ByteCountFormatter.string(fromByteCount: item.finding.size, countStyle: .file))
                    if item.isProtected {
                        Text(t("受保护", "受保護", "protected", "保護対象", "보호됨", "защищено"))
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

                Text(item.reason)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
    }

    private func summaryPill(_ title: String, count: Int) -> some View {
        Text("\(title) \(count)")
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(.quaternary, in: Capsule())
    }

    private var reportAvailable: Bool {
        guard let report = maintenanceAgent.lastReport else { return false }
        return !report.findings.isEmpty
    }

    private func count(_ recommendation: CodexRecommendation) -> Int {
        validated.filter { $0.recommendation == recommendation }.count
    }

    private func exportCurrentScan() {
        guard let report = maintenanceAgent.lastReport else { return }
        do {
            let url = try CodexHandoffWorkspace.export(report: report)
            validated = []
            statusIsError = false
            statusMessage = t("已导出：", "已匯出：", "Exported: ", "書き出しました: ", "내보냄: ", "Экспортировано: ") + url.path
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func importAssessment() {
        guard let report = maintenanceAgent.lastReport else { return }
        do {
            validated = try CodexHandoffWorkspace.importAssessment(report: report)
            statusIsError = false
            statusMessage = t("评估已通过本机安全校验。", "評估已通過本機安全校驗。", "Assessment passed local safety validation.", "評価はローカル安全検証に合格しました。", "평가가 로컬 안전 검증을 통과했습니다.", "Оценка прошла локальную проверку безопасности.")
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
        loc.text(simplifiedChinese: zh, traditionalChinese: zhHant, english: en, japanese: ja, korean: ko, russian: ru)
    }
}
