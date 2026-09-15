import AppKit

final class EmojiInputPanel: NSView {
    var onCommit: (([String]) -> Void)?

    let emojiField: NSTextField

    private let titleLabel = NSTextField(labelWithString: "任意 emoji")
    private let stackView = NSStackView()

    init() {
        emojiField = NSTextField()
        emojiField.stringValue = EmojiSpecies.showcase.randomElement() ?? "✨"
        emojiField.placeholderString = "🚀🍎👻"
        emojiField.font = NSFont.systemFont(ofSize: 21)
        emojiField.alignment = .center
        emojiField.usesSingleLineMode = true

        super.init(frame: CGRect(x: 0, y: 0, width: 428, height: 74))

        wantsLayer = true
        layer?.backgroundColor = CGColor(gray: 0.05, alpha: 0.86)
        layer?.cornerRadius = 14
        layer?.borderWidth = 1
        layer?.borderColor = CGColor(gray: 1, alpha: 0.14)
        isHidden = true

        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.86)

        emojiField.target = self
        emojiField.action = #selector(commit)

        let randomButton = NSButton(
            title: "随机",
            target: self,
            action: #selector(randomize)
        )
        randomButton.controlSize = .small
        randomButton.bezelStyle = .rounded
        randomButton.font = NSFont.systemFont(ofSize: 13, weight: .medium)

        let applyButton = NSButton(
            title: "确认",
            target: self,
            action: #selector(commit)
        )
        applyButton.controlSize = .small
        applyButton.bezelStyle = .rounded
        applyButton.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        applyButton.keyEquivalent = "\r"

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addView(titleLabel, in: .leading)
        stackView.addView(emojiField, in: .leading)
        stackView.addView(randomButton, in: .leading)
        stackView.addView(applyButton, in: .leading)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            emojiField.widthAnchor.constraint(equalToConstant: 168),
            randomButton.widthAnchor.constraint(equalToConstant: 56),
            applyButton.widthAnchor.constraint(equalToConstant: 62)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var currentEmojiOptions: [String] {
        EmojiSpecies.emojiOptions(in: emojiField.stringValue)
    }

    func layout(in bounds: CGRect) {
        frame = CGRect(
            x: bounds.midX - 214,
            y: bounds.height - 126,
            width: 428,
            height: 74
        )
    }

    func present(in parent: NSView) {
        if superview !== parent {
            parent.addSubview(self)
        }
        isHidden = false
        window?.makeFirstResponder(emojiField)
    }

    @objc private func commit() {
        onCommit?(currentEmojiOptions)
    }

    @objc private func randomize() {
        emojiField.stringValue = EmojiSpecies.showcase.randomElement() ?? "✨"
        commit()
    }
}
