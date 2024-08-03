
import LambdaspireAbstractions
import UserNotifications

/// Provides an avenue for type-safe notification response handling and some other, less notable conveniences.
public class NotificationService : NSObject, UNUserNotificationCenterDelegate {

    private var handlers: [String : Handler] = [:]
    
    private let scope: DependencyResolutionScope
    
    public init(scope: DependencyResolutionScope) {
        self.scope = scope
    }
    
    public func becomeMainNotificationResponder() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    @MainActor
    public func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])
    }
    
    public func register<H: NotificationActionHandler>(handler: H.Type) {
        handlers[H.name] = { [weak self] actionIdentifierJson, userInfoDataJson, userInput async in
            
            guard let self else { return }
            
            guard let actionIdentifier: H.NotificationActionIdentifierType = actionIdentifierJson.decoded() else {
                Log.warning("Unable to parse JSON from ActionIdentifier as \(H.NotificationActionIdentifierType.self). Aborting.")
                return
            }
            
            guard let requestData: H.NotificationRequestDataType = userInfoDataJson.decoded() else {
                Log.warning("Unable to parse JSON from User Info Data JSON String as \(H.NotificationRequestDataType.self). Aborting.")
                return
            }
            
            Log.info("Handling Notification Action \(H.NotificationActionIdentifierType.self) with Handler \(H.self).")
            
            let handler = scope.tryResolve(H.self) ?? H.init(scope: scope)
            await handler.handle(actionIdentifier, requestData, userInput)
        }
    }
    
    public func requestNotification<T : Codable>(_ request: NotificationRequest<T>) async {
        
        Log.debug("Requesting Notification \(request.identifier) (\(T.self)).")
        
        let actions: [UNNotificationAction] = request
            .actions
            .compactMap { a in
                
                guard let identifier = NotificationActionIdentifierContainer(a.identifier).encoded() else {
                    Log.warning("Failed to encode Action Identifier for request \(request.identifier). Action will be excluded.")
                    return nil
                }
                
                switch a.type {
                    
                case .button(let def):
                    return UNNotificationAction(
                        identifier: identifier,
                        title: a.title,
                        options: def.requiresForeground ? .foreground : .authenticationRequired,
                        icon: .init(systemImageName: a.icon))
                    
                case .userInput(let def):
                    return UNTextInputNotificationAction(
                        identifier: identifier,
                        title: a.title,
                        options: .authenticationRequired,
                        icon: .init(systemImageName: a.icon),
                        textInputButtonTitle: def.buttonTitle,
                        textInputPlaceholder: def.placeholder)
                }
            }
        
        let category: UNNotificationCategory = .init(
            identifier: request.categoryIdentifier,
            actions: actions,
            intentIdentifiers: [])
        
        // Ensure category is always up to date...
        
        let categories = await UNUserNotificationCenter.current().notificationCategories()
        
        let newCategories = categories
            .filter { $0.identifier != category.identifier }
            .union([category])
        
        Log.debug("Setting Notification Categories (\(newCategories.map { $0.identifier }.joined(separator: ", "))).")
        
        UNUserNotificationCenter.current().setNotificationCategories(newCategories)
        
        guard let userInfoDataJson = request.data.encoded() else {
            Log.warning("Failed to encode request data.")
            return
        }
        
        let content: UNMutableNotificationContent = .init()
        content.title = request.title
        content.subtitle = request.subtitle
        content.body = request.body
        content.userInfo = ["data" : userInfoDataJson]
        content.categoryIdentifier = category.identifier
        
        let trigger: UNCalendarNotificationTrigger = .init(
            dateMatching: Calendar
                .current
                .dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: request.date),
            repeats: false)
        
        let request: UNNotificationRequest = .init(
            identifier: request.identifier.uuidString,
            content: content,
            trigger: trigger)
        
        try! await UNUserNotificationCenter.current().add(request)
        
        Log.debug("Successfully requested Notification \(request.identifier) (\(T.self)).")
    }
    
    @MainActor
    private func handle(_ : UNUserNotificationCenter, _ response: UNNotificationResponse) async {
        
        Log.debug("Handling Notification Response \(response.actionIdentifier).")
        
        // Determine the action identifier as one of:
        // - System (dismiss / default).
        // - A custom one conforming to NotificationActionIdentifier and the related protocols.
        // - One created outside of the confines of this walled garden and therefore impossible to handle.
        let actionIdentifierContainer: NotificationActionIdentifierContainer? = {
            switch response.actionIdentifier {
            
            // System - Default
            case UNNotificationDefaultActionIdentifier:
                return .init(DefaultNotificationActionIdentifier())
                
            // System - Dismiss
            case UNNotificationDismissActionIdentifier:
                return .init(DismissNotificationActionIdentifier())
            
            // Custom (or nil if it can't be decoded)
            default:
                return response.actionIdentifier.decoded()
            }
        }()
        
        guard let actionIdentifierContainer else {
            Log.warning("Unable to derive NotificationActionIdentifier from \(response.actionIdentifier). Aborting.")
            return
        }
        
        guard let handler = handlers[actionIdentifierContainer.type] else {
            Log.warning("Unable to find action handler for type \(actionIdentifierContainer.type). Aborting.")
            return
        }
        
        await handler(
            actionIdentifierContainer.json,
            response.notification.request.content.userInfo["data"] as? String ?? Empty().encoded()!,
            (response as? UNTextInputNotificationResponse)?.userText)
        
        Log.debug("Successfully handled Notification Response \(response.actionIdentifier).")
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await handle(center, response)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.badge, .banner, .list]
    }
}

fileprivate struct Empty : Codable { }

fileprivate typealias ActionIdentifierAsJson = String
fileprivate typealias UserInfoDataAsJson = String
fileprivate typealias Handler = (ActionIdentifierAsJson, UserInfoDataAsJson, UserInput) async -> Void

fileprivate struct NotificationActionIdentifierContainer : Codable {
    let type: String
    let json: String
    
    init<T: NotificationActionIdentifier>(_ t: T) {
        self.type = .init(describing: T.self)
        self.json = t.encoded()!
    }
}

extension NotificationActionHandler {
    static var name: String { "\(NotificationActionIdentifierType.self)" }
}
