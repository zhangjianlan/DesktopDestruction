import AppKit
import QuartzCore

final class DestructionController {
    let canvas = DestructionCanvas()
    let toolManager = ToolManager()

    var onExit: (() -> Void)?

    private unowned let view: NSView
    private let toolbar: ToolbarController
    private let emojiInputPanel = EmojiInputPanel()
    private let backgroundLayer = CALayer()
    private let cursorLayer = CALayer()
    private let cursorReticleLayer = CAShapeLayer()
    private let cursorPositionLayer = CATextLayer()
    private let hudLayer = CATextLayer()

    private var currentCursorPoint: CGPoint = .zero
    private var continuousTimer: Timer?
    private var activeStreams: [Tool: CAEmitterLayer] = [:]
    private var pendingTasks: [DispatchWorkItem] = []
    private var lastSawPoint: CGPoint?
    private var sawStepCount = 0
    private var lastEraseTime: Date?
    private var lastEscapeTime: Date?
    private var burningSpots: [BurningSpot] = []
    private var creatures: [CreatureActor] = []
    private var walls: [WallEntity] = []
    private var simulationTimer: Timer?
    private var lastFireIgnition = Date.distantPast
    private var nextCreatureFireCheck = Date.distantPast
    private var vehicleCollisionTick = 0
    private var lastPerformanceLog = Date.distantPast
    private var lastPointerPoint: CGPoint = .zero
    private var emojiOptions: [String] = []

    init(view: NSView, background: CGImage, toolbar: ToolbarController) {
        self.view = view
        self.toolbar = toolbar
        backgroundLayer.contents = background
        backgroundLayer.contentsGravity = .resize
        backgroundLayer.zPosition = -10

        cursorLayer.bounds = CGRect(x: 0, y: 0, width: 52, height: 52)
        cursorLayer.contentsGravity = .resizeAspect
        cursorLayer.contentsScale = 2
        cursorLayer.zPosition = 100

        cursorReticleLayer.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
        cursorReticleLayer.path = cursorReticlePath()
        cursorReticleLayer.strokeColor = CGColor(red: 1, green: 0.86, blue: 0.28, alpha: 0.98)
        cursorReticleLayer.fillColor = NSColor.clear.cgColor
        cursorReticleLayer.lineWidth = 2
        cursorReticleLayer.lineCap = .round
        cursorReticleLayer.shadowColor = CGColor(gray: 0, alpha: 0.75)
        cursorReticleLayer.shadowOpacity = 1
        cursorReticleLayer.shadowRadius = 3
        cursorReticleLayer.shadowOffset = CGSize(width: 0, height: 0)
        cursorReticleLayer.contentsScale = 2
        cursorReticleLayer.zPosition = 102

        cursorPositionLayer.bounds = CGRect(x: 0, y: 0, width: 104, height: 22)
        cursorPositionLayer.contentsScale = 2
        cursorPositionLayer.fontSize = 12
        cursorPositionLayer.alignmentMode = .center
        cursorPositionLayer.cornerRadius = 11
        cursorPositionLayer.masksToBounds = true
        cursorPositionLayer.backgroundColor = CGColor(gray: 0, alpha: 0.72)
        cursorPositionLayer.foregroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)
        cursorPositionLayer.zPosition = 101

        hudLayer.contentsScale = 2
        hudLayer.fontSize = 14
        hudLayer.alignmentMode = .center
        hudLayer.cornerRadius = 16
        hudLayer.masksToBounds = true
        hudLayer.backgroundColor = CGColor(gray: 0, alpha: 0.68)
        hudLayer.zPosition = 90
        setHUD("🔨 锤子 · 左键使用 · 右键轮盘 · 0 放虫 · A 放动物 · P 放人 · V 放车 · W 放围墙 · E 任意 emoji · R 恢复 · 连按 ESC 退出")

        emojiInputPanel.onCommit = { [weak self] options in
            self?.emojiOptions = options
            if options.isEmpty {
                self?.setHUD("✨ 未检测到 emoji · 请粘贴或输入 emoji")
            } else {
                self?.setHUD("🎲 已准备 \(options.count) 个 emoji · 点击桌面放置")
            }
        }

        toolManager.onChange = { [weak self] tool in
            self?.toolDidChange(tool)
        }

