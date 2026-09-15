import Foundation

enum PipelineLog {
    private static let logDirectory = FileManager.default.urls(
        for: .libraryDirectory,
        in: .userDomainMask
    ).first?.appendingPathComponent("Logs/DesktopDestruction", isDirectory: true)

    static func info(_ message: String) {
        let timestamp = ISO8601DateFormatter()
        let line = "[DesktopDestruction] [\(timestamp.string(from: Date()))] \(message)\n"
        FileHandle.standardError.write(Data(line.utf8))
        writeToLogFile(line)
    }

    private static func writeToLogFile(_ line: String) {
        guard let directory = logDirectory else { return }
        let queue = DispatchQueue(label: "com.codex.desktopdestruction.log")
        queue.async {
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let url = directory.appendingPathComponent("app.log")
            if let handle = FileHandle(forWritingAtPath: url.path) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: Data(line.utf8))
            } else {
                try? line.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}
