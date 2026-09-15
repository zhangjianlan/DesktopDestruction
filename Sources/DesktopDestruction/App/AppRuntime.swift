import AppKit

enum AppRuntime {
    private static var isQuitting = false

    static func quit() {
        guard !isQuitting else { return }
        isQuitting = true
        PipelineLog.info("app quit requested")
        AudioManager.shared.stopAllLoops()

        Thread.detachNewThread {
            PipelineLog.info("app quit watchdog armed")
            Thread.sleep(forTimeInterval: 0.3)
            PipelineLog.info("app quit watchdog fired")
            _exit(0)
        }
        DispatchQueue.main.async {
            PipelineLog.info("appkit stop requested")
            NSApp.stop(nil)
            NSApp.terminate(nil)
        }
    }
}
