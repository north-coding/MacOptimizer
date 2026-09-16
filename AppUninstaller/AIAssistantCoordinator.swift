import Foundation

enum AIAssistantTarget: String, CaseIterable, Codable, Identifiable {
    case smartScan = "smart_scan"
    case systemJunk = "system_junk"
    case mailAttachments = "mail_attachments"
    case deepClean = "deep_clean"
    case privacy = "privacy"
    case trash = "trash"
    case malware = "malware"
    case largeFiles = "large_files"
    case spaceLens = "space_lens"
    case applications = "applications"
    case updates = "updates"
    case optimization = "optimization"
    case maintenance = "maintenance"
    case extensions = "extensions"
    case shredder = "shredder"
    case fileManager = "file_manager"
    case console = "console"

    var id: String { rawValue }

    var module: AppModule {
        switch self {
        case .smartScan: return .smartClean
        case .systemJunk: return .cleaner
        case .mailAttachments: return .mailAttachments
        case .deepClean: return .deepClean
        case .privacy: return .privacy
        case .trash: return .trash
        case .malware: return .malware
        case .largeFiles: return .largeFiles
        case .spaceLens: return .spaceLens
        case .applications: return .uninstaller
        case .updates: return .updater
        case .optimization: return .optimizer
        case .maintenance: return .maintenance
        case .extensions: return .extensions
        case .shredder: return .shredder
        case .fileManager: return .fileExplorer
        case .console: return .monitor
        }
    }

    var supportsAutomaticScan: Bool {
        switch self {
        case .maintenance, .shredder, .fileManager, .console:
            return false
        default:
            return true
        }
    }

    var supportsConfirmedClean: Bool {
        switch self {
        case .smartScan, .systemJunk, .mailAttachments, .deepClean, .privacy, .trash, .malware:
            return true
        default:
            return false
        }
    }

    static func target(for module: AppModule) -> AIAssistantTarget {
        allCases.first(where: { $0.module == module }) ?? .smartScan
    }

    func localizedName(_ language: AppLanguage) -> String {
        switch language {
        case .chinese:
            switch self {
            case .smartScan: return "智能扫描"
            case .systemJunk: return "系统垃圾"
            case .mailAttachments: return "邮件附件"
            case .deepClean: return "深度清理"
            case .privacy: return "隐私保护"
            case .trash: return "废纸篓"
            case .malware: return "恶意软件"
            case .largeFiles: return "大型和旧文件"
            case .spaceLens: return "空间透镜"
            case .applications: return "应用卸载"
            case .updates: return "更新程序"
            case .optimization: return "系统优化"
            case .maintenance: return "系统维护"
            case .extensions: return "扩展"
            case .shredder: return "碎纸机"
            case .fileManager: return "文件管理"
            case .console: return "控制台"
            }
        case .traditionalChinese:
            switch self {
            case .smartScan: return "智慧掃描"
            case .systemJunk: return "系統垃圾"
            case .mailAttachments: return "郵件附件"
            case .deepClean: return "深度清理"
            case .privacy: return "隱私保護"
            case .trash: return "廢紙簍"
            case .malware: return "惡意軟體"
            case .largeFiles: return "大型與舊檔案"
            case .spaceLens: return "空間透鏡"
            case .applications: return "應用程式解除安裝"
            case .updates: return "更新程式"
            case .optimization: return "系統最佳化"
            case .maintenance: return "系統維護"
            case .extensions: return "延伸功能"
            case .shredder: return "碎紙機"
            case .fileManager: return "檔案管理"
            case .console: return "控制台"
            }
        case .english:
            switch self {
            case .smartScan: return "Smart Scan"
            case .systemJunk: return "System Junk"
            case .mailAttachments: return "Mail Attachments"
            case .deepClean: return "Deep Clean"
            case .privacy: return "Privacy"
            case .trash: return "Trash Bins"
            case .malware: return "Malware Removal"
            case .largeFiles: return "Large & Old Files"
            case .spaceLens: return "Space Lens"
            case .applications: return "Uninstaller"
            case .updates: return "Updater"
            case .optimization: return "Optimization"
            case .maintenance: return "Maintenance"
            case .extensions: return "Extensions"
            case .shredder: return "Shredder"
            case .fileManager: return "File Manager"
            case .console: return "Console"
            }
        case .japanese:
            switch self {
            case .smartScan: return "スマートスキャン"
            case .systemJunk: return "システムジャンク"
            case .mailAttachments: return "メール添付ファイル"
            case .deepClean: return "ディープクリーン"
            case .privacy: return "プライバシー"
            case .trash: return "ゴミ箱"
            case .malware: return "マルウェア削除"
            case .largeFiles: return "大容量ファイルと古いファイル"
            case .spaceLens: return "スペースレンズ"
            case .applications: return "アンインストーラ"
            case .updates: return "アップデータ"
            case .optimization: return "最適化"
            case .maintenance: return "メンテナンス"
            case .extensions: return "機能拡張"
            case .shredder: return "シュレッダー"
            case .fileManager: return "ファイル管理"
            case .console: return "コンソール"
            }
        case .korean:
            switch self {
            case .smartScan: return "스마트 스캔"
            case .systemJunk: return "시스템 정크"
            case .mailAttachments: return "메일 첨부 파일"
            case .deepClean: return "정밀 정리"
            case .privacy: return "개인정보 보호"
            case .trash: return "휴지통"
            case .malware: return "악성 코드 제거"
            case .largeFiles: return "대용량 및 오래된 파일"
            case .spaceLens: return "공간 렌즈"
            case .applications: return "앱 제거"
            case .updates: return "업데이터"
            case .optimization: return "최적화"
            case .maintenance: return "유지보수"
            case .extensions: return "확장 프로그램"
            case .shredder: return "파일 분쇄기"
            case .fileManager: return "파일 관리"
            case .console: return "콘솔"
            }
        case .russian:
            switch self {
            case .smartScan: return "Умное сканирование"
            case .systemJunk: return "Системный мусор"
            case .mailAttachments: return "Почтовые вложения"
            case .deepClean: return "Глубокая очистка"
            case .privacy: return "Конфиденциальность"
            case .trash: return "Корзина"
            case .malware: return "Удаление вредоносных программ"
            case .largeFiles: return "Большие и старые файлы"
            case .spaceLens: return "Обзор пространства"
            case .applications: return "Удаление приложений"
            case .updates: return "Обновление приложений"
            case .optimization: return "Оптимизация"
            case .maintenance: return "Обслуживание"
            case .extensions: return "Расширения"
            case .shredder: return "Шредер"
            case .fileManager: return "Управление файлами"
            case .console: return "Консоль"
            }
        }
    }
}

