import CoreGraphics
import Foundation

struct CreatureSpatialGrid {
    struct Entry {
        let index: Int
        let creature: CreatureActor
    }

    private struct Cell: Hashable {
        let x: Int
        let y: Int
    }

    let maxHitRadius: CGFloat
    private let cellSize: CGFloat
    private var cells: [Cell: [Entry]]

    init(creatures: [CreatureActor], cellSize: CGFloat = 256) {
        self.cellSize = max(64, cellSize)
        var builtCells: [Cell: [Entry]] = [:]
        var maximumHitRadius: CGFloat = 0

        for (index, creature) in creatures.enumerated() where creature.isAlive {
            maximumHitRadius = max(maximumHitRadius, creature.traits.hitRadius)
            let cell = Cell(
                x: Int(floor(creature.currentPosition.x / self.cellSize)),
                y: Int(floor(creature.currentPosition.y / self.cellSize))
            )
            builtCells[cell, default: []].append(Entry(index: index, creature: creature))
        }

        cells = builtCells
        maxHitRadius = maximumHitRadius
    }

    func nearbyEntries(point: CGPoint, radius: CGFloat) -> [Entry] {
        let cellReach = max(0, radius) + maxHitRadius
        let firstColumn = Int(floor((point.x - cellReach) / cellSize))
        let lastColumn = Int(floor((point.x + cellReach) / cellSize))
        let firstRow = Int(floor((point.y - cellReach) / cellSize))
        let lastRow = Int(floor((point.y + cellReach) / cellSize))
        var entries: [Entry] = []

        for column in firstColumn...lastColumn {
            for row in firstRow...lastRow {
                for entry in cells[Cell(x: column, y: row), default: []] {
                    let dx = entry.creature.currentPosition.x - point.x
                    let dy = entry.creature.currentPosition.y - point.y
                    let reach = max(0, radius) + entry.creature.traits.hitRadius
                    if dx * dx + dy * dy <= reach * reach {
                        entries.append(entry)
                    }
                }
            }
        }

        return entries
    }

    func nearbyActors(point: CGPoint, radius: CGFloat) -> [CreatureActor] {
        nearbyEntries(point: point, radius: radius).map(\.creature)
    }
}
