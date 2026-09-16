import SwiftUI

@main
struct AppUninstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Hold a strong reference to the manager (Keep it, but access via shared in AppDelegate if needed)
    @StateObject var menuBarManager = MenuBarManager.shared
    @StateObject private var localization = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if localization.hasSelectedLanguage {
                    ContentView()
                } else {
                    LanguageSelectionView(isInitialSetup: true) { }
                }
            }
                .frame(minWidth: 980, minHeight: 600)
                .preferredColorScheme(.dark)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        AppMenuLocalizer.apply(localization.currentLanguage)
                    }
                }
                .task {
                    if localization.hasSelectedLanguage {
                        await UpdateCheckerService.shared.checkForUpdates()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu(localization.text(
                simplifiedChinese: "语言",
                traditionalChinese: "語言",
                english: "Language",
                japanese: "言語",
                korean: "언어",
                russian: "Язык"
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        localization.setLanguage(language)
                    } label: {
                        if localization.currentLanguage == language {
                            Label(language.displayName, systemImage: "checkmark")
                        } else {
                            Text(language.displayName)
                        }
                    }
                }
            }

            CommandMenu("Codex") {
                Button {
                    CodexRoundTripWindowController.shared.show()
                } label: {
                    Label(
                        localization.text(
                            simplifiedChinese: "打开 Codex 安全审阅",
                            traditionalChinese: "開啟 Codex 安全審閱",
                            english: "Open Codex Safe Review",
                            japanese: "Codex セーフレビューを開く",
                            korean: "Codex 안전 검토 열기",
                            russian: "Открыть безопасную проверку Codex"
                        ),
                        systemImage: "checklist"
                    )
                }

                Button {
                    CodexJunkGroupWindowController.shared.show()
                } label: {
                    Label(
                        localization.text(
                            simplifiedChinese: "打开垃圾缓存分组审阅",
                            traditionalChinese: "開啟垃圾快取分組審閱",
                            english: "Open Junk Cache Group Review",
                            japanese: "ジャンクキャッシュのグループレビューを開く",
                            korean: "정크 캐시 그룹 검토 열기",
                            russian: "Открыть групповую проверку кэша"
                        ),
                        systemImage: "square.stack.3d.up"
                    )
                }
            }
        }
        // Keep AppKit's native titlebar buttons. AppDelegate makes the
        // titlebar transparent and expands the content under it, matching the
        // original CleanMyMac window without drawing replacement traffic
        // lights in SwiftUI.
        
        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
        }

        // MenuBarExtra removed. Manager logic runs on init.
    }
}