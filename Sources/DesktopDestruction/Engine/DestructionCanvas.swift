import QuartzCore

/// Paints persistent damage into a bounded number of bitmap tiles.
final class DestructionCanvas {
    let root = CALayer()
    var remainingDamageCount: Int { damageRecords.count }

    private let damageLayer = CALayer()
    private let transientLayer = CALayer()
    private var tiles: [TileCoordinate: DamageTile] = [:]
    private var damageRecords: [DamageRecord] = []
    private var dirtyTiles: Set<TileCoordinate> = []
    private var commitIsScheduled = false
    private let tileSize: CGFloat = 512
    private let backingScale: CGFloat = 2

    private struct DamageRecord {
        let frame: CGRect
        let isPermanent: Bool
    }

    private struct TileCoordinate: Hashable {
        let x: Int
        let y: Int
    }

    private final class DamageTile {
        let coordinate: TileCoordinate
        let layer = CALayer()
        let context: CGContext

        init(coordinate: TileCoordinate, tileSize: CGFloat, backingScale: CGFloat) {
            self.coordinate = coordinate
            let pixelSize = max(1, Int(tileSize * backingScale))
            context = CGContext(
                data: nil,
                width: pixelSize,
                height: pixelSize,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.scaleBy(x: backingScale, y: backingScale)

            layer.frame = CGRect(
                x: CGFloat(coordinate.x) * tileSize,
                y: CGFloat(coordinate.y) * tileSize,
                width: tileSize,
                height: tileSize
            )
            layer.contentsGravity = .resize
        }

        var frame: CGRect { layer.frame }
    }

    init() {
        root.masksToBounds = false
        damageLayer.masksToBounds = false
        transientLayer.masksToBounds = false
        root.addSublayer(damageLayer)
        root.addSublayer(transientLayer)
    }

    func layout(for bounds: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        root.frame = bounds
        damageLayer.frame = bounds
        transientLayer.frame = bounds
        CATransaction.commit()
        rebuildTiles(for: bounds)
    }

    func addDamage(image: CGImage, frame: CGRect, permanent: Bool = false) {
        damageRecords.append(DamageRecord(frame: frame, isPermanent: permanent))
        forEachTile(intersecting: frame) { tile in
            tile.context.draw(
                image,
                in: CGRect(
                    x: frame.minX - tile.frame.minX,
                    y: frame.minY - tile.frame.minY,
                    width: frame.width,
                    height: frame.height
                )
            )
            dirtyTiles.insert(tile.coordinate)
        }
        scheduleCommit()
    }

    func addTransient(_ layer: CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        transientLayer.addSublayer(layer)
        CATransaction.commit()
    }

    func removeAfter(_ layer: CALayer, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            layer.removeFromSuperlayer()
            _ = self
        }
    }

    func clearTransients() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        transientLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        CATransaction.commit()
    }

    @discardableResult
    func erase(at point: CGPoint, radius: CGFloat) -> Int {
        let eraseRect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let removedCount = damageRecords.filter { $0.frame.intersects(eraseRect) }.count
        damageRecords.removeAll { $0.frame.intersects(eraseRect) }

        forEachTile(intersecting: eraseRect) { tile in
            tile.context.setBlendMode(.clear)
            tile.context.fill(CGRect(
                x: eraseRect.minX - tile.frame.minX,
                y: eraseRect.minY - tile.frame.minY,
                width: eraseRect.width,
                height: eraseRect.height
            ))
            tile.context.setBlendMode(.normal)
            dirtyTiles.insert(tile.coordinate)
        }
        scheduleCommit()
        return removedCount
    }

    @discardableResult
    func clearDamage() -> Int {
        let removedCount = damageRecords.count
        damageRecords.removeAll()

        for tile in tiles.values {
            tile.context.clear(CGRect(origin: .zero, size: tile.frame.size))
            dirtyTiles.insert(tile.coordinate)
        }
        scheduleCommit()
        return removedCount
    }

    private func rebuildTiles(for bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let firstColumn = Int(floor(bounds.minX / tileSize))
        let lastColumn = Int(floor(bounds.maxX / tileSize))
        let firstRow = Int(floor(bounds.minY / tileSize))
        let lastRow = Int(floor(bounds.maxY / tileSize))
        var neededTiles = Set<TileCoordinate>()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for column in firstColumn...lastColumn {
            for row in firstRow...lastRow {
                let coordinate = TileCoordinate(x: column, y: row)
                neededTiles.insert(coordinate)
                if tiles[coordinate] == nil {
                    let tile = DamageTile(
                        coordinate: coordinate,
                        tileSize: tileSize,
                        backingScale: backingScale
                    )
                    damageLayer.addSublayer(tile.layer)
                    tiles[coordinate] = tile
                }
            }
        }

        let staleTiles = tiles.keys.filter { !neededTiles.contains($0) }
        for coordinate in staleTiles {
            tiles[coordinate]?.layer.removeFromSuperlayer()
            tiles[coordinate] = nil
            dirtyTiles.remove(coordinate)
        }
        CATransaction.commit()
    }

    private func forEachTile(
        intersecting frame: CGRect,
        _ body: (DamageTile) -> Void
    ) {
        guard frame.maxX >= frame.minX, frame.maxY >= frame.minY else { return }
        let firstColumn = Int(floor(frame.minX / tileSize))
        let lastColumn = Int(floor(frame.maxX / tileSize))
        let firstRow = Int(floor(frame.minY / tileSize))
        let lastRow = Int(floor(frame.maxY / tileSize))

        for column in firstColumn...lastColumn {
            for row in firstRow...lastRow {
                if let tile = tiles[TileCoordinate(x: column, y: row)] {
                    body(tile)
                }
            }
        }
    }

    private func scheduleCommit() {
        guard !commitIsScheduled, !dirtyTiles.isEmpty else { return }
        commitIsScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.commitDirtyTiles()
        }
    }

    private func commitDirtyTiles() {
        commitIsScheduled = false
        guard !dirtyTiles.isEmpty else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for coordinate in dirtyTiles {
            if let tile = tiles[coordinate] {
                tile.layer.contents = tile.context.makeImage()
            }
        }
        CATransaction.commit()
        dirtyTiles.removeAll()
    }
}
