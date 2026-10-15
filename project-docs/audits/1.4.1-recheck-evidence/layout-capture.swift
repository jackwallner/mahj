import SwiftUI
import UIKit
import XCTest
@testable import MahjTrainer

/// Temporary audit capture of the actual post-purchase reminder view.
@MainActor
final class AuditEvidenceTests: XCTestCase {
    func testCaptureTrialReminderAtLargeText() async throws {
        try await capture(size: .large, name: "trial-reminder-large")
    }

    func testCaptureTrialReminderAtAX5() async throws {
        try await capture(size: .accessibilityExtraExtraExtraLarge, name: "trial-reminder-ax5")
    }

    private func capture(size: ContentSizeCategory, name: String) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let controller = UIHostingController(rootView:
            TrialReminderOfferView(onAccept: {}, onDecline: {})
                .environment(\.sizeCategory, size)
                .preferredColorScheme(.light)
        )
        controller.traitOverrides.preferredContentSizeCategory = size == .large
            ? .large : .accessibilityExtraExtraExtraLarge
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        window.rootViewController = controller
        window.windowLevel = .normal + 1
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previous?.makeKeyAndVisible()
        }
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(400))
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertGreaterThan(image.size.height, 0)
    }
}
