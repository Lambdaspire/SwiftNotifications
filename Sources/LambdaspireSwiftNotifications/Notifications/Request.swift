
import Foundation

/// Represents data that may be accessed when handling a notification response.
public struct NotificationRequest<T: NotificationRequestData> {
    public var identifier: UUID = .init()
    public var date: Date
    public var categoryIdentifier: String
    public var title: String
    public var subtitle: String
    public var body: String
    public var data: T
    public var actions: [NotificationAction]
    
    public init(identifier: UUID, date: Date, categoryIdentifier: String, title: String, subtitle: String, body: String, data: T, actions: [NotificationAction]) {
        self.identifier = identifier
        self.date = date
        self.categoryIdentifier = categoryIdentifier
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.data = data
        self.actions = actions
    }
}

// Represents a notification action (an option presented to the user as a notification response).
public struct NotificationAction {
    public var identifier: NotificationActionIdentifier
    public var type: NotificationActionType
    public var title: String
    public var icon: String
    
    public init(identifier: NotificationActionIdentifier, type: NotificationActionType, title: String, icon: String) {
        self.identifier = identifier
        self.type = type
        self.title = title
        self.icon = icon
    }
}

/// Represents an action type that determines the presentation of an action on a notification.
public enum NotificationActionType {
    case button(NotificationActionTypeButtonDefinition)
    case userInput(NotificationActionTypeUserInputDefinition)
}

public struct NotificationActionTypeButtonDefinition {
    /// Whether the app should be brought into the foreground upon selecting this action.
    public var requiresForeground: Bool
    
    public init(requiresForeground: Bool) {
        self.requiresForeground = requiresForeground
    }
}

public struct NotificationActionTypeUserInputDefinition {
    /// The text that appears on the confirmation button next to the user input textbox.
    public var buttonTitle: String
    /// The placeholder test that appears in the user input textbox.
    public var placeholder: String
    
    public init(buttonTitle: String, placeholder: String) {
        self.buttonTitle = buttonTitle
        self.placeholder = placeholder
    }
}
