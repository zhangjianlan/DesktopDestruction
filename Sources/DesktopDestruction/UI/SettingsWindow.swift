import AppKit

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.level = .screenSaver + 2
        window.isReleasedWhenClosed = false
        super.init(window: window)

        let settings = AppSettings.shared
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let soundButton = NSButton(
            checkboxWithTitle: "开启音效",
            target: self,
            action: #selector(soundChanged(_:))
        )
        soundButton.state = settings.soundEnabled ? .on : .off

        let volumeSlider = NSSlider(value: Double(settings.volume) * 100, minValue: 0, maxValue: 100, target: self, action: #selector(volumeChanged(_:)))
        volumeSlider.frame = NSRect(x: 0, y: 0, width: 300, height: 24)
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.widthAnchor.constraint(equalToConstant: 300).isActive = true

        let shakeButton = NSButton(
            checkboxWithTitle: "屏幕震动",
            target: self,
            action: #selector(shakeChanged(_:))
        )
        shakeButton.state = settings.shakeEnabled ? .on : .off

        let particlePopup = NSPopUpButton()
        for level in ParticleLevel.allCases {
            particlePopup.addItem(withTitle: "粒子密度：\(level.label)")
        }
        particlePopup.selectItem(at: settings.particleLevel.rawValue)
        particlePopup.target = self
        particlePopup.action = #selector(particleChanged(_:))

        let hint = NSTextField(labelWithString: "所有破坏效果只覆盖在桌面截图上，不会修改真实文件。")
        hint.textColor = .secondaryLabelColor
        hint.lineBreakMode = .byWordWrapping
        hint.maximumNumberOfLines = 3
        hint.preferredMaxLayoutWidth = 350

        stack.addArrangedSubview(soundButton)
        stack.addArrangedSubview(volumeSlider)
        stack.addArrangedSubview(shakeButton)
        stack.addArrangedSubview(particlePopup)
        stack.addArrangedSubview(hint)

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 380)
        ])
        window.contentView = content
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func soundChanged(_ sender: NSButton) {
        AppSettings.shared.soundEnabled = sender.state == .on
        if !AppSettings.shared.soundEnabled {
            AudioManager.shared.stopAllLoops()
        }
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        AppSettings.shared.volume = Float(sender.doubleValue / 100)
        AudioManager.shared.applyVolumeChange()
    }

    @objc private func shakeChanged(_ sender: NSButton) {
        AppSettings.shared.shakeEnabled = sender.state == .on
    }

    @objc private func particleChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        if let level = ParticleLevel(rawValue: index) {
            AppSettings.shared.particleLevel = level
        }
    }
}
