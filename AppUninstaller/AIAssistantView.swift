import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AIAssistantView: View {
    let currentModule: AppModule

    @ObservedObject private var assistant = AIAssistantCoordinator.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var input = ""
    @State private var attachments: [AIAttachment] = []
    @State private var composerHeight: CGFloat = 32
    @State private var attachmentError = ""

    var body: some View {
        VStack(spacing: 0) {
            header

            if assistant.showsSettings {
                AIAssistantSettingsView {
                    assistant.showsSettings = false
                }
            } else {
                conversation
            }
        }
        .frame(width: 740, height: 630)
        .background(agentBackground)
    }

    private var agentBackground: some View {
        ZStack {
            Color(red: 0.065, green: 0.071, blue: 0.082)
            LinearGradient(
                colors: [Color.white.opacity(0.035), Color.clear, Color.black.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(Color(red: 0.36, green: 0.76, blue: 0.66).opacity(0.045))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: -310, y: -260)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color(red: 0.22, green: 0.56, blue: 0.49))
                    .frame(width: 34, height: 34)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.94, green: 1.0, blue: 0.98))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(t("Mac 优化智能体", "Mac 最佳化智慧代理", "Mac Optimization Agent", "Mac最適化エージェント", "Mac 최적화 에이전트", "Агент оптимизации Mac"))
                    .font(.system(size: 15, weight: .semibold))
                Text(t("本机扫描 · 只读分析 · 性能诊断", "本機掃描 · 唯讀分析 · 效能診斷", "Local scanning · Read-only analysis · Diagnostics", "ローカルスキャン · 読み取り専用分析 · 診断", "로컬 검사 · 읽기 전용 분석 · 진단", "Локальное сканирование · Анализ только для чтения · Диагностика"))
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            Button {
                assistant.showsSettings.toggle()
            } label: {
                Image(systemName: assistant.showsSettings ? "message" : "gearshape")
                    .frame(width: 27, height: 27)
            }
            .help(assistant.showsSettings
                  ? t("返回 Mac 优化智能体", "返回 Mac 最佳化智慧代理", "Back to Mac Optimization Agent", "Mac最適化エージェントに戻る", "Mac 최적화 에이전트로 돌아가기", "Вернуться к агенту оптимизации Mac")
                  : t("智能体模型设置", "智慧代理模型設定", "Agent Model Settings", "エージェントモデル設定", "에이전트 모델 설정", "Настройки модели агента"))
            .buttonStyle(AIAssistantToolbarButtonStyle())

            Button {
                assistant.isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 27, height: 27)
            }
            .buttonStyle(AIAssistantToolbarButtonStyle())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 17)
        .frame(height: 58)
        .background(Color.black.opacity(0.14))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    private var conversation: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(assistant.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if assistant.isWorking {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text(assistant.progressText)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.64))
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 22)
                }
                .onChange(of: assistant.messages.count) { _ in
                    guard let last = assistant.messages.last else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            composer
        }
    }

    private func messageBubble(_ message: AIAssistantMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user { Spacer(minLength: 88) }

            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.72, green: 0.94, blue: 0.86))
                    .frame(width: 25, height: 25)
                    .background(Color(red: 0.22, green: 0.56, blue: 0.49).opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if !message.attachments.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 108, maximum: 148), spacing: 8)], spacing: 8) {
                        ForEach(message.attachments) { attachment in
                            if let image = attachment.image {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 116, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.13), lineWidth: 1))
                            }
                        }
                    }
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 13.5))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .padding(.horizontal, message.role == .user ? 14 : 0)
                        .padding(.vertical, message.role == .user ? 10 : 1)
                        .background(message.role == .user ? Color(red: 0.20, green: 0.23, blue: 0.28).opacity(0.92) : Color.clear, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }

                if shouldShowClearHistory(after: message) {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            assistant.clearConversation(currentModule: currentModule)
                        }
                    } label: {
                        Label(
                            t("清除聊天记录", "清除聊天記錄", "Clear chat history", "チャット履歴を消去", "채팅 기록 지우기", "Очистить историю чата"),
                            systemImage: "trash"
                        )
                    }
                    .buttonStyle(AIAssistantInlineActionButtonStyle())
                    .help(t("清除聊天记录", "清除聊天記錄", "Clear chat history", "チャット履歴を消去", "채팅 기록 지우기", "Очистить историю чата"))
                }
            }

            if message.role == .assistant { Spacer(minLength: 88) }
        }
    }

    private func shouldShowClearHistory(after message: AIAssistantMessage) -> Bool {
        message.role == .assistant
            && message.id == assistant.messages.last?.id
            && assistant.messages.contains(where: { $0.role == .user })
            && !assistant.isWorking
    }

    private var composer: some View {
        VStack(spacing: 7) {
            VStack(spacing: 8) {
                if !attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(attachments) { attachment in
                                attachmentThumbnail(attachment)
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.top, 2)
                    }
                    .frame(height: 76)
                }

                ZStack(alignment: .topLeading) {
                    if input.isEmpty {
                        Text(t("告诉 Mac 优化智能体你要检查什么", "告訴 Mac 最佳化智慧代理您要檢查什麼", "Tell Mac Optimization Agent what to inspect", "Mac最適化エージェントに確認内容を伝える", "Mac 최적화 에이전트에게 검사할 내용을 알려 주세요", "Укажите агенту оптимизации Mac, что проверить"))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.38))
                            .padding(.top, 6)
                            .allowsHitTesting(false)
                    }
                    AIComposerTextView(
                        text: $input,
                        measuredHeight: $composerHeight,
                        onSend: send,
                        onPasteAttachments: addAttachments(from:)
                    )
                    .frame(height: composerHeight)
                }

                HStack(spacing: 10) {
                    Button(action: chooseImages) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.78))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.07), in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.09), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help(t("添加图片", "加入圖片", "Add images", "画像を追加", "이미지 추가", "Добавить изображения"))

                    Text(t("粘贴或拖入图片", "貼上或拖入圖片", "Paste or drop images", "画像を貼り付けまたはドロップ", "이미지 붙여넣기 또는 드롭", "Вставьте или перетащите изображения"))
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.34))

                    Spacer()

                    Button(action: send) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(canSend ? Color(red: 0.08, green: 0.11, blue: 0.16) : .white.opacity(0.34))
                            .frame(width: 31, height: 31)
                            .background(canSend ? Color.white : Color.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                    .help(t("发送", "傳送", "Send", "送信", "보내기", "Отправить"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, attachments.isEmpty ? 9 : 10)
            .padding(.bottom, 10)
            .background(Color(red: 0.105, green: 0.115, blue: 0.135).opacity(0.98), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(Color.white.opacity(0.11), lineWidth: 1))
            .shadow(color: .black.opacity(0.16), radius: 14, y: 6)

            if !attachmentError.isEmpty {
                Text(attachmentError)
                    .font(.system(size: 10.5))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    private var canSend: Bool {
        (!input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty) && !assistant.isWorking
    }

    private func attachmentThumbnail(_ attachment: AIAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            if let image = attachment.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.16), lineWidth: 1))
            }
            Button {
                attachments.removeAll { $0.id == attachment.id }
                attachmentError = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 17, height: 17)
                    .background(Color.black.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .offset(x: 5, y: -5)
        }
        .padding(.top, 5)
        .padding(.trailing, 5)
    }

    private func send() {
        guard canSend else { return }
        let request = input
        let sentAttachments = attachments
        input = ""
        attachments = []
        attachmentError = ""
        Task { await assistant.submit(request, attachments: sentAttachments, currentModule: currentModule) }
    }

    private func chooseImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .webP, .heic, .heif]
        panel.prompt = t("添加", "加入", "Add", "追加", "추가", "Добавить")
        guard panel.runModal() == .OK else { return }
        add(urls: panel.urls)
    }

    private func addAttachments(from pasteboard: NSPasteboard) -> Bool {
        do {
            let added = try AIAttachmentLoader.attachments(
                from: pasteboard,
                availableSlots: AIAttachmentLoader.maximumCount - attachments.count
            )
            guard !added.isEmpty else { return false }
            attachments.append(contentsOf: added)
            attachmentError = ""
            return true
        } catch {
            attachmentError = attachmentErrorMessage(error)
            return true
        }
    }

    private func add(urls: [URL]) {
        do {
            attachments.append(contentsOf: try AIAttachmentLoader.load(
                urls: urls,
                availableSlots: AIAttachmentLoader.maximumCount - attachments.count
            ))
            attachmentError = ""
        } catch {
            attachmentError = attachmentErrorMessage(error)
        }
    }

    private func attachmentErrorMessage(_ error: Error) -> String {
        switch error {
        case AIAttachmentLoadError.tooMany:
            return t("最多可添加 8 张图片", "最多可加入 8 張圖片", "You can add up to 8 images", "画像は最大8枚まで追加できます", "이미지는 최대 8개까지 추가할 수 있습니다", "Можно добавить не более 8 изображений")
        case AIAttachmentLoadError.tooLarge:
            return t("每张图片不能超过 15 MB", "每張圖片不能超過 15 MB", "Each image must be 15 MB or smaller", "各画像は15 MB以下にしてください", "각 이미지는 15MB 이하여야 합니다", "Размер каждого изображения не должен превышать 15 МБ")
        case AIAttachmentLoadError.unsupportedFormat:
            return t("仅支持 PNG、JPEG、WebP 和 HEIC 图片", "僅支援 PNG、JPEG、WebP 與 HEIC 圖片", "Only PNG, JPEG, WebP, and HEIC images are supported", "PNG、JPEG、WebP、HEIC画像のみ対応しています", "PNG, JPEG, WebP 및 HEIC 이미지만 지원됩니다", "Поддерживаются только PNG, JPEG, WebP и HEIC")
        default:
            return t("无法读取这张图片", "無法讀取此圖片", "This image could not be read", "この画像を読み込めません", "이 이미지를 읽을 수 없습니다", "Не удалось прочитать изображение")
        }
    }

    private func t(_ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String, _ ru: String) -> String {
        loc.text(simplifiedChinese: zh, traditionalChinese: zhHant, english: en, japanese: ja, korean: ko, russian: ru)
    }
}

