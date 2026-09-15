import AppKit

final class PermissionGateController: NSObject {
    static let shared = PermissionGateController()

    private var window: NSWindow?
    private var pollTimer: Timer?
    private var statusLabel = NSTextField(wrappingLabelWithString: "")
    private var capture: (() async -> DesktopCapture.CaptureAttempt)?
    private var onReady: ((CGImage) -> Void)?
    private var onUseSyntheticBackground: (() -> Void)?
    private var onQuit: (() -> Void)?
    private var isAttemptingCapture = false
    private var lastDiagnostic = "尚未完成真实截图检测"
    private var elapsedSeconds = 0

    func run(
        capture: @escaping () async -> DesktopCapture.CaptureAttempt,
        onReady: @escaping (CGImage) -> Void,
        onUseSyntheticBackground: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        guard self.capture == nil else { return }
        self.capture = capture
        self.onReady = onReady
        self.onUseSyntheticBackground = onUseSyntheticBackground
        self.onQuit = onQuit

        let hasPermission = DesktopCapture.hasPermission
        PipelineLog.info(
            "screen-capture preflight granted=\(hasPermission) bundle=\(Bundle.main.bundleIdentifier ?? "nil") path=\(Bundle.main.bundleURL.path)"
        )

        // CGPreflightScreenCaptureAccess can remain false after a TCC change. A real
        // ScreenCaptureKit capture is therefore the authoritative permission test.
        DesktopCapture.requestPermission()
        startCaptureAttempt()
    }

    func dismiss() {
        stopPolling()
        closeWindow()
        capture = nil
        onReady = nil
        onUseSyntheticBackground = nil
        onQuit = nil
    }

    private func startCaptureAttempt() {
        guard !isAttemptingCapture, let capture else { return }
        isAttemptingCapture = true
        lastDiagnostic = "正在执行真实截图检测..."
        updateStatus()

        Task { @MainActor [weak self] in
            let result = await capture()
            guard let self else { return }
            self.isAttemptingCapture = false

            if let image = result.image {
                PipelineLog.info("screen-capture gate passed by real capture")
                let ready = self.onReady
                self.dismiss()
                ready?(image)
                return
            }

            self.lastDiagnostic = result.diagnostic
            PipelineLog.info("screen-capture gate diagnostic: \(result.diagnostic)")
            if self.window == nil {
                self.showGate()
                self.startPolling()
            } else {
                self.updateStatus()
            }
        }
    }

    private func showGate() {
        statusLabel = NSTextField(wrappingLabelWithString: "")
        statusLabel.alignment = .center
        statusLabel.font = NSFont.systemFont(ofSize: 14)
        statusLabel.preferredMaxLayoutWidth = 520
        statusLabel.textColor = .black

        let gate = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        gate.title = "屏幕录制权限检测"
        gate.level = .screenSaver + 2
        gate.isReleasedWhenClosed = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        let openButton = ActionButton(title: "打开系统设置") { [weak self] in
            self?.openPrivacySettings()
        }
        let retryButton = ActionButton(title: "立即重试") { [weak self] in
            self?.startCaptureAttempt()
        }
        let restartButton = ActionButton(title: "重启应用") { [weak self] in
            self?.relaunchAfterPermissionChange()
        }
        let syntheticButton = ActionButton(title: "先用测试背景") { [weak self] in
            let fallback = self?.onUseSyntheticBackground
            self?.dismiss()
            fallback?()
        }
        let quitButton = ActionButton(title: "退出") { [weak self] in
            self?.onQuit?()
        }

        for button in [openButton, retryButton, restartButton, syntheticButton, quitButton] {
            button.bezelStyle = .rounded
        }

        let buttons = NSStackView(
            views: [openButton, retryButton, restartButton, syntheticButton, quitButton]
        )
        buttons.orientation = .horizontal
        buttons.spacing = 8

        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(buttons)

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
        ])
        gate.contentView = content
        window = gate
        gate.center()
        gate.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        updateStatus()
    }

    private func startPolling() {
        guard pollTimer == nil else { return }
        elapsedSeconds = 0
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1

            let shouldRetry = !self.isAttemptingCapture && (
                DesktopCapture.hasPermission || self.elapsedSeconds % 3 == 0
            )
            if shouldRetry {
                self.startCaptureAttempt()
            } else {
                self.updateStatus()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func updateStatus() {
        let launchedFromAppBundle = Bundle.main.bundleURL.pathExtension == "app"
        let launchMode = launchedFromAppBundle
            ? ".app 启动（推荐）"
            : "可执行文件直启（权限可能记到终端或启动器上）"
        let actionHint = launchedFromAppBundle
            ? "如果你刚刚在系统设置里打开权限，请点击“重启应用”。窗口也会每 3 秒自动做一次真实截图检测。"
            : "请改用 .app 启动；如果必须直启，请给负责启动它的终端授予屏幕录制权限。"

        statusLabel.stringValue = """
        \(lastDiagnostic)

        系统预检：\(DesktopCapture.hasPermission ? "已通过" : "未通过")
        启动方式：\(launchMode)

        \(actionHint)
        """
    }

    private func openPrivacySettings() {
        let urls = [
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"),
            URL(fileURLWithPath: "/System/Library/PreferencePanes/PrivacyScreenCapture.prefPane"),
        ].compactMap { $0 }

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }

    private func relaunchAfterPermissionChange() {
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension == "app" else {
            updateStatus()
            return
        }

        PipelineLog.info("screen-capture permission relaunch requested")
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true
        Task { @MainActor [weak self] in
            do {
                try await NSWorkspace.shared.openApplication(
                    at: bundleURL,
                    configuration: configuration
                )
                AppRuntime.quit()
            } catch {
                PipelineLog.info("screen-capture relaunch failed: \(String(describing: error))")
                self?.lastDiagnostic = "重启失败：\(error.localizedDescription)"
                self?.updateStatus()
            }
        }
    }

    private func closeWindow() {
        window?.close()
        window = nil
    }
}

private final class ActionButton: NSButton {
    private let clickHandler: () -> Void

    init(title: String, handler: @escaping () -> Void) {
        self.clickHandler = handler
        super.init(frame: .zero)
        self.title = title
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        clickHandler()
    }
}
