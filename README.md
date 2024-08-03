# Lambdaspire - Swift Notifications

Strongly-typed User Notifications for iOS, iPadOS, and macOS. Action Identifier Strings (`actionIdentifier`) and User Info Dictionaries (`userInfo`) are replaced with `Codable` structs to provide a slightly less painful experience when handling notification responses. Fewer switch statements. Less magic string parsing. More refactor-friendly.

Built for internal use @Lambdaspire, so might not be fit for your purposes, but do as you wish with this package and/or the code.

Feel free to submit a Pull Request.

## Usage

[There is a minimalist example project.](https://github.com/Lambdaspire/SwiftNotifications-Example)

Otherwise, (hopefully exhaustive) steps are outlined below.

### 1. Create the Notification Service.

`NotificationService` is the main driver. It requires a `DependencyResolutionScope`.

```swift
let builder: ContainerBuilder = .init()
builder.singleton { scope in NotificationService(scope: scope) }
let container = builder.build()

let notificationService: NotificationService = container.resolve()
```

We're using `Container` from [Lambdaspire-Swift-DependencyResolution](https://github.com/Lambdaspire/Lambdaspire-Swift-DependencyResolution).

### 2. Register Notification Handlers and Associated Types.

Users respond to notifications via actions (see the [Actionable Notifications Documentation from Apple](https://developer.apple.com/documentation/usernotifications/declaring-your-actionable-notification-types)). Even tapping on a notification with no custom actions constitutes an action (specifically, `UNNotificationDefaultActionIdentifier`). We need to register handlers for the actions the user can take in our application. Notifications may also carry custom data, so we need to define the types associated with that data.

Below are some contrived examples.

```swift
struct EmployeePerformanceReviewRequestData : NotificationRequestData {
    var employeeName: String
}

@Resolvable
class DefaultHandler : NotificationActionHandler {

    private let appState: AppState

    func handle(
        _ actionIdentifierData: DefaultNotificationActionIdentifier,
        _ requestData: EmployeePerformanceReviewRequestData,
        _ userInput: UserInput) async {

            // The default action brings the app into the foreground,
            // so show the performance review UI for the relevant employee.
            await appState.reviewEmployeePerformance(requestData.employeeName)
        }
}

struct PerformanceRatingActionIdentifier : NotificationActionIdentifier {
    var rating: String
}

@Resolvable
class PerformanceRatingHandler : NotificationActionHandler {

    private let employeeDatabase: EmployeeDatabase

    func handle(
        _ actionIdentifierData: PerformanceRatingActionIdentifier,
        _ requestData: EmployeePerformanceReviewRequestData,
        _ userInput: UserInput) async {

            // The user has supplied a rating directly from the notification,
            // so update the database accordingly.
            await employeeDatabase.saveReview(employeeName: requestData.employeeName, rating: actionIdentifierData.rating)
        }
}

struct WrittenNoteActionIdentifier : NotificationActionIdentifier {
    // Empty - use UserInput instead.
}

@Resolvable
class WrittenNoteHandler : NotificationActionHandler {

    private let humanResources: HumanResources

    func handle(
        _ actionIdentifierData: WrittenNoteActionIdentifier,
        _ requestData: EmployeePerformanceReviewRequestData,
        _ userInput: UserInput) async {

            guard let userInput else { return }

            // The user has written a note rather than supplying a rating,
            // so notify HR post-haste.
            await humanResources.notify("Regarding \(requestData.employeeName): \(userInput)")
        }
}
```

## 3. Start listening for Notification Responses.

You'll need to register your handlers with the `NotificationService` instance. Ideally you'd do this in the same place where you declare the service.

```swift
notificationService.register(handler: DefaultHandler.self)
notificationService.register(handler: PerformanceRatingHandler.self)
notificationService.register(handler: WrittenNoteHandler.self)
```

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

Another convenience function will request permission from the user for your app to send notifications. It is a very naive implementation of `requestAuthorization(options: UNAuthorizationOptions = [])` on `UNUserNotificationCenter`. Put this wherever makes sense in your app lifecycle, but - obviously - before you schedule notifications.

```swift
await notificationService.requestPermission()
```

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
                    title: "Bad",
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

Shouldn't be a surprise that you'll need to include the **Push Notifications** entitlement for your app target.

### Registering Dependencies

Handlers are resolved via the `Resolvable` protocol. Use the `@Resolvable` macro from the [DependencyResolution package](https://github.com/Lambdaspire/Lambdaspire-Swift-DependencyResolution) to simplify this. See that package's readme for more details.
