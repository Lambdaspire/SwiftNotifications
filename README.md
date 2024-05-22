# Lambdaspire - Swift Notifications

Strongly-typed User Notifications for iOS, iPadOS, and macOS. Action Identifier Strings (`actionIdentifier`) and User Info Dictionaries (`userInfo`) are replaced with `Codable` structs to provide a .

Built for internal use @Lambdaspire, so might not be fit for your purposes, but do as you wish with this package and/or the code.

Feel free to submit a Pull Request.

## Usage

### 1. Create the Notification Service.

`NotificationService` is the main driver. It requires a `DependencyResolver` and a `Logger` (there are default implementations of both available).

```swift
let serviceLocator: BasicServiceLocator = .init()
let notificationService: NotificationService = .init(resolver: serviceLocator, logger: PrintLogger())
```

### 2. Register Notification Handlers and Associated Types.

Users respond to notifications via actions (see the [Actionable Notifications Documentation from Apple](https://developer.apple.com/documentation/usernotifications/declaring-your-actionable-notification-types)). Even tapping on a notification with no custom actions constitutes an action (specifically, `UNNotificationDefaultActionIdentifier`). We need to register handlers for the actions the user can take in our application. Notifications may also carry custom data, so we need to define the types associated with that data.

Below are some contrived examples.

```swift
struct EmployeePerformanceReviewRequestData {
    var employeeName: String
}

struct DefaultHandler : NotificationActionHandler {
    static func handle(
        _ actionIdentifierData: DefaultNotificationActionIdentifier,
        _ requestData: EmployeePerformanceReviewRequestData,
        _ userInput: UserInput,
        _ resolver: DependencyResolver) async {

            // The default action brings the app into the foreground,
            // so show the performance review UI for the relevant employee.
            await resolver
                .resolve(AppState.self)!
                .reviewEmployeePerformance(requestData.employeeName)
        }
}

struct PerformanceRatingHandler : NotificationActionHandler {
    static func handle(
        _ actionIdentifierData: DefaultNotificationActionIdentifier,
        _ requestData: EmployeePerformanceReviewRequestData,
        _ userInput: UserInput,
        _ resolver: DependencyResolver) async {

            // The user has supplied a rating directly from the notification,
            // so update the database accordingly.
            await resolver
                .resolve(EmployeeDatabase.self)!
                .saveReview(employeeName: requestData.employeeName, rating: requestData.rating)
        }
}

struct WrittenNoteHandler : NotificationActionHandler {
    static func handle(
        _ actionIdentifierData: DefaultNotificationActionIdentifier,
        _ requestData: EmployeePerformanceReviewRequestData,
        _ userInput: UserInput,
        _ resolver: DependencyResolver) async {

            guard let userInput else { return }

            // The user has written a note rather than supplying a rating,
            // so notify HR post-haste.
            await resolver
                .resolve(HumanResources.self)!
                .notify("Regarding \(requestData.employeeName): \(userInput)")
        }
}
```

## 3. Start listening for Notification Responses.

The `NotificationService` has a couple of convenience functions on it which hide some `UserNotifications` framework implementation details.

Where you would normally do something like:

```swift
UNUserNotificationCenter.current().delegate = /* SOME DELEGATE IMPLEMENTATION */
```

You will instead do this:

```swift
notificationService.becomeMainNotificationResponder()
```

---

## Appendix

### Registering Dependencies

The `DependencyResolver` will be passed to your handlers, so you'll want to register whatever dependencies will be required for them to function (ideally, as early as possible in the app lifecycle).

Example 1: You might want to register some singletons for database access and external services. You could do this wherever you declare your resolver and service.

```swift
// Example 1:

serviceLocator.register(HumanResources())
serviceLocator.register(EmployeeDatabase())
```

Example 2: If you want to resolve the `NotificationService` itself as a dependency, you could register it in the same `DependencyResolver` that it references after initialising it. You might do this if you want a notification handler to schedule another notification.

```swift
Example 2:

let notificationService: NotificationService = .init(resolver: serviceLocator, logger: PrintLogger())

serviceLocator.register(notificationService)
```

Example 3: You might want to register some root `AppState` environment object so that the handlers can manipulate state to update the UI when the app is brought ot the foreground by a notification action.

```swift
// Example 3:

@main
struct StronglyTypedNotificationsExampleApp: App {
    
    @StateObject private var appState: AppState = .init()
    
    private let serviceLocator: BasicServiceLocator = .default
    
    var body: some Scene {
        WindowGroup {
            ContentView().with(appState, serviceLocator)
        }
    }
}

class AppState : ObservableObject {
    // You do you.
}

extension View {
    
    func with(_ appState: AppState, _ serviceLocator: BasicServiceLocator) -> some View {
    
        serviceLocator.register(appState)
        
        return self
            .environmentObject(appState)
            .environmentObject(serviceLocator)
    }
}

// So we can pass it along with @EnvironmentObject
extension BasicServiceLocator : ObservableObject { }
```
