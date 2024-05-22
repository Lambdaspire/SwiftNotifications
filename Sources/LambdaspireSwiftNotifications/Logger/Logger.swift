
public protocol Logger {
    func info(_ message: String)
    func debug(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
    func error(_ message: String, _ error: Error)
}
