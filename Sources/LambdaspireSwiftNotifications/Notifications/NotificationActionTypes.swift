
public extension NotificationAction {
    
    /// Convenience builder for button actions.
    static func button(
        identifier: NotificationActionIdentifier,
        title: String,
        icon: String,
        requiresForeground: Bool) -> NotificationAction {
            .init(
                identifier: identifier,
                type: .button(.init(requiresForeground: requiresForeground)),
                title: title,
                icon: icon)
        }
    
    /// Convenience builder for user input actions.
    static func userInput(
        identifier: NotificationActionIdentifier,
        title: String,
        icon: String,
        buttonTitle: String,
        placeholder: String) -> NotificationAction {
            .init(
                identifier: identifier,
                type: .userInput(.init(buttonTitle: buttonTitle, placeholder: placeholder)),
                title: title,
                icon: icon)
        }
}