enum AIAssistantOperation: String {
    case scan
    case clean
    case scanAndClean = "scan_and_clean"
    case navigate
    case status
    case help
}

struct AIAssistantPlan {
    let operation: AIAssistantOperation
    let targets: [AIAssistantTarget]
}

struct AIAssistantMessage: Identifiable {
    enum Role: Equatable { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
    let attachments: [AIAttachment]

    init(role: Role, text: String, attachments: [AIAttachment] = []) {
        self.role = role
        self.text = text
        self.attachments = attachments
    }
}

@MainActor
final class AIAssistantCoordinator: ObservableObject {
    static let shared = AIAssistantCoordinator()

    @Published var isPresented = false
    @Published var showsSettings = false
    @Published var messages: [AIAssistantMessage] = []
    @Published var isWorking = false
    @Published var progressText = ""
    private let settings = AIProviderSettingsStore.shared
    private let client = AIProviderClient()
    private let services = ScanServiceManager.shared
    private let maintenanceAgent = MacMaintenanceAgentService.shared
    private var lastOpenedModule: AppModule?

    private init() {}

    func open(currentModule: AppModule) {
        isPresented = true
        showsSettings = !settings.hasCompleteConfiguration()
        if messages.isEmpty {
            messages.append(.init(role: .assistant, text: welcomeMessage(currentModule)))
        } else if let lastOpenedModule, lastOpenedModule != currentModule {
            messages.append(.init(role: .assistant, text: currentModuleMessage(currentModule)))
        }
        lastOpenedModule = currentModule
    }

    func submit(_ request: String, attachments: [AIAttachment] = [], currentModule: AppModule) async {
        let trimmed = request.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!trimmed.isEmpty || !attachments.isEmpty), !isWorking else { return }
        guard settings.hasCompleteConfiguration() else {
            showsSettings = true
            messages.append(.init(role: .assistant, text: configurationRequiredMessage))
            return
        }

        let providerPrompt = trimmed.isEmpty ? attachedImagePrompt : trimmed
        messages.append(.init(role: .user, text: trimmed, attachments: attachments))
        maintenanceAgent.cancelCleanup()
        isWorking = true
        progressText = organizingMessage

        do {
            try await runMaintenanceAgent(
                request: providerPrompt,
                attachments: attachments,
                currentModule: currentModule
            )
        } catch {
            messages.append(.init(role: .assistant, text: providerFailureMessage(error)))
        }

        progressText = ""
        isWorking = false
    }

    func clearConversation(currentModule: AppModule) {
        messages = [.init(role: .assistant, text: welcomeMessage(currentModule))]
        lastOpenedModule = currentModule
        maintenanceAgent.cancelCleanup()
        progressText = ""
    }

    private func runMaintenanceAgent(
        request: String,
        attachments: [AIAttachment],
        currentModule: AppModule
    ) async throws {
        let configuration = settings.configuration()
        var transcript = """
        User request: \(request)
        Current application page: \(AIAssistantTarget.target(for: currentModule).rawValue)
        Select the first local tool now.
        """
        var latestReport: MacAgentToolReport?

        for step in 0..<4 {
            let raw = try await client.generateJSON(
                configuration: configuration,
                systemPrompt: maintenanceAgentSystemPrompt,
                userPrompt: transcript,
                attachments: step == 0 ? attachments.map(\.payload) : []
            )
            let decodedDecision = decodeAgentDecision(raw)
                ?? fallbackAgentDecision(for: request, hasReport: latestReport != nil)
            let decision = AIAssistantReadOnlyPolicy.sanitize(
                decodedDecision,
                hasReport: latestReport != nil
            )

            if decision.tool == .finish {
                let reportText = latestReport.map(agentReportMessage) ?? agentReadyMessage
                let analysis = decision.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let finalText = analysis.isEmpty ? reportText : "\(reportText)\n\n\(analysis)"
                messages.append(.init(role: .assistant, text: finalText))
                return
            }

            progressText = agentProgressMessage(decision.tool)
            let report = await maintenanceAgent.execute(decision.tool, arguments: decision.arguments)
            latestReport = report

            transcript += """

            Local tool completed. Only aggregate data is provided; no file paths leave the Mac.
            \(report.modelSummary)
            Decide the next tool. Use finish when enough evidence is available and summarize only these real results.
            """
        }

        messages.append(.init(role: .assistant, text: latestReport.map(agentReportMessage) ?? agentReadyMessage))
    }

    private var maintenanceAgentSystemPrompt: String {
        """
        You are Mac Optimization Agent, a specialized autonomous maintenance agent running inside a macOS utility.
        You choose local tools; the macOS app executes them directly against the local filesystem and returns real aggregate results. Do not claim you personally accessed a path unless a tool result confirms it. Do not refer to existing application modules or APIs.
        Return exactly one JSON object and no Markdown:
        {"tool":"scan_junk|scan_large_files|scan_duplicates|inspect_storage|inspect_system|inspect_startup|list_results|finish","arguments":{"minimumSizeMB":100,"olderThanDays":3},"message":"localized final analysis"}
        Tool rules:
        - This assistant is read-only. It may scan and explain cleanup candidates, but must never prepare or execute cleanup. If the user asks to clean or delete, inspect and explain instead.
        - scan_junk directly scans local caches, logs, crash reports, and saved application state.
        - scan_large_files directly scans user content. It never selects large files for automatic cleanup.
        - scan_duplicates directly groups files by size and verifies byte-identical copies with SHA-256. Duplicate files require manual review and are never automatically selected for cleanup.
        - inspect_storage reads real local disk capacity.
        - inspect_system reads processor, memory, uptime, power, and thermal state.
        - inspect_startup reads local launch-agent files.
        - finish ends the loop. Its message must use only facts returned by tools, must not invent counts, sizes, diagnoses, paths, or completed cleanup.
        The interface language is \(LocalizationManager.shared.currentLanguage.rawValue). The message field must use that language only. JSON tool names stay exactly as specified.
        """
    }

    private func decodeAgentDecision(_ text: String) -> MacAgentDecision? {
        let stripped = text
            .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = stripped.firstIndex(of: "{"),
              let end = stripped.lastIndex(of: "}"),
              start <= end else { return nil }
        return try? JSONDecoder().decode(MacAgentDecision.self, from: Data(stripped[start...end].utf8))
    }

