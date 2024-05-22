# Lambdaspire - Swift Notifications

Strongly-typed User Notifications for iOS, iPadOS, and macOS. Action Identifier Strings (`actionIdentifier`) and User Info Dictionaries (`userInfo`) are replaced with `Codable` structs to provide a slightly less painful experience when handling notification responses. Fewer switch statements. Less magic string parsing. More refactor-friendly.

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
struct EmployeePerformanceReviewRequestData : NotificationRequestData {
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

struct PerformanceRatingActionIdentifier : NotificationActionIdentifier {
    var rating: String
}

struct PerformanceRatingHandler : NotificationActionHandler {
    static func handle(
        _ actionIdentifierData: PerformanceRatingActionIdentifier,
        _ requestData: EmployeePerformanceReviewRequestData,
        _ userInput: UserInput,
        _ resolver: DependencyResolver) async {

            // The user has supplied a rating directly from the notification,
            // so update the database accordingly.
            await resolver
                .resolve(EmployeeDatabase.self)!
                .saveReview(employeeName: requestData.employeeName, rating: actionIdentifierData.rating)
        }
}

struct WrittenNoteActionIdentifier : NotificationActionIdentifier {
    // Empty - use UserInput instead.
}

struct WrittenNoteHandler : NotificationActionHandler {
    static func handle(
        _ actionIdentifierData: WrittenNoteActionIdentifier,
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
// ❌
UNUserNotificationCenter.current().delegate = /* SOME DELEGATE IMPLEMENTATION */
```

You will instead do this:

```swift
// ✅
notificationService.becomeMainNotificationResponder()
```

You should do this as soon as possible in the app lifecycle. Ideally, you'd do it in the same location you declare your `NotificationService`.

As long as the `notificationService` remains alive, it will receive notification responses via the `userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async` function on the `UNUserNotificationCenterDelegate` protocol and usher those responses through to your handlers.

## 4. Schedule some Notifications

The examples so far are for some kind of Employee Performance Review app. Riveting. Let's pretend we want to schedule a notification for a manager to review their subordinates each afternoon. Obviously this isn't an ideal UX but it'll do for an example.

```swift
let employees = employeeDatabase.getMySubordinates()

await employees.forEach { employee in

    await notificationService
        .requestNotification(.init(
            identifier: .init(),
            date: thisAfternoon,
            categoryIdentifier: "EmployeePerformanceReview",
            title: "\(employee.name)",
            subtitle: "Performance Review",
            body: "Supply a rating or write a note.",
            data: EmployeePerformanceReviewRequestData(employeeName: employee.name),
            actions: [
                .button(
                    identifier: PerformanceRatingActionIdentifier(rating: "Good"),
                    title: "Good",
                    icon: "hand.thumbsup.fill",
                    requiresForeground: false),
                .button(
                    identifier: PerformanceRatingActionIdentifier(rating: "Bad"),
                    title: "Bad",,
                    icon: "hand.thumbsdown.fill",
                    requiresForeground: false),
                .userInput(
                    identifier: WrittenNoteActionIdentifier(),
                    title: "Write a note",
                    icon: "pencil.line",
                    buttonTitle: "Done",
                    placeholder: "Write a note for HR")
            ]))

}
```

## Done.

That's all.

---

## Appendix

### Push Notifications App Entitlement

Shouldn't be s surprise that you'll need to include the **Push Notifications** entitlement for your app target.

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
// Example 2:

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
