import Foundation

final class ToolManager {
    private(set) var current: Tool = .hammer {
        didSet {
            guard oldValue != current else { return }
            onChange?(current)
        }
    }

    var onChange: ((Tool) -> Void)?

    func select(_ tool: Tool) {
        current = tool
    }

    func select(number: Int) {
        guard let tool = Tool(rawValue: number) else { return }
        current = tool
    }

    func cycle(_ direction: Int) {
        let count = Tool.allCases.count
        let next = (current.rawValue - 1 + direction + count * 2) % count
        current = Tool(rawValue: next + 1) ?? .hammer
    }
}
