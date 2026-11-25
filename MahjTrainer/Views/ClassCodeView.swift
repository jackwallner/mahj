import SwiftUI

/// Settings > Class Code: type the code from a teacher's card, or leave the
/// class. Scanning the card's link (`mahj://class/<code>`) joins without
/// coming here.
struct ClassCodeView: View {
    @ObservedObject private var classes = ClassCodeService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var entry = ""
    @State private var joining = false
    @State private var failure: ClassCodeService.JoinOutcome?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        Form {
            if let joined = classes.current {
                joinedSection(joined)
            } else {
                entrySection
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .tint(Theme.jade)
        .analyticsScreen("ClassCode")
        .navigationTitle("Class Code")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if classes.current == nil { fieldFocused = true } }
    }

    private func joinedSection(_ joined: TeacherClass) -> some View {
        Section {
            LabeledContent("Class", value: joined.name)
            if let room = joined.focusRoom {
                LabeledContent("This Week", value: room.name)
            }
            Button("Leave Class", role: .destructive) {
                classes.leave()
            }
            .foregroundStyle(Theme.gradeWrong)
        }
    }

    private var entrySection: some View {
        Section {
            TextField("Code", text: $entry)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($fieldFocused)
                .submitLabel(.join)
                .onSubmit(join)
                .onChange(of: entry) { _, _ in failure = nil }
            Button(action: join) {
                HStack {
                    Text("Join")
                    if joining {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(joining || ClassCode.normalized(entry) == nil)
        } footer: {
            if let message = failureMessage {
                Text(message).foregroundStyle(Theme.gradeWrong)
            }
        }
    }

    private var failureMessage: String? {
        switch failure {
        case .notFound: return String(localized: "No class uses that code.")
        case .offline: return String(localized: "Can't connect right now. Try again in a moment.")
        case .joined, nil: return nil
        }
    }

    private func join() {
        guard !joining, ClassCode.normalized(entry) != nil else { return }
        joining = true
        Task {
            let outcome = await classes.join(entry)
            joining = false
            if outcome == .joined {
                dismiss()
            } else {
                failure = outcome
            }
        }
    }
}
