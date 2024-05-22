
/// A protocol for resolving dependencies by type.
public protocol DependencyResolver {
    func resolve<T>(_ t: T.Type) -> T?
    func resolve<T>() -> T?
}
