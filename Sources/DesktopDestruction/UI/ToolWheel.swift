import AppKit
import QuartzCore

final class ToolWheel {
    private weak var host: CALayer?
    private let container = CALayer()
    private let centerLabel = CATextLayer()
    private var itemLayers: [CALayer] = []
    private var selectedIndex: Int?

    init() {
        container.bounds = CGRect(x: 0, y: 0, width: 360, height: 360)
        container.cornerRadius = 180
        container.backgroundColor = CGColor(gray: 0, alpha: 0.24)
        container.borderColor = CGColor(gray: 1, alpha: 0.16)
        container.borderWidth = 1
        container.isHidden = true
        container.zPosition = 200

        centerLabel.contentsScale = 2
        centerLabel.fontSize = 17
        centerLabel.alignmentMode = .center
        centerLabel.frame = CGRect(x: 125, y: 163, width: 110, height: 34)
        centerLabel.string = "选择工具"
        centerLabel.foregroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.9)
        container.addSublayer(centerLabel)
    }

    func attach(to layer: CALayer?) {
        host = layer
        if let layer {
            container.frame = layer.bounds
            layer.addSublayer(container)
        }
    }

    func begin(at point: CGPoint) {
        guard host != nil else { return }
        container.sublayers?.forEach { layer in
            if layer != centerLabel {
                layer.removeFromSuperlayer()
            }
        }
        itemLayers.removeAll()
        selectedIndex = nil
        centerLabel.string = "选择工具"
        container.position = point
        container.isHidden = false

        let radius: CGFloat = 146
        let step = (2 * .pi) / CGFloat(Tool.allCases.count)
        for (index, tool) in Tool.allCases.enumerated() {
            let angle = .pi / 2 - CGFloat(index) * step
            let item = CALayer()
            item.bounds = CGRect(x: 0, y: 0, width: 58, height: 58)
            item.cornerRadius = 29
            item.backgroundColor = CGColor(gray: 0, alpha: 0.72)
            item.borderColor = CGColor(gray: 1, alpha: 0.12)
            item.borderWidth = 1
            item.contents = ArtAssets.image(named: tool.assetName)
                ?? IconRenderer.emoji(tool.emoji, size: 34)
            item.contentsScale = 2
            item.position = CGPoint(
                x: 180 + cos(angle) * radius,
                y: 180 + sin(angle) * radius
            )
            container.addSublayer(item)
            itemLayers.append(item)
        }
    }

    func update(at point: CGPoint) {
        guard !container.isHidden, !itemLayers.isEmpty else { return }
        let dx = point.x - container.position.x
        let dy = point.y - container.position.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 38, distance < 192 else { return }

        let step = (2 * .pi) / CGFloat(itemLayers.count)
        let angle = atan2(dy, dx)
        var index = Int(((.pi / 2 - angle) / step).rounded())
        index = (index + itemLayers.count) % itemLayers.count
        setSelected(index)
    }

    func commit() -> Tool? {
        let tool = selectedIndex.flatMap { Tool.allCases[$0] }
        dismiss()
        return tool
    }

    func dismiss() {
        container.isHidden = true
    }

    private func setSelected(_ index: Int) {
        guard selectedIndex != index else { return }
        selectedIndex = index
        for (position, layer) in itemLayers.enumerated() {
            layer.borderColor = position == index
                ? CGColor(red: 1, green: 0.78, blue: 0.25, alpha: 0.9)
                : CGColor(gray: 1, alpha: 0.12)
            layer.borderWidth = position == index ? 2 : 1
        }
        centerLabel.string = Tool.allCases[index].name
    }
}
