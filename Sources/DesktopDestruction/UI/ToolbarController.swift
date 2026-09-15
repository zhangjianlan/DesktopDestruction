import AppKit

final class ToolbarController {
    let view = NSView(frame: CGRect(x: 0, y: 0, width: 872, height: 46))

    var onTool: ((Tool) -> Void)?
    var onRestore: (() -> Void)?
    var onSettings: (() -> Void)?
    var onExit: (() -> Void)?

    private let stackView = NSStackView()
    private var hideTimer: Timer?

    init() {
        view.wantsLayer = true
        view.layer?.backgroundColor = CGColor(gray: 0.04, alpha: 0.8)
        view.layer?.cornerRadius = 18
        view.layer?.borderWidth = 1
        view.layer?.borderColor = CGColor(gray: 1, alpha: 0.12)

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 4
        stackView.frame = view.bounds.insetBy(dx: 8, dy: 5)
        stackView.autoresizingMask = [.width, .height]
        view.addSubview(stackView)

        for tool in Tool.allCases {
            let button = makeButton(tool.emoji, title: tool.name) { [weak self] in
                self?.onTool?(tool)
            }
            stackView.addView(button, in: .leading)
        }

        stackView.addView(makeSpacer(), in: .leading)
        stackView.addView(makeButton("🧹", title: "恢复") { [weak self] in self?.onRestore?() }, in: .leading)
        stackView.addView(makeButton("⚙️", title: "设置") { [weak self] in self?.onSettings?() }, in: .leading)
        stackView.addView(makeButton("✕", title: "退出") { [weak self] in self?.onExit?() }, in: .leading)
        showAndScheduleHide()
    }

    func pointerMoved(y: CGFloat, inBounds bounds: CGRect) {
        if y > bounds.height - 72 {
            showAndScheduleHide()
        }
    }

    func showAndScheduleHide() {
        hideTimer?.invalidate()
        view.isHidden = false
        view.alphaValue = 1
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
            self?.view.isHidden = true
        }
    }

    private func makeButton(_ title: String, title label: String, handler: @escaping () -> Void) -> NSButton {
        let button = ActionButton(title: title, target: nil, action: nil)
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 20)
        button.toolTip = label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 42).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.handler = handler
        return button
    }

    private func makeSpacer() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 10).isActive = true
        return view
    }
}

private final class ActionButton: NSButton {
    var handler: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        handler?()
    }
}