        view.wantsLayer = true
        if let viewLayer = view.layer {
            viewLayer.addSublayer(backgroundLayer)
            viewLayer.addSublayer(canvas.root)
            viewLayer.addSublayer(cursorReticleLayer)
            viewLayer.addSublayer(cursorPositionLayer)
            viewLayer.addSublayer(cursorLayer)
            viewLayer.addSublayer(hudLayer)
        }
        view.addSubview(emojiInputPanel)
        layout()
        if let stressEmoji = ProcessInfo.processInfo.environment["DD_STRESS_EMOJI"] {
            emojiInputPanel.emojiField.stringValue = stressEmoji
            emojiOptions = EmojiSpecies.emojiOptions(in: stressEmoji)
            toolManager.select(.anything)
        }
        NSLog("[DesktopDestruction] overlay installed")
    }

    func layout() {
        let bounds = view.bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundLayer.frame = bounds
        canvas.layout(for: bounds)
        hudLayer.frame = CGRect(
            x: bounds.midX - min(380, bounds.width * 0.46),
            y: bounds.minY + 24,
            width: min(760, bounds.width * 0.92),
            height: 34
        )
        emojiInputPanel.layout(in: bounds)
        CATransaction.commit()
    }

    func moveCursor(to point: CGPoint) {
        lastPointerPoint = currentCursorPoint
        currentCursorPoint = point
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cursorReticleLayer.position = point
        cursorLayer.position = clampedCursorBadgePoint(for: point)
        updateCursorPositionLabel(at: point)
        CATransaction.commit()
    }

    func pointerMoved(to point: CGPoint) {
        moveCursor(to: point)
        toolbar.pointerMoved(y: point.y, inBounds: view.bounds)
    }

    func handleMouseDown(at point: CGPoint) {
        pointerMoved(to: point)
        PipelineLog.info("mouse-down received tool=\(toolManager.current.rawValue) point=(\(point.x), \(point.y))")
        switch toolManager.current {
        case .flame:
            igniteCreatures(at: point, radius: 48)
            startFlame(at: point)
        case .water:
            startWater(at: point)
        case .bomb:
            placeBomb(at: point)
        case .nuke:
            launchNuke(to: point)
        case .hammer:
            hammerSmash(at: point)
        case .machineGun:
            startGun()
        case .saw:
            startSaw(at: point)
        case .fist:
            throwFist(at: point)
        case .eraser:
            eraseAt(point)
        case .insect:
            placeInsect(at: point)
        case .person:
            placePerson(at: point)
        case .vehicle:
            placeVehicle(at: point)
        case .animal:
            placeAnimal(at: point)
        case .anything:
            placeAnything(at: point)
        case .wall:
            placeWall(at: point)
        }
    }

    func handleMouseDragged(to point: CGPoint) {
        let previousPoint = currentCursorPoint
        pointerMoved(to: point)
        let direction = dragDirection(from: previousPoint, to: point)
        switch toolManager.current {
        case .saw:
            dragSaw(to: point)
        case .water:
            updateStream(.water, at: point, direction: direction)
        case .flame:
            updateStream(.flame, at: point, direction: direction)
        case .eraser:
            eraseAt(point)
        default:
            break
        }
    }

    func handleMouseUp() {
        stopContinuous()
    }

    func handleEscape() {
        let now = Date()
        if let last = lastEscapeTime, now.timeIntervalSince(last) <= 1.4 {
            NSLog("[DesktopDestruction] exit confirmed")
            onExit?()
            return
        }
        lastEscapeTime = now
        setHUD("⚠️ 再按一次 ESC 退出")
    }

    func restoreAll() {
        cancelPendingTasks()
        stopContinuous()
        clearActiveEffects()
        let removedCount = canvas.clearDamage()
        canvas.clearTransients()
        AudioManager.shared.play("restore_chime", gain: 0.75)
        PipelineLog.info("restore cleared=\(removedCount) remaining=\(canvas.remainingDamageCount)")
        setHUD("✨ 桌面已恢复原样")
    }

    private func toolDidChange(_ tool: Tool) {
        stopContinuous()
        updateCursor(for: tool)
        AudioManager.shared.play("switch_click", gain: 0.7)
        if tool == .anything {
            emojiInputPanel.present(in: view)
        } else {
            emojiInputPanel.isHidden = true
            if view.window?.firstResponder !== view {
                view.window?.makeFirstResponder(view)
            }
        }
        setHUD("\(tool.emoji) \(tool.name) · 左键使用 · 右键轮盘 · R 恢复 · 连按 ESC 退出")
    }

    private func updateCursor(for tool: Tool) {
        cursorLayer.contents = IconRenderer.emoji(tool.cursorEmoji, size: 38)
    }

    private func clampedCursorBadgePoint(for point: CGPoint) -> CGPoint {
        let bounds = view.bounds
        let target = CGPoint(x: point.x + 36, y: point.y - 36)
        return CGPoint(
            x: min(max(target.x, bounds.minX + 30), bounds.maxX - 30),
            y: min(max(target.y, bounds.minY + 30), bounds.maxY - 30)
        )
    }

    private func updateCursorPositionLabel(at point: CGPoint) {
        let bounds = view.bounds
        let target = CGPoint(x: point.x + 76, y: point.y + 38)
        cursorPositionLayer.position = CGPoint(
            x: min(max(target.x, bounds.minX + 56), bounds.maxX - 56),
            y: min(max(target.y, bounds.minY + 15), bounds.maxY - 15)
        )
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        cursorPositionLayer.string = NSAttributedString(
            string: "x \(Int(point.x.rounded())) · y \(Int(point.y.rounded()))",
            attributes: attributes
        )
    }

    private func setHUD(_ text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        hudLayer.string = NSAttributedString(string: text, attributes: attributes)
        hudLayer.setNeedsDisplay()
    }

    private func hammerSmash(at point: CGPoint) {
        damageCreatures(at: point, radius: 78, amount: 2)
        addCrack(at: point, radius: 88, strength: 1.7)
        let secondary = CGPoint(
            x: point.x + CGFloat.random(in: -30...30),
            y: point.y + CGFloat.random(in: -30...30)
        )
        addCrack(at: secondary, radius: 48, strength: 1.0)
        NSLog("[DesktopDestruction] cracks added count=2")
        ParticleFactory.sparks(at: point, count: 34, in: canvas)
        ParticleFactory.glassShards(at: point, count: 28, in: canvas)
        let soundAccepted = AudioManager.shared.play("hammer_hit", gain: 1, rate: 1.25)
        AudioManager.shared.play("glass_shatter", gain: 0.75, rate: 1.05)
        NSLog("[DesktopDestruction] hammer sound accepted=%d", soundAccepted ? 1 : 0)
        let shakeAccepted = ScreenShake.shake(canvas.root, intensity: 13, duration: 0.2)
        NSLog("[DesktopDestruction] shake requested accepted=%d", shakeAccepted ? 1 : 0)
        swingCursor()
    }

    private func startGun() {
        guard continuousTimer == nil else { return }
        fireGun()
        startRepeatingTimer(interval: 0.075) { [weak self] in
            self?.fireGun()
        }
    }

    private func fireGun() {
        let point = CGPoint(
            x: currentCursorPoint.x + CGFloat.random(in: -18...18),
            y: currentCursorPoint.y + CGFloat.random(in: -18...18)
        )
        if let damage = DamageRenderer.renderBulletHole(at: point, radius: 25) {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
        damageCreatures(at: point, radius: 34, amount: 1)
        addTracer(to: point)
        ParticleFactory.muzzleFlash(at: point, in: canvas)
        AudioManager.shared.play(
            "gun_0\(Int.random(in: 1...4))",
            gain: 0.9,
            rate: Float.random(in: 0.92...1.08)
        )
        ScreenShake.shake(canvas.root, intensity: 3.2, duration: 0.07)
    }

    private func addTracer(to point: CGPoint) {
        let start = CGPoint(
            x: point.x - CGFloat.random(in: 48...88),
            y: point.y - CGFloat.random(in: 70...125)
        )
        let layer = CAShapeLayer()
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: point)
        layer.path = path
        layer.strokeColor = CGColor(red: 1, green: 0.91, blue: 0.6, alpha: 0.9)
        layer.fillColor = NSColor.clear.cgColor
        layer.lineWidth = 5
        layer.lineCap = .round
        layer.zPosition = 60
        canvas.addTransient(layer)

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.duration = 0.16
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        layer.add(fade, forKey: "tracerFade")
        canvas.removeAfter(layer, delay: 0.2)
    }

    private func startSaw(at point: CGPoint) {
        lastSawPoint = point
        sawStepCount = 0
        AudioManager.shared.startLoop("saw_loop")
        updateStream(.saw, at: point, direction: CGPoint(x: 1, y: 0))
    }

    private func dragSaw(to point: CGPoint) {
        let previousPoint = lastSawPoint ?? point
        updateStream(.saw, at: point, direction: dragDirection(from: previousPoint, to: point))
        guard let last = lastSawPoint else {
            lastSawPoint = point
            return
        }
        let dx = point.x - last.x
        let dy = point.y - last.y
        guard sqrt(dx * dx + dy * dy) >= 14 else { return }

        damageCreatures(at: point, radius: 48, amount: 1)
        if let damage = DamageRenderer.renderCutSegment(from: last, to: point, width: 10) {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
        sawStepCount += 1
        ParticleFactory.sawdust(at: point, count: 5, in: canvas)
        if sawStepCount % 2 == 0 {
            ParticleFactory.sparks(at: point, count: 9, in: canvas)
        }
        lastSawPoint = point
    }

    private func startWater(at point: CGPoint) {
        updateStream(.water, at: point, direction: CGPoint(x: 0, y: 1))
        AudioManager.shared.startLoop("water_spray")
        startRepeatingTimer(interval: 0.06) { [weak self] in
            guard let self, self.toolManager.current == .water else { return }
            self.addWetSpot(at: self.currentCursorPoint, radius: 38)
            self.extinguishBurningCreatures(at: self.currentCursorPoint, radius: 58)
            self.extinguishFireNear(self.currentCursorPoint, radius: 95)
        }
    }

    private func startFlame(at point: CGPoint) {
        updateStream(.flame, at: point, direction: CGPoint(x: 0, y: 1))
        AudioManager.shared.startLoop("flame_loop")
        startRepeatingTimer(interval: 0.13) { [weak self] in
            guard let self, self.toolManager.current == .flame else { return }
            self.addScorch(at: self.currentCursorPoint, radius: 12)
            self.igniteCreatures(at: self.currentCursorPoint, radius: 48)
            self.igniteFire(at: self.currentCursorPoint, intensity: 1.35)
        }
    }

    private func placeBomb(at point: CGPoint) {
        let bomb = CALayer()
        bomb.contents = ArtAssets.image(named: "tool-bomb")
        bomb.contentsGravity = .resizeAspect
        bomb.contentsScale = 2
        bomb.bounds = CGRect(x: 0, y: 0, width: 48, height: 48)
        bomb.position = point
        bomb.zPosition = 70
        canvas.addTransient(bomb)

        let label = CATextLayer()
        label.contentsScale = 2
        label.fontSize = 22
        label.alignmentMode = .center
        label.frame = CGRect(x: point.x - 28, y: point.y + 26, width: 56, height: 34)
        label.string = "3"
        label.foregroundColor = CGColor(red: 1, green: 0.36, blue: 0.22, alpha: 1)
        canvas.addTransient(label)

        for (delay, text) in [(0.0, "3"), (0.5, "2"), (1.0, "1")] {
            after(delay) { [weak self] in
                guard self != nil else { return }
                label.string = text
                AudioManager.shared.play("bomb_tick", gain: 0.8)
            }
        }

        after(1.5) { [weak self] in
            guard let self else { return }
            bomb.removeFromSuperlayer()
            label.removeFromSuperlayer()
            self.bombBlast(at: point)
        }
    }

    private func launchNuke(to target: CGPoint) {
        let bounds = view.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = target.x - center.x
        let dy = target.y - center.y
        let angle = dx == 0 && dy == 0 ? CGFloat.pi / 2 : atan2(dy, dx)
        let travel = max(bounds.width, bounds.height)
        let start = CGPoint(
            x: target.x + cos(angle) * travel,
            y: target.y + sin(angle) * travel
        )

        let missile = CALayer()
        missile.contents = ArtAssets.image(named: "tool-nuke")
        missile.contentsGravity = .resizeAspect
        missile.contentsScale = 2
        missile.bounds = CGRect(x: 0, y: 0, width: 54, height: 54)
        missile.position = target
        missile.setAffineTransform(CGAffineTransform(rotationAngle: angle - .pi / 2))
        missile.zPosition = 70
        canvas.addTransient(missile)
        ParticleFactory.rocketTrail(attachedTo: missile)

        let flight = CABasicAnimation(keyPath: "position")
        flight.fromValue = NSValue(point: start)
        flight.toValue = NSValue(point: target)
        flight.duration = 0.55
        flight.timingFunction = CAMediaTimingFunction(name: .easeIn)
        missile.add(flight, forKey: "nukeFlight")
        AudioManager.shared.play("rocket_launch", gain: 0.9)

        after(0.55) { [weak self] in
            guard let self else { return }
            missile.removeFromSuperlayer()
            self.nukeBlast(at: target, angle: angle)
        }
        canvas.removeAfter(missile, delay: 0.6)
    }

    private func throwFist(at target: CGPoint) {
        let fist = CALayer()
        fist.contents = ArtAssets.image(named: "tool-fist")
        fist.contentsGravity = .resizeAspect
        fist.contentsScale = 2
        fist.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        fist.position = target
        fist.zPosition = 70
        canvas.addTransient(fist)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.3
        scale.toValue = 1
        scale.duration = 0.18
        fist.add(scale, forKey: "fistScale")

        after(0.18) { [weak self] in
            guard let self else { return }
            self.damageCreatures(at: target, radius: 86, amount: 3)
            self.addCrack(at: target, radius: 98, strength: 2.1)
            self.addCrack(at: target, radius: 48, strength: 1.2)
            ParticleFactory.sparks(at: target, count: 20, in: self.canvas)
            ParticleFactory.dust(at: target, count: 30, in: self.canvas)
            ParticleFactory.debris(at: target, count: 12, in: self.canvas)
            AudioManager.shared.play("punch_hit", gain: 1)
            ScreenShake.shake(self.canvas.root, intensity: 18, duration: 0.28)
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            fade.duration = 0.18
            fade.fillMode = .forwards
            fade.isRemovedOnCompletion = false
            fist.add(fade, forKey: "fistFade")
        }
        canvas.removeAfter(fist, delay: 0.38)
    }

    private func eraseAt(_ point: CGPoint) {
        eraseCreatures(at: point, radius: 64)
        let removed = canvas.erase(at: point, radius: 64)
        let now = Date()
        if removed > 0, lastEraseTime == nil || now.timeIntervalSince(lastEraseTime!) >= 0.12 {
            ParticleFactory.dust(at: point, count: 16, in: canvas)
            AudioManager.shared.play("erase_swish", gain: 0.6)
            lastEraseTime = now
        }
    }

    private func eraseCreatures(at point: CGPoint, radius: CGFloat) {
        let hitCreatures = creatures.filter { $0.hitTest(point, radius: radius) }
        for creature in hitCreatures {
            creature.discard()
        }
        creatures.removeAll { !$0.isAlive }
    }

    private func bombBlast(at point: CGPoint) {
        let radius: CGFloat = 215
        damageCreatures(at: point, radius: radius + 24, amount: 1000)
        damageWalls(at: point, radius: radius, amount: 180)
        addFlash(at: point, radius: radius * 0.9)
        addShockwave(at: point, radius: radius * 0.75)
        addMushroomCloud(at: point, radius: radius)

        for _ in 0..<5 {
            let offset = CGPoint(
                x: point.x + CGFloat.random(in: -radius * 0.2...radius * 0.2),
                y: point.y + CGFloat.random(in: -radius * 0.2...radius * 0.2)
            )
            addCrack(at: offset, radius: radius * CGFloat.random(in: 0.34...0.6), strength: 2.4)
        }
        addScorch(at: point, radius: radius * 0.72)
        ParticleFactory.debris(at: point, count: 48, in: canvas)
        ParticleFactory.sparks(at: point, count: 56, in: canvas)
        ParticleFactory.smoke(at: point, count: 42, in: canvas)
        ParticleFactory.glassShards(at: point, count: 18, in: canvas)
        AudioManager.shared.play("explosion", gain: 1, rate: 0.78)
        AudioManager.shared.play("gun_04", gain: 0.42, rate: 0.48)
        ScreenShake.shake(canvas.root, intensity: 30, duration: 0.58)

        after(0.34) { [weak self] in
            guard let self else { return }
            self.addShockwave(at: point, radius: radius * 1.15)
            self.damageCreatures(at: point, radius: radius * 1.05, amount: 1000)
            self.damageWalls(at: point, radius: radius * 0.9, amount: 100)
            ParticleFactory.smoke(at: point, count: 24, in: self.canvas)
            ParticleFactory.dust(at: point, count: 30, in: self.canvas)
            AudioManager.shared.play("explosion", gain: 0.62, rate: 0.55)
            ScreenShake.shake(self.canvas.root, intensity: 16, duration: 0.34)
        }
    }

    private func nukeBlast(at point: CGPoint, angle: CGFloat) {
        let radius: CGFloat = 620
        damageCreatures(at: point, radius: radius, amount: 5000)
        damageWalls(at: point, radius: radius, amount: 500)
        addFlash(at: point, radius: radius * 0.82)
        addShockwave(at: point, radius: radius * 0.75)
        addDirectionalBlast(at: point, angle: angle, radius: radius * 0.58)

        for index in 0..<8 {
            let distance = radius * 0.07 * CGFloat(index)
            let gougePoint = CGPoint(
                x: point.x + cos(angle) * distance,
                y: point.y + sin(angle) * distance
            )
            if let damage = DamageRenderer.renderGouge(
                at: gougePoint,
                angle: angle,
                radius: radius * (0.42 - CGFloat(index) * 0.025)
            ) {
                canvas.addDamage(image: damage.0, frame: damage.1)
            }
        }

        addScorch(at: point, radius: radius * 0.36)
        addCrack(at: point, radius: radius * 0.28, strength: 3.4)
        addMushroomCloud(at: point, radius: radius)
        ParticleFactory.debris(at: point, count: 72, in: canvas)
        ParticleFactory.sparks(at: point, count: 90, in: canvas)
        ParticleFactory.smoke(at: point, count: 86, in: canvas)
        ParticleFactory.glassShards(at: point, count: 44, in: canvas)

        for index in 0..<12 {
            let blastAngle = CGFloat(index) / 12 * 2 * .pi
            let distance = radius * CGFloat.random(in: 0.08...0.3)
            igniteFire(
                at: CGPoint(
                    x: point.x + cos(blastAngle) * distance,
                    y: point.y + sin(blastAngle) * distance
                ),
                intensity: 1.5,
                force: true
            )
        }

        AudioManager.shared.play("explosion", gain: 1, rate: 0.52)
        AudioManager.shared.play("rocket_launch", gain: 0.7, rate: 0.45)
        AudioManager.shared.play("glass_shatter", gain: 0.65, rate: 0.78)
        ScreenShake.shake(canvas.root, intensity: 46, duration: 1.1)

        after(0.38) { [weak self] in
            guard let self else { return }
            self.addShockwave(at: point, radius: radius * 1.05)
            self.damageCreatures(at: point, radius: radius * 0.92, amount: 2500)
            self.damageWalls(at: point, radius: radius * 0.85, amount: 240)
            ParticleFactory.smoke(at: point, count: 54, in: self.canvas)
            ParticleFactory.dust(at: point, count: 70, in: self.canvas)
            ScreenShake.shake(self.canvas.root, intensity: 29, duration: 0.7)
        }

        after(0.82) { [weak self] in
            guard let self else { return }
            self.addShockwave(at: point, radius: radius * 1.24)
            self.damageCreatures(at: point, radius: radius * 1.08, amount: 1800)
            self.damageWalls(at: point, radius: radius, amount: 180)
            ParticleFactory.smoke(at: point, count: 38, in: self.canvas)
            AudioManager.shared.play("explosion", gain: 0.48, rate: 0.38)
            ScreenShake.shake(self.canvas.root, intensity: 18, duration: 0.5)
        }
    }

    private func addCrack(at point: CGPoint, radius: CGFloat, strength: CGFloat = 1) {
        let geometry = CrackGenerator.cluster(at: point, radius: radius, strength: strength)
        if let damage = DamageRenderer.addDamage(geometry) {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
    }

    private func addWetSpot(at point: CGPoint, radius: CGFloat) {
        if let damage = DamageRenderer.renderWetSpot(at: point, radius: radius) {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
    }

    private func addScorch(at point: CGPoint, radius: CGFloat) {
        if let damage = DamageRenderer.renderScorch(at: point, radius: radius) {
            canvas.addDamage(image: damage.0, frame: damage.1)
        }
    }

    private func placeInsect(at point: CGPoint) {
        let species = InsectSpecies.allCases.randomElement() ?? .ant
        let count = min(species.groupSpawnCount, max(1, 220 - creatures.count))
        for index in 0..<count {
            let offset = count == 1 ? .zero : CGPoint(
                x: CGFloat.random(in: -20...20),
                y: CGFloat.random(in: -20...20)
            )
            let spawnPoint = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
            let actor = CreatureActor(at: spawnPoint, kind: .insect(species))
            canvas.addTransient(actor.layer)
            creatures.append(actor)
            if index == 0 { continue }
            ParticleFactory.dust(at: spawnPoint, count: 2, in: canvas)
        }
        ensureSimulation()
        ParticleFactory.dust(at: point, count: 4, in: canvas)
        AudioManager.shared.play("switch_click", gain: 0.5, rate: 0.82)
    }

    private func placePerson(at point: CGPoint) {
        guard creatures.count < 220 else { return }
        let species = PersonSpecies.randomSpawn()
        let actor = CreatureActor(at: point, kind: .person(species))
        canvas.addTransient(actor.layer)
        creatures.append(actor)
        ensureSimulation()
        ParticleFactory.dust(at: point, count: 6, in: canvas)
        AudioManager.shared.play("switch_click", gain: 0.5, rate: 1.12)
    }

    private func placeVehicle(at point: CGPoint) {
        guard creatures.count < 220 else { return }
        let species = VehicleSpecies.allCases.randomElement() ?? .car
        let actor = CreatureActor(at: point, kind: .vehicle(species))
        canvas.addTransient(actor.layer)
        creatures.append(actor)
        ensureSimulation()
        ParticleFactory.dust(at: point, count: 10, in: canvas)
        AudioManager.shared.play("switch_click", gain: 0.55, rate: 0.72)
    }

    private func placeAnimal(at point: CGPoint) {
        let species = AnimalSpecies.random()
        let count = min(species.groupSpawnCount, max(1, 220 - creatures.count))
        for index in 0..<count {
            let offset = count == 1 ? .zero : CGPoint(
                x: CGFloat.random(in: -28...28),
                y: CGFloat.random(in: -28...28)
            )
            let spawnPoint = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
            let actor = CreatureActor(at: spawnPoint, kind: .animal(species))
            canvas.addTransient(actor.layer)
            creatures.append(actor)
            if index == 0 { continue }
            ParticleFactory.dust(at: spawnPoint, count: 3, in: canvas)
        }
        ensureSimulation()
        ParticleFactory.dust(at: point, count: 8, in: canvas)
        AudioManager.shared.play("switch_click", gain: 0.55, rate: 0.68)
    }

    private func placeAnything(at point: CGPoint) {
        guard creatures.count < 220 else { return }
        let selectedOptions = emojiOptions.isEmpty ? emojiInputPanel.currentEmojiOptions : emojiOptions
        let emoji = selectedOptions.randomElement()
            ?? EmojiSpecies.showcase.randomElement()
            ?? "✨"
        let species = EmojiSpecies(emoji: emoji)
        let count = species.actorClass == .insect ? 2 : 1

        for index in 0..<count {
            let spawnPoint = count == 1 ? point : CGPoint(
                x: point.x + CGFloat.random(in: -22...22),
                y: point.y + CGFloat.random(in: -22...22)
            )
            let actor = CreatureActor(at: spawnPoint, kind: .anything(species))
            canvas.addTransient(actor.layer)
            creatures.append(actor)
            if index > 0 {
                ParticleFactory.dust(at: spawnPoint, count: 3, in: canvas)
            }
        }

        ensureSimulation()
        ParticleFactory.dust(at: point, count: species.actorClass == .vehicle ? 12 : 7, in: canvas)
        AudioManager.shared.play("switch_click", gain: 0.55, rate: 1.25)
    }

    private func placeWall(at point: CGPoint) {
        guard walls.count < 120 else { return }
        let wall = WallEntity(at: point, size: CGSize(width: 210, height: 36))
        canvas.addTransient(wall.layer)
        walls.append(wall)
        ParticleFactory.dust(at: point, count: 10, in: canvas)
        AudioManager.shared.play("hammer_hit", gain: 0.45, rate: 0.75)
        ensureSimulation()
    }

    private func damageWalls(at point: CGPoint, radius: CGFloat, amount: CGFloat) {
        for wall in walls where wall.isAlive && wall.hitTest(position: point, radius: radius) {
            wall.applyDamage(amount, canvas: canvas)
        }
        walls.removeAll { !$0.isAlive }
    }

    private func addCreatureEffect(named name: String, at point: CGPoint, size: CGFloat) {
        let effect = CALayer()
        effect.contents = ArtAssets.image(named: name)
        effect.contentsGravity = .resizeAspect
        effect.contentsScale = 2
        effect.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        effect.position = point
        effect.zPosition = 86
        canvas.addTransient(effect)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.35
        scale.toValue = 1.2
        scale.duration = 0.26
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.duration = 0.3
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        effect.add(scale, forKey: "creatureEffectScale")
        effect.add(fade, forKey: "creatureEffectFade")
        canvas.removeAfter(effect, delay: 0.34)
    }

    private func igniteFire(at point: CGPoint, intensity: CGFloat = 1.25, force: Bool = false) {
        let now = Date()
        guard force || now.timeIntervalSince(lastFireIgnition) >= 0.48 else { return }
        guard burningSpots.count < 80 else { return }
        lastFireIgnition = now
        burningSpots.append(BurningSpot(at: point, canvas: canvas, intensity: intensity))
        ensureSimulation()
    }

    private func extinguishFireNear(_ point: CGPoint, radius: CGFloat) {
        burningSpots.removeAll { spot in
            let dx = point.x - spot.position.x
            let dy = point.y - spot.position.y
            if sqrt(dx * dx + dy * dy) <= radius + spot.radius {
                spot.extinguish()
                return true
            }
            return false
        }
    }

    @discardableResult
    private func igniteCreatures(at point: CGPoint, radius: CGFloat) -> Int {
        var affected = 0
        let hitCreatures = creatures.filter { $0.hitTest(point, radius: radius) }
        for creature in hitCreatures {
            if creature.kind.isVehicle {
                affected += damageVehicle(creature, amount: 0.8, at: point)
            } else {
                creature.ignite()
                affected += 1
            }
        }
        creatures.removeAll { !$0.isAlive }
        return affected
    }

    private func extinguishBurningCreatures(at point: CGPoint, radius: CGFloat) {
        let burningCreatures = creatures.filter {
            $0.isBurning && $0.hitTest(point, radius: radius)
        }
        for creature in burningCreatures {
            creature.extinguish()
            ParticleFactory.steam(at: creature.currentPosition, count: 10, in: canvas)
        }
    }

    private func igniteCreaturesFromBurningSpots() {
        for spot in burningSpots {
            for creature in creatures where creature.isAlive && !creature.kind.isVehicle {
                if creature.hitTest(spot.position, radius: spot.radius * 0.7) {
                    creature.ignite()
                }
            }
        }
    }

    @discardableResult
    private func damageCreatures(at point: CGPoint, radius: CGFloat, amount: CGFloat = 1000) -> Int {
        var affected = 0
        let hitCreatures = creatures.filter { $0.hitTest(point, radius: radius) }
        for creature in hitCreatures {
            if creature.kind.isVehicle {
                affected += damageVehicle(creature, amount: amount, at: point)
            } else {
                if creature.applyDamage(amount, from: point) {
                    creature.kill(canvas: canvas)
                    affected += 1
                } else {
                    affected += 1
                    ParticleFactory.dust(at: creature.currentPosition, count: 4, in: canvas)
                }
            }
        }
        creatures.removeAll { !$0.isAlive }
        return affected
    }

    @discardableResult
    private func damageVehicle(
        _ vehicle: CreatureActor,
        amount: CGFloat,
        at point: CGPoint
    ) -> Int {
        guard vehicle.applyDamage(amount, from: point) else {
            let position = vehicle.currentPosition
            ParticleFactory.sparks(at: position, count: 10, in: canvas)
            ParticleFactory.smoke(at: position, count: 6, in: canvas)
            AudioManager.shared.play(
                "hammer_hit",
                gain: 0.26,
                rate: 0.72,
                minimumInterval: 0.06
            )
            return 0
        }
        return explodeVehicle(vehicle)
    }

    @discardableResult
    private func explodeVehicle(_ vehicle: CreatureActor) -> Int {
        guard vehicle.isAlive else { return 0 }
        let point = vehicle.currentPosition
        let radius = max(82, vehicle.traits.explosionRadius)
        vehicle.destroy()

        var affected = 1
        let nearbyCreatures = creatures.filter { $0.isAlive && $0.hitTest(point, radius: radius) }
        for creature in nearbyCreatures {
            if creature.kind.isVehicle {
                affected += explodeVehicle(creature)
            } else {
                if creature.applyDamage(1000, from: point) {
                    creature.kill(canvas: canvas)
                }
                affected += 1
            }
        }
        creatures.removeAll { !$0.isAlive }
        addVehicleExplosion(at: point, radius: radius)
        return affected
    }

    private func addVehicleExplosion(at point: CGPoint, radius: CGFloat) {
        let blast = CALayer()
        blast.contents = ArtAssets.image(named: "effect-explosion")
        blast.contentsGravity = .resizeAspect
        blast.contentsScale = 2
        blast.bounds = CGRect(x: 0, y: 0, width: radius, height: radius)
        blast.position = point
        blast.zPosition = 88
        canvas.addTransient(blast)

        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [0.2, 1.35, 1]
        scale.keyTimes = [0, 0.24, 1]
        scale.duration = 0.42
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.duration = 0.42
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        blast.add(scale, forKey: "vehicleBlastScale")
        blast.add(fade, forKey: "vehicleBlastFade")
        canvas.removeAfter(blast, delay: 0.46)

        let fire = CALayer()
        fire.contents = ArtAssets.image(named: "effect-fire")
        fire.contentsGravity = .resizeAspect
        fire.contentsScale = 2
        fire.bounds = CGRect(x: 0, y: 0, width: radius * 0.52, height: radius * 0.52)
        fire.position = point
        fire.zPosition = 87
        canvas.addTransient(fire)
        let fireFade = CABasicAnimation(keyPath: "opacity")
        fireFade.fromValue = 1
        fireFade.toValue = 0
        fireFade.duration = 0.72
        fireFade.fillMode = .forwards
        fireFade.isRemovedOnCompletion = false
        fire.add(fireFade, forKey: "vehicleFireFade")
        canvas.removeAfter(fire, delay: 0.76)

        addFlash(at: point, radius: radius * 0.7)
        addShockwave(at: point, radius: radius * 0.78)
        addScorch(at: point, radius: radius * 0.55)
        addCrack(at: point, radius: radius * 0.38, strength: 1.5)
        ParticleFactory.debris(at: point, count: 34, in: canvas)
        ParticleFactory.sparks(at: point, count: 40, in: canvas)
        ParticleFactory.smoke(at: point, count: 28, in: canvas)
        ParticleFactory.glassShards(at: point, count: 20, in: canvas)
        igniteFire(at: point, intensity: 1.4, force: true)
        AudioManager.shared.play(
            "explosion",
            gain: 0.94,
            rate: Float.random(in: 1.04...1.24)
        )
        AudioManager.shared.play("glass_shatter", gain: 0.42, rate: 1.18)
        ScreenShake.shake(canvas.root, intensity: 21, duration: 0.35)
    }

    private func resolveVehicleCollisions() {
        var hadCollision = false
        var vehicleCollisionPairs: [(vehicle: CreatureActor, other: CreatureActor)] = []

        for (index, vehicle) in creatures.enumerated() {
            guard vehicle.isAlive && vehicle.kind.isVehicle else { continue }
            for otherIndex in creatures.indices where otherIndex > index {
                let other = creatures[otherIndex]
                guard other.isAlive else { continue }
                guard vehicle.hitTest(other.currentPosition, radius: vehicle.traits.hitRadius) else {
                    continue
                }

                if other.kind.isVehicle {
                    vehicleCollisionPairs.append((vehicle, other))
                    hadCollision = true
                } else {
                    let died = other.kill(canvas: canvas)
                    hadCollision = true
                    if died {
                        let contact = CGPoint(
                            x: (vehicle.currentPosition.x + other.currentPosition.x) / 2,
                            y: (vehicle.currentPosition.y + other.currentPosition.y) / 2
                        )
                        if let damage = DamageRenderer.renderGouge(
                            at: contact,
                            angle: CGFloat.random(in: 0...(2 * .pi)),
                            radius: 24
                        ) {
                            canvas.addDamage(image: damage.0, frame: damage.1)
                        }
                        ParticleFactory.dust(at: contact, count: 8, in: canvas)
                        AudioManager.shared.play("punch_hit", gain: 0.48, rate: 1.4)
                    }
                }
            }
        }

        for collision in vehicleCollisionPairs where collision.vehicle.isAlive {
            explodeVehicle(collision.vehicle)
        }

        if !vehicleCollisionPairs.isEmpty {
            PipelineLog.info("vehicle collision explosion pairs=\(vehicleCollisionPairs.count)")
        }

        if hadCollision {
            creatures.removeAll { !$0.isAlive }
        }
    }

    private func ensureSimulation() {
        guard simulationTimer == nil else { return }
        simulationTimer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.simulationTick()
        }
        if let simulationTimer {
            RunLoop.main.add(simulationTimer, forMode: .common)
        }
    }

    private func simulationTick() {
        let tickStartedAt = CFAbsoluteTimeGetCurrent()
        let now = Date()
        let bounds = view.bounds
        let lowDetail = burningSpots.count > 24 || creatures.count > 120
        let maxBurningSpots = lowDetail ? 40 : 72
        var survivingSpots: [BurningSpot] = []
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for spot in burningSpots {
            let update = spot.update(now: now, bounds: bounds, lowDetail: lowDetail)
            if update.isAlive {
                guard survivingSpots.count < maxBurningSpots else {
                    spot.extinguish()
                    continue
                }
                survivingSpots.append(spot)
                if let spreadPoint = update.spreadPoint, survivingSpots.count < maxBurningSpots {
                    survivingSpots.append(
                        BurningSpot(
                            at: spreadPoint,
                            canvas: canvas,
                            duration: 6,
                            intensity: spot.spreadIntensity
                        )
                    )
                }
            }
        }
        CATransaction.commit()
        burningSpots = survivingSpots

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        creatures = creatures.filter {
            $0.update(
                now: now,
                canvas: canvas,
                bounds: bounds,
                threat: currentCursorPoint,
                others: creatures,
                walls: walls
            )
        }
        CATransaction.commit()

        let persistentDamageChance: CGFloat = creatures.count < 90 ? 1 : (creatures.count < 150 ? 0.55 : 0.28)
        resolveCreatureInteractions(now: now)
        resolveGiantZombieDestruction()
        mergeZombies()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for creature in creatures where creature.isAlive {
            creature.biteDesktopIfReady(
                now: now,
                canvas: canvas,
                chance: persistentDamageChance
            )
        }
        CATransaction.commit()

        if now >= nextCreatureFireCheck {
            nextCreatureFireCheck = now.addingTimeInterval(0.1)
            igniteCreaturesFromBurningSpots()
        }
        vehicleCollisionTick += 1
        if vehicleCollisionTick % 2 == 0 {
            resolveVehicleCollisions()
        }

        if now.timeIntervalSince(lastPerformanceLog) >= 1 {
            lastPerformanceLog = now
            PipelineLog.info(
                "perf creatures=\(creatures.count) damage=\(canvas.remainingDamageCount) fire=\(burningSpots.count) tick_ms=\((CFAbsoluteTimeGetCurrent() - tickStartedAt) * 1000)"
            )
        }

        if burningSpots.isEmpty && creatures.isEmpty {
            simulationTimer?.invalidate()
            simulationTimer = nil
        }
    }

    private func resolveCreatureInteractions(now: Date) {
        for creature in creatures where creature.isAlive {
            guard let target = creature.creatureBiteTargetIfReady(now: now, others: creatures) else {
                continue
            }

            if creature.isZombie {
                target.infect()
                addCreatureEffect(
                    named: "effect-zombie-bite",
                    at: target.currentPosition,
                    size: max(48, creature.traits.biteRadius * 4)
                )
                ParticleFactory.dust(at: target.currentPosition, count: 5, in: canvas)
                AudioManager.shared.play("switch_click", gain: 0.22, rate: 0.55)
            } else if creature.kind.isAnimal {
                if target.kill(canvas: canvas) {
                    creature.evolve()
                    addCreatureEffect(
                        named: "effect-evolution",
                        at: creature.currentPosition,
                        size: max(62, creature.traits.bodySize * 1.1)
                    )
                    ParticleFactory.dust(at: creature.currentPosition, count: 9, in: canvas)
                    if let damage = DamageRenderer.renderChewMarks(
                        at: target.currentPosition,
                        radius: creature.traits.biteRadius,
                        shape: creature.traits.biteShape
                    ) {
                        canvas.addDamage(image: damage.0, frame: damage.1)
                    }
                }
            }
        }
        creatures.removeAll { !$0.isAlive }
    }

    private func mergeZombies() {
        guard creatures.contains(where: \.isZombie) else { return }
        let maximumTier = creatures.compactMap { $0.isZombie ? $0.zombieTier : nil }.max() ?? 0

        for tier in 1...max(1, maximumTier) {
            var sameTierZombies = creatures.filter { $0.isZombie && $0.zombieTier == tier }
            while sameTierZombies.count >= 2 {
                let merging = Array(sameTierZombies.prefix(2))
                let survivor = merging[0]
                for zombie in merging.dropFirst() {
                    zombie.discard()
                }
                survivor.promoteZombieTier()

                if let damage = DamageRenderer.renderScorch(
                    at: survivor.currentPosition,
                    radius: survivor.traits.bodySize * 0.7
                ) {
                    canvas.addDamage(image: damage.0, frame: damage.1)
                }
                ParticleFactory.dust(at: survivor.currentPosition, count: 22, in: canvas)
                ParticleFactory.sparks(at: survivor.currentPosition, count: 14, in: canvas)
                AudioManager.shared.play("punch_hit", gain: 0.45, rate: 0.55)
                sameTierZombies.removeAll { !($0.isAlive) }
            }
        }

        creatures.removeAll { !$0.isAlive }
    }

    private func resolveGiantZombieDestruction() {
        let giants = creatures.filter { $0.isZombie && $0.zombieTier >= 2 }
        guard !giants.isEmpty else { return }

        for giant in giants where giant.isAlive {
            for vehicle in creatures
            where vehicle.isAlive && vehicle.kind.isVehicle && vehicle.id != giant.id {
                if vehicle.hitTest(giant.currentPosition, radius: giant.traits.hitRadius) {
                    explodeVehicle(vehicle)
                }
            }

            for victim in creatures
            where victim.isAlive
                && !victim.kind.isVehicle
                && !victim.isZombie
                && victim.id != giant.id
                && victim.hitTest(giant.currentPosition, radius: giant.traits.hitRadius) {
                if victim.applyDamage(giant.destructionPower, from: giant.currentPosition) {
                    victim.kill(canvas: canvas)
                }
            }

            for wall in walls where wall.isAlive {
                if wall.hitTest(position: giant.currentPosition, radius: giant.traits.hitRadius) {
                    wall.applyDamage(giant.destructionPower, canvas: canvas)
                }
            }
        }

        walls.removeAll { !$0.isAlive }
        creatures.removeAll { !$0.isAlive }
    }

    private func clearActiveEffects() {
        burningSpots.forEach { $0.extinguish() }
        creatures.forEach { $0.discard() }
        walls.forEach { $0.discard() }
        burningSpots.removeAll()
        creatures.removeAll()
        walls.removeAll()
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    private func addMushroomCloud(at point: CGPoint, radius: CGFloat) {
        let cloudSize = radius * 1.6
        let cloud = CALayer()
        cloud.contents = ArtAssets.image(named: "effect-mushroom-cloud")
        cloud.contentsGravity = .resizeAspect
        cloud.contentsScale = 2
        cloud.bounds = CGRect(x: 0, y: 0, width: cloudSize, height: cloudSize)
        cloud.position = point
        cloud.zPosition = 84
        canvas.addTransient(cloud)

        animateMushroomPart(
            cloud,
            from: CGPoint(x: point.x, y: point.y - radius * 0.08),
            to: CGPoint(x: point.x, y: point.y + radius * 0.62),
            fromScale: 0.14,
            toScale: 1.18,
            duration: 1.35
        )
        canvas.removeAfter(cloud, delay: 1.55)
    }

    private func animateMushroomPart(
        _ layer: CALayer,
        from: CGPoint,
        to: CGPoint,
        fromScale: CGFloat,
        toScale: CGFloat,
        duration: TimeInterval
    ) {
        layer.position = from
        let rise = CABasicAnimation(keyPath: "position")
        rise.fromValue = NSValue(point: from)
        rise.toValue = NSValue(point: to)
        rise.duration = duration

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = fromScale
        scale.toValue = toScale
        scale.duration = duration
        scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 0.96, 0.72, 0]
        fade.keyTimes = [0, 0.16, 0.64, 1]
        fade.duration = duration
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false

        layer.add(rise, forKey: "mushroomRise")
        layer.add(scale, forKey: "mushroomScale")
        layer.add(fade, forKey: "mushroomFade")
    }

    private func addDirectionalBlast(at point: CGPoint, angle: CGFloat, radius: CGFloat) {
        let blast = CALayer()
        blast.contents = ArtAssets.image(named: "effect-explosion")
        blast.contentsGravity = .resize
        blast.contentsScale = 2
        blast.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 1.1)
        blast.position = point
        blast.zPosition = 82
        blast.setAffineTransform(
            CGAffineTransform(rotationAngle: angle).scaledBy(x: 1.55, y: 0.55)
        )
        canvas.addTransient(blast)

        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [0.15, 1.1, 1]
        scale.keyTimes = [0, 0.3, 1]
        scale.duration = 0.4
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.duration = 0.4
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        blast.add(scale, forKey: "directionalBlastScale")
        blast.add(fade, forKey: "directionalBlastFade")
        canvas.removeAfter(blast, delay: 0.45)
    }

    private func addFlash(at point: CGPoint, radius: CGFloat) {
        let flash = CALayer()
        flash.contents = ArtAssets.image(named: "effect-muzzle-flash")
        flash.contentsGravity = .resizeAspect
        flash.contentsScale = 2
        flash.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        flash.position = point
        flash.zPosition = 80
        canvas.addTransient(flash)
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0, 1, 0]
        animation.keyTimes = [0, 0.22, 1]
        animation.duration = 0.35
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        flash.add(animation, forKey: "explosionFlash")
        canvas.removeAfter(flash, delay: 0.38)
    }

    private func addShockwave(at point: CGPoint, radius: CGFloat) {
        let wave = CALayer()
        wave.contents = ArtAssets.image(named: "effect-shockwave")
        wave.contentsGravity = .resizeAspect
        wave.contentsScale = 2
        wave.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        wave.position = point
        wave.zPosition = 75
        canvas.addTransient(wave)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.15
        scale.toValue = 1.25
        scale.duration = 0.38
        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.9
        opacity.toValue = 0
        opacity.duration = 0.38
        opacity.fillMode = .forwards
        opacity.isRemovedOnCompletion = false
        wave.add(scale, forKey: "waveScale")
        wave.add(opacity, forKey: "waveOpacity")
        canvas.removeAfter(wave, delay: 0.42)
    }

    private func updateStream(_ tool: Tool, at point: CGPoint, direction: CGPoint) {
        if let stream = activeStreams[tool] {
            stream.emitterPosition = point
            stream.emitterCells?.forEach { $0.emissionLongitude = atan2(direction.y, direction.x) }
            return
        }

        let stream: CAEmitterLayer
        switch tool {
        case .water:
            stream = ParticleFactory.waterStream(at: point, direction: direction, in: canvas)
        case .flame:
            stream = ParticleFactory.flameStream(at: point, direction: direction, in: canvas)
        case .saw:
            stream = ParticleFactory.sawSparks(at: point, direction: direction, in: canvas)
        default:
            return
        }
        activeStreams[tool] = stream
    }

    private func stopContinuous() {
        continuousTimer?.invalidate()
        continuousTimer = nil
        lastSawPoint = nil
        AudioManager.shared.stopLoop("saw_loop")
        AudioManager.shared.stopLoop("water_spray")
        AudioManager.shared.stopLoop("flame_loop")
        for stream in activeStreams.values {
            stream.emitterCells?.forEach { $0.birthRate = 0 }
            canvas.removeAfter(stream, delay: 0.25)
        }
        activeStreams.removeAll()
    }

    private func startRepeatingTimer(interval: TimeInterval, action: @escaping () -> Void) {
        continuousTimer?.invalidate()
        let timer = Timer(timeInterval: interval, repeats: true, block: { _ in action() })
        RunLoop.main.add(timer, forMode: .common)
        continuousTimer = timer
    }

    private func after(_ delay: TimeInterval, _ action: @escaping () -> Void) {
        let task = DispatchWorkItem(block: action)
        pendingTasks.append(task)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }

    private func cancelPendingTasks() {
        pendingTasks.forEach { $0.cancel() }
        pendingTasks.removeAll()
    }

    private func dragDirection(to point: CGPoint) -> CGPoint {
        let direction = CGPoint(x: point.x - currentCursorPoint.x, y: point.y - currentCursorPoint.y)
        return direction == .zero ? CGPoint(x: 0, y: 1) : direction
    }

    private func dragDirection(from previousPoint: CGPoint, to point: CGPoint) -> CGPoint {
        let direction = CGPoint(x: point.x - previousPoint.x, y: point.y - previousPoint.y)
        return direction == .zero ? CGPoint(x: 0, y: 1) : direction
    }

    private func cursorReticlePath() -> CGPath {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: 6, y: 6, width: 22, height: 22))
        path.move(to: CGPoint(x: 0, y: 17))
        path.addLine(to: CGPoint(x: 5, y: 17))
        path.move(to: CGPoint(x: 29, y: 17))
        path.addLine(to: CGPoint(x: 34, y: 17))
        path.move(to: CGPoint(x: 17, y: 0))
        path.addLine(to: CGPoint(x: 17, y: 5))
        path.move(to: CGPoint(x: 17, y: 29))
        path.addLine(to: CGPoint(x: 17, y: 34))
        return path
    }

    private func swingCursor() {
        NSLog("[DesktopDestruction] hammer animation scheduled")
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [0, -0.24, 0.12, 0]
        animation.keyTimes = [0, 0.3, 0.75, 1]
        animation.duration = 0.14
        cursorLayer.add(animation, forKey: "cursorSwing")
    }
}
