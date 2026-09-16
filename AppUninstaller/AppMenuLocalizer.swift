import AppKit

/// SwiftUI builds the standard macOS menu from the operating-system language.
/// The product language is an in-app choice, so update AppKit-owned menu copy
/// as well to keep the menu bar from mixing languages after a live switch.
enum AppMenuLocalizer {
    static func apply(_ language: AppLanguage) {
        guard let mainMenu = NSApp.mainMenu else { return }

        let topLevelTitles = localizedTopLevelTitles(language)
        if !mainMenu.items.isEmpty { setTopLevelTitle(ProductIdentity.displayName, item: mainMenu.items[0]) }
        if mainMenu.items.count > 1 { setTopLevelTitle(topLevelTitles.file, item: mainMenu.items[1]) }
        if mainMenu.items.count > 2 { setTopLevelTitle(topLevelTitles.edit, item: mainMenu.items[2]) }
        if mainMenu.items.count > 3 { setTopLevelTitle(topLevelTitles.view, item: mainMenu.items[3]) }

        // Do not assume Window and Help immediately follow the in-app Language menu.
        // Custom CommandMenu entries (for example Codex) may sit between them.
        // Resolve the standard menus by their known localized titles instead.
        let standardIndices = standardMenuIndices(in: mainMenu.items.map(\.title))
        if let windowIndex = standardIndices.window, mainMenu.items.indices.contains(windowIndex) {
            setTopLevelTitle(topLevelTitles.window, item: mainMenu.items[windowIndex])
        }
        if let helpIndex = standardIndices.help, mainMenu.items.indices.contains(helpIndex) {
            setTopLevelTitle(topLevelTitles.help, item: mainMenu.items[helpIndex])
        }

        for item in mainMenu.items {
            let current = item.title
            if isApplicationMenuTitle(current) {
                setTopLevelTitle(ProductIdentity.displayName, item: item)
            } else if matches(current, ["文件", "檔案", "File", "ファイル", "파일", "Файл"]) {
                item.title = topLevelTitles.file
            } else if matches(current, ["编辑", "編輯", "Edit", "編集", "편집", "Правка"]) {
                item.title = topLevelTitles.edit
            } else if matches(current, ["显示", "顯示方式", "View", "表示", "보기", "Вид"]) {
                item.title = topLevelTitles.view
            } else if matches(current, ["窗口", "視窗", "Window", "ウインドウ", "윈도우", "Окно"]) {
                item.title = topLevelTitles.window
            } else if matches(current, ["帮助", "輔助說明", "Help", "ヘルプ", "도움말", "Справка"]) {
                item.title = topLevelTitles.help
            }
            localize(menu: item.submenu, language: language)
        }

        NSApp.mainWindow?.title = ProductIdentity.displayName

        let settingsTitle = t(language, "设置", "設定", "Settings", "設定", "설정", "Настройки")
        for window in NSApp.windows where window.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" {
            window.title = "\(ProductIdentity.displayName) — \(settingsTitle)"
        }
    }

    /// Returns standard Window/Help menu positions without relying on adjacency.
    /// Kept internal so the menu-shape contract can be covered by tests without
    /// mutating NSApplication global state.
    static func standardMenuIndices(in titles: [String]) -> (window: Int?, help: Int?) {
        let windowTitles = ["窗口", "視窗", "Window", "ウインドウ", "윈도우", "Окно"]
        let helpTitles = ["帮助", "輔助說明", "Help", "ヘルプ", "도움말", "Справка"]
        return (
            window: titles.firstIndex(where: { windowTitles.contains($0) }),
            help: titles.firstIndex(where: { helpTitles.contains($0) })
        )
    }

    private static func localize(menu: NSMenu?, language: AppLanguage) {
        guard let menu else { return }
        for item in menu.items {
            if let action = item.action {
                let selector = NSStringFromSelector(action)
                if let title = localizedActionTitle(selector, language: language) {
                    item.title = title
                }
            }
            localize(menu: item.submenu, language: language)
        }
    }

    private static func localizedActionTitle(_ selector: String, language: AppLanguage) -> String? {
        switch selector {
        case "orderFrontStandardAboutPanel:": return t(language, "关于", "關於", "About", "このアプリについて", "앱 정보", "О приложении")
        case "showSettingsWindow:", "showPreferencesWindow:": return t(language, "设置…", "設定…", "Settings…", "設定…", "설정…", "Настройки…")
        case "hide:": return t(language, "隐藏", "隱藏", "Hide", "隠す", "가리기", "Скрыть")
        case "hideOtherApplications:": return t(language, "隐藏其他应用", "隱藏其他應用程式", "Hide Others", "ほかを隠す", "기타 가리기", "Скрыть остальные")
        case "unhideAllApplications:": return t(language, "全部显示", "全部顯示", "Show All", "すべてを表示", "모두 보기", "Показать все")
        case "terminate:": return t(language, "退出", "結束", "Quit", "終了", "종료", "Выйти")
        case "performClose:": return t(language, "关闭窗口", "關閉視窗", "Close Window", "ウインドウを閉じる", "윈도우 닫기", "Закрыть окно")
        case "undo:": return t(language, "撤销", "還原", "Undo", "取り消す", "실행 취소", "Отменить")
        case "redo:": return t(language, "重做", "重做", "Redo", "やり直す", "다시 실행", "Повторить")
        case "cut:": return t(language, "剪切", "剪下", "Cut", "カット", "오려두기", "Вырезать")
        case "copy:": return t(language, "复制", "複製", "Copy", "コピー", "복사", "Копировать")
        case "paste:": return t(language, "粘贴", "貼上", "Paste", "ペースト", "붙여넣기", "Вставить")
        case "delete:": return t(language, "删除", "刪除", "Delete", "削除", "삭제", "Удалить")
        case "selectAll:": return t(language, "全选", "全選", "Select All", "すべてを選択", "모두 선택", "Выбрать все")
        case "performMiniaturize:": return t(language, "最小化", "縮到最小", "Minimize", "しまう", "최소화", "Свернуть")
        case "performZoom:": return t(language, "缩放", "縮放", "Zoom", "拡大／縮小", "확대/축소", "Масштаб")
        case "toggleFullScreen:": return t(language, "进入全屏幕", "進入全螢幕", "Enter Full Screen", "フルスクリーンにする", "전체 화면 시작", "На весь экран")
        default: return nil
        }
    }

    private static func localizedTopLevelTitles(_ language: AppLanguage) -> (file: String, edit: String, view: String, window: String, help: String) {
        switch language {
        case .chinese: return ("文件", "编辑", "显示", "窗口", "帮助")
        case .traditionalChinese: return ("檔案", "編輯", "顯示方式", "視窗", "輔助說明")
        case .english: return ("File", "Edit", "View", "Window", "Help")
        case .japanese: return ("ファイル", "編集", "表示", "ウインドウ", "ヘルプ")
        case .korean: return ("파일", "편집", "보기", "윈도우", "도움말")
        case .russian: return ("Файл", "Правка", "Вид", "Окно", "Справка")
        }
    }

    private static func t(_ language: AppLanguage, _ zhHans: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String, _ ru: String) -> String {
        switch language {
        case .chinese: return zhHans
        case .traditionalChinese: return zhHant
        case .english: return en
        case .japanese: return ja
        case .korean: return ko
        case .russian: return ru
        }
    }

    private static func matches(_ title: String, _ candidates: [String]) -> Bool {
        candidates.contains(title)
    }

    private static func isApplicationMenuTitle(_ title: String) -> Bool {
        ["Mac优化大师", "Mac最佳化大師", "MacOptimizer", "Macオプティマイザー", "Mac 최적화 도구"].contains(title)
    }

    private static func setTopLevelTitle(_ title: String, item: NSMenuItem) {
        item.title = title
        item.submenu?.title = title
    }
}
