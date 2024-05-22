
/// A basic, not-fit-for-production logger to serve as a default implementation of Logger.
public class PrintLogger : Logger {
    
    public init() { }
    
    public func info(_ message: String) {
        log("ℹ️ Info", message)
    }
    
    public func debug(_ message: String) {
        log("🐞 Debug", message)
    }
    
    public func warning(_ message: String) {
        log("⚠️ Warning", message)
    }
    
    public func error(_ message: String) {
        log("❌ Error", message)
    }
    
    public func error(_ message: String, _ error: Error) {
        log("❌ Error", "\(message)\n\nError Description: \(error.localizedDescription)")
    }
    
    private func log(_ level: String, _ message: String) {
        print("\(level) : \(message)")
    }
}
