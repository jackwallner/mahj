import SwiftUI
import UIKit
import XCTest
@testable import MahjTrainer

/// Send read the text binding while dictation still held most of the
/// message as marked text, so players' feedback arrived as one word.
@MainActor
final class FeedbackDictationTests: XCTestCase {
    private final class Draft: ObservableObject {
        @Published var text = ""
    }

    private struct Editor: View {
        @ObservedObject var draft: Draft
        var body: some View { TextEditor(text: $draft.text) }
    }

    private func textView(in view: UIView) -> UITextView? {
        if let found = view as? UITextView { return found }
        for sub in view.subviews {
            if let found = textView(in: sub) { return found }
        }
        return nil
    }

    func testCommitHandsDictatedWordsToTheBinding() async throws {
        let draft = Draft()
        let host = UIHostingController(rootView: Editor(draft: draft))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 600))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(300))

        let field = try XCTUnwrap(textView(in: host.view))
        XCTAssertTrue(field.becomeFirstResponder())
        field.insertText("I'm ")
        field.setMarkedText("just a beginner", selectedRange: NSRange(location: 15, length: 0))
        try await Task.sleep(for: .milliseconds(100))
        // The bug: what Send used to read.
        XCTAssertEqual(draft.text.trimmingCharacters(in: .whitespaces), "I'm")

        await PendingTextInput.commit()

        XCTAssertEqual(draft.text, "I'm just a beginner")
    }
}