    private func fallbackAgentDecision(for request: String, hasReport: Bool) -> MacAgentDecision {
        if hasReport { return .init(tool: .finish, arguments: nil, message: nil) }
        let normalized = request.lowercased()
        let containsAny: ([String]) -> Bool = { words in words.contains(where: normalized.contains) }
        if containsAny(["重复文件", "重复项", "duplicate", "duplicates", "重複ファイル", "중복 파일", "дубликат"]) {
            return .init(tool: .scanDuplicates, arguments: nil, message: nil)
        }
        if containsAny(["大文件", "大型", "large file", "big file", "大容量", "대용량", "большие файл"]) {
            return .init(tool: .scanLargeFiles, arguments: .init(minimumSizeMB: 100, olderThanDays: nil), message: nil)
        }
        if containsAny(["磁盘", "空间", "disk", "storage", "ディスク", "ストレージ", "디스크", "저장 공간", "диск", "хранилищ"]) {
            return .init(tool: .inspectStorage, arguments: nil, message: nil)
        }
        if containsAny(["启动项", "开机", "startup", "launch agent", "起動", "시작 항목", "автозапуск"]) {
            return .init(tool: .inspectStartup, arguments: nil, message: nil)
        }
        if containsAny(["性能", "发热", "内存", "performance", "thermal", "memory", "パフォーマンス", "メモリ", "성능", "메모리", "производительност", "память"]) {
            return .init(tool: .inspectSystem, arguments: nil, message: nil)
        }
        return .init(tool: .scanJunk, arguments: .init(minimumSizeMB: nil, olderThanDays: 3), message: nil)
    }

    private func agentProgressMessage(_ tool: MacAgentTool) -> String {
        let name = localizedAgentToolName(tool)
        return localized([
            .chinese: "智能体正在执行本机工具：\(name)…",
            .traditionalChinese: "智慧代理正在執行本機工具：\(name)…",
            .english: "Agent is running the local tool: \(name)…",
            .japanese: "エージェントがローカルツールを実行中：\(name)…",
            .korean: "에이전트가 로컬 도구를 실행하는 중: \(name)…",
            .russian: "Агент выполняет локальный инструмент: \(name)…"
        ])
    }

    private func localizedAgentToolName(_ tool: MacAgentTool) -> String {
        let values: [MacAgentTool: [AppLanguage: String]] = [
            .scanJunk: [.chinese: "垃圾文件扫描", .traditionalChinese: "垃圾檔案掃描", .english: "junk scan", .japanese: "ジャンクスキャン", .korean: "정크 파일 검사", .russian: "сканирование мусора"],
            .scanLargeFiles: [.chinese: "大文件扫描", .traditionalChinese: "大型檔案掃描", .english: "large-file scan", .japanese: "大容量ファイルスキャン", .korean: "대용량 파일 검사", .russian: "поиск больших файлов"],
            .scanDuplicates: [.chinese: "重复文件扫描", .traditionalChinese: "重複檔案掃描", .english: "duplicate-file scan", .japanese: "重複ファイルスキャン", .korean: "중복 파일 검사", .russian: "поиск дубликатов"],
            .inspectStorage: [.chinese: "磁盘空间诊断", .traditionalChinese: "磁碟空間診斷", .english: "storage diagnostics", .japanese: "ストレージ診断", .korean: "저장 공간 진단", .russian: "диагностика хранилища"],
            .inspectSystem: [.chinese: "系统性能诊断", .traditionalChinese: "系統效能診斷", .english: "system diagnostics", .japanese: "システム診断", .korean: "시스템 진단", .russian: "диагностика системы"],
            .inspectStartup: [.chinese: "启动项检查", .traditionalChinese: "啟動項目檢查", .english: "startup inspection", .japanese: "起動項目チェック", .korean: "시작 항목 검사", .russian: "проверка автозапуска"],
            .listResults: [.chinese: "读取扫描结果", .traditionalChinese: "讀取掃描結果", .english: "result review", .japanese: "結果確認", .korean: "결과 확인", .russian: "просмотр результатов"],
            .finish: [.chinese: "完成", .traditionalChinese: "完成", .english: "finish", .japanese: "完了", .korean: "완료", .russian: "завершение"]
        ]
        return values[tool]?[language] ?? tool.rawValue
    }

