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
    @State private var isScanning = false

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
                "可直接运行一次只读安全垃圾扫描，再导出给本机 Codex；建议只用于审阅，不会执行删除。",
                "可直接執行一次唯讀安全垃圾掃描，再匯出給本機 Codex；建議只供審閱，不會執行刪除。",
                "Run a read-only safe junk scan, then export it for local Codex analysis. Recommendations are review-only and cannot delete files.",
                "読み取り専用の安全なジャンクスキャンを実行し、ローカル Codex に渡します。提案はレビュー専用で削除は実行しません。",
                "읽기 전용 안전 정크 검사를 실행한 뒤 로컬 Codex에 전달합니다. 권고는 검토 전용이며 삭제를 실행하지 않습니다.",
                "Запустите безопасное сканирование мусора только для чтения и передайте результат локальному Codex. Рекомендации предназначены только для проверки и не удаляют файлы."
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
                        Text(t(
                            "可直接运行安全垃圾扫描。它只读取缓存、日志、崩溃报告和 Saved Application State，不会执行清理。",
                            "可直接執行安全垃圾掃描。它只讀取快取、日誌、當機報告與 Saved Application State，不會執行清理。",
                            "Run the safe junk scan directly. It only reads caches, logs, crash reports, and Saved Application State; it does not clean anything.",
                            "安全なジャンクスキャンを直接実行できます。キャッシュ、ログ、クラッシュレポート、Saved Application State のみを読み取り、削除は行いません。",
                            "안전 정크 검사를 직접 실행할 수 있습니다. 캐시, 로그, 충돌 보고서와 Saved Application State만 읽으며 정리는 수행하지 않습니다.",
                            "Можно напрямую запустить безопасное сканирование мусора. Оно только читает кэши, журналы, отчёты о сбоях и Saved Application State и ничего не очищает."
                        ))
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
                Button {
                    Task { await runSafeJunkScan() }
                } label: {
                    if isScanning {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(t("扫描中…", "掃描中…", "Scanning…", "スキャン中…", "검사 중…", "Сканирование…"))
                        }
                    } else {
                        Label(t("运行安全垃圾扫描", "執行安全垃圾掃描", "Run Safe Junk Scan", "安全ジャンクスキャン", "안전 정크 검사", "Безопасное сканирование мусора"), systemImage: "magnifyingglass")
                    }
                }
                .disabled(isScanning)

                Button(action: exportCurrentScan) {
                    Label(t("导出给 Codex", "匯出給 Codex", "Export for Codex", "Codex 用に書き出す", "Codex용 내보내기", "Экспорт для Codex"), systemImage: "square.and.arrow.up")
                }
                .disabled(!reportAvailable || isScanning)

                Button(action: importAssessment) {
                    Label(t("导入评估", "匯入評估", "Import assessment", "評価を読み込む", "평가 가져오기", "Импорт оценки"), systemImage: "square.and.arrow.down")
                }
                .disabled(!reportAvailable || isScanning)

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

    private func runSafeJunkScan() async {
        isScanning = true
        validated = []
        statusIsError = false
        statusMessage = t("正在执行只读安全垃圾扫描…", "正在執行唯讀安全垃圾掃描…", "Running read-only safe junk scan…", "読み取り専用の安全ジャンクスキャンを実行中…", "읽기 전용 안전 정크 검사 실행 중…", "Выполняется безопасное сканирование мусора только для чтения…")
        defer { isScanning = false }

        let report = await maintenanceAgent.execute(
            .scanJunk,
            arguments: .init(minimumSizeMB: nil, olderThanDays: 7)
        )

        if report.findings.isEmpty {
            statusMessage = t("扫描完成：没有找到 7 天以上的可评估垃圾文件。", "掃描完成：沒有找到 7 天以上的可評估垃圾檔案。", "Scan complete: no eligible junk files older than 7 days were found.", "スキャン完了：7日以上前の対象ジャンクファイルは見つかりませんでした。", "검사 완료: 7일 이상 된 평가 대상 정크 파일을 찾지 못했습니다.", "Сканирование завершено: подходящих файлов мусора старше 7 дней не найдено.")
        } else {
            statusMessage = t("扫描完成：", "掃描完成：", "Scan complete: ", "スキャン完了: ", "검사 완료: ", "Сканирование завершено: ")
                + "\(report.count) · \(ByteCountFormatter.string(fromByteCount: report.bytes, countStyle: .file))"
        }
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
