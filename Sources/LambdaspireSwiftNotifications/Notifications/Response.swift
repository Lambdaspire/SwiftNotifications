
import UserNotifications

/// Defines the contract for custom NotificationActionIdentifier types.
public protocol NotificationActionIdentifier : Codable { }

/// Defines the contract for custom NotificationRequestData types.
public protocol NotificationRequestData : Codable { }

/// Represents optional text input from a notification.
public typealias UserInput = String?

/// Defines the contract for custom NotificationActionHandler 
public protocol NotificationActionHandler {
    associatedtype NotificationActionIdentifierType : NotificationActionIdentifier
    associatedtype NotificationRequestDataType : NotificationRequestData
    
    /// Invoked when a notification with an action identifier of the matching type is processed.
    /// - Parameter actionIdentifier: The strongly typed action identifier and associated data.
    /// - Parameter requestData: The strongly typed userInfo data associated with the notification.
    /// - Parameter userInput: Optional text input from the notification response.
    /// - Parameter resolver: A dependency resolver that allows the handler to access application-specific context.
    static func handle(
        _ actionIdentifier: NotificationActionIdentifierType,
        _ requestData: NotificationRequestDataType,
        _ userInput: UserInput,
        _ resolver: DependencyResolver) async -> Void
}

// Type-safe identifiers for system defaults.

/// Represents a strongly typed action identifier for the Default action (when the user taps the notification indiscriminately).
public struct DefaultNotificationActionIdentifier : NotificationActionIdentifier { }

/// Represents a strongly typed action identifier for the Dismiss action (when the user dismisses the notification).
public struct DismissNotificationActionIdentifier : NotificationActionIdentifier { }