    private func agentReportMessage(_ report: MacAgentToolReport) -> String {
        if report.tool == .scanDuplicates {
            let groups = report.facts["duplicate_groups"] ?? "0"
            return localized([
                .chinese: "本机重复文件扫描完成：使用 SHA-256 内容校验发现 \(groups) 组重复文件，其中 \(report.count) 个为冗余副本，可释放约 \(formattedBytes(report.bytes))。为避免删错原件，重复文件不会自动清理，需要逐组确认。",
                .traditionalChinese: "本機重複檔案掃描完成：使用 SHA-256 內容驗證找到 \(groups) 組重複檔案，其中 \(report.count) 個為多餘副本，可釋放約 \(formattedBytes(report.bytes))。為避免刪錯原檔，重複檔案不會自動清理，需要逐組確認。",
                .english: "Local duplicate scan finished. SHA-256 content verification found \(groups) duplicate groups with \(report.count) redundant copies, representing about \(formattedBytes(report.bytes)). Duplicates are never cleaned automatically and require group-by-group review.",
                .japanese: "ローカル重複ファイルスキャンが完了しました。SHA-256内容検証で\(groups)グループ、冗長コピー\(report.count)件（約\(formattedBytes(report.bytes))）を検出しました。原本の誤削除を防ぐため、自動削除せずグループごとの確認が必要です。",
                .korean: "로컬 중복 파일 검사가 완료되었습니다. SHA-256 콘텐츠 검증으로 \(groups)개 그룹과 \(report.count)개 중복 사본(약 \(formattedBytes(report.bytes)))을 찾았습니다. 원본 오삭제를 방지하기 위해 자동 정리하지 않으며 그룹별 확인이 필요합니다.",
                .russian: "Локальный поиск дубликатов завершён. Проверка SHA-256 обнаружила групп: \(groups), лишних копий: \(report.count), потенциально освобождается около \(formattedBytes(report.bytes)). Дубликаты не удаляются автоматически и требуют проверки каждой группы."
            ])
        }
        if report.tool == .inspectStorage {
            let total = Int64(report.facts["total_bytes"] ?? "0") ?? 0
            let available = Int64(report.facts["available_bytes"] ?? "0") ?? 0
            return localized([
                .chinese: "本机磁盘诊断完成：总容量 \(formattedBytes(total))，当前可用 \(formattedBytes(available))。",
                .traditionalChinese: "本機磁碟診斷完成：總容量 \(formattedBytes(total))，目前可用 \(formattedBytes(available))。",
                .english: "Local storage diagnostics finished: \(formattedBytes(total)) total, \(formattedBytes(available)) available.",
                .japanese: "ローカルストレージ診断が完了しました。合計\(formattedBytes(total))、空き容量\(formattedBytes(available))です。",
                .korean: "로컬 저장 공간 진단 완료: 총 \(formattedBytes(total)), 사용 가능 \(formattedBytes(available)).",
                .russian: "Диагностика хранилища завершена: всего \(formattedBytes(total)), доступно \(formattedBytes(available))."
            ])
        }
        if report.tool == .inspectSystem {
            let memory = Int64(report.facts["physical_memory_bytes"] ?? "0") ?? 0
            let thermal = report.facts["thermal_state"] ?? "unknown"
            return localized([
                .chinese: "本机系统诊断完成：物理内存 \(formattedBytes(memory))，温控状态 \(thermal)，活跃处理器 \(report.facts["active_processor_count"] ?? "0") 个。",
                .traditionalChinese: "本機系統診斷完成：實體記憶體 \(formattedBytes(memory))，溫控狀態 \(thermal)，使用中處理器 \(report.facts["active_processor_count"] ?? "0") 個。",
                .english: "Local system diagnostics finished: \(formattedBytes(memory)) physical memory, thermal state \(thermal), \(report.facts["active_processor_count"] ?? "0") active processors.",
                .japanese: "ローカルシステム診断が完了しました。物理メモリ\(formattedBytes(memory))、温度状態\(thermal)、アクティブプロセッサ\(report.facts["active_processor_count"] ?? "0")個です。",
                .korean: "로컬 시스템 진단 완료: 물리 메모리 \(formattedBytes(memory)), 온도 상태 \(thermal), 활성 프로세서 \(report.facts["active_processor_count"] ?? "0")개.",
                .russian: "Диагностика системы завершена: физическая память \(formattedBytes(memory)), тепловое состояние \(thermal), активных процессоров: \(report.facts["active_processor_count"] ?? "0")."
            ])
        }
        let toolName = localizedAgentToolName(report.tool)
        return localized([
            .chinese: "本机\(toolName)完成，发现 \(report.count) 个项目，共 \(formattedBytes(report.bytes))。扫描由智能体的独立本机工具直接完成。",
            .traditionalChinese: "本機\(toolName)完成，找到 \(report.count) 個項目，共 \(formattedBytes(report.bytes))。掃描由智慧代理的獨立本機工具直接完成。",
            .english: "The local \(toolName) finished: \(report.count) items totaling \(formattedBytes(report.bytes)). The agent’s independent local tool performed the scan directly.",
            .japanese: "ローカル\(toolName)が完了しました。\(report.count)件、合計\(formattedBytes(report.bytes))です。エージェントの独立したローカルツールが直接スキャンしました。",
            .korean: "로컬 \(toolName) 완료: \(report.count)개 항목, 총 \(formattedBytes(report.bytes)). 에이전트의 독립 로컬 도구가 직접 검사했습니다.",
            .russian: "Локальная операция «\(toolName)» завершена: объектов — \(report.count), объём — \(formattedBytes(report.bytes)). Сканирование выполнено напрямую независимым локальным инструментом агента."
        ])
    }

    private var agentReadyMessage: String {
        localized([
            .chinese: "Mac 优化智能体已就绪。它可以自主选择本机扫描和诊断工具。",
            .traditionalChinese: "Mac 最佳化智慧代理已就緒，可自主選擇本機掃描與診斷工具。",
            .english: "Mac Optimization Agent is ready and can autonomously choose local scanning and diagnostic tools.",
            .japanese: "Mac最適化エージェントの準備ができました。ローカルのスキャン・診断ツールを自律的に選択できます。",
            .korean: "Mac 최적화 에이전트가 준비되었습니다. 로컬 검사 및 진단 도구를 자율적으로 선택할 수 있습니다.",
            .russian: "Агент оптимизации Mac готов и может самостоятельно выбирать локальные инструменты сканирования и диагностики."
        ])
    }

    private func scan(_ targets: [AIAssistantTarget]) async -> Bool {
        let uniqueTargets = targets.reduce(into: [AIAssistantTarget]()) { result, target in
            if !result.contains(target) { result.append(target) }
        }
        guard !uniqueTargets.isEmpty else { return false }
        guard !hasCleaningOperation(in: uniqueTargets) else {
            messages.append(.init(role: .assistant, text: operationAlreadyRunningMessage))
            return false
        }
        AppNavigationController.shared.selectedModule = uniqueTargets[0].module

        for target in uniqueTargets {
            progressText = scanningMessage(target)
            switch target {
            case .smartScan:
                if services.smartCleanerService.isScanning {
                    await waitUntilFinished { self.services.smartCleanerService.isScanning }
                } else {
                    await services.smartCleanerService.scanAll()
                }
            case .systemJunk:
                if services.junkCleaner.isScanning {
                    await waitUntilFinished { self.services.junkCleaner.isScanning }
                } else {
                    await services.junkCleaner.scanJunk()
                }
            case .mailAttachments:
                if services.junkCleaner.isScanningMailAttachments {
                    await waitUntilFinished { self.services.junkCleaner.isScanningMailAttachments }
                } else {
                    await services.junkCleaner.scanMailAttachments()
                }
            case .deepClean:
                if services.deepCleanScanner.isScanning {
                    await waitUntilFinished { self.services.deepCleanScanner.isScanning }
                } else {
                    await services.deepCleanScanner.startScan()
                }
            case .privacy:
                if services.privacyScanner.isScanning {
                    await waitUntilFinished { self.services.privacyScanner.isScanning }
                } else {
                    await services.privacyScanner.scanAll()
                }
            case .trash:
                if services.trashScanner.isScanning {
                    await waitUntilFinished { self.services.trashScanner.isScanning }
                } else {
                    await services.trashScanner.scan()
                }
            case .malware:
                if services.malwareScanner.isScanning {
                    await waitUntilFinished { self.services.malwareScanner.isScanning }
                } else {
                    await services.malwareScanner.scan()
                }
            case .largeFiles:
                if services.largeFileScanner.isScanning {
                    await waitUntilFinished { self.services.largeFileScanner.isScanning }
                } else {
                    await services.largeFileScanner.scan()
                }
            case .spaceLens:
                if services.spaceLensScanner.isScanning {
                    await waitUntilFinished { self.services.spaceLensScanner.isScanning }
                } else {
                    await services.spaceLensScanner.scan()
                }
            case .applications:
                if services.appScanner.isScanning {
                    await waitUntilFinished { self.services.appScanner.isScanning }
                } else {
                    await services.appScanner.scanApplications()
                }
            case .updates:
                if AppUpdaterService.shared.isScanning {
                    await waitUntilFinished { AppUpdaterService.shared.isScanning }
                } else {
                    await AppUpdaterService.shared.scanForUpdates()
                }
            case .optimization:
                await OptimizerService.shared.scanAndWait()
            case .extensions:
                await ExtensionsService.shared.scanAndWait()
            case .maintenance, .shredder, .fileManager, .console:
                AppNavigationController.shared.selectedModule = target.module
            }
        }

        messages.append(.init(
            role: .assistant,
            text: scanCompleteMessage(targets: uniqueTargets, count: selectedItemCount(for: uniqueTargets))
        ))
        return true
    }

