import XCTest

struct ApplicationDescriptor: Equatable, Sendable {
    let bundleIdentifier: String
    let launchConfiguration: LaunchConfiguration

    init(bundleIdentifier: String, launchConfiguration: LaunchConfiguration = .init()) {
        self.bundleIdentifier = bundleIdentifier
        self.launchConfiguration = launchConfiguration
    }
}

struct LaunchConfiguration: Equatable, Sendable {
    var arguments: [String]
    var environment: [String: String]
    var resetArguments: [String]

    init(
        arguments: [String] = [],
        environment: [String: String] = [:],
        resetArguments: [String] = []
    ) {
        self.arguments = arguments
        self.environment = environment
        self.resetArguments = resetArguments
    }

    func arguments(reset: Bool) -> [String] {
        reset ? arguments + resetArguments : arguments
    }
}

@MainActor
class BaseUITestCase: XCTestCase {
    private(set) var application: XCUIApplication?

    @discardableResult
    func launchApplication(
        _ descriptor: ApplicationDescriptor,
        reset: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: descriptor.bundleIdentifier)
        app.launchArguments = descriptor.launchConfiguration.arguments(reset: reset)
        app.launchEnvironment = descriptor.launchConfiguration.environment
        app.launch()
        application = app
        return app
    }

    @discardableResult
    func relaunchApplication(
        _ descriptor: ApplicationDescriptor,
        reset: Bool = false
    ) -> XCUIApplication {
        application?.terminate()
        return launchApplication(descriptor, reset: reset)
    }

    func captureScreenshot(named name: String) {
        guard let application else {
            XCTFail("Cannot capture a screenshot before launching an application")
            return
        }
        let attachment = XCTAttachment(screenshot: application.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    override func tearDown() {
        application?.terminate()
        application = nil
        super.tearDown()
    }

    override func record(_ issue: XCTIssue) {
        if let application {
            captureScreenshot(named: "Failure - \(name)")

            let hierarchy = XCTAttachment(string: application.debugDescription)
            hierarchy.name = "Accessibility hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        super.record(issue)
    }
}

extension XCUIElement {
    @MainActor
    @discardableResult
    func requireExistence(
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertTrue(
            waitForExistence(timeout: timeout),
            "Element did not appear: \(self)",
            file: file,
            line: line
        )
        return self
    }

    @MainActor
    func tapWhenHittable(
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        requireExistence(timeout: timeout, file: file, line: line)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: self
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Element is not hittable: \(self)",
            file: file,
            line: line
        )
        tap()
    }

    @MainActor
    func replaceText(
        with value: String,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        tapWhenHittable(timeout: timeout, file: file, line: line)
        if let currentValue = self.value as? String, !currentValue.isEmpty {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        }
        typeText(value)
    }
}

protocol ScreenObject {
    var application: XCUIApplication { get }
}