struct AIAssistantSettingsView: View {
    var onSaved: (() -> Void)?

    @ObservedObject private var store = AIProviderSettingsStore.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedProvider = AIProviderSettingsStore.shared.activeProvider
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var model = ""
    @State private var statusMessage = ""
    @State private var statusIsError = false
    @State private var isTesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                zaomengPromotionCard

                VStack(alignment: .leading, spacing: 4) {
                    Text(t("模型连接", "模型連線", "Model Connection", "モデル接続", "모델 연결", "Подключение модели"))
                        .font(.system(size: 16, weight: .semibold))
                    Text(t("选择接口协议并填写你的模型服务。支持官方接口和兼容中转服务。", "選擇介面協定並填寫您的模型服務。支援官方介面與相容中轉服務。", "Choose an API protocol and enter your model service. Official APIs and compatible gateways are supported.", "APIプロトコルを選択し、モデルサービスを入力してください。公式APIと互換ゲートウェイに対応しています。", "API 프로토콜을 선택하고 모델 서비스를 입력하세요. 공식 API와 호환 게이트웨이를 지원합니다.", "Выберите протокол API и укажите сервис модели. Поддерживаются официальные API и совместимые шлюзы."))
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.48))
                }

                Picker("", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedProvider) { provider in load(provider) }

                settingsField(
                    title: "Base URL",
                    detail: endpointHint,
                    content: AnyView(
                        TextField(selectedProvider.defaultBaseURL, text: $baseURL)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(settingsInputBackground)
                    )
                )

                settingsField(
                    title: t("模型", "模型", "Model", "モデル", "모델", "Модель"),
                    detail: t("模型名称会原样发送，不限制服务商或中转命名", "模型名稱會原樣傳送，不限制服務商或中轉命名", "The model name is sent unchanged; provider and gateway naming are not restricted", "モデル名は変更せず送信され、プロバイダーやゲートウェイの命名を制限しません", "모델 이름은 그대로 전송되며 제공업체나 게이트웨이 이름을 제한하지 않습니다", "Имя модели передаётся без изменений; названия поставщиков и шлюзов не ограничиваются"),
                    content: AnyView(
                        TextField(selectedProvider.defaultModel, text: $model)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(settingsInputBackground)
                    )
                )

                settingsField(
                    title: "API Key",
                    detail: t("配置保存在普通明文 JSON 文件中，不使用钥匙串", "設定儲存在普通明文 JSON 檔案中，不使用鑰匙圈", "Settings are stored in a regular plain-text JSON file; Keychain is not used", "設定は通常のプレーンテキストJSONファイルに保存され、キーチェーンは使用しません", "설정은 일반 텍스트 JSON 파일에 저장되며 키체인을 사용하지 않습니다", "Настройки хранятся в обычном открытом JSON-файле; Связка ключей не используется"),
                    content: AnyView(
                        SecureField("••••••••••••", text: $apiKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(settingsInputBackground)
                    )
                )

                if !statusMessage.isEmpty {
                    HStack(spacing: 7) {
                        Image(systemName: statusIsError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        Text(statusMessage)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(statusIsError ? .orange : .green)
                }

                HStack {
                    Spacer()
                    Button {
                        save()
                    } label: {
                        Text(t("保存", "儲存", "Save", "保存", "저장", "Сохранить"))
                            .frame(minWidth: 72)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack(spacing: 6) {
                            if isTesting { ProgressView().controlSize(.small) }
                            Text(t("保存并测试连接", "儲存並測試連線", "Save & Test Connection", "保存して接続をテスト", "저장 및 연결 테스트", "Сохранить и проверить"))
                        }
                        .frame(minWidth: 130)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTesting)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onAppear { load(selectedProvider) }
    }

    private var zaomengPromotionCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 11) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.66))
                    .frame(width: 34, height: 34)
                    .background(Color(red: 0.82, green: 0.30, blue: 0.20).opacity(0.20), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(t("造梦影视与设计平台", "造夢影視與設計平台", "Zaomeng Film & Design Platform", "造夢 映像・デザインプラットフォーム", "Zaomeng 영상 및 디자인 플랫폼", "Платформа Zaomeng для кино и дизайна"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.94))

                Spacer(minLength: 12)

                Link(destination: URL(string: "https://zaomeng.art")!) {
                    HStack(spacing: 5) {
                        Text(t("前往体验", "前往體驗", "Try it", "体験する", "체험하기", "Попробовать"))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.86, blue: 0.78))
                    .padding(.horizontal, 11)
                    .frame(height: 28)
                    .background(Color(red: 0.82, green: 0.30, blue: 0.20).opacity(0.24), in: Capsule())
                    .overlay(Capsule().stroke(Color(red: 1.0, green: 0.55, blue: 0.40).opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text(t("专注于 AI 生图、AI 生视频、AI 设计智能体与 AI 导演智能体。", "專注於 AI 生圖、AI 生影片、AI 設計智慧代理與 AI 導演智慧代理。", "Focused on AI image generation, AI video generation, AI design agents, and AI director agents.", "AI画像生成、AI動画生成、AIデザインエージェント、AI監督エージェントに特化しています。", "AI 이미지 생성, AI 영상 생성, AI 디자인 에이전트와 AI 감독 에이전트에 특화되어 있습니다.", "Специализируется на генерации изображений и видео с ИИ, дизайн-агентах и ИИ-режиссёрах."))
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.white.opacity(0.74))

            Text(t("欢迎前往 zaomeng.art，在最新的智能画布上进行创作。", "歡迎前往 zaomeng.art，在最新的智慧畫布上進行創作。", "Visit zaomeng.art and create on the latest intelligent canvas.", "zaomeng.artにアクセスし、最新のインテリジェントキャンバスで制作を始めましょう。", "zaomeng.art에서 최신 지능형 캔버스로 창작해 보세요.", "Посетите zaomeng.art и создавайте работы на новейшем интеллектуальном холсте."))
                .font(.system(size: 10.5))
                .foregroundColor(.white.opacity(0.48))
        }
        .padding(15)
        .background(Color(red: 0.12, green: 0.125, blue: 0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(red: 1.0, green: 0.52, blue: 0.38).opacity(0.18), lineWidth: 1))
    }

    private var settingsInputBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.white.opacity(0.065))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }

    private var endpointHint: String {
        switch selectedProvider {
        case .openAI:
            return t("使用 OpenAI Chat Completions 兼容格式，自动追加 /chat/completions", "使用 OpenAI Chat Completions 相容格式，自動附加 /chat/completions", "Uses the OpenAI Chat Completions-compatible format and appends /chat/completions", "OpenAI Chat Completions互換形式を使用し、/chat/completionsを自動的に追加します", "OpenAI Chat Completions 호환 형식을 사용하며 /chat/completions를 자동으로 추가합니다", "Используется формат OpenAI Chat Completions; /chat/completions добавляется автоматически")
        case .gemini:
            return t("使用 Gemini generateContent 原生格式", "使用 Gemini generateContent 原生格式", "Uses Gemini’s native generateContent format", "GeminiのネイティブgenerateContent形式を使用します", "Gemini 기본 generateContent 형식을 사용합니다", "Используется нативный формат Gemini generateContent")
        case .claude:
            return t("使用 Anthropic Messages 原生格式，自动追加 /messages", "使用 Anthropic Messages 原生格式，自動附加 /messages", "Uses Anthropic’s native Messages format and appends /messages", "AnthropicのネイティブMessages形式を使用し、/messagesを自動的に追加します", "Anthropic 기본 Messages 형식을 사용하며 /messages를 자동으로 추가합니다", "Используется нативный формат Anthropic Messages; /messages добавляется автоматически")
        }
    }

    private func settingsField(title: String, detail: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 13, weight: .semibold))
            content
            Text(detail)
                .font(.system(size: 10.5))
                .foregroundColor(.white.opacity(0.42))
        }
    }

    private func load(_ provider: AIProvider) {
        let configuration = store.configuration(for: provider)
        baseURL = configuration.baseURL
        apiKey = configuration.apiKey
        model = configuration.model
        statusMessage = ""
    }

    private func save() {
        guard validateDraft() else { return }
        do {
            try store.save(provider: selectedProvider, baseURL: baseURL, apiKey: apiKey, model: model)
            statusIsError = false
            statusMessage = t("设置已保存到配置文件", "設定已儲存至設定檔", "Settings saved to the configuration file", "設定ファイルに保存しました", "설정 파일에 저장했습니다", "Настройки сохранены в файл конфигурации")
            onSaved?()
        } catch {
            statusIsError = true
            statusMessage = t("无法写入 AI 配置文件", "無法寫入 AI 設定檔", "Could not write the AI configuration file", "AI設定ファイルに書き込めませんでした", "AI 설정 파일에 쓸 수 없습니다", "Не удалось записать файл конфигурации ИИ")
        }
    }

    private func testConnection() async {
        guard validateDraft() else { return }
        isTesting = true
        defer { isTesting = false }
        do {
            try store.save(provider: selectedProvider, baseURL: baseURL, apiKey: apiKey, model: model)
            _ = try await AIProviderClient().generateJSON(
                configuration: store.configuration(for: selectedProvider),
                systemPrompt: "Return JSON only.",
                userPrompt: "Return exactly {\"status\":\"ok\"}."
            )
            statusIsError = false
            statusMessage = t("连接成功，Mac 优化智能体已可使用", "連線成功，Mac 最佳化智慧代理已可使用", "Connection successful. Mac Optimization Agent is ready.", "接続に成功しました。Mac最適化エージェントを使用できます。", "연결되었습니다. Mac 최적화 에이전트를 사용할 수 있습니다.", "Подключение выполнено. Агент оптимизации Mac готов к работе.")
            onSaved?()
        } catch {
            statusIsError = true
            if case let AIProviderError.httpStatus(code) = error {
                statusMessage = httpFailureMessage(code)
            } else {
                statusMessage = t("连接失败，请检查地址、模型和密钥", "連線失敗，請檢查位址、模型與金鑰", "Connection failed. Check the endpoint, model, and key.", "接続に失敗しました。エンドポイント、モデル、キーを確認してください。", "연결에 실패했습니다. 주소, 모델 및 키를 확인하세요.", "Ошибка подключения. Проверьте адрес, модель и ключ.")
            }
        }
    }

    private func httpFailureMessage(_ code: Int) -> String {
        switch code {
        case 401:
            return t("认证失败（HTTP \(code)）。请确认 API Key 来自当前服务商、仍然有效，且账户可用。", "驗證失敗（HTTP \(code)）。請確認 API Key 來自目前服務商、仍然有效，且帳戶可用。", "Authentication failed (HTTP \(code)). Confirm that the API key belongs to this provider, is still valid, and the account is active.", "認証に失敗しました（HTTP \(code)）。APIキーがこのプロバイダーのもので有効であり、アカウントが利用可能か確認してください。", "인증에 실패했습니다(HTTP \(code)). API 키가 현재 제공업체의 것이며 유효하고 계정을 사용할 수 있는지 확인하세요.", "Ошибка аутентификации (HTTP \(code)). Убедитесь, что API-ключ выдан этим поставщиком, не истёк и учётная запись активна.")
        case 402:
            return t("账户余额或额度不足（HTTP 402）。请检查服务商账户的余额和套餐状态。", "帳戶餘額或額度不足（HTTP 402）。請檢查服務商帳戶的餘額與方案狀態。", "The account balance or quota is insufficient (HTTP 402). Check the provider account balance and plan status.", "残高またはクォータが不足しています（HTTP 402）。プロバイダーの残高とプラン状態を確認してください。", "계정 잔액 또는 할당량이 부족합니다(HTTP 402). 제공업체 계정의 잔액과 요금제 상태를 확인하세요.", "Недостаточно средств или квоты (HTTP 402). Проверьте баланс и тариф у поставщика.")
        case 403:
            return t("当前 API Key 无权访问该模型（HTTP 403）。请检查模型权限、账户状态或网络限制。", "目前 API Key 無權存取此模型（HTTP 403）。請檢查模型權限、帳戶狀態或網路限制。", "This API key cannot access the model (HTTP 403). Check model permissions, account status, or network restrictions.", "このAPIキーにはモデルへのアクセス権がありません（HTTP 403）。モデル権限、アカウント状態、ネットワーク制限を確認してください。", "현재 API 키에 모델 접근 권한이 없습니다(HTTP 403). 모델 권한, 계정 상태 또는 네트워크 제한을 확인하세요.", "У API-ключа нет доступа к модели (HTTP 403). Проверьте права, состояние аккаунта и сетевые ограничения.")
        case 400:
            return t("请求格式或模型不受支持（HTTP 400）。请检查模型名称是否为聊天/视觉理解模型。", "要求格式或模型不受支援（HTTP 400）。請檢查模型名稱是否為聊天／視覺理解模型。", "The request format or model is unsupported (HTTP 400). Check that the model is a chat or vision-understanding model.", "リクエスト形式またはモデルが対応していません（HTTP 400）。チャットまたは画像理解モデルか確認してください。", "요청 형식 또는 모델이 지원되지 않습니다(HTTP 400). 채팅 또는 비전 이해 모델인지 확인하세요.", "Формат запроса или модель не поддерживаются (HTTP 400). Проверьте, что выбрана модель чата или анализа изображений.")
        case 404:
            return t("找不到接口或模型（HTTP 404）。请检查 Base URL、接口版本和模型名称。", "找不到介面或模型（HTTP 404）。請檢查 Base URL、介面版本與模型名稱。", "The endpoint or model was not found (HTTP 404). Check the Base URL, API version, and model name.", "エンドポイントまたはモデルが見つかりません（HTTP 404）。Base URL、APIバージョン、モデル名を確認してください。", "엔드포인트 또는 모델을 찾을 수 없습니다(HTTP 404). Base URL, API 버전 및 모델 이름을 확인하세요.", "Интерфейс или модель не найдены (HTTP 404). Проверьте Base URL, версию API и имя модели.")
        case 429:
            return t("请求过于频繁或额度不足（HTTP 429）。请稍后重试并检查账户额度。", "要求過於頻繁或額度不足（HTTP 429）。請稍後再試並檢查帳戶額度。", "The rate limit or quota was reached (HTTP 429). Try again later and check the account quota.", "レート制限またはクォータに達しました（HTTP 429）。しばらくしてから再試行し、利用枠を確認してください。", "요청 한도 또는 할당량에 도달했습니다(HTTP 429). 나중에 다시 시도하고 계정 할당량을 확인하세요.", "Превышена частота запросов или квота (HTTP 429). Повторите попытку позже и проверьте лимиты аккаунта.")
        case 500...599:
            return t("AI 服务暂时不可用（HTTP \(code)），请稍后重试。", "AI 服務暫時無法使用（HTTP \(code)），請稍後再試。", "The AI service is temporarily unavailable (HTTP \(code)). Try again later.", "AIサービスは一時的に利用できません（HTTP \(code)）。後でもう一度お試しください。", "AI 서비스를 일시적으로 사용할 수 없습니다(HTTP \(code)). 나중에 다시 시도하세요.", "Сервис ИИ временно недоступен (HTTP \(code)). Повторите попытку позже.")
        default:
            return t("连接失败：HTTP \(code)", "連線失敗：HTTP \(code)", "Connection failed: HTTP \(code)", "接続失敗：HTTP \(code)", "연결 실패: HTTP \(code)", "Ошибка подключения: HTTP \(code)")
        }
    }

    private func validateDraft() -> Bool {
        let normalizedURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: normalizedURL),
              let scheme = components.scheme?.lowercased(),
              (scheme == "https" || scheme == "http"),
              components.host != nil,
              !normalizedModel.isEmpty,
              !normalizedKey.isEmpty else {
            statusIsError = true
            statusMessage = t("请完整填写有效的 Base URL、模型和 API Key", "請完整填寫有效的 Base URL、模型與 API Key", "Enter a valid Base URL, model, and API key", "有効なBase URL、モデル、APIキーをすべて入力してください", "유효한 Base URL, 모델 및 API 키를 모두 입력하세요", "Укажите корректные Base URL, модель и API-ключ")
            return false
        }
        return true
    }

    private func t(_ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String, _ ru: String) -> String {
        loc.text(simplifiedChinese: zh, traditionalChinese: zhHant, english: en, japanese: ja, korean: ko, russian: ru)
    }
}

private struct AIAssistantToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white.opacity(configuration.isPressed ? 0.52 : 0.76))
            .background(Color.white.opacity(configuration.isPressed ? 0.10 : 0.06), in: Circle())
    }
}

private struct AIAssistantInlineActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10.5, weight: .medium))
            .foregroundColor(.white.opacity(configuration.isPressed ? 0.76 : 0.43))
            .padding(.vertical, 3)
            .contentShape(Rectangle())
    }
}
