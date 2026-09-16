import XCTest
@testable import AppUninstaller

final class LocalizationManagerTests: XCTestCase {
    private var localization: LocalizationManager!

    override func setUp() {
        super.setUp()
        localization = LocalizationManager()
    }

    override func tearDown() {
        localization = nil
        super.tearDown()
    }

    func testDynamicSinglePlaceholderInEveryLanguage() {
        let source = "Deleted 3 snapshots"
        let simplifiedChinese = "已删除 3 个快照"
        let expected: [AppLanguage: String] = [
            .chinese: simplifiedChinese,
            .traditionalChinese: "已刪除 3 個快照",
            .english: source,
            .japanese: "3個のスナップショットを削除しました",
            .korean: "스냅샷 3개 삭제됨",
            .russian: "Удалено снимков: 3"
        ]

        assertTranslations(simplifiedChinese, source, expected: expected)
    }

    func testDynamicMultiplePlaceholdersCanBeReordered() {
        let source = "2 GB used of 8 GB"
        let simplifiedChinese = "已使用 2 GB，共 8 GB"
        let expected: [AppLanguage: String] = [
            .chinese: simplifiedChinese,
            .traditionalChinese: "已使用 2 GB，共 8 GB",
            .english: source,
            .japanese: "2 GB / 8 GB 使用済み",
            .korean: "8 GB 중 2 GB 사용됨",
            .russian: "Занято: 2 GB из 8 GB"
        ]

        assertTranslations(simplifiedChinese, source, expected: expected)
    }

    func testDynamicFileNameIsPreserved() {
        let source = "Are you sure you want to delete \"demo.txt\"? This action cannot be undone."
        let simplifiedChinese = "确定要删除“demo.txt”吗？此操作无法撤销。"
        let expected: [AppLanguage: String] = [
            .chinese: simplifiedChinese,
            .traditionalChinese: "您確定要刪除「demo.txt」嗎？此動作無法復原。",
            .english: source,
            .japanese: "「demo.txt」を削除してもよろしいですか？この操作は元に戻せません。",
            .korean: "\"demo.txt\" 파일을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.",
            .russian: "Вы уверены, что хотите удалить «demo.txt»? Это действие необратимо."
        ]

        assertTranslations(simplifiedChinese, source, expected: expected)
    }

    func testDynamicPlaceholderAcrossLineBreaks() {
        let source = "This will clean all cache, logs, and config data.\nThe app itself (42 MB) will be kept."
        let simplifiedChinese = "此操作将清除 App 的所有缓存、日志和配置数据。\nApp 本身（42 MB）将被保留。"
        let expected: [AppLanguage: String] = [
            .chinese: simplifiedChinese,
            .traditionalChinese: "此操作將清除 App 的所有快取、記錄檔和配置資料。\nApp 本身（42 MB）將被保留。",
            .english: source,
            .japanese: "これにより、App のキャッシュ、ログ、構成データがすべてクリーンアップされます。\nApp 本体（42 MB）は保持されます。",
            .korean: "이 작업은 앱의 모든 캐시, 로그 및 구성 데이터를 정리합니다.\n앱 자체(42 MB)는 유지됩니다.",
            .russian: "Будут удалены все кэш, журналы и данные конфигурации.\nСамо приложение (42 MB) будет сохранено."
        ]

        assertTranslations(simplifiedChinese, source, expected: expected)
    }

    func testLegacyBrandNameIsNormalizedAtLocalizationBoundary() {
        localization.currentLanguage = .chinese
        XCTAssertEqual(
            localization.text("欢迎使用Mac优化大师", "Welcome to MacOptimizer"),
            "欢迎使用MacOptimizer"
        )

        localization.currentLanguage = .traditionalChinese
        XCTAssertEqual(
            localization.text(
                simplifiedChinese: "Mac优化大师",
                traditionalChinese: "Mac最佳化大師",
                english: "MacOptimizer",
                japanese: "Macオプティマイザー",
                korean: "Mac 최적화 도구",
                russian: "MacOptimizer"
            ),
            "MacOptimizer"
        )
    }

    func testStandardMenuIndicesIgnoreCustomCodexMenuBetweenLanguageAndWindow() {
        let titles = ["MacOptimizer", "File", "Edit", "View", "Language", "Codex", "Window", "Help"]

        let indices = AppMenuLocalizer.standardMenuIndices(in: titles)

        XCTAssertEqual(indices.window, 6)
        XCTAssertEqual(indices.help, 7)
        XCTAssertEqual(titles[5], "Codex")
    }

    func testStandardMenuIndicesRecognizeLocalizedWindowAndHelpTitles() {
        let titles = ["Mac优化大师", "文件", "编辑", "显示", "语言", "Codex", "窗口", "帮助"]

        let indices = AppMenuLocalizer.standardMenuIndices(in: titles)

        XCTAssertEqual(indices.window, 6)
        XCTAssertEqual(indices.help, 7)
    }

    private func assertTranslations(
        _ simplifiedChinese: String,
        _ english: String,
        expected: [AppLanguage: String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for language in AppLanguage.allCases {
            localization.currentLanguage = language
            XCTAssertEqual(
                localization.text(simplifiedChinese, english),
                expected[language],
                "Unexpected translation for \(language.rawValue)",
                file: file,
                line: line
            )
        }
    }
}