    private func waitUntilFinished(_ isRunning: @escaping () -> Bool) async {
        while isRunning() {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private func hasCleaningOperation(in targets: [AIAssistantTarget]) -> Bool {
        targets.contains { target in
            switch target {
            case .smartScan: return services.smartCleanerService.isCleaning
            case .systemJunk: return services.junkCleaner.isCleaning
            case .mailAttachments: return services.junkCleaner.isCleaningMailAttachments
            case .deepClean: return services.deepCleanScanner.isCleaning
            case .privacy: return services.privacyScanner.isCleaning
            case .trash: return services.trashScanner.isCleaning
            case .malware: return services.malwareScanner.isRemoving
            case .largeFiles: return services.largeFileScanner.isCleaning
            default: return false
            }
        }
    }

    private func decodePlan(_ text: String, currentModule: AppModule) throws -> AIAssistantPlan {
        struct RawPlan: Decodable {
            let action: String
            let targets: [String]?
        }

        let stripped = text
            .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = stripped.firstIndex(of: "{"),
              let end = stripped.lastIndex(of: "}"),
              start <= end else { throw AIProviderError.invalidResponse }
        let json = String(stripped[start...end])
        let raw = try JSONDecoder().decode(RawPlan.self, from: Data(json.utf8))
        guard let operation = AIAssistantOperation(rawValue: raw.action.lowercased()) else {
            throw AIProviderError.invalidResponse
        }
        let decodedTargets = (raw.targets ?? []).compactMap { AIAssistantTarget(rawValue: $0.lowercased()) }
        let targets = decodedTargets.isEmpty ? [AIAssistantTarget.target(for: currentModule)] : decodedTargets
        return AIAssistantPlan(operation: operation, targets: targets)
    }

    private func fallbackPlan(for request: String, currentModule: AppModule) -> AIAssistantPlan {
        let normalized = request.lowercased()
        let containsAny: ([String]) -> Bool = { words in words.contains(where: normalized.contains) }
        let asksToClean = containsAny(["清理", "删除", "移除", "clean", "delete", "remove", "クリーン", "削除", "정리", "삭제", "очист", "удал"])
        let asksToScan = containsAny(["扫描", "检查", "查找", "scan", "inspect", "find", "check", "スキャン", "確認", "검사", "스캔", "провер", "скан"])
        let operation: AIAssistantOperation

        if asksToScan && asksToClean {
            operation = .scanAndClean
        } else if asksToClean {
            operation = .clean
        } else if asksToScan {
            operation = .scan
        } else if containsAny(["状态", "进度", "status", "progress", "状態", "進捗", "상태", "진행", "статус", "ход выполнения"]) {
            operation = .status
        } else if containsAny(["打开", "进入", "open", "navigate", "開く", "移動", "열기", "이동", "откры", "перейти"]) {
            operation = .navigate
        } else {
            operation = .help
        }

        return AIAssistantPlan(
            operation: operation,
            targets: [AIAssistantTarget.target(for: currentModule)]
        )
    }

    private func intentSystemPrompt(currentModule: AppModule) -> String {
        let targetValues = AIAssistantTarget.allCases.map(\.rawValue).joined(separator: ", ")
        return """
        You are the private intent router inside a macOS maintenance application. Never claim that files were scanned or deleted. The application executes tools and reports real results after you return a plan.
        Return exactly one JSON object and no Markdown: {"action":"scan|clean|scan_and_clean|navigate|status|help","targets":["target"]}
        Allowed targets: \(targetValues)
        Current page: \(AIAssistantTarget.target(for: currentModule).rawValue)
        Use the current page when the request does not name a module. Use scan_and_clean only when the user explicitly asks both to scan and clean. A clean request still requires confirmation inside the app. Never invent paths, counts, sizes, findings, commands, or extra fields.
        The user interface language is \(LocalizationManager.shared.currentLanguage.rawValue). Understand the request in that language, but keep JSON action and target identifiers exactly as specified above.
        Attached images are only context for understanding the user's request. Do not infer arbitrary file paths, deletion targets, counts, or scan results from an image.
        """
    }

    private func selectedItemCount(for targets: [AIAssistantTarget]) -> Int {
        targets.reduce(0) { total, target in
            total + resultCount(for: target)
        }
    }

    private func resultCount(for target: AIAssistantTarget) -> Int {
        switch target {
        case .smartScan:
            let smart = services.smartCleanerService
            var count = smart.systemCacheFiles.filter(\.isSelected).count
            count += smart.oldUpdateFiles.filter(\.isSelected).count
            count += smart.userCacheFiles.filter(\.isSelected).count
            count += smart.appCacheGroups.reduce(0) { $0 + $1.files.filter(\.isSelected).count }
            count += smart.trashFiles.filter(\.isSelected).count
            count += smart.systemLogFiles.filter(\.isSelected).count
            count += smart.userLogFiles.filter(\.isSelected).count
            count += smart.duplicateGroups.reduce(0) { $0 + $1.files.filter(\.isSelected).count }
            count += smart.similarPhotoGroups.reduce(0) { $0 + $1.files.filter(\.isSelected).count }
            count += smart.localizationFiles.filter(\.isSelected).count
            count += smart.largeFiles.filter(\.isSelected).count
            count += smart.virusThreats.filter(\.isSelected).count
            count += smart.startupItems.filter(\.isSelected).count
            count += smart.performanceApps.filter(\.isSelected).count
            count += smart.hasAppUpdates ? 1 : 0
            return count
        case .systemJunk:
            return services.junkCleaner.junkItems.filter(\.isSelected).count
        case .mailAttachments:
            return services.junkCleaner.junkItems.filter { $0.type == .mailAttachments && $0.isSelected }.count
        case .deepClean:
            return services.deepCleanScanner.items.filter(\.isSelected).count
        case .privacy:
            return services.privacyScanner.privacyItems.filter(\.isSelected).count
        case .trash:
            return services.trashScanner.items.filter(\.isSelected).count
        case .malware:
            return services.malwareScanner.threats.filter(\.isSelected).count
        case .largeFiles:
            return services.largeFileScanner.foundFiles.count
        case .applications:
            return services.appScanner.apps.count
        case .updates:
            return AppUpdaterService.shared.updates.count
        case .optimization:
            return OptimizerService.shared.heavyProcesses.count + OptimizerService.shared.launchAgents.count + OptimizerService.shared.hungApps.count
        case .extensions:
            return ExtensionsService.shared.items.count
        case .spaceLens, .maintenance, .shredder, .fileManager, .console:
            return 0
        }
    }

    private var language: AppLanguage { LocalizationManager.shared.currentLanguage }

    private func localized(_ values: [AppLanguage: String]) -> String {
        values[language] ?? values[.english] ?? ""
    }

    private func joinedNames(_ targets: [AIAssistantTarget]) -> String {
        let names = targets.map { $0.localizedName(language) }
        switch language {
        case .chinese, .traditionalChinese, .japanese: return names.joined(separator: "、")
        case .english, .korean, .russian: return names.joined(separator: ", ")
        }
    }

    private func welcomeMessage(_ module: AppModule) -> String {
        let name = AIAssistantTarget.target(for: module).localizedName(language)
        return localized([
            .chinese: "我是 Mac 优化智能体。我会自主选择独立的本机工具，直接检查垃圾文件、磁盘空间、系统状态和启动项；当前页面是“\(name)”。我只提供只读分析和建议，不会清理或删除文件。",
            .traditionalChinese: "我是 Mac 最佳化智慧代理。我會自主選擇獨立的本機工具，直接檢查垃圾檔案、磁碟空間、系統狀態與啟動項目；目前頁面是「\(name)」。我只提供唯讀分析和建議，不會清理或刪除檔案。",
            .english: "I’m Mac Optimization Agent. I autonomously choose independent local tools to inspect junk, storage, system health, and startup items. You’re currently on \(name). I provide read-only analysis and advice and never clean or delete files.",
            .japanese: "Mac最適化エージェントです。独立したローカルツールを自律的に選択し、ジャンク、ストレージ、システム状態、起動項目を直接確認します。現在のページは「\(name)」です。読み取り専用の分析と助言のみを行い、クリーンアップや削除はしません。",
            .korean: "Mac 최적화 에이전트입니다. 독립 로컬 도구를 자율적으로 선택해 정크 파일, 저장 공간, 시스템 상태 및 시작 항목을 직접 검사합니다. 현재 페이지는 \(name)입니다. 읽기 전용 분석과 조언만 제공하며 파일을 정리하거나 삭제하지 않습니다.",
            .russian: "Я агент оптимизации Mac. Я самостоятельно выбираю независимые локальные инструменты для проверки мусора, диска, состояния системы и автозапуска. Текущая страница: «\(name)». Я предоставляю только анализ и рекомендации в режиме чтения и никогда не очищаю и не удаляю файлы."
        ])
    }

    private func currentModuleMessage(_ module: AppModule) -> String {
        let name = AIAssistantTarget.target(for: module).localizedName(language)
        return localized([
            .chinese: "当前页面已切换为“\(name)”，接下来的未指定需求会以此页面为目标。",
            .traditionalChinese: "目前頁面已切換為「\(name)」，接下來未指定的需求會以此頁面為目標。",
            .english: "The current page is now \(name). Requests without a named target will use this page.",
            .japanese: "現在のページは「\(name)」に切り替わりました。対象が指定されていない次のリクエストでは、このページを使用します。",
            .korean: "현재 페이지: \(name). 대상을 지정하지 않은 다음 요청에는 이 페이지를 사용합니다.",
            .russian: "Текущая страница переключена на «\(name)». Следующие запросы без указанной цели будут относиться к этой странице."
        ])
    }

    private var configurationRequiredMessage: String {
        localized([
            .chinese: "请先在智能体模型设置中填写服务商、Base URL、模型和 API Key。",
            .traditionalChinese: "請先在智慧代理模型設定中填寫服務商、Base URL、模型與 API Key。",
            .english: "Set the provider, Base URL, model, and API key in Agent Model Settings first.",
            .japanese: "先にエージェントモデル設定でプロバイダー、Base URL、モデル、APIキーを設定してください。",
            .korean: "먼저 에이전트 모델 설정에서 제공업체, Base URL, 모델 및 API 키를 입력하세요.",
            .russian: "Сначала укажите поставщика, Base URL, модель и API-ключ в настройках модели агента."
        ])
    }

    private var organizingMessage: String {
        localized([.chinese: "正在整理需求…", .traditionalChinese: "正在整理需求…", .english: "Organizing your request…", .japanese: "ご要望を整理しています…", .korean: "요청을 정리하는 중…", .russian: "Анализ запроса…"])
    }

    private var attachedImagePrompt: String {
        localized([
            .chinese: "请根据附加图片理解我的需求，并为当前页面整理合适的操作。",
            .traditionalChinese: "請根據附加圖片理解我的需求，並為目前頁面整理合適的操作。",
            .english: "Use the attached image to understand my request and choose an appropriate action for the current page.",
            .japanese: "添付画像から要望を理解し、現在のページに適した操作を整理してください。",
            .korean: "첨부 이미지를 바탕으로 요청을 이해하고 현재 페이지에 적합한 작업을 정리해 주세요.",
            .russian: "Определите запрос по прикреплённому изображению и выберите подходящее действие для текущей страницы."
        ])
    }

    private var cleaningMessage: String {
        localized([.chinese: "正在执行已确认的清理…", .traditionalChinese: "正在執行已確認的清理…", .english: "Running the confirmed cleanup…", .japanese: "確認済みのクリーンアップを実行しています…", .korean: "확인된 정리를 실행하는 중…", .russian: "Выполняется подтверждённая очистка…"])
    }

    private var operationAlreadyRunningMessage: String {
        localized([
            .chinese: "对应模块正在执行清理，请等待当前操作完成后再开始新的扫描。",
            .traditionalChinese: "對應模組正在執行清理，請等待目前操作完成後再開始新的掃描。",
            .english: "The module is already cleaning. Wait for the current operation to finish before starting another scan.",
            .japanese: "対象モジュールでクリーンアップを実行中です。現在の操作が完了してから新しいスキャンを開始してください。",
            .korean: "해당 모듈에서 정리를 실행 중입니다. 현재 작업이 완료된 후 새 스캔을 시작하세요.",
            .russian: "В соответствующем модуле уже выполняется очистка. Дождитесь её завершения перед новым сканированием."
        ])
    }

    private func scanningMessage(_ target: AIAssistantTarget) -> String {
        let name = target.localizedName(language)
        return localized([.chinese: "正在扫描\(name)…", .traditionalChinese: "正在掃描\(name)…", .english: "Scanning \(name)…", .japanese: "\(name)をスキャンしています…", .korean: "\(name) 스캔 중…", .russian: "Сканирование: \(name)…"])
    }

    private func planMessage(_ plan: AIAssistantPlan) -> String {
        let names = joinedNames(plan.targets)
        return localized([
            .chinese: "已整理需求，目标为：\(names)。我只会调用应用现有功能并读取真实结果。",
            .traditionalChinese: "已整理需求，目標為：\(names)。我只會呼叫應用程式現有功能並讀取真實結果。",
            .english: "I organized the request for: \(names). I’ll use only the app’s existing tools and their real results.",
            .japanese: "ご要望を整理しました。対象：\(names)。アプリの既存機能のみを使用し、実際の結果を読み取ります。",
            .korean: "요청을 정리했습니다. 대상: \(names). 앱의 기존 기능과 실제 결과만 사용합니다.",
            .russian: "Запрос подготовлен. Цели: \(names). Будут использованы только встроенные функции приложения и фактические результаты."
        ])
    }

    private func scanCompleteMessage(targets: [AIAssistantTarget], count: Int) -> String {
        let names = joinedNames(targets)
        return localized([
            .chinese: "\(names)扫描完成，当前发现 \(count) 个相关项目。结果已同步到对应模块，请先检查选择状态。",
            .traditionalChinese: "\(names)掃描完成，目前找到 \(count) 個相關項目。結果已同步至對應模組，請先檢查選取狀態。",
            .english: "The \(names) scan is complete. \(count) related items were found. Results are synced to the module; review the selections first.",
            .japanese: "\(names)のスキャンが完了し、\(count)件の関連項目が見つかりました。結果は該当モジュールに同期されています。選択内容を確認してください。",
            .korean: "\(names) 스캔이 완료되었으며 관련 항목 \(count)개를 찾았습니다. 결과가 해당 모듈에 동기화되었습니다. 선택 상태를 확인하세요.",
            .russian: "Сканирование «\(names)» завершено. Найдено связанных объектов: \(count). Результаты переданы в соответствующий модуль; проверьте выбранные объекты."
        ])
    }

    private func cleanConfirmationMessage(_ targets: [AIAssistantTarget]) -> String {
        let count = selectedItemCount(for: targets)
        let names = joinedNames(targets)
        return localized([
            .chinese: "已准备好清理\(names)中选中的 \(count) 个项目。此操作可能删除文件，需要你明确确认。",
            .traditionalChinese: "已準備好清理\(names)中選取的 \(count) 個項目。此操作可能刪除檔案，需要您明確確認。",
            .english: "Ready to clean \(count) selected items in \(names). This may delete files and requires your explicit confirmation.",
            .japanese: "\(names)で選択された\(count)件をクリーンアップする準備ができました。ファイルが削除される可能性があるため、明示的な確認が必要です。",
            .korean: "\(names)에서 선택된 항목 \(count)개를 정리할 준비가 되었습니다. 파일이 삭제될 수 있으므로 명시적인 확인이 필요합니다.",
            .russian: "Готово к очистке выбранных объектов (\(count)) в разделе «\(names)». Возможно удаление файлов, поэтому требуется явное подтверждение."
        ])
    }

    private func cleanCompleteMessage(count: Int, bytes: Int64, failed: Int) -> String {
        let size = formattedBytes(bytes)
        return localized([
            .chinese: "已完成确认的清理：处理 \(count) 个项目，释放 \(size)，失败 \(failed) 个。",
            .traditionalChinese: "已完成確認的清理：處理 \(count) 個項目，釋放 \(size)，失敗 \(failed) 個。",
            .english: "Confirmed cleanup finished: \(count) items processed, \(size) freed, \(failed) failed.",
            .japanese: "確認済みのクリーンアップが完了しました。処理：\(count)件、解放：\(size)、失敗：\(failed)件。",
            .korean: "확인된 정리가 완료되었습니다. 처리 \(count)개, 확보 \(size), 실패 \(failed)개.",
            .russian: "Подтверждённая очистка завершена: обработано \(count), освобождено \(size), ошибок: \(failed)."
        ])
    }

    private var cleanCancelledMessage: String {
        localized([.chinese: "已取消清理，没有删除任何项目。", .traditionalChinese: "已取消清理，未刪除任何項目。", .english: "Cleanup canceled. Nothing was deleted.", .japanese: "クリーンアップをキャンセルしました。項目は削除されていません。", .korean: "정리를 취소했습니다. 삭제된 항목이 없습니다.", .russian: "Очистка отменена. Ничего не удалено."])
    }

    private var nothingToCleanMessage: String {
        localized([.chinese: "扫描完成，但目前没有选中可清理的项目。", .traditionalChinese: "掃描完成，但目前沒有選取可清理的項目。", .english: "The scan finished, but no cleanable items are currently selected.", .japanese: "スキャンは完了しましたが、クリーンアップ対象が選択されていません。", .korean: "스캔이 완료되었지만 현재 선택된 정리 항목이 없습니다.", .russian: "Сканирование завершено, но очищаемые объекты не выбраны."])
    }

    private func manualReviewMessage(_ targets: [AIAssistantTarget]) -> String {
        let names = joinedNames(targets)
        return localized([
            .chinese: "\(names)需要你在模块中选择具体项目。已为你打开对应页面；选择后再使用页面底部按钮确认操作。",
            .traditionalChinese: "\(names)需要您在模組中選取具體項目。已為您開啟對應頁面；選取後再使用頁面底部按鈕確認操作。",
            .english: "\(names) requires you to choose specific items in the module. I opened the page; review the results and confirm with its bottom action button.",
            .japanese: "\(names)では、モジュール内で項目を選択する必要があります。該当ページを開きました。結果を確認し、下部の操作ボタンで確定してください。",
            .korean: "\(names)에서는 모듈에서 구체적인 항목을 선택해야 합니다. 해당 페이지를 열었습니다. 결과를 확인한 후 하단 작업 버튼으로 확정하세요.",
            .russian: "Для раздела «\(names)» необходимо выбрать конкретные объекты. Соответствующая страница открыта; проверьте результаты и подтвердите действие нижней кнопкой."
        ])
    }

    private func openedModuleMessage(_ target: AIAssistantTarget) -> String {
        let name = target.localizedName(language)
        return localized([.chinese: "已打开\(name)。", .traditionalChinese: "已開啟\(name)。", .english: "Opened \(name).", .japanese: "\(name)を開きました。", .korean: "\(name)을 열었습니다.", .russian: "Открыт раздел «\(name)»." ])
    }

    private var statusMessage: String {
        let scanning = services.isAnyScanning
        let count = services.totalItemsFound
        return localized([
            .chinese: scanning ? "当前仍在扫描，已发现 \(count) 个项目。" : "当前没有正在运行的扫描，已有结果共 \(count) 个项目。",
            .traditionalChinese: scanning ? "目前仍在掃描，已找到 \(count) 個項目。" : "目前沒有正在執行的掃描，現有結果共 \(count) 個項目。",
            .english: scanning ? "A scan is still running; \(count) items have been found." : "No scan is currently running; \(count) items are available in existing results.",
            .japanese: scanning ? "スキャンを実行中です。現在\(count)件が見つかっています。" : "実行中のスキャンはありません。既存の結果は\(count)件です。",
            .korean: scanning ? "현재 스캔 중이며 \(count)개 항목을 찾았습니다." : "현재 실행 중인 스캔이 없으며 기존 결과는 \(count)개입니다.",
            .russian: scanning ? "Сканирование продолжается. Найдено объектов: \(count)." : "Активного сканирования нет. В имеющихся результатах объектов: \(count)."
        ])
    }

    private var helpMessage: String {
        localized([
            .chinese: "你可以说：“扫描系统垃圾”“查找大型和旧文件”“检查隐私痕迹”“扫描后清理废纸篓”或“打开应用卸载”。删除类操作始终需要确认。",
            .traditionalChinese: "您可以說：「掃描系統垃圾」、「尋找大型與舊檔案」、「檢查隱私痕跡」、「掃描後清理廢紙簍」或「開啟應用程式解除安裝」。刪除類操作一律需要確認。",
            .english: "Try “scan system junk,” “find large and old files,” “check privacy traces,” “scan then clean the Trash,” or “open Uninstaller.” Deletion always requires confirmation.",
            .japanese: "「システムジャンクをスキャン」「大容量ファイルと古いファイルを検索」「プライバシー履歴を確認」「ゴミ箱をスキャンしてクリーンアップ」「アンインストーラを開く」などと入力できます。削除操作には必ず確認が必要です。",
            .korean: "“시스템 정크 스캔”, “대용량 및 오래된 파일 찾기”, “개인정보 흔적 확인”, “휴지통 스캔 후 정리”, “앱 제거 열기”처럼 요청할 수 있습니다. 삭제 작업은 항상 확인이 필요합니다.",
            .russian: "Можно написать: «просканировать системный мусор», «найти большие и старые файлы», «проверить следы конфиденциальности», «просканировать и очистить Корзину» или «открыть удаление приложений». Удаление всегда требует подтверждения."
        ])
    }

    private func providerFailureMessage(_ error: Error) -> String {
        let detail: String
        if case let AIProviderError.httpStatus(code) = error {
            detail = providerFailureDetail(code)
        } else {
            detail = localized([.chinese: "请求或响应格式无效", .traditionalChinese: "要求或回應格式無效", .english: "invalid request or response format", .japanese: "リクエストまたは応答形式が無効です", .korean: "요청 또는 응답 형식이 올바르지 않음", .russian: "недопустимый формат запроса или ответа"])
        }
        return localized([
            .chinese: "AI 服务暂时无法使用（\(detail)）。请检查 Base URL、模型和 API Key。没有执行扫描或清理。",
            .traditionalChinese: "AI 服務暫時無法使用（\(detail)）。請檢查 Base URL、模型與 API Key。未執行掃描或清理。",
            .english: "The AI service is unavailable (\(detail)). Check the Base URL, model, and API key. No scan or cleanup was run.",
            .japanese: "AIサービスを利用できません（\(detail)）。Base URL、モデル、APIキーを確認してください。スキャンやクリーンアップは実行されていません。",
            .korean: "AI 서비스를 사용할 수 없습니다(\(detail)). Base URL, 모델 및 API 키를 확인하세요. 스캔이나 정리는 실행되지 않았습니다.",
            .russian: "Служба ИИ недоступна (\(detail)). Проверьте Base URL, модель и API-ключ. Сканирование и очистка не запускались."
        ])
    }

    private func providerFailureDetail(_ code: Int) -> String {
        switch code {
        case 401:
            return localized([.chinese: "认证失败（HTTP \(code)）", .traditionalChinese: "驗證失敗（HTTP \(code)）", .english: "authentication failed (HTTP \(code))", .japanese: "認証に失敗しました（HTTP \(code)）", .korean: "인증 실패(HTTP \(code))", .russian: "ошибка аутентификации (HTTP \(code))"])
        case 402:
            return localized([.chinese: "余额或额度不足（HTTP 402）", .traditionalChinese: "餘額或額度不足（HTTP 402）", .english: "insufficient balance or quota (HTTP 402)", .japanese: "残高またはクォータ不足（HTTP 402）", .korean: "잔액 또는 할당량 부족(HTTP 402)", .russian: "недостаточно средств или квоты (HTTP 402)"])
        case 403:
            return localized([.chinese: "无权访问该模型（HTTP 403）", .traditionalChinese: "無權存取此模型（HTTP 403）", .english: "model access denied (HTTP 403)", .japanese: "モデルへのアクセス権がありません（HTTP 403）", .korean: "모델 접근 권한 없음(HTTP 403)", .russian: "нет доступа к модели (HTTP 403)"])
        case 429:
            return localized([.chinese: "请求过于频繁或额度不足（HTTP 429）", .traditionalChinese: "要求過於頻繁或額度不足（HTTP 429）", .english: "rate limit or quota reached (HTTP 429)", .japanese: "レート制限またはクォータに達しました（HTTP 429）", .korean: "요청 한도 또는 할당량 초과(HTTP 429)", .russian: "превышена частота запросов или квота (HTTP 429)"])
        case 404:
            return localized([.chinese: "接口或模型不存在（HTTP 404）", .traditionalChinese: "介面或模型不存在（HTTP 404）", .english: "endpoint or model not found (HTTP 404)", .japanese: "エンドポイントまたはモデルが見つかりません（HTTP 404）", .korean: "엔드포인트 또는 모델을 찾을 수 없음(HTTP 404)", .russian: "интерфейс или модель не найдены (HTTP 404)"])
        default:
            return "HTTP \(code)"
        }
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 MB" }
        let value: Double
        let unit: String
        if bytes >= 1_073_741_824 {
            value = Double(bytes) / 1_073_741_824
            unit = "GB"
        } else if bytes >= 1_048_576 {
            value = Double(bytes) / 1_048_576
            unit = "MB"
        } else {
            value = Double(bytes) / 1024
            unit = "KB"
        }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.maximumFractionDigits = value >= 10 ? 0 : 1
        return "\(formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)) \(unit)"
    }
}
