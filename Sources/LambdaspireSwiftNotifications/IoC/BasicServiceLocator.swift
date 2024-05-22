
/// A very, very, very basic Service Locator to serve as a default implementation of DependencyResolver.
public class BasicServiceLocator : DependencyResolver {
    
    fileprivate var services: [String : () -> Any] = [:]
    
    public init() { }
    
    public func register<T>(_ t: @escaping () -> T) {
        services[.init(describing: T.self)] = t
    }
    
    public func register<T>(_ t: T) {
        register({ t })
    }
    
    public func resolve<T>(_ t: T.Type) -> T? {
        (services[.init(describing: T.self)] ?? { nil })() as? T
    }
    
    public func resolve<T>() -> T? {
        resolve(T.self)
    }
}
